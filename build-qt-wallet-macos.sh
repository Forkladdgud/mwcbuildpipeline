#!/bin/sh

. ~/.cargo/env

# Clean everything. This is a release build so we can wait
rm -rf mwc713 mwc-node mwc-qt-wallet target/*
mkdir -p target

# Build mwc-node
git clone https://github.com/mwcproject/mwc-node
cd mwc-node
TAG_FOR_BUILD_FILE=../mwc-node.version
if [ -f "$TAG_FOR_BUILD_FILE" ]; then
    git fetch && git fetch --tags;
    git checkout `cat $TAG_FOR_BUILD_FILE`;
fi
./build_static.sh

FILE=target/release/mwc
if [ ! -f "$FILE" ]; then
    echo "ERROR: $FILE does not exist";
    exit 1;
fi

cd ..

# First build mwc713 statically
git clone https://github.com/mwcproject/mwc713
cd mwc713
TAG_FOR_BUILD_FILE=../mwc713.version
if [ -f "$TAG_FOR_BUILD_FILE" ]; then
    git fetch && git fetch --tags;
    git checkout `cat $TAG_FOR_BUILD_FILE`;
fi
./build_static.sh 

FILE=target/release/mwc713
if [ ! -f "$FILE" ]; then
    echo "ERROR: $FILE does not exist";
    exit 1;
fi

cd ..


# Second build mwc-qt-wallet
git clone https://github.com/mwcproject/mwc-qt-wallet
cd mwc-qt-wallet
TAG_FOR_BUILD_FILE=../mwc-qt-wallet.version
if [ -f "$TAG_FOR_BUILD_FILE" ]; then
    git fetch && git fetch --tags;
    git checkout `cat $TAG_FOR_BUILD_FILE`;
    echo "#define BUILD_VERSION  \"`cat $TAG_FOR_BUILD_FILE`\"" > build_version.h
else
    echo "#define BUILD_VERSION  \"1.0-7.beta.$1\"" > build_version.h
fi
qmake mwc-qt-wallet.pro -spec macx-clang CONFIG+=x86_64
make

# Finally prep dmg
cp ../mwc-node/target/release/mwc mwc-qt-wallet.app/Contents/MacOS/mwc
cp ../mwc713/target/release/mwc713 mwc-qt-wallet.app/Contents/MacOS/mwc713
macdeployqt mwc-qt-wallet.app -appstore-compliant

if [ -z "$2" ]
then
   # We can't sign so just build dmg
   hdiutil create ../target/mwc-qt-wallet.dmg -fs HFS+ -srcfolder mwc-qt-wallet.app -format UDZO -volname mwc-qt-wallet;
   echo "Complete!";
else
   # Sign
   codesign --force --options runtime --sign 'Developer ID Application: Christopher Gilliard (D6WGXN9XBM)' --deep mwc-qt-wallet.app
   # Building the disk image for the app folder
   hdiutil create ../target/mwc-qt-wallet.dmg -fs HFS+ -srcfolder mwc-qt-wallet.app -format UDZO -volname mwc-qt-wallet

   echo "Your diskimage is created. Now we need to sign it..."
   # signing resulting package
   codesign --sign 'Developer ID Application: Christopher Gilliard (D6WGXN9XBM)' ../target/mwc-qt-wallet.dmg

   # now notarize the app
   echo "Notarizing this will take a while..."

   rm -rf /tmp/notarize_out.log;
   xcrun altool --notarize-app -f ../target/mwc-qt-wallet.dmg --primary-bundle-id com.yourcompany.mwc-qt-wallet -u mimblewimblecoin2@protonmail.com -p $2
   echo "Sleeping for 2 minutes to let apple process things."
   sleep 120;
   xcrun stapler staple -q -v ../target/mwc-qt-wallet.dmg

   echo "Check your resulting image at target/mwc-qt-wallet.dmg. Check contents at mwc-qt-wallet/mwc-qt-wallet.app"
   echo "To do this, open the dmg, and drag the app into the /Applications folder"
   echo "Then run this command: spctl -a -v /Applications/mwc-qt-wallet.app"
   echo "You should see a message like this: source=Notarized Developer ID"
   echo "Note you must be on MacOSX10.14+"
fi

