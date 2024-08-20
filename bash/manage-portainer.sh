#!/bin/bash

# Function to install Portainer
install_portainer() {
  read -p "Portainer version - Community Edition (ce) | Enterprise Edition (ee): " portainer_version
  if [ "$portainer_version" != "ce" ] && [ "$portainer_version" != "ee" ]; then
    echo "Invalid Portainer version"
    exit 1
  fi
  docker volume create portainer_data
  docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-${portainer_version}:latest --http-enabled
  if [ $? -eq 0 ]; then
    echo "Portainer $portainer_version installed successfully"
  else
    echo "Failed to install Portainer $portainer_version"
    exit 1
  fi
}

# Function to install Portainer Agent
install_portainer_agent() {
  docker run -d -p 9001:9001 --name portainer_agent --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    portainer/agent:latest
  if [ $? -eq 0 ]; then
    echo "Portainer Agent installed successfully"
  else
    echo "Failed to install Portainer Agent"
    exit 1
  fi
}

# Function to update Portainer
update_portainer() {
  if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    docker stop portainer
    docker rm portainer
    docker pull portainer/portainer-ee
    install_portainer
  fi
  if docker ps -a --format '{{.Names}}' | grep -q '^portainer_agent$'; then
    docker stop portainer_agent
    docker rm portainer_agent
    docker pull portainer/agent
    install_portainer_agent
  fi
}

# Function to uninstall Portainer
uninstall_portainer() {
  if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    docker stop portainer
    docker rm portainer
    docker volume rm portainer_data
    echo "Portainer uninstalled"
  fi
  if docker ps -a --format '{{.Names}}' | grep -q '^portainer_agent$'; then
    docker stop portainer_agent
    docker rm portainer_agent
    echo "Portainer Agent uninstalled"
  fi
}

# Check if Portainer or Portainer Agent is already installed
if docker ps -a --format '{{.Names}}' | grep -Eq '^portainer$|^portainer_agent$'; then
  echo "Portainer or Portainer Agent is already installed."
  read -p "Do you want to update (u) or uninstall (x) Portainer? [u/x]: " action_choice
  if [ "$action_choice" == "u" ]; then
    update_portainer
  elif [ "$action_choice" == "x" ]; then
    uninstall_portainer
  else
    echo "Invalid choice"
  fi
else
  # Prompt for installation options
  until [[ $portainer = 'y'  || $portainer = 'a' || $portainer = 'n' ]]; do
    read -p "Portainer install - Yes (y) | Agent Only (a) | No (n): " portainer
  done

  if [ "$portainer" == "y" ]; then
    install_portainer
  elif [ "$portainer" == 'a' ]; then  
    install_portainer_agent
  else
    echo "Portainer installation skipped"
  fi
fi

echo "Docker setup complete"