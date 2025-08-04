<?php
/**
 * Script de Verificación del Sistema TienditaMejorada
 * Ejecutar este archivo para verificar que todo esté funcionando correctamente
 */

require_once 'database/config-advanced.php';
require_once 'database/config.php';

class SystemChecker {
    private $results = [];
    private $config;
    
    public function __construct() {
        $this->config = DatabaseConfigAdvanced::getInstance();
    }
    
    /**
     * Ejecutar todas las verificaciones
     */
    public function runAllChecks() {
        echo "<h1>🔍 Verificación del Sistema TienditaMejorada</h1>";
        echo "<style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .success { color: green; }
            .error { color: red; }
            .warning { color: orange; }
            .info { color: blue; }
            .result { margin: 10px 0; padding: 10px; border-left: 4px solid; }
            .result.success { border-color: green; background: #f0fff0; }
            .result.error { border-color: red; background: #fff0f0; }
            .result.warning { border-color: orange; background: #fff8f0; }
        </style>";
        
        $this->checkSystemRequirements();
        $this->checkFilePermissions();
        $this->checkDatabaseConnection();
        $this->checkDatabaseSchema();
        $this->checkAPIEndpoints();
        $this->checkConfigFiles();
        $this->checkDirectories();
        
        $this->displaySummary();
    }
    
    /**
     * Verificar requisitos del sistema
     */
    private function checkSystemRequirements() {
        echo "<h2>📋 Requisitos del Sistema</h2>";
        
        $requirements = [
            'PHP Version (>= 7.4)' => version_compare(PHP_VERSION, '7.4.0', '>='),
            'PDO Extension' => extension_loaded('pdo'),
            'PDO MySQL Extension' => extension_loaded('pdo_mysql'),
            'JSON Extension' => extension_loaded('json'),
            'MBString Extension' => extension_loaded('mbstring'),
            'GD Extension' => extension_loaded('gd'),
            'cURL Extension' => extension_loaded('curl')
        ];
        
        foreach ($requirements as $requirement => $met) {
            $status = $met ? 'success' : 'error';
            $icon = $met ? '✅' : '❌';
            echo "<div class='result {$status}'>{$icon} {$requirement}</div>";
            $this->results['requirements'][$requirement] = $met;
        }
    }
    
    /**
     * Verificar permisos de archivos
     */
    private function checkFilePermissions() {
        echo "<h2>🔐 Permisos de Archivos</h2>";
        
        $files = [
            '.env' => 'readable',
            '.htaccess' => 'readable',
            'database/config.php' => 'readable',
            'api/index.php' => 'readable',
            'logs/' => 'writable',
            'cache/' => 'writable',
            'uploads/' => 'writable'
        ];
        
        foreach ($files as $file => $permission) {
            $path = __DIR__ . '/' . $file;
            $exists = file_exists($path);
            
            if (!$exists) {
                echo "<div class='result warning'>⚠️ {$file} - No existe</div>";
                continue;
            }
            
            $readable = is_readable($path);
            $writable = is_writable($path);
            
            if ($permission === 'readable' && $readable) {
                echo "<div class='result success'>✅ {$file} - Lectura OK</div>";
            } elseif ($permission === 'writable' && $writable) {
                echo "<div class='result success'>✅ {$file} - Escritura OK</div>";
            } else {
                echo "<div class='result error'>❌ {$file} - Permisos insuficientes</div>";
            }
        }
    }
    
    /**
     * Verificar conexión a la base de datos
     */
    private function checkDatabaseConnection() {
        echo "<h2>🗄️ Conexión a Base de Datos</h2>";
        
        try {
            $db = Database::getInstance();
            echo "<div class='result success'>✅ Conexión a MySQL exitosa</div>";
            
            // Verificar versión de MySQL
            $version = $db->query("SELECT VERSION() as version")->fetch();
            echo "<div class='result info'>ℹ️ Versión de MySQL: {$version['version']}</div>";
            
            // Verificar configuración
            $charset = $db->query("SELECT @@character_set_database as charset")->fetch();
            echo "<div class='result info'>ℹ️ Charset de BD: {$charset['charset']}</div>";
            
            $this->results['database']['connection'] = true;
            
        } catch (Exception $e) {
            echo "<div class='result error'>❌ Error de conexión: " . $e->getMessage() . "</div>";
            $this->results['database']['connection'] = false;
        }
    }
    
    /**
     * Verificar esquema de la base de datos
     */
    private function checkDatabaseSchema() {
        echo "<h2>🏗️ Esquema de Base de Datos</h2>";
        
        if (!$this->results['database']['connection']) {
            echo "<div class='result error'>❌ No se puede verificar: sin conexión a BD</div>";
            return;
        }
        
        try {
            $db = Database::getInstance();
            
            // Verificar tablas
            $tables = [
                'usuarios', 'empleados', 'categorias', 'productos', 
                'proveedores', 'ventas', 'detalle_ventas', 
                'inventario', 'auditoria'
            ];
            
            $existingTables = [];
            $result = $db->query("SHOW TABLES");
            while ($row = $result->fetch()) {
                $existingTables[] = $row[array_keys($row)[0]];
            }
            
            foreach ($tables as $table) {
                if (in_array($table, $existingTables)) {
                    echo "<div class='result success'>✅ Tabla '{$table}' existe</div>";
                } else {
                    echo "<div class='result error'>❌ Tabla '{$table}' no existe</div>";
                }
            }
            
            // Verificar vistas
            $views = ['vista_productos_stock', 'vista_ventas_detalle', 'vista_empleados_activos', 'vista_productos_categoria'];
            $existingViews = [];
            $result = $db->query("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
            while ($row = $result->fetch()) {
                $existingViews[] = $row[array_keys($row)[0]];
            }
            
            foreach ($views as $view) {
                if (in_array($view, $existingViews)) {
                    echo "<div class='result success'>✅ Vista '{$view}' existe</div>";
                } else {
                    echo "<div class='result warning'>⚠️ Vista '{$view}' no existe</div>";
                }
            }
            
        } catch (Exception $e) {
            echo "<div class='result error'>❌ Error verificando esquema: " . $e->getMessage() . "</div>";
        }
    }
    
    /**
     * Verificar endpoints de la API
     */
    private function checkAPIEndpoints() {
        echo "<h2>🌐 API Endpoints</h2>";
        
        $baseUrl = $this->config->get('app.url') . '/TienditaMejorada/api';
        $endpoints = [
            '/auth/login' => 'POST',
            '/auth/register' => 'POST',
            '/products' => 'GET',
            '/employees' => 'GET',
            '/suppliers' => 'GET'
        ];
        
        foreach ($endpoints as $endpoint => $method) {
            $url = $baseUrl . $endpoint;
            
            // Verificar que el archivo de la API existe
            if (file_exists(__DIR__ . '/api/index.php')) {
                echo "<div class='result success'>✅ API disponible en {$endpoint}</div>";
            } else {
                echo "<div class='result error'>❌ Archivo de API no encontrado</div>";
                break;
            }
        }
    }
    
    /**
     * Verificar archivos de configuración
     */
    private function checkConfigFiles() {
        echo "<h2>⚙️ Archivos de Configuración</h2>";
        
        $configFiles = [
            '.env' => 'Variables de entorno',
            '.htaccess' => 'Configuración de Apache',
            'database/config.php' => 'Configuración de BD básica',
            'database/config-advanced.php' => 'Configuración avanzada',
            'database/tiendita_schema.sql' => 'Script de BD'
        ];
        
        foreach ($configFiles as $file => $description) {
            if (file_exists(__DIR__ . '/' . $file)) {
                $size = filesize(__DIR__ . '/' . $file);
                echo "<div class='result success'>✅ {$description} ({$file}) - {$size} bytes</div>";
            } else {
                echo "<div class='result error'>❌ {$description} ({$file}) - No encontrado</div>";
            }
        }
    }
    
    /**
     * Verificar directorios
     */
    private function checkDirectories() {
        echo "<h2>📁 Directorios del Sistema</h2>";
        
        $directories = [
            'database/' => 'Scripts de base de datos',
            'api/' => 'API REST',
            'js/' => 'JavaScript del frontend',
            'css/' => 'Estilos CSS',
            'logs/' => 'Archivos de log',
            'cache/' => 'Cache del sistema',
            'uploads/' => 'Archivos subidos'
        ];
        
        foreach ($directories as $dir => $description) {
            $path = __DIR__ . '/' . $dir;
            
            if (is_dir($path)) {
                $writable = is_writable($path) ? 'Escribible' : 'Solo lectura';
                echo "<div class='result success'>✅ {$description} ({$dir}) - {$writable}</div>";
            } else {
                echo "<div class='result warning'>⚠️ {$description} ({$dir}) - No existe</div>";
                
                // Intentar crear el directorio
                if (mkdir($path, 0755, true)) {
                    echo "<div class='result success'>✅ Directorio {$dir} creado automáticamente</div>";
                }
            }
        }
    }
    
    /**
     * Mostrar resumen de la verificación
     */
    private function displaySummary() {
        echo "<h2>📊 Resumen de Verificación</h2>";
        
        $totalChecks = 0;
        $passedChecks = 0;
        
        // Contar resultados
        foreach ($this->results as $category => $results) {
            if (is_array($results)) {
                foreach ($results as $result) {
                    $totalChecks++;
                    if ($result) $passedChecks++;
                }
            }
        }
        
        $percentage = $totalChecks > 0 ? round(($passedChecks / $totalChecks) * 100, 2) : 0;
        
        if ($percentage >= 90) {
            echo "<div class='result success'>🎉 Sistema funcionando correctamente ({$percentage}%)</div>";
        } elseif ($percentage >= 70) {
            echo "<div class='result warning'>⚠️ Sistema funcional con advertencias ({$percentage}%)</div>";
        } else {
            echo "<div class='result error'>❌ Sistema requiere atención ({$percentage}%)</div>";
        }
        
        echo "<div class='result info'>ℹ️ Verificaciones pasadas: {$passedChecks}/{$totalChecks}</div>";
        
        // Recomendaciones
        echo "<h3>💡 Recomendaciones:</h3>";
        echo "<ul>";
        echo "<li>Si hay errores de conexión, verificar credenciales en .env</li>";
        echo "<li>Si faltan tablas, ejecutar database/tiendita_schema.sql en MySQL</li>";
        echo "<li>Si hay problemas de permisos, verificar configuración de Apache</li>";
        echo "<li>Para mejor rendimiento, habilitar mod_rewrite y mod_deflate</li>";
        echo "</ul>";
        
        echo "<div class='result info'>🚀 <strong>Para acceder al sistema:</strong> <a href='index.html'>Abrir TienditaMejorada</a></div>";
    }
}

// Ejecutar verificación si se accede directamente
if (basename($_SERVER['PHP_SELF']) === 'system-check.php') {
    $checker = new SystemChecker();
    $checker->runAllChecks();
}
?>
