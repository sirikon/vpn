#!/usr/bin/env bash

set -e

add-apt-repository ppa:wireguard/wireguard
apt update
apt upgrade -y
apt install wireguard -y
