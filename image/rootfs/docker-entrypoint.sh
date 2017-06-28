#!/bin/bash
set -xe

function check_files_exists() {
  ls "$1" 1> /dev/null 2>&1
}

function copy_file() {
  file="$1"; shift
  dir="$1"; shift
  mod="$1"; shift
  if [ -e "$file" ]; then
    mkdir -p "$dir"
    cp "$file" "$dir/$file"
    chmod $mod "$dir/$file"
  fi
}

function update_nginx_conf() {
  ##
  file="/etc/nginx/nginx.conf"
  search="(worker_processes )\d+;"
  replace="\1${NGINX_WORKER_PROCESSES};"
  do_sed "$file" "$search" "$replace"
  search="(\s+worker_connections )\d+;"
  replace="\1${NGINX_WORKER_CONNECTIONS};"
  do_sed "$file" "$search" "$replace"
  ##
  file="/etc/nginx/sites-enabled/graphite-statsd.conf"
  search="(\s+listen\s+)"
  replace="\1${NGINX_HTTP_PORT};"
  do_sed "$file" "$search" "$replace"
}

function copy_graphite_conf() {
  dir="/graphite-conf-in"
  if [ ! -d "${dir}" ]; then
    return
  fi
  cd "${dir}"
  if ! check_files_exists "*.conf"; then
    return
  fi
  rsync -u -v "${dir}/*.conf" /opt/graphite/conf/
}

function copy_statsd_conf() {
  dir="/statsd-conf-in"
  if [ ! -d "${dir}" ]; then
    return
  fi
  cd "${dir}"
  if [ -e config.js ]; then
    rsync -u -v "${dir}/config.js" /opt/statsd/config.js
  fi
}

function copy_nginx_conf() {
  dir="/nginx-conf-in"
  if [ ! -d "${dir}" ]; then
    return
  fi
  cd "${dir}"
  if [ -e nginx.conf ]; then
    rsync -u -v "${dir}/nginx.conf" /etc/nginx/nginx.conf
  fi
  if [ -e nginx.conf ]; then
    rsync -u -v "${dir}/graphite-statsd.conf" /etc/nginx/sites-enabled/graphite-statsd.conf
  fi
}

echo "#### Debug"
echo "Run as `id`"
echo "####"

source /docker-entrypoint-utils.sh
update_nginx_conf
bash -x /etc/my_init.d/01_conf_init.sh
copy_graphite_conf
copy_statsd_conf
copy_nginx_conf

cd "${WWW_ROOT}"
exec "$@"
