#! /bin/bash

set -u

usage() {
    echo "Usage: $0 [-u <username>]" 1>&2
    echo "  -u: Username on fd.vertel.se (defaults to \$USER)"
    exit 1
}

OPTIONS=$(getopt -o u: -- "$@") || usage
eval set -- "$OPTIONS"

USERNAME="$USER"  # Default to current user

while [ $# -gt 0 ]; do
    case "$1" in
        -u) USERNAME="$2"; shift 2 ;;
        --) shift; break ;;
        *) usage ;;
    esac
done

WG_PATH=/etc/wireguard
WG_CONF="$WG_PATH"/wg1.conf
KEYS_PATH="$WG_PATH"/keys

sudo apt install wireguard

sudo mkdir "$KEYS_PATH"
sudo chmod 700 "$KEYS_PATH"

echo creating private key...
PRIV_KEY=$(sudo wg genkey)
echo "$PRIV_KEY" | sudo tee "$KEYS_PATH"/private >/dev/null
sudo chmod 600 "$KEYS_PATH"/private

echo creating public key...
PUB_KEY=$(echo "$PRIV_KEY" | sudo wg pubkey)
echo "$PUB_KEY" | tee "/tmp/pubkey" >/dev/null
sudo cp "/tmp/pubkey" "$KEYS_PATH"/pubkey

scp /tmp/pubkey "$USERNAME"@gw1.vertel.se:/tmp/pubkey 

if ! ssh "$USERNAME@gw1.vertel.se" "command -v wg_client_helper >/dev/null 2>&1"; then
  ssh -t "$USERNAME@gw1.vertel.se" "wget -O ~/wg_client_helper https://github.com/vertelab/wireguard/raw/refs/heads/main/wg_client_helper.sh && chmod +x ~/wg_client_helper && sudo mv ~/wg_client_helper /usr/local/bin/"
fi

ssh -t "$USERNAME"@gw1.vertel.se "wg_client_helper"
SERVPUB_AND_IP=$(ssh "$USERNAME"@gw1.vertel.se "cat /tmp/serv_pub_ip")
ssh -t "$USERNAME"@gw1.vertel.se "sudo rm /tmp/serv_pub_ip"
readarray -t SERVPUB_AND_IP <<< "$SERVPUB_AND_IP"

WG1_PUB_KEY=${SERVPUB_AND_IP[0]}
IP=${SERVPUB_AND_IP[1]}

sudo tee "$WG_CONF" >/dev/null <<EOF
[Interface]
Address = $IP/24
PrivateKey = $PRIV_KEY

[Peer]
PublicKey = $WG1_PUB_KEY
Endpoint = 135.181.32.1:51820
AllowedIPs = 172.16.11.0/24, 192.168.12.0/24, 192.168.11.0/24
PersistentKeepalive = 25
EOF

is_desktop() {
    # Check desktop package
    dpkg -l ubuntu-desktop >/dev/null 2>&1 && return 0
    
    # Check GUI session
    [ "$XDG_SESSION_TYPE" = "x11" ] || [ "$XDG_SESSION_TYPE" = "wayland" ] && return 0
    
    # Check graphical target
    systemctl -q is-active graphical.target && return 0
    
    # Check display manager
    pgrep -x "gdm3" >/dev/null 2>&1 || pgrep -x "gdm" >/dev/null 2>&1 && return 0
    
    return 1
}

if is_desktop; then
    echo "DESKTOP detected: adding wg1 to GNOME NetworkManager"
    sudo nmcli connection import type wireguard file /etc/wireguard/wg1.conf
    sudo nmcli connection up wg1
else
    echo "SERVER deteted: adding wg1 as a service"
    sudo systemctl enable wg-quick@wg1
    sudo systemctl start wg-quick@wg1
fi


