@echo off
setlocal enabledelayedexpansion

set "PT_DIR=%~dp0"
set "ZIP_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
set "TEMP_ZIP=%TEMP%\pt_latest.zip"
set "EXTRACT_TEMP=%TEMP%\pt_extracted"
set "ETAG_FILE=%PT_DIR%.latest_etag"

echo ===================================================
echo     Android Platform-Tools Auto-Updater
echo ===================================================
echo Directory: "%PT_DIR%"
echo.

echo [1/3] Checking Google servers for updates...
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ^
    "$req = [System.Net.HttpWebRequest]::Create('%ZIP_URL%'); $req.Method = 'HEAD'; $res = $req.GetResponse(); $res.Headers['ETag']; $res.Close()"`) do (
    set "REMOTE_ETAG=%%I"
)

if not defined REMOTE_ETAG (
    echo [ERROR] Could not fetch version information from Google servers.
    echo Check your internet connection and try again.
    goto :END
)

set "LOCAL_ETAG="
if exist "%ETAG_FILE%" (
    set /p LOCAL_ETAG=<"%ETAG_FILE%"
)

if defined LOCAL_ETAG (
    if "%LOCAL_ETAG%"=="%REMOTE_ETAG%" (
        echo.
        echo [SUCCESS] Platform-Tools is already up to date!
        goto :END
    )
)

echo [INFO] New version found or local version tag missing.
echo.

echo [2/3] Downloading latest Platform-Tools...
powershell -NoProfile -Command ^
    "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%TEMP_ZIP%' -UseBasicParsing"

if not exist "%TEMP_ZIP%" (
    echo [ERROR] Download failed.
    goto :END
)

echo [3/3] Updating files...

if exist "%EXTRACT_TEMP%" rmdir /s /q "%EXTRACT_TEMP%"

powershell -NoProfile -Command ^
    "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%EXTRACT_TEMP%' -Force"

if exist "%EXTRACT_TEMP%\platform-tools" (
    xcopy "%EXTRACT_TEMP%\platform-tools\*" "%PT_DIR%" /E /Y /Q >nul
    echo "%REMOTE_ETAG%">"%ETAG_FILE%"
    echo [SUCCESS] Platform-Tools successfully updated!
) else (
    echo [ERROR] Extraction failed or archive structure unexpectedly changed.
)

echo Cleaning up temporary files...
if exist "%TEMP_ZIP%" del /q "%TEMP_ZIP%"
if exist "%EXTRACT_TEMP%" rmdir /s /q "%EXTRACT_TEMP%"

:END
echo.
echo Press any key to exit...
pause >nul
