# Stage 1: Build the application
FROM composer:latest as builder

WORKDIR /app

# Copy composer.json and composer.lock
COPY composer.json composer.lock ./

# Install dependencies (excluding dev dependencies)
RUN composer install --no-scripts --no-autoloader --no-dev

# Copy the rest of the application files
COPY . .

# Generate the autoloader
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# Stage 2: Final image
FROM php:8.0.29-fpm-alpine3.16

# Set the working directory
WORKDIR /var/www/html/web

# Install dependencies
RUN apk add --no-cache \
    git \
    curl \
    libzip-dev \
    zip

# Install PHP extensions
RUN docker-php-ext-install \
    zip \
    mysqli \
    pdo \
    pdo_mysql \
    opcache 

RUN docker-php-ext-enable \
    mysqli

# Copy custom php.ini, opcache.ini, and www.conf files
COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy the application from the builder stage
COPY --from=builder /app .

# Set appropriate permissions
RUN chown -R www-data:www-data /var/www/html/web && \
    chmod -R 755 /var/www/html/web

COPY custom/themes/ /var/www/html/web/app/themes/
COPY custom/plugins/ /var/www/html/web/app/plugins/

# Expose port 9000 (PHP-FPM)
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
