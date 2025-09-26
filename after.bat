@echo off

echo Removing placeholder file if exists...
DEL D:\tar-surge-client\Thickclient\placeholder.txt

set "folder=D:\tar-surge-client"  REM Change this to your target folder

if not exist "%folder%" (
    echo Folder does not exist. Creating it now...
    mkdir "%folder%"
) else (
    echo Folder exists, deleting files...
    del /q "%folder%\*.*"
    echo Cleanup complete!
)

REM Move files from staging to final destination without keeping the "Thickclient" subfolder
echo "Moving files from staging to final destination..."
robocopy D:\tar-surgeclient-staging\Thickclient D:\tar-surge-client\Thickclient /E /MOVE

echo "Files moved successfully."


exit 0
