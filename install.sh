#!/usr/bin/env bash

set -e

add-apt-repository -y ppa:wireguard/wireguard
apt update
apt upgrade -y
apt install -y wireguard qrencode iputils-ping
