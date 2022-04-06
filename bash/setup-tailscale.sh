#!/bin/bash

# Run as user with sudo privileges

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Emnable IP Forwarding for exit node functionality
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo /usr/sbin/sysctl -p /etc/sysctl.conf

read -p "Enter comma separted list of routes to advertise\n: " api_key

# Start with subnet routes & exit node
sudo tailscale up --accept-routes --advertise-routes=10.30.0.0/16


# Change MTU for site to site to work
# Check the names of the interfaces before running
#sudo iptables -t mangle -A FORWARD -i tailscale0 -o ens192 -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu