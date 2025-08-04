# Usar imagen oficial de PHP con Apache
FROM php:8.1-apache

# Instalar extensiones de PHP necesarias
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# Configurar Apache para usar el puerto dinámico de Render
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf && \
    sed -i 's/:80/:${PORT}/' /etc/apache2/sites-available/000-default.conf

# Copiar archivos del proyecto al directorio web
COPY . /var/www/html/

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Crear un script de inicio personalizado
RUN echo '#!/bin/bash\n\
export PORT=${PORT:-80}\n\
sed -i "s/Listen \${PORT}/Listen $PORT/" /etc/apache2/ports.conf\n\
sed -i "s/:\${PORT}/:$PORT/" /etc/apache2/sites-available/000-default.conf\n\
apache2-foreground' > /start.sh && chmod +x /start.sh

# Exponer el puerto
EXPOSE $PORT

# Usar el script personalizado
CMD ["/start.sh"]
