#!/usr/bin/env bash
set -euo pipefail

# Network route first (before apk fetches)
ip route del default 2>/dev/null || true
ip route add default via "$GATEWAY_IP" || true

# Prepare adm user and sshd configuration
chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh

# Launch SSH daemon for ansible access
/usr/sbin/sshd -D -e &

# Fix amavis permissions
chown root:root /etc/amavis/conf.d/50-user

# Генерируем файл /tmp/docker-mailserver/config/postfix-accounts.cf
source="/root/passwords.txt"
postfix_accounts="/tmp/docker-mailserver/postfix-accounts.cf"

echo "[srv_web] start to generate accounts"

if [ -f "$source" ]; then
	# Ожидается формат: user:password (plain)
	# Для каждого пользователя генерируем строку user:{SHA512-CRYPT}hash
	true >"$postfix_accounts"
	while IFS=: read -r user pass; do
		# Генерируем хэш пароля
		hash=$(doveadm pw -s SHA512-CRYPT -p "$pass")
		echo "$user|$hash" >>"$postfix_accounts"
	done <"$source"
	chown root:root "$postfix_accounts"
	chmod 600 "$postfix_accounts"
fi

echo "[srv_web] accounts generated"
rm -f "$source"

# Hand over to dumb-init supervising supervisord like upstream
exec /usr/bin/dumb-init -- supervisord -c /etc/supervisor/supervisord.conf
