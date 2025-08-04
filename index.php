<?php
// Punto de entrada principal para Apache
session_start();

// Configuración de CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Manejar peticiones OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Obtener la ruta solicitada
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);

// Limpiar la ruta
$path = trim($path, '/');

// Enrutamiento simple
if (empty($path)) {
    // Página principal - mostrar el login
    if (file_exists('login.html')) {
        readfile('login.html');
    } else {
        echo '<!DOCTYPE html>
<html>
<head>
    <title>Tiendita Mejorada</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>🛒 Tiendita Mejorada</h1>
    <p>Sistema de punto de venta</p>
    <a href="/api/">Acceder a la API</a>
</body>
</html>';
    }
} elseif (strpos($path, 'api/') === 0) {
    // Redirigir peticiones de API
    $api_path = substr($path, 4); // Remover 'api/'
    $_SERVER['PATH_INFO'] = '/' . $api_path;
    include_once 'api/index.php';
} else {
    // Intentar servir archivos estáticos
    $file_path = __DIR__ . '/' . $path;
    
    if (file_exists($file_path) && is_file($file_path)) {
        // Determinar el tipo de contenido
        $extension = pathinfo($file_path, PATHINFO_EXTENSION);
        $mime_types = [
            'html' => 'text/html',
            'css' => 'text/css',
            'js' => 'application/javascript',
            'json' => 'application/json',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'gif' => 'image/gif',
            'svg' => 'image/svg+xml',
            'ico' => 'image/x-icon'
        ];
        
        $content_type = $mime_types[$extension] ?? 'application/octet-stream';
        header('Content-Type: ' . $content_type);
        
        readfile($file_path);
    } else {
        // Archivo no encontrado
        http_response_code(404);
        echo '<!DOCTYPE html>
<html>
<head>
    <title>404 - Página no encontrada</title>
</head>
<body>
    <h1>404 - Página no encontrada</h1>
    <p>La página solicitada no existe.</p>
    <a href="/">Volver al inicio</a>
</body>
</html>';
    }
}
?>
