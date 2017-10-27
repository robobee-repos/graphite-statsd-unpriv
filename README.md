# Piwik-Noroot

## Description

The image is based on the `graphite-project/docker-graphite-statsd` image and 
lets the services run as the non-privileged user `www-data`.
Furthermore, it adds the option to have a input directory for configuration
files that can be used with Kubernetes Config Map. Need to copy the whole
Dockerfile code because the `docker-graphite-statsd`
image is based on `phusion/baseimage` and is adding a lot of additional daemon
related configuration that will be done by `supervisord` in this image.
This docker image will also remove `nginx` because it should be in an external
container.

## Environment Parameters

| Variable | Default | Description |
| ------------- | ------------- | ----- |
| NGINX_HTTP_PORT  | 8080 | The nginx HTTP port. |
| NGINX_WORKER_PROCESSES | 2 | worker_processes |
| NGINX_WORKER_CONNECTIONS | 1024 | worker_connections |

## Exposed Ports

| Port | Description |
| ------------- | ----- |
| 9000  | php-fpm |
| 8873 | rsync daemon |
| 2003 | "carbon receiver - plaintext":http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-plaintext-protocol" |
| 2004 | "carbon receiver - pickle":http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-pickle-protocol" |
| 2023 | "carbon aggregator - plaintext":http://graphite.readthedocs.io/en/latest/carbon-daemons.html#carbon-aggregator-py" |
| 2024 | "carbon aggregator - pickle":http://graphite.readthedocs.io/en/latest/carbon-daemons.html#carbon-aggregator-py" |
| 8125/udp | "statsd":https://github.com/etsy/statsd/blob/master/docs/server.md" |
| 8126 | "statsd admin":https://github.com/etsy/statsd/blob/v0.7.2/docs/admin_interface.md" |

## Directories

| Path | Description |
| ------------- | ----- |
| /var/www/html  | www-root directory. |
| /data | Reserved ownCloud user data directory. |

## Input Configration

| Source | Destination |
| ------------- | ------------- |
| /graphite-conf-in/*.conf | /opt/graphite/conf/ |
| /statsd-conf-in/config.js | /opt/statsd/config.js |
| /nginx-conf-in/nginx.conf | /etc/nginx/nginx.conf |
| /nginx-conf-in/graphite-statsd.conf | /etc/nginx/sites-enabled/graphite-statsd.conf |

## Rsync

The rsync daemon is running and can be used to backup the data.

| Module | Destination |
| ------------- | ------------- |
| storage | /opt/graphite/storage |

```
rsync -rv rsync://graphite-statsd:8873/storage/. .
```

## Test

The docker-compose file `test.yaml` can be used to the containers.
The command `make test` will start docker-compose.
The installation can be then accessed
from `localhost:8080`.

```
make test > log.txt
```
