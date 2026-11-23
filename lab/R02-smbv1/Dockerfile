FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends samba smbclient && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /srv/samba/public /run/samba && \
    chmod 755 /srv/samba/public
