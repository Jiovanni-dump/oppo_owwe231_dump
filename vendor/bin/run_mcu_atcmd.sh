#!/vendor/bin/sh
atcmd=`getprop debug.mcu_atcmd`
if [ "$atcmd" != "" ];then
    echo "at+$atcmd\r\n" > /dev/mcu_factory
    timeout 2 cat /dev/mcu_factory
else
    echo "debug.mcu_atcmd not set"
fi
