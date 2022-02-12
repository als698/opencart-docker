#!/bin/bash

set -eo pipefail
shopt -s nullglob

mkdir -p /db/data
chmod 777 -R /db
if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
    chmod 777 /run/mysqld
    mysql_installed=0
else
    rm -f /run/mysqld/msqld.sock
    mysql_installed=1
fi

if [ ! -d "/var/www/html/admin" ]; then
  mkdir -p /var/www/html/admin
fi
cp /catalog-config.php /var/www/html/config.php
cp /admin-config.php /var/www/html/admin/config.php

if [ "$HTTP_SERVER" != "" ]; then
  sed -i -e "s/\/localhost/\/$HTTP_SERVER/g" /var/www/html/config.php
  sed -i -e "s/\/localhost/\/$HTTP_SERVER/g" /var/www/html/admin/config.php
fi

if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
  MYSQL_ROOT_PASSWORD="t0rpas"
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL root Password: $MYSQL_ROOT_PASSWORD"
fi

if [ "$MYSQL_DATABASE" = "" ]; then
  MYSQL_DATABASE="opencart"
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL database: $MYSQL_DATABASE"
else
  sed -i -e "s/opencart'/$MYSQL_DATABASE'/g" /var/www/html/config.php
  sed -i -e "s/opencart'/$MYSQL_DATABASE'/g" /var/www/html/admin/config.php
fi

if [ "$MYSQL_USER" = "" ]; then
  MYSQL_USER="dbus3r"
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL user: $MYSQL_USER"
else
  sed -i -e "s/dbus3r/$MYSQL_USER/g" /var/www/html/config.php
  sed -i -e "s/dbus3r/$MYSQL_USER/g" /var/www/html/admin/config.php
fi

if [ "$MYSQL_PASSWORD" = "" ]; then
  MYSQL_PASSWORD="dbpas"
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL $MYSQL_USER password: $MYSQL_PASSWORD"
else
  sed -i -e "s/dbpas/$MYSQL_PASSWORD/g" /var/www/html/config.php
  sed -i -e "s/dbpas/$MYSQL_PASSWORD/g" /var/www/html/admin/config.php
fi

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
    return 1
fi

if [ -d /db/data/mysql ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL directory already present, skipping creation"
else
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: creating database"
  mysql_install_db > /dev/null
  echo "USE mysql;" >> $tfile
  echo "TRUNCATE mysql.user;" >> $tfile
  echo "FLUSH PRIVILEGES;" >> $tfile
  echo "CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" >> $tfile
  echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" >> $tfile
  echo "DROP DATABASE IF EXISTS test;" >> $tfile
  echo "FLUSH PRIVILEGES;" >> $tfile
fi

if [ -d /db/data/${MYSQL_DATABASE} ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: $MYSQL_DATABASE already present, skipping creation"
else
  echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: $MYSQL_DATABASE not found, creating initial DBs"
  echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
  IMPORT_DB=1
  cp /opencart.sql /db/opencart.sql
fi

echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: creating $MYSQL_USER"
echo "USE mysql;" >> $tfile
echo "DROP USER IF EXISTS $MYSQL_USER;" >> $tfile
echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: grant privileges $MYSQL_USER to $MYSQL_DATABASE"
echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%';" >> $tfile

/usr/bin/mysqld --skip-networking &
pid="$!"

if [ "$mysql_installed" = "0" ]; then
  mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/run/mysqld/mysqld.sock )
else
  mysql=( mysql --protocol=socket -uroot -p$MYSQL_ROOT_PASSWORD -hlocalhost --socket=/run/mysqld/mysqld.sock )
fi

for i in {30..0}; do
    echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL init process in progress..."
    if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
        break
    fi
    
    sleep 1
done

if [ "$i" = 0 ]; then
    echo >&2 $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL init process failed."
    exit 1
else
    echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: Database initiated [1/2]"
fi

if [ "$IMPORT_DB" = "1" ]; then
    echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: importing /db/opencart.sql to $MYSQL_DATABASE"
    echo "USE $MYSQL_DATABASE;" >> $tfile
    echo "source /db/opencart.sql;" >> $tfile
fi

"${mysql[@]}" < $tfile

rm -f $tfile

if ! kill -s TERM "$pid" || ! wait "$pid"; then
    echo >&2 $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: MySQL init process failed."
    exit 1
else
    echo $(date '+%Y-%m-%d %H:%M:%S') "mysql [info]: Database initiated [2/2]"
fi

if [ ! -f "/var/www/html/index.php" ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Opencart not present in docker-compose"
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Installing Opencart"
  unzip /oc.zip -d /var/www/html/
fi

if [ ! -f "/var/www/storage/vendor/autoload.php" ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Opencart Storage not present in docker-compose"
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Installing Opencart Storage"
  unzip /storage.zip -d /var/www/storage/
fi
echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Opencart installed [OK]"


if [ ! -f "/var/www/pma/index.php" ]; then
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: Installing phpMyAdmin"
  unzip /pma.zip -d /var/www/
  echo $(date '+%Y-%m-%d %H:%M:%S') "web [info]: phpMyAdmin installed [OK]"
fi

chmod -R 777 /var/www/
chmod -R 644 /var/www/*/config*.php
chown -R nginx.nginx /var/www

echo $(date '+%Y-%m-%d %H:%M:%S') "STARTING DATABASE"

exec /usr/bin/mysqld