FROM alpine:3.18
RUN apk add --no-cache nginx && mkdir -p /run/nginx && \
    printf "events {}\nhttp { server { listen 443 ssl; ssl_certificate /etc/ssl/certs/server.crt; ssl_certificate_key /etc/ssl/private/server.key; location / { return 200 'OK'; } } }\n" > /etc/nginx/nginx.conf
COPY certs/server.crt /etc/ssl/certs/server.crt
COPY certs/server.key /etc/ssl/private/server.key
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
