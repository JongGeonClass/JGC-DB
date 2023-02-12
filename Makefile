# 도커 관련된 변수와 세팅입니다.
SERVER_NAME = jgc-db
SERVER_VERSION = 0.1
CONTAINER_NAME = JGC-DB
DOCKER_NETWORK = jgc-net
PORT = 3306

# 콘솔 색 관련 세팅입니다.
# 아래와 같이 사용하면 됩니다.
# @echo "$(GRENN)Hello World$(RESET)"
GREEN = \033[92m
RESET = \033[0m

# 명령어에 붙는 prefix입니다.
PREFIX = $(GREEN)[JGC]$(RESET)

server:
	@echo "$(PREFIX) Building mysql image..."
	@docker build \
		--platform linux/x86_64 \
		-t $(SERVER_NAME):$(SERVER_VERSION) .
	@echo "$(PREFIX) Done building mysql image."
.PHONY: server

run-test:
	@echo "$(PREFIX) Running mysql image..."
	@docker run \
		--platform linux/x86_64 \
		--name $(CONTAINER_NAME) \
		--network $(DOCKER_NETWORK) \
		-d \
		--restart always \
		-e MYSQL_ROOT_PASSWORD=dbpassjgc \
		-p $(PORT):$(PORT) \
		$(SERVER_NAME):$(SERVER_VERSION) \
			--max_connections=4096 \
			--general_log=1 \
			--general_log_file=/var/lib/mysql/general.log \
			--innodb_print_all_deadlocks=1 \
			--log_error=/var/lib/mysql/error.log \
			--character-set-server=utf8mb4 \
			--collation-server=utf8mb4_unicode_ci
	@echo "$(PREFIX) Success running mysql image."
.PHONY: run

stop:
	@echo "$(PREFIX) Stopping mysql image..."
	@docker stop \
		$(shell docker ps -aqf "name=$(CONTAINER_NAME)")
	@echo "$(PREFIX) Success stopping mysql image."
.PHONY: stop

DANGLING_IMAGE = $(shell docker images -f dangling=true -q)
DB_IMAGE = $(shell docker images --filter=reference="jgc-db" -q)
clean:
	@echo "$(PREFIX) Remove db image..."
ifneq ($(shell docker ps -aqf "name=$(CONTAINER_NAME)"),)
	@docker rm -f \
		$(shell docker ps -aqf "name=$(CONTAINER_NAME)")
endif
	@echo "$(PREFIX) Success Removing db image."

	@echo "$(PREFIX) Removing dangling images..."
ifneq ($(DANGLING_IMAGE),)
	@docker rmi $(DANGLING_IMAGE)
endif
	@echo "$(PREFIX) Done removing dangling images."

	@echo "$(PREFIX) Removing all jgc-db images..."
ifneq ($(DB_IMAGE),)
	@docker rmi -f $(DB_IMAGE)
endif
	@echo "$(PREFIX) Done removing all jgc-db images."
.PHONY: clean
