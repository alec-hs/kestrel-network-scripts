#!/bin/bash

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy


rm -f Caddyfile
SERVER=$(hostname)
FILE="https://api.github.com/repos/alec-hs/caddy-configs/contents/$SERVER?ref=main"
curl -H 'Authorization: token $TOKEN' -H 'Accept: application/vnd.github.v4.raw' -o /etc/caddy/Caddyfile -L $FILE
service caddy restart