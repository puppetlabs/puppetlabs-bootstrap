[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)]
  [String]
  $Master,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ $_ -notmatch '^\s*$' })]
  [String]
  $CACert_Content,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ if ([System.URI]::CheckHostName($_) -ne 'Dns') {
      throw "Invalid DNS name `"$_`""
  }; $True})]
  [String]
  $CertName,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ $_ -split ',' | % {
    if ([System.URI]::CheckHostName($_) -ne 'Dns') {
      throw "Invalid DNS name `"$_`""
  }}; $True})]
  [String]
  $DNS_Alt_Names
)

function Get-HostName
{
  $ipAddress = ([System.Net.Dns]::GetHostEntry([System.Environment]::MachineName)).AddressList |
    ? { $_.AddressFamily -eq 'InterNetwork' } |
    Select -First 1 -ExpandProperty IPAddressToString

  $name = [System.Net.Dns]::GetHostEntry($ipAddress).HostName
  Write-Verbose "Resolved current hostname to $name"
  return $name
}

function Get-CA($Master)
{
  $verificationCallback = [Net.ServicePointManager]::ServerCertificateValidationCallback
  try
  {
    # temporarily disable SSL verification while downloading CA
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    $caUri = "https://${Master}:8140/puppet-ca/v1/certificate/ca"
    Write-Verbose "Downloading root ca cert from $caUri"
    return (New-Object System.Net.WebClient).DownloadString($caUri)
  }
  finally
  {
    # restore original chain validation
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $verificationCallback
  }
}

function New-CertificateFromContent($Content)
{
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,$bytes)
  $cert.Import($bytes)

  return $cert
}

function Get-InstallerScriptBlock($Master, $RootCertificate)
{
  $verificationCallback = [Net.ServicePointManager]::ServerCertificateValidationCallback
  try
  {
    $customCACallback = {
      param(
        $sender,
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $certificate,
        [System.Security.Cryptography.X509Certificates.X509Chain]
        $chain,
        [System.Net.Security.SslPolicyErrors]
        $sslPolicyErrors
      )

      # when there are no policy errors the root certificate used to sign the
      # masters certificate is either:
      # * in the local trusted cert store already (other CA infra / intermediate
      #   CA already in place)
      # * is not self-signed / generated from a valid third-party root CA
      if ($sslPolicyErrors -eq 'None') { return $true }

      # Build a new chain that includes the Root Certificate Authority
      $chain.ChainPolicy.ExtraStore.Add($RootCertificate)
      $chain.Build($certificate)

      # For a Puppet server response to typically be valid:

      # 1. there should only be a single status
      $oneStatus = $chain.ChainStatus.Count -eq 1
      # 2. the chain terminated with a status of UntrustedRoot (self-signed) cert
      # not one of the 20+ other possible failure modes
      # https://msdn.microsoft.com/en-us/library/windows/apps/xaml/system.security.cryptography.x509certificates.x509chainstatusflags(v=vs.90).aspx
      $untrustedRoot = [System.Security.Cryptography.X509Certificates.X509ChainStatusFlags]::UntrustedRoot
      $untrustedCA = $chain.ChainStatus[0].Status -eq $untrustedRoot
      # 3. the end of the chain (root) is the same CA as passed in
      $lastCertInChain = $chain.ChainElements[$chain.ChainElements.Count - 1].Certificate
      $rootIsExpectedCA = $lastCertInChain -eq $RootCertificate

      return $oneStatus -and $untrustedCA -and $rootIsExpectedCA
    }

    # Allow install.ps1 from an endpoint signed by the Root Certificate Authority
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $customCACallback
    $installerUri = "https://${Master}:8140/packages/current/install.ps1"
    Write-Verbose "Downloading simplified installer $installerUri - allowing root cert [$($RootCertificate.Thumbprint)]"
    $installer = (New-Object System.Net.WebClient).DownloadString($installerUri)

    return [ScriptBlock]::Create($installer)
  }
  finally
  {
    # restore original chain validation
    [Net.ServicePointManager]::ServerCertificateValidationCallback = $verificationCallback
  }
}

if (!$PSBoundParameters.ContainsKey('CertName'))
{
  $CertName = Get-HostName
}

if (!$PSBoundParameters.ContainsKey('CACert_Content') -or [String]::IsNullOrEmpty($CACert_Content))
{
  $CACert_Content = Get-CA -Master $Master
}

New-Item -ItemType Directory -Force -Path "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs"
Out-File -InputObject $CACert_Content -FilePath "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs\ca.pem" -Encoding ascii -Force

$MasterCA = New-CertificateFromContent -Content $CACert_Content
$installer = Get-InstallerScriptBlock -Master $Master -RootCertificate $MasterCA
$MasterCA.Dispose()

$installerArgs = @{
  Arguments = @("agent:certname='$CertName'")
}
if ($PSBoundParameters.ContainsKey('DNS_Alt_Names')) {
  $installerArgs.Arguments += "agent:dns_alt_names='$DNS_Alt_Names'"
}

& $installer @installerArgs
Write-Output 'Installed'
