#!/bin/bash
# This script will make all the iptable or firewall changes to setup a server as a router
# The instance is connected to two networks and the traffic will be routed from private to public network
# If going with iptables then the changes are not persistentA
# The firewalld changes are persistent. Firewalld should be up and running on the instance

# Start of user inputs
PRIVATEIFNAME="ens33"
PUBLICIFNAME="ens37"
USEIPTABLES="no"
#USEIPTABLES="yes"
USEFIREWALLD="yes"
#USEFIREWALLD="no"
# End of user inputs


if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
fi

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p


if [[ $USEIPTABLES == "yes" ]]
then
	# Clean up IPTABLES
	iptables -F
	iptables -X
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -P INPUT ACCEPT
	iptables -P FORWARD DROP
	iptables -P OUTPUT ACCEPT
	# Create new IPTABLES entries. This is not making the change persistent
	iptables -t nat -A POSTROUTING -o $PUBLICIFNAME -j MASQUERADE
	iptables -A FORWARD -i $PRIVATEIFNAME -o $PUBLICIFNAME -m state --state RELATED,ESTABLISHED,NEW -j ACCEPT
	iptables -A FORWARD -i $PUBLICIFNAME -o $PRIVATEIFNAME -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

if [[ $USEFIREWALLD == "yes" ]]
then
	systemctl mask iptables
	systemctl mask ip6tables
	systemctl mask ebtables

	firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -o $PUBLICIFNAME -j MASQUERADE
	firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i $PRIVATEIFNAME -o $PUBLICIFNAME -m state --state RELATED,ESTABLISHED,NEW -j ACCEPT
	firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i $PUBLICIFNAME -o $PRIVATEIFNAME -m state --state RELATED,ESTABLISHED -j ACCEPT
	firewall-cmd --reload
fi


