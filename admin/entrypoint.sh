#!/usr/bin/env bash
set -eu

useradd -m -s /bin/bash -p "${ADMIN_HASH}" admin || true

# Adjust default route via firewall
ip route del default || true
ip route add default via "$GATEWAY_IP" || true

set -euo pipefail

# Ensure APT repositories use HTTPS (replace any http:// with https://)
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list

# Prepare XRDP session for admin
mkdir -p /home/admin
printf '%s\n%s\n' "setxkbmap -layout us,ru -option grp:alt_shift_toggle" "exec startplasma-x11" >/home/admin/.xsession
chown -R admin:admin /home/admin

# Ensure XDG base directories and default user-places file for Dolphin/Plasma
mkdir -p /home/admin/.local/share /home/admin/.config /home/admin/.cache
if [ ! -s /home/admin/.local/share/user-places.xbel ]; then
	cat >/home/admin/.local/share/user-places.xbel <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0">
  <folder folded="no"><title>Places</title></folder>
  <!-- Initialized by container startup -->
</xbel>
EOF
fi
chown -R admin:admin /home/admin/.local /home/admin/.config /home/admin/.cache

# Harden xrdp.ini: keep listener at 3389 in [Globals], ensure [Xorg] uses port=-1
awk 'BEGIN{in_g=0} \
  /^\[Globals\]/{in_g=1} \
  /^\[.*\]/{if($0!~"^\\[Globals\\]") in_g=0} \
  { \
    if(in_g && $0 ~ /^use_vsock=/){$0="use_vsock=false"} \
    if(in_g && $0 ~ /^#?address=/){$0="address=0.0.0.0"} \
    if(in_g && $0 ~ /^port=/){$0="port=3389"} \
    print \
  }' /etc/xrdp/xrdp.ini >/etc/xrdp/xrdp.ini.tmp && mv /etc/xrdp/xrdp.ini.tmp /etc/xrdp/xrdp.ini
sed -i '/^\[Xorg\]/,/^\[/{s/^lib=.*/lib=libxup.so/; s/^port=.*/port=-1/; s/^ip=.*/ip=127.0.0.1/}' /etc/xrdp/xrdp.ini || true

# Ensure Xorg can start for non-console users
printf 'allowed_users=anybody\n' >/etc/Xwrapper.config

# Start dbus (needed by desktop session)
service dbus start || true

# Clean up possible stale PID files from previous restarts
mkdir -p /run/xrdp || true
rm -f /run/xrdp/xrdp.pid /run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid || true

# Preconfigure Thunderbird for user 'petrovich' and add desktop launchers
MAIL_USER="admin"
MAIL_ADDR=${MAIL_ADDR:-admin@investpro.local}
MAIL_NAME=${MAIL_NAME:-Routov Alexey}
MAIL_IMAP_HOST=${MAIL_IMAP_HOST:-192.168.70.20}
MAIL_IMAP_PORT=${MAIL_IMAP_PORT:-143}
MAIL_SMTP_HOST=${MAIL_SMTP_HOST:-192.168.70.20}
MAIL_SMTP_PORT=${MAIL_SMTP_PORT:-25}

ST_HOME=/home/$MAIL_USER
TB_BASE="$ST_HOME/.thunderbird"
TB_PROF_DIR="$TB_BASE/Profiles/dkprofile.default-release"
DESK_DIR="$ST_HOME/Desktop"
mkdir -p "$TB_PROF_DIR" "$DESK_DIR" "$TB_BASE"

cat >"$TB_BASE/profiles.ini" <<EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default-release
IsRelative=1
Path=Profiles/dkprofile.default-release
Default=1
EOF

cat >"$TB_PROF_DIR/user.js" <<EOF
// Default account and local folders
user_pref("mail.account.account1.server", "server1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account2.server", "server2");
user_pref("mail.accountmanager.accounts", "account1,account2");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.accountmanager.localfoldersserver", "server2");

// Identity (From:)
user_pref("mail.identity.id1.fullName", "$MAIL_NAME");
user_pref("mail.identity.id1.useremail", "$MAIL_ADDR");
user_pref("mail.identity.id1.smtpServer", "smtp1");

// IMAP server (srv_mail)
user_pref("mail.server.server1.name", "$MAIL_ADDR");
user_pref("mail.server.server1.hostname", "$MAIL_IMAP_HOST");
user_pref("mail.server.server1.type", "imap");
user_pref("mail.server.server1.userName", "$MAIL_ADDR");
user_pref("mail.server.server1.port", $MAIL_IMAP_PORT);
user_pref("mail.server.server1.socketType", 0);           // 0=plain, 2=SSL/TLS, 3=STARTTLS
user_pref("mail.server.server1.authMethod", 3);           // 3=cleartext password
user_pref("mail.server.server1.login_at_startup", false);
user_pref("mail.server.server1.check_new_mail", false);
user_pref("mail.server.server1.download_on_biff", true);
user_pref("mail.server.server1.autosync_offline_stores", true);

// Local Folders
user_pref("mail.server.server2.name", "Local Folders");
user_pref("mail.server.server2.hostname", "Local Folders");
user_pref("mail.server.server2.type", "none");
user_pref("mail.server.server2.userName", "nobody");

// SMTP
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "$MAIL_SMTP_HOST");
user_pref("mail.smtpserver.smtp1.port", $MAIL_SMTP_PORT);
user_pref("mail.smtpserver.smtp1.try_ssl", 0);
user_pref("mail.smtpserver.smtp1.authMethod", 1);         // 1=none, 3=cleartext password
user_pref("mail.smtpserver.smtp1.username", "$MAIL_ADDR");

// UX: suppress first-run wizard and defaults
user_pref("mail.provider.enabled", true);
user_pref("mail.provider.suppress_dialog_on_startup", true);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mailnews.start_page.enabled", false);
EOF

cat >"$DESK_DIR/Thunderbird.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Thunderbird
Comment=Email client
Exec=thunderbird -P dkprofile.default-release -profile "/home/${MAIL_USER}/.thunderbird/Profiles/dkprofile.default-release"
Icon=thunderbird
Terminal=false
Categories=Network;Email;
EOF

cat >"$DESK_DIR/Google Chrome.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Google Chrome
Comment=Web browser
Exec=google-chrome --no-sandbox
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF

# Mark desktop launchers as trusted (executable) to avoid Plasma warning
chmod +x "$DESK_DIR/Thunderbird.desktop" "$DESK_DIR/Google Chrome.desktop" || true

chown -R $MAIL_USER:$MAIL_USER "$TB_BASE" "$DESK_DIR"

# Note: we do not auto-launch Thunderbird headlessly here to avoid blocking startup.
# The Desktop entry runs Thunderbird with the explicit profile path, so installs.ini isn't required.

# Restrict XRDP logins to group 'rdpusers' only and add admin to it
getent group rdpusers >/dev/null || groupadd rdpusers
usermod -aG rdpusers 'admin' || true
if ! grep -q 'pam_succeed_if.so.*ingroup rdpusers' /etc/pam.d/xrdp-sesman 2>/dev/null; then
	sed -i '1i auth required pam_succeed_if.so user ingroup rdpusers' /etc/pam.d/xrdp-sesman || true
fi

# Подождем пока заведется srv_samba, чтобы диски подключились
sleep 10
# Mount Samba share on srv_samba
if ! mount -t cifs //192.168.50.30/share /mnt/share \
	-o username="${SAMBA_USER}",password="${SAMBA_PASSWORD}",vers=3.0,iocharset=utf8,uid=$(id -u admin),gid=$(id -g admin); then
	echo 'WARNING: failed to mount //192.168.50.30/share, continuing without mapped drive' >&2
fi

# Dolphin link on Desktop
cat >/home/admin/Desktop/Dolphin.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Dolphin
Comment=KDE File Manager
Exec=dolphin
Icon=system-file-manager
Terminal=false
Categories=System;FileTools;FileManager;
EOF
chmod +x /home/admin/Desktop/Dolphin.desktop
chown admin:admin /home/admin/Desktop/Dolphin.desktop

# Разворачиваем sshd + adm пользователя
chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh
/usr/sbin/sshd

# Start XRDP services (sesman in background, xrdp in foreground)
/usr/sbin/xrdp-sesman -n &
exec /usr/sbin/xrdp -n

# Keep container alive
sleep infinity
