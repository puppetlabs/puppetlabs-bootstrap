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

if (!$PSBoundParameters.ContainsKey('CertName'))
{
  $CertName = Get-HostName
}

if ($CACert_Content) {
  New-Item -ItemType Directory -Force -Path "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs"
  Out-File -InputObject $CACert_Content -FilePath "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs\ca.pem" -Encoding ascii -Force
}

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$installerUri = "https://${Master}:8140/packages/current/install.ps1"
$installer = (New-Object System.Net.WebClient).DownloadString($installerUri)
$installer = [ScriptBlock]::Create($installer)

$installerArgs = @{
  Arguments = @("agent:certname='$CertName'")
}
if ($PSBoundParameters.ContainsKey('DNS_Alt_Names')) {
  $installerArgs.Arguments += "agent:dns_alt_names='$DNS_Alt_Names'"
}

& $installer @installerArgs
Write-Output 'Installed'
