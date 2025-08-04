<?php
/**
 * API REST para TienditaMejorada
 * Archivo principal de enrutamiento de la API
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Manejar preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../database/config.php';

/**
 * Clase principal de la API
 */
class TienditaAPI {
    
    private $db;
    private $request_method;
    private $endpoint;
    private $params;
    
    public function __construct() {
        $this->db = DatabaseConfig::getInstance();
        $this->request_method = $_SERVER['REQUEST_METHOD'];
        $this->parseRequest();
    }
    
    /**
     * Parsear la petición
     */
    private function parseRequest() {
        $request = $_SERVER['REQUEST_URI'];
        $path = parse_url($request, PHP_URL_PATH);
        $path = trim($path, '/');
        $path_parts = explode('/', $path);
        
        // Remover 'api' del path si existe
        if ($path_parts[0] === 'api') {
            array_shift($path_parts);
        }
        
        $this->endpoint = $path_parts[0] ?? '';
        $this->params = array_slice($path_parts, 1);
    }
    
    /**
     * Procesar la petición
     */
    public function processRequest() {
        try {
            switch ($this->endpoint) {
                case 'auth':
                    return $this->handleAuth();
                case 'products':
                case 'productos':
                    return $this->handleProducts();
                case 'employees':
                case 'empleados':
                    return $this->handleEmployees();
                case 'suppliers':
                case 'proveedores':
                    return $this->handleSuppliers();
                case 'sales':
                case 'ventas':
                    return $this->handleSales();
                case 'reports':
                case 'reportes':
                    return $this->handleReports();
                case 'inventory':
                case 'inventario':
                    return $this->handleInventory();
                case 'dashboard':
                    return $this->handleDashboard();
                default:
                    return $this->response(['error' => 'Endpoint no encontrado'], 404);
            }
        } catch (Exception $e) {
            error_log("Error en API: " . $e->getMessage());
            return $this->response(['error' => 'Error interno del servidor'], 500);
        }
    }
    
    /**
     * Manejo de autenticación
     */
    private function handleAuth() {
        switch ($this->request_method) {
            case 'POST':
                $input = $this->getInput();
                if (isset($this->params[0]) && $this->params[0] === 'login') {
                    return $this->login($input);
                } elseif (isset($this->params[0]) && $this->params[0] === 'register') {
                    return $this->register($input);
                }
                break;
            case 'DELETE':
                if (isset($this->params[0]) && $this->params[0] === 'logout') {
                    return $this->logout();
                }
                break;
        }
        return $this->response(['error' => 'Método no permitido'], 405);
    }
    
    /**
     * Login de usuario
     */
    private function login($input) {
        if (!isset($input['username']) || !isset($input['password'])) {
            return $this->response(['error' => 'Username y password son requeridos'], 400);
        }
        
        $query = "SELECT u.*, t.nombre as tienda_nombre 
                  FROM usuarios u 
                  JOIN tiendas t ON u.tienda_id = t.id 
                  WHERE u.username = ? AND u.estado = 'activo'";
        
        $user = $this->db->select($query, [$input['username']]);
        
        if (empty($user) || !DatabaseUtils::verifyPassword($input['password'], $user[0]['password_hash'])) {
            return $this->response(['error' => 'Credenciales inválidas'], 401);
        }
        
        $user_data = $user[0];
        
        // Generar token de sesión
        $token = DatabaseUtils::generateSessionToken();
        
        // Guardar sesión
        $this->db->insert(
            "INSERT INTO sesiones_usuario (usuario_id, token_sesion, ip_address, user_agent) VALUES (?, ?, ?, ?)",
            [$user_data['id'], $token, $_SERVER['REMOTE_ADDR'] ?? '', $_SERVER['HTTP_USER_AGENT'] ?? '']
        );
        
        // Preparar respuesta
        $response = [
            'success' => true,
            'user' => [
                'id' => $user_data['id'],
                'username' => $user_data['username'],
                'nombre_completo' => $user_data['nombre_completo'],
                'email' => $user_data['email'],
                'rol' => $user_data['rol'],
                'tienda_id' => $user_data['tienda_id'],
                'tienda_nombre' => $user_data['tienda_nombre']
            ],
            'token' => $token
        ];
        
        return $this->response($response);
    }
    
    /**
     * Registro de nuevo usuario (solo jefes)
     */
    private function register($input) {
        $required = ['username', 'password', 'nombre_completo', 'email', 'tienda_nombre'];
        foreach ($required as $field) {
            if (!isset($input[$field]) || empty($input[$field])) {
                return $this->response(['error' => "El campo $field es requerido"], 400);
            }
        }
        
        // Verificar si el username ya existe
        $existing = $this->db->select("SELECT id FROM usuarios WHERE username = ?", [$input['username']]);
        if (!empty($existing)) {
            return $this->response(['error' => 'El username ya existe'], 409);
        }
        
        try {
            $this->db->beginTransaction();
            
            // Crear tienda
            $tienda_id = $this->db->insert(
                "INSERT INTO tiendas (nombre, email) VALUES (?, ?)",
                [$input['tienda_nombre'], $input['email']]
            );
            
            // Crear usuario jefe
            $user_id = $this->db->insert(
                "INSERT INTO usuarios (tienda_id, username, password_hash, nombre_completo, email, rol) VALUES (?, ?, ?, ?, ?, 'jefe')",
                [
                    $tienda_id,
                    $input['username'],
                    DatabaseUtils::hashPassword($input['password']),
                    $input['nombre_completo'],
                    $input['email']
                ]
            );
            
            $this->db->commit();
            
            return $this->response([
                'success' => true,
                'message' => 'Usuario registrado exitosamente',
                'user_id' => $user_id,
                'tienda_id' => $tienda_id
            ]);
            
        } catch (Exception $e) {
            $this->db->rollback();
            error_log("Error en registro: " . $e->getMessage());
            return $this->response(['error' => 'Error al registrar usuario'], 500);
        }
    }
    
    /**
     * Manejo de productos
     */
    private function handleProducts() {
        $tienda_id = $this->getTiendaId();
        if (!$tienda_id) {
            return $this->response(['error' => 'No autorizado'], 401);
        }
        
        switch ($this->request_method) {
            case 'GET':
                if (isset($this->params[0])) {
                    return $this->getProduct($this->params[0], $tienda_id);
                }
                return $this->getProducts($tienda_id);
                
            case 'POST':
                $input = $this->getInput();
                return $this->createProduct($input, $tienda_id);
                
            case 'PUT':
                if (!isset($this->params[0])) {
                    return $this->response(['error' => 'ID de producto requerido'], 400);
                }
                $input = $this->getInput();
                return $this->updateProduct($this->params[0], $input, $tienda_id);
                
            case 'DELETE':
                if (!isset($this->params[0])) {
                    return $this->response(['error' => 'ID de producto requerido'], 400);
                }
                return $this->deleteProduct($this->params[0], $tienda_id);
        }
        
        return $this->response(['error' => 'Método no permitido'], 405);
    }
    
    /**
     * Obtener productos
     */
    private function getProducts($tienda_id) {
        $search = $_GET['search'] ?? '';
        $category = $_GET['category'] ?? '';
        $stock_filter = $_GET['stock_filter'] ?? '';
        
        $query = "SELECT p.*, c.nombre as categoria_nombre, pr.empresa as proveedor_nombre
                  FROM productos p
                  LEFT JOIN categorias c ON p.categoria_id = c.id
                  LEFT JOIN proveedores pr ON p.proveedor_id = pr.id
                  WHERE p.tienda_id = ? AND p.estado = 'activo'";
        
        $params = [$tienda_id];
        
        if ($search) {
            $query .= " AND (p.nombre LIKE ? OR p.codigo LIKE ? OR p.marca LIKE ?)";
            $search_param = "%$search%";
            $params[] = $search_param;
            $params[] = $search_param;
            $params[] = $search_param;
        }
        
        if ($category) {
            $query .= " AND c.nombre = ?";
            $params[] = $category;
        }
        
        if ($stock_filter === 'bajo') {
            $query .= " AND p.stock_actual <= p.stock_minimo";
        } elseif ($stock_filter === 'agotado') {
            $query .= " AND p.stock_actual = 0";
        }
        
        $query .= " ORDER BY p.nombre";
        
        $products = $this->db->select($query, $params);
        
        return $this->response(['products' => $products]);
    }
    
    /**
     * Crear producto
     */
    private function createProduct($input, $tienda_id) {
        $required = ['codigo', 'nombre', 'precio_compra', 'precio_venta', 'stock_actual'];
        foreach ($required as $field) {
            if (!isset($input[$field])) {
                return $this->response(['error' => "El campo $field es requerido"], 400);
            }
        }
        
        try {
            $product_id = $this->db->insert(
                "INSERT INTO productos (tienda_id, categoria_id, proveedor_id, codigo, nombre, descripcion, marca, precio_compra, precio_venta, stock_actual, stock_minimo) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                [
                    $tienda_id,
                    $input['categoria_id'] ?? null,
                    $input['proveedor_id'] ?? null,
                    $input['codigo'],
                    $input['nombre'],
                    $input['descripcion'] ?? null,
                    $input['marca'] ?? null,
                    $input['precio_compra'],
                    $input['precio_venta'],
                    $input['stock_actual'],
                    $input['stock_minimo'] ?? 0
                ]
            );
            
            return $this->response([
                'success' => true,
                'message' => 'Producto creado exitosamente',
                'product_id' => $product_id
            ]);
            
        } catch (Exception $e) {
            error_log("Error creando producto: " . $e->getMessage());
            return $this->response(['error' => 'Error al crear producto'], 500);
        }
    }
    
    /**
     * Manejo de empleados
     */
    private function handleEmployees() {
        $tienda_id = $this->getTiendaId();
        if (!$tienda_id) {
            return $this->response(['error' => 'No autorizado'], 401);
        }
        
        switch ($this->request_method) {
            case 'GET':
                return $this->getEmployees($tienda_id);
                
            case 'POST':
                $input = $this->getInput();
                return $this->createEmployee($input, $tienda_id);
                
            case 'PUT':
                if (!isset($this->params[0])) {
                    return $this->response(['error' => 'ID de empleado requerido'], 400);
                }
                $input = $this->getInput();
                return $this->updateEmployee($this->params[0], $input, $tienda_id);
        }
        
        return $this->response(['error' => 'Método no permitido'], 405);
    }
    
    /**
     * Obtener empleados
     */
    private function getEmployees($tienda_id) {
        $employees = $this->db->select(
            "SELECT id, username, nombre_completo, email, telefono, fecha_registro, estado 
             FROM usuarios 
             WHERE tienda_id = ? AND rol = 'empleado' 
             ORDER BY nombre_completo",
            [$tienda_id]
        );
        
        return $this->response(['employees' => $employees]);
    }
    
    /**
     * Crear empleado
     */
    private function createEmployee($input, $tienda_id) {
        $required = ['username', 'password', 'nombre_completo', 'email'];
        foreach ($required as $field) {
            if (!isset($input[$field]) || empty($input[$field])) {
                return $this->response(['error' => "El campo $field es requerido"], 400);
            }
        }
        
        try {
            $employee_id = $this->db->insert(
                "INSERT INTO usuarios (tienda_id, username, password_hash, nombre_completo, email, telefono, rol) 
                 VALUES (?, ?, ?, ?, ?, ?, 'empleado')",
                [
                    $tienda_id,
                    $input['username'],
                    DatabaseUtils::hashPassword($input['password']),
                    $input['nombre_completo'],
                    $input['email'],
                    $input['telefono'] ?? null
                ]
            );
            
            return $this->response([
                'success' => true,
                'message' => 'Empleado creado exitosamente',
                'employee_id' => $employee_id
            ]);
            
        } catch (Exception $e) {
            error_log("Error creando empleado: " . $e->getMessage());
            return $this->response(['error' => 'Error al crear empleado'], 500);
        }
    }
    
    /**
     * Manejo de ventas
     */
    private function handleSales() {
        $tienda_id = $this->getTiendaId();
        if (!$tienda_id) {
            return $this->response(['error' => 'No autorizado'], 401);
        }
        
        switch ($this->request_method) {
            case 'GET':
                return $this->getSales($tienda_id);
                
            case 'POST':
                $input = $this->getInput();
                return $this->createSale($input, $tienda_id);
        }
        
        return $this->response(['error' => 'Método no permitido'], 405);
    }
    
    /**
     * Crear venta
     */
    private function createSale($input, $tienda_id) {
        if (!isset($input['empleado_id']) || !isset($input['productos']) || empty($input['productos'])) {
            return $this->response(['error' => 'Datos de venta incompletos'], 400);
        }
        
        try {
            $productos_json = json_encode($input['productos']);
            
            // Llamar al procedimiento almacenado
            $result = $this->db->callProcedure(
                'sp_registrar_venta',
                [
                    $tienda_id,
                    $input['empleado_id'],
                    $productos_json,
                    $input['descuento'] ?? 0,
                    $input['metodo_pago'] ?? 'efectivo',
                    $input['notas'] ?? null
                ]
            );
            
            return $this->response([
                'success' => true,
                'message' => 'Venta registrada exitosamente',
                'venta_id' => $result[0]['venta_id'] ?? null
            ]);
            
        } catch (Exception $e) {
            error_log("Error registrando venta: " . $e->getMessage());
            return $this->response(['error' => 'Error al registrar venta'], 500);
        }
    }
    
    /**
     * Manejo del dashboard
     */
    private function handleDashboard() {
        $tienda_id = $this->getTiendaId();
        if (!$tienda_id) {
            return $this->response(['error' => 'No autorizado'], 401);
        }
        
        $stats = DatabaseUtils::getTiendaStats($tienda_id);
        
        return $this->response(['dashboard' => $stats]);
    }
    
    /**
     * Obtener tienda_id del usuario autenticado
     */
    private function getTiendaId() {
        $headers = getallheaders();
        $token = $headers['Authorization'] ?? $_GET['token'] ?? null;
        
        if (!$token) {
            return null;
        }
        
        // Remover 'Bearer ' si existe
        if (strpos($token, 'Bearer ') === 0) {
            $token = substr($token, 7);
        }
        
        $session = $this->db->select(
            "SELECT u.tienda_id FROM sesiones_usuario s 
             JOIN usuarios u ON s.usuario_id = u.id 
             WHERE s.token_sesion = ? AND s.estado = 'activa'",
            [$token]
        );
        
        return $session[0]['tienda_id'] ?? null;
    }
    
    /**
     * Obtener input JSON
     */
    private function getInput() {
        return json_decode(file_get_contents('php://input'), true) ?? [];
    }
    
    /**
     * Enviar respuesta JSON
     */
    private function response($data, $status = 200) {
        http_response_code($status);
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    // Métodos adicionales para completar la API...
    private function handleSuppliers() { /* Implementar */ }
    private function handleReports() { /* Implementar */ }
    private function handleInventory() { /* Implementar */ }
    private function logout() { /* Implementar */ }
    private function getProduct($id, $tienda_id) { /* Implementar */ }
    private function updateProduct($id, $input, $tienda_id) { /* Implementar */ }
    private function deleteProduct($id, $tienda_id) { /* Implementar */ }
    private function updateEmployee($id, $input, $tienda_id) { /* Implementar */ }
    private function getSales($tienda_id) { /* Implementar */ }
}

// Ejecutar la API
try {
    $api = new TienditaAPI();
    $api->processRequest();
} catch (Exception $e) {
    error_log("Error fatal en API: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Error interno del servidor']);
}
?>
