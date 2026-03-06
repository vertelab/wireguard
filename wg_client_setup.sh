#! /bin/bash

sudo apt install wireguard

sudo mkdir /etc/wireguard/keys
sudo chmod 700 /etc/wireguard/keys

echo creating private key...
PRIV_KEY=$(sudo wg genkey)
echo "$PRIV_KEY" | sudo tee /etc/wireguard/keys/private >/dev/null
sudo chown 600 /etc/wireguard/keys/private

echo creating public key...
PUB_KEY=$(echo "$PRIV_KEY" | sudo wg pubkey)
echo "$PUB_KEY" | sudo tee /etc/wireguard/keys/pubkey >/dev/null

sudo tee /etc/wireguard/wg0.conf >/dev/null <<'EOF'
[Interface]
Address = 172.16.11.3/24
PrivateKey = <private>

[Peer]
PublicKey = <public>
Endpoint = 135.181.32.1:51820
AllowedIPs = 172.16.11.0/29, 192.168.11.0/24
PersistentKeepalive = 25
EOF