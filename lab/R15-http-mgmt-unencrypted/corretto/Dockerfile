FROM alpine:3.18
RUN apk add --no-cache nginx openssl && mkdir -p /run/nginx && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/cert.key -out /etc/ssl/certs/cert.crt -subj "/CN=target" && \
    printf "events {}\nhttp { server { listen 80; return 301 https://\$host\$request_uri; } server { listen 443 ssl; ssl_certificate /etc/ssl/certs/cert.crt; ssl_certificate_key /etc/ssl/private/cert.key; add_header Strict-Transport-Security 'max-age=31536000' always; location / { return 200 'Admin Panel Login (HTTPS)'; } } }\n" > /etc/nginx/nginx.conf
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
