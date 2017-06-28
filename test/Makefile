include ../utils/Makefile.help
include ../utils/Makefile.functions

NAME := graphite-statsd-unpriv
ROOT_DIR:=$(shell realpath root)

test: up ##@targets Starts the test containers.

up:
	export ROOT_DIR="$(ROOT_DIR)" \
	&& docker-compose -p $(NAME) -f test.yaml up
.PHONY: up

stop:
	export ROOT_DIR="$(ROOT_DIR)" \
	&& docker-compose -p $(NAME) -f test.yaml stop
.PHONY: stop

clean: stop
	export ROOT_DIR="$(ROOT_DIR)" \
	&& docker-compose -p $(NAME) -f test.yaml rm
.PHONY: stop
