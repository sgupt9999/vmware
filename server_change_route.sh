#!/bin/bash
# With multiple network cards, the routing needs to be corrected
# This is for an instance on 2 networks - one private and the other one public
# All the public traffic needs to go through the gateway on the public network
# By default 2 routes are created for default traffic through both networks
# Need to delete the default traffic via the private network


# Start of user inputs
PRIVATEIFNAME="ens33"
PRIVATEGATEWAYIP="192.168.150.2"
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
# Deleting the default route on the private network
ip route del default via $PRIVATEGATEWAYIP dev $PRIVATEIFNAME
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

