#!/bin/bash
# Run as root to setup seerver for budibase

# Get info for setup

until [[ ! -z $BB_ADMIN_USER_EMAIL  ]]; do
    read -p "Enter admin email address: " BB_ADMIN_USER_EMAIL
done

until [[ ! -z $DOMAIN  ]]; do
    read -p "Enter domain (without https://) for Budibase Site: " DOMAIN
done

until [[ ! -z $PG_DATABASE  ]]; do
    read -p "Enter a name for Default PG Database: " PG_DATABASE
done 

until [[ ! -z $STEAM_API_KEY  ]]; do
    read -p "Enter Steam API: " STEAM_API_KEY
done

# Setup account, groups and ssh keys
apt update -y && apt upgrade -y
apt install curl certbot apt-transport-https ca-certificates curl gnupg2 software-properties-common sudo -y
adduser --disabled-password --gecos "" budibase
usermod -aG sudo budibase
echo 'budibase ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/budibase
chmod 440 /etc/sudoers.d/budibase
mkdir -p /home/budibase/.ssh
chmod 700 /home/budibase/.ssh
touch /home/budibase/.ssh/authorized_keys
chmod 600 /home/budibase/.ssh/authorized_keys
chown -R budibase:budibase /home/budibase/.ssh
wget https://github.com/alec-hs.keys -O /home/budibase/.ssh/authorized_keys
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
cp /home/budibase/.ssh/authorized_keys /root/.ssh/authorized_keys 
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh/

# Setup Docker and Docker Compose
apt update -y && sudo apt upgrade -y

apt remove docker docker-engine docker.io containerd runc -y
apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common nfs-common -y

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

apt update

apt-cache policy docker-ce
apt install docker-ce docker-ce-cli containerd.io -y
curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url  | grep docker-compose-linux-x86_64 | cut -d '"' -f 4 | wget -qi -
chmod +x docker-compose-linux-x86_64
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

usermod -aG docker "budibase"

# Create app folder
sudo -u budibase -H bash -c "mkdir /home/budibase/budi-app"

# Download Budibase files
sudo -u budibase -H bash -c "wget https://raw.githubusercontent.com/Budibase/budibase/master/hosting/docker-compose.yaml -O /home/budibase/budi-app/docker-compose.yaml"
sudo -u budibase -H bash -c "wget https://raw.githubusercontent.com/Budibase/budibase/master/hosting/.env -O /home/budibase/budi-app/.env"

# Edit .env file with random values

BB_ADMIN_USER_PASSWORD=$(openssl rand -hex 12)
JWT_SECRET=$(openssl rand -hex 24)
MINIO_ACCESS_KEY=$(openssl rand -hex 24)
MINIO_SECRET_KEY=$(openssl rand -hex 24)
COUCH_DB_PASSWORD=$(openssl rand -hex 24)
REDIS_PASSWORD=$(openssl rand -hex 24)
INTERNAL_API_KEY=$(openssl rand -hex 24)

sed -i "s/BB_ADMIN_USER_EMAIL=/BB_ADMIN_USER_EMAIL=$BB_ADMIN_USER_EMAIL/g" /home/budibase/budi-app/.env
sed -i "s/BB_ADMIN_USER_PASSWORD=/BB_ADMIN_USER_PASSWORD=$BB_ADMIN_USER_PASSWORD/g" /home/budibase/budi-app/.env
sed -i "s/JWT_SECRET=testsecret/JWT_SECRET=$JWT_SECRET/g" /home/budibase/budi-app/.env
sed -i "s/MINIO_ACCESS_KEY=budibase/MINIO_ACCESS_KEY=$MINIO_ACCESS_KEY/g" /home/budibase/budi-app/.env
sed -i "s/MINIO_SECRET_KEY=budibase/MINIO_SECRET_KEY=$MINIO_SECRET_KEY/g" /home/budibase/budi-app/.env
sed -i "s/COUCH_DB_PASSWORD=budibase/COUCH_DB_PASSWORD=$COUCH_DB_PASSWORD/g" /home/budibase/budi-app/.env
sed -i "s/REDIS_PASSWORD=budibase/REDIS_PASSWORD=$REDIS_PASSWORD/g" /home/budibase/budi-app/.env
sed -i "s/INTERNAL_API_KEY=budibase/INTERNAL_API_KEY=$INTERNAL_API_KEY/g" /home/budibase/budi-app/.env

# Setup update script
sudo -u budibase -H bash -c "touch /home/budibase/budi-app/update-budibase.sh"
chmod +x /home/budibase/budi-app/update-budibase.sh
cat > /home/budibase/budi-app/update-budibase.sh << EOF
#!/bin/bash
mv /home/budibase/budi-app/docker-compose.yaml /home/budibase/budi-app/docker-compose.yaml.bak
wget https://raw.githubusercontent.com/Budibase/budibase/master/hosting/docker-compose.yaml -O /home/budibase/budi-app/docker-compose.yaml
docker-compose down
docker-compose up -d
EOF

# Start Budibase
cd /home/budibase/budi-app
docker-compose up -d
cd ~


# Setup Steam OIDC Provider
sudo -u budibase -H bash -c "mkdir /home/budibase/steam-oidc"
OPENID_SECRET=$(openssl rand -hex 24)
cat > /home/budibase/steam-oidc/docker-compose.yaml << EOF
version: '3.3'
services:
    steam-openid-connect-provider:
        image: imperialplugins/steam-openid-connect-provider
        ports:
            - 9780:80
        environment:
            - 'OpenID__RedirectUri=https://$DOMAIN/api/global/auth/oidc/callback'
            - OpenID__ClientID=steamidp
            - OpenID__ClientSecret=$OPENID_SECRET
            - Authentication__Steam__ApplicationKey=$STEAM_API_KEY
            - Hosting__PublicOrigin=https://$DOMAIN
        restart: unless-stopped
        container_name: steamidp
EOF

# Start Steam OIDC Provider
cd /home/budibase/steam-oidc
docker-compose up -d
cd ~

# Setup PostGres Database
sudo -u budibase -H bash -c "mkdir /home/budibase/postgres"
POSTGRES_PASSWORD=$(openssl rand -hex 12)
cat > /home/budibase/postgres/docker-compose.yaml << EOF
version: '3.3'
volumes:
    postgres-data:
        driver: local
services:
    postgres:
        image: postgres:latest
        ports:
            - 5432:5432
        environment:
            - POSTGRES_PASSWORD=$POSTGRES_PASSWORD
            - POSTGRES_USER=pgadmin
            - POSTGRES_DB=$PG_DATABASE
        volumes:
            - postgres-data:/var/lib/postgresql/data/
        restart: unless-stopped
        container_name: postgres
EOF

# Start PostGres Database
cd /home/budibase/postgres
docker-compose up -d
cd ~

# Install Caddy 
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy

# Setup Caddy config
systemctl stop caddy
rm /etc/caddy/Caddyfile
touch /etc/caddy/Caddyfile
cat > /etc/caddy/Caddyfile << EOF
tools.stormworks.cc {
  reverse_proxy http://localhost:10000
}

auth.stormworks.cc {
  reverse_proxy http://localhost:9780
}

https://tools.stormworks.cc/builder/assets/favicon.e7fc7733.png {
  redir https://tools.stormworks.cc/global/settings/logoUrl permanent
}
EOF
systemctl start caddy


# Echo out the password for the user
echo "Use this password for the Budibase admin user ($BB_ADMIN_USER_EMAIL): $BB_ADMIN_USER_PASSWORD"
echo "Use this password for the postgres user (pgadmin): $POSTGRES_PASSWORD"