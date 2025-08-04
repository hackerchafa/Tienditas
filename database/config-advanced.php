<?php
/**
 * Configuración Avanzada de la Base de Datos
 * Sistema TienditaMejorada - Configuración extendida con variables de entorno
 */

class DatabaseConfigAdvanced {
    private static $instance = null;
    private $config = [];
    
    private function __construct() {
        $this->loadEnvironmentConfig();
        $this->setDefaultConfig();
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Cargar configuración desde archivo .env
     */
    private function loadEnvironmentConfig() {
        $envFile = dirname(__DIR__) . '/.env';
        if (file_exists($envFile)) {
            $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                if (strpos($line, '=') !== false && substr($line, 0, 1) !== '#') {
                    list($key, $value) = explode('=', $line, 2);
                    $_ENV[trim($key)] = trim($value);
                }
            }
        }
    }
    
    /**
     * Configuración por defecto del sistema
     */
    private function setDefaultConfig() {
        $this->config = [
            // Configuración de Base de Datos
            'database' => [
                'host' => $_ENV['DB_HOST'] ?? 'localhost',
                'port' => $_ENV['DB_PORT'] ?? 3306,
                'dbname' => $_ENV['DB_NAME'] ?? 'tiendita_mejorada',
                'username' => $_ENV['DB_USER'] ?? 'root',
                'password' => $_ENV['DB_PASSWORD'] ?? '',
                'charset' => 'utf8mb4',
                'collation' => 'utf8mb4_unicode_ci',
                'options' => [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
                ]
            ],
            
            // Configuración de la Aplicación
            'app' => [
                'name' => $_ENV['APP_NAME'] ?? 'TienditaMejorada',
                'env' => $_ENV['APP_ENV'] ?? 'development',
                'debug' => filter_var($_ENV['APP_DEBUG'] ?? true, FILTER_VALIDATE_BOOLEAN),
                'url' => $_ENV['APP_URL'] ?? 'http://localhost',
                'timezone' => 'America/Mexico_City'
            ],
            
            // Configuración de Seguridad
            'security' => [
                'jwt_secret' => $_ENV['JWT_SECRET'] ?? 'default_secret_change_in_production',
                'encryption_key' => $_ENV['ENCRYPTION_KEY'] ?? 'default_encryption_key',
                'session_lifetime' => 7200, // 2 horas
                'max_login_attempts' => 5,
                'lockout_duration' => 900 // 15 minutos
            ],
            
            // Configuración de Cache
            'cache' => [
                'driver' => $_ENV['CACHE_DRIVER'] ?? 'file',
                'ttl' => intval($_ENV['CACHE_TTL'] ?? 3600),
                'path' => dirname(__DIR__) . '/cache'
            ],
            
            // Configuración de Logs
            'logging' => [
                'level' => $_ENV['LOG_LEVEL'] ?? 'debug',
                'file' => $_ENV['LOG_FILE'] ?? 'logs/app.log',
                'max_size' => 10485760, // 10MB
                'max_files' => 5
            ],
            
            // Configuración de Archivos
            'uploads' => [
                'max_size' => intval($_ENV['UPLOAD_MAX_SIZE'] ?? 10485760),
                'allowed_extensions' => explode(',', $_ENV['ALLOWED_EXTENSIONS'] ?? 'jpg,jpeg,png,gif,pdf'),
                'path' => dirname(__DIR__) . '/uploads'
            ],
            
            // Configuración de API
            'api' => [
                'rate_limit' => intval($_ENV['API_RATE_LIMIT'] ?? 1000),
                'timeout' => intval($_ENV['API_TIMEOUT'] ?? 30),
                'version' => 'v1'
            ]
        ];
    }
    
    /**
     * Obtener configuración por clave
     */
    public function get($key, $default = null) {
        $keys = explode('.', $key);
        $value = $this->config;
        
        foreach ($keys as $k) {
            if (is_array($value) && isset($value[$k])) {
                $value = $value[$k];
            } else {
                return $default;
            }
        }
        
        return $value;
    }
    
    /**
     * Obtener DSN para conexión PDO
     */
    public function getDSN() {
        $host = $this->get('database.host');
        $port = $this->get('database.port');
        $dbname = $this->get('database.dbname');
        $charset = $this->get('database.charset');
        
        return "mysql:host={$host};port={$port};dbname={$dbname};charset={$charset}";
    }
    
    /**
     * Validar configuración de la base de datos
     */
    public function validateDatabaseConfig() {
        $required = ['host', 'dbname', 'username'];
        foreach ($required as $key) {
            if (empty($this->get("database.{$key}"))) {
                throw new Exception("Configuración de base de datos incompleta: {$key} es requerido");
            }
        }
        return true;
    }
    
    /**
     * Crear directorios necesarios
     */
    public function createDirectories() {
        $directories = [
            $this->get('cache.path'),
            dirname($this->get('logging.file')),
            $this->get('uploads.path')
        ];
        
        foreach ($directories as $dir) {
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
        }
    }
    
    /**
     * Verificar requisitos del sistema
     */
    public function checkSystemRequirements() {
        $requirements = [
            'PHP' => version_compare(PHP_VERSION, '7.4.0', '>='),
            'PDO' => extension_loaded('pdo'),
            'PDO MySQL' => extension_loaded('pdo_mysql'),
            'JSON' => extension_loaded('json'),
            'MBString' => extension_loaded('mbstring')
        ];
        
        $failed = [];
        foreach ($requirements as $requirement => $met) {
            if (!$met) {
                $failed[] = $requirement;
            }
        }
        
        if (!empty($failed)) {
            throw new Exception('Requisitos del sistema no cumplidos: ' . implode(', ', $failed));
        }
        
        return true;
    }
    
    /**
     * Obtener configuración completa
     */
    public function getAll() {
        return $this->config;
    }
    
    /**
     * Establecer configuración
     */
    public function set($key, $value) {
        $keys = explode('.', $key);
        $config = &$this->config;
        
        foreach ($keys as $k) {
            $config = &$config[$k];
        }
        
        $config = $value;
    }
    
    /**
     * Verificar si estamos en modo debug
     */
    public function isDebug() {
        return $this->get('app.debug', false);
    }
    
    /**
     * Verificar si estamos en producción
     */
    public function isProduction() {
        return $this->get('app.env') === 'production';
    }
}

// Función helper para obtener configuración
function config($key, $default = null) {
    return DatabaseConfigAdvanced::getInstance()->get($key, $default);
}

// Inicializar configuración
try {
    $config = DatabaseConfigAdvanced::getInstance();
    $config->checkSystemRequirements();
    $config->validateDatabaseConfig();
    $config->createDirectories();
    
    // Configurar zona horaria
    date_default_timezone_set($config->get('app.timezone'));
    
    // Configurar manejo de errores en desarrollo
    if ($config->isDebug()) {
        error_reporting(E_ALL);
        ini_set('display_errors', 1);
    } else {
        error_reporting(0);
        ini_set('display_errors', 0);
    }
    
} catch (Exception $e) {
    if (php_sapi_name() === 'cli') {
        echo "Error de configuración: " . $e->getMessage() . PHP_EOL;
    } else {
        header('HTTP/1.1 500 Internal Server Error');
        echo json_encode([
            'error' => true,
            'message' => 'Error de configuración del sistema'
        ]);
    }
    exit(1);
}
?>
