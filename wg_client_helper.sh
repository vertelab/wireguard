#!/bin/bash

BASE="172.16.11"

for i in {1..254}; do
    if ! ping -c 2 -W 2 "$BASE.$i" > /dev/null 2>&1; then
        echo "First free IP: $BASE.$i"
        IP="$BASE.$i"
        break
    fi
done

SERVER_PUB_KEY=$(sudo cat /etc/wireguard/keys/pubkey)
CLIENT_PUB_KEY=$(cat /tmp/pubkey)

sudo tee -a "$WG_CONF" >/dev/null <<'EOF'

[Peer]
PublicKey = $CLIENT_PUB_KEY
AllowedIPs = $IP/32
EOF

sudo wg-quick down wg0
sudo wg-quick up wg0

tee /tmp/serv_pub_ip >/dev/null <<'EOF'
$SERVER_PUB_KEY
$IP
EOF