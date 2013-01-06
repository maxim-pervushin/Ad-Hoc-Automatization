#!/bin/bash

# Project name, for example "Test" or "MyChat" and so on.
project_name=""
# Project root directory 
project_path=""
# Subdirectory of project_path that contains .xcodeproj file.
project_source_directory="Source"
# Scheme that will be used to build project.
project_scheme=""
# Configuration that will be used to build project.
project_configuration="Ad Hoc"
# SDK.
project_sdk="iphoneos"

# Directory that will contain all build results.
build_directory="Build"
# Subsirectory of build_directory that will contain intermediate build files.  
build_output_directory="Output"

# Code signing identity, for example "iPhone Distribution: Maxim Pervushin" 
code_signing_identity=""
# Path to the Ad Hoc provisioning profile. (Example: "/Users/maximpervushin/Library/MobileDevice/Provisioning Profiles/2D158130-FA84-46A5-A1F3-C5A383BB24F4.mobileprovision") 
provisioning_profile_path=""

# Bundle ID prefix. (Example: "com.mayfleet", "com.example")
bundle_id_prefix=""

# Server address. (Use download_address/install.html to install app)
download_address="vkjukebox.mayfleet.com"

# SFTP configuration 
sftp_user=""
sftp_password=""
sftp_address=""
sftp_directory=""

# increment build number
build_number=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $project_path/$project_source_directory/$project_name/$project_name-Info.plist)
build_number=$(($build_number + 1))
build_number=$(/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" $project_path/$project_source_directory/$project_name/$project_name-Info.plist)

# build project
xcodebuild\
  -verbose\
	-project "$project_path/$project_source_directory/$project_name.xcodeproj"\
	-scheme "$project_scheme"\
	-configuration "$project_configuration"\
	-sdk $project_sdk\
	SYMROOT="$project_path/$build_directory"\
	DSTROOT="$project_path/$build_directory/$build_output_directory"\
	install

# create .ipa
xcrun\
	-sdk $project_sdk\
	PackageApplication -v "$project_path/$build_directory/$build_output_directory/Applications/$project_name.app"\
	-o "$project_path/$build_directory/$project_name.ipa"\
	--sign "$code_signing_identity"\
	--embed "$provisioning_profile_path"


# create plist file
cd "$project_path/$build_directory"

/usr/libexec/PlistBuddy -c "Add :items array" $project_name.plist
/usr/libexec/PlistBuddy -c "Delete :items: dict" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items: dict" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:assets array" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:assets:0 dict" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:kind string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:kind software-package" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:url string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:url http://$download_address/$project_name.ipa" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:metadata dict" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-identifier string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-identifier $bundle_id_prefix.$project_name" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-version string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-version 1.0" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:kind string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:kind software" $project_name.plist
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:title string" $project_name.plist
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:title $project_name" $project_name.plist

# create html file
echo "<a href=\"itms-services://?action=download-manifest&url=http://$download_address/$project_name.plist\">Install</a>" >> install.html

# upload files to server via sftp
expect -c\
	"spawn sftp $sftp_user@$sftp_address:$sftp_directory
	expect \"password:\"
	send \"$sftp_password\r\"
	expect \"sftp>\"
	send \"put $project_name.ipa\r\"
	expect \"sftp>\"
	send \"put $project_name.plist\r\"
	expect \"sftp>\"
	send \"put install.html\r\"
	expect \"sftp>\"
	send bye\r"
