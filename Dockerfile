FROM php:7.2-apache

# Update
RUN apt-get update && \
    apt-get upgrade -y

# Install git, process tools
RUN apt-get -y install \ 
	git \ 
	procps \
    zip \
    curl \
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

# .htaccess mod_rewrite for URL rewrite
RUN a2enmod rewrite headers

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

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer self-update --snapshot

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

# Install Python 3.8
ENV PYTHON_VERSION 3.8.5

WORKDIR /pythoninstall
RUN curl -O https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz
RUN tar -xf Python-$PYTHON_VERSION.tar.xz

WORKDIR /pythoninstall/Python-$PYTHON_VERSION
RUN ./configure --enable-optimizations
RUN make -j 4
RUN make altinstall

WORKDIR /
RUN rm -rf /pythoninstall
RUN python3.8 --version

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*