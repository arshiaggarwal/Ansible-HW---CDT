FROM ubuntu:20.04

# Install build tools
RUN apt update && apt install -y \
    build-essential \
    libpam0g-dev \
    libssl-dev \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create FTP user
RUN useradd -m ftpuser && echo "ftpuser:weakpass123" | chpasswd

# FTP root
RUN mkdir -p /srv/ftp && chmod 755 /srv/ftp

# Copy the tar.gz instead of the full folder
COPY vsftpd-2.3.4.tar.gz /opt/

# Extract and build
RUN cd /opt && tar -xzf vsftpd-2.3.4.tar.gz
RUN cd /opt/vsftpd-2.3.4 && \
    sed -i 's/LDFLAGS =/LDFLAGS = -lpam/' Makefile && \
    sed -i 's/$(LDFLAGS)/$(LDFLAGS) -lpam/' Makefile && \
    make && \
    cp vsftpd /usr/sbin/vsftpd



# Debug: list files
RUN ls -l /usr/sbin | grep vsftpd


# Config
COPY vsftpd.conf /etc/vsftpd.conf

EXPOSE 21 6200

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]
