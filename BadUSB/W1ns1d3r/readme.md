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

**W1ns1d3r_4dm1n:** 
- Get administrative privileges on target if user is already admin.
- Sets the working directory to C:\temp and adds an exception in Firewall.
- The informations the script pulls :
    - Stage 1 :
        - Web browser passwords
    - Stage 2 :
        - Antivirus software and version
        - User informations
        - System informations
        - Wifi passwords
- Post everything in your discord webhook
- Delete the C:\temp directory
  
**W1ns1d3r** 
- Don't get the administrative privileges on target.
- Sets the working directory to C:\temp.
- The informations the script pulls :
    - Stage 1 :
        - Web browser passwords
    - Stage 2 :
        - Antivirus software and version
        - Hardware informations
        - System informations
        - Wifi passwords
- Post everything in your discord webhook
- Delete the C:\temp directory
  
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

