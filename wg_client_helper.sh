#!/bin/bash

BASE="172.16.11"
WG_PATH=/etc/wireguard
WG_CONF="$WG_PATH"/wg0.conf

RAND_ADD=$((RANDOM % 254 + 1))

for i in $(seq $RAND_ADD 254); do
    if ! ping -c 2 -W 2 "$BASE.$i" > /dev/null 2>&1; then
        echo "FREE IP: $BASE.$i"
        IP="$BASE.$i"
        break
    fi
done

if [ -z "$IP" ]; then
    for i in $(seq 1 $((RAND_ADD-1))); do
        if ! ping -c 2 -W 2 "$BASE.$i" > /dev/null 2>&1; then
            echo "FREE IP: $BASE.$i"
            IP="$BASE.$i"
            break
        fi
    done
fi

SERVER_PUB_KEY=$(sudo cat /etc/wireguard/keys/pubkey)
CLIENT_PUB_KEY=$(cat /tmp/pubkey)
rm -f /tmp/pubkey

sudo tee -a "$WG_CONF" >/dev/null <<EOF

[Peer]
PublicKey = $CLIENT_PUB_KEY
AllowedIPs = $IP/32
EOF

sudo wg-quick down wg0
sudo wg-quick up wg0

tee /tmp/serv_pub_ip >/dev/null <<EOF
$SERVER_PUB_KEY
$IP
EOF