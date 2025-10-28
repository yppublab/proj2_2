FROM alpine:3.20

ENV TZ=Etc/UTC
RUN apk add --no-cache shadow nftables iproute2 iptables openssh openssh-server sudo bash tcpdump nano

COPY /entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
