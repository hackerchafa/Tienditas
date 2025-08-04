# Usar imagen oficial de PHP con Apache
FROM php:8.1-apache

# Instalar extensiones de PHP necesarias
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Habilitar mod_rewrite
RUN a2enmod rewrite

# Configurar DocumentRoot
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Copiar archivos del proyecto
COPY . /var/www/html/

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Configurar Apache para el puerto dinámico
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf && \
    echo '<VirtualHost *:${PORT}>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    DocumentRoot /var/www/html' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    <Directory /var/www/html>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Script de inicio
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'export APACHE_RUN_USER=www-data' >> /start.sh && \
    echo 'export APACHE_RUN_GROUP=www-data' >> /start.sh && \
    echo 'export APACHE_LOG_DIR=/var/log/apache2' >> /start.sh && \
    echo 'export APACHE_PID_FILE=/tmp/apache2.pid' >> /start.sh && \
    echo 'export APACHE_LOCK_DIR=/tmp/apache2' && \
    echo 'sed -i "s/\${PORT}/$PORT/g" /etc/apache2/ports.conf' >> /start.sh && \
    echo 'sed -i "s/\${PORT}/$PORT/g" /etc/apache2/sites-available/000-default.conf' >> /start.sh && \
    echo 'apache2 -D FOREGROUND' >> /start.sh && \
    chmod +x /start.sh

# Exponer puerto
EXPOSE $PORT

# Usar script de inicio
CMD ["/start.sh"]
