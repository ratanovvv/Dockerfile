#!/bin/bash
cd /app
dir | while read i; do cd $i && (./yii install||true) && (./yii migrate/up --interactive=0||true) && cd ..; done
chown -R www-data /app
php-fpm
