# Usar imagen oficial de PHP
FROM php:8.1-cli

# Instalar extensiones necesarias
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY . .

# Exponer puerto
EXPOSE $PORT

# Comando para iniciar el servidor
CMD ["sh", "-c", "php -S 0.0.0.0:$PORT server.php"]
