FROM alpine:3.18
RUN apk add --no-cache unfs3 rpcbind && mkdir -p /srv/nfs && echo "dati_nfs" > /srv/nfs/file.txt && \
    printf "/srv/nfs 10.250.250.0/24(ro,root_squash)\n" > /etc/exports
EXPOSE 111 2049
CMD ["sh", "-c", "rpcbind && unfsd -d -e /etc/exports"]
