@echo off
setlocal enabledelayedexpansion

REM Define variables
set SANDBOX_IP_FILE=sandbox_ip_address.txt
set LISTEN_PORT=8080
set LOG_FILE=proxy_info.txt

REM Ensure the sandbox IP file exists
if not exist "%SANDBOX_IP_FILE%" (
    echo [ERROR] Sandbox IP file not found! > "%LOG_FILE%"
    echo Make sure %SANDBOX_IP_FILE% exists.
    exit /b
)

REM Read Sandbox IP from file
set /p SANDBOX_IP=<%SANDBOX_IP_FILE%

REM Validate that an IP was retrieved
if "%SANDBOX_IP%"=="" (
    echo [ERROR] Sandbox IP is empty! > "%LOG_FILE%"
    exit /b
)

REM Get the Laptop's Local IP Address (First non-loopback IPv4)
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /C:"IPv4 Address"') do (
    set LAPTOP_IP=%%A
    set LAPTOP_IP=!LAPTOP_IP:~1!
    goto :found
)

:found
REM Validate that the laptop IP was retrieved
if "%LAPTOP_IP%"=="" (
    echo [ERROR] Could not determine Laptop IP! > "%LOG_FILE%"
    exit /b
)

REM Handle add or remove command
if "%1"=="add" (
    echo Adding port proxy from %LAPTOP_IP%:%LISTEN_PORT% to %SANDBOX_IP%:%LISTEN_PORT%...
    netsh interface portproxy add v4tov4 listenport=%LISTEN_PORT% listenaddress=%LAPTOP_IP% connectport=%LISTEN_PORT% connectaddress=%SANDBOX_IP%
    echo %DATE% %TIME% - Added Proxy from %LAPTOP_IP%:%LISTEN_PORT% to %SANDBOX_IP%:%LISTEN_PORT% > "%LOG_FILE%"
    netsh interface portproxy show all >> "%LOG_FILE%"
    echo Proxy added successfully!
    exit /b
)

if "%1"=="remove" (
    echo Removing port proxy from %LAPTOP_IP%:%LISTEN_PORT%...
    netsh interface portproxy delete v4tov4 listenport=%LISTEN_PORT% listenaddress=%LAPTOP_IP%
    echo %DATE% %TIME% - Removed Proxy from %LAPTOP_IP%:%LISTEN_PORT% > "%LOG_FILE%"
    echo Proxy removed successfully!
    exit /b
)

REM Show usage if no valid argument is passed
echo Usage: %0 [add | remove]
exit /b
