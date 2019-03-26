#!/bin/bash
#set -x
pid=0
RIAK_HOST=$(hostname)
IP=$(awk 'END {print $1}' /etc/hosts)
_riakcsnode="riak-cs@$IP"
export TERM=xterm

sed -i "s/listener.http.internal =.*/listener.http.internal = ${IP_ADDR}:8098/g" /etc/riak/riak.conf
sed -i "s/listener.protobuf.internal =.*/listener.protobuf.internal = ${IP_ADDR}:8087/g" /etc/riak/riak.conf
sed -i "s/nodename = .*/nodename = riak@${IP_ADDR}/g" /etc/riak/riak.conf
sed -i "s/listener = .*/listener = ${IP_ADDR}:8080/g" /etc/riak-cs/riak-cs.conf
sed -i "s/riak_host = .*/riak_host = ${IP_ADDR}:8087/g" /etc/riak-cs/riak-cs.conf
sed -i "s/root_host = .*/root_host = ${RIAK_HOST}/g" /etc/riak-cs/riak-cs.conf
sed -i "s/stanchion_host = .*/stanchion_host = ${IP_STANCHION}:8085/g" /etc/riak-cs/riak-cs.conf
sed -i "s/nodename = .*/nodename = riak-cs@${IP_ADDR}/g" /etc/riak-cs/riak-cs.conf
sed -i "s/listener = .*/listener = ${IP_ADDR}:8085/g" /etc/stanchion/stanchion.conf
sed -i "s/riak_host = .*/riak_host = ${IP_ADDR}:8087/g" /etc/stanchion/stanchion.conf
sed -i "s/nodename = .*/nodename = stanchion@${IP_ADDR}/g" /etc/stanchion/stanchion.conf
sed -i 's/anonymous_user_creation = .*/anonymous_user_creation = off/g' /etc/riak-cs/riak-cs.conf

export WAIT_FOR_ERLANG=300

/sbin/riak start

if [ -z "$ADMINKEY" ] && [ -z "$ADMINSECRET" ]; then 
  /sbin/stanchion start
else
  sed -i "s/admin.key = .*/admin.key = $ADMINKEY/g" /etc/riak-cs/riak-cs.conf
  sed -i "s/admin.secret = .*/admin.secret = $ADMINSECRET/g" /etc/riak-cs/riak-cs.conf
  sed -i "s/admin.key = .*/admin.key = $ADMINKEY/g" /etc/stanchion/stanchion.conf
  sed -i "s/admin.secret = .*/admin.secret = $ADMINSECRET/g" /etc/stanchion/stanchion.conf
fi

if [ "$IP_STANCHION" == "$IP" ]; then /sbin/stanchion start || true; fi

/sbin/riak-cs start
until /sbin/riak-cs ping; do sleep 10; done

if [ -f riakadmin.erl ] && [ -n "$ADMINKEY" ] && [ -n "$ADMINSECRET" ]; then
  #needs refactoring
  echo "Waiting 60 seconds...RiakCS is starting..." && sleep 60 && \
  /bin/bash -c "/usr/lib64/riak-cs/erts-5.10.3/bin/erlc riakadmin.erl && \
  /usr/lib64/riak-cs/erts-5.10.3/bin/erl -noshell \
  -name n@172.30.0.22 -setcookie riak \
  -s riakadmin main $_riakcsnode \"$ADMINKEY\" \"$ADMINSECRET\" -s init stop" && \
  echo -e "\nadmin.key = $ADMINKEY\nadmin.secret = $ADMINSECRET" &&
  rm -f riakadmin.erl
fi

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    echo "stopping..." >> /var/log/riak/console.log
    /sbin/riak-cs stop && /sbin/stanchion stop &&  /sbin/riak stop
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

pid=$(/sbin/riak-cs getpid)

trap 'kill ${!};term_handler' SIGTERM

while true; do
  tail -f /var/log/riak/console.log & wait ${!}
done
