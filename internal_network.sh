#!/bin/bash
# This script will create a static IP on a vmware RHEL/Centos instance attached to an internal network
# It seems DHCP doesnt work on instances attached to an internal network
# It looks like by default on machines with a NAT connection 192.168.126.0/24 network is used
# If this machine will talk to a machine with NAT, then pick a different network


# Start of user inputs
NEW_CONN="test"
IFNAME="ens33"
STATIC_IP="192.168.150.10/24"
GATEWAY="192.168.150.2"
DNS="192.168.150.2"
# End of user inputs



if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
fi

# Delete existing connection
OLD_CONN=`nmcli connection show | grep ethernet | cut -f1 -d" "`
if [ $? == "0" ]
then
	nmcli connection delete $OLD_CONN
fi


nmcli connection add con-name $NEW_CONN type ethernet ifname $IFNAME ipv4.addresses $STATIC_IP ipv4.gateway $GATEWAY ipv4.dns $DNS ipv4.method manual autoconnect true
nmcli connection up $NEW_CONN
