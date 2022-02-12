FROM alpine:3.5

ENV PAGER="more"

RUN apk --no-cache add \
    mysql mysql-client \
    nginx supervisor curl tzdata htop dcron nano bash unzip && \
    rm -rf /var/cache/apk/*

COPY config/http.conf /etc/nginx/conf.d/default.conf
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY config/mysql.sh /mysql.sh
COPY config/my.cnf /etc/mysql/my.cnf

COPY config/opencart.zip /opencart.zip
COPY db/opencart.sql /opencart.sql
COPY config/catalog-config.php /catalog-config.php
COPY config/admin-config.php /admin-config.php

COPY php/web/pma/ /var/www/pma/

RUN chmod 755 /mysql.sh

WORKDIR /var/www/html

EXPOSE 80
EXPOSE 3306

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping