:: ====================================================================================
:: NIC_CONFIGURE.BAT
::
:: SYNOPSIS:
::     A robust batch script designed to streamline the configuration of Windows
::     network adapters (NICs) using `netsh` and `ipconfig`. This interactive tool
::     allows users to:
::         - Select and identify a network adapter
::         - Choose between DHCP, Static IP, or Predefined configurations
::         - Apply DNS settings manually or using trusted providers (Google, Cloudflare, OpenDNS)
::         - Display final NIC settings for verification
::
:: FEATURES:
::     - Interactive menus for adapter and configuration choices
::     - Strong input validation and error handling
::     - Admin rights verification for elevated commands
::     - Preset DNS options for convenience
::     - Clean exit flow and informative messages
::
:: USAGE FLOW:
::     1. Run as administrator.
::     2. Select NIC by menu or input custom name.
::     3. Choose DHCP, manual static IP, or predefined settings.
::     4. (If applicable) Pick DNS provider or enter manually.
::     5. Final configuration is displayed for confirmation.
::
:: REQUIREMENTS:
::     - Must be run with elevated (Administrator) privileges.
::     - Adapter names must match how they appear in system settings.
:: ====================================================================================
@echo off
setlocal EnableDelayedExpansion

:: ========== HEADER ==========
echo.
echo      -------------
echo      NIC CONFIGURE
echo      -------------
echo.
echo      Configure a network adapter without all the clicking.
echo.

:: ========== ADMIN CHECK ==========
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] This script must be run as administrator.
    pause
    exit /b
)

:: ========== ADAPTER SELECTION ==========
echo      Please choose which network adapter to configure:
echo.
echo           [1] Built In Ethernet
echo           [2] Built In WiFi
echo           [3] USB Ethernet Blue
echo           [4] USB Ethernet Green
echo           [5] USB Ethernet Yellow
echo           [6] USB Wifi Pink
echo           [7] USB Wifi Orange
echo           [8] Configure Another Adapter
echo.

:adapter_choice
SET /P C=[Select from 1 to 8]?
IF /I "%C%"=="1" SET NIC=Built In Ethernet & goto config_menu
IF /I "%C%"=="2" SET NIC=Built In WiFi & goto config_menu
IF /I "%C%"=="3" SET NIC=USB Ethernet Blue & goto config_menu
IF /I "%C%"=="4" SET NIC=USB Ethernet Green & goto config_menu
IF /I "%C%"=="5" SET NIC=USB Ethernet Yellow & goto config_menu
IF /I "%C%"=="6" SET NIC=USB Wifi Pink & goto config_menu
IF /I "%C%"=="7" SET NIC=USB Wifi Orange & goto config_menu
IF /I "%C%"=="8" (
    echo Adapter Name:
    set /p NIC=
    IF "!NIC!"=="" (
        echo [ERROR] Adapter name cannot be empty.
        goto adapter_choice
    )
    goto config_menu
)
echo [ERROR] Invalid selection.
goto adapter_choice

:: ========== CONFIGURATION TYPE ==========
:config_menu
echo.
echo      How do you want to configure the "%NIC%" NIC?
echo           [1] Set DHCP
echo           [2] Set Static IP Manually
echo           [3] Pre Defined Config
echo.

:config_choice
SET /P C=[Select from 1 to 3]?
IF /I "%C%"=="1" goto DHCP
IF /I "%C%"=="2" goto STATIC
IF /I "%C%"=="3" goto PREDEF
echo [ERROR] Invalid selection.
goto config_choice

:: ========== DHCP SETUP ==========
:DHCP
echo.
echo ----- Setting "%NIC%" to DHCP configuration -----
netsh interface ip set address "%NIC%" dhcp
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to set DHCP IP.
    goto end
)
netsh interface ip set dns "%NIC%" dhcp
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to set DHCP DNS.
    goto end
)
ipconfig /renew "%NIC%"
netsh int ip show config "%NIC%"
pause
goto end

:: ========== STATIC SETUP ==========
:STATIC
echo.
set /p IP_Addr=Enter Static IP Address:
IF "!IP_Addr!"=="" (
    echo [ERROR] IP address is required.
    goto STATIC
)
set /p D_Gate=Enter Default Gateway:
IF "!D_Gate!"=="" (
    echo [ERROR] Default Gateway is required.
    goto STATIC
)
set /p Sub_Mask=Enter Subnet Mask:
IF "!Sub_Mask!"=="" (
    echo [ERROR] Subnet Mask is required.
    goto STATIC
)

netsh interface ip set address "%NIC%" static !IP_Addr! !Sub_Mask! !D_Gate! 1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to apply static IP settings.
    goto end
)

echo.
SET /P C=Do you want to set DNS manually? [Y/N]:
IF /I "%C%"=="Y" goto SETDNS
IF /I "%C%"=="N" goto NODNS
echo [ERROR] Invalid input.
goto STATIC

:: ========== DNS PROVIDER SELECTION ==========
:SETDNS
echo.
echo      Choose a DNS provider:
echo           [1] Google DNS (8.8.8.8 / 8.8.4.4)
echo           [2] Cloudflare DNS (1.1.1.1 / 1.0.0.1)
echo           [3] OpenDNS (208.67.222.222 / 208.67.220.220)
echo           [4] Enter DNS manually
SET /P DNSOpt=Your choice [1-4]?

IF "%DNSOpt%"=="1" (
    SET P_DNS=8.8.8.8
    SET A_DNS=8.8.4.4
)
IF "%DNSOpt%"=="2" (
    SET P_DNS=1.1.1.1
    SET A_DNS=1.0.0.1
)
IF "%DNSOpt%"=="3" (
    SET P_DNS=208.67.222.222
    SET A_DNS=208.67.220.220
)
IF "%DNSOpt%"=="4" (
    set /p P_DNS=Enter Primary DNS:
    IF "!P_DNS!"=="" (
        echo [ERROR] Primary DNS is required.
        goto SETDNS
    )
    set /p A_DNS=Enter Alternate DNS:
    IF "!A_DNS!"=="" (
        echo [ERROR] Alternate DNS is required.
        goto SETDNS
    )
)

netsh interface ip set dns "%NIC%" static !P_DNS!
netsh interface ip add dns "%NIC%" !A_DNS! index=2
goto SHOWCONF

:NODNS
echo Skipping DNS setup.
goto SHOWCONF

:: ========== SHOW FINAL CONFIG ==========
:SHOWCONF
echo.
netsh int ip show config "%NIC%"
pause
goto end

:: ========== PREDEFINED CONFIG ==========
:PREDEF
echo.
echo      Choose a config to apply:
echo           [1] 192.168.0.253/24, Gateway .254
echo           [2] 192.168.1.253/24, Gateway .254
echo           [3] 192.168.2.253/24, Gateway .254
echo.

:predef_choice
SET /P C=[Select from 1 to 3]?
IF /I "%C%"=="1" SET IP=192.168.0.253 & SET GW=192.168.0.254 & goto APPLY_PREDEF
IF /I "%C%"=="2" SET IP=192.168.1.253 & SET GW=192.168.1.254 & goto APPLY_PREDEF
IF /I "%C%"=="3" SET IP=192.168.2.253 & SET GW=192.168.2.254 & goto APPLY_PREDEF
echo [ERROR] Invalid selection.
goto predef_choice

:APPLY_PREDEF
netsh interface ip set address "%NIC%" static %IP% 255.255.255.0 %GW%
netsh interface ip set dns "%NIC%" static none
netsh int ip show config "%NIC%"
pause
goto end

:: ========== END ==========
:end
echo.
echo NIC Configuration Complete.
endlocal
exit /b