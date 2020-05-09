FROM php:7.4.4-cli as baseApp

LABEL stage=s5-base

ENV webFolder=/var/www
ENV rootFolder="s5-docker"
WORKDIR ${webFolder}/${rootFolder}
RUN pwd

COPY . ./

RUN \
    pwd && \
    apt-get update && \
    apt-get install -y git zlib1g-dev libzip-dev wget && \
    docker-php-ext-install -j$(nproc) zip && \
    wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_386 -O yq && chmod +x yq && mv yq /usr/local/sbin/. && \
    # Install composer and plugin of prestissimo for parallel package installation
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer install -n


FROM php:7.4.4-fpm-alpine3.11 as prodOases

ENV webFolder="/var/www"
ENV rootFolder="s5-docker"
ENV webServerUser=www-data
ENV webServerGroup=www-data

# Set work directory
WORKDIR ${webFolder}/${rootFolder}

COPY . ./
COPY --from=baseApp ${webFolder}/${rootFolder}/config/ ./config/
COPY --from=baseApp ${webFolder}/${rootFolder}/vendor/ ./vendor/
COPY --from=baseApp ${webFolder}/${rootFolder}/var/ ./var/

RUN pwd && ls

# Install required php modules
ENV wwwDataUID=1000
ENV wwwDataGID=1000
ENV binPath="/usr/local/bin/"

# Clean up nonessential files and dump asset
RUN \
    id && \
    pwd && \
    ls && \

    rm -rf .githooks docs nginx && \
    php bin/console asset:install && \
    find var/cache/ -type f -name '*' -exec rm -r {} \; && \
    apk --no-cache add shadow && \
    usermod -u ${wwwDataUID} ${webServerUser} && \
    groupmod -g ${wwwDataGID} ${webServerGroup} && \
    chown -R ${webServerUser}:${webServerGroup} ${webFolder}/${rootFolder}/public && \
    chown -R ${webServerUser}:${webServerGroup} ${webFolder}/${rootFolder}/var && \
    chmod -R o=rw ${webFolder}/${rootFolder}/var
CMD ["php-fpm"]

EXPOSE 9000
