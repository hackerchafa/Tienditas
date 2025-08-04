#!/bin/bash
# Script para instalar PHP y ejecutar el servidor
echo "🚀 Iniciando instalación de PHP..."

# Detectar el sistema operativo
if command -v apt-get &> /dev/null; then
    echo "📦 Detectado sistema Ubuntu/Debian"
    apt-get update
    apt-get install -y php php-cli php-mysql php-json php-mbstring
elif command -v yum &> /dev/null; then
    echo "📦 Detectado sistema CentOS/RHEL"
    yum install -y php php-cli php-mysql php-json php-mbstring
elif command -v apk &> /dev/null; then
    echo "📦 Detectado sistema Alpine"
    apk add --no-cache php php-cli php-mysql php-json php-mbstring
else
    echo "⚠️ Sistema no reconocido, intentando con apt..."
    apt-get update && apt-get install -y php php-cli php-mysql php-json php-mbstring
fi

# Verificar instalación
if command -v php &> /dev/null; then
    echo "✅ PHP instalado correctamente: $(php --version | head -n1)"
    echo "🌐 Iniciando servidor en puerto $PORT..."
    php -S 0.0.0.0:$PORT server.php
else
    echo "❌ Error: PHP no se pudo instalar"
    exit 1
fi
