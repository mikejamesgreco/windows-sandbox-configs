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

  REM Install Software 

  REM Install WinGet
  call :log "Calling install_winget.bat"
  start /min /wait cmd /c "%COMMON_DIR%\install_winget.bat %SANDBOX_DIR%\logs\install_winget.log >> %LOGFILE% 2>&1"

  REM Reset msstore source (only if needed)
  winget source reset --name msstore > nul

  REM Install 7zip using winget
  call :log "Installing 7zip"
  winget install -e --id 7zip.7zip -h --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "7zip installation failed with error code %errorlevel%"

  REM Install JQ using winget
  call :log "Installing JQ"
  winget install -e --id jqlang.jq -h --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "JQ installation failed with error code %errorlevel%"

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
  
  REM Install ApacheDS
  call :log "Installing ApacheDS (apacheds-2.0.0.AM27)"
  copy "%COMMON_DIR%\apacheds-2.0.0.AM27.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\apacheds-2.0.0.AM27.zip" -o"%DEVDIR%\apacheds-2.0.0.AM27" -y > nul 2>&1
  if %errorlevel% neq 0 call :log "ApacheDS installation failed with error code %errorlevel%"
  REM Desktop shortcuts

  REM Install Apache Directory Studio
  call :log "Installing Apache Directory Studio"
  winget install -e --id Apache.DirectoryStudio -h --scope machine --accept-source-agreements --silent > nul 2>&1
  if %errorlevel% neq 0 call :log "Apache Directory Studio installation failed with error code %errorlevel%"

  REM Install Keycloak
  call :log "Installing Keycloak (keycloak-26.1.3)"
  copy "%COMMON_DIR%\keycloak-26.1.3.zip" %DEVDIR%
  "C:\Program Files\7-Zip\7z.exe" x "%DEVDIR%\keycloak-26.1.3.zip" -o"%DEVDIR%\keycloak-26.1.3" -y > nul 2>&1
  copy "%COMMON_DIR%\apacheds-keycloak-realm.json" %DEVDIR% > nul 2>&1
  if %errorlevel% neq 0 call :log "Keycloak installation failed with error code %errorlevel%"

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

  REM Shortcut for Eclipse
  call :log "Creating shortcut for Eclipse"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Eclipse" -TargetPath "C:\Development\eclipse-jee-2024-12-R-win32-x86_64\eclipse\eclipse.exe" -WorkingDirectory "C:\Development\eclipse-jee-2024-09-R-win32-x86_64\eclipse"

  REM Shortcut for ApacheDS start
  call :log "Creating shortcut for ApacheDS start"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Start ApacheDS" -TargetPath "C:\Development\apacheds-2.0.0.AM27\apacheds-2.0.0.AM28-SNAPSHOT\bin\apacheds.bat" -WorkingDirectory "C:\Development\apacheds-2.0.0.AM27\apacheds-2.0.0.AM28-SNAPSHOT\bin" -Arguments "default start"

  REM Shortcut for ApacheDS stop
  call :log "Creating shortcut for ApacheDS stop"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Stop ApacheDS" -TargetPath "C:\Development\apacheds-2.0.0.AM27\apacheds-2.0.0.AM28-SNAPSHOT\bin\apacheds.bat" -WorkingDirectory "C:\Development\apacheds-2.0.0.AM27\apacheds-2.0.0.AM28-SNAPSHOT\bin" -Arguments "default stop"

  REM Shortcut for Viewing ApacheDS Logs
  call :log "Creating shortcut for ApacheDS logs"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "ApacheDS Logs" -TargetPath "C:\Program Files\Notepad++\Notepad++.exe" -Arguments "C:\Development\apacheds-2.0.0.AM27\apacheds-2.0.0.AM28-SNAPSHOT\instances\default\log\apacheds.log"

  REM Shortcut to Open Apache Directory Studio
  call :log "Creating shortcut for Apache Directory Studio"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Apache Directory Studio" -TargetPath "C:\Program Files\Apache Directory Studio\ApacheDirectoryStudio.exe"

  REM Shortcut for Keycloak Start
  call :log "Creating shortcut for Keycloak Start"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Start Keycloak" -TargetPath "C:\Development\keycloak-26.1.3\keycloak-26.1.3\bin\kc.bat" -WorkingDirectory "C:\Development\keycloak-26.1.3\keycloak-26.1.3\bin" -Arguments "start-dev"

  REM Shortcut for Keycloak Stop
  call :log "Creating shortcut for Keycloak Stop"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Stop Keycloak" -TargetPath "C:\Windows\System32\taskkill.exe" -Arguments "/F /IM java.exe"

  REM Shortcut for Keycloak Admin Panel
  call :log "Creating shortcut for Keycloak Admin Panel"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "Keycloak Admin Panel" -TargetPath "C:\Windows\System32\cmd.exe" -Arguments "/c start http://localhost:8080/admin"

  REM Default admin connection to ApacheDS can be imported with the following file:
  REM C:\Common\ApacheDS_Connection.lbc
  REM Host: localhost
  REM Port: 10389
  REM Bind DN or user: uid=admin,ou=system
  REM Bind password  : secret

  REM bootstramp keycloak with this command:
  REM C:\Development\keycloak-26.1.3\keycloak-26.1.3\bin\kc.bat bootstrap-admin user --user admin --password admin
  REM or set these to env vars
  REM setx KC_BOOTSTRAP_ADMIN_USERNAME admin /m
  REM setx KC_BOOTSTRAP_ADMIN_PASSWORD admin /m

  REM Set keycloak admin user and password

  call :log "Set keycloak admin password"
  set KC_BOOTSTRAP_ADMIN_USERNAME=admin
  set KC_BOOTSTRAP_ADMIN_PASSWORD=admin
  setx KC_BOOTSTRAP_ADMIN_USERNAME "admin" /m
  setx KC_BOOTSTRAP_ADMIN_PASSWORD "admin" /m

  REM Set PATH

  set "NEW_PATH=!PATH!;!JAVA_HOME!\bin;C:\Program Files\7-Zip;C:\Program Files\Git\bin;C:\Program Files\Notepad++;C:\Development\eclipse-jee-2024-12-R-win32-x86_64\eclipse"
  set PATH=!NEW_PATH!
  setx PATH "!NEW_PATH!" /m
  call :log "PATH=!PATH!"

  REM Post steps
  REM Start ApacheDS
  REM Start Apache Directory Studio
  REM Import ApacheDS_Connection.ldc connection info
  REM Import ou-users.ldif and users.ldif into apacheds
  REM Running keycloak startup (be sure to start apacheds first)
  REM Create a new realm by importing C:\Development\example-realm.json (this will wire together ldap including ldap attr mapping and set up a springboot-api example)

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
REM log
REM
REM *********************************************

:log

  echo [%date% %time%] %~1 >> "%LOGFILE%"

exit /b
