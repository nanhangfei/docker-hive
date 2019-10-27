[![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/big-data-europe/Lobby)

# docker-hive

This is a docker container for Apache Hive 2.3.2. It is based on https://github.com/big-data-europe/docker-hadoop so check there for Hadoop configurations.
This deploys Hive and starts a hiveserver2 on port 10000.
Metastore is running with a connection to postgresql database.
The hive configuration is performed with HIVE_SITE_CONF_ variables (see hadoop-hive.env for an example).

To run Hive with postgresql metastore:
```
    docker-compose up -d
```

To deploy in Docker Swarm:
```
    docker stack deploy -c docker-compose.yml hive
```

To run a PrestoDB 0.181 with Hive connector:

```
  docker-compose up -d presto-coordinator
```

This deploys a Presto server listens on port `8080`

## Testing
Load data into Hive:
```
  $ docker-compose exec hive-server bash
  # /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
  > CREATE TABLE pokes (foo INT, bar STRING);
  > LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
```

Then query it from PrestoDB. You can get [presto.jar](https://prestosql.io/docs/current/installation/cli.html) from PrestoDB website:
```
  $ wget https://repo1.maven.org/maven2/io/prestosql/presto-cli/308/presto-cli-308-executable.jar
  $ mv presto-cli-308-executable.jar presto.jar
  $ chmod +x presto.jar
  $ ./presto.jar --server localhost:8080 --catalog hive --schema default
  presto> select * from pokes;
```

## Contributors
* Ivan Ermilov [@earthquakesan](https://github.com/earthquakesan) (maintainer)
* Yiannis Mouchakis [@gmouchakis](https://github.com/gmouchakis)

* Ke Zhu [@shawnzhu](https://github.com/shawnzhu)

###详细步骤

1. 克隆代码

```bash
$ git clone https://github.com/nanhangfei/docker-hive.git
$ cd docker-hive
```

2. 构建 bde2020/hive:2.3.2-mysql-metastore镜像

```bash
$ make
```
3. 启动相关镜像

```bash
[root@localhost docker-hive]# docker-compose  up -d  mysql
[root@localhost docker-hive]# docker-compose  up -d  datanode namenode
[root@localhost docker-hive]# docker-compose  up -d hive-server
```
4. mysql创建了metastore数据库，但里面没有任何表。使用Hive Schema Tool的初始化元数据，mysql可以看到多了很多表。如果不执行初始化这一步的话，启动hive-metastore容器是会出现 **Version information not found** 的错误日志。

```bash
[root@localhost docker-hive]# mysql -h 127.0.0.1 -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.6.38 MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| metastore          |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.00 sec)

MySQL [(none)]> use metastore
Database changed
MySQL [metastore]> show tables;
Empty set (0.00 sec)

MySQL [metastore]>
```

在hive-server容器中使用schematool初始化hive需要的元数据
```bash
[root@localhost docker-hive]# docker-compose exec hive-server bash
root@69f59b3f589e:/opt# ./hive/bin/schematool -initSchema -dbType mysql
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/hive/lib/log4j-slf4j-impl-2.6.2.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/hadoop-2.7.4/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Metastore connection URL:     jdbc:mysql://mysql:3306/metastore?createDatabaseIfNotExist=true
Metastore Connection Driver :     com.mysql.cj.jdbc.Driver
Metastore connection User:     root
Starting metastore schema initialization to 2.3.0
Initialization script hive-schema-2.3.0.mysql.sql
Initialization script completed
schemaTool completed
root@69f59b3f589e:/opt#
```

然后启动hive-metastore
```bash
docker-compose  up -d   hive-metastore
```

查看hive-metastore和hive-server的日志，都正常启动了
```bash
[root@localhost docker-hive]# docker-compose logs hive-metastore
[root@localhost docker-hive]# docker-compose logs hive-server
```

5. 验证hive

```bash
  [root@localhost docker-hive]# docker-compose exec hive-server bash
  [root@localhost docker-hive]# /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
  > CREATE TABLE pokes (foo INT, bar STRING);
  > LOAD DATA LOCAL INPATH '/opt/hive/examples/files/kv1.txt' OVERWRITE INTO TABLE pokes;
  > select * from pokes;
```

6. 启动spark、hue

```bash
docker-compose  up -d spark-master spark-worker  hue
```


**执行完第四步执行初始化hive的meta后，以后直接就可以docker-compose up了**
