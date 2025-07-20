#***********************************************************
#* Copyright (C), 2008-2019, OPPO Mobile Comm Corp., Ltd.
#* WATCH_EDIT
#* File: autochmod.sh
#* Description: logcat shell scipt
#* Version: 1.0
#* Date : 2019/06/25
#* Author: zhangxiaowei@wear.Android.Framework.Logkit
#*
#* ---------------------Revision History: ---------------------
#*  <author>      <data>    <version >   <desc>
#* zhangxiaowei 2019/06/25     1.0     build this module
#* Bo.Wu        2019/08/06     1.1     add userdatarefresh()
#* zhangxiaowei 2019/08/06     1.2     add tcpdump/modem/mcu/copylog
#***************************************************************/

#!/system/bin/sh
DATE=`date +%F-%H`
CURTIME=`date +%F-%H-%M-%S`
ROOT_DATA_PATH=/data/oppo_log
config="$1"
shlog=`getprop persist.sys.collectlog.shlog`

function init_logkit(){
    setprop sys.wear.logkit.logtime `date +%F-%H-%M-%S`
}

function onboot_logkit(){
    logtimeCur=`getprop sys.wear.logkit.logtime`
    logtimeOld=`getprop persist.sys.wear.logkit.logtime`
    boottime=`getprop persist.sys.wear.boottime`
    isCollect=`getprop persist.sys.collectlog`
    if [ ${logtimeOld} == ${logtimeCur} ]; then
        return 0
    elif [ "${isCollect}" != "0" ] && [ "${isCollect}" != "" ]; then
        setprop persist.sys.wear.boottime `date +%F-%H-%M-%S`
        writelog "onboot -- ${logtimeCur} -- ${logtimeOld} -- ${boottime} -- ${isCollect}"
        if [ "${boottime}" != "" ] && [ "${logtimeOld}" != "${boottime}" ]; then
            mv -f /data/oppo_log/${logtimeOld} /data/oppo_log/${boottime}
        fi
    else
        setprop persist.sys.wear.boottime ""
        setprop sys.wear.logkit.logtime `date +%F-%H-%M-%S`
    fi
    setprop persist.sys.wear.logkit.logtime `getprop sys.wear.logkit.logtime`
}
function initAndroid(){
    FreeMemory
    tmpMain=`getprop persist.sys.log.main`
    if [ "${tmpMain}" == "" ]; then
        tmpMain=`getprop sys.log.main`
    fi
    if [ "${tmpMain}" != "" ]; then
        #get the config size main
        androidSize=`set -f;array=(${tmpMain//|/ });echo "${array[0]}"`
        androidCount=`set -f;array=(${tmpMain//|/ });echo "${array[1]}"`
        writelog "androidSize=${androidSize} androidCount=${androidCount}"
    else
        if [ ${FreeSize} -ge 2301952 ]; then #2G+200M
            androidSize=61440
            androidCount=15
        elif [ ${FreeSize} -ge 1777664 ]; then #1.5G+200M
            androidSize=61440
            androidCount=11
        elif [ ${FreeSize} -ge 1253376 ]; then #1G+200M
            androidSize=30720
            androidCount=12
        elif [ ${FreeSize} -ge 716800 ]; then #500M+200M
            androidCount=$((2 + 2 * (${FreeSize} / 102400 - 7)))
            androidSize=30720
            writelog "Android using default androidSize=${androidSize} androidCount=${androidCount}"
        else
            androidCount=2
            androidSize=30720
        fi
        setprop sys.log.main "${androidSize}|${androidCount}"
        writelog "Android using default androidSize=${androidSize} androidCount=${androidCount}"
    fi

    tmp=`getprop sys.wear.logkit.logtime`
    if [ "${tmp}" != "" ]; then
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/mobilelog/
    else
        LOGTIME=`date +%F-%H-%M-%S`
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${LOGTIME}/mobilelog/
        setprop sys.wear.logkit.logtime ${LOGTIME}
        setprop persist.sys.wear.logkit.logtime ${LOGTIME}
    fi

    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ]; then
        mkdir -p  ${ROOT_DATA_apps_LOG_PATH}
    fi

    chmod 770 ${ROOT_DATA_PATH}/${tmp}
    chown root:system ${ROOT_DATA_PATH}/${tmp}
}
function initRadio(){
    FreeMemory
    tmpRadio=`getprop persist.sys.log.radio`
    if [ "${tmpRadio}" != "" ]; then
        #get the config size main
        radioSize=`set -f;array=(${tmpRadio//|/ });echo "${array[0]}"`
        radioCount=`set -f;array=(${tmpRadio//|/ });echo "${array[1]}"`
        writelog "radioSize=${radioSize} radioCount=${radioCount}"
    else
        if [ ${FreeSize} -ge 2301952 ]; then
            radioSize=15360
            radioCount=3
        elif [ ${FreeSize} -ge 1777664 ]; then
            radioSize=15360
            radioCount=2
        else
            radioSize=15360
            radioCount=1
        fi
        writelog "Radio using default radioSize=${radioSize} radioCount=${radioCount}"
    fi
    tmp=`getprop sys.wear.logkit.logtime`
    if [ "${tmp}" != "" ]; then
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/mobilelog/
    else
        LOGTIME=`date +%F-%H-%M-%S`
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${LOGTIME}/mobilelog/
        setprop sys.wear.logkit.logtime ${LOGTIME}
        setprop persist.sys.wear.logkit.logtime ${LOGTIME}
    fi

    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ]; then
        mkdir -p  ${ROOT_DATA_apps_LOG_PATH}
    fi
}
function initEvent(){
    FreeMemory
    tmpEvent=`getprop persist.sys.log.event`
    if [ "${tmpEvent}" != "" ]; then
        #get the config size main
        eventSize=`set -f;array=(${tmpEvent//|/ });echo "${array[0]}"`
        eventCount=`set -f;array=(${tmpEvent//|/ });echo "${array[1]}"`
        writelog "eventSize=${eventSize} eventCount=${eventCount}"
    else
        if [ ${FreeSize} -ge 2301952 ]; then
            eventSize=61440
            eventCount=4
        elif [ ${FreeSize} -ge 1777664 ]; then
            eventSize=61440
            eventCount=2
        elif [ ${FreeSize} -ge 1253376 ]; then
            eventSize=30720
            eventCount=2
        elif [ ${FreeSize} -ge 716800 ]; then
            eventSize=15360
            eventCount=2
        else
            eventSize=10240
            eventCount=3
        fi
        writelog "Event using default eventSize=${eventSize} eventCount=${eventCount}"
    fi

    tmp=`getprop sys.wear.logkit.logtime`
    if [ "${tmp}" != "" ]; then
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/mobilelog/
    else
        LOGTIME=`date +%F-%H-%M-%S`
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${LOGTIME}/mobilelog/
        setprop sys.wear.logkit.logtime ${LOGTIME}
        setprop persist.sys.wear.logkit.logtime ${LOGTIME}
    fi
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ]; then
        mkdir -p  ${ROOT_DATA_apps_LOG_PATH}
    fi
}
function initKernel(){
    FreeMemory
    tmpKernel=`getprop persist.sys.log.kernel`
    if [ "${tmpKernel}" != "" ]; then
        #get the config size main
        kernelSize=`set -f;array=(${tmpKernel//|/ });echo "${array[0]}"`
        kernelCount=`set -f;array=(${tmpKernel//|/ });echo "${array[1]}"`
        writelog "kernelSize=${kernelSize} kernelCount=${kernelCount}"
    else
        if [ ${FreeSize} -ge 2301952 ]; then
            kernelSize=30720
            kernelCount=3
        elif [ ${FreeSize} -ge 1777664 ]; then
            kernelSize=30720
            kernelCount=2
        elif [ ${FreeSize} -ge 1253376 ]; then
            kernelSize=15360
            kernelCount=2
        else
            kernelSize=10240
            kernelCount=3
        fi
        writelog "Kernel using default kernelSize=${kernelSize} kernelCount=${kernelCount}"
    fi

    tmp=`getprop sys.wear.logkit.logtime`
    if [ "${tmp}" != "" ]; then
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/mobilelog/
    else
        LOGTIME=`date +%F-%H-%M-%S`
        ROOT_DATA_apps_LOG_PATH=${ROOT_DATA_PATH}/${LOGTIME}/mobilelog/
        etprop sys.wear.logkit.logtime ${LOGTIME}
        setprop persist.sys.wear.logkit.logtime ${LOGTIME}
    fi
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ]; then
        mkdir -p  ${ROOT_DATA_apps_LOG_PATH}
    fi
}
function initTcpdump(){
    FreeMemory
    tmpTcpdump=`getprop persist.sys.log.tcpdump`
    if [ "${tmpTcpdump}" != "" ]; then
        #get the config size main
        tcpdumpSize=`set -f;array=(${tmpTcpdump//|/ });echo "${array[0]}"`
        tcpdumpCount=`set -f;array=(${tmpTcpdump//|/ });echo "${array[1]}"`
        writelog "tcpdumpSize=${tcpdumpSize} tcpdumpCount=${tcpdumpCount}"
    else
        writelog "Tcpdump using default size and count"
        #one million bytes
        tcpdumpSize=100
        tcpdumpCount=1
    fi
        tmp=`getprop sys.wear.logkit.logtime`
        if [ "${tmp}" != "" ]; then
            ROOT_DATA_tcpdump_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/netlog/
        else
            LOGTIME=`date +%F-%H-%M-%S`
            ROOT_DATA_tcpdump_LOG_PATH=${ROOT_DATA_PATH}/${LOGTIME}/netlog/
            setprop sys.wear.logkit.logtime ${LOGTIME}
            setprop persist.sys.wear.logkit.logtime ${LOGTIME}
        fi
        if [ "${ROOT_DATA_tcpdump_LOG_PATH}" != "" ]; then
            mkdir -p  ${ROOT_DATA_tcpdump_LOG_PATH}
            chmod 777 ${ROOT_DATA_PATH}/${tmp}
        fi
}
function initModem(){
    tmpModem=`getprop persist.sys.log.modem`
    if [ "${tmpModem}" != "" ]; then
        #get the config size main
        modemSize=`set -f;array=(${tmpModem//|/ });echo "${array[0]}"`
        modemCount=`set -f;array=(${tmpModem//|/ });echo "${array[1]}"`
        writelog "modemSize=${modemSize} modemCount=${modemCount}"
    else
        writelog "Modem using default size and count"
        #MB
        modemSize=100
        modemCount=11
    fi
    tmp=`getprop sys.wear.logkit.logtime`
    if [ "${tmp}" != "" ]; then
        ROOT_DATA_modem_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/modem
    else
        LOGTIME=`date +%F-%H-%M-%S`
        ROOT_DATA_modem_LOG_PATH=${ROOT_DATA_PATH}/${tmp}/modem
        setprop sys.wear.logkit.logtime ${LOGTIME}
        setprop persist.sys.wear.logkit.logtime ${LOGTIME}
    fi
    if [ "${ROOT_DATA_modem_LOG_PATH}" != "" ]; then
        mkdir -p  ${ROOT_DATA_modem_LOG_PATH}
        chmod 777 ${ROOT_DATA_PATH}/${tmp}
    fi
}
function Logcat(){
    writelog "Logcat androidSize=${androidSize} androidCount=${androidCount} path=${ROOT_DATA_apps_LOG_PATH}"
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ] && [ ${FreeSize} -ge ${MSIZE} ]
    then
        tmp=$(add_file_count)
        echo "--------- beginning of newfile ---- index ${tmp} " >> ${ROOT_DATA_apps_LOG_PATH}/android.txt
        /system/bin/logcat -b default -f ${ROOT_DATA_apps_LOG_PATH}/android.txt -r ${androidSize} -n ${androidCount}  -v threadtime
    else
        setprop ctl.stop logcatsdcard
        writelog "ctl.stop logcatsdcard"
    fi
}
function LogcatRadio(){
    writelog "LogcatRadio radioSize=${radioSize} radioCount=${radioCount}"
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ] && [ ${FreeSize} -ge ${MSIZE} ]
    then
        echo "--------- beginning of newfile" >> ${ROOT_DATA_apps_LOG_PATH}/radio.txt
        /system/bin/logcat -b radio -f ${ROOT_DATA_apps_LOG_PATH}/radio.txt -r ${radioSize} -n ${radioCount}  -v threadtime
    else
        setprop ctl.stop logcatradio
    fi
}
function LogcatEvent(){
    writelog "LogcatEvent eventSize=${eventSize} eventCount=${eventCount}"
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ] && [ ${FreeSize} -ge ${MSIZE} ]
    then
    echo "--------- beginning of newfile" >> ${ROOT_DATA_apps_LOG_PATH}/events.txt
    /system/bin/logcat -b events -f ${ROOT_DATA_apps_LOG_PATH}/events.txt -r ${eventSize} -n ${eventCount}  -v threadtime
    else
    setprop ctl.stop logcatevent
    fi
}
function LogcatKernel(){
    writelog "LogcatKernel kernelSize=${kernelSize} kernelCount=${kernelCount} path=${ROOT_DATA_apps_LOG_PATH}"
    if [ "${ROOT_DATA_apps_LOG_PATH}" != "" ] && [ ${FreeSize} -ge ${MSIZE} ]
    then
    echo "--------- beginning of newfile" >> ${ROOT_DATA_apps_LOG_PATH}/kernel.txt
    /system/bin/logcat -b kernel -f ${ROOT_DATA_apps_LOG_PATH}/kernel.txt -r ${kernelSize} -n ${kernelCount}  -v threadtime
    else
    setprop ctl.stop logcatkernel
    fi
}
function Tcpdump(){
    writelog "Tcpdump tcpdumpSize=${tcpdumpSize} tcpdumpCount=${tcpdumpCount}"
    FreeMemory
    if [ "${ROOT_DATA_tcpdump_LOG_PATH}" != "" ] && [ ${FreeSize} -ge ${MSIZE} ]
    then
    /system/bin/tcpdump -i any -p -s 0 -W ${tcpdumpCount} -C ${tcpdumpSize} -w ${ROOT_DATA_tcpdump_LOG_PATH}/tcpdump -Z root
    else
    setprop ctl.stop tcpdump
    fi
}
function Diagmdlog(){
    writelog "Diagmdlog modemSize=${modemSize} modemCount=${modemCount}"
    FreeMemory
    if [ ${FreeSize} -ge ${MSIZE} ]
    then
    tmp=`getprop sys.wear.logkit.logtime`
    chmod 777 ${ROOT_DATA_PATH}/Diag.cfg
    chmod 777 ${ROOT_DATA_PATH}/${tmp}
    chmod 777 ${ROOT_DATA_modem_LOG_PATH}
    setprop vendor.logkit.modem.size ${modemSize}
    setprop vendor.logkit.modem.count ${modemCount}
    setprop ctl.start modem_vendor
    #/vendor/bin/diag_mdlog -f ${ROOT_DATA_PATH}/Diag.cfg -o ${ROOT_DATA_modem_LOG_PATH} -s ${modemSize} -n ${modemCount}  -c
    fi
}
function modem_stop(){
    logkit_modem_pid=(`ps -Af | grep mdlog | grep oppo_log`)
    kill ${logkit_modem_pid[1]}
}
function CopyLog(){
    echo "copylog 1200000000000" > /sys/power/wake_lock

    inTime=`getprop sys.wear.logkit.logtime`
    outTime=`getprop persist.sys.wear.boottime`
    endtime=`getprop persist.sys.logkit.endtime`

    if [ -f /data/oppo_log/Diag.cfg ]; then #for modem
        modem_delay=0
        pid=(`ps -Af | grep mdlog | grep oppo_log`)
        while [ ${pid[1]} != "" ] && [ ${modem_delay} -lt 15 ];do
            sleep 1
            modem_delay=`expr $modem_delay + 1`
            pid=(`ps -Af | grep mdlog | grep oppo_log`)
        done
    fi

    mkdir -p /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}

    if [ "${outTime}" != "" ]; then
        mv -f /data/oppo_log/${inTime} /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/${outTime}
        writelog "`ls -R /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}`"
    fi

    writelog "CopyLog ${endtime}"
    mkdir -p /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/uefi
    mkdir -p /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/btsnoop_hci
    mv -f /data/oppo_log/Diag.cfg /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    mv -f /data/oppo_log/logInfo.txt /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    mv -f /data/oppo_log/mcu_log /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    mv -f /data/local/traces/. /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/traces/
    mv -f /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/trigger /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/


    skip_report=`getprop persist.sys.wear.logkit.skip_report`
    if [ "${skip_report}" == "1"  ] || [  ! -d /sdcard/Android/  ]
    then
        writelog "skip ${skip_report}"
    else
        setprop dumpstate.options heytap
        bgpath=`bugreportz`
        writelog "bgpath ${bgpath}"
        result=${bgpath#*OK:}
        setprop dumpstate.options ""
        writelog "result ${result}"
    fi

    copy_dir data/misc/bluetooth/logs sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/btsnoop_hci/
    copy_dir /data/oppo_log /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    mv -f /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/shlog.txt /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/shlog.txt

    cp -r /data/anr/. /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/anr/
    cp -r /data/tombstones/. /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/tombstones/
    cp -r /cache/recovery /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    cp -r /sys/fs/pstore/dmesg-ramoops-0 /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    cp -r /data/oplusreserve/media/log/. /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/reserve3
    cp -r /data/oppo/common/mcudump /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/mcu_log/
    dd if=/dev/block/platform/soc/4744000.sdhci/by-name/logfs of=/sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/uefi/logfs


    mcu_wait=`getprop sys.wear.logkit.mcuoffline.wait`
    if [ "${mcu_wait}" != "" ]; then #for mcu
        mcu_delay=0
        writelog "mcu_wait ${mcu_wait}  mcu_delay ${mcu_delay} `date +%F-%H-%M-%S`"
        while ([ "${mcu_wait}" = "2" ] && [ ${mcu_delay} -lt 5 ]) || ([ "${mcu_wait}" = "1" ] && [ ${mcu_delay} -lt 300 ]);do
            sleep 1
            mcu_delay=`expr $mcu_delay + 1`
            mcu_wait=`getprop sys.wear.logkit.mcuoffline.wait`
            writelog "mcu_wait ${mcu_wait}  mcu_delay ${mcu_delay}"
        done
    fi

    if [ -d  /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log ]; then
        mkdir -p /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/mcu_log
        copy_dir_rename /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/gps /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/mcu_log/gps
        copy_dir_rename /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/offline /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/mcu_log/offline
        rmdir /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log
    fi

    setprop sys.wear.logkit.mcuoffline.wait ""

    cat /data/oppo_log/shlog.txt >> /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/shlog.txt
    rm -f /data/oppo_log/shlog.txt


    if [ `getprop persist.sys.special.version` == "true" ]; then
        echo  "`date +%F-%H-%M-%S-%N` ls SensorTools2:  `ls -R /sdcard/Android/data/com.heytap.sensortools/files/SensorTools2`" >> /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/shlog.txt
        mv -f  /sdcard/Android/data/com.heytap.sensortools/files/SensorTools2 /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/
    fi

    logcat -d > /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/copylog.txt

    chown system:ext_data_rw -R /sdcard/Android/data/com.heytap.wearable.logkit/files
    chmod 770 -R /sdcard/Android/data/com.heytap.wearable.logkit/files


    if [ `getprop sys.wear.logkit.mode` == "1" ]; then
        am start -n com.heytap.wearable.logkit/.main.LogkitSaveDialogActivity  -e folder_name /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}
    fi

    am start-service -n com.heytap.wearable.logkit/.upload.ocloud.UploadAllService -e folder_name /sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}

    setprop sys.wear.logkit.mode ""
    setprop sys.wear.logkit.logtime ""
    setprop persist.sys.wear.logkit.logtime ""
    setprop persist.sys.wear.boottime ""
    setprop sys.log.main ""
    setprop persist.sys.wear.logkit.filecount ""
    echo "copylog" > /sys/power/wake_unlock
    setprop persist.sys.collectlog.copy false
}
function copy_dir(){
    for file in `ls $1`
    do
        local src=$1"/"$file
        local dest=$2"/"$file
        size=`du -s $src`
        count=`set -f;array=(${size// / });echo "${array[0]}"`

        if [ ! -d $src ]; then
            writelog "file $src move to $dest"
            mv -f $src  $dest
        elif [ $count -ge 102400 ]; then
            writelog "mkdir $dest"
            mkdir -p $dest
            copy_dir $src $dest
            rmdir $src
        else
            writelog "move dir $src/. to $dest"
            mv -f $src/. $dest
            rmdir $src
        fi
    done
}
function copy_dir_rename(){
    if [ -d $2 ]; then
        writelog "$2 exist!! aa"
        local src=$1/*
        writelog "$2 exist!! copy sub: $src : `ls -R $src` "
        mv -f $src $2
        writelog "copy end `ls -R $2`"
        rm -rf $1
    else
        writelog "$2 do not exist or a file, copy $1 to $2"
        mv -f $1 $2
        rm -rf $1
    fi
}
function cleanlog(){
    case $1 in
        "history")
            if [  -d /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log ]; then
                if [  ! -d /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log ]; then
                    writelog "copy11 `ls -R /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/`"
                    mv -f /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log
                else
                    writelog "copy22 `ls -R /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/`"
                    mv -f /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/* /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/
                    mv -f /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/mcu_log/* /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/
                    mv -f /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/mcu_log/offline/* /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/offline/
                    mv -f /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/mcu_log/gps/* /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/gps/
                    rm -rf /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oppo_log/
                fi
            fi
            find /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log -maxdepth 1 -mtime +7  -not -name oplus_log -not -name mcu_log  -exec rm -rf {} \;   #抓取中的mcu_log也在此目录，不能直接删，并且mcu_log里新增文件不会更新oppo_log的时间，为了避免删掉oppo_log时把抓取中的小核log也删掉所以要排除他俩
            find /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/offline -mtime +3  -exec rm -rf {} \;  #单独删小核log
            find /storage/emulated/0/Android/data/com.heytap.wearable.logkit/files/oplus_log/mcu_log/gps -mtime +3  -exec rm -rf {} \;  #单独删小核GPSlog
            chmod 770 -R /sdcard/Android/data/com.heytap.wearable.logkit/files
            chown system:ext_data_rw -R /sdcard/Android/data/com.heytap.wearable.logkit/files
            if [ `getprop persist.sys.special.version` == "true" ]; then
                pm enable com.heytap.wearable.logkit/.IconMainActivity
            fi
        ;;
        "cache")
            tmp=`getprop persist.sys.collectlog.copy`
            if [ ! ${tmp} ] || [ ${tmp} != "" ]; then
                tmp=`getprop sys.wear.logkit.logtime`
                writelog "clean cache `find /data/oppo_log -maxdepth 1 -mtime +4  -not -name ${tmp}`"
                find /data/oppo_log  -name "*-*-*-*-*-*" -maxdepth 1 -mtime +4  -not -name ${tmp} -exec rm -rf {} \;
            fi
        ;;
        esac
}
function dump_system_state(){
    if [ `getprop persist.sys.collectlog.copy` == "true" ]; then
        endtime=`getprop persist.sys.logkit.endtime`
        if [ "${endtime}" != "" ]; then
            LOG_PATH=/sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/${endtime}/trigger
        else
            LOG_PATH=/sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/trigger
        fi
    else
        LOG_PATH=/sdcard/Android/data/com.heytap.wearable.logkit/files/oplus_log/trigger
    fi
    tmp=`date +%F-%H-%M-%S`
    mkdir -p ${LOG_PATH}
    case $1 in
        "storage")
            echo "mount------------------------------------------------" > ${LOG_PATH}/storage_${tmp}.txt
            mount >> ${LOG_PATH}/storage_${tmp}.txt
            echo "\n\ndumpsys devicestoragemonitor---------------------" >> ${LOG_PATH}/storage_${tmp}.txt
            dumpsys devicestoragemonitor >> ${LOG_PATH}/storage_${tmp}.txt
            echo "\n\ndumpsys mount------------------------------------" >> ${LOG_PATH}/storage_${tmp}.txt
            dumpsys mount >> ${LOG_PATH}/storage_${tmp}.txt
            echo "\n\n dumpsys diskstats-------------------------------" >> ${LOG_PATH}/storage_${tmp}.txt
            dumpsys diskstats >> ${LOG_PATH}/storage_${tmp}.txt
        ;;
        "top")
            top -n 2 -d 1 -b > ${LOG_PATH}/top_${tmp}.txt
            chmod 777 -R /${LOG_PATH}
        ;;
        "ps")
            ps -A > ${LOG_PATH}/ps_${tmp}.txt
        ;;
        "service_list")
            service list > ${LOG_PATH}/service_list_${tmp}.txt
        ;;
        "bugreport")
            bugreport > ${LOG_PATH}/bugreport_${tmp}.txt
        ;;
        "dumpsys")
            dumpsys > ${LOG_PATH}/dumpsys_${tmp}.txt
        ;;
       "dumpstate")
            dumpstate > ${LOG_PATH}/dumpstate_${tmp}.txt
        ;;
    esac
    echo "dump done"
}
function set_tp_level(){
    echo `getprop persist.sys.collectlog.tplevel` > /proc/touchpanel/debug_level
}
function FreeMemory(){
    DataSize=`df /data | grep /dev`
    array=(`echo $DataSize | tr ',' ' '` )
    index=1
    for var in ${array[@]}
    do
        if ((index==4)); then
            FreeSize=$var
        fi
        ((index++))
    done
    writelog "FreeSize=${FreeSize}"
    MSIZE=512000
}
function writelog(){
    echo  " `date +%F-%H-%M-%S-%N` $1"
    if [ "${shlog}" != "" ]; then
        echo  "`date +%F-%H-%M-%S-%N` $1" >> /data/oppo_log/shlog.txt
    fi
}
function heypower_bugreport(){
    tmp=`getprop init.svc.dumpstate`
    dump_delay=0
    while [ "${tmp}" = "running" ] && [ ${dump_delay} -lt 40 ];do
        sleep 1
        dump_delay=`expr $dump_delay + 1`
        tmp=`getprop init.svc.dumpstate`
        writelog "bugreport ${tmp}, ${dump_delay}"
    done
    if [ "${tmp}" != "running" ]; then
        setprop dumpstate.options bugreportpower
        path=`getprop sys.wear.logkit.reportpath`
        writelog "report path ${path}"
        if [ "${path}" != "" ]; then
            bugreport > ${path}/bugreport.txt
            if [ `getprop persist.sys.special.version` == "true" ]; then
                cp data/system/stamp.db ${path}/stamp.db
            fi
            tar -C ${path} -czvf ${path}/bugreport.tar.gz bugreport.txt stamp.db
            rm -rf ${path}/bugreport.txt ${path}/stamp.db
            chmod 666 ${path}/bugreport.tar.gz
        else
            bugreport > /data/anr/power/power.txt
            chmod 666 /data/anr/power/power.txt
        fi
    fi
    setprop sys.wear.logkit.reportpath ""
}
#do not writelog in this func
function add_file_count(){
    tmp=`getprop persist.sys.wear.logkit.filecount`
    ((tmp++))
    setprop persist.sys.wear.logkit.filecount ${tmp}
    echo ${tmp};
}
case "$config" in
    "init_logkit")
        init_logkit
        ;;
    "onboot_logkit")
        onboot_logkit
        ;;
    "main")
        initAndroid
        Logcat
        ;;
    "radio")
        initRadio
        LogcatRadio
        ;;
    "event")
        initEvent
        LogcatEvent
        ;;
    "kernel")
        initKernel
        LogcatKernel
        ;;
    "tcpdump")
        initTcpdump
        Tcpdump
        ;;
    "dump_system_state")
        dump_system_state $2
        ;;
    "settplevel")
        set_tp_level
        ;;
    "modem")
        initModem
        Diagmdlog
        ;;
     "modem_stop")
        modem_stop
        ;;
    "copylog")
        CopyLog
        ;;
    "cleanlog")
        cleanlog $2
        ;;
    "heypower_bugreport")
        heypower_bugreport
        ;;

    "hiderecord")
        hiderecord
        ;;
    "force_suspend")
        force_suspend
        ;;
    "add_sid")
        add_sid
        ;;
    "remove_sid")
        remove_sid
        ;;
    "smart_mode_balance")
        smart_mode_balance
        ;;
    "smart_mode_perf")
        smart_mode_perf
        ;;
esac
