<?php
/**
 * Script de diagnóstico para verificar la conexión a Railway
 */

// Mostrar errores
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>🔍 Diagnóstico de TienditaMejorada</h1>";

// 1. Verificar variables de entorno
echo "<h2>📊 Variables de Entorno:</h2>";
$vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
foreach ($vars as $var) {
    $value = $_ENV[$var] ?? getenv($var) ?? 'NO DEFINIDA';
    if ($var === 'DB_PASSWORD') {
        $value = $value !== 'NO DEFINIDA' ? '****' . substr($value, -4) : 'NO DEFINIDA';
    }
    echo "<p><strong>$var:</strong> $value</p>";
}

// 2. Intentar conexión a la base de datos
echo "<h2>🔌 Prueba de Conexión:</h2>";
try {
    $host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?? 'switchback.proxy.rlwy.net';
    $port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?? '31739';
    $dbname = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?? 'railway';
    $username = $_ENV['DB_USER'] ?? getenv('DB_USER') ?? 'root';
    $password = $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?? 'DcFHhdYINqDJuvHxKZOeOLcbsIGf';
    
    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    
    echo "<p>📡 Intentando conectar a: $host:$port</p>";
    echo "<p>🗄️ Base de datos: $dbname</p>";
    echo "<p>👤 Usuario: $username</p>";
    
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    echo "<p style='color: green;'>✅ <strong>Conexión exitosa a Railway!</strong></p>";
    
    // 3. Verificar tablas
    echo "<h2>📋 Verificar Tablas:</h2>";
    $tables = $pdo->query("SHOW TABLES")->fetchAll();
    if (empty($tables)) {
        echo "<p style='color: red;'>❌ No hay tablas en la base de datos</p>";
    } else {
        echo "<p style='color: green;'>✅ Tablas encontradas:</p><ul>";
        foreach ($tables as $table) {
            echo "<li>" . array_values($table)[0] . "</li>";
        }
        echo "</ul>";
    }
    
    // 4. Verificar estructura de usuarios
    try {
        $columns = $pdo->query("DESCRIBE usuarios")->fetchAll();
        echo "<h3>👥 Estructura tabla usuarios:</h3><ul>";
        foreach ($columns as $col) {
            echo "<li><strong>{$col['Field']}</strong>: {$col['Type']}</li>";
        }
        echo "</ul>";
    } catch (Exception $e) {
        echo "<p style='color: red;'>❌ Error al verificar tabla usuarios: " . $e->getMessage() . "</p>";
    }
    
} catch (PDOException $e) {
    echo "<p style='color: red;'>❌ <strong>Error de conexión:</strong> " . $e->getMessage() . "</p>";
    echo "<p>🔧 <strong>Código de error:</strong> " . $e->getCode() . "</p>";
}

// 5. Información del servidor
echo "<h2>🖥️ Información del Servidor:</h2>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>Servidor:</strong> " . ($_SERVER['SERVER_SOFTWARE'] ?? 'No detectado') . "</p>";
echo "<p><strong>Puerto:</strong> " . ($_SERVER['SERVER_PORT'] ?? 'No detectado') . "</p>";
echo "<p><strong>Host:</strong> " . ($_SERVER['HTTP_HOST'] ?? 'No detectado') . "</p>";

?>
