#!/bin/bash
set -eu

ip route del default 2>/dev/null || true
ip route add default via "$GATEWAY_IP" || true

apk add shadow openssh sudo

chmod 666 /dev/stdout /dev/stderr
chown -R nginx:nginx /data && chmod -R 700 /data
exec su -s /bin/sh nginx -c "/usr/share/bunkerweb/all-in-one/entrypoint.sh \"$@\""
