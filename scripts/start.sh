#!/bin/bash

# Enable custom nginx config files if they exist
if [ -f /usr/share/nginx/html/nginx/nginx-${PROFILE}.conf ]; then
  cp /usr/share/nginx/html/nginx/nginx-${PROFILE}.conf /etc/nginx/nginx.conf
fi

if [ -f /usr/share/nginx/html/nginx/vhost-${PROFILE}.conf ]; then
  cp /usr/share/nginx/html/nginx/vhost-${PROFILE}.conf /etc/nginx/conf.d/default.conf
fi

# Enable custom php-fpm config files if they exist
if [ -f /usr/share/nginx/html/nginx/php-fpm-${PROFILE}.conf ]; then
  cp /usr/share/nginx/html/nginx/php-fpm-${PROFILE}.conf /usr/local/etc/php-fpm.conf
fi

# Custom different settings for different environment,such as dev,qa,prod
if [ -f /usr/share/nginx/html/conf/settings-${PROFILE}.js ]; then
  cp /usr/share/nginx/html/conf/settings-${PROFILE}.js /usr/share/nginx/html/conf/settings.js
fi

####
if [ ! -z "$PUID" ]; then
  if [ -z "$PGID" ]; then
    PGID=${PUID}
  fi
  deluser nginx
  addgroup -g ${PGID} nginx
  adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u ${PUID} nginx
else
  if [ -z "$SKIP_CHOWN" ]; then
    chown -Rf nginx.nginx /usr/share/nginx/html
  fi
fi

# Run custom scripts
if [[ "$RUN_SCRIPTS" == "1" ]] ; then
  if [ -d "/usr/share/nginx/html/scripts/" ]; then
    # make scripts executable incase they aren't
    chmod -Rf 750 /usr/share/nginx/html/scripts/*; sync;
    # run scripts in number order
    for i in `ls /usr/share/nginx/html/scripts/`; do /usr/share/nginx/html/scripts/$i ; done
  else
    echo "Can't find script directory"
  fi
fi

if [ -z "$SKIP_COMPOSER" ]; then
    # Try auto install for composer
    if [ -f "/usr/share/nginx/html/composer.lock" ]; then
        if [ "$APPLICATION_ENV" == "development" ]; then
            composer global require hirak/prestissimo
            composer install --working-dir=/usr/share/nginx/html
        else
            composer global require hirak/prestissimo
            composer install --no-dev --working-dir=/usr/share/nginx/html
        fi
    fi
fi

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf

