FROM php:8.0-apache

# Install PHP MySQL extension
RUN docker-php-ext-install mysqli

# Fix Apache ServerName warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copy application files to Apache web root
COPY html/ /var/www/html/

EXPOSE 80

CMD ["apache2-foreground"]
