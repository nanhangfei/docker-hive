current_branch := 2.3.2-mysql-metastore
build:
	docker build -t bde2020/hive:$(current_branch) ./
