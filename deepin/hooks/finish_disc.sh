#! /bin/bash
# TODO: rewrite in perl

#set -x
set -e

cddir=$4
archlist=$5

myecho () {
	echo "disc-finish-hook:" " $@"
}

myecho "write build info to disc"

[[ $BUILD_ID -gt 0 ]] || {
    myecho "Unknown build id $BUILD_ID"
    exit 1
}

[[ -n $BUILD_DATE ]] || {
	myecho "Unknown build date"
	exit 2
}

echo $BUILD_DATE > $cddir/.disk/build_date
echo $BUILD_ID > $cddir/.disk/build_id


if [[ -d ${ISO_SKELETON} ]] ; then
    myecho "Copy ISO skeleton to $cddir from ${ISO_SKELETON}"
    cp -rv ${ISO_SKELETON}/* ${cddir}
fi
if [[ $arch == mips64el ]] ; then
    myecho "Fix boot entries for ${arch}"
    sed -e "s/V15/& B${BUILD_ID}/" \
        -i $cddir/boot/boot.cfg   \
        -i $cddir/boot/grub.cfg
fi
