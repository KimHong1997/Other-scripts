@echo off

echo Attempting to kill XAMPP control panel
taskkill /im xampp-control.exe /f

echo Attempting to stop Mysql
echo Please close this command only for Shutdown
echo Mysql is stopping ...

xampp-control stop mysql

echo Attempting to stop Apache
echo Please close this command only for Shutdown
echo Apache 2 is stopping ...

xampp-control stop httpd

exit