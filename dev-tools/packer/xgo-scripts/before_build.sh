#!/bin/sh

set -e

if [ $BEAT_NAME = "packetbeat" ]; then
	patch -p1 < /gopacket_pcap.patch
fi

cd $GOPATH/src/$BEAT_PATH

# Files must be copied before before-build calls to allow modifications on the config files

PREFIX=/build

# Copy fields.yml
cp fields.yml $PREFIX/fields.yml

# linux
cp $BEAT_NAME.yml $PREFIX/$BEAT_NAME-linux.yml
chmod 0600 $PREFIX/$BEAT_NAME-linux.yml
cp $BEAT_NAME.reference.yml $PREFIX/$BEAT_NAME-linux.reference.yml

# darwin
cp $BEAT_NAME.yml $PREFIX/$BEAT_NAME-darwin.yml
chmod 0600 $PREFIX/$BEAT_NAME-darwin.yml
cp $BEAT_NAME.reference.yml $PREFIX/$BEAT_NAME-darwin.reference.yml

# win
cp $BEAT_NAME.yml $PREFIX/$BEAT_NAME-win.yml
chmod 0600 $PREFIX/$BEAT_NAME-win.yml
cp $BEAT_NAME.reference.yml $PREFIX/$BEAT_NAME-win.reference.yml

# Runs beat specific tasks which should be done before building
PREFIX=$PREFIX make before-build

# Add data to the home directory
mkdir -p $PREFIX/homedir
make install-home HOME_PREFIX=$PREFIX/homedir

if [ -n "BUILDID" ]; then
    echo "$BUILDID" > $PREFIX/homedir/.build_hash.txt
fi

# Append doc versions to package.yml
cat ${ES_BEATS}/libbeat/docs/version.asciidoc >> ${PREFIX}/package.yml

# Make variable naming of doc-branch compatible with gotpl. Generate and copy README.md into homedir
sed -i -e 's/:doc-branch/doc_branch/g' ${PREFIX}/package.yml

# Create README file
/go/bin/gotpl /templates/readme.md.j2 < ${PREFIX}/package.yml > ${PREFIX}/homedir/README.md

