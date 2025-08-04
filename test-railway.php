<?php
/**
 * PRUEBA DE CONEXIÓN A RAILWAY
 * Archivo para verificar la conexión a la base de datos Railway
 */

// Configuración de Railway
$host = 'switchback.proxy.rlwy.net';
$port = 31739;
$dbname = 'railway';
$username = 'root';
$password = 'DcFHhdYINqDJuvHxKZOeOLcbsIGf';

echo "<h1>🚀 Prueba de Conexión a Railway</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .success { color: green; background: #f0fff0; padding: 10px; border: 1px solid green; }
    .error { color: red; background: #fff0f0; padding: 10px; border: 1px solid red; }
    .info { color: blue; background: #f0f8ff; padding: 10px; border: 1px solid blue; }
</style>";

try {
    // Crear conexión PDO
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
    
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false
    ];
    
    echo "<div class='info'>📡 Intentando conectar a Railway...</div>";
    echo "<div class='info'>🔗 Host: {$host}:{$port}</div>";
    echo "<div class='info'>🗄️ Base de datos: {$dbname}</div>";
    
    $pdo = new PDO($dsn, $username, $password, $options);
    
    echo "<div class='success'>✅ CONEXIÓN EXITOSA A RAILWAY</div>";
    
    // Verificar versión de MySQL
    $version = $pdo->query("SELECT VERSION() as version")->fetch();
    echo "<div class='info'>📊 Versión MySQL: {$version['version']}</div>";
    
    // Verificar charset
    $charset = $pdo->query("SELECT @@character_set_database as charset")->fetch();
    echo "<div class='info'>🔤 Charset: {$charset['charset']}</div>";
    
    // Mostrar tablas existentes
    echo "<h2>📋 Tablas en la Base de Datos</h2>";
    $tables = $pdo->query("SHOW TABLES")->fetchAll();
    
    if (empty($tables)) {
        echo "<div class='error'>⚠️ No hay tablas en la base de datos. Ejecutar railway_setup.sql</div>";
    } else {
        echo "<div class='success'>📚 Tablas encontradas:</div>";
        echo "<ul>";
        foreach ($tables as $table) {
            $tableName = $table[array_keys($table)[0]];
            echo "<li>{$tableName}</li>";
        }
        echo "</ul>";
        
        // Verificar datos en tablas principales
        echo "<h2>📊 Contenido de Tablas</h2>";
        
        $importantTables = ['usuarios', 'empleados', 'categorias', 'productos', 'proveedores'];
        
        foreach ($importantTables as $tableName) {
            try {
                $count = $pdo->query("SELECT COUNT(*) as total FROM {$tableName}")->fetch();
                echo "<div class='info'>📋 {$tableName}: {$count['total']} registros</div>";
                
                if ($count['total'] > 0 && in_array($tableName, ['usuarios', 'productos'])) {
                    echo "<div style='margin-left: 20px;'>";
                    if ($tableName === 'usuarios') {
                        $users = $pdo->query("SELECT nombre_usuario, email, tipo_usuario FROM usuarios LIMIT 3")->fetchAll();
                        foreach ($users as $user) {
                            echo "👤 {$user['nombre_usuario']} ({$user['tipo_usuario']}) - {$user['email']}<br>";
                        }
                    } elseif ($tableName === 'productos') {
                        $products = $pdo->query("SELECT nombre, precio_venta, stock_actual FROM productos LIMIT 3")->fetchAll();
                        foreach ($products as $product) {
                            echo "📦 {$product['nombre']} - \${$product['precio_venta']} (Stock: {$product['stock_actual']})<br>";
                        }
                    }
                    echo "</div>";
                }
            } catch (Exception $e) {
                echo "<div class='error'>❌ Error en tabla {$tableName}: Tabla no existe</div>";
            }
        }
    }
    
    // Probar inserción de datos de prueba
    echo "<h2>🧪 Prueba de Operaciones</h2>";
    
    try {
        $pdo->beginTransaction();
        
        // Probar inserción en tabla de prueba
        $pdo->exec("CREATE TEMPORARY TABLE test_connection (id INT AUTO_INCREMENT PRIMARY KEY, mensaje VARCHAR(100), fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
        $pdo->exec("INSERT INTO test_connection (mensaje) VALUES ('Conexión Railway funcionando')");
        
        $result = $pdo->query("SELECT * FROM test_connection")->fetch();
        echo "<div class='success'>✅ Operación INSERT: {$result['mensaje']} - {$result['fecha']}</div>";
        
        $pdo->rollback(); // No hacer commit de la tabla temporal
        
    } catch (Exception $e) {
        echo "<div class='error'>❌ Error en operación: {$e->getMessage()}</div>";
        $pdo->rollback();
    }
    
    echo "<div class='success'>🎉 RAILWAY ESTÁ LISTO PARA USAR</div>";
    echo "<div class='info'>🔗 Puedes usar esta configuración en tu aplicación</div>";
    
} catch (PDOException $e) {
    echo "<div class='error'>❌ ERROR DE CONEXIÓN</div>";
    echo "<div class='error'>📝 Mensaje: {$e->getMessage()}</div>";
    echo "<div class='error'>💡 Verificar credenciales y conexión a internet</div>";
} catch (Exception $e) {
    echo "<div class='error'>❌ ERROR GENERAL: {$e->getMessage()}</div>";
}

// Información de configuración para referencia
echo "<h2>⚙️ Configuración Actual</h2>";
echo "<div class='info'>";
echo "<strong>Configuración Railway:</strong><br>";
echo "Host: {$host}<br>";
echo "Puerto: {$port}<br>";
echo "Base de datos: {$dbname}<br>";
echo "Usuario: {$username}<br>";
echo "URL conexión: mysql://{$username}:***@{$host}:{$port}/{$dbname}";
echo "</div>";

echo "<h2>📝 Próximos Pasos</h2>";
echo "<div class='info'>";
echo "1. Si no hay tablas, ejecutar <strong>railway_setup.sql</strong> en Railway<br>";
echo "2. Verificar que el archivo <strong>.env</strong> tenga la configuración correcta<br>";
echo "3. Abrir <strong>index.html</strong> para usar el sistema<br>";
echo "4. Login con: <strong>admin / admin123</strong>";
echo "</div>";
?>
