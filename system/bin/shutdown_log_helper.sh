#! /system/bin/sh

LOG_DEV="/dev/block/by-name/oplusreserve3"
SHD_LOG_DIR="/data/oplusreserve/media/log/shutdown"
SHD_LOG_FILE_PATTERN="shutdown_log"
ANR_TRACE_DIR="/data/anr"
SYSTEM_SERVER_OFFSET=60
MAX_SHD_LOG_COUNT=4

TMP_DIR="/cache/shutdown_$(date +"%Y%m%d%H%M%S_%N")"
TIME_BEGIN_TO_COLLECT_LOG=$(date +%s)

ERROR_FUNC_MAP_KEY=("GET_ANDROID_LOG"
                    "SHUTDOWN_LOG_READBACK"
                      )

ERROR_FUNC_MAP_VAL=("collect_android_log"
                    "readback_shutdown_log"
                      )

function print_dir_filelist()
{
    dir=$1
    list=$2
    echo "dir filelist count ${#list[@]}"
    for val in ${list[*]}
    do
        echo "${val} modiy time: $(stat -c %Y ${dir}/${val})"
    done
}

function remove_the_older_file_if_need()
{
    dir=$1
    file_pattern=$2
    max_file_count=$3
    i=0
    for file in $(ls -rt ${dir}/ | grep ${file_pattern})
    do
        echo "${file}"
        file_list[$i]="${file}"
        ((i++))
    done
    echo "file list count ${#file_list[@]} max_file_count $max_file_count"
    print_dir_filelist ${dir} "${file_list[*]}"
    file_count=${#file_list[@]}
    if [ ${file_count} -lt ${max_file_count} ]; then
        return 0
    else
        ((file_need_remove_count=${file_count} - ${max_file_count} + 1))
        echo "file_need_remove_count=${file_need_remove_count}"
        for j in $(seq 1 ${file_need_remove_count})
        do
            echo "will remove ${file_list[(($j-1))]}"
            rm -f ${dir}/${file_list[(($j-1))]}
        done
    fi
    return 0
}

function search_latest_file()
{
    search_dir=$1
    file=$(ls -t ${search_dir} | sed -n "1p")
    echo ${file}
}

function collect_system_server_trace_log()
{
    system_server_pid=$(pidof system_server)
    if [ "${system_server_pid}" != "" ]; then
        kill -3 ${system_server_pid}
        sleep 10
        system_server_trace_file=$(search_latest_file ${ANR_TRACE_DIR})
        dd if=${ANR_TRACE_DIR}/${system_server_trace_file} of=${LOG_DEV} bs=10480 seek=${SYSTEM_SERVER_OFFSET}
    fi
}

function collect_android_log()
{
    echo w > /proc/sysrq-trigger
    echo l > /proc/sysrq-trigger
    dd if=dev/zero of=sdcard/zero4 bs=1m count=4
    dd if=dev/zero of=sdcard/zero15 bs=1m count=15
    dd if=sdcard/zero15 of=dev/block/bootdevice/by-name/oplusreserve3
    dd if=sdcard/zero4 of=dev/block/bootdevice/by-name/oplusreserve3 bs=10480 seek=${SYSTEM_SERVER_OFFSET}
    rm -rf sdcard/zero15
    rm -rf sdcard/zero4
    logcat -b crash -b main -b system > ${LOG_DEV} &
    collect_system_server_trace_log
}

function readback_shutdown_log()
{
    echo "TIME_BEGIN_TO_COLLECT_LOG=${TIME_BEGIN_TO_COLLECT_LOG}"
    collect_tmp_dir=${TMP_DIR}
    if [ ! -d ${SHD_LOG_DIR} ];
    then
        mkdir -m 0777 -p ${SHD_LOG_DIR}
    fi
    rm -rf ${collect_tmp_dir}
    mkdir -m 0770 ${collect_tmp_dir}

    dd if=${LOG_DEV} of=${collect_tmp_dir}/oplusreserve3

    file_count=$(ls -A ${collect_tmp_dir} | wc -w)
    if [ ${file_count} -gt 0 ] ;
    then
        remove_the_older_file_if_need ${SHD_LOG_DIR} ${SHD_LOG_FILE_PATTERN} ${MAX_SHD_LOG_COUNT}
        tar -czvf ${SHD_LOG_DIR}/${SHD_LOG_FILE_PATTERN}_$(date +%F-%H-%M-%S).tz  ${collect_tmp_dir}/*
        rm -rf ${collect_tmp_dir}
    fi
    chgrp -R system ${SHD_LOG_DIR}
    chmod -R 777 ${SHD_LOG_DIR}
    chown -R system ${SHD_LOG_DIR}
}

function shd_log_native_helper_main()
{
    argv=$1
    echo "argument $argv"
    for i in $(seq 1 ${#ERROR_FUNC_MAP_KEY[@]})
    do
        if [ ${argv} == ${ERROR_FUNC_MAP_KEY[(($i-1))]} ] ;
        then
            echo "matched will run ${ERROR_FUNC_MAP_VAL[(($i-1))]}"
            ${ERROR_FUNC_MAP_VAL[(($i-1))]}
        fi
    done
}

shd_log_native_helper_main $1
