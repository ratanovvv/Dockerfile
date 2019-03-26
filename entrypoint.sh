#!/bin/bash
mkdir /dev/net | true
mknod /dev/net/tun c 10 200 | true
VPN_IP=$(ip addr show eth0 | sed -n "s|.*inet \(.*\)/\(.*\)|\1 |p")
if [ -n $NX_IP ] && [ -n $NX_PORT ]; then
  iptables -t nat -A PREROUTING -p tcp -i tun0 --dport $NX_PORT -j DNAT --to-destination $NX_IP:$NX_PORT
  iptables -A FORWARD -p tcp -d $NX_IP --dport $NX_PORT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -t nat -A POSTROUTING -o eth0 -p tcp --dport $NX_PORT -d $NX_IP -j SNAT --to-source $VPN_IP
fi
openvpn --config /etc/openvpn/server.conf
