REM *********************************************
REM
REM START OF SCRIPT
REM
REM *********************************************

@echo off
setlocal enabledelayedexpansion

cd C:\>nul 2>&1

REM Safety check in case someone bumps the .bat file
set SAFE=%1
if "%SAFE%"=="" (
    echo Error: SAFE is not set. Exiting...
    exit /b 1
)

REM Call functions

call :set_starttime
call :init_environment
call :read_config
call :call_installers
call :set_desktop_prefs
call :set_endtime
call :calculate_elapsed_time
call :write_ip

REM *********************************************
REM
REM set_starttime
REM
REM *********************************************

:set_starttime

  for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
      set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
  )

exit /b

REM *********************************************
REM
REM init_environment
REM
REM *********************************************

:init_environment

  set SANDBOX_DIR=c:\sandbox
  set COMMON_DIR=c:\common
  set CONFIGS_DIR=%SANDBOX_DIR%\configs
  set INSTALLERS_DIR=%SANDBOX_DIR%\installers
  set CONFIG_FILE=%CONFIGS_DIR%\sandbox.properties
  set LOGFILE=%SANDBOX_DIR%\logs\sandbox.log
  mkdir C:\Development
  set DEVDIR=C:\Development

  del %LOGFILE% > nul 2>&1 
  call :log "Starting"

  start powershell -NoExit -Command "Get-Content -Path '%LOGFILE%' -Wait"

  call :log "SANDBOX_DIR=%SANDBOX_DIR%"
  call :log "COMMON_DIR=%COMMON_DIR%"
  call :log "CONFIGS_DIR=%CONFIGS_DIR%"
  call :log "INSTALLERS_DIR=%INSTALLERS_DIR%"
  call :log "CONFIG_FILE=%CONFIG_FILE%"
  call :log "LOGFILE=%LOGFILE%"
  call :log "DEVDIR=%DEVDIR%"
  call :log "PATH=%PATH%"

exit /b

REM *********************************************
REM
REM read_config
REM
REM *********************************************

:read_config

  REM Check if startup config file exists
  if not exist "%CONFIG_FILE%" (
      call :log "Configuration file not found: %CONFIG_FILE%"
      exit /b 1
  )

  REM Parse the startup config file
  for /f "tokens=1,* delims==" %%A in (%CONFIG_FILE%) do (
      set "KEY=%%A"
      set "VALUE=%%B"
      set "!KEY!=!VALUE!"
      call :log "Property: !KEY!=!VALUE!"
      echo !VALUE! | findstr "," > nul
      if !errorlevel! == 0 (
          REM Handle the comma-separated value as an array
          set "INDEX=0"
          for %%C in (!VALUE!) do (
              set /a INDEX+=1
              set "!KEY![!INDEX!]=%%C"
              call :log "List Property: !KEY![!INDEX!]=%%C"
          )
      )
  )

exit /b

REM *********************************************
REM
REM call_installers
REM
REM *********************************************

:call_installers

  REM Install WinGet
  call :log "Calling install_winget.bat"
  start /min /wait cmd /c "%COMMON_DIR%\install_winget.bat %SANDBOX_DIR%\logs\install_winget.log >> %LOGFILE% 2>&1"

  REM Reset msstore source (only if needed)
  winget source reset --name msstore > nul

  REM Install 7zip using winget
  call :log "Installing 7zip"
  winget install -e --id 7zip.7zip -h --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "7zip installation failed with error code %errorlevel%"

  REM Install Eclipse Temurin JDK 17 with Hotspot
  call :log "Installing Eclipse Temurin JDK 17 with Hotspot"
  winget install -e --id EclipseAdoptium.Temurin.17.JDK -h --scope machine --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "JDK17 installation failed with error code %errorlevel%"
  call :set_java_home

  REM Install Git
  call :log "Installing Git"
  winget install -e --id Git.Git -h --scope machine --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "Git installation failed with error code %errorlevel%"

  REM Install Notepad++
  call :log "Installing Notepad++"
  winget install -e --id Notepad++.Notepad++ -h --scope machine --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "Notepad++ installation failed with error code %errorlevel%"

  REM Install Eclipse with Lombok
  call :log "Installing Eclipse (jee-2024-12-R-win32-x86_64)"
  copy "%COMMON_DIR%\eclipse-jee-2024-12-R-win32-x86_64.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\eclipse-jee-2024-12-R-win32-x86_64.zip" -o"%DEVDIR%\eclipse-jee-2024-12-R-win32-x86_64" -y > nul 2>&1
  if %errorlevel% neq 0 call :log "Eclipse installation failed with error code %errorlevel%"
  
  REM Download and install lombok jar
  call :log "Installing Lombok"
  curl -L -o "%DEVDIR%\eclipse-jee-2024-12-R-win32-x86_64\eclipse\lombok.jar" "https://projectlombok.org/downloads/lombok.jar"
  if %errorlevel% neq 0 call :log "Lombok.jar download failed with error code %errorlevel%"
  echo -javaagent:%DEVDIR%\eclipse-jee-2024-12-R-win32-x86_64\eclipse\lombok.jar >> "%DEVDIR%\eclipse-jee-2024-12-R-win32-x86_64\eclipse\eclipse.ini"

  REM Install Maven
  call :log "Installing Maven (apache-maven-3.9.9-bin)"
  copy "%COMMON_DIR%\apache-maven-3.9.9-bin.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\apache-maven-3.9.9-bin.zip" -o"%DEVDIR%" -y > nul 2>&1
  if %errorlevel% neq 0 call :log "Maven installation failed with error code %errorlevel%"

  REM Set MAVEN_HOME and update PATH
  set MAVEN_HOME=%DEVDIR%\apache-maven-3.9.9
  setx MAVEN_HOME %DEVDIR%\apache-maven-3.9.9 /m
  call :log "MAVEN_HOME is set to %MAVEN_HOME%"

  REM Install Ant
  call :log "Installing Ant (apache-ant-1.10.15-bin)"
  copy "%COMMON_DIR%\apache-ant-1.10.15-bin.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\apache-ant-1.10.15-bin.zip" -o"%DEVDIR%" -y > nul 2>&1
  if %errorlevel% neq 0 call :log "Ant installation failed with error code %errorlevel%"

  REM Set ANT_HOME and update PATH
  set ANT_HOME=%DEVDIR%\apache-ant-1.10.15
  setx MAVEN_HOME %DEVDIR%\apache-maven-3.9.9 /m
  call :log "ANT_HOME is set to %ANT_HOME%"

  REM Install Tomcat
  call :log "Installing Tomcat (apache-tomcat-11.0.2)"
  copy "%COMMON_DIR%\apache-tomcat-11.0.2.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\apache-tomcat-11.0.2.zip" -o"%DEVDIR%" -y > nul 2>&1
  if %errorlevel% neq 0 call :log "Tomcat installation failed with error code %errorlevel%"
  
  REM Desktop shortcuts

  REM Shortcut for 7-Zip
  call :log "Creating shortcut for 7zip"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "7-Zip" -TargetPath "C:\Program Files\7-Zip\7zFM.exe"

  REM Shortcut for Git Bash
  call :log "Creating shortcut for Git Bash"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Git Bash" -TargetPath "C:\Program Files\Git\git-bash.exe"

  REM Shortcut for Notepad++
  call :log "Creating shortcut for Notepad++"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Notepad++" -TargetPath "C:\Program Files\Notepad++\notepad++.exe"

  REM Shortcut for Git Bash
  call :log "Creating shortcut for Eclipse"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Eclipse" -TargetPath "C:\Development\eclipse-jee-2024-12-R-win32-x86_64\eclipse\eclipse.exe" -WorkingDirectory "C:\Development\eclipse-jee-2024-09-R-win32-x86_64\eclipse"

  REM Shortcut for Starting Tomcat
  call :log "Creating shortcut for Start Tomcat"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Start Tomcat" -TargetPath "%DEVDIR%\apache-tomcat-11.0.2\bin\startup.bat" -WorkingDirectory "%DEVDIR%\apache-tomcat-11.0.2\bin"

  REM Shortcut for Stopping Tomcat
  call :log "Creating shortcut for Stop Tomcat"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Stop Tomcat" -TargetPath "%DEVDIR%\apache-tomcat-11.0.2\bin\shutdown.bat" -WorkingDirectory "%DEVDIR%\apache-tomcat-11.0.2\bin"

  REM Shortcut for Restarting Tomcat
  call :log "Creating shortcut for Restart Tomcat"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Restart Tomcat" -TargetPath "C:\Windows\System32\cmd.exe" -Arguments "/c %DEVDIR%\apache-tomcat-11.0.2\bin\shutdown.bat && %DEVDIR%\apache-tomcat-11.0.2\bin\startup.bat" -WorkingDirectory "%DEVDIR%\apache-tomcat-11.0.2"

  REM Shortcut for Tomcat Manager Web UI
  call :log "Creating shortcut for Tomcat Manager"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Tomcat Manager" -TargetPath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -WorkingDirectory "C:\Program Files (x86)\Microsoft\Edge\Application" -Arguments "http://localhost:8080/manager/html"

  REM Shortcut for Tomcat Homepage
  call :log "Creating shortcut for Tomcat Homepage"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Tomcat Homepage" -TargetPath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -WorkingDirectory "C:\Program Files (x86)\Microsoft\Edge\Application" -Arguments "http://localhost:8080/"

  REM Shortcut for Tomcat Logs Folder
  call :log "Creating shortcut for Tomcat Logs"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Tomcat Logs" -TargetPath "%DEVDIR%\apache-tomcat-11.0.2\logs"

  REM Shortcut for Tomcat Configuration (server.xml)
  call :log "Creating shortcut for Tomcat Config"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Tomcat Config" -TargetPath "C:\Program Files\Notepad++\notepad++.exe" -Arguments "%DEVDIR%\apache-tomcat-11.0.2\conf\server.xml"

  REM Set PATH

  set "NEW_PATH=!PATH!;!JAVA_HOME!\bin;!ANT_HOME!\bin;!MAVEN_HOME!\bin;C:\Program Files\7-Zip;C:\Program Files\Git\bin;C:\Program Files\Notepad++;C:\Development\eclipse-jee-2024-12-R-win32-x86_64\eclipse"
  set PATH=!NEW_PATH!
  setx PATH "!NEW_PATH!" /m
  call :log "PATH=!PATH!"

exit /b

REM *********************************************
REM
REM set_java_home
REM
REM *********************************************

:set_java_home

  REM Define the search term and specific directories to search
  set "search_term=java.exe"
  set "found_path="
  call :log "Searching for %search_term%"

  for %%D in ("C:\Program Files" "C:\Program Files (x86)" "C:\ProgramData" "C:\Users\%USERNAME%\AppData\Local\Programs") do (
      for /f "delims=" %%a in ('dir /s /b "%%~D\%search_term%" 2^>nul') do (
          set "found_path=%%~dpa"
          goto :FOUND_JAVA
      ) 
  )

  :NOT_FOUND
  call :log "%search_term% not found in likely directories"
  exit /b 1

  :FOUND_JAVA
  REM Trim "\bin\" from the found path using PowerShell
  for /f "delims=" %%A in ('powershell -NoProfile -Command "[regex]::Replace('%found_path%'.TrimEnd(), '\\bin[\\/]?\s*$', '')"') do set "found_path=%%A"

  REM Set JAVA_HOME and update PATH
  set JAVA_HOME=%found_path%
  setx JAVA_HOME "%found_path%" /m
  call :log "JAVA_HOME is set to %JAVA_HOME%"

exit /b

REM *********************************************
REM
REM set_desktop_prefs
REM
REM *********************************************

:set_desktop_prefs

  REM Enable File Extensions View
  call :log "Setting file extensions to be visible"
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f

  REM Enable Auto Arrange and Disable Align to Grid
  call :log "Setting desktop icons to auto sort"
  reg add "HKCU\Software\Microsoft\Windows\Shell\Bags\1\Desktop" /v "FFlags" /t REG_DWORD /d 1075839521 /f

  taskkill /f /im explorer.exe && start explorer.exe

exit /b

REM *********************************************
REM
REM set_endtime
REM
REM *********************************************

:set_endtime

  for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
     set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100" 
  )

exit /b

REM *********************************************
REM
REM calculate_elapsed_time
REM
REM *********************************************

:calculate_elapsed_time

  set /A elapsed=end-start

  REM Display the elapsed time
  set /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
  if %mm% lss 10 set mm=0%mm%
  if %ss% lss 10 set ss=0%ss%
  if %cc% lss 10 set cc=0%cc%
  call :log "Elapsed Time is %hh%:%mm%:%ss%.%cc%"

exit /b

REM *********************************************
REM
REM write_ip
REM
REM *********************************************

:write_ip

  for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /C:"IPv4 Address"') do (
    set ip=%%A
    set ip=!ip:~1!
    goto :found
  )

  :found
  REM Write IP to file
  (
    echo|set /p=!ip!
  ) > C:\common\sandbox_ip_address.txt
  call :log "IP Address is !ip!"

exit /b

REM *********************************************
REM
REM log
REM
REM *********************************************

:log

  echo [%date% %time%] %~1 >> "%LOGFILE%"

exit /b
