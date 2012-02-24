#!/bin/sh
# This small script aims at automating release process
# * svn export or the sources
# * updating the buildnumber in common.php
# * compressing the archive in files with standard names
# * upload files to Sourceforge
#
# Requirements
# * Linux system with svn installed and a Limesurvey repository
# * p7zip package installed
# * curl with twitter support for autotwitt feature
#
# History
# * 2008/10/27: creation date (lemeur)
# * 2009/11/08: upload modified to fit the enw sf.net upload procedure (lemeur)
# * 2010/02/20: autotwitt feature (lemeur)

# Parameters
#-------------
#-------------
#
# Path to required applications
# -----------------------------
#
SVN=/usr/bin/svn
P7Z=/usr/bin/7za
RSYNC=/usr/bin/rsync
CURL=/usr/bin/curl
#
# Path to temp directory
# ----------------------
#
# TMPDIR = the target temp directory in which you want to get the packages
TMPDIR=/tmp
#
# Texts
# -----
# VERSION = The default name used for the package file name
#           You will be asked to confirm this one later anyway
VERSION="187plus"
VERSIONTXT="LimeSurvey 1.87+"
#
# Upload setup
# ------------
#
# REPOSITORY_ROOT = The SVN repository root for limesurvey
REMOTEPATH="/home/frs/project/l/li/limesurvey/1._LimeSurvey_stable/1.87+/"
# REPOSITORY_ROOT = The SVN repository root for limesurvey
REPOSITORY_ROOT=/path/to/mysvn-directory/limesurvey
# AUTOUPLOAD = YES or NO, if set to NO you'll be prompted if you want
#              to upload the packages to Sf.net or not, and if yes, you'll be
#              prompted for your Sf.net username
# SFUSER = used if AUTOUPLOAD is set to YES, won't ask you your Sf.net username
AUTOUPLOAD="NO"
SFUSER=mysfloginname
#
# Twitter Feature
# ---------------
#
# AUTOTWITT = YES or NO, if set to NO you'll be prompted if you want
#             to automatically send a tweet for the new release
# TWEETMSG = The twitter message to append to the full text release name
# TWITTERUSER = The twitter username (if empty the script will ask for it)
# TWITTERPASS = The twitter password (if empty the script will ask for it)
AUTOTWITT="NO"
TWEETMSG=" released - update now: http://www.limesurvey.org/en/download"
TWITTERUSER="limesurvey"
TWITTERPASS=""

####################################################################
#################Don't modify below#################################
####################################################################
export LANG=en_US.UTF-8
# Let's update the repository first
CURRENTPATH=`pwd`
echo "Updating the repository first"
cd $REPOSITORY_ROOT
$SVN update -q
if [ $? -ne 0 ]
then
	echo "ERROR: SVN update failed"
	exit 1
fi
echo 

# Let's get the buildnumber
BUILDNUM=`$SVN info | grep "Revision:" | awk '{print $2}'`
DATESTR=`date +%Y%m%d`


echo "Version to build will have builnumber $BUILDNUM"
echo -n "Version Name [hit enter for '$VERSION']:"
read versionname
if [ ! -z $versionname ]
then
	VERSION=$versionname
fi
PKGNAME="limesurvey$VERSION-build$BUILDNUM-$DATESTR"
echo

# export sources
echo -n "I'm about to delete $TMPDIR/limesurvey* files and directories, is this OK ['Y']:"
read cleanall
if [ ! -z $cleanall ]
then
	echo "Operation cancelled by user"
	exit 1
fi
 
rm -Rf $TMPDIR/limesurvey
rm -Rf $TMPDIR/limesurveyUpload
rm -f $TMPDIR/limesurvey*
cd $REPOSITORY_ROOT/source

echo -n "Exporting sources to $TMPDIR : "
svn export -q limesurvey /tmp/limesurvey
if [ $? -ne 0 ]
then
	echo "ERROR: SVN export failed"
	exit 2
fi
echo "OK"

#Modify build version in common.php
echo -n "Updating buildnumber in version.php : "
cd /tmp
sed -i "s/\$buildnumber = '[0-9]*';/\$buildnumber = '$BUILDNUM';/" limesurvey/version.php
if [ $? -ne 0 ]
then
	echo "ERROR: Update buildnumber in version.php failed"
	exit 4
fi
echo "OK"

echo "Preparing packages:"

echo -n " * $PKGNAME.7z : "
$P7Z a -t7z $PKGNAME.7z limesurvey 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "ERROR: 7z Archive failed"
	exit 10
fi
echo "OK"

echo -n " * $PKGNAME.zip : "
$P7Z a -tzip $PKGNAME.zip limesurvey 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "ERROR: ZIP Archive failed"
	exit 10
fi
echo "OK"

echo -n " * $PKGNAME.tar.gz : "
tar zcvf $PKGNAME.tar.gz limesurvey 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "ERROR: TAR GZ Archive failed"
	exit 10
fi
echo "OK"

echo -n " * $PKGNAME.tar.bz2 : "
tar jcvf $PKGNAME.tar.bz2 limesurvey 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "ERROR: TAR BZ2 Archive failed"
	exit 10
fi
echo "OK"
echo

if [ $AUTOUPLOAD != "YES" ]
then
	echo -n "Do you want to upload to Sf.net [N]:"
	read goupload
	if [ "$goupload" != "Y" -a "$goupload" != "y" ]
	then
		echo "Packages are ready but were not uploaded"	
		exit 3
	fi
	echo -n "Please enter your Sf.net login:"
	read SFUSER
fi

mkdir $TMPDIR/limesurveyUpload
mv $TMPDIR/$PKGNAME.* $TMPDIR/limesurveyUpload
cp $TMPDIR/limesurvey/docs/*release_notes.txt $TMPDIR/limesurveyUpload/README

#$RSYNC -avP -e ssh $TMPDIR/$PKGNAME.* $SFUSER@frs.sourceforge.net:uploads/
#$RSYNC --delete --delete-after -avP -r -e ssh $TMPDIR/limesurvey/docs/release_notes_and_upgrade_instructions.txt $TMPDIR/$PKGNAME.* $SFUSER,limesurvey@frs.sourceforge.net:$REMOTEPATH

echo "Synching /tmp/limesurveyUpload directory to release directory. This will remove old files"
$RSYNC --delete --delete-after -avP -r -e ssh $TMPDIR/limesurveyUpload/  $SFUSER,limesurvey@frs.sourceforge.net:$REMOTEPATH

if [ $? -ne 0 ]
then
	echo "ERROR: SourceForge Upload failed"
	exit 10
fi
echo "Packages upload succeeded"


if [ $AUTOTWITT != "YES" ]
then
	echo -n "Do you want to Tweet the new release [N]:"
	read gotwitt
	if [ "$gotwitt" != "Y" -a "$gotwitt" != "y" ]
	then
		echo "No tweet sent for new release"	
	fi
fi
if [ $AUTOTWITT = "YES" -o "$gotwitt" = "y" -o "$gotwitt" = "Y" ]
then
	tweet_this "$VERSIONTXT $BUILDNUM $TWEETMSG"
fi

tweet_this()
{
  if [ -z $TWITTERUSER ]
  then
    echo -n "Enter twitter username: "
    read TWITTERUSER
  else
    echo "Twitter username is '$TWITTERUSER'"
  fi

  if [ -z $TWITTERPASS ]
  then
    echo -n "Enter twitter password for '$TWITTERUSER': "
    stty -echo
    read TWITTERPASS
    stty echo
  fi
  echo

  MESSAGE="$*"
  curl -u $TWITTERUSER:$TWITTERPASS -d status="$MESSAGE" http://twitter.com/statuses/update.json
  echo

}

exit 0
