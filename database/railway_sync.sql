-- =====================================================
-- SCRIPT PARA SINCRONIZAR RAILWAY Y LOCAL
-- Cambiar nombre de base de datos para Railway
-- =====================================================

-- Para RAILWAY - Usar base de datos existente 'railway'
USE railway;

-- Limpiar base de datos si es necesario (CUIDADO: esto borra todo)
-- DROP TABLE IF EXISTS auditoria, movimientos_inventario, detalles_venta, ventas, productos, categorias, empleados, usuarios, proveedores;

-- =====================================================
-- TABLAS PRINCIPALES (Mismo contenido pero para Railway)
-- =====================================================

-- Tabla de usuarios del sistema
CREATE TABLE IF NOT EXISTS usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    tipo_usuario ENUM('jefe', 'empleado') NOT NULL DEFAULT 'empleado',
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    ultimo_acceso TIMESTAMP NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_usuario_estado (nombre_usuario, estado),
    INDEX idx_email (email),
    INDEX idx_tipo_usuario (tipo_usuario)
) ENGINE=InnoDB;

-- Tabla de empleados
CREATE TABLE IF NOT EXISTS empleados (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    fecha_contratacion DATE NOT NULL,
    salario DECIMAL(10,2),
    estado ENUM('activo', 'inactivo', 'suspendido') NOT NULL DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_empleado_estado (estado),
    INDEX idx_empleado_nombres (nombres, apellidos)
) ENGINE=InnoDB;

-- Tabla de categorías de productos
CREATE TABLE IF NOT EXISTS categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_categoria_estado (estado)
) ENGINE=InnoDB;

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    categoria_id INT NOT NULL,
    codigo_barras VARCHAR(50) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio_compra DECIMAL(10,2) NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL,
    stock_minimo INT NOT NULL DEFAULT 0,
    stock_actual INT NOT NULL DEFAULT 0,
    estado ENUM('activo', 'inactivo', 'descontinuado') NOT NULL DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT,
    INDEX idx_producto_categoria (categoria_id),
    INDEX idx_producto_codigo (codigo_barras),
    INDEX idx_producto_nombre (nombre),
    INDEX idx_producto_estado (estado),
    INDEX idx_stock_bajo (stock_actual, stock_minimo)
) ENGINE=InnoDB;

-- Tabla de proveedores
CREATE TABLE IF NOT EXISTS proveedores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(200) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion TEXT,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_proveedor_nombre (nombre),
    INDEX idx_proveedor_estado (estado)
) ENGINE=InnoDB;

-- Tabla de ventas
CREATE TABLE IF NOT EXISTS ventas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tienda_id INT NOT NULL DEFAULT 1,
    empleado_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0.00,
    total_final DECIMAL(10,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia') NOT NULL,
    estado ENUM('pendiente', 'completada', 'cancelada') NOT NULL DEFAULT 'completada',
    notas TEXT,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE RESTRICT,
    INDEX idx_venta_fecha (fecha_venta),
    INDEX idx_venta_empleado (empleado_id),
    INDEX idx_venta_estado (estado),
    INDEX idx_venta_total (total_final)
) ENGINE=InnoDB;

-- Tabla de detalles de venta
CREATE TABLE IF NOT EXISTS detalles_venta (
    id INT PRIMARY KEY AUTO_INCREMENT,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    INDEX idx_detalle_venta (venta_id),
    INDEX idx_detalle_producto (producto_id)
) ENGINE=InnoDB;

-- Tabla de movimientos de inventario
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    producto_id INT NOT NULL,
    usuario_id INT NOT NULL,
    tipo_movimiento ENUM('entrada', 'salida', 'ajuste') NOT NULL,
    cantidad INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    motivo VARCHAR(200),
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    INDEX idx_movimiento_producto (producto_id),
    INDEX idx_movimiento_fecha (fecha_movimiento),
    INDEX idx_movimiento_tipo (tipo_movimiento)
) ENGINE=InnoDB;

-- Tabla de auditoría
CREATE TABLE IF NOT EXISTS auditoria (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tabla_afectada VARCHAR(50) NOT NULL,
    operacion ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    registro_id INT NOT NULL,
    usuario_id INT,
    datos_anteriores JSON,
    datos_nuevos JSON,
    fecha_operacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_auditoria_tabla (tabla_afectada),
    INDEX idx_auditoria_fecha (fecha_operacion),
    INDEX idx_auditoria_usuario (usuario_id)
) ENGINE=InnoDB;

-- =====================================================
-- INSERTAR DATOS INICIALES (solo si no existen)
-- =====================================================

-- Verificar si ya existen usuarios
SET @user_count = (SELECT COUNT(*) FROM usuarios);

-- Solo insertar si no hay usuarios
INSERT INTO usuarios (nombre_usuario, email, password_hash, tipo_usuario) 
SELECT * FROM (
    SELECT 'admin' as nombre_usuario, 'admin@tiendita.com' as email, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' as password_hash, 'jefe' as tipo_usuario
    UNION ALL
    SELECT 'empleado1', 'empleado1@tiendita.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'empleado'
) AS tmp
WHERE @user_count = 0;

-- Solo insertar empleados si no existen
INSERT INTO empleados (usuario_id, nombres, apellidos, telefono, fecha_contratacion, salario)
SELECT * FROM (
    SELECT 1 as usuario_id, 'Administrador' as nombres, 'Principal' as apellidos, '555-0001' as telefono, CURDATE() as fecha_contratacion, 15000.00 as salario
    UNION ALL
    SELECT 2, 'Juan Carlos', 'Pérez', '555-0002', CURDATE(), 8000.00
) AS tmp
WHERE (SELECT COUNT(*) FROM empleados) = 0;

-- Solo insertar categorías si no existen
INSERT INTO categorias (nombre, descripcion)
SELECT * FROM (
    SELECT 'Bebidas' as nombre, 'Refrescos, jugos y bebidas' as descripcion
    UNION ALL
    SELECT 'Snacks', 'Frituras y botanas'
    UNION ALL
    SELECT 'Dulces', 'Chocolates y golosinas'
    UNION ALL
    SELECT 'Limpieza', 'Productos de limpieza'
    UNION ALL
    SELECT 'Lácteos', 'Leche, queso y derivados'
) AS tmp
WHERE (SELECT COUNT(*) FROM categorias) = 0;

-- Solo insertar productos si no existen
INSERT INTO productos (categoria_id, codigo_barras, nombre, descripcion, precio_compra, precio_venta, stock_minimo, stock_actual)
SELECT * FROM (
    SELECT 1 as categoria_id, '7501234567890' as codigo_barras, 'Coca Cola 600ml' as nombre, 'Refresco de cola' as descripcion, 12.00 as precio_compra, 18.00 as precio_venta, 10 as stock_minimo, 50 as stock_actual
    UNION ALL
    SELECT 1, '7501234567891', 'Agua Natural 1L', 'Agua purificada', 8.00, 12.00, 20, 100
    UNION ALL
    SELECT 2, '7501234567892', 'Sabritas Original', 'Papas fritas', 10.00, 15.00, 15, 75
    UNION ALL
    SELECT 3, '7501234567893', 'Chocolate Carlos V', 'Chocolate con leche', 5.00, 8.00, 25, 120
    UNION ALL
    SELECT 4, '7501234567894', 'Detergente Ariel 1kg', 'Detergente en polvo', 35.00, 55.00, 5, 25
) AS tmp
WHERE (SELECT COUNT(*) FROM productos) = 0;

-- Solo insertar proveedores si no existen
INSERT INTO proveedores (nombre, contacto, telefono, email, direccion)
SELECT * FROM (
    SELECT 'Coca Cola FEMSA' as nombre, 'Juan Distribuidor' as contacto, '555-1001' as telefono, 'ventas@cocacola.com' as email, 'Av. Principal 123' as direccion
    UNION ALL
    SELECT 'Sabritas S.A.', 'María Comercial', '555-1002', 'contacto@sabritas.com', 'Zona Industrial 456'
    UNION ALL
    SELECT 'Nestlé México', 'Carlos Ventas', '555-1003', 'pedidos@nestle.com', 'Col. Centro 789'
) AS tmp
WHERE (SELECT COUNT(*) FROM proveedores) = 0;

-- =====================================================
-- VERIFICAR DATOS INSERTADOS
-- =====================================================

SELECT 'SINCRONIZACIÓN COMPLETADA' AS Estado,
       (SELECT COUNT(*) FROM usuarios) AS Usuarios,
       (SELECT COUNT(*) FROM empleados) AS Empleados,
       (SELECT COUNT(*) FROM categorias) AS Categorias,
       (SELECT COUNT(*) FROM productos) AS Productos,
       (SELECT COUNT(*) FROM proveedores) AS Proveedores;

-- Mostrar algunos datos para verificar
SELECT 'USUARIOS:' AS Tabla, nombre_usuario, email, tipo_usuario FROM usuarios
UNION ALL
SELECT 'PRODUCTOS:', nombre, CONCAT('$', precio_venta), categoria_id FROM productos LIMIT 3;
