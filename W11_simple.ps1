#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$False
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
}

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "24H2"
    OSEdition = "Pro"
    OSLanguage = "de-de"
    OSLicense = "Retail"
    ZTI = $true
    Firmware = $false
}
Start-OSDCloud @Params

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "AddNetFX3":  {
                      "IsPresent":  false
                  },
    "Autopilot":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                    "MicrosoftTeams",
                    "Microsoft.BingWeather",
                    "Microsoft.BingNews",
                    "Microsoft.GamingApp",
                    "Microsoft.GetHelp",
                    "Microsoft.Getstarted",
                    "Microsoft.Messaging",
                    "Microsoft.MicrosoftOfficeHub",
                    "Microsoft.MicrosoftSolitaireCollection",
                    "Microsoft.MicrosoftStickyNotes",
                    "Microsoft.MSPaint",
                    "Microsoft.People",
                    "Microsoft.PowerAutomateDesktop",
                    "Microsoft.StorePurchaseApp",
                    "Microsoft.Todos",
                    "microsoft.windowscommunicationsapps",
                    "Microsoft.WindowsFeedbackHub",
                    "Microsoft.WindowsMaps",
                    "Microsoft.WindowsSoundRecorder",
                    "Microsoft.Xbox.TCUI",
                    "Microsoft.XboxGameOverlay",
                    "Microsoft.XboxGamingOverlay",
                    "Microsoft.XboxIdentityProvider",
                    "Microsoft.XboxSpeechToTextOverlay",
                    "Microsoft.YourPhone",
                    "Microsoft.ZuneMusic",
                    "Microsoft.ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force


#================================================
#  [PostOS] OOBE CMD Command Line
#================================================
Invoke-RestMethod https://raw.githubusercontent.com/cloudsolutiongmbh/wpag/refs/heads/main/keyboard-CH.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\keyboard.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/cloudsolutiongmbh/pal/refs/heads/main/windows_license.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\productkey.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/cloudsolutiongmbh/pal/refs/heads/main/prereq.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\prereq.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/cloudsolutiongmbh/pal/refs/heads/main/cleanlogs.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\cleanlogs.ps1' -Encoding ascii -Force


$OOBECMD = @'
@echo off
# Execute OOBE Tasks
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\keyboard.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\productkey.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\prereq.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F D:\autopilot.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F E:\autopilot.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F F:\autopilot.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F G:\autopilot.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F H:\autopilot.ps1
start /wait powershell.exe -NoL -ExecutionPolicy Bypass -F C:\Windows\Setup\Scripts\cleanlogs.ps1

# Below a PS session for debug and testing in system context, # when not needed 
#start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
