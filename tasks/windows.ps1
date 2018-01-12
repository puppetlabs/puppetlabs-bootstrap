[CmdletBinding()]
Param(
  [Parameter(Mandatory = $True)] [String] $master,
  [Parameter(Mandatory = $False)] [String] $cacert_content,
  [Parameter(Mandatory = $False)] [String] $certname,
  [Parameter(Mandatory = $False)] [String] $dns_alt_names
)

Function Validate-Parameter {
  Param ($param)
  if ($param -contains "'") {
    Throw 'Single-quote is not allowed in arguments'
  }
}

Validate-Parameter($certname)
Validate-Parameter($alt_names)

if ($certname.Length -eq 0) {
  $certname_arg = "agent:certname='$certname' "
}
else {
  $fqdn = [System.Net.Dns]::GetHostByName(($env:computerName)).Hostname 
  $certname_arg = "agent:certname='$fqdn' "
}
if ($dns_alt_names.Length -eq 0) {
  $alt_names_arg = "agent:dns_alt_names='$alt_names' "
}
else {
  $alt_names_arg = ""
}
if ($cacert_content) {
  New-Item -ItemType Directory -Force -Path "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs"
  Out-File -InputObject $cacert_content -FilePath "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs\ca.pem" -Encoding ascii -Force
}

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile("https://${master}:8140/packages/current/install.ps1", $env:temp + '\install.ps1')
&($env:temp + '\install.ps1') $certname_arg $alt_names_arg
Write-Output 'Installed'
