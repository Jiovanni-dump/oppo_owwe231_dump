#***********************************************************
#* Copyright (C), 2008-2021, OPPO Mobile Comm Corp., Ltd.
#* WEAROS_EDIT
#* File: preset.sh
#* Description: sh file
#* Version: 1.0
#* Date : 2021/02/20
#* Author: Chen.long@Wear.Android.Framework.PresetApp
#*
#* ---------------------Revision History: ---------------------
#*  <author>      <date>    <version >   <desc>
#*  chenlong    2021/02/20     1.0     build this module
#***************************************************************/

#!/system/bin/sh

system="/system"
system_reserve="/system/reserve"
system_reserve_oppo="/system/reserve_oppo"
system_reserve_oneplus="/system/reserve_oneplus"

data="/data"
data_app="/data/app"
data_app_oppo="/data/app_oppo"
data_app_oneplus="/data/app_oneplus"

replace_oppo=`getprop sys.preset.replaceoppo`
replace_oneplus=`getprop sys.preset.replaceoneplus`
replace_path=`getprop sys.replace.reserve_path`

config="$1"

log -p i -t preset "getin presetapp config:${config} replace_oppo:${replace_oppo} replace_oneplus:${replace_oneplus} replace_path:${replace_path}"

function oneplusToApp(){
	if [ "$replace_oneplus" == "true" ]; then
		log -p i -t preset "begin move ${data_app_oneplus} to ${data_app}"
		mv -t ${data_app} ${data_app_oneplus}/*
		chmod 775 -R ${data_app}
		chown system:system -R ${data_app}
		wait
		log -p i -t preset "end move ${data_app_oneplus} to ${data_app}"
		setprop sys.preset.replaceoneplus false
		exit 0
	else
		log -p e -t preset "oneplusToApp fail"
	fi
}

function oppoToApp(){
	if [ "$replace_oppo" == "true" ]; then
		log -p i -t preset "begin move ${data_app_oppo} to ${data_app}"
		mv -t ${data_app} ${data_app_oppo}/*
		chmod 775 -R ${data_app}
		chown system:system -R ${data_app}
		wait
		log -p i -t preset "end move ${data_app_oppo} to ${data_app}"
		setprop sys.preset.replaceoppo false
		exit 0
	else
		log -p e -t preset "oppoToApp fail"
	fi
}

function preset(){
	if [ "$replace_path" == "reserve" ]; then
		system_reserve=${system_reserve}
	elif [ "$replace_path" == "reserve_oppo" ]; then
		system_reserve=${system_reserve_oppo}
	elif [ "$replace_path" == "reserve_oneplus" ]; then
		system_reserve=${system_reserve_oneplus}
	fi
	log -p i -t preset "getin presetapp ${system_reserve} to ${data_app}"
	if test -d ${system_reserve}; then
		log -p i -t preset "begin copy presetapp from ${system_reserve} to ${data_app}"
		module=`getprop sys.replace.module`
		system_path=${system_reserve}/${module}
		data_path=${data_app}/${module}
		rm -rf $(data_path)
		cp -r ${system_path} ${data_app}
		chmod 775 -R ${data_path}
		chown system:system -R ${data_path}

		# Wait for jobs to finish
		wait
		log -p i -t preset "end copy presetapp from ${system_path} to ${data_path}"
		setprop sys.preset.replace false
		exit 0
	else
		log -p e -t preset "Usage: presetapp <preopts-mount-point>"
		exit 1
	fi
}

case "$config" in
	"preset")
		preset
		;;
	"oppotoapp")
		oppoToApp
		;;
	"oneplustoapp")
		oneplusToApp
		;;
esac
