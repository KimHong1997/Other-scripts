#!/bin/bash
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
# * 2012/02/24: Converted the script to use Git and a new twitter bash script

# Parameters
#-------------
#-------------
#
# Path to required applications
# -----------------------------
#
VCS=/usr/bin/git
P7Z=/usr/bin/7za
RSYNC=/usr/bin/rsync
LFTP=/usr/bin/lftp
#
# Path to temp directory
# ----------------------
#
# TMPDIR = the local target temp directory in which you want to put the packages
TMPDIR=/tmp
#
# Texts
# -----
# VERSION = The default name used for the package file name
#           You will be asked to confirm this one later anyway
VERSION="192plus"
VERSIONTXT="LimeSurvey 1.92+"
#
# Upload setup
# ------------
#
# REPOSITORY_ROOT = The VCS repository root for limesurvey - 
# Please note that a clone of the related Git repository should already exist in that path
REPOSITORY_ROOT=/home/c_schmitz/limesurvey/limesurveyrepo
# AUTOUPLOAD = YES or NO, if set to NO you'll be prompted if you want
#              to upload the packages automatically or not
AUTOUPLOAD="NO"
# Must be configured
UPLOADUSER=""
UPLOADPASSWORD=""
UPLOADHOST=""
UPLOADPORT=""
# Note that the path slashes must be properly escaped (for SED)
UPLOADSTABLEPATH="\/Releases\/Latest_stable_release"
UPLOADUNSTABLEPATH="\/Releases\/Unstable_releases"


INNOSETUPBASEPATH="Z:\home\loginname\limesurvey\innosetup"
INNOSETUPLSTEMPPATH="Z:\tmp\limesurvey"
INNOSETUPTEMPPATH="Z:\tmp"

#
#
# Twitter Feature
# ---------------
#
# AUTOTWITT = YES or NO, if set to NO you'll be prompted if you want
#             to automatically send a tweet for the new release
# TWEETMSG = The twitter message to append to the full text release name
AUTOTWITT="NO"
TWEETMSGSTABLE=" released - update now: http://www.limesurvey.org/en/download"
TWEETMSGUNSTABLE=" released - try it out: http://www.limesurvey.org/en/download"

####################################################################
#################Don't modify below#################################
####################################################################
export LANG=en_US.UTF-8
# Let's update the repository first
CURRENTPATH=`pwd`
echo "Updating the repository first"
cd $REPOSITORY_ROOT
$VCS pull
if [ $? -ne 0 ]
then
	echo "ERROR: VCS update failed"
	exit 1
fi
echo 
# Let's get the buildnumber
BUILDNUM=`date +%y%m%d`
DATESTR=`date +%Y%m%d`

UPLOADPATH=$UPLOADSTABLEPATH;
TWEETMSG=$TWEETMSGSTABLE;

echo -n "What kind of version do you want to release ((s)table/(u)nstable)[s]:"
read releasekind
if [  -z $releasekind ]; then
	UPLOADPATH=$UPLOADSTABLEPATH;
        TWEETMSG=$TWEETMSGSTABLE;
        echo 'OK, stable version it is.'
fi
if [ "$releasekind" == "u" ]; then
	UPLOADPATH=$UPLOADUNSTABLEPATH;
        TWEETMSG=$TWEETMSGUNSTABLE;
	echo 'OK, unstable version it is.'
fi


echo -n "Build number [hit enter for '$BUILDNUM']:"
read buildnumber
if [ ! -z $buildnumber ]
then
        BUILDNUM=$buildnumber
fi

echo

echo -n "Version Name [hit enter for '$VERSION']:"
read versionname
if [ ! -z $versionname ]
then
	VERSION=$versionname
fi
PKGNAME="limesurvey$VERSION-build$BUILDNUM"
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
cd $REPOSITORY_ROOT

echo -n "Copying sources to $TMPDIR : "
rsync -r --exclude .git $REPOSITORY_ROOT/ $TMPDIR/limesurvey/
if [ $? -ne 0 ]
then
	echo "ERROR: Copying sources to $TMPDIR/limesurvey/ failed"
	exit 2
fi
echo "OK"

#Modify build version in common.php
echo -n "Updating buildnumber in version.php : "
cd $TMPDIR
sed -i "s/\$buildnumber = '[0-9]*';/\$buildnumber = '$BUILDNUM';/" limesurvey/version.php
if [ $? -ne 0 ]
then
	echo "ERROR: Update buildnumber in version.php failed"
	exit 4
fi
echo "OK"

# Packagin files
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

echo -n " * $PKGNAME-on-xampp-win32-setup.exe : "
cd $CURRENTPATH/innosetup
# The following line needs to be configured separately - wine assumes Z: as virtual drive
wine ISCC "/dBASEPATH=$INNOSETUPBASEPATH" "/dLSSOURCEPATH=$INNOSETUPLSTEMPPATH" "$INNOSETUPBASEPATH\ls_1x_on_xampp.iss" "/o$INNOSETUPTEMPPATH" "/f$PKGNAME-on-xampp-win32-setup" /q
if [ $? -ne 0 ]
then
	echo "ERROR: Preparing LimeSurvey-on-xampp package failed"
	exit 10
fi
echo "OK"
echo 




if [ $AUTOUPLOAD != "YES" ]
then
	echo -n "Do you want to upload to limesurvey.org [Y]:"
	read goupload
    if [ ! -z $goupload ]
	then
		echo "Packages are ready but were not uploaded"	
		exit 3
	fi
fi

mkdir $TMPDIR/limesurveyUpload
mv $TMPDIR/$PKGNAME*.* $TMPDIR/limesurveyUpload
cp $TMPDIR/limesurvey/docs/*release_notes.txt $TMPDIR/limesurveyUpload/README




# Prepare lftp batch
echo -n "Preparing lftp batch: "
cp $CURRENTPATH/sftp.tpl $TMPDIR/sftp.cmd
cd $TMPDIR
sed -i "s/%login/$UPLOADUSER/" sftp.cmd
sed -i "s/%password/$UPLOADPASSWORD/" sftp.cmd
sed -i "s/%host/$UPLOADHOST/" sftp.cmd
sed -i "s/%port/$UPLOADPORT/" sftp.cmd
sed -i "s/%sourcedir/\\$TMPDIR\/limesurveyUpload/" sftp.cmd
sed -i "s/%targetdir/$UPLOADPATH/" sftp.cmd
if [ $? -ne 0 ]
then
	echo "ERROR: Updating lftp batch failed"
	exit 4
fi
echo "OK"


# Upload with lftp and the prepared script
echo "Synching $TMPDIR/limesurveyUpload directory to release directory. This will remove old files"
$LFTP -f $TMPDIR/sftp.cmd
rm -f $TMPDIR/sftp.cmd
if [ $? -ne 0 ]
then
	echo "ERROR: Upload failed"
	exit 10
fi
echo "Packages upload succeeded"


if [ $AUTOTWITT != "YES" ]
then
	echo -n "Do you want to Tweet the new release [N]:"
	read gotwitt
	if [ "$gotwitt" != "Y" -a "$gotwitt" != "y" ];
	then
		echo "No tweet sent for new release"
    else
        $CURRENTPATH/tweet.sh "$VERSIONTXT Build $BUILDNUM $TWEETMSG"
	fi
else
if [ $AUTOTWITT = "YES" -o "$gotwitt" = "y" -o "$gotwitt" = "Y" ]
then
   $CURRENTPATH/tweet.sh "$VERSIONTXT Build $BUILDNUM $TWEETMSG"
fi
fi


exit 0
