FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server && \
    mkdir -p /run/sshd && \
    ssh-keygen -A && \
    printf "Port 22\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com\n" >> /etc/ssh/sshd_config && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
