@echo off
REM FlutterPOS - Build Script for Product Flavors (Windows Batch)
REM Usage: build_flavors.bat [pos|kds|backend|dealer|all] [debug|release]

setlocal enabledelayedexpansion

set FLAVOR=all
set BUILD_TYPE=release

if "%~1" neq "" set FLAVOR=%~1
if "%~2" neq "" set BUILD_TYPE=%~2

REM Validate inputs
if "%FLAVOR%" neq "pos" (
    if "%FLAVOR%" neq "kds" (
        if "%FLAVOR%" neq "backend" (
            if "%FLAVOR%" neq "dealer" (
                if "%FLAVOR%" neq "frontend" (
                    if "%FLAVOR%" neq "all" (
                        echo Error: Invalid flavor '%FLAVOR%'. Use: pos, kds, backend, dealer, frontend, or all
                        exit /b 1
                    )
                )
            )
        )
    )
)

if "%BUILD_TYPE%" neq "debug" (
    if "%BUILD_TYPE%" neq "release" (
        echo Error: Invalid build type '%BUILD_TYPE%'. Use: debug or release
        exit /b 1
    )
)

echo ╔════════════════════════════════════════╗
echo ║   FlutterPOS Flavor Build Script      ║
echo ╚════════════════════════════════════════╝
echo.

REM Get version from pubspec.yaml
for /f "tokens=2 delims=:" %%i in ('findstr "version:" pubspec.yaml') do set VERSION_LINE=%%i
for /f "tokens=1 delims=+" %%i in ("%VERSION_LINE%") do set VERSION=%%i
set VERSION=%VERSION% 

REM Get date
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set DATE=%%c%%a%%b

if "%FLAVOR%"=="pos" goto build_pos
if "%FLAVOR%"=="kds" goto build_kds
if "%FLAVOR%"=="backend" goto build_backend
if "%FLAVOR%"=="dealer" goto build_dealer
if "%FLAVOR%"=="frontend" goto build_frontend

REM Build all
call :build_pos
echo.
call :build_kds
echo.
call :build_backend
echo.
call :build_dealer
echo.
call :build_frontend
goto end

:build_pos
echo Building POS App (%BUILD_TYPE%)...
flutter build apk --%BUILD_TYPE% --flavor posApp --target lib/main.dart
if %errorlevel% equ 0 (
    echo ✓ POS App built successfully!
    set APK_PATH=build\app\outputs\flutter-apk\app-posapp-%BUILD_TYPE%.apk
    for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
    set /a APK_SIZE_MB=!APK_SIZE!/1048576
    echo   Location: !APK_PATH!
    echo   Size: !APK_SIZE_MB! MB
    
    REM Copy to desktop
    set DESKTOP_APK=%USERPROFILE%\Desktop\FlutterPOS-!VERSION!-%DATE%-pos.apk
    copy "!APK_PATH!" "!DESKTOP_APK!"
    echo   Copied to: !DESKTOP_APK!
) else (
    echo ✗ POS App build failed!
)
goto :eof

:build_kds
echo Building KDS App (%BUILD_TYPE%)...
flutter build apk --%BUILD_TYPE% --flavor kdsApp --target lib/main_kds.dart
if %errorlevel% equ 0 (
    echo ✓ KDS App built successfully!
    set APK_PATH=build\app\outputs\flutter-apk\app-kdsapp-%BUILD_TYPE%.apk
    for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
    set /a APK_SIZE_MB=!APK_SIZE!/1048576
    echo   Location: !APK_PATH!
    echo   Size: !APK_SIZE_MB! MB
    
    REM Copy to desktop
    set DESKTOP_APK=%USERPROFILE%\Desktop\FlutterPOS-!VERSION!-%DATE%-kds.apk
    copy "!APK_PATH!" "!DESKTOP_APK!"
    echo   Copied to: !DESKTOP_APK!
) else (
    echo ✗ KDS App build failed!
)
goto :eof

:build_backend
echo Building Backend App (%BUILD_TYPE%)...
flutter build web --%BUILD_TYPE% --target lib/main_backend.dart --no-tree-shake-icons
if %errorlevel% equ 0 (
    echo ✓ Backend App built successfully!
    set WEB_PATH=build\web
    echo   Location: !WEB_PATH!
    
    REM Copy to desktop
    set DESKTOP_WEB=%USERPROFILE%\Desktop\FlutterPOS-!VERSION!-%DATE%-backend-web
    xcopy "!WEB_PATH!" "!DESKTOP_WEB!\" /E /I /H /Y
    echo   Copied to: !DESKTOP_WEB!
) else (
    echo ✗ Backend App build failed!
)
goto :eof

:build_dealer
echo Building Dealer Portal App (%BUILD_TYPE%)...
flutter build web --%BUILD_TYPE% --target lib/main_dealer.dart
if %errorlevel% equ 0 (
    echo ✓ Dealer Portal App built successfully!
    set WEB_PATH=build\web
    echo   Location: !WEB_PATH!
    
    REM Copy to desktop
    set DESKTOP_WEB=%USERPROFILE%\Desktop\FlutterPOS-!VERSION!-%DATE%-dealer-web
    xcopy "!WEB_PATH!" "!DESKTOP_WEB!\" /E /I /H /Y
    echo   Copied to: !DESKTOP_WEB!
) else (
    echo ✗ Dealer Portal App build failed!
)
goto :eof

:build_frontend
echo Building Frontend Customer App (%BUILD_TYPE%)...
flutter build apk --%BUILD_TYPE% --flavor frontendApp --target lib/main_frontend.dart
if %errorlevel% equ 0 (
    echo ✓ Frontend Customer App built successfully!
    set APK_PATH=build\app\outputs\flutter-apk\app-frontendapp-%BUILD_TYPE%.apk
    for %%A in ("%APK_PATH%") do set APK_SIZE=%%~zA
    set /a APK_SIZE_MB=!APK_SIZE!/1048576
    echo   Location: !APK_PATH!
    echo   Size: !APK_SIZE_MB! MB
    
    REM Copy to desktop
    set DESKTOP_APK=%USERPROFILE%\Desktop\FlutterPOS-!VERSION!-%DATE%-frontend.apk
    copy "!APK_PATH!" "!DESKTOP_APK!"
    echo   Copied to: !DESKTOP_APK!
) else (
    echo ✗ Frontend Customer App build failed!
)
goto :eof

:end
echo.
echo ╔════════════════════════════════════════╗
echo   Build completed
echo ╚════════════════════════════════════════╝

REM List APKs
echo.
echo Available APKs:
if exist "build\app\outputs\flutter-apk\app-*-%BUILD_TYPE%.apk" (
    for %%f in (build\app\outputs\flutter-apk\app-*-%BUILD_TYPE%.apk) do (
        for %%A in ("%%f") do set APK_SIZE=%%~zA
        set /a APK_SIZE_MB=!APK_SIZE!/1048576
        echo   %%~nf%%~xf (!APK_SIZE_MB! MB)
    )
) else (
    echo No APKs found
)