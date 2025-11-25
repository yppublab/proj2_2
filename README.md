### Запуск на стенде

```bash
docker compose up --build
```

### Запуск в разработке

> ребилдим каждый раз контейнеры

```bash
docker compose up --build --force-recreate
```

### Пароли от почтаря

```bash
./srv_mail/passwords.txt
```

- Хеши и учетки на почтаре созадуться сами при поднятии контейнера
- При логине через thunderbird ставим (или настраиваем nat для 25 143 на fw в соотв с примером)

```
  chain PREROUTING {
    type nat hook prerouting priority -100;
    iif "eth_nat" tcp dport 25 counter dnat to 192.168.50.20:80 # nat для smtp
  }

  chain POSTROUTING {
    type nat hook postrouting priority 100;
    ip daddr 192.168.50.20 tcp dport 25 counter snat to 192.168.50.254 # nat для smtp
    oifname "eth_nat" masquerade  # Generic egress to nat
  }

```

```
IMAP 192.168.50.20 143
SMTP 192.168.50.20 25

Auth method: Password
```

### Креды от samba (srv_fs)

Смотрим `.env`

```
SAMBA_USER=samba
SAMBA_PASSWORD=SambaPassword
SAMBA_SHARE_NAME=share
```

smb://192.168.50.30
