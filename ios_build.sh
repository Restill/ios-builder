#!/bin/bash

function failed() {
    echo "Failed: $@" >&2
    exit 1
}

LOGIN_KEYCHAIN=~/Library/Keychains/login.keychain

script_dir_relative=`dirname $0`
script_dir=`cd ${script_dir_relative}; pwd`
echo "script_dir = ${script_dir}"

# read config
. ${script_dir}/ios_build.config

echo "*** Set Xcode build config ***"
if [[ ${IOS_PROVISIONING_PROFILE} == "development" ]]
then
    EXPORT_OPTIONS_PLIST="${script_dir}/app_development.plist"
    XCCONFIG="${script_dir}/app_development.xcconfig"
    FILENAME_SUFFIX="Development"
else
    EXPORT_OPTIONS_PLIST="${script_dir}/app_distribution.plist"
    XCCONFIG="${script_dir}/app_distribution.xcconfig"
    FILENAME_SUFFIX="Distribution"
fi

# unlock login keygen
security unlock-keychain -p ${LOGIN_PASSWORD} ${LOGIN_KEYCHAIN} || failed "unlock-keygen"

mkdir -pv ${APP_DIR} || failed "mkdir ${APP_DIR}"
cd ${PROJECT_DIR} || failed "cd ${PROJECT_DIR}"

rm -rf bin/*
mkdir -pv bin

# set version to project file
# update CFBundleVersion
agvtool new-version -all ${VERSION}
# update CFBundleShortVersionString
agvtool new-marketing-version ${SHORT_VERSION}
                                             
# archive
xcodebuild archive -project ${PROJECT_NAME}.xcodeproj \
                   -scheme ${SCHEME_NAME} \
                   -destination generic/platform=iOS \
                   -archivePath bin/${PROJECT_NAME}.xcarchive \
                   -xcconfig ${XCCONFIG} \
                   || failed "xcodebuild archive"
# export ipa
xcodebuild -exportArchive -archivePath bin/${PROJECT_NAME}.xcarchive \
                          -exportPath bin \
                          -exportOptionsPlist ${EXPORT_OPTIONS_PLIST} \
                          -verbose \
                          || failed "xcodebuild export archive"

# move ipa to dest directory
timestamp=`date "+%Y%m%d%H"`

mv bin/${PROJECT_NAME}.ipa ${APP_DIR}/${APP_NAME}_${VERSION}_${FILENAME_SUFFIX}_${timestamp}.ipa || failed "mv ipa"

# clean bin files
echo "clean bin files ..."
rm -rf bin/*

echo "Done."
