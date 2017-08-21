#! /bin/bash
# TODO: rewrite in perl

#set -x
set -e

cddir=$4
archlist=$5

# TODO: move the configuration to a central place
#export mips64el_iso_skeleton="/work/loongson-boot"
declare -A skeleton=(
	[mips64el]="$MIPS64EL_ISO_SKELETON"
	[sw_64]="$SW_64_ISO_SKELETON"
)

myecho () {
	echo "disc-finish-hook:" " $@"
}

myecho "write build info to disc"

[[ -n $BUILD_ID ]] || {
    myecho "Unknown build id"
}

if [[ -z $BUILD_DATE ]] ; then
	myecho "Unknown build date"
	exit 1
fi

echo $BUILD_DATE > $cddir/.disk/build_date
echo $BUILD_ID > $cddir/.disk/build_id


for arch in $archlist; do
    echo "skeleton[$arch]"
    if [[ -n ${skeleton[$arch]} ]] ; then
        myecho "Copy $arch $skeleton to $cddir"
        cp -rv ${skeleton[$arch]}/* ${cddir}
    fi
    if [[ $arch == mips64el ]] ; then
        myecho "Fix boot entries"
        sed -e "s/V15/& B${BUILD_ID}/" \
            -i $cddir/boot/boot.cfg   \
            -i $cddir/boot/grub.cfg
    fi
done


