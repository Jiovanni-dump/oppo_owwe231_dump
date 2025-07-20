#!/vendor/bin/sh
gpioset  0 100=1
sleep 1
gpioset  0 100=0
gpioget 0 100
