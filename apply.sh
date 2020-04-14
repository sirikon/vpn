#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

INTERFACE_NAME="wg0"
CONFIG_FOLDER="/etc/wireguard"
CONFIG_PATH="${CONFIG_FOLDER}/${INTERFACE_NAME}.conf"
CLIENT_CONFIG_PATH="${CONFIG_FOLDER}/${INTERFACE_NAME}-client.conf"

SERVER_PRIV_KEY_FILE_NAME="server.key.priv"
SERVER_PUB_KEY_FILE_NAME="server.key.pub"
SERVER_PRIV_KEY_PATH="${CONFIG_FOLDER}/${SERVER_PRIV_KEY_FILE_NAME}"
SERVER_PUB_KEY_PATH="${CONFIG_FOLDER}/${SERVER_PUB_KEY_FILE_NAME}"

CLIENT_PRIV_KEY_FILE_NAME="client.key.priv"
CLIENT_PUB_KEY_FILE_NAME="client.key.pub"
CLIENT_PRIV_KEY_PATH="${CONFIG_FOLDER}/${CLIENT_PRIV_KEY_FILE_NAME}"
CLIENT_PUB_KEY_PATH="${CONFIG_FOLDER}/${CLIENT_PUB_KEY_FILE_NAME}"

umask 0066

if [ ! -f "$SERVER_PRIV_KEY_PATH" ]; then
    echo "Generating server key pair"
    wg genkey > "$SERVER_PRIV_KEY_PATH"
    cat "$SERVER_PRIV_KEY_PATH" | wg pubkey > "$SERVER_PUB_KEY_PATH"
fi

if [ ! -f "$CLIENT_PRIV_KEY_PATH" ]; then
    echo "Generating client key pair"
    wg genkey > "$CLIENT_PRIV_KEY_PATH"
    cat "$CLIENT_PRIV_KEY_PATH" | wg pubkey > "$CLIENT_PUB_KEY_PATH"
fi

(
    export PRIVATE_KEY=$(cat "$SERVER_PRIV_KEY_PATH")
    export INTERFACE_NAME=$INTERFACE_NAME
    envsubst < ./assets/server.template.conf > $CONFIG_PATH
)

(
    export PUBLIC_KEY=$(cat "$CLIENT_PUB_KEY_PATH")
    export ALLOWED_IPS="10.0.1.1/32"
    envsubst < ./assets/server.peer.template.conf >> $CONFIG_PATH
)

(
    export ADDRESS="10.0.1.1/16"
    export PRIVATE_KEY=$(cat "$CLIENT_PRIV_KEY_PATH")
    export PEER_ALLOWED_IPS="10.0.0.0/16"
    export PEER_ENDPOINT="$(curl -s checkip.amazonaws.com):51820"
    export PEER_PUBLIC_KEY=$(cat "$SERVER_PUB_KEY_PATH")
    envsubst < ./assets/client.template.conf > $CLIENT_CONFIG_PATH
)

qrencode -t ansiutf8 < $CLIENT_CONFIG_PATH
