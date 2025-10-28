#!/usr/bin/env bash
set -eu

# Network route first (before apk fetches)
ip route del default 2>/dev/null || true
ip route add default via "${GATEWAY_IP}" || true

# Разворачиваем sshd + adm пользователя
chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh
/usr/sbin/sshd

# Keep container alive
sleep infinity
