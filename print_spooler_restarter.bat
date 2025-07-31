:: ============================================================================
:: PRINT SPOOLER RESTARTER SCRIPT (Enhanced Version)
:: ----------------------------------------------------------------------------
:: This script performs the following operations:
:: - Verifies that it's running with administrative privileges
:: - Stops the Print Spooler service
:: - Waits for 5 seconds before restarting the service
:: - Restarts the Print Spooler service
:: - Provides error feedback if any service command fails
:: ============================================================================

@echo off

:: --- Check for administrative rights ---
:: net session requires admin; if command fails, exit the script
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo This script must be run as administrator.
    pause
    exit /b
)

:: --- Display header section ---
echo.
echo      ----------------------------
echo      PRINT SPOOLER RESTARTER TOOL
echo      ----------------------------
echo.

:: --- Stop the Print Spooler service ---
echo     Stopping print spooler...
net stop spooler
IF %ERRORLEVEL% NEQ 0 (
    echo     ERROR: Failed to stop Print Spooler.
    goto End
)

:: --- Brief pause before restarting ---
echo     Waiting 5 seconds before restarting...
timeout /t 5 /nobreak >nul

:: --- Start the Print Spooler service ---
echo     Starting print spooler...
net start spooler
IF %ERRORLEVEL% NEQ 0 (
    echo     ERROR: Failed to start Print Spooler.
    goto End
)

:: --- Success message ---
echo     Print Spooler successfully restarted.

:End
:: --- Final prompt to keep script window open ---
echo.
set /P DUMMY=Press ENTER to continue...