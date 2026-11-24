FROM alpine:3.18
RUN apk add --no-cache vsftpd && mkdir -p /var/ftp && \
    printf "listen=YES\nanonymous_enable=NO\nlocal_enable=YES\npasv_enable=YES\npasv_min_port=30000\npasv_max_port=30005\nseccomp_sandbox=NO\n" > /etc/vsftpd/vsftpd.conf
EXPOSE 21 30000-30005
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]
