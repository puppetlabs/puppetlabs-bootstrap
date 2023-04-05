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
  $DNS_Alt_Names,

  [Parameter(Mandatory = $False)]
  [String]
  $Environment,

  [Parameter(Mandatory = $False)]
  [String]
  $Set_Noop,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ $_ -match '\w+=\w+' })]
  [String[]]
  $Custom_Attribute,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ $_ -match '\w+=\w+' })]
  [String[]]
  $Extension_Request,

  [Parameter(Mandatory = $False)]
  [ValidateScript({ $_ -match '\w+:\w+=\w+' })]
  [String[]]
  $Puppet_Conf_Settings
)

function Set-SecurityProtocol {
  Try {
    # Note: 3072 is the enum value for tls12 to support .NET 4.0
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]3072
  } Catch {
    Throw "Unable to Set Security Protocol to TLS 1.2; this may cause network-dependent calls to fail!`r`nException:`r`n$($_.Exception)"
  }
}

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

function Out-CA($Content)
{
  # https://github.com/puppetlabs/puppet-specifications/blob/master/file_paths.md#puppet-agent-windows
  $sslDirectory = Join-Path $ENV:ProgramData 'PuppetLabs\puppet\etc\ssl\certs'
  $caFilePath = Join-Path $sslDirectory 'ca.pem'
  New-Item -ItemType Directory -Path $sslDirectory | Out-Null
  Write-Verbose "Writing $($Content.Length) length string to $caFilePath"
  $Content | Out-File -FilePath $caFilePath -Encoding ASCII
}

function ConvertTo-JsonString($string)
{
  (($string -replace '\\', '\\') -replace '\"', '\"') -replace '[\u0000-\u001F]', ' '
}

function New-OptionsHash($Prefix, $Values)
{
  $hash = @{}
  $Values | % { $k, $v = $_ -split '=',2; $hash."$Prefix`:$k" = $v }
  $hash
}

function New-OptionsStringHash($Values)
{
  $hash = @{}
  Foreach ($i in $Values)
  {
    echo $i
    $k, $v = $i -split '=',2
    $hash.["$k"] = $v
  }
  echo "hash is"
  echo $hash
  $hash
}

function New-OptionsString($Values)
{
  $String = ""
  Foreach ($i in $Values)
  {
    $String = "${String}$i "
  }
  $String
}

function Invoke-SimplifiedInstaller
{
  [CmdletBinding()]
  param
  (
    $Master,
    $CertName,
    $CACertContent,
    $ExtraConfig = @{},
    # $Puppet_Conf
  )

  Out-CA -Content $CACertContent
  $masterCA = New-CertificateFromContent -Content $CACertContent
  $installer = Get-InstallerScriptBlock -Master $Master -RootCertificate $masterCA
  if ($masterCA -is [System.IDisposable]) { [Void]$masterCA.Dispose() }

  $ExtraConfig.Add('agent:certname', $CertName)
  $installerArgs = @{
    Arguments = $ExtraConfig.GetEnumerator() | % { "$($_.Key)=$($_.Value)" }
  }

  # echo "$installer @installerArgs $Puppet_Conf"

  Write-Verbose "Calling installer ScriptBlock with arguments: $($installerArgs.Arguments)"
  echo $installer
  & $installer @installerArgs 2>&1
}

try
{
  Set-SecurityProtocol

  # if ($PSBoundParameters.ContainsKey('Puppet_Conf_Settings')) {
  #   $Puppet_Conf = (New-OptionsString $Puppet_Conf_Settings)
  #   echo "puppet conf settings are"
  #   echo $Puppet_Conf_Settings
  #   echo $Puppet_Conf_Settings > c:\pupsetting.txt
  # } else {
  #   $Puppet_Conf = ""
  # }

  $options = @{
    Master = $Master
    CertName = ($PSBoundParameters['CertName'], (Get-HostName) -ne $null)[0].ToLower()
    CACertContent = ($PSBoundParameters['CACertContent'], (Get-CA -Master $Master) -ne $null)[0]
    ExtraConfig = @{}
    # Puppet_Conf = $Puppet_Conf
  }
  if ($PSBoundParameters.ContainsKey('DNS_Alt_Names')) {
    $options.ExtraConfig += @{ 'agent:dns_alt_names' = "'$DNS_Alt_Names'" }
  }
  if ($PSBoundParameters.ContainsKey('Custom_Attribute')) {
    $options.ExtraConfig += (New-OptionsHash 'custom_attributes' $Custom_Attribute)
  }
  if ($PSBoundParameters.ContainsKey('Extension_Request')) {
    $options.ExtraConfig += (New-OptionsHash 'extension_requests' $Extension_Request)
  }
    if ($PSBoundParameters.ContainsKey('Puppet_Conf_Settings')) {
    $options.ExtraConfig += (New-OptionsStringHash $Puppet_Conf_Settings)
  }
  if ($PSBoundParameters.ContainsKey('Environment')) {
    $options.ExtraConfig += @{ 'agent:environment' = "'$Environment'" }
  }
  if ($PSBoundParameters.ContainsKey('Set_Noop')) {
    $options.ExtraConfig += @{ 'agent:noop' = "$Set_Noop".ToLower() }
  }
  echo "options are"
  echo $options
  $installerOutput = Invoke-SimplifiedInstaller @options
  $jsonOutput = ConvertTo-JsonString $installerOutput
  $jsonSafeConfig = $options.ExtraConfig.GetEnumerator() |
    % { ConvertTo-JsonString "$($_.Key)=$($_.Value)" }
  $jsonHostName = ConvertTo-JsonString (Get-HostName)
  $jsonCertName = ConvertTo-JsonString $options.CertName

  # TODO: could use ConvertTo-Json, but that requires PS3
  # if embedding in literal, should make sure Name / Status doesn't need escaping
  Write-Host @"
{
  "host"     : "$jsonHostName",
  "certname" : "$jsonCertName",
  "master"   : "$Master",
  "config"   : "$jsonSafeConfig",
  "output"   : "$jsonOutput",
  "status"   : "success"
}
"@
}
catch
{
  Write-Host @"
  {
    "status"   : "failure",
    "host"     : "$jsonHostName",
    "certname" : "$jsonCertName",
    "master"   : "$Master",
    "_error"   : {
      "msg" : "Unable to install agent on $jsonHostName with certname ${jsonCertName}: $(ConvertTo-JsonString $_.Exception.Message)",
      "kind": "powershell_error",
      "details" : {}
    }
  }
"@
}
