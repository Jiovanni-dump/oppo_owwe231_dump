#***********************************************************
#* Copyright (C), 2008-2021, OPPO Mobile Comm Corp., Ltd.
#* WATCH_EDIT
#* File: diag.sh
#* Description: diag sh
#* Version: 1.0
#* Date : 2021/04/02
#* Author: zhangxiaowei@wear.Android.Framework.Diag
#*
#* ---------------------Revision History: ---------------------
#*  <author>      <data>    <version >   <desc>
#* zhangxiaowei 2021/04/02     1.0     build this module
#***************************************************************/

#!/system/bin/sh
config="$1"



function transfer_stamp(){
    cp -f /data/system/stamp.db /data/user_de/0/com.oplus.postmanservice/databases/
    uid=`getprop sys.diag.uid`
    if [ "${uid}" != "" ]; then
       chown ${uid}:${uid} /data/user_de/0/com.oplus.postmanservice/databases/stamp.db
    fi

    cp -f /data/system/stamp.db /data/user_de/0/com.heytap.wearable.heydiag/databases/
    uid=`getprop sys.diag.uid.test`
    if [ "${uid}" != "" ]; then
       chown ${uid}:${uid} /data/user_de/0/com.heytap.wearable.heydiag/databases/stamp.db
    fi
    setprop persist.sys.diag.transfer.stamp.completed "true"
}

function transfer_log(){
    #TODO
    setprop persist.sys.diag.transfer.log.completed "true"
}

function powerlog(){
    #mkdir -p  /data/user_de/0/com.heytap.wearable.heydiag/files/#selinux issue
    cp -rf /data/anr/power/diag_power_log.txt /data/user_de/0/com.heytap.wearable.heydiag/files/
    cp -rf /data/anr/power/diag_power_log.txt /data/user_de/0/com.oplus.postmanservice/files/
    setprop persist.sys.transfer.completed.powerlog "true"
}


case "$config" in
    "transfer_stamp")
        transfer_stamp
        transfer_log
        ;;
    "transfer_log")
        transfer_log
        ;;
    "powerlog")
        powerlog
        ;;
esac
