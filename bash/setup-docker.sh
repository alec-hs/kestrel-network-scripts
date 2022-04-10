#!/bin/bash

# Tested on Debian 10.8
# To be run as user with sudo permissions

sudo apt update -y && sudo apt upgrade -y

sudo apt remove docker docker-engine docker.io containerd runc -y
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common nfs-common -y

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

sudo apt update

apt-cache policy docker-ce
sudo apt install docker-ce -y


sudo usermod -aG docker ${USER}