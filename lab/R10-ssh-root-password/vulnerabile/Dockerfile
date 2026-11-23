FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server && \
    mkdir -p /run/sshd && \
    ssh-keygen -A && \
    echo "root:Password123!" | chpasswd && \
    printf "Port 22\nPermitRootLogin yes\nPasswordAuthentication yes\n" >> /etc/ssh/sshd_config && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
