#!/bin/bash
# Script de inicio para Render
# Este archivo fuerza el uso del entorno PHP

echo "🚀 Iniciando TienditaMejorada en PHP..."
echo "📂 Directorio actual: $(pwd)"
echo "📋 Archivos disponibles:"
ls -la

# Verificar si PHP está disponible
if command -v php &> /dev/null; then
    echo "✅ PHP encontrado: $(php --version | head -n1)"
    echo "🌐 Iniciando servidor PHP en puerto $PORT..."
    php -S 0.0.0.0:$PORT server.php
else
    echo "❌ PHP no encontrado"
    echo "🔍 Buscando alternativas..."
    
    # Intentar con php8.1
    if command -v php8.1 &> /dev/null; then
        echo "✅ PHP 8.1 encontrado"
        php8.1 -S 0.0.0.0:$PORT server.php
    # Intentar con php8.0
    elif command -v php8.0 &> /dev/null; then
        echo "✅ PHP 8.0 encontrado"
        php8.0 -S 0.0.0.0:$PORT server.php
    # Intentar con php7.4
    elif command -v php7.4 &> /dev/null; then
        echo "✅ PHP 7.4 encontrado"
        php7.4 -S 0.0.0.0:$PORT server.php
    else
        echo "💡 Instalando PHP..."
        # Para Ubuntu/Debian en Render
        apt-get update && apt-get install -y php
        php -S 0.0.0.0:$PORT server.php
    fi
fi
