FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server && \
    mkdir -p /run/sshd && \
    ssh-keygen -A && \
    printf "Port 22\nKexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1\nCiphers +aes128-cbc,3des-cbc\nMACs +hmac-sha1\n" >> /etc/ssh/sshd_config && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
