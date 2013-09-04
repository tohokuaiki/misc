#!/bin/sh

if [ $# -lt 2  ]; then
    echo "specify expire time and server MAC address. like ic_createlicense.sh 30d 52:54:07:00:90:92"
    exit
fi

CWD=`dirname $0`
cd $CWD

MACADDR=$2
EXPIRE=$1
LICENSEFILE="deploy/wikiworks.license"
PASSPHRASE="xxxxxxxxxxxxxxxxxx"

if [ "$MACADDR" = "" ] ; then
    exit
fi


make_license --passphrase $PASSPHRASE \
    --expire-in $EXPIRE \
    --allowed-server {$MACADDR} \
    -o $LICENSEFILE

echo "create license file at $LICENSEFILE"
more $LICENSEFILE
