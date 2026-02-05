FROM ubuntu:20.04

RUN apt update && apt install -y \
    build-essential \
    libpam0g-dev \
    libpam0g \
    libssl-dev \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Build vsftpd
COPY vsftpd-2.3.4.tar.gz /opt/
RUN cd /opt && tar -xzf vsftpd-2.3.4.tar.gz && \
    cd vsftpd-2.3.4 && \
    sed -i 's/LDFLAGS =/LDFLAGS = -lpam/' Makefile && \
    sed -i 's/$(LDFLAGS)/$(LDFLAGS) -lpam/' Makefile && \
    make && \
    cp vsftpd /usr/sbin/vsftpd

# Runtime dirs
RUN mkdir -p /var/run/vsftpd/empty && \
    chown root:root /var/run/vsftpd/empty && \
    chmod 755 /var/run/vsftpd/empty

# PAM file (CRITICAL)
RUN echo "auth required pam_permit.so" > /etc/pam.d/vsftpd && \
    echo "account required pam_permit.so" >> /etc/pam.d/vsftpd

# Anonymous FTP root (must exist)
RUN mkdir -p /srv/ftp && \
    chmod 755 /srv/ftp && \
    useradd -d /srv/ftp -s /usr/sbin/nologin ftp && \
    chown root:root /srv/ftp

COPY vsftpd.conf /etc/vsftpd.conf

EXPOSE 21 6200
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]