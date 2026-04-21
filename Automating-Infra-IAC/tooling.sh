#!/bin/bash
mkdir /var/www/
yum update -y
yum install -y mysql
yum install -y php php-mysqlnd php-fpm php-json
yum install -y httpd
systemctl start httpd
systemctl enable httpd
