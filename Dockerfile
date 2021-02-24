FROM debian:buster

#utils
RUN apt-get update && apt-get install -y vim git wget

#Entrykit
ENV ENTRYKIT_VERSION 0.4.0
WORKDIR /
RUN apt-get install -y openssl \
	&& wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
	&& tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
	&& rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
	&& mv entrykit /bin/entrykit \
	&& chmod +x /bin/entrykit \
	&& entrykit --symlink

#Mariadb
RUN apt-get update && apt-get install -y \
		mariadb-server mariadb-client

#PHP
RUN apt-get update && apt-get install -y php-cgi php-common php-fpm php-pear php-mbstring php-zip php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath

#nginx
RUN apt-get update && apt-get install -y nginx 
COPY ./srcs/default.tmpl /etc/nginx/sites-available/default.tmpl

#SSL
RUN apt-get update && apt-get install -y openssl
COPY ./srcs/on_ssl.sh /var/www/on_ssl.sh
RUN bash /var/www/on_ssl.sh

#phpMyadmin
WORKDIR /tmp
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz; \
	tar -xvzf phpMyAdmin-5.0.2-all-languages.tar.gz; \
	rm phpMyAdmin-5.0.2-all-languages.tar.gz; \
	mv phpMyAdmin-5.0.2-all-languages phpmyadmin; \
	mv phpmyadmin/ /var/www/html/
COPY srcs/config.inc.php /var/www/html/phpmyadmin
RUN chmod 744 /var/www/html/phpmyadmin/config.inc.php

#Mysql
COPY srcs/setup.sql /tmp/
RUN service mysql start; \
	mysql -u root < /var/www/html/phpmyadmin/sql/create_tables.sql; \
	mysql -u root < /tmp/setup.sql; \
	rm -f /tmp/setup_mysql

#WORDPRESS
WORKDIR /var/www/html/
RUN wget https://wordpress.org/latest.tar.gz \
	&& tar -xvzf latest.tar.gz\
	&& rm latest.tar.gz;
COPY srcs/wp-config.php wordpress/
RUN	chown -R www-data:www-data .


COPY ./srcs/service_start.sh /tmp/service_start.sh

ENTRYPOINT ["render", "/etc/nginx/sites-available/default", "--", "bash","/tmp/service_start.sh"]