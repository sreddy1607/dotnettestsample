@echo off

REM Ensure that surge-client directory is empty before deploying files
echo "Cleaning up previous deployment..."
DEL /S /Q D:\tar-surge-client\*

echo "Cleanup completed."
exit 0
