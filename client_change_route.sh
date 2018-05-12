#!/bin/bash
# If you have an instance on an internal network and want to route all default traffic via another machine then need to change the routibng table on this instance
# Also if this second machine has a NAT connection then need to add the correct DNS server to /etc/resolv on this machine

# Start of user inputs
IFNAME="ens33"
CURRENTGATEWAYIP="192.168.150.2"
NEWGATEWAYIP="192.168.150.10"
NEWDNS="192.168.126.2"
# End of user inputs


if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
fi

# Create file called by systemd service
rm -rf /usr/local/src/routes.sh
cat << EOF > /usr/local/src/routes.sh
#!/bin/bash
# Adding the route for via the new router and deleting the old one
ip route add default via $NEWGATEWAYIP dev $IFNAME
ip route del default via $CURRENTGATEWAYIP dev $IFNAME
sed -i "s/.*nameserver.*/nameserver $NEWDNS" /etc/resolv.conf
EOF
chmod a+x /usr/local/src/routes.sh
# End of file with the new route

# Create a new systemd service
rm -rf /etc/systemd/system/new_routes.service
cat << EOF > /etc/systemd/system/new_routes.service
[Unit]
Description=Configure new routes
After=network-online.target network.service

[Service]
ExecStart=/usr/local/src/routes.sh

[Install]
WantedBy=network-online.target network.service
EOF
# End of new systemd service

echo "New systemd service - new routes created"

systemctl daemon-reload
systemctl enable new_routes.service
systemctl restart network
echo "Network restarted successfully"

