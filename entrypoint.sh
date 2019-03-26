#!/bin/bash
if [ -n "$S3_HOST" ] && [ -n "$S3_IP" ]; then
  echo -e "interface=eth0\nbind-dynamic\naddress=/.$S3_HOST/$S3_IP" > /etc/dnsmasq.d/s3
else
  rm /etc/dnsmasq.d/s3
fi
/usr/sbin/dnsmasq -d
