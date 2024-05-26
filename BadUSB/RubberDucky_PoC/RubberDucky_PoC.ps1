function Payload_Launch {

OpenNotepad
#CreateWarningSlideshow

}

function OpenNotepad {
    # Ouvrir le Bloc-notes
    Start-Process notepad
    Start-Sleep -Seconds 2
    
    # Maximiser la fenêtre du Bloc-notes
    MaximizeNotepad
    
    # Augmenter la police d'écriture
    SetNotepadFontSize -fontSize 24
    
    # Écrire le texte spécifié
    $wshell = New-Object -ComObject wscript.shell
    $wshell.AppActivate('Notepad')
    Start-Sleep -Seconds 1
    $wshell.SendKeys("Bonjour,`r`n`r`nVoici une demonstration de ce qu'une cle USB infectee peut faire :")
    Start-Sleep -Seconds 5

    # Fermer le Bloc-notes directement via le processus
    $notepad = Get-Process notepad -ErrorAction SilentlyContinue
    if ($notepad) {
        $notepad.Kill()
    }
}

function MaximizeNotepad {
    # Utiliser les API Windows pour maximiser la fenêtre du Bloc-notes
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class User32 {
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@

    $maxAttempts = 20
    $attempt = 0
    $hwnd = [IntPtr]::Zero

    while ($hwnd -eq [IntPtr]::Zero -and $attempt -lt $maxAttempts) {
        $hwnd = [User32]::FindWindow("Notepad", $null)
        if ($hwnd -eq [IntPtr]::Zero) {
            $hwnd = [User32]::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, $null, "Sans titre - Bloc-notes")
        }
        if ($hwnd -eq [IntPtr]::Zero) {
            $hwnd = [User32]::FindWindowEx([IntPtr]::Zero, [IntPtr]::Zero, $null, "Untitled - Notepad")
        }
        Start-Sleep -Milliseconds 500
        $attempt++
    }

    if ($hwnd -ne [IntPtr]::Zero) {
        [User32]::SetForegroundWindow($hwnd)
        # SW_MAXIMIZE = 3
        [User32]::ShowWindow($hwnd, 3)
    } else {
        Write-Host "Notepad window not found."
    }
}

function SetNotepadFontSize {
    param (
        [int]$fontSize = 24
    )

    # Définir la taille de la police dans le registre
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Notepad" -Name "lfHeight" -Value (-$fontSize * 10)

    # Redémarrer Notepad pour appliquer les modifications
    $notepad = Get-Process notepad -ErrorAction SilentlyContinue
    if ($notepad) {
        $notepad.Kill()
    }
    
    Start-Sleep -Seconds 1

    # Réouvrir Notepad
    Start-Process notepad
    Start-Sleep -Seconds 2
    
    # Rémaximiser après le redémarrage
    MaximizeNotepad
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
        "https://wallpapergod.com/images/hd/hacker-1920X1080-wallpaper-hnae561v4cbp8cvu.jpeg",
        "https://images3.alphacoders.com/853/85329.jpg",
        "https://wallpapers.com/images/hd/hacking-background-bryw246r4lx5pyue.jpg",
        "https://images.pexels.com/photos/97077/pexels-photo-97077.jpeg?cs=srgb&dl=pexels-negativespace-97077.jpg&fm=jpg"
    )

    # Télécharger les images dans le dossier "WARNING"
    $downloadedImages = @()
    foreach ($url in $imageURLs) {
        $filename = [System.IO.Path]::GetFileName($url)
        $destinationPath = Join-Path $warningFolderPath $filename
        Invoke-WebRequest -Uri $url -OutFile $destinationPath
        $downloadedImages += $destinationPath
    }

    # Créer le fichier de configuration du diaporama
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
    foreach ($image in $downloadedImages) {
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $image, 0x0001 -bor 0x0002)
        Start-Sleep -Seconds 2
    }
}


# Ouvre un nouveau mail via Outlook
function OutlookNewMail {
$olApp = New-Object -ComObject Outlook.Application
$mailItem = $olApp.CreateItem(0) # 0: olMailItem
$mailItem.Display()
}


Payload_Launch
