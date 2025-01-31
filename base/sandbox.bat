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
call :set_java_home
call :set_desktop_prefs
call :set_endtime
call :calculate_elapsed_time
call :reset_desktop

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

  set SANDBOX_DIR=C:\sandbox
  set COMMON_DIR=C:\common
  set CONFIGS_DIR=%SANDBOX_DIR%\configs
  set INSTALLERS_DIR=%SANDBOX_DIR%\installers
  set CONFIG_FILE=%CONFIGS_DIR%\sandbox.properties
  set LOGFILE=%SANDBOX_DIR%\logs\sandbox.log

  del %LOGFILE% > nul 2>&1 

  start powershell -NoExit -Command "Get-Content -Path '%LOGFILE%' -Wait"

  call :log "SANDBOX_DIR=%SANDBOX_DIR%"
  call :log "COMMON_DIR=%COMMON_DIR%"
  call :log "CONFIGS_DIR=%CONFIGS_DIR%"
  call :log "INSTALLERS_DIR=%INSTALLERS_DIR%"
  call :log "CONFIG_FILE=%CONFIG_FILE%"
  call :log "LOGFILE=%LOGFILE%"

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

  REM Shortcut for 7-Zip
  call :log "Creating shortcut for 7zip"
  powershell -ExecutionPolicy Bypass -File "%COMMON_DIR%\create_desktop_shortcut.ps1" -ShortcutName "7-Zip" -TargetPath "C:\Program Files\7-Zip\7zFM.exe"

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

  set PATH=%PATH%;%JAVA_HOME%\bin
  setx PATH "%PATH%" /m
  call :log "PATH is updated to include %JAVA_HOME%\bin"

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

  REM Set desktop background to black
  call :log "Setting desktop background to black"
  reg add "HKCU\Control Panel\Colors" /v Background /t REG_SZ /d "0 0 0" /f > nul 2>&1
  reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "" /f > nul 2>&1
  reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 0 /f > nul 2>&1
  reg add "HKCU\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d 0 /f > nul 2>&1

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
REM reset_desktop
REM
REM *********************************************

:reset_desktop

  taskkill /IM explorer.exe /F > nul 2>&1
  start explorer.exe >> %LOGFILE% 2>&1

exit /b

REM *********************************************
REM
REM log
REM
REM *********************************************

:log

  echo [%date% %time%] %~1 >> "%LOGFILE%"

exit /b
