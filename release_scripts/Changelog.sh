#!/bin/bash
#
#---------------------------------------------------------------
# This is a dirty and quick script to automate changelog
# generation from Git repository logs
# This will output a txt file wich can be added to the relevant
# section in the release notes.
#----------------------------------------------------------------
#
# Configuration section
#
export LANG=en_US.UTF-8
# REPOSITORY_ROOT = root of your local limesurvey repository
#REPOSITORY_ROOT=/path/to/limesurvey-repo
REPOSITORY_ROOT=/home/loginname/limesurvey/limesurveyrepo

# TMPDIR is the directory where temporary and output files will be written
TMPDIR=`pwd`

# PATH to some important binaries
VCS=/usr/bin/git
PHP=/usr/bin/php

# Let's update the repository first
echo "Updating SVN local repository"
CURRENTPATH=`pwd`
cd $REPOSITORY_ROOT
$VCS pull --all
if [ $? -ne 0 ]
then
        echo "ERROR: Pulling  failed"
        exit 1
fi

echo -n "Which branch do you want to release [master]: "
read BRANCH
if [$BRANCH = '']
then
    BRANCH="master"
fi

$VCS checkout $BRANCH -f
git rev-parse HEAD
# Let's get the buildnumber
CURRENTBUILDID=`$VCS rev-parse HEAD`
NEXTREVID=`date +"%y%m%d"`

echo "Current repository head is SHA $CURRENTBUILDID,"
echo "  Let's assume you're preparing the build $NEXTREVID release"

echo -n "Please enter the last release SHA: "
read OLDID
SOLDID="${OLDID:0:10}"
echo "Getting log from $SOLDID to HEAD for branch $BRANCH"
$VCS log --no-merges $OLDID..HEAD|php ../logformat.php| sort -u > $CURRENTPATH/log/log-LS-$SOLDID-$NEXTREVID.txt

echo "Now you have to:"
echo " * Review the generated changelog in $CURRENTPATH/Changelog-LS-$OLDID-$NEXTREVID.txt"
echo " * Add it to the relevant section in /docs/release_notes.txt"
echo " * Commit and push the new release_notes.txt"
echo " * Run the Package.sh script to build and upload the packages to Sf.net"
