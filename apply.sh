#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

INTERFACE_NAME="wg0"
PORT="51820"

SERVER_PUBLIC_IP="$(curl -s checkip.amazonaws.com)"
BASE_IP="10.0.0.0"
SERVER_IP="10.0.0.1"
CLIENT_IP="10.0.1.1"

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

if [ -f "$CONFIG_PATH" ]; then
    wg-quick down ${INTERFACE_NAME}
fi

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
    # Server config
    export ADDRESS="${SERVER_IP}/16"
    export LISTEN_PORT="${PORT}"
    export PRIVATE_KEY=$(cat "$SERVER_PRIV_KEY_PATH")
    export INTERFACE_NAME=$INTERFACE_NAME
    envsubst < ./assets/server.template.conf > $CONFIG_PATH
)

(
    # Server peer config
    export PUBLIC_KEY=$(cat "$CLIENT_PUB_KEY_PATH")
    export ALLOWED_IPS="${CLIENT_IP}/32"
    envsubst < ./assets/server.peer.template.conf >> $CONFIG_PATH
)

(
    # Client config
    export ADDRESS="${CLIENT_IP}/16"
    export PRIVATE_KEY=$(cat "$CLIENT_PRIV_KEY_PATH")
    export PEER_ALLOWED_IPS="${BASE_IP}/16"
    export PEER_ENDPOINT="${SERVER_PUBLIC_IP}:${PORT}"
    export PEER_PUBLIC_KEY=$(cat "$SERVER_PUB_KEY_PATH")
    envsubst < ./assets/client.template.conf > $CLIENT_CONFIG_PATH
)

wg-quick up ${INTERFACE_NAME}

qrencode -t ansiutf8 < $CLIENT_CONFIG_PATH
