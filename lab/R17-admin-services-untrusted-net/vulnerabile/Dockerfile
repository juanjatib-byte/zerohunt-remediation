FROM alpine:3.18
RUN apk add --no-cache nginx && mkdir -p /run/nginx && \
    printf "events {}\nhttp { server { listen 0.0.0.0:8080; location / { return 200 'Admin Console Exposed'; } } }\n" > /etc/nginx/nginx.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
