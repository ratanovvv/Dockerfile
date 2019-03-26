FROM debian:8.5

ENV TERM=xterm

RUN apt-get update && apt-get install -y dnsmasq
RUN sed -i 's|^#conf-dir=/etc/dnsmasq.d$|conf-dir=/etc/dnsmasq.d|' /etc/dnsmasq.conf

EXPOSE 53

VOLUME ["/etc/dnsmasq.d"]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
