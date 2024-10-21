src = $(shell find . -type f -name '*.go' | grep -v "kitex_gen" | grep -v "vendor")

.PHONY: fmt build test clean
.PHONY: run-docker-kibana run-docker-kibana-arm64 run-docker-es run-docker-es-arm64 run-docker-mysql run-docker-mysql-arm64 run-docker-mongo run-docker-mongo-arm64 run-docker-redis run-docker-redis-arm64
.PHONY: script-gen-es-data script-clean-data

################################################################
# Go
################################################################

build:
	@echo "Building Go scripts..."
	go build -o bin/my-script ./cmd/...

test:
	@echo "Running tests..."
	go test ./...

clean:
	@echo "Cleaning up..."
	rm -rf bin/*

fmt:
	@echo "Formatting go files..."
	@goimports -w $(src)

################################################################
# Env
################################################################

run-docker-es:
	@docker run --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -d docker.elastic.co/elasticsearch/elasticsearch:7.10.0

run-docker-es-arm64:
	@docker run --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -d docker.elastic.co/elasticsearch/elasticsearch:7.17.0-arm64

run-docker-kibana:
	@docker run --name kibana --link=elasticsearch:test -p 5601:5601 -d docker.elastic.co/kibana/kibana:7.10.0

run-docker-kibana-arm64:
	@docker run --name kibana --link=elasticsearch:test -p 5601:5601 -d docker.elastic.co/kibana/kibana:7.17.0-arm64

run-docker-mysql:
	@docker run -itd --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 mysql

run-docker-mysql-arm64:
	@docker run -itd --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 arm64v8/mysql

run-docker-mongo:
	@docker run -d --name=mongo -p 27017:27017 mongo:latest

run-docker-mongo-arm64:
	@docker run -d --name=mongo -p 27017:27017 arm64v8/mongo:latest

run-docker-redis:
	@docker run -d --name=redis -p 6379:6379 redis:latest

run-docker-redis-arm64:
	@docker run -d --name=redis -p 6379:6379 arm64v8/redis:latest

################################################################
# Scripts
################################################################

script-gen-es-data:
	@go run cmd/es-data-loader/main.go

script-clean-data:
	@go run cmd/data-cleaner/main.go

