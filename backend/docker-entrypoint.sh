#!/bin/sh
set -e

# Initialize .env if missing
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env
    php artisan key:generate --force
fi

# Ensure storage and bootstrap cache permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Run database migrations
php artisan migrate --force

# Optionally seed synthetic demo accounts if requested
if [ "$SEED_DEMO_DATA" = "true" ]; then
    php artisan db:seed --force
fi

# Optimize application
php artisan config:cache
php artisan route:cache

# Start Laravel HTTP server
exec php artisan serve --host=0.0.0.0 --port=8000

