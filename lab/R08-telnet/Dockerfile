FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends inetutils-inetd inetutils-telnetd openssh-server netcat-openbsd && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/sshd
