#!/vendor/bin/sh
bus=3
addr_dig=0x11
addr_pmu=0x27
addr_1806=0x17
addr_rf=0x16
addr_ana=0x15
addr_rc=0x1c
addr_xtal=0x1b
addr_emmc=0x19

symbols_file=/vendor/firmware/mcufirmware/$(getprop ro.build.product)/symbols.txt

function init()
{
    if [ -f  /vendor/lib/modules/i2c-gpio.ko ];then
        insmod /vendor/lib/modules/i2c-gpio.ko
    fi
    if [ -f  /vendor_dlkm/lib/modules/i2c-dev.ko ];then
        insmod /vendor_dlkm/lib/modules/i2c-dev.ko
    fi
    if [ -f  /vendor_dlkm/lib/modules/i2c-gpio.ko ];then
        insmod /vendor_dlkm/lib/modules/i2c-gpio.ko
    fi

    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x50 0x58 w4@$addr_dig 0xCA 0xFE 0x02 0xF7
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0xCA 0xFE 0x02 0xF3 w4@$addr_dig 0xCA 0xFE 0x02 0xF1
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x50 0x58 w4@$addr_dig 0xCA 0xFE 0x02 0xF0
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x00 0xA0 w4@$addr_dig 0x00 0x00 0x10 0x00
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x00 0xCC w4@$addr_dig 0x00 0x00 0x00 0x04
}

function to_word()
{
awk '{print ""$1""substr($2,3)""substr($3,3)""substr($4,3)}'
}

function to_word_no_prefix()
{
awk '{print ""substr($1,3)""substr($2,3)""substr($3,3)""substr($4,3)}'
}


function from_word()
{
echo $1|awk '{print "0x"substr($1,3,2)" 0x"substr($1,5,2)" 0x"substr($1,7,2)" 0x"substr($1, 9,2)}'
}

function read_m55_pc()
{
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x01 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0xf4 r4 |to_word
}
function read_m55_lr()
{
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x09 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0xf4 r4 |to_word
}
function read_m55_sp()
{
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x11 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0xf4 r4 |to_word
}


function dump_sens_reg()
{
    echo "\npc:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x01 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0xf4 r4 |to_word

    echo "lr:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x09 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0xf4 r4 |to_word

    echo "sp:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0x54 w4@$addr_dig 0x00 0x00 0x11 0x03
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0xf4 r4 |to_word
}

function switch_jtag()
{
    echo "switch to jtag"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x00 0x04 w4@$addr_dig 0x00 0x00 0x00 0x08
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x60 0x0C w4@$addr_dig 0xFF 0xFF 0x22 0xFF
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x60 0x48 w4@$addr_dig 0x00 0x00 0x00 0x03
}
function dump_pmu()
{
    echo "pmu:"
    /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_pmu 0x00  r2
    /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_pmu 0x01  r2

}
function dump_others()
{
    echo "\n1806@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_1806 0x00  r2
    echo "\nrf@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_rf 0x00  r2
    echo "\nana@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_ana 0x00  r2
    echo "\nrc@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_rc 0x00  r2
    echo "\nxtal@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_xtal 0x00  r2
    echo "\nemmc@0x00:"
     /vendor/bin/i2ctransfer  -f -y $bus w1@$addr_emmc 0x00  r2
    echo "\naon cmu@0x40080000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x00 0x00  r4
    echo "\naon psc@0x40085000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x08 0x50 0x00  r4
    echo "\nsens cmu@0x58000000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x58 0x00 0x00 0x00  r4
    echo "\nsys cmu@0x50000000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x00 0x00 0x00  r4
    echo "\nbth cmu@0x40000000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x40 0x00 0x00 0x00  r4
    echo "\npsram mc@0x50180000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x18 0x00 0x00  r4
    echo "\npsram phy@0x50188000:"
    /vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig 0x50 0x18 0x80 0x00  r4
  
}

function deinit()
{
    rmmod i2c_gpio
    if [ -f  /vendor_dlkm/lib/modules/i2c-dev.ko ];then
        rmmod i2c_dev
    fi
}

function to_hex()
{
   printf "0x%x\n" $1
}
function read_addr()
{
echo -n "$1: "
/vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig $(from_word $1) r4|to_word
}

function read_addr_x()
{
/vendor/bin/i2ctransfer  -f -y $bus w4@$addr_dig $(from_word $1) r4|to_word
}
function read_addr_offset()
{
addr=$(($1 + $2))
read_addr $(to_hex $addr)
}
function read_addr_offset_x()
{
addr=$(($1 + $2))
read_addr_x $(to_hex $addr)
}

function read_addr_n()
{
beg=$(($1))
cnt=$2
end=$(( beg + cnt * 4 ))
addr=$beg
while [  $addr -lt $end ];
do
read_addr `printf "0x%x\n" $addr`
addr=$((addr + 4))
done
}

function dump_addr_n()
{
beg=$(($1))
cnt=$2
end=$(( beg + cnt * 4 ))
addr=$beg
offset=0
while [  $addr -lt $end ];
do
printf "0x%08x: " $addr
read_addr_x `printf "0x%x\n" $addr`
addr=$((addr + 4))
offset=$((offset +4))
done
}


#read 4 byte at 0x2c270e84
function dump_mem()
{
echo "\nmem@$1:"
dump_addr_n  $1 $2
}

function get_symbol_addr()
{
grep $1 $2 |awk '{print $2}'
}

#arg1 &pxCurrentTCB
function read_current_task()
{
    echo "\npxCurrentTCB:"
    read_addr $1
    echo "current task name:"
    read_addr_offset $(read_addr_x $1) 0x34
    read_addr_offset $(read_addr_x $1) 0x38
    echo "current task TopOfStack:"
    read_addr $(read_addr_x $1)
    echo "current task EndOfStack:"
    read_addr_offset $(read_addr_x $1) 0x4c

}

function do_dump()
{
init
dump_pmu
#dump_other
m55_pc_1=$(read_m55_pc)
m55_lr_1=$(read_m55_lr)
m55_sp_1=$(read_m55_sp)
echo "pc:"
echo $m55_pc_1
echo "lr:"
echo $m55_lr_1
echo "sp:"
echo $m55_sp_1
#dump twice to see if pc changed
echo "again:"
m55_pc_2=$(read_m55_pc)
m55_lr_2=$(read_m55_lr)
m55_sp_2=$(read_m55_sp)
echo "pc:"
echo $m55_pc_2
echo "lr:"
echo $m55_lr_2
echo "sp:"
echo $m55_sp_2
#dump_sens_reg
if [ "$m55_pc_1" == "$m55_pc_2"  ] && [ "$m55_pc_1" != "" ] && [ "$m55_sp_2" != "" ];then
    dump_mem $m55_sp_2 16
    if [ -f $symbols_file ];then
        traced_psp_addr=$(get_symbol_addr "traced_psp" $symbols_file)
        if [ "$traced_psp_addr" != "" ];then
            traced_psp=$(read_addr_x $traced_psp_addr)
            echo  "\ntraced_psp:" $traced_psp
            dump_mem $traced_psp 16
       fi
       current_tcb_addr=$(get_symbol_addr "pxCurrentTCB" $symbols_file)
       if [ "$current_tcb_addr" != "" ];then
            read_current_task $current_tcb_addr
       fi
    fi
fi
deinit
}

path="/data/oppo/common/mcudump"
mkdir $path
chmod 0777 $path
rm -f $path/reset_mcu_*.txt
file="$path/reset_mcu_$(date +%Y%m%d_%H%M%S).txt"
echo "registers before reset mcu:" > $file
do_dump |tee -a $file
