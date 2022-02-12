# Opencart Docker

Configuration:
* Alpine 3.5
* Nginx
* MySQL 8
* PHP 7.4

## Compose
```
curl -O https://raw.githubusercontent.com/als698/opencart-docker/master/docker-compose.yml && docker-compose up -d
```

## Pull
```
docker pull als698/opencart
docker pull als698/php:7.4
```

## Config
Admin OC
  * User: padmin
  * Password: pasmin  
  * Opencart: localhost

phpMyAdmin - http://localhost/pma/

Default Env
  * Database: opencart
  * User DB: dbus3r
  * Password DB: dbpas
  * Root Pass DB: t0rpas
  * HTTP_SERVER: localhost
  * IMPORT_DB: unset - set it to 1 in docker-compose if you want to import your oc db from db/opencart.sql

## Directory for docker-compose

```
db/ - Database
db/data/ - Database data - /db/data/
db/opencart.sql - Import database - /db/opencart.sql

web/ - Web files
web/oc.zip - Opencart files - /var/www/html/
web/storage.zip - Opencart storage - /var/www/storage/
web/pma.zip - phpMyAdmin - /var/www/pma/
```

If you want to use your opencart files, don't forget to remove your config files before you run it (config.php and admin/config.php)

## Acknowledgements
This image was inspired by [khromov/alpine-nginx-php8](https://github.com/khromov/alpine-nginx-php8), [TrafeX/docker-php-nginx](https://github.com/TrafeX/docker-php-nginx), [wangxian/alpine-mysql](https://github.com/wangxian/alpine-mysql) and [this subsequent fork](https://github.com/khromov/docker-php-nginx)
