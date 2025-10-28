#!/bin/bash

chmod +x /usr/local/bin/ansible.sh
/usr/local/bin/ansible.sh
/usr/sbin/sshd

case "${USERNAME}" in
user1)
	useradd -m -s /bin/bash -p "${USER1_HASH}" user1 || true
	;;
user2)
	useradd -m -s /bin/bash -p "${USER2_HASH}" user2 || true
	;;
admin)
	useradd -m -s /bin/bash -p "${ADMIN_HASH}" admin || true
	;;
boss)
	useradd -m -s /bin/bash -p "${BOSS_HASH}" boss || true
	;;
esac

sleep infinity
