#!/bin/sh
set -e

# Run DB migrations then start gunicorn
python manage.py migrate --noinput

# If you want to collect static files, set env DJANGO_COLLECTSTATIC=1 and configure STATIC_ROOT in settings
if [ "$DJANGO_COLLECTSTATIC" = "1" ] ; then
  python manage.py collectstatic --noinput
fi

exec gunicorn ecommerce_backend.wsgi:application --bind 0.0.0.0:8000
