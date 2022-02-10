FROM alpine:latest

ARG PHP_VERSION="8.0.14-r0"

ENV PAGER="more"

RUN apk --no-cache add php8=${PHP_VERSION} \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-exif \
    php8-fileinfo \
    php8-fpm \
    php8-gd \
    php8-iconv \
    php8-intl \
    php8-mbstring \
    php8-mysqli \
    php8-opcache \
    php8-openssl \
    php8-pecl-imagick \
    php8-pecl-redis \
    php8-phar \
    php8-session \
    php8-simplexml \
    php8-soap \
    php8-xml \
    php8-xmlreader \
    php8-zip \
    php8-zlib \
    php8-pdo \
    php8-xmlwriter \
    php8-tokenizer \
    php8-pdo_mysql \
    mysql mysql-client \
    nginx supervisor curl tzdata htop dcron nano bash

RUN ln -s /usr/bin/php8 /usr/bin/php

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

COPY config/nginx.conf /etc/nginx/nginx.conf

COPY config/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY config/php.ini /etc/php8/conf.d/custom.ini

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY config/mysql.sh /mysql.sh
COPY config/my.cnf /etc/mysql/my.cnf
COPY db/opencart.sql /opencart.sql

RUN mkdir -p /var/www/html && \
    mkdir -p /db/data && \
    chown -R nobody.nobody /db && \
    mkdir -p /run/mysqld && \
    chown -R nobody.nobody /run/mysqld && \
    chmod 777 /run/mysqld && \
    chown nobody.nobody /mysql.sh && \
    chmod 755 /mysql.sh && \
    chown nobody.nobody /opencart.sql && \
    chmod 755 /opencart.sql && \
    chown -R nobody.nobody /run && \
    chown -R nobody.nobody /var/lib/nginx && \
    chown -R nobody.nobody /var/log/nginx

COPY web/pma/ /var/www/pma/
COPY web/oc/ /var/www/html/
COPY web/storage/ /var/www/storage/

RUN chown -R nobody.nobody /var/www

USER nobody

WORKDIR /var/www/html

EXPOSE 8080
EXPOSE 3306

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping