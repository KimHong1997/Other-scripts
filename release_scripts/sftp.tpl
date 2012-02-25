open sftp://%login:%password@%host:%port
mirror -e -c -R %sourcedir %targetdir
exit