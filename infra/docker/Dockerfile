# STAGE PLATFORM

# STAGE NGINX

# STAGE AWS
FROM php:7.4.7-cli-buster as base-app

LABEL stage=base-app

ENV webFolder=/var/www/html
ENV rootFolder=s5-docker
WORKDIR ${webFolder}/${rootFolder}
#ARG SSH_PRIVATE_KEY
RUN apt-get update && \
    apt-get install -y git zlib1g-dev wget libgmp3-dev libzip-dev default-mysql-client && \
    docker-php-ext-configure zip && \
    docker-php-ext-install -j$(nproc) \
        zip \
	    gmp \
        pdo_mysql && \
    mkdir -p /root/.ssh/ && \
#    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa && \
    # download yq for yaml parsing config_*.yml
    wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_386 -O yq && chmod +x yq && mv yq /usr/local/sbin/. && \
    chmod -R 600 /root/.ssh/ && \
    /usr/bin/ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts && \
    # Install composer and plugin of prestissimo for parallel package installation
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer self-update && composer global require hirak/prestissimo

# Place private repositories to the root folder
COPY . .

RUN composer install -n

##### Build the eventual image #####
FROM php:7.4.7-fpm-alpine3.12 as app-nginx

# Copy user api code with vendor folder
ENV webFolder=/var/www/html
ENV rootFolder=s5-docker
ENV webServerUser=www-data
ENV webServerGroup=www-data

# Set work directory
WORKDIR ${webFolder}/${rootFolder}
COPY . ./
COPY --from=base-app ${webFolder}/${rootFolder}/config/ ./config/
COPY --from=base-app ${webFolder}/${rootFolder}/vendor/ ./vendor/
COPY --from=base-app ${webFolder}/${rootFolder}/var/ ./var/

# Install required php modules
RUN \
    apk add libzip-dev shadow gmp-dev && \
    docker-php-ext-configure zip && \
    docker-php-ext-install "-j$(nproc)" \
        zip \
        gmp \
        pdo_mysql \
        opcache \
    ;


# Nginx
RUN apk add nginx

# Install Nginx configuration file
COPY ./infra/nginx/conf/nginx.conf /etc/nginx/nginx.conf
COPY ./infra/nginx/conf/nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 8000

ENTRYPOINT [ "sh", "./infra/docker/start-server.sh" ]
