
elasticsearch-logging:
	docker build -t skillshare/elasticsearch-logging:latest elasticsearch-logging

kibana-logging:
	docker build -t skillshare/kibana-logging:latest kibana-logging

fluentd-logging:
	docker build -t skillshare/kibana-logging:latest kibana-logging

push:
	docker push skillshare/elasticsearch-logging:latest
	docker push skillshare/kibana-logging:latest
	docker push skillshare/fluentd-logging:latest

all: elasticsearch-logging kibana-logging fluentd-logging push

.PHONY: all elasticsearch-logging kibana-logging fluentd-logging
