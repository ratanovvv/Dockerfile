FROM centos:7

ENV TERM=xterm

RUN yum -y install curl openssl-devel sudo
RUN curl -s https://packagecloud.io/install/repositories/basho/riak/script.rpm.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/basho/riak-cs/script.rpm.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/basho/stanchion/script.rpm.sh | bash 

RUN yum -y install riak-2.1.1-1.el7.centos.x86_64 riak-cs-2.1.0-1.el7.centos.x86_64 stanchion-2.1.0-1.el7.centos.x86_64

RUN ulimit -n 65536
RUN echo -e "\n# ulimit settings for Riak CS\nroot soft nofile 65536\nroot hard nofile 65536\nriak soft nofile 65536\nriak hard nofile 65536" >> /etc/security/limits.conf
RUN sed -i '/storage_backend =/d' /etc/riak/riak.conf
RUN sed -i '/buckets.default.allow_mult =/d' /etc/riak/riak.conf
RUN echo "buckets.default.allow_mult = true" >> /etc/riak/riak.conf
RUN sed -i 's/anonymous_user_creation = .*/anonymous_user_creation = on/g' /etc/riak-cs/riak-cs.conf

COPY advanced.config /etc/riak/

EXPOSE 8098 8080

COPY riakadmin.erl /

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/stanchion"]
VOLUME ["/var/lib/riak-cs"]
VOLUME ["/var/lib/riak"]
VOLUME ["/etc/riak"]
VOLUME ["/etc/riak-cs"]
VOLUME ["/etc/stanchion"]

ENTRYPOINT ["/entrypoint.sh"]
