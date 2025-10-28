FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

RUN apt-get update \
 && apt-get install -y \
    openssh-server \
    sudo \
    iproute2 \
    curl \
    systemctl \
    ca-certificates \
    cron \
    tcpdump \
    dnsutils \
 && rm -rf /var/lib/apt/lists/*

# Ensure ping is available (install separately to avoid any conflicts)
RUN apt-get update && apt-get install -y iputils-ping && rm -rf /var/lib/apt/lists/*


# Run entrypoint.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
