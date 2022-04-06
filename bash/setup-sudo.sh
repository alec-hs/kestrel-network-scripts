#!/bin/bash

# To be run as root

apt update -y
apt upgrade -y
apt install sudo
/sbin/adduser alec-hs sudo