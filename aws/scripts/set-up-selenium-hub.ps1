echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Disable FW"
netsh advfirewall set allprofiles state off
netsh advfirewall show allprofiles

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Disable Auto Update of Windows Update"
cscript C:\Windows\system32\scregedit.wsf /au 1
Restart-Service wuauserv
cscript C:\Windows\System32\SCRegEdit.wsf /AU /v

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Disable Windows Defender"
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SecurityHealth" -ErrorAction SilentlyContinue

# (Windows 10/Windows 2016 Server only)
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Disable Action Center"
If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Configure UAC"
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Stop-Process -Name Explorer -Force

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Create Directory"
mkdir C:\selenium

$webclient = New-Object System.Net.WebClient

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Install Oracle Java"
$j = $webclient.DownloadString("https://www.java.com/en/download/manual.jsp")
$j -match "Offline(.*)>"
$java = $matches[0].Split('"')
$url = $java[2]
$webclient.DownloadFile($url, "C:\selenium\install_java.exe")
Start-Process "C:\selenium\install_java.exe" -ArgumentList "/s" -Wait
$javaexe = Get-ChildItem -path 'C:\Program Files (x86)\Java' -filter java.exe -recurse
$newpath = $env:path + ';' + $javaexe.DirectoryName + '\;C:\selenium\'
$env:Path = $newpath
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name 'Path' -Value $newpath

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Set Up NSSM"
$n = $webclient.DownloadString("http://nssm.cc/download")
$n -match "release(.*)zip"
$url = "http://nssm.cc/" + $matches[0]
$webclient.DownloadFile($url, "C:\selenium\nssm.zip")
$shell = new-object -com shell.application
$zip = $shell.NameSpace("C:\selenium\nssm.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm C:\selenium\nssm.zip
mv C:\selenium\nssm-* C:\selenium\install_nssm
cp C:\selenium\install_nssm/win64/nssm.exe C:\selenium\

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Set Up Selenium Hub"
[xml]$selenium = $webclient.DownloadString("https://selenium-release.storage.googleapis.com/")
[string]$jar = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'standalone' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($jar.Split('/')[0]) + '/' + ($jar.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\selenium-server-standalone.jar")
C:\selenium\nssm install seleniumhub java -jar C:\selenium\selenium-server-standalone.jar -role hub
Start-Service seleniumhub

