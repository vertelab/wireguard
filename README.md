# Wireguard

## Install

```
curl -fsSL https://raw.githubusercontent.com/vertelab/wireguard/refs/heads/main/wg_client_setup.sh | bash
```

### If you installed the script on a desktop client before it had code for persistence.
### Run the code below.
```
sudo nmcli connection import type wireguard file /etc/wireguard/wg1.conf
sudo nmcli connection up wg1
```
**PS check the name of the config file in /etc/wireguard to see if its wg1 or wg0.**

You will now be able to toggle the VPN on/off in the network settings.


### Same as above but for servers.
```
sudo systemctl enable wg-quick@wg1
sudo systemctl start wg-quick@wg1
```
