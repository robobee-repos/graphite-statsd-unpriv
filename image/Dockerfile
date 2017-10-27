FROM debian:stretch-slim
LABEL maintainer "Erwin Mueller <erwin.mueller@deventm.com>"

MAINTAINER Denys Zhdanov <denis.zhdanov@gmail.com>

RUN apt-get -y update \
  && apt-get -y upgrade \
  && apt-get -y install vim \
  #nginx \
  python-dev \
  python-flup \
  python-pip \
  python-ldap \
  expect \
  git \
  memcached \
  sqlite3 \
  libffi-dev \
  libcairo2 \
  libcairo2-dev \
  python-cairo \
  python-rrdtool \
  pkg-config \
  nodejs \
  supervisor \
  && rm -rf /var/lib/apt/lists/*

# choose a timezone at build-time
# use `--build-arg CONTAINER_TIMEZONE=Europe/Brussels` in `docker build`
ARG CONTAINER_TIMEZONE
ENV DEBIAN_FRONTEND noninteractive

RUN if [ ! -z "${CONTAINER_TIMEZONE}" ]; \
    then ln -sf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata; \
    fi

# fix python dependencies (LTS Django and newer memcached/txAMQP)
RUN pip install --upgrade pip && \
  pip install django==1.8.18 \
  python-memcached==1.53 \
  txAMQP==0.6.2 \
  && pip install cffi==1.11.2

ENV version=1.0.2
ENV whisper_version=${version}
ENV carbon_version=${version}
ENV graphite_version=${version}
ENV statsd_version=v0.8.0

# install whisper
RUN git clone -b ${whisper_version} --depth 1 https://github.com/graphite-project/whisper.git /usr/local/src/whisper \
&& cd /usr/local/src/whisper \
&& python ./setup.py install \
# install carbon
&& git clone -b ${carbon_version} --depth 1 https://github.com/graphite-project/carbon.git /usr/local/src/carbon \
&& cd /usr/local/src/carbon \
&& sed -r -i -e "s|git://github.com/graphite-project/ceres.git|https://github.com/graphite-project/ceres.git|g" requirements.txt \
&& sed -r -i -e "s|git://github.com/graphite-project/whisper.git|https://github.com/graphite-project/whisper.git|g" requirements.txt \
&& cat requirements.txt \
&& pip install -r requirements.txt \
  && python ./setup.py install \
# install graphite
&& git clone -b ${graphite_version} --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web \
&& cd /usr/local/src/graphite-web \
&& pip install -r requirements.txt \
  && python ./setup.py install \
# install statsd
&& git clone -b ${statsd_version} https://github.com/etsy/statsd.git /opt/statsd \
&& apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# config graphite
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/
ADD conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
# ADD conf/opt/graphite/webapp/graphite/app_settings.py /opt/graphite/webapp/graphite/app_settings.py
WORKDIR /opt/graphite/webapp
RUN mkdir -p /var/log/graphite/ \
  && PYTHONPATH=/opt/graphite/webapp django-admin.py collectstatic --noinput --settings=graphite.settings \
&& apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# config statsd
ADD conf/opt/statsd/config_*.js /opt/statsd/

# config nginx
#RUN rm /etc/nginx/sites-enabled/default
#ADD conf/etc/nginx/nginx.conf /etc/nginx/nginx.conf
#ADD conf/etc/nginx/sites-enabled/graphite-statsd.conf /etc/nginx/sites-enabled/graphite-statsd.conf

# init django admin
ADD conf/usr/local/bin/django_admin_init.exp /usr/local/bin/django_admin_init.exp
ADD conf/usr/local/bin/manage.sh /usr/local/bin/manage.sh
RUN chmod +x /usr/local/bin/manage.sh && /usr/local/bin/django_admin_init.exp \
&& apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx
ADD conf/etc/logrotate.d/graphite-statsd /etc/logrotate.d/graphite-statsd

# daemons
ADD conf/etc/service/carbon/run /etc/service/carbon/run
ADD conf/etc/service/carbon-aggregator/run /etc/service/carbon-aggregator/run
ADD conf/etc/service/graphite/run /etc/service/graphite/run
ADD conf/etc/service/statsd/run /etc/service/statsd/run
ADD conf/etc/service/nginx/run /etc/service/nginx/run

# default conf setup
ADD conf /etc/graphite-statsd/conf
ADD conf/etc/my_init.d/01_conf_init.sh /etc/my_init.d/01_conf_init.sh

# cleanup
#RUN apt-get clean\
# && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# defaults
#EXPOSE 80 2003-2004 2023-2024 8125 8125/udp 8126
#VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/etc/nginx", "/opt/statsd", "/etc/logrotate.d", "/var/log"]
WORKDIR /
ENV HOME /root
ENV STATSD_INTERFACE udp

# Finish graphite-project/docker-graphite-statsd.

ENV WWW_USER="www-data"

ADD rootfs/ /

RUN set -x \
  && chmod o+rwX /var/run \
  && mkdir -p /var/log/supervisord \
  && chmod o+rwX /var/log/supervisord \
  && chmod +x /*.sh \
  && chmod o+rwX -R \
    "/etc/logrotate.d" \
    "/var/log" \
  && chmod o+rw /usr/local/src/graphite-web/setup.cfg \
  && chmod o+rw /usr/local/src/carbon/setup.cfg

EXPOSE 9090 2003-2004 2023-2024 8125 8125/udp 8126

VOLUME ["/opt/graphite", "/opt/statsd"]

USER ${WWW_USER}

WORKDIR /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
