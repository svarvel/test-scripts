#!/bin/bash
## Note: script to automate setup and compilation of Brave on Android 
## Author: Matteo Varvello (varvello@brave.com)
## Date:  02/22/2019

# common parameters 
WORKSPACE=$HOME"/jenkins/workspace"                     # current workspace 
android_path=$WORKSPACE"/brave-browser-build-android"   # android brave workspace 
last_yarn_vrs="1.13.0"                                  # last version of yarn 

# testing parametrization on Jenkins
COMPILE="FALSE"
ARCH="ARM"
#echo "----> ARCH: $ARCH"
#exit 0 

# switch out folder based on architecture 
case $ARCH in
    "ARM")
        out_folder="out/DefaultR"
        ;;
    
    "X86")
        out_folder="out/Defaultx86"
        ;;
    
    *)
        echo "Architecture requested ($ARCH) not supported yet"
        echo "Supported architectures are: [ARM, X86]"
        exit -1 
        ;;
esac

# pull Google depot_tools and setup path 
cd $workspace
if [ -d "depot_tools" ] 
then
    echo "Update depot_tools (if needed)..." 
    cd "depot_tools"
    git pull
    cd .. 
else 
    echo "Cloning depot_tools"
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi 

# update path if needed 
curr_path=`pwd`
depot_tools_path=$curr_path"/depot_tools"
hash ninja > /dev/null 2>&1
if [ $? -eq 1 ]
then 
    echo "Updating PATH with $depot_tools_path..."
    echo "export PATH=\$PATH:"$depot_tools_path >> ~/.bashrc 
    source ~/.bashrc
else 
    echo "PATH already contains $depot_tools_path"
fi 

# install nodejs, if needed 
# FIXME -- not sure which version is "enough"
to_install="False"
hash nodejs > /dev/null 2>&1 
if [ $? -eq 1 ] 
then 
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    apt-get install -y nodejs
fi 

# install yarn, if needed 
to_install="False"
hash yarn > /dev/null 2>&1 
if [ $? -eq 1 ] 
then 
    to_install="True"
else 
    yarn_vrs=`yarn --version`
    if [ $yarn_vrs != $last_yarn_vrs ] 
    then 
        to_install="True"
    fi  
fi 
if [ $to_install == "True" ] 
then 
    echo "Installing yarn vrs $last_yarn_vrs..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update && sudo apt-get install yarn
else 
    echo "Skipping yarn installation since available and already at right version: $yarn_vrs"
fi 

# pull third parties -- if needed 
# FIXME -- add variable to enable configuration change (e.g., arm vs x86, debug vs release) 
# tmp, jenkins can do it for us 
#git clone https://github.com/svarvel/browser-android-tabs.git src
if [ -d $android_path"/src" ] 
then
    cd $android_path"/src"
    mkdir -p $out_folder
    if [ -f $out_folder"/args.gn" ] 
    then
        echo "Avoid running getThirdParties. Resorting to configuration in $out_folder/args.gn"
    else
        echo "Running getThirdParties..."
        echo "Replacing script with matteo version with no editor need + args.gn sample files..."
        if [ -d "test-scripts" ]
        then
            cd "test-scripts"
            git pull 
            cd ..
        else 
            git clone https://github.com/svarvel/test-scripts.git
        fi 
        cp test-scripts/getThirdParties.sh ./scripts
        
        start_time=`date +%s`
        echo "Running getThirdParties.sh -- debug-arm configuration"
        sh scripts/getThirdParties.sh test-scripts/debug-arm.gn $out_folder
        curr_time=`date +%s`
        let "time_passed = curr_time - start_time"
        echo "[getThirdParties.sh] Duration: $time_passed"
    fi 
else 
    echo "Missing $android_path/src"
    echo "Suggestion: check jenkins \"checkout to a sub directory\""
    exit -1 
fi 

# compile or not 
if [ $COMPILE == "True" ] 
then 
    start_time=`date +%s`
    echo "Compiling..." 
    ninja -C $out_folder chrome_public_apk -k 1000
    curr_time=`date +%s`
    let "time_passed = curr_time - start_time"
    echo "[ninja-compilation] Duration: $time_passed"
fi 

# that's all 
echo "All good!"