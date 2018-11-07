Param( [string]$hubip)

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

Write-Message "Set Up Selenium Hub"
[xml]$selenium = $webclient.DownloadString("https://selenium-release.storage.googleapis.com/")
[string]$jar = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'standalone' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($jar.Split('/')[0]) + '/' + ($jar.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\selenium-server-standalone.jar")

Write-Message "Download ChromeDriver"
$chromedriverversion = $webclient.DownloadString("http://chromedriver.storage.googleapis.com/LATEST_RELEASE")
$url = "http://chromedriver.storage.googleapis.com/" + $chromedriverversion + "/chromedriver_win32.zip"
$webclient.DownloadFile($url, "C:\selenium\install_chromedriver.zip")
$zip = $shell.NameSpace("C:\selenium\install_chromedriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm install_chromedriver.zip

Write-Message "Download GeckoDriver"
$url = "https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-win64.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webclient.DownloadFile($url, "C:\selenium\geckodriver.zip")
$zip = $shell.NameSpace("C:\selenium\geckodriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }

Write-Message "Download IEDriverServer"
[string]$iedriver = $selenium.ListBucketResult.Contents.Key | ? { $_ -match 'IEDriverServer_Win32' } | Select-Object -Last 1
$url = 'https://selenium-release.storage.googleapis.com/' + ($iedriver.Split('/')[0]) + '/' + ($iedriver.Split('/')[1])
$webclient.DownloadFile($url, "C:\selenium\install_iedriver.zip")
$zip = $shell.NameSpace("C:\selenium\install_iedriver.zip")
foreach($item in $zip.items()) { $shell.Namespace("C:\selenium").copyhere($item) }
rm install_iedriver.zip

Write-Message "Install Google Chrome"
$url = "http://dl.google.com/chrome/install/chrome_installer.exe"
$webclient.DownloadFile($url, "C:\selenium\install_chrome.exe")
Start-Process "C:/selenium/install_chrome.exe" -ArgumentList "/silent /install" -Wait
Start-Sleep -s 30

Write-Message "Install Mozilla Firefox"
$f = $webclient.DownloadString("https://www.mozilla.org/en-US/firefox/all/")
$f -match "https:\/\/download\.mozilla\.org\/(.*)os=win(.*)en-US"
$url = $matches[0] -replace "&amp;", "&"
$webclient.DownloadFile($url, "C:\selenium\install_firefox.exe")
Start-Process "C:/selenium/install_firefox.exe" -ArgumentList "-ms" -Wait
Start-Sleep -s 30

Write-Message "Set Up Internet Explore"
Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "WarnOnZoneCrossing" -Value 00000000
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "CertificateRevocation" -Value "0"
Set-ItemProperty "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" -name “2500" -value "0"
Stop-Process -Name Explorer -Force

Write-Message "create selenium node configuration file"
New-Item C:/selenium/node.json -type file
$nodejson = @"
{
  "capabilities":
  [
    {
      "browserName": "firefox",
      "marionette": true,
      "maxInstances": 5,
      "seleniumProtocol": "WebDriver"
    },
    {
      "browserName": "chrome",
      "maxInstances": 5,
      "seleniumProtocol": "WebDriver"
    },
    {
      "browserName": "internet explorer",
      "platform": "WINDOWS",
      "maxInstances": 1,
      "seleniumProtocol": "WebDriver"
    }
  ],
  "proxy": "org.openqa.grid.selenium.proxy.DefaultRemoteProxy",
  "maxSession": 5,
  "port": 5555,
  "register": true,
  "registerCycle": 5000,
  "hub": "http://${hubip}:4444",
  "nodeStatusCheckTimeout": 5000,
  "nodePolling": 5000,
  "role": "node",
  "unregisterIfStillDownAfter": 60000,
  "downPollingLimit": 2,
  "debug": false,
  "servlets" : [],
  "withoutServlets": [],
  "custom": {}
}
"@
$nodejson > C:/selenium/node.json

Write-Message "set up selenium.bat"
$webclient.DownloadFile("https://raw.githubusercontent.com/s-hata/selenium-grid-on-aws/master/aws/scripts/selenium.bat", "C:\selenium\selenium.bat")
cp "C:\selenium/selenium.bat" "C:/ProgramData/Microsoft/Windows/Start Menu/Programs/Startup/"
Stop-Process -Name Explorer -Force
Start-Process "C:/ProgramData/Microsoft/Windows/Start Menu/Programs/Startup/selenium.bat"

Write-Message "Restart browsers"
start-process iexplore; start-process firefox; start-process chrome; sleep 60; get-process iexplore | stop-process; get-process firefox | stop-process; get-process chrome | stop-process;
