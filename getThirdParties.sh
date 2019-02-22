# default parameters 
full="True"
editor="True"

# read input parameters 
if [ $# -gt 0 ] 
then 
	gn_file=$1
	out_folder=$2
	full="$3"
	editor="False"
fi 

# this can be skipped if goal is just to change ninja configuration -- VERIFY
if [ "$full" = "True" ] 
then 
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
fi 

# run gn via editor or not 
if [ "$editor" = "False" ]
then
    if [ -f $gn_file ]
    then
        echo "No editor requested. Using $gn_file"
        cp $gn_file $out_folder"/args.gn"
        gn gen $out_folder
    else
        echo "gn_file $gn_file is missing. Resorting to editot"
        editor="True"
    fi
fi
if [ "$editor" = "True" ]
then
    gn args out/Default
fi
