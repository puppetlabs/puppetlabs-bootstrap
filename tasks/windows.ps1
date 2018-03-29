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

if ($CertName.Length -gt 0) {
  $certname_arg = "agent:certname='$CertName' "
}
else {
  $fqdn = [System.Net.Dns]::GetHostByName(($env:computerName)).Hostname
  $certname_arg = "agent:certname='$fqdn' "
}
if ($DNS_Alt_Names.Length -gt 0) {
  $alt_names_arg = "agent:dns_alt_names='$alt_names' "
}
else {
  $alt_names_arg = ""
}
if ($CACert_Content) {
  New-Item -ItemType Directory -Force -Path "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs"
  Out-File -InputObject $CACert_Content -FilePath "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs\ca.pem" -Encoding ascii -Force
}

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("https://${Master}:8140/packages/current/install.ps1", $env:temp + '\install.ps1')
&($env:temp + '\install.ps1') $certname_arg $alt_names_arg
Write-Output 'Installed'
