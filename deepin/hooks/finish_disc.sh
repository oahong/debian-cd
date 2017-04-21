#! /bin/bash
# TODO: rewrite in perl

cddir=$4
archlist=$5

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
    if [[ -n ${arch}_ISO_SKELETON ]] ; then
        myecho "Copy ${arch} ISO SKELETON to $cddir"
        cp -rv ${arch}_ISO_SKELETON ${cddir}
    fi
done

myecho "Fix boot entries"
sed -e "s/V15/& B${BUILD_ID}/" \
    -i $cddir/boot/boot.cfg   \
    -i $cddir/boot/grub.cfg
