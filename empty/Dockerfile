FROM alpine:3.20

RUN apk add --no-cache openssh iproute2 curl bash sudo tcpdump shadow

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
