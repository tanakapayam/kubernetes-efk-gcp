
elasticsearch-logging:
	docker build -t alexcurtin/elasticsearch-logging:latest elasticsearch-logging

kibana-logging:
	docker build -t alexcurtin/kibana-logging:latest kibana-logging

fluentd-logging:
	docker build -t alexcurtin/fluentd-logging:latest fluentd-logging

push:
	docker push alexcurtin/elasticsearch-logging:latest
	docker push alexcurtin/kibana-logging:latest
	docker push alexcurtin/fluentd-logging:latest

all: elasticsearch-logging kibana-logging fluentd-logging push

.PHONY: all elasticsearch-logging kibana-logging fluentd-logging
