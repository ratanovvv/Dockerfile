FROM php:5-fpm

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

RUN apt-get update && apt-get install -y libpq-dev libmemcached-dev libicu-dev libpng-dev freetype* libssl-dev ssmtp libxml2-dev
    
RUN apt-get install -y libmagickwand-dev --no-install-recommends

RUN echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf && \
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini
   
RUN printf '\n\n\n' | pecl install xdebug memcached imagick apcu-4.0.11 mongo

RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
   
RUN docker-php-ext-install pdo pdo_pgsql pgsql gd pdo_mysql intl zip soap bcmath && \
    docker-php-ext-enable gd pdo_pgsql memcached imagick apcu pdo_mysql intl mongo bcmath xdebug

RUN echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so\nxdebug.remote_enable=1\nxdebug.remote_handler=dbgp\nxdebug.remote_port=9009\nxdebug.remote_connect_back = 1\nxdebug.idekey=PHP_STORM' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN echo "upload_max_filesize = 200M\npost_max_size = 200M" > /usr/local/etc/php/conf.d/largefiles.ini

COPY entrypoint.sh /
RUN mkdir /app && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
