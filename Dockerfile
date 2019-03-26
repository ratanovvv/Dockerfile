FROM debian:8.5

ENV TERM=xterm
ENV FQDN=openvpn.platform
ENV SUBJ="/C=RU/ST=Moscow/L=Moscow/O=AllYourBaseAreBelongToUs"

RUN apt-get update && apt-get install -y wget openssl openssl-blacklist iptables && \
    wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add - && \
    echo "deb http://swupdate.openvpn.net/apt jessie main" > /etc/apt/sources.list.d/swupdate.openvpn.net.list && \
    apt-get update && apt-get install -y openvpn && \
    apt-key del E158C569 && mkdir -p /etc/openssl/openvpn/ca/

COPY openssl-ca.cnf /etc/openssl/openvpn/ca/
COPY openssl-ca-sign.cnf /etc/openssl/openvpn/ca/
COPY openssl-server.cnf /etc/openssl/openvpn/ca/
COPY openssl-client.cnf /etc/openssl/openvpn/ca/

RUN cd /etc/openssl/openvpn/ca && \
    touch index.txt && echo '01' > serial.txt && \
    openssl req -x509 -config openssl-ca.cnf -newkey rsa:4096 -sha256 -nodes -days 36500 -subj $SUBJ -out platform.pem -outform PEM && \
    openssl req -out $FQDN.csr -new -newkey rsa:2048 -nodes -keyout $FQDN.key -config openssl-server.cnf -subj "$SUBJ/CN=$FQDN" && \
    openssl ca -batch -config openssl-ca-sign.cnf -policy signing_policy -extensions signing_req -out $FQDN.pem -infiles $FQDN.csr && \
    openssl dhparam -out dh2048.pem 2048 && \
    cp $FQDN.pem $FQDN.key platform.pem /etc/openvpn/ && \
    chmod 600 /etc/openvpn/$FQDN.key && \
    cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/ && \
    gzip -d /etc/openvpn/server.conf.gz && ln -snfv /etc/openssl/openvpn/ca /etc/openvpn/ssl && \
    mkdir /dev/net && mknod /dev/net/tun c 10 200 && \
    sed -i 's|^ca .*|ca /etc/openvpn/ssl/platform.pem|' /etc/openvpn/server.conf && \
    sed -i "s|^cert .*|cert /etc/openvpn/ssl/$FQDN.pem|" /etc/openvpn/server.conf && \
    sed -i "s|^key .*|key /etc/openvpn/ssl/$FQDN.key|" /etc/openvpn/server.conf && \
    sed -i 's|^dh .*|dh /etc/openvpn/ssl/dh2048.pem|' /etc/openvpn/server.conf
    
EXPOSE 1194/udp

VOLUME ["/etc/openvpn/"]
VOLUME ["/etc/openssl/openvpn/ca/"]

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
