# Usar imagen oficial de PHP
FROM php:8.1-cli

# Instalar extensiones de PHP necesarias
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY . .

# Exponer el puerto (Render asigna dinámicamente)
EXPOSE $PORT

# Comando para iniciar el servidor PHP integrado
CMD ["sh", "-c", "php -S 0.0.0.0:$PORT index.php"]
