@echo off
setlocal enabledelayedexpansion

rem Get sunshine root directory
for %%I in ("%~dp0\..") do set "ROOT_DIR=%%~fI"

set SERVICE_NAME=SunshineService
set "SERVICE_BIN=%ROOT_DIR%\tools\sunshinesvc.exe"
set "SERVICE_CONFIG_DIR=%ProgramData%\Sunshine-ASC"
set "SERVICE_CONFIG_FILE=%SERVICE_CONFIG_DIR%\service_start_type.txt"
set "LEGACY_CONFIG_FILE=%LOCALAPPDATA%\LizardByte\Sunshine\service_start_type.txt"
if not exist "%SERVICE_CONFIG_FILE%" if exist "%LEGACY_CONFIG_FILE%" set "SERVICE_CONFIG_FILE=%LEGACY_CONFIG_FILE%"
set "SYSTEM_LEGACY_CONFIG_FILE=%SystemRoot%\System32\config\systemprofile\AppData\Local\LizardByte\Sunshine\service_start_type.txt"
if not exist "%SERVICE_CONFIG_FILE%" if exist "%SYSTEM_LEGACY_CONFIG_FILE%" set "SERVICE_CONFIG_FILE=%SYSTEM_LEGACY_CONFIG_FILE%"

rem Set service to demand start. It will be changed to auto later if the user selected that option.
set SERVICE_START_TYPE=demand

rem Remove the legacy SunshineSvc service
net stop sunshinesvc
sc delete sunshinesvc

rem Check if SunshineService already exists
sc qc %SERVICE_NAME% > nul 2>&1
if %ERRORLEVEL%==0 (
    rem Stop the existing service if running
    net stop %SERVICE_NAME%

    rem Reconfigure the existing service
    set SC_CMD=config
) else (
    rem Create a new service
    set SC_CMD=create
)

rem Check if we have a saved start type from previous installation
if exist "%SERVICE_CONFIG_FILE%" (
    rem Debug output file content
    type "%SERVICE_CONFIG_FILE%"

    rem Read the saved start type
    for /f "usebackq delims=" %%a in ("%SERVICE_CONFIG_FILE%") do (
        set "SAVED_START_TYPE=%%a"
    )

    echo Raw saved start type: [!SAVED_START_TYPE!]

    rem Check start type
    if "!SAVED_START_TYPE!"=="2-delayed" (
        set SERVICE_START_TYPE=delayed-auto
    ) else if "!SAVED_START_TYPE!"=="2" (
        set SERVICE_START_TYPE=auto
    ) else if "!SAVED_START_TYPE!"=="3" (
        set SERVICE_START_TYPE=demand
    ) else if "!SAVED_START_TYPE!"=="4" (
        set SERVICE_START_TYPE=disabled
    )

    del "%SERVICE_CONFIG_FILE%"
)

echo Setting service start type set to: [!SERVICE_START_TYPE!]

rem Retry service registration if Windows is still deleting the previous service
set /a WAIT_COUNT=0
:register_service
rem Recheck service existence because deletion may finish between retries
sc qc %SERVICE_NAME% >nul 2>&1
if errorlevel 1 (
    set "SC_CMD=create"
) else (
    set "SC_CMD=config"
)
sc !SC_CMD! %SERVICE_NAME% binPath= "\"%SERVICE_BIN%\"" start= %SERVICE_START_TYPE% DisplayName= "Sunshine Service" > "%TEMP%\sunshine-service-register.log" 2>&1
if not errorlevel 1 goto service_registered

findstr /C:"1072" /C:"1073" "%TEMP%\sunshine-service-register.log" >nul
if errorlevel 1 (
    type "%TEMP%\sunshine-service-register.log"
    echo ERROR: Failed to create or configure SunshineService.
    exit /b 1
)
if !WAIT_COUNT! GEQ 15 (
    type "%TEMP%\sunshine-service-register.log"
    echo ERROR: SunshineService remained marked for deletion.
    exit /b 1
)
ping -n 2 127.0.0.1 >nul
set /a WAIT_COUNT+=1
goto register_service

:service_registered
del "%TEMP%\sunshine-service-register.log" >nul 2>&1

rem Set the description of the service
sc description %SERVICE_NAME% "Sunshine is a self-hosted game stream host for Moonlight."

rem Start the new service unless it is configured as disabled
if /I "!SERVICE_START_TYPE!"=="disabled" exit /b 0
net start %SERVICE_NAME%
if errorlevel 1 (
    echo ERROR: Failed to start SunshineService.
    exit /b 1
)
exit /b 0
