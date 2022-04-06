#!/bin/bash

# To be run as user with sudo permissions
# Will install adguard home with DNS on port 53 and admin portal on port 443 using LetsEncrypt for SSL
# Requires Cloudflare API Token with Zone:Zone:Read and Zone:DNS:Edit permissions

# Install Adguard Home
sudo apt install curl -y
sudo curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

# Install LetsEncrypt dependencies and setup folders/files
sudo apt update -y
sudo apt install certbot python3-certbot-dns-cloudflare -y
sudo mkdir /root/.secrets/ 
sudo touch /root/.secrets/cloudflare.ini 
sudo chmod 0700 /root/.secrets/
sudo chmod 0400 /root/.secrets/cloudflare.ini

# Get info from user needed for certbot
read -p "Enter Cloudflare API token: " api_key
read -p "Enter FQDN for web admin: " domain
read -p "Enter email for LetsEncrypt updates: " email
echo "dns_cloudflare_api_token = $api_key" | sudo tee -a /root/.secrets/cloudflare.ini

# Request cetrtificate
FQDN="$(hostname --fqdn)"
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d $domain -d $FQDN --preferred-challenges dns-01 -n --agree-tos --email $email

# Ask user to setup basic settings
read -rsp $'
Please go to http://'$FQDN':3000 and complete basic setup...
When done press any key to continue.
' -n1 key

# Setup Adguard Home config
certpath="/etc/letsencrypt/live/$domain/fullchain.pem"
keypath="/etc/letsencrypt/live/$domain/privkey.pem"
sudo sed -i 'N;s+tls:\n  enabled: false+tls:\n  enabled: true+g' /opt/AdGuardHome/AdGuardHome.yaml
sudo sed -i 's+certificate_path: ""+certificate_path: '$certpath'+g' /opt/AdGuardHome/AdGuardHome.yaml
sudo sed -i 's+private_key_path: ""+private_key_path: '$keypath'+g' /opt/AdGuardHome/AdGuardHome.yaml
sudo sed -i 's+server_name: ""+server_name: '$domain'+g' /opt/AdGuardHome/AdGuardHome.yaml
sudo sed -i 's+force_https: false+force_https: true+g' /opt/AdGuardHome/AdGuardHome.yaml
sudo systemctl restart AdGuardHome