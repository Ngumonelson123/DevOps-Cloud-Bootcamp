FROM php:7.4-apache

LABEL maintainer="Nelson Ngumo <nelson@kewisco.co.ke>"

# Install PHP extensions and dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo pdo_mysql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set ServerName to suppress AH00558 warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY html/ /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
