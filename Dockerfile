FROM phusion/baseimage:0.9.16

ENV HOME /root
ONBUILD RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/graphite-api.sh"]

### see also brutasse/graphite-api

VOLUME /srv/graphite

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# add our config
ONBUILD ADD graphite-api.yaml /etc/graphite-api.yaml
ONBUILD RUN chmod 0644 /etc/graphite-api.yaml

# init scripts
ADD graphite-api.sh /graphite-api.sh
ADD patch /patch

EXPOSE 8000

RUN echo 'deb http://ppa.launchpad.net/pypy/ppa/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://ppa.launchpad.net/pypy/ppa/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y language-pack-en python-virtualenv libcairo2-dev && \
    apt-get install -y --force-yes pypy && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales && \
    chmod +x /graphite-api.sh && \
    mkdir /var/log/graphite-api && \
    virtualenv -p /usr/bin/pypy /srv/graphite-pypy && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# equivalent to what source bin/activate, minus adjusting the shell prompt (PS1)
ENV VIRTUAL_ENV=/srv/graphite-pypy
ENV PATH=/srv/graphite-pypy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ONBUILD ENV VIRTUAL_ENV=/srv/graphite-pypy
ONBUILD ENV PATH=/srv/graphite-pypy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN pip install gunicorn graphite-api[sentry,cyanite] graphite-influxdb Flask-Cache statsd raven blinker elasticsearch && \
    pip uninstall -y graphite-api && \
    pip install https://github.com/Dieterbe/graphite-api/tarball/support-templates2 && \
    cd /srv/graphite-pypy/site-packages && patch -p2 < /patch && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
