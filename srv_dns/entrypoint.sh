#!/bin/sh
set -eu

ip route del default 2>/dev/null || true
ip route add default via "$GATEWAY_IP" || true

chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh
/usr/sbin/sshd

exec coredns -conf /etc/coredns/Corefile
