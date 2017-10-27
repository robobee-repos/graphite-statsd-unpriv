#!/bin/bash
set -e
source /docker-entrypoint-utils.sh
set_debug

echo "#### Debug"
echo "Run as `id`"
echo "####"

$BASH_CMD /etc/my_init.d/01_conf_init.sh
copy_files "/graphite-conf-in" "/opt/graphite/conf" "*.conf"
copy_files "/statsd-conf-in" "/opt/statsd" "config.js"

cd "${WWW_ROOT}"
exec "$@"
