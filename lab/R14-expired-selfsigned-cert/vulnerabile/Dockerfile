FROM alpine:3.18
RUN apk add --no-cache nginx openssl && mkdir -p /run/nginx && \
    openssl req -x509 -nodes -days 1 -newkey rsa:2048 -keyout /etc/ssl/private/cert.key -out /etc/ssl/certs/cert.crt -subj "/CN=target" && \
    printf "events {}\nhttp { server { listen 443 ssl; ssl_certificate /etc/ssl/certs/cert.crt; ssl_certificate_key /etc/ssl/private/cert.key; location / { return 200 'OK'; } } }\n" > /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
