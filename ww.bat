:: ww - The multiple-workspace batch script
::
:: Minimum folder structure for an environment:
:: - env_number
::     - aa_conf
::         - aasimar10.conf
::     - envs
::     - Projects
::     - tmp
::
:: Environment variables that can be previously defined (suggestion: define them as system variables)
:: For more information, see :DEFINE_GLOBAL_VARIABLES function in this file.
::
:: WW_DEFAULT_VOLUME:  Default volume to be used in ww.
:: WW_SHARED_DIR:      Point to PATH of Shared used by aa.
:: WW_PROJECTS_SUBDIR: Subdirectory of workspace where projects are clones.
:: WW_QUIET:           If defined, ww will not print normal messages (only error ones).

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
setlocal
call :DEFINE_GLOBAL_VARIABLES
goto PARSE_ARGS


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:PARSE_ARGS
:: if no args and no current workspace, Show help
if [%1] equ [] if [%WW_CURRENT_WORKSPACE%] == [] goto USAGE

:: if args == --help or args == -h, Show help
if [%1] equ [--help] goto USAGE
if [%1] equ [-h] goto USAGE

:: if args == --create <env_number> or args == -c <env_number>, createn env
if [%1] equ [--create] goto CREATE_ENV
if [%1] equ [-c] goto CREATE_ENV

:: No args: Show current env
if [%1] equ [] goto SHOW_CURRENT_WORKSPACE

:: Finally, has args and are none of the above, assume that have passed the workspace as argument
goto SETUP_WORKSPACE


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:DEFINE_GLOBAL_VARIABLES
if not defined WW_PROJECTS_SUBDIR set WW_PROJECTS_SUBDIR=Projects
if not defined WW_DEFAULT_VOLUME set WW_DEFAULT_VOLUME=W
if not defined WW_SHARED_DIR set WW_SHARED_DIR=%WW_DEFAULT_VOLUME%:\Shared

exit /b 0


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CREATE_ENV
:: if args[2] == '', Show help
if [%2] equ [] (
    echo Expected workspace as second parameter. Example: ww --create 99
    exit /b 1
)

set _NEW_WORKSPACE=%WW_DEFAULT_VOLUME%:\%2%
set _PROJECTS_DIR=%_NEW_WORKSPACE%\%WW_PROJECTS_SUBDIR%
set _TMP_DIR=%_NEW_WORKSPACE%\tmp
set _CONDA_ENVS_PATH_DIR=%_NEW_WORKSPACE%\envs

mkdir %_NEW_WORKSPACE% 2> NUL
mkdir %_NEW_WORKSPACE%\aa_conf 2> NUL
mkdir %_PROJECTS_DIR% 2> NUL
mkdir %_TMP_DIR% 2> NUL
mkdir %_CONDA_ENVS_PATH_DIR% 2> NUL

goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SETUP_WORKSPACE

set _WW_WORKSPACE=%1
if not exist %_WW_WORKSPACE%\ if exist D:\%_WW_WORKSPACE%\ set _WW_WORKSPACE=D:\%_WW_WORKSPACE%
if not exist %_WW_WORKSPACE%\ if exist C:\%_WW_WORKSPACE%\ set _WW_WORKSPACE=C:\%_WW_WORKSPACE%
if not exist %_WW_WORKSPACE%\ goto PATH_ERROR
:: Change WW_CURRENT_WORKSPACE to absolute PATH, if it is still relative
for /F "tokens=* delims=\" %%i in ("%_WW_WORKSPACE%") do set "WW_CURRENT_WORKSPACE=%%~fi"

if not defined WW_QUIET echo Initializing workspace %WW_CURRENT_WORKSPACE%...

set WW_PROJECTS_DIR=%WW_CURRENT_WORKSPACE%\%WW_PROJECTS_SUBDIR%

:: Temporary folder will be overriden
set TMP=%WW_CURRENT_WORKSPACE%\tmp
set TEMP=%TMP%
if not defined WW_QUIET echo TMP and TEMP variables have been updated!

:: Aasimar uses this configuration file to keep track of some env variables, so we need to make
:: sure it won't use any global configuration file
set AA_CONFIG_FILE=%WW_CURRENT_WORKSPACE%\aa_conf\aasimar10.conf
if not exist %AA_CONFIG_FILE% (
    (
        echo [system]
        echo flags = LIST:conda
        echo platform = STRING:win64
        echo projects_dir = PATH:%WW_PROJECTS_DIR%
        echo shared_dir = PATH:%WW_SHARED_DIR%
    ) > %AA_CONFIG_FILE%
)
if not defined WW_QUIET echo AA_CONFIG_FILE variable have been updated!

:: Update global conda envs path variable so that we isolate the workspace environment
set CONDA_ENVS_PATH=%WW_CURRENT_WORKSPACE%\envs
if not defined WW_QUIET echo CONDA_ENVS_PATH variable have been updated!

:: Isolate conda configuration file
set "CONDARC=%WW_CURRENT_WORKSPACE%\.condarc"

:: Create it copying from the root, if it doesn't already exist
if not exist "%CONDARC%" for /F %%i in ('conda info --root') do copy "%%i\.condarc" "%CONDARC%" > NUL

where RenameTab > NUL 2>&1
if not errorlevel 1 call RenameTab [%WW_CURRENT_WORKSPACE%]

:: That's it :)
if not defined WW_QUIET echo Ready to work!

:: Export variables
endlocal & (
    set WW_CURRENT_WORKSPACE=%WW_CURRENT_WORKSPACE%
    set TMP=%TMP%
    set TEMP=%TEMP%
    set WW_PROJECTS_DIR=%WW_PROJECTS_DIR%
    set AA_CONFIG_FILE=%AA_CONFIG_FILE%
    set CONDA_ENVS_PATH=%CONDA_ENVS_PATH%
    set CONDARC=%CONDARC%
)

cd /d %WW_PROJECTS_DIR%

goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:PATH_ERROR
echo Could not find path %_WW_WORKSPACE% (or variants)
exit /b 1

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SHOW_CURRENT_WORKSPACE
echo Current workspace:  %WW_CURRENT_WORKSPACE%
echo WW_DEFAULT_VOLUME:  %WW_DEFAULT_VOLUME%
echo WW_SHARED_DIR:      %WW_SHARED_DIR%
echo WW_PROJECTS_SUBDIR: %WW_PROJECTS_SUBDIR%
echo WW_QUIET:           %WW_QUIET%
echo.
conda info
mu status
goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:USAGE
echo Usage: %0 [OPTION] workspace_path_or_number
echo ww - The multiple-workspace batch script
echo.
echo ^-c, --create       Create a new workspace folder structure in the given ^<number^>
echo ^-h, --help         Show this help
echo.
echo Examples:
echo %0 -c 99
echo %0 9
echo.
goto :eof
