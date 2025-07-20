#! /system/bin/sh

STARTUP_LOG_DRIVER="/proc/startup_log"
DROPBOX_DIR="/data/system/dropbox"
TOMBSTONE_DIR="/data/tombstones"
ANR_TRACE_DIR="/data/anr"
TIME_BEGIN_TO_COLLECT_LOG=$(date +%s)

SYSTEM_SERVER_CRASH_FILE_PATTERN="system_server_crash"
SYSTEM_SERVER_WATCHDOG_FILE_PATTERN="system_server_watchdog"
TMP_DIR="/cache/startup_log_$(date +"%Y%m%d%H%M%S_%N")"
OPLUSRESERVE2_MOUNT_POINT="/data/oplusreserve"

LOG_DIR="/data/oplusreserve/media/log"
STARTUP_LOG_DIR="/data/oplusreserve/media/log/hang"
STARTUP_LOG_FILE_PATTERN="hang_oplus_log"
MAX_STARTUP_LOG_COUNT=4
PHX_TIME_INTERVAL=60

OPLUSRESERVE2_PARTITION_AVAILABLE=0


ERROR_FUNC_MAP_KEY=("ERROR_HANG_OPLUS"
                    "ERROR_CRITICAL_SERVICE_CRASHED_4_TIMES"
                    "ERROR_SYSTEM_SERVER_WATCHDOG"
                    "ERROR_NATIVE_REBOOT_INTO_RECOVERY"
                    )


ERROR_FUNC_MAP_VAL=("collect_hang_oplus_log"
                    "collect_critical_service_crash_4_times_log"
                    "collect_system_server_watchdog_log"
                    "collect_native_reboot_into_recovery_log"
                    )

function generate_keyfinfo()
{
    key_info_file=$1
    echo "happen_time: ${TIME_NOW_IN_LOCALTIME}" > ${key_info_file}
    boot_stage=$(cat /proc/startup_log | grep "STAGE" | sed -n '$p')
    echo "boot_stage: ${boot_stage}" >> ${key_info_file}
    echo "boot_time: ${BOOT_TIME:1}" >> ${key_info_file}
    data_capcity=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f2)
    data_usage=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f3)
    data_left=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    data_usage_ratio=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f5)
    echo "data_capcity: ${data_capcity}" >> ${key_info_file}
    echo "data_usage: ${data_usage}" >> ${key_info_file}
    echo "data_left: ${data_left}" >> ${key_info_file}
    echo "data_usage_ratio: ${data_usage_ratio}" >> ${key_info_file}
    echo "platform: $PLATFORM" >> ${key_info_file}

    if [ -f "/proc/devinfo/ufs" ]; then
        flash_type="UFS"
    else
        flash_type="EMMC"
    fi
    if [ "${flash_type}" == "UFS" ]; then
        flash_info_file="/proc/devinfo/ufs"
    else
        flash_info_file="/proc/devinfo/emmc"
    fi
    flash_manufacture=$(cat ${flash_info_file} | grep manufacture | cut -d ":" -f2 | sed 's/\t//g')
    flash_version=$(cat ${flash_info_file} | grep version | cut -d ":" -f2 | sed 's/\t//g')
    echo "flash_type: ${flash_type}" >> ${key_info_file}
    echo "flash_manufacture: ${flash_manufacture}" >> ${key_info_file}
    echo "flash_version: ${flash_version}" >> ${key_info_file}
}
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
function check_oplusreserve2_is_available()
{
    log_collect_dir=$1
    #echo $log_collect_dir
    log_pack_size=$(du -sk $log_collect_dir | sed 's/[[:space:]]/,/g' | cut -d "," -f1)
    oplusreserve2_remainsize=$(df -k ${LOG_DIR} | grep "${LOG_DIR}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    echo "log_pack_size $log_pack_size"
    echo "oplusreserve2_remainsize $oplusreserve2_remainsize"
    if [ "x$log_pack_size" == "x" -o "x$oplusreserve2_remainsize" == "x" ]; then
        OPLUSRESERVE2_PARTITION_AVAILABLE=0
        return 0
    fi
    while [ "$oplusreserve2_remainsize" -lt "$log_pack_size" ];
    do
        oldest_file=$(ls -rt ${STARTUP_LOG_DIR} | sed -n "1p")
        if [ "x$oldest_file" != "x" ] ;
        then
            rm -rf ${STARTUP_LOG_DIR}/$oldest_file
            #echo "remove ${STARTUP_LOG_DIR}/$oldest_file"
        else
            OPLUSRESERVE2_PARTITION_AVAILABLE=0
            return 0
        fi
        #oplusreserve2_remainsize=$(df -k | grep "${OPLUSRESERVE2_MOUNT_POINT}"  | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
        #echo "oplusreserve2_remainsize $oplusreserve2_remainsize"
    done
    OPLUSRESERVE2_PARTITION_AVAILABLE=1
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
function is_file_modify_in_the_past_interval()
{
    file=$1
    base_time=$2
    interval=$3
    file_modify_time=$(stat -c %Y ${file})
    echo "latest_file=${file} modify_time=${file_modify_time}" > /dev/zero
    ((time_past=${base_time} - ${file_modify_time}))
    echo "time_past = $time_past" > /dev/zero
    if [ ${time_past} -lt ${interval} ];
    then
        return 1
    fi
    return 0
}

function search_latest_file_with_pattern()
{
    search_dir=$1
    search_pattern=$2
    file=$(ls -t ${search_dir} | grep ${search_pattern}| sed -n "1p")
    echo ${file}

}

function search_latest_file()
{
    search_dir=$1
    file=$(ls -t ${search_dir} | sed -n "1p")
    echo ${file}
}
function collect_ftrace_log()
{
    cat /proc/interrupts > ${1}/interrupts_before_ftrace.txt
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    echo 32768 > /sys/kernel/debug/tracing/buffer_size_kb
    echo "" > /sys/kernel/debug/tracing/trace
    echo 1  > /sys/kernel/debug/tracing/events/irq/enable
    echo 1  > /sys/kernel/debug/tracing/events/irq/filter
    echo 1  > /sys/kernel/debug/tracing/events/irq/softirq_entry/enable
    echo 1  > /sys/kernel/debug/tracing/events/irq/softirq_exit/enable
    echo 1  > /sys/kernel/debug/tracing/events/irq/softirq_raise/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_blocked_reason/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_enq_deq_task/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_find_best_target/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_isolate/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_migrate_task/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_preempt_disable/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_set_preferred_cluster/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_stat_blocked/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_stat_iowait/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_wakeup/enable
    echo 1  > /sys/kernel/debug/tracing/events/sched/sched_waking/enable
    cache_remainsize=$(df -k | grep "cache" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    echo "cache_remainsize=${cache_remainsize}"
    #Save ftrace to tmp_dir when cache size more than 128MB
    if [ "cache_remainsize" -gt "131027" ] ;
    then
        echo 1  > /sys/kernel/debug/tracing/tracing_on
        cat /sys/kernel/debug/tracing/trace_pipe | head -n 600000 > ${1}/ftrace.txt &
    else
        echo "Save ftrace need cache size more than 128MB,cache size is ${cache_remainsize}KB" > ${1}/ftrace.txt &
    fi
    sleep 30
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    tar -czvf ${1}/ftrace.tz ${1}/ftrace.txt
    rm -f ${1}/ftrace.txt
    cat /proc/interrupts > ${1}/interrupts_after_ftrace.txt
}

function collect_basic_log()
{
    echo w > /proc/sysrq-trigger
    echo l > /proc/sysrq-trigger
    dmesg > ${1}/dmesg.txt
    BOOT_TIME=$(cat ${1}/dmesg.txt | sed -n '$p' | cut -d "]" -f1 | sed 's/ //g')
    # in some case, logcat will hang, so we collect android log to backgroud
    logcat -b crash -b main -b system -d -v threadtime > ${1}/android.txt &
    logcat -b radio -d -v threadtime > ${1}/radio.txt &
    logcat -b events -d -v threadtime > ${1}/events.txt &
    sleep 3
}


function collect_binder_transition_log()
{
    cat /d/binder/transactions > ${1}/binder_transaction.txt
    cat /d/binder/state > ${1}/binder_state.txt
}

function collect_auxiliary_log()
{
    ps -AT > ${1}/ps_thread.txt
    mount > ${1}/mount.txt
    cp -rf /data/system/packages.xml ${1}/packages.xml
    cat /proc/meminfo > ${1}/proc_meminfo.txt
    #cat /d/ion/heaps/system > ${1}/iom_system_heaps.txt
    df -k > ${1}/df.txt
    #getprop > ${1}/props.txt

}

function collect_native_trace_log()
{
    process_name=$1
    file_save_dir=$2
    pid=$(pidof ${process_name})
    echo "process_name = $process_name pid = $pid"
    if [ "${pid}" == "" ];
    then
        echo "${process_name} not runing"
        return 0
    fi
    debuggerd -b ${pid} > ${file_save_dir}/${process_name}_bt.txt
    for child_tid in $(ls /proc/${pid}/task)
    do
        echo "--------- tid = ${child_tid} ---------" >> ${file_save_dir}/${process_name}_bt.txt
        cat /proc/${pid}/task/${child_tid}/stack >> ${file_save_dir}/${process_name}_bt.txt
        echo >> ${file_save_dir}/${process_name}_bt.txt
    done
}

function collect_system_server_trace_log()
{
    file_save_dir=$1
    system_server_pid=$(pidof system_server)
    kill -3 ${system_server_pid}
    sleep 5
    system_server_trace_file=$(search_latest_file ${ANR_TRACE_DIR})
    cp -a ${ANR_TRACE_DIR}/${system_server_trace_file} ${file_save_dir}/system_server_bt.txt
}
function search_latest_file_in_dropbox()
{
    file_pattern=$1
    time_begin=$2
    time_interval=$3
    latest_file=$(search_latest_file_with_pattern ${DROPBOX_DIR} ${file_pattern})
    if [ "${latest_file}" != "" ] ;
    then
        latest_file_full_path=${DROPBOX_DIR}/${latest_file}
        is_file_modify_in_the_past_interval ${latest_file_full_path} ${time_begin} ${time_interval}
        if [ "$?" == "1" ] ;
        then
            echo ${latest_file}
        fi
    fi
    echo ""
}



function collect_system_server_crash_log()
{
    file_save_dir=$1
    system_server_crash_log=$(search_latest_file_in_dropbox ${SYSTEM_SERVER_CRASH_FILE_PATTERN} ${TIME_BEGIN_TO_COLLECT_LOG} ${PHX_TIME_INTERVAL})
    if [ "${system_server_crash_log}" != "" ] ;
    then
        cp -a ${DROPBOX_DIR}/${system_server_crash_log} ${file_save_dir}/${system_server_crash_log}
    fi
}

function collect_critical_service_tombstone_log()
{
    file_save_dir=$1
    critical_service_tombstone_log=$(search_latest_file ${TOMBSTONE_DIR})
    if [ "${critical_service_tombstone_log}" != "" ] ;
    then
        critical_service_tombstone_log_full_path=${TOMBSTONE_DIR}/${critical_service_tombstone_log}
        is_file_modify_in_the_past_interval ${critical_service_tombstone_log_full_path} ${TIME_BEGIN_TO_COLLECT_LOG} PHX_TIME_INTERVAL
        if [ "$?" == "1" ] ;
        then
            cp -a ${TOMBSTONE_DIR}/${critical_service_tombstone_log} ${file_save_dir}/${critical_service_tombstone_log}
        fi
    fi
}

function collect_system_server_watchdog_log()
{
    tmp_dir=$1
    #collect_ftrace_log ${tmp_dir}
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    system_server_watchdog_log=$(search_latest_file_in_dropbox ${SYSTEM_SERVER_WATCHDOG_FILE_PATTERN} ${TIME_BEGIN_TO_COLLECT_LOG} ${PHX_TIME_INTERVAL})
    if [ "${system_server_watchdog_log}" != "" ] ;
    then
        cp -a ${DROPBOX_DIR}/${system_server_watchdog_log} ${tmp_dir}/${system_server_watchdog_log}
    fi
    generate_keyfinfo ${tmp_dir}/ERROR_SYSTEM_SERVER_WATCHDOG
}
function collect_critical_service_crash_4_times_log()
{
    tmp_dir=$1
    #sleep 3
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    collect_system_server_crash_log ${tmp_dir}
    collect_critical_service_tombstone_log ${tmp_dir}
    generate_keyfinfo ${tmp_dir}/ERROR_CRITICAL_SERVICE_CRASHED_4_TIMES
}

function collect_native_reboot_into_recovery_log()
{
    tmp_dir=$1
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    generate_keyfinfo ${tmp_dir}/ERROR_NATIVE_REBOOT_INTO_RECOVERY
}
function collect_hang_oplus_log()
{
    tmp_dir=$1
    #collect_ftrace_log ${tmp_dir}
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    collect_binder_transition_log ${tmp_dir}
    collect_system_server_trace_log ${tmp_dir}
    collect_native_trace_log "surfaceflinger" ${tmp_dir}
    collect_native_trace_log "installd" ${tmp_dir}
    collect_native_trace_log "dex2oat" ${tmp_dir}
    generate_keyfinfo ${tmp_dir}/ERROR_HANG_OPLUS
}

function log_native_helper_main()
{
    echo "TIME_BEGIN_TO_COLLECT_LOG=${TIME_BEGIN_TO_COLLECT_LOG}"
    startup_log_error=$1
    collect_tmp_dir=${TMP_DIR}
    if [ ! -d ${OPLUSRESERVE2_MOUNT_POINT} ] ;
    then
        sleep 5
    fi
    if [ ! -d ${OPLUSRESERVE2_MOUNT_POINT} ] ;
    then
        echo "[STARTUP_LOG] oplusreserve2 not mount!" > /dev/kmsg
        return 0
    fi
    if [ ! -d ${STARTUP_LOG_DIR} ];
    then
        mkdir -p ${STARTUP_LOG_DIR}
    fi
    rm -rf ${collect_tmp_dir}
    mkdir -m 0770 ${collect_tmp_dir}
    echo "startup_log_error $startup_log_error"
    for i in $(seq 1 ${#ERROR_FUNC_MAP_KEY[@]})
    do
        if [ ${startup_log_error} == ${ERROR_FUNC_MAP_KEY[(($i-1))]} ] ;
        then
            echo "matched will run ${ERROR_FUNC_MAP_VAL[(($i-1))]}"
            ${ERROR_FUNC_MAP_VAL[(($i-1))]} ${collect_tmp_dir}
            file_count=$(ls -A ${collect_tmp_dir} | wc -w)
            if [ ${file_count} -gt 0 ] ;
            then
                remove_the_older_file_if_need ${STARTUP_LOG_DIR} ${STARTUP_LOG_FILE_PATTERN} ${MAX_STARTUP_LOG_COUNT}
                check_oplusreserve2_is_available  ${collect_tmp_dir}
                if [ "$OPLUSRESERVE2_PARTITION_AVAILABLE" == "1" ] ;
                then
                    tar -czvf ${STARTUP_LOG_DIR}/${STARTUP_LOG_FILE_PATTERN}_$(date +%F-%H-%M-%S).tz  ${collect_tmp_dir}/*
                fi
            else
                rm -rf ${collect_tmp_dir}
                exit 0
            fi
        fi
    done
    rm -rf ${collect_tmp_dir}
    chmod -R 0770 ${STARTUP_LOG_DIR}
    chgrp -R system ${STARTUP_LOG_DIR}
    chown -R system ${STARTUP_LOG_DIR}
}

function start_poweron_log(){
    /system/bin/logcat -b all -f ${LOG_DIR}/poweron/poweron.txt -r 1024 -n 2  -v threadtime &
    sleep 120
    poweron_logcat_pid=$(ps -Af | grep "${LOG_DIR}/poweron.txt" | sed 's/[ ][ ]*/,/g'| sed -n '/logcat/p' | cut -d "," -f2)
    kill -9 $poweron_logcat_pid
}
function start_recovery_log(){
    /system/bin/logcat -b all -f ${LOG_DIR}/poweron/recovery.txt -r 1024 -n 2  -v threadtime &
    sleep 120
    recovery_logcat_pid=$(ps -Af | grep "${LOG_DIR}/recovery.txt" | sed 's/[ ][ ]*/,/g'| sed -n '/logcat/p' | cut -d "," -f2)
    kill -9 $recovery_logcat_pid
}
function stop_poweron_log(){
    poweron_logcat_pid=$(ps -Af | grep "${LOG_DIR}/poweron.txt" | sed 's/[ ][ ]*/,/g'| sed -n '/logcat/p' | cut -d "," -f2)
    sleep 10
    kill -9 $poweron_logcat_pid
}
#Zhiwen.Li@Framework.Stability, 2021/04/26, add for diagnosis
function clear_pmic_ocp_value()
{
    dd if=/dev/zero of=/dev/block/by-name/oplusreserve1 bs=512 seek=9004 count=2
}
case "$1" in
    "clear_pmic_ocp_value")
        clear_pmic_ocp_value
        ;;
    "start_poweron_log")
        start_poweron_log
        ;;
    "stop_poweron_log")
        stop_poweron_log
        ;;
    "start_recovery_log")
        start_recovery_log
        ;;
    *)
if [ -f ${STARTUP_LOG_DRIVER} ]; then
    log_native_helper_main $1
fi
    ;;
esac
