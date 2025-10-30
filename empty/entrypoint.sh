#!/bin/bash

chmod +x /usr/local/bin/adm.sh
/usr/local/bin/adm.sh
/usr/sbin/sshd

case "${USERNAME}" in
m.lebedeva)
	useradd -m -s /bin/bash -p "${USER1_HASH}" m.lebedeva || true
	;;
i.soloviev)
	useradd -m -s /bin/bash -p "${USER2_HASH}" i.soloviev || true
	;;
admin)
	useradd -m -s /bin/bash -p "${ADMIN_HASH}" admin || true
	;;
boss)
	useradd -m -s /bin/bash -p "${BOSS_HASH}" boss || true
	;;
esac

sleep infinity
