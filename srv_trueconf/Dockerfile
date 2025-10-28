FROM trueconf/trueconf-server:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y \
    openssh-server \
    sudo \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
