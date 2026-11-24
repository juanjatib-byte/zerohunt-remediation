FROM alpine:3.18
RUN apk add --no-cache nginx apache2-utils && mkdir -p /run/nginx /var/www/html/admin
RUN echo "Welcome Admin" > /var/www/html/admin/index.html
RUN htpasswd -cbB /etc/nginx/.htpasswd admin admin
RUN printf "events {}\nhttp { server { listen 80; root /var/www/html; location /admin { auth_basic 'Admin'; auth_basic_user_file /etc/nginx/.htpasswd; } } }\n" > /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
