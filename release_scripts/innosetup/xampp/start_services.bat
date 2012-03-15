@echo off
echo Attempting to start Mysql
echo Please close this command only for Shutdown
echo Mysql is starting ...

xampp-control start mysql

echo Trying to install LimeSurvey -- use correct version of php else CLI error!
echo Please close this command only for Shutdown
echo LimeSurvey is getting installed ...

php\php.exe htdocs\admin\install\cmd_install.php install

echo Attempting to start Apache
echo Please close this command only for Shutdown
echo Apache 2 is starting ...

xampp-control start httpd

exit