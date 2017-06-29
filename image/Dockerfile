FROM debian:jessie-slim
LABEL maintainer "Erwin Mueller <erwin.mueller@deventm.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV WWW_ROOT /var/www/html
ENV WWW_USER www-data
ENV GRAPHITE_PORT 9090
ENV NGINX_HTTP_PORT 8080
ENV NGINX_WORKER_PROCESSES 2
ENV NGINX_WORKER_CONNECTIONS 1024

RUN set -x \
  # Optional add proxy entries for apt.
  && if [ -n "${APT_CACHE}" ]; then \
  echo Acquire::ftp::Proxy \"$APT_CACHE\"; >> /etc/apt/apt.conf.d/08proxy;\
  echo Acquire::http::Proxy \"$APT_CACHE\"; >> /etc/apt/apt.conf.d/08proxy;\
  echo Acquire::https::Proxy \"$APT_CACHE\"; >> /etc/apt/apt.conf.d/08proxy;\
  fi

RUN apt-get -y update\
 && apt-get -y upgrade \
 && apt-get -y --force-yes install \
 nginx\
 python-dev\
 python-flup\
 python-pip\
 python-ldap\
 expect\
 git\
 memcached\
 sqlite3\
 libcairo2\
 libcairo2-dev\
 libffi-dev \
 python-cairo\
 python-rrdtool\
 pkg-config\
 nodejs \
 # extras
    rsync \
# cleanup
&& apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -x \
  # supervisor
  && pip install -U  pip setuptools \
  && easy_install supervisor

RUN set -x \
 # python dependencies
&& pip install django==1.9.13\
 python-memcached==1.58\
 txAMQP==0.4\
 simplejson==3.11.1\
 django-tagging==0.4.3\
 twisted==11.1.0\
 pytz==2017.2\
 pyparsing==2.2.0\
 cairocffi==0.8.0\
 git+https://github.com/graphite-project/whisper.git#egg=whisper\
 git+https://github.com/graphite-project/ceres.git#egg=ceres\
 scandir==1.5 \
 pyCLI==devel

ENV GRAPHITE_VERSION 1.0.1
ENV STATSD_VERSION v0.8.0

# install graphite
RUN git clone -b ${GRAPHITE_VERSION} --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web
WORKDIR /usr/local/src/graphite-web
RUN python ./setup.py install
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/
ADD conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
ADD conf/opt/graphite/webapp/graphite/app_settings.py /opt/graphite/webapp/graphite/app_settings.py
WORKDIR /opt/graphite/webapp

# install whisper
RUN git clone -b ${GRAPHITE_VERSION} --depth 1 https://github.com/graphite-project/whisper.git /usr/local/src/whisper
WORKDIR /usr/local/src/whisper
RUN python ./setup.py install

# install carbon
RUN git clone -b ${GRAPHITE_VERSION} --depth 1 https://github.com/graphite-project/carbon.git /usr/local/src/carbon
WORKDIR /usr/local/src/carbon
RUN python ./setup.py install

# install statsd
RUN git clone -b ${STATSD_VERSION} https://github.com/etsy/statsd.git /opt/statsd
ADD conf/opt/statsd/config.js /opt/statsd/config.js

# config nginx
RUN rm /etc/nginx/sites-enabled/default
ADD conf/etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/etc/nginx/sites-enabled/graphite-statsd.conf /etc/nginx/sites-enabled/graphite-statsd.conf

# init django admin
ADD conf/usr/local/bin/django_admin_init.exp /usr/local/bin/django_admin_init.exp
RUN set -x \
  && export PYTHONPATH=/opt/graphite/webapp \
  && /usr/local/bin/django_admin_init.exp

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx

# default conf setup
ADD conf /etc/graphite-statsd/conf
ADD conf/etc/my_init.d/01_conf_init.sh /etc/my_init.d/01_conf_init.sh

# rsync daemon

ADD rootfs/rsyncd.conf /etc/rsyncd.conf

EXPOSE 8873

# Finishing up.

ADD rootfs/docker-entrypoint-utils.sh /docker-entrypoint-utils.sh
ADD rootfs/docker-entrypoint.sh /docker-entrypoint.sh
ADD rootfs/supervisord.conf /etc/supervisord.conf

RUN set -x \
  && chmod o+rwX /var/run \
  && mkdir -p /var/log/supervisord \
  && chmod o+rwX /var/log/supervisord \
  && chmod o+rwX /var/log \
  && chmod +x /docker-entrypoint.sh \
  && mkdir -p /var/lib/nginx \
  && chown ${WWW_USER} -R \
    "/opt/graphite/conf" \
    "/opt/graphite/storage" \
    "/etc/nginx" \
    "/opt/statsd" \
    "/etc/logrotate.d" \
    "/var/log" \
    "/var/lib/nginx" \
  && mkdir -p /graphite-conf-in \
  && mkdir -p /statsd-conf-in \
  && mkdir -p /nginx-conf-in

EXPOSE 8080 2003-2004 2023-2024 8125/udp 8126

VOLUME ["/opt/graphite/storage"]

USER ${WWW_USER}

WORKDIR /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
