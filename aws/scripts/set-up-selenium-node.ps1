Param([string]$hubip)
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Parameters"
echo $hubip
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
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Download Selenium"
[xml]$selenium = $webclient.DownloadString("https://selenium-release.storage.googleapis.com/")
[string]$jar = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'standalone' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($jar.Split('/')[0]) + '/' + ($jar.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\selenium-server-standalone.jar")
$shell = new-object -com shell.application
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Download ChromeDriver"
$chromedriverversion = $webclient.DownloadString("http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
$url = "http://chromedriver.storage.googleapis.com/" + $chromedriverversion + "/chromedriver_win32.zip"
$webclient.DownloadFile($url, "C:\selenium\install_chromedriver.zip")
$zip = $shell.NameSpace("C:\selenium\install_chromedriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm C:\selenium\install_chromedriver.zip
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Download GeckoDriver"
$url = "https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-win64.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webclient.DownloadFile($url, "C:\selenium\geckodriver.zip")
$zip = $shell.NameSpace("C:\selenium\geckodriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Download IEDriverServer"
[string]$iedriver = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'IEDriverServer_Win32' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($iedriver.Split('/')[0]) + '/' + ($iedriver.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\install_iedriver.zip")
$zip = $shell.NameSpace("C:\selenium\install_iedriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm C:\selenium\install_iedriver.zip
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Install Google Chrome"
$url = "http://dl.google.com/chrome/install/chrome_installer.exe"
$webclient.DownloadFile($url, "C:\selenium\install_chrome.exe")
Start-Process "C:\selenium\install_chrome.exe" -ArgumentList "/silent /install" -Wait
Start-Sleep -s 30
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Install Mozilla Firefox"
$f = $webclient.DownloadString("https://www.mozilla.org/en-US/firefox/all/")
$f -match "https:\/\/download\.mozilla\.org\/(.*)os=win(.*)en-US"
$url = $matches[0] -replace "&amp;", "&"
$webclient.DownloadFile($url, "C:\selenium\install_firefox.exe")
Start-Process "C:/selenium/install_firefox.exe" -ArgumentList "-ms" -Wait
Start-Sleep -s 30
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Setup Internet Explore"
Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "WarnOnZoneCrossing" -Value 00000000
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "CertificateRevocation" -Value "0"
Set-ItemProperty "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" -name "2500" -value "0"
Stop-Process -Name Explorer -Force

echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Generate Selenium Node configuration file"
$webclient.DownloadFile("https://raw.githubusercontent.com/s-hata/selenium-grid-on-aws/non-secure/aws/scripts/node.json", "C:\selenium\node.json")
$nodestr = [string](gc C:\selenium\node.json)
$nodestr.replace("HUBIP",$hubip)|sc C:\selenium\node.json
echo "[$(Get-Date -UFormat "%Y/%m/%d %H:%M:%S")] Set Up selenium.bat"
$webclient.DownloadFile("https://raw.githubusercontent.com/s-hata/selenium-grid-on-aws/non-secure/aws/scripts/selenium.bat", "C:\selenium\selenium.bat")
cp "C:\selenium\selenium.bat" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"
Start-Process "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\selenium.bat"
Start-Process iexplore; start-process firefox; start-process chrome; sleep 60; get-process iexplore | stop-process; get-process firefox | stop-process; get-process chrome | stop-process
