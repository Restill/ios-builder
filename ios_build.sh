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


# unlock login keygen
security unlock-keychain -p ${LOGIN_PASSWORD} ${LOGIN_KEYCHAIN} || failed "unlock-keygen"

mkdir -pv ${APP_DIR} || failed "mkdir ${APP_DIR}"

cd ${PROJECT_DIR} || failed "cd ${PROJECT_DIR}"

rm -rf bin/*
mkdir -pv bin

# clean
xcodebuild clean -project ${PROJECT_NAME}.xcodeproj \
                 -configuration ${CONFIGURATION} \
                 -alltargets \
                 || failed "xcodebuild clean"
# archive
xcodebuild archive -project ${PROJECT_NAME}.xcodeproj \
                   -scheme ${SCHEME_NAME} \
                   -destination generic/platform=iOS \
                   -archivePath bin/${PROJECT_NAME}.xcarchive \
                   || failed "xcodebuild archive"
# export ipa
xcodebuild -exportArchive -archivePath bin/${PROJECT_NAME}.xcarchive \
                          -exportPath bin/${PROJECT_NAME} \
                          -exportFormat ipa \
                          -exportProvisioningProfile ${PROFILE_NAME} \
                          -verbose \
                          || failed "xcodebuild export archive"

# move ipa to dest directory
timestamp=`date "+%Y%m%d%H"`

mv bin/${PROJECT_NAME}.ipa ${APP_DIR}/${APP_NAME}_${timestamp}.ipa || failed "mv ipa"

# clean bin files
echo "clean bin files ..."
rm -rf bin/*

echo "Done."
