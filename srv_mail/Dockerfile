FROM ghcr.io/docker-mailserver/docker-mailserver:latest

ENV DEBIAN_FRONTEND=noninteractive

COPY ./amavis/50-user /etc/amavis/conf.d/50-user
COPY ./amavis/05-node_id /etc/amavis/conf.d/05-node_id
COPY ./passwords.txt /root/passwords.txt

RUN chown root:root /etc/amavis/conf.d/50-user /etc/amavis/conf.d/05-node_id \
 && chmod 0644 /etc/amavis/conf.d/50-user /etc/amavis/conf.d/05-node_id

RUN apt-get update \
 && apt-get install -y \
    openssh-server \
    sudo \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
