#!/bin/sh
echo "Unpacking files..."
FILESDIR=`mktemp -d -t aws_bootstrap.XXXXX`
LINES=$(awk '/^__ARCHIVE_DATA_FOLLOWS__/ {print NR + 1; exit 0; }' $0)
tail -n +${LINES} $0 | base64 --decode | tar xJv -C $FILESDIR
echo "Bootstrapping server..."
$FILESDIR/bootstrap_server.sh aws $FILESDIR
echo "Cleaning up..."
rm -rf $FILESDIR
exit 0
__ARCHIVE_DATA_FOLLOWS__
