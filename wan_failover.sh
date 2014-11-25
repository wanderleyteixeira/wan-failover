#!/bin/sh
#
# Automatic Connection Repair - WAN Failover
# Scheduled to run every hour
# 
# Failover DHCP WAN connection to USB 3G Internet stick (HUAWEI)
# Tested on latest Shibby build
# 
# Copyright (c) 2013 Wanderley B. Teixeira Filho
#
# THIS SOFTWARE IS OFFERED "AS IS", AND THE AUTHOR GRANTS NO WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, BY STATUTE,
# COMMUNICATION OR OTHERWISE. THE AUTHOR SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE.
#
##
logger Checking internet connection - `date +%m%d%Y%H%M%S`...

pingandswitch ()                                          
{                                                         
if [ "$(pingtest)" != "5" ]                        
then                                                      
        logger $wandns is DOWN. Switch to 3G connection...                   
	service vpnclient1 stop
	nvram set wan_proto="ppp3g"                  
        nvram set modem_apn="broadband.windmobile.ca"
        nvram commit                                
        sleep 1                                     
        service wan restart                         
        logger Completed.                           
fi                                                                             
}                                                                              
                                                                               
pingtest ()                                                                    
{                                                                              
PACKETS=5                                                                      
wandns=$(nvram get wan_get_dns | awk '{ print $1 }')                           
if [ "$wandns" == "" ]                                                         
then                                                                           
        pingtest=0                                                             
else                                                                           
        pingtest=$(ping -c $PACKETS -W 1 $wandns | awk '/received/ {print $4}')
fi              
echo $pingtest
}

iface_lst=`route | awk ' {print $8}'`
for tun_if in $iface_lst; do
	if [ $tun_if == "tun11" ] || [ $tun_if == "tun12" ]
	then
		exit 1
	fi
done

if [ "$(pingtest)" != "5" ] && [ "$(nvram get wan_proto)" != "ppp3g" ]
then
	/sbin/dhcpc-release
	logger Automatic WAN release
	sleep 1
	/sbin/dhcpc-renew
	sleep 10
	logger Automatic WAN renew
	pingandswitch
else	
	if [ "$(nvram get wan_proto)" == "ppp3g" ]
	then
		logger Switch to Cable connection...
		nvram set wan_proto="dhcp"
		nvram commit
		sleep 1
		service wan restart
		export pingandswitch
	fi
fi

cru a wan_failover "1 * * * * /tmp/wanfailover/wan_failover.sh"
