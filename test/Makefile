include ../utils/Makefile.help
include ../utils/Makefile.functions

NAME := graphite-statsd

test: setup ##@targets Starts docker compose.
	docker-compose -p $(NAME) -f test.yaml up
.PHONY: test

rm:
	docker-compose -p $(NAME) -f test.yaml stop
.PHONY: rm

clean: rm
	docker-compose -p $(NAME) -f test.yaml rm -f
	sudo rm -rf root
.PHONY: clean

setup:
	mkdir -p root/graphite
	mkdir -p root/statsd
	sudo chmod o+rwX root/graphite
	sudo chmod o+rwX root/statsd
.PHONY: setup
