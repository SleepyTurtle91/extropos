@echo off
REM ADB Setup Script for FlutterPOS
REM Add ADB to PATH for easy access

set ADB_PATH=%LOCALAPPDATA%\Android\sdk\platform-tools
set PATH=%PATH%;%ADB_PATH%

echo ADB is now available in this command prompt.
echo You can run commands like:
echo   adb devices
echo   adb logcat
echo   adb shell
echo.
echo Your connected device:
adb devices
echo.
echo Device info:
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
echo.
echo To run Flutter on your tablet:
echo   flutter run -d 8bab44b57d88