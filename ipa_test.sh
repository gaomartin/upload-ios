#/bin/bash

function pre_build {
echo "pre_build"

version=`date "+%m-%d"`
pwd
}

function build_project {
echo "build_project"

echo "begin clean"

xcodebuild -project PPUploadFileDemo.xcodeproj -scheme PPUploadFileDemo -derivedDataPath build/ -configuration Release clean

echo "start build"
xcodebuild -project PPUploadFileDemo.xcodeproj -scheme PPUploadFileDemo -derivedDataPath build/ -configuration Release build
}

function create_package {
xcrun -sdk iphoneos PackageApplication -v build/Build/Products/Release-iphoneos/PPUploadFileDemo.app -o ~/Desktop/PPUploadFileDemo$version.ipa
}

echo "$WORKSPACE"
security unlock-keychain -p "123456" ~/Library/Keychains/login.keychain

pre_build
build_project
create_package

