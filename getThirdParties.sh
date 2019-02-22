cp -f scripts/.gclient ../.gclient
cp -f scripts/.gclient_entries ../.gclient_entries
gclient sync --with_branch_heads
cd ..
echo "{ 'GYP_DEFINES': 'OS=android target_arch=arm buildtype=Official', }" > chromium.gyp_env
cd src
gclient runhooks
build/install-build-deps-android.sh
gclient sync
sh . build/android/envsetup.sh
sh scripts/postThirdPartiesSetup.js
editor="True"
if [ $# -eq 1 ] 
then 
    gn_file=$1
    if [ -f $gn_file ] 
    then 
        echo "No editor requested. Using $gn_file"
        cp $gn_file out/Default/args.gn
        gn gen out/Default/
        editor="False"
    else 
        echo "gn_file $gn_file is missing. Resorting to editot"
        editor="True"
    fi 
fi 
if [ "$editor" = "True" ] 
then
    gn args out/Default
fi 
