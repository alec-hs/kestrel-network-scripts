#!/bin/bash

# To be run as user with docker permissions

read -p "Install (i) or Update (u) Portainer [i/u]: " method

if [ "$method" == "i" ]; then
  docker volume create portainer_data
  docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest --http-enabled
elif [ "$method" == "u" ]; then
  docker stop portainer
  docker rm portainer
  docker pull portainer/portainer-ee
  docker volume create portainer_data
  docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest --http-enabled
else
  echo "Invalid method"
fi