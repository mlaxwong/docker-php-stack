FROM php:8.0.7-fpm

# Update
RUN apt-get update && \
    apt-get upgrade -y

# Install git, process tools
RUN apt-get -y install \ 
	git \ 
	procps \
    zip \
    curl \
	wget \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
	libzip-dev \
	libonig-dev \
    g++

# PHP extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    pdo_mysql \
    zip

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# RUN composer self-update --snapshot
RUN composer self-update
RUN composer --version

# Install xdebug
RUN yes | pecl install xdebug \
	&& echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" \
		 > /usr/local/etc/php/conf.d/xdebug.ini \
	&& echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini \
	&& echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini \
	&& echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini \
	&& echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/xdebug.ini

# Dev Composer Cli
WORKDIR /usr/local/bin
RUN wget -O devcomposercli https://raw.githubusercontent.com/mlaxwong/devcomposercli/1.0.0/builds/devcomposercli
RUN chmod +x /usr/local/bin/devcomposercli

# Install NodeJS
ARG NODE_VERSION=14.11.0
ARG NVM_DIR=/usr/local/nvm

# https://github.com/creationix/nvm#install-script
RUN mkdir $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN node -v
RUN npm -v

# Directory restructure
ENV DEVTOOL_LOCALPACKAGE_PATH /localpackages
ENV APP_ROOT /app

WORKDIR ${DEVTOOL_LOCALPACKAGE_PATH}
WORKDIR ${APP_ROOT}
RUN echo "<?php phpinfo(); ?>" > index.php

# Permission
RUN chmod -R 755 ${APP_ROOT}

# Volume
VOLUME ${APP_ROOT}
VOLUME ${DEVTOOL_LOCALPACKAGE_PATH}

# Change back to default directory
WORKDIR ${APP_ROOT}

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*