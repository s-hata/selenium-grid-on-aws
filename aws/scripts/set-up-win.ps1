function Write-Message {

  [CmdletBinding()]
  Param (
    [Parameter()]
    $Message
  )

  $Timestamp = Get-Date -UFormat "%Y/%m/%d %H:%M:%S"
  Write-Host "[$Timestamp] $Message"
}

Write-Message "Disable FW"
netsh advfirewall set allprofiles state off
netsh advfirewall show allprofiles

Write-Message "Disable Auto Update of Windows Update"
cscript C:\Windows\system32\scregedit.wsf /au 1
Restart-Service wuauserv
cscript C:\Windows\System32\SCRegEdit.wsf /AU /v

Write-Message "Disable Windows Defender"
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SecurityHealth" -ErrorAction SilentlyContinue

# (Windows 10/Windows 2016 Server only)
Write-Message "Disable Action Center"
If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
}
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0

Write-Message "Configure UAC"
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Stop-Process -Name Explorer -Force
