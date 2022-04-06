#!/bin/bash

# To be run as user with docker permissions

docker stop portainer
docker rm portainer
docker pull portainer/portainer-ce
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce