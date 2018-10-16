function Write-Message {

  [CmdletBinding()]
  Param (
    [Parameter()]
    $Message
  )

  $Timestamp = Get-Date -UFormat "%Y/%m/%d %H:%M:%S"
  Write-Host "[$Timestamp] $Message"
}

Write-Message "Create Directory"
mkdir C:\selenium

$webclient = New-Object System.Net.WebClient

Write-Message "Install Oracle JDK"
$j = $webclient.DownloadString("https://www.java.com/en/download/manual.jsp")
$j -match "Offline(.*)>"
$java = $matches[0].Split('"')
$url = $java[2]
$webclient.DownloadFile($url, "C:\selenium\install_java.exe")
Start-Process "install_java.exe" -ArgumentList "/s" -Wait
$javaexe = Get-ChildItem -path 'C:\Program Files (x86)\Java' -filter java.exe -recurse
$newpath = $env:path + ';' + $javaexe.DirectoryName + '\;C:\selenium\'
$env:Path = $newpath
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name 'Path' -Value $newpath

Write-Message "Download NSSM"
$n = $webclient.DownloadString("http://nssm.cc/download")
$n -match "release(.*)zip"
$url = "http://nssm.cc/" + $matches[0]
$webclient.DownloadFile($url, "C:\selenium\nssm.zip")
$shell = new-object -com shell.application
$zip = $shell.NameSpace("C:\selenium\nssm.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm nssm.zip
mv nssm-* install_nssm
cp install_nssm/win64/nssm.exe .

Write-Message "Set Up Selenium Hub"
[xml]$selenium = $webclient.DownloadString("https://selenium-release.storage.googleapis.com/")
[string]$jar = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'standalone' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($jar.Split('/')[0]) + '/' + ($jar.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\selenium-server-standalone.jar")
nssm install seleniumhub java -jar C:\selenium\selenium-server-standalone.jar -role hub
Start-Service seleniumhub

