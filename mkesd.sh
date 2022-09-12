#!/usr/bin/env zsh

function cab2esd {
    CAB=$1
    ESD=$2
    [[ -e $ESD ]] && return 1

    TEMPDIR=`mktemp -d`
    7z x $1 -o$TEMPDIR &>/dev/null

    wimcapture $TEMPDIR $ESD --no-acls --norpfix &>/dev/null || {
        print -P '[%F{red}%BError%b%f] CAB→ESD capture failed !'
    }
    rm -rf $TEMPDIR
}

if [[ $# != 2 ]]
then
    print -P "[%F{red}%BError%b%f] Wrong argument count"
    print "Usage: $0 METADATA_ESD OUT_ESD"
    print "metadata ESD's directory has to contain the full UUP set"
    exit 1
fi

METADATA=$1
UUP_SET=`dirname $METADATA`
OUT_ESD=$2

#
# Step 1: Convert all CABs to ESDs

CAB_LIST=$(find $UUP_SET/ -iname '*.cab' \
-and -not -iname 'Windows10.0-KB*' \
-and -not -iname 'SSU-*' \
-and -not -iname '*AggregatedMetadata*' \
-and -not -iname '*DesktopDeployment*')

print -P '[%BInfo%b]Converting all CAB files into ESD.. Please wait.'

for CABINET in ${=CAB_LIST}; do
    cab2esd $CABINET ${CABINET%.*}.esd &
done
wait

#
# Step 2: Re-export the metadata ESD's edition index with all its references
wimexport $METADATA 3 $OUT_ESD --ref=$UUP_SET/*.esd || {
    print -P '[%F{red}%BError%b%f] Error reexporting wim..'
    exit 1
}

echo 'Done!'