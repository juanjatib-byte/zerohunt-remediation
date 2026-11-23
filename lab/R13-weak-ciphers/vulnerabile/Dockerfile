FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends nginx-light openssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/cert.key -out /etc/ssl/certs/cert.crt -subj "/CN=target" && \
    rm -f /etc/nginx/sites-enabled/default && \
    printf "server { listen 443 ssl; ssl_certificate /etc/ssl/certs/cert.crt; ssl_certificate_key /etc/ssl/private/cert.key; ssl_protocols TLSv1.2; ssl_ciphers ALL:@SECLEVEL=0; location / { return 200 'OK'; } }\n" > /etc/nginx/conf.d/ssl.conf && \
    rm -rf /var/lib/apt/lists/*
COPY openssl_legacy.cnf /etc/ssl/openssl_legacy.cnf
ENV OPENSSL_CONF=/etc/ssl/openssl_legacy.cnf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
