# MariaDB packaged by Bitnami

## What is MariaDB?

> MariaDB is an open source, community-developed SQL database server that is widely in use around the world due to its enterprise features, flexibility, and collaboration with leading tech firms.

[Overview of MariaDB](https://mariadb.org/)

This project has been forked from [bitnami-docker-mariadb](https://github.com/bitnami/bitnami-docker-mariadb),  We mainly modified the dockerfile in order to build the images of amd64 and arm64 architectures. 

Trademarks: This software listing is packaged by Bitnami. The respective trademarks mentioned in the offering are owned by the respective companies, and use of them does not imply any affiliation or endorsement.

## TL;DR

```console
$ docker run --name mariadb -e ALLOW_EMPTY_PASSWORD=yes quay.io/drycc-addons/mariadb:latest
```

### Docker Compose

```console
$ curl -sSL https://raw.githubusercontent.com/drycc-addons/drycc-docker-mariadb/master/docker-compose.yml > docker-compose.yml
$ docker-compose up -d
```

**Warning**: These quick setups are only intended for development environments. You are encouraged to change the insecure default credentials and check out the available configuration options in the [Configuration](#configuration) section for a more secure deployment.

## Get this image

The recommended way to get the drycc-addons MariaDB Docker Image is to pull the prebuilt image from the [Container Image Registry](https://quay.io/repository/drycc-addons/mariadb).

To use a specific version, you can pull a versioned tag. You can view the [list of available versions](https://quay.io/repository/drycc-addons/mariadb?tab=tags) in the Container Image Registry.

```console
$ docker pull quay.io/drycc-addons/mariadb:[TAG]
```

If you wish, you can also build the image yourself by cloning the repository, changing to the directory containing the Dockerfile and executing the `docker build` command. Remember to replace the `VERSION` and `OPERATING-SYSTEM` path placeholders in the example command below with the correct values.

```console
$ git clone https://github.com/drycc-addons/drycc-docker-mariadb.git
$ cd drycc-docker-mariadb/VERSION/OPERATING-SYSTEM
$ docker build -t drycc/mariadb:latest .
```

## Persisting your database

If you remove the container all your data will be lost, and the next time you run the image the database will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should mount a directory at the `/drycc/mariadb` path. If the mounted directory is empty, it will be initialized on the first run.

```console
$ docker run \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /path/to/mariadb-persistence:/drycc/mariadb \
    quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    volumes:
      - /path/to/mariadb-persistence:/drycc/mariadb
  ...
```

> NOTE: As this is a non-root container, the mounted files and directories must have the proper permissions for the UID `1001`.

## Connecting to other containers

Using [Docker container networking](https://docs.docker.com/engine/userguide/networking/), a MariaDB server running inside a container can easily be accessed by your application containers.

Containers attached to the same network can communicate with each other using the container name as the hostname.

### Using the Command Line

In this example, we will create a MariaDB client instance that will connect to the server instance that is running on the same docker network as the client.

#### Step 1: Create a network

```console
$ docker network create app-tier --driver bridge
```

#### Step 2: Launch the MariaDB server instance

Use the `--network app-tier` argument to the `docker run` command to attach the MariaDB container to the `app-tier` network.

```console
$ docker run -d --name mariadb-server \
    -e ALLOW_EMPTY_PASSWORD=yes \
    --network app-tier \
    quay.io/drycc-addons/mariadb:10.8
```

#### Step 3: Launch your MariaDB client instance

Finally we create a new container instance to launch the MariaDB client and connect to the server created in the previous step:

```console
$ docker run -it --rm \
    --network app-tier \
    quay.io/drycc-addons/mariadb:10.8 mysql -h mariadb-server -u root
```

### Using Docker Compose

When not specified, Docker Compose automatically sets up a new network and attaches all deployed services to that network. However, we will explicitly define a new `bridge` network named `app-tier`. In this example we assume that you want to connect to the MariaDB server from your own custom application image which is identified in the following snippet by the service name `myapp`.

```yaml
version: '2'

networks:
  app-tier:
    driver: bridge

services:
  mariadb:
    image: 'quay.io/drycc-addons/mariadb:10.8'
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    networks:
      - app-tier
  myapp:
    image: 'YOUR_APPLICATION_IMAGE'
    networks:
      - app-tier
```

> **IMPORTANT**:
>
> 1. Please update the `YOUR_APPLICATION_IMAGE` placeholder in the above snippet with your application image
> 2. In your application container, use the hostname `mariadb` to connect to the MariaDB server

Launch the containers using:

```console
$ docker-compose up -d
```

## Configuration

### Initializing a new instance

When the container is executed for the first time, it will execute the files with extensions `.sh`, `.sql` and `.sql.gz` located at `/docker-entrypoint-initdb.d`.

In order to have your custom files inside the docker image you can mount them as a volume.

Take into account those scripts are treated differently depending on the extension. While the `.sh` scripts are executed in all the nodes; the `.sql` and `.sql.gz` scripts are only executed in the master nodes. The reason behind this differentiation is that the `.sh` scripts allow adding conditions to determine what is the node running the script, while these conditions can't be set using `.sql` nor `sql.gz` files. This way it is possible to cover different use cases depending on their needs.

> NOTE: If you are importing large databases, it is recommended to import them as `.sql` instead of `.sql.gz`, as the latter one needs to be decompressed on the fly and not allowing for additional optimizations to import large files.

### Passing extra command-line flags to mysqld startup

Passing extra command-line flags to the mysqld service command is possible through the following env var:

- `MARIADB_EXTRA_FLAGS`: Flags to be appended to the startup command. No defaults

```console
$ docker run --name mariadb -e ALLOW_EMPTY_PASSWORD=yes -e MARIADB_EXTRA_FLAGS='--max-connect-errors=1000 --max_connections=155' quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_EXTRA_FLAGS=--max-connect-errors=1000 --max_connections=155
  ...
```

### Setting character set and collation

It is possible to configure the character set and collation used by default by the database with the following environment variables:

- `MARIADB_CHARACTER_SET`: The default character set to use. Default: `utf8`
- `MARIADB_COLLATE`: The default collation to use. Default: `utf8_general_ci`

### Setting the root password on first run

The root user and password can easily be setup with the Bitnami MariaDB Docker image using the following environment variables:

 - `MARIADB_ROOT_USER`: The database admin user. Defaults to `root`.
 - `MARIADB_ROOT_PASSWORD`: The database admin user password. No defaults.
 - `MARIADB_ROOT_PASSWORD_FILE`: Path to a file that contains the admin user password. This will override the value specified in `MARIADB_ROOT_PASSWORD`. No defaults.

Passing the `MARIADB_ROOT_PASSWORD` environment variable when running the image for the first time will set the password of the `MARIADB_ROOT_USER` user to the value of `MARIADB_ROOT_PASSWORD`.

```console
$ docker run --name mariadb -e MARIADB_ROOT_PASSWORD=password123 quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    environment:
      - MARIADB_ROOT_PASSWORD=password123
  ...
```

**Warning** The `MARIADB_ROOT_USER` user is always created with remote access. It's suggested that the `MARIADB_ROOT_PASSWORD` env variable is always specified to set a password for the `MARIADB_ROOT_USER` user. In case you want to allow the `MARIADB_ROOT_USER` user to access the database without a password set the environment variable `ALLOW_EMPTY_PASSWORD=yes`. **This is recommended only for development**.

### Allowing empty passwords

By default the MariaDB image expects all the available passwords to be set. In order to allow empty passwords, it is necessary to set the `ALLOW_EMPTY_PASSWORD=yes` env variable. This env variable is only recommended for testing or development purposes. We strongly recommend specifying the `MARIADB_ROOT_PASSWORD` for any other scenario.

```console
$ docker run --name mariadb -e ALLOW_EMPTY_PASSWORD=yes quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:


```yaml
services:
  mariadb:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
  ...
```

### Creating a database on first run

By passing the `MARIADB_DATABASE` environment variable when running the image for the first time, a database will be created. This is useful if your application requires that a database already exists, saving you from having to manually create the database using the MySQL client.

```console
$ docker run --name mariadb \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -e MARIADB_DATABASE=my_database \
    quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_DATABASE=my_database
  ...
```

### Creating a database user on first run

You can create a restricted database user that only has permissions for the database created with the [`MARIADB_DATABASE`](#creating-a-database-on-first-run) environment variable. To do this, provide the `MARIADB_USER` environment variable and to set a password for the database user provide the `MARIADB_PASSWORD` variable (alternatively, you can set the `MARIADB_PASSWORD_FILE` with the path to a file that contains the user password). MariaDB supports different authentication mechanisms, such as `pam` or `mysql_native_password`. To set it, use the `MARIADB_AUTHENTICATION_PLUGIN` variable.

```console
$ docker run --name mariadb \
  -e ALLOW_EMPTY_PASSWORD=yes \
  -e MARIADB_USER=my_user \
  -e MARIADB_PASSWORD=my_password \
  -e MARIADB_DATABASE=my_database \
  quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=my_user
      - MARIADB_PASSWORD=my_password
      - MARIADB_DATABASE=my_database
  ...
```

**Note!** The `root` user will be created with remote access and without a password if `ALLOW_EMPTY_PASSWORD` is enabled. Please provide the `MARIADB_ROOT_PASSWORD` env variable instead if you want to set a password for the `root` user.

### Disable creation of test database

By default MariaDB creates a test database. In order to disable the creation of this test database, the flag `--skip-test-db` can be passed to `mysql_install_db`. This function is only on MariaDB >= `10.5`.

To disable the test database in the Bitnami MariaDB container, set the `MARIADB_SKIP_TEST_DB` environment variable to `yes` during the first boot of the container.

```console
$ docker run --name mariadb \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -e MARIADB_SKIP_TEST_DB=yes \
    quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_SKIP_TEST_DB=yes
  ...
```

### Slow query logs

By default MariaDB doesn't enable [slow query log](https://mariadb.com/kb/en/slow-query-log-overview/) to record the SQL queries that take a long time to perform. You can modify these settings using the following environment variables:

- `MARIADB_ENABLE_SLOW_QUERY`: Whether to enable slow query logs. Default: `0`
- `MARIADB_LONG_QUERY_TIME`: How much time, in seconds, defines a slow query. Default: `10.0`

### Slow filesystems

In some platforms, the filesystem used for persistence could be slow. That could cause the database to take extra time to be ready. If that's the case, you can configure the `MARIADB_INIT_SLEEP_TIME` environment variable to make the initialization script to wait extra time (in seconds) before proceeding with the configuration operations.

### Configuration file

The image looks for user-defined configurations in `/opt/drycc/mariadb/conf/my_custom.cnf`. Create a file named `my_custom.cnf` and mount it at `/opt/drycc/mariadb/conf/my_custom.cnf`.

For example, in order to override the `max_allowed_packet` directive:

#### Step 1: Write your `my_custom.cnf` file with the following content.

```config
[mysqld]
max_allowed_packet=32M
```

#### Step 2: Run the mariaDB image with the designed volume attached.

```console
$ docker run --name mariadb \
    -p 3306:3306 \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /path/to/my_custom.cnf:/opt/drycc/mariadb/conf/my_custom.cnf:ro \
    -v /path/to/mariadb-persistence:/drycc/mariadb \
    quay.io/drycc-addons/mariadb:10.8
```

or by modifying the [`docker-compose.yml`](https://github.com/drycc-addons/drycc-docker-mariadb/blob/main/docker-compose.yml) file present in this repository:

```yaml
services:
  mariadb:
  ...
    volumes:
      - /path/to/my_custom.cnf:/opt/drycc/mariadb/conf/my_custom.cnf:ro
      - /path/to/mariadb-persistence:/drycc/mariadb
  ...
```

After that, your changes will be taken into account in the server's behaviour.

Refer to the [MariaDB server option and variable reference guide](https://dev.mysql.com/doc/refman/5.7/en/server-option-variable-reference.html) for the complete list of configuration options.

#### Overwrite the main Configuration file

It is also possible to use your custom `my.cnf` and overwrite the main configuration file.

```console
$ docker run --name mariadb  -e ALLOW_EMPTY_PASSWORD=yes -v /path/to/my.cnf:/opt/drycc/mariadb/conf/my.cnf:ro quay.io/drycc-addons/mariadb:10.8
```

## Customize this image

The Bitnami MariaDB Docker image is designed to be extended so it can be used as the base image for your custom configuration.

### Extend this image

Before extending this image, please note there are certain configuration settings you can modify using the original image:

- Settings that can be adapted using environment variables. For instance, you can change the ports used by MariaDB, by setting the environment variables `MARIADB_PORT_NUMBER` or the character set using `MARIADB_CHARACTER_SET` respectively.

If your desired customizations cannot be covered using the methods mentioned above, extend the image. To do so, create your own image using a Dockerfile with the format below:

```Dockerfile
FROM quay.io/drycc-addons/mariadb
### Put your customizations below
...
```

Here is an example of extending the image with the following modifications:

- Install the `vim` editor
- Modify the MariaDB configuration file
- Modify the ports used by MariaDB
- Change the user that runs the container

```Dockerfile
### Change user to perform privileged actions
USER 0
### Install 'vim'
RUN install_packages vim
### Revert to the original non-root user
USER 1001

### modify configuration file.
RUN ini-file set --section "mysqld" --key "collation-server" --value "utf8_general_ci" "/opt/drycc/mariadb/conf/my.cnf"

### Modify the ports used by MariaDB by default
## It is also possible to change these environment variables at runtime
ENV MARIADB_PORT_NUMBER=3307
EXPOSE 3307

### Modify the default container user
USER 1002
```

Based on the extended image, you can use a Docker Compose file like the one below to add other features:

- Add a custom configuration

```yaml
version: '2'

services:
  mariadb:
    build: .
    ports:
      - '3306:3307'
    volumes:
      - /path/to/my_custom.cnf:/opt/drycc/mariadb/conf/my_custom.cnf:ro
      - data:/drycc/mariadb/data
volumes:
  data:
    driver: local
```

## Logging

The Bitnami MariaDB Container image sends the container logs to the `stdout`. To view the logs:

```console
$ docker logs mariadb
```

or using Docker Compose:

```console
$ docker-compose logs mariadb
```

You can configure the containers [logging driver](https://docs.docker.com/engine/admin/logging/overview/) using the `--log-driver` option if you wish to consume the container logs differently. In the default configuration docker uses the `json-file` driver.

## Maintenance

### Upgrade this image

Bitnami provides up-to-date versions of MariaDB, including security patches, soon after they are made upstream. We recommend that you follow these steps to upgrade your container.

#### Step 1: Get the updated image

```console
$ docker pull quay.io/drycc-addons/mariadb:10.8
```

or if you're using Docker Compose, update the value of the image property to
`quay.io/drycc-addons/mariadb:10.8`.

#### Step 2: Stop and backup the currently running container

Stop the currently running container using the command

```console
$ docker stop mariadb
```

or using Docker Compose:

```console
$ docker-compose stop mariadb
```

Next, take a snapshot of the persistent volume `/path/to/mariadb-persistence` using:

```console
$ rsync -a /path/to/mariadb-persistence /path/to/mariadb-persistence.bkp.$(date +%Y%m%d-%H.%M.%S)
```

You can use this snapshot to restore the database state should the upgrade fail.

#### Step 3: Remove the currently running container

```console
$ docker rm -v mariadb
```

or using Docker Compose:

```console
$ docker-compose rm -v mariadb
```

#### Step 4: Run the new image

Re-create your container from the new image.

```console
$ docker run --name mariadb quay.io/drycc-addons/mariadb:10.8
```

or using Docker Compose:

```console
$ docker-compose up mariadb
```

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/drycc-addons/drycc-docker-mariadb/issues), or submit a [pull request](https://github.com/drycc-addons/drycc-docker-mariadb/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can file an [issue](https://github.com/drycc-addons/drycc-docker-mariadb/issues/new). For us to provide better support, be sure to include the following information in your issue:

- Host OS and version
- Docker version (`docker version`)
- Output of `docker info`
- Version of this container
- The command you used to run the container, and any relevant output you saw (masking any sensitive information)
