#!/bin/sh

OPTION="-rltgoDvz"
OBFUSCATIONKEY="tinycms-junoe-encode"
LICENSEFILE="wikiworks.license"
PASSPHRASE="wikiworks-license-phrase"

IONCUBE=""

if [ $# -ge 2  ]; then
    MACADDR="$2"
fi

if [ $# -ge 1  ]; then
    if [ $1 != "do"  ]; then
        OPTION=${OPTION}n
    else
        IONCUBE="do"
    fi
else
    OPTION=${OPTION}n
fi

CWD=`dirname $0`

set -x

cd $CWD/gitrepo
git pull origin master

cd ..
rsync -e ssh --exclude="tinycms/*" --exclude=".gitignore" --exclude="doc/*" $OPTION gitrepo/* deploy/

if [ ! -f deploy/$LICENSEFILE ] ; then
    echo "LICENSE FILE NOT FOUND."
    exit
fi

if [ $IONCUBE != "do"  ]; then
    exit
fi

#    --obfuscate all --obfuscation-key $OBFUSCATIONKEY \
#     --obfuscation-exclusion-file gitrepo/doc/unobfuscation_functions.txt \
ION_OPTION=" \
    --replace-target \
    --ignore-strict-warnings \
    --ignore-deprecated-warnings \
    --copy app/plugin/Smarty/ \
    --copy app/Tinycms_Controller.php \
    --copy app/Tinycms_Logger.php \
    --copy app/Tinycms_SmartyPlugin.php \
    --copy lib/Ethna/ \
    --copy lib/gtickets.php \
    --copy lib/PEAR.php \
    --copy lib/Smarty/ \
    --copy lib/XML/ \
    --copy bin/check_statichtml.php \
    --copy etc/env/ \
    --copy locale/ \
    --copy log/ \
    --copy schema/ \
    --copy skel/ \
    --copy www/ \
    --with-license $LICENSEFILE \
    --passphrase $PASSPHRASE \
"

ioncube_encoder53 --add-comment "Wikiworks project/copy right Junoe.inc www.junoe.jp " $ION_OPTION gitrepo/tinycms --into deploy/
