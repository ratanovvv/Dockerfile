FROM jenkins/jnlp-slave

COPY docker /usr/local/bin/docker
COPY docker-compose /usr/local/bin/docker-compose
USER root

RUN mkdir -p /home/jenkins/workspace
