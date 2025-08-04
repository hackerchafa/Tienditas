<?php
/**
 * Archivo principal para Render
 * Sirve el contenido estático y maneja las rutas de la API
 */

// Configurar headers para CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Manejar preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Obtener la ruta solicitada
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);

// Manejar rutas de la API
if (strpos($path, '/api/') === 0) {
    // Redirigir a la API
    require_once 'api/index.php';
    exit();
}

// Servir archivos estáticos
$file_path = __DIR__ . $path;

// Si es la raíz, servir index.html
if ($path === '/' || $path === '') {
    $file_path = __DIR__ . '/index.html';
}

// Verificar si el archivo existe
if (file_exists($file_path) && is_file($file_path)) {
    // Determinar el tipo de contenido
    $extension = pathinfo($file_path, PATHINFO_EXTENSION);
    
    switch ($extension) {
        case 'html':
            header('Content-Type: text/html');
            break;
        case 'css':
            header('Content-Type: text/css');
            break;
        case 'js':
            header('Content-Type: application/javascript');
            break;
        case 'json':
            header('Content-Type: application/json');
            break;
        case 'png':
            header('Content-Type: image/png');
            break;
        case 'jpg':
        case 'jpeg':
            header('Content-Type: image/jpeg');
            break;
        case 'gif':
            header('Content-Type: image/gif');
            break;
        default:
            header('Content-Type: text/plain');
    }
    
    // Servir el archivo
    readfile($file_path);
} else {
    // Archivo no encontrado - servir index.html para SPA routing
    if (pathinfo($path, PATHINFO_EXTENSION) === '') {
        header('Content-Type: text/html');
        readfile(__DIR__ . '/index.html');
    } else {
        http_response_code(404);
        echo "Archivo no encontrado: " . htmlspecialchars($path);
    }
}
?>
