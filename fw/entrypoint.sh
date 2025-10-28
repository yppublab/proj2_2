#!/usr/bin/env bash
set -euo pipefail

# Enable IPv4 forwarding (privileged container)
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# Prepare PATH
echo 'export PATH=/usr/sbin:/sbin:$PATH' >/etc/profile.d/00-sbin.sh

echo "[fw] renaming interfaces by subnet..."
# Collect non-loopback IPv4 interfaces
while read -r line; do
	dev=$(echo "$line" | awk '{print $2}')
	cidr=$(echo "$line" | awk '{print $4}')
	[ "$dev" = "lo" ] && continue
	ip=${cidr%/*}
	# Derive /24 subnet x.y.z.0/24
	subnet=$(echo "$ip" | awk -F. '{printf "%s.%s.%s.0/24\n", $1,$2,$3}')
	new=""
	case "$subnet" in
	192.168.90.0/24) new="eth_nat" ;;
	192.168.70.0/24) new="eth_dmz" ;;
	192.168.10.0/24) new="eth_mng" ;;
	192.168.50.0/24) new="eth_servers" ;;
	192.168.0.0/24) new="eth_users" ;;
	esac
	[ -z "$new" ] && continue
	[ "$dev" = "$new" ] && continue
	# Skip if target name is already taken
	if ip link show "$new" >/dev/null 2>&1; then
		echo "[fw] Target name '$new' already exists, skipping $dev"
		continue
	fi
	echo "[fw] renaming $dev ($cidr) -> $new"
	ip link set dev "$dev" down || true
	ip link set dev "$dev" name "$new" || true
	ip link set dev "$new" up || true
done < <(ip -o -4 addr show)

# Задаем дефолтный маршрут на NAT
ip route add default via 192.168.90.254 dev eth_nat || true
echo "[fw] set default route via 192.168.90.254 / eth_nat"

# Load nftables rules
nft -f /etc/nftables.conf

# Разворачиваем sshd + adm пользователя
chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh

# Keep running
exec /usr/sbin/sshd -D
