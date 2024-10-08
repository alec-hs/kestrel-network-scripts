#!/bin/bash

# Tested on Debian 11.3, 12.5
# To be run as user with sudo permissions


if [ -x "$(command -v docker)" ]; then
  until [[ $install = 'y'  || $install = 'n' ]]; do
    read -p "Docker is already installed, do you want to reinstall? - Yes (y) | No (n): " install
  done
else
  install='y'
fi

if [ "$install" = 'y' ]; then
  echo "Installing Docker..."
  sudo apt update -y && sudo apt upgrade -y

  sudo apt remove docker docker-engine docker.io containerd runc -y
  sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common nfs-common -y

  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

  sudo apt update

  apt-cache policy docker-ce
  sudo apt install docker-ce docker-ce-cli containerd.io -y
  curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url  | grep docker-compose-linux-x86_64 | cut -d '"' -f 4 | wget -qi -
  chmod +x docker-compose-linux-x86_64
  sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

  sudo usermod -aG docker "${USER}"
  echo "Docker installed"
else 
  echo "Docker installation skipped"
fi


until [[ $portainer = 'y'  || $portainer = 'a' || $portainer = 'n' ]]; do
  read -p "Portainer install - Yes (y) | Agent Only (a) | No (n): " portainer
done

if [[ $portainer == "y" || $portainer == "a" ]]; then
  until [[ $portainer_version = 'ce' || $portainer_version = 'ee' ]]; do
    read -p "Portainer version - Community Edition (ce) | Enterprise Edition (ee): " portainer_version
  done
fi

if [ "$portainer" == "y" ]; then
  sudo docker volume create portainer_data
  sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-${portainer_version}:latest --http-enabled
elif [ "$portainer" == 'a' ]; then  
  sudo docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
else
  echo "Portainer installation skipped"
fi

echo "Docker setup complete"
