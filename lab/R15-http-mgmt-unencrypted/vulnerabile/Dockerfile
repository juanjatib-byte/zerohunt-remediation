FROM alpine:3.18
RUN apk add --no-cache nginx && mkdir -p /run/nginx && \
    printf "events {}\nhttp { server { listen 80; location / { return 200 'Admin Panel Login (HTTP Cleartext)'; } } }\n" > /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
