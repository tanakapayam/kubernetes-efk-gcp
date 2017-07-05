FROM docker.elastic.co/elasticsearch/elasticsearch:5.4.2
USER root
RUN yum install sudo -y
MAINTAINER Alex Curtin <acurtin@westfield.com>

# install the fabric8 kubernetes networking pluging to enable multicast discovery
RUN bin/elasticsearch-plugin install io.fabric8:elasticsearch-cloud-kubernetes:5.4.2

ENV NODE_DATA=true \
    NODE_MASTER=true \
    ES_JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Xms1g -Xmx1g" \
    HTTP_PORT=9200 \
    TRANSPORT_PORT=9300

# pre-stop-hook.sh and dependencies
# RUN apt-get update && apt-get install -y \
#     jq \
#     curl \
#  && rm -rf /var/lib/apt/lists/*
COPY pre-stop-hook.sh /pre-stop-hook.sh

# Copy our config files over
COPY config ./config
# Copy our config files over
ONBUILD COPY config ./config
# USER root
RUN mkdir -p /data
RUN chown elasticsearch:elasticsearch config/elasticsearch.yml
RUN chown -R elasticsearch:elasticsearch /data


EXPOSE 9200 9300
VOLUME ["/data"]

COPY ./run.sh /run.sh
RUN chmod +x /run.sh


RUN chown elasticsearch:elasticsearch /run.sh

CMD ["/run.sh"]
