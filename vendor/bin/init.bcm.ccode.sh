#!/vendor/bin/sh
# Copyright (c) 2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
export PATH=/vendor/bin

region_mask=`getprop ro.vendor.oplus.regionmark`
region_ccode_list=("CN" "ID" "TW" "VN" "IN" "MY" "DE")
for region_ccode in ${region_ccode_list[@]}
do
	if [ "$region_mask" == "$region_ccode" ]
	then
        ccode="$region_mask"
        setprop persist.vendor.oplus.wlan.ccode $region_mask
        exit
    else
        echo "Unrecognized region ccode"
    fi
done

if [ "$region_mask" == "UN" ]; then
    ccode="US"
elif [ "$region_mask" == "US" ]; then
    ccode="CA"
elif [ "$region_mask" == "EUEX" ]; then
    ccode="FR"
elif [ "$region_mask" == "APC" ]; then
    ccode="SG"
else
    echo "Unrecognized regionmark"
    ccode="US"
fi
setprop persist.vendor.oplus.wlan.ccode $ccode
