#!/bin/bash

# Tested on Debian 10.8
# To be run as user with sudo permissions

sudo apt update -y && sudo apt upgrade -y

sudo apt remove docker docker-engine docker.io containerd runc
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

sudo apt-update

apt-cache policy docker-ce
sudo apt install docker-ce


sudo usermod -aG docker ${USER}
su - ${USER}