FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends bind9 dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/cache/bind /run/named && \
    chown -R bind:bind /var/cache/bind /run/named && \
    printf '$TTL 60\n@ IN SOA ns1.zerohunt.local. admin.zerohunt.local. (1 60 60 60 60)\n@ IN NS ns1.zerohunt.local.\nns1 IN A 127.0.0.1\ndc01 IN A 10.10.10.10\ndb-interna IN A 10.10.10.20\n' > /etc/bind/db.zerohunt.local
