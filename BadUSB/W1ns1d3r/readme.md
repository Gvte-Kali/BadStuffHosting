# W1ns1d3r BadUSB

## Description

This project is a BadUSB mix of some rubber ducky scripts.

- **Version:** [2.2]
- **Average Time :** 30 Secs
- **Target:** Windows 10/11 (7/8 not tested)
- **Supported Layout keyboard:** US/FR/DE
- **Author:** [Gvte-kali](https://github.com/Gvte-Kali/BadStuffHosting)
  
- **Credits:**
  - [![blobs0](https://img.shields.io/badge/blobs0-Ultimate%20Flipper%20Grabber-brightgreen)](https://github.com/blobs0/Ultimate-Flipper-Grabber)
  - [![I-am-jakoby](https://img.shields.io/badge/I--am--jakoby-Discord%20Webhooks%20Functions-blue)](https://github.com/I-am-jakoby)
  - [![UNCOV3R3D](https://img.shields.io/badge/UNCOV3R3D-Statut-orange)](https://github.com/UNC0V3R3D)
  - 7h30th3r0n3
  - moosehadley

## Features 

**W1ns1d3r** 
- Uses Discord or Dropbox Webhook
  
**W1ns1d3r_Tr3ll0** 
- Uses Trello API
  
## How to use
- Download the [.txt] file, put your webhook inside it. 
- Put the modified file into your Rubber Ducky or Flipper Zero.
- Enjoy !


# Releases

- **Version [2.0]** - *26/01/2024*
  
- **Version [2.1]** - *27/01/2024*
  - **Changelog:**
    - Changed the code to 2 payloads:
      - **Stage 1:** Web browser passwords only
      - **Stage 2:** Anti-Spyware version, information about user, computer, updates, and WiFi passwords
        
- **Version [2.2]** - *27/01/2024*
  - **Changelog:**
    - Added the admin rights version of the badUSB
    - Added the TempDir function to check if the C:\temp directory is already created.
      - If C:\temp exists, simply go to C:\temp
      - If C:\temp does not exist, create the directory and move into it
        
- **Version [2.3]** - *01/02/2024*
  - **Changelog:**
    - Added function "*StorageAndTreeInfo*" :
      - Collects informations about hard drives
      - Does the command *tree $Env:userprofile /a /f* to get an idea of what's interesting into user's folder
      - Writes the output to "St0r4ge_1nf0.txt"
    - Added function "*NetworkInfo*" :
      - Collects informations about the network
      - Writes the output to "n3tw0rk_1nf0.txt"
    - Added function "*HardwareInfo*" :
      - Collects a lot of Hardware data
      - Writes the output to "h4rdw4re_1nf0.txt"
    - Added function "*GrabBrowserData" :
      - Collects history and bookmarks for :
        - Google Chrome
        - Microsoft Edge
        - Mozilla Firefox
      - Writes the output to "Br0ws3r_d4t4.txt"
    - Added function "*ZipAndUploadToDiscord*" :
      - Put all the content of "C:\temp" and zips it to "${username}_LOOT_${dateSansHeure}.zip"
      - Uploads the zip file to Discord
        
- **Version [2.4]** - *currently in progress*
    - To do :
      - Try to go on DropBox or some Cloud-Based Storage with API --> Discord sometimes detects zip file as virus.
      - Add the trash folder erasing
      - Add the powershell history erasing
      - Change versions to do : 1 - W1ns1d3r_f4st  |  2 - W1ns1d3r_St4gg3d  |  3 - W1ns1d3r_4dm1n
      - On W1ns1d3r_4dm1n, try to add keylogger and reverse shell with persistence. ( metasploit meterpreter ? )
