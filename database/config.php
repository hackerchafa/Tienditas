<?php
/**
 * Configuración de Base de Datos - TienditaMejorada
 * Archivo de conexión y configuración para MySQL
 */

class DatabaseConfig {
    
    // Configuración de conexión - Usar variables de entorno
    // Para desarrollo local usar .env, para producción usar variables de Render
    private const DB_HOST = null; // Se obtiene de variables de entorno
    private const DB_NAME = null; // Se obtiene de variables de entorno  
    private const DB_USER = null; // Se obtiene de variables de entorno
    private const DB_PASS = null; // Se obtiene de variables de entorno
    private const DB_PORT = null; // Se obtiene de variables de entorno
    private const DB_CHARSET = 'utf8mb4';
    
    private static $instance = null;
    private $connection = null;
    
    private function __construct() {
        $this->connect();
    }
    
    /**
     * Singleton para obtener la instancia de la base de datos
     */
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Establecer conexión con la base de datos
     */
    private function connect() {
        try {
            // Obtener configuración de variables de entorno o .env
            $host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?? 'switchback.proxy.rlwy.net';
            $port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?? '31739';
            $dbname = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?? 'railway';
            $username = $_ENV['DB_USER'] ?? getenv('DB_USER') ?? 'root';
            $password = $_ENV['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?? 'DcFHhdYINqDJuvHxKZOeOLcbsIGf';
            
            $dsn = "mysql:host=" . $host . 
                   ";port=" . $port . 
                   ";dbname=" . $dbname . 
                   ";charset=" . self::DB_CHARSET;
            
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES " . self::DB_CHARSET
            ];
            
            $this->connection = new PDO($dsn, $username, $password, $options);
            
        } catch (PDOException $e) {
            error_log("Error de conexión a la base de datos: " . $e->getMessage());
            throw new Exception("Error de conexión a la base de datos");
        }
    }
    
    /**
     * Obtener la conexión PDO
     */
    public function getConnection() {
        return $this->connection;
    }
    
    /**
     * Ejecutar consulta SELECT
     */
    public function select($query, $params = []) {
        try {
            $stmt = $this->connection->prepare($query);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Error en SELECT: " . $e->getMessage());
            throw new Exception("Error al ejecutar consulta SELECT");
        }
    }
    
    /**
     * Ejecutar consulta INSERT
     */
    public function insert($query, $params = []) {
        try {
            $stmt = $this->connection->prepare($query);
            $result = $stmt->execute($params);
            return $this->connection->lastInsertId();
        } catch (PDOException $e) {
            error_log("Error en INSERT: " . $e->getMessage());
            throw new Exception("Error al ejecutar consulta INSERT");
        }
    }
    
    /**
     * Ejecutar consulta UPDATE
     */
    public function update($query, $params = []) {
        try {
            $stmt = $this->connection->prepare($query);
            $stmt->execute($params);
            return $stmt->rowCount();
        } catch (PDOException $e) {
            error_log("Error en UPDATE: " . $e->getMessage());
            throw new Exception("Error al ejecutar consulta UPDATE");
        }
    }
    
    /**
     * Ejecutar consulta DELETE
     */
    public function delete($query, $params = []) {
        try {
            $stmt = $this->connection->prepare($query);
            $stmt->execute($params);
            return $stmt->rowCount();
        } catch (PDOException $e) {
            error_log("Error en DELETE: " . $e->getMessage());
            throw new Exception("Error al ejecutar consulta DELETE");
        }
    }
    
    /**
     * Ejecutar procedimiento almacenado
     */
    public function callProcedure($procedure, $params = []) {
        try {
            $placeholders = str_repeat('?,', count($params) - 1) . '?';
            $stmt = $this->connection->prepare("CALL $procedure($placeholders)");
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Error en PROCEDURE: " . $e->getMessage());
            throw new Exception("Error al ejecutar procedimiento almacenado");
        }
    }
    
    /**
     * Iniciar transacción
     */
    public function beginTransaction() {
        return $this->connection->beginTransaction();
    }
    
    /**
     * Confirmar transacción
     */
    public function commit() {
        return $this->connection->commit();
    }
    
    /**
     * Revertir transacción
     */
    public function rollback() {
        return $this->connection->rollback();
    }
    
    /**
     * Cerrar conexión
     */
    public function close() {
        $this->connection = null;
    }
    
    /**
     * Verificar si la tabla existe
     */
    public function tableExists($tableName) {
        try {
            $query = "SHOW TABLES LIKE ?";
            $stmt = $this->connection->prepare($query);
            $stmt->execute([$tableName]);
            return $stmt->rowCount() > 0;
        } catch (PDOException $e) {
            return false;
        }
    }
    
    /**
     * Obtener información de la base de datos
     */
    public function getDatabaseInfo() {
        try {
            $info = [
                'server_version' => $this->connection->getAttribute(PDO::ATTR_SERVER_VERSION),
                'client_version' => $this->connection->getAttribute(PDO::ATTR_CLIENT_VERSION),
                'connection_status' => $this->connection->getAttribute(PDO::ATTR_CONNECTION_STATUS),
                'server_info' => $this->connection->getAttribute(PDO::ATTR_SERVER_INFO)
            ];
            return $info;
        } catch (PDOException $e) {
            return null;
        }
    }
}

/**
 * Clase de utilidades para la base de datos
 */
class DatabaseUtils {
    
    /**
     * Validar conexión a la base de datos
     */
    public static function testConnection() {
        try {
            $db = DatabaseConfig::getInstance();
            $result = $db->select("SELECT 1 as test");
            return !empty($result);
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * Obtener estadísticas de la tienda
     */
    public static function getTiendaStats($tienda_id) {
        try {
            $db = DatabaseConfig::getInstance();
            
            $stats = [
                'total_productos' => 0,
                'productos_stock_bajo' => 0,
                'ventas_hoy' => 0,
                'total_ventas_hoy' => 0,
                'empleados_activos' => 0
            ];
            
            // Total de productos
            $result = $db->select(
                "SELECT COUNT(*) as total FROM productos WHERE tienda_id = ? AND estado = 'activo'",
                [$tienda_id]
            );
            $stats['total_productos'] = $result[0]['total'] ?? 0;
            
            // Productos con stock bajo
            $result = $db->select(
                "SELECT COUNT(*) as total FROM productos 
                 WHERE tienda_id = ? AND stock_actual <= stock_minimo AND estado = 'activo'",
                [$tienda_id]
            );
            $stats['productos_stock_bajo'] = $result[0]['total'] ?? 0;
            
            // Ventas de hoy
            $result = $db->select(
                "SELECT COUNT(*) as total, COALESCE(SUM(total_final), 0) as monto 
                 FROM ventas 
                 WHERE tienda_id = ? AND DATE(fecha_venta) = CURDATE() AND estado = 'completada'",
                [$tienda_id]
            );
            $stats['ventas_hoy'] = $result[0]['total'] ?? 0;
            $stats['total_ventas_hoy'] = $result[0]['monto'] ?? 0;
            
            // Empleados activos
            $result = $db->select(
                "SELECT COUNT(*) as total FROM usuarios 
                 WHERE tienda_id = ? AND rol = 'empleado' AND estado = 'activo'",
                [$tienda_id]
            );
            $stats['empleados_activos'] = $result[0]['total'] ?? 0;
            
            return $stats;
            
        } catch (Exception $e) {
            error_log("Error obteniendo estadísticas: " . $e->getMessage());
            return null;
        }
    }
    
    /**
     * Formatear precio para mostrar
     */
    public static function formatPrice($price) {
        return '$' . number_format($price, 2);
    }
    
    /**
     * Validar datos de entrada
     */
    public static function sanitizeInput($data) {
        if (is_array($data)) {
            return array_map([self::class, 'sanitizeInput'], $data);
        }
        return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
    }
    
    /**
     * Generar hash de contraseña
     */
    public static function hashPassword($password) {
        return password_hash($password, PASSWORD_DEFAULT);
    }
    
    /**
     * Verificar contraseña
     */
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
    
    /**
     * Generar token de sesión
     */
    public static function generateSessionToken() {
        return bin2hex(random_bytes(32));
    }
    
    /**
     * Validar email
     */
    public static function validateEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
    
    /**
     * Registrar actividad del usuario
     */
    public static function logUserActivity($usuario_id, $actividad, $ip = null) {
        try {
            $db = DatabaseConfig::getInstance();
            
            // Aquí podrías crear una tabla de logs si es necesaria
            error_log("Usuario $usuario_id: $actividad desde IP " . ($ip ?? 'desconocida'));
            
        } catch (Exception $e) {
            error_log("Error registrando actividad: " . $e->getMessage());
        }
    }
}

// Función de conveniencia para obtener la instancia de la base de datos
function getDB() {
    return DatabaseConfig::getInstance();
}

// Auto-configurar zona horaria
date_default_timezone_set('America/Mexico_City');

// Configurar manejo de errores
error_reporting(E_ALL);
ini_set('display_errors', 0); // En producción debe ser 0
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/logs/php_errors.log');

?>
