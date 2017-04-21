#! /bin/sh
set -e

## Build an installation media for deepin server, it's a wrapper based on
## debian easy-build.sh
## See README.easy-build for instructions how to use this script.
## See also CONF.sh for the meaning of variables used here.

show_usage() {
	echo "Usage: $(basename $0) [OPTIONS] NETINST|CD|DVD [<ARCH> ...]"
	echo "  Options:"
	echo "     -d mate|lxde|lxqt|light|all : desktop variant (task) to use, default is mate"
	echo "     -h : help"
}


# Set configuration file to be used for the build and source it
export CF=./CONF.sh
. $CF
export DEBIAN_CD_CONF_SOURCED=true
unset UPDATE_LOCAL


## Parse the parameters passed to the script
if [ $# -eq 0 ]; then
	show_usage
	exit 1
fi

# set Mate as default DE
desktop=mate
while getopts d:h OPT; do
	case $OPT in
	    d)
		case $OPTARG in
		    mate|lxde|lxqt|light|all)
			desktop=$2
			;;
		    *)
			show_usage
			exit 1
			;;
		esac ;;
	    h)
		show_usage
		exit 0
		;;
	    \?)
		show_usage
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))

if [ $# -eq 0 ] ; then
    show_usage
    exit 1
fi

# DISKTYPE should set to DVD in current development stage
export DISKTYPE="$1"
shift

# The architecture(s) for which to build the CD/DVD image
if [ "$1" ]; then
	ARCHES="$@"
else
	ARCHES=mips64el
fi


## For what release to build images

# The suite the installed system will be based on
export CODENAME=kui
# The suite from which the udebs for the installer will be taken (normally
# the same as CODENAME)
export DI_CODENAME=kui


## The debian-installer images to use. This must match the suite (DI_CODENAME)
## from which udebs will be taken.
## Use *only one* of the next four settings. The "%ARCH%" placeholder in the
## 2nd and 4th options will be magically expanded at runtime.
## See also: tools/boot/<codename>/boot-$ARCH scripts.

# Use official images from the local mirror
export DI_DIST=$DI_CODENAME
# or, use official images from an outside mirror
#export DI_WWW_HOME="http://ftp.nl.debian.org/debian/dists/$DI_CODENAME/main/installer-%ARCH%/current/images/"
# or, use daily built d-i images (most from http://people.debian.org)
#export DI_WWW_HOME=default
# or, use custom / locally built images
#export DI_DIR="$HOME/d-i_images/%ARCH%"

## Other options

# Include local packages in the build
#export LOCAL=1
# Automatically update the Packages file(s) for the "local" repository?
#UPDATE_LOCAL=1

# Number of CD/DVDs to build; comment out to build full set
MAX_CDS=1

# Only create the ISO files; don't create jigdo files
export MAXJIGDOS=0

## Options that include CODENAME must be set here if needed, not in CONF.sh

# Include proposed-updates
#export PROPOSED_UPDATES=$CODENAME-proposed-updates

#export UDEB_INCLUDE="$BASEDIR"/data/$CODENAME/udeb_include
#export UDEB_EXCLUDE="$BASEDIR"/data/$CODENAME/udeb_exclude
#export BASE_INCLUDE="$BASEDIR"/data/$CODENAME/base_include
#export BASE_EXCLUDE="$BASEDIR"/data/$CODENAME/base_exclude
#export SPLASHPNG="$BASEDIR/data/$CODENAME/splash-img.png"
#export RELEASE_NOTES_LOCATION="http://www.debian.org/releases/$CODENAME"

# deepin customization
export CDNAME=${PROJECT:-deepin-server}
export DEBVERSION=${CDVERSION:-15.1}

# IMPORTANT : The 4 following paths must be on the same partition/device.
#             If they aren't then you must set COPYLINK below to 1. This
#             takes a lot of extra room to create the sandbox for the ISO
#             images, however. Also, if you are using an NFS partition for
#             some part of this, you must use this option.
# Paths to the mirrors
export MIRROR=${DEEPIN_MIRROR}
# Path of the temporary directory
export TDIR=${WORK:-$BASEDIR}/build/$DEBVERSION
# Path where the images will be written
export OUT=${OUTPUT:-${BASEDIR}/output}/$DEBVERSION/$(date +%F)
# Where we keep the temporary apt stuff.
# This cannot reside on an NFS mount.
export APTTMP=$TDIR/apt

# uncomment this to if you want to see more of what the Makefile is doing
#export VERBOSE_MAKE=1

export IMAGESUMS=1
export CHECKSUMS="md5 sha512"

# enable NONFREE and CONTRIB
export NONFREE=1
export CONTRIB=1

# Disable documentations
export OMIT_MANUAL=1
export OMIT_RELEASE_NOTES=1
export OMIT_DOC_TOOLS=1

export EXCLUDE1=exclude

# Add suggested packages to the CD set
export NOSUGGESTS=0

# Do I want to force (potentially non-free) firmware packages to be
# placed on disc 1? Will make installation much easier if systems
# contain hardware that depends on this firmware
export FORCE_FIRMWARE=1

export DISKINFO_DISTRO="deepin server"
#export DISKINFO_DEBVERSION="$DEBVERSION"

export BUILD_ID=${TASK:-1}
# TODO: read from config
export MIPS64EL_ISO_SKELETON="/work/loongson-boot"
#export COMPLETE=0

##################################
# LOCAL HOOK DEFINITIONS
##################################
# $TDIR (the temporary dir containing the build tree)
# $MIRROR (the location of the mirror)
# $DISKNUM (the image number in the set)
# $CDDIR (the root of the temp disc tree)
# $ARCHES (the set of architectures chosen)
# The disc_start hook. This will be called near the beginning of the
# start_new_disc script, just after the directory tree has been created
# but before any files have been added
#export DISC_START_HOOK=/bin/true

#export DISC_PKG_HOOK=/bin/true
#export RESERVED_BLOCKS_HOOK=/bin/true
#export DISC_END_HOOK=/bin/true
export DISC_FINISH_HOOK=$BASEDIR/deepin/hooks/finish_disc.sh

## The rest of the script should just work without any changes

# Set variables that determine the type of image to be built
case $DISKTYPE in
    NETINST)
	export INSTALLER_CD=2
	;;
    CD)
	unset INSTALLER_CD
	[ -z "$MAX_CDS" ] || export MAXCDS=$MAX_CDS
	;;
    DVD)
	export INSTALLER_CD=3
	[ -z "$MAX_DVDS" ] || export MAXCDS=$MAX_DVDS
	;;
    *)
	show_usage
	exit 1
	;;
esac

if [ "$desktop" ]; then
	if [ ! -e tasks/$CODENAME/deepin-$desktop ]; then
		echo "Error: desktop '$desktop' is not supported for $CODENAME"
		exit 1
	fi
	export TASK=deepin-$desktop
	KERNEL_PARAMS="desktop=$desktop"
	DESKTOP=$desktop
	export KERNEL_PARAMS DESKTOP
fi

if [ "$LOCAL" ] && [ "$UPDATE_LOCAL" ]; then
	echo "Updating Packages files for local repository..."
	for arch in $ARCHES; do
		./tools/Packages-gen $CODENAME $arch
		./tools/Packages-gen -i $DI_CODENAME $arch
	done
	echo
fi

echo "Starting the actual debian-cd build..."
./build.sh "$ARCHES"
