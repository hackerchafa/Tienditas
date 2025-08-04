-- =====================================================
-- SCRIPT DIRECTO PARA RAILWAY
-- Ejecutar directamente en la consola de Railway
-- =====================================================

-- Usar la base de datos railway
USE railway;

-- =====================================================
-- CREAR TABLAS SI NO EXISTEN
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
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
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
    
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla de categorías de productos
CREATE TABLE IF NOT EXISTS categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT
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
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
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
    
    FOREIGN KEY (empleado_id) REFERENCES empleados(id) ON DELETE RESTRICT
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
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
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
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT
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
    
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- INSERTAR DATOS INICIALES
-- =====================================================

-- Insertar usuarios (usar INSERT IGNORE para evitar duplicados)
INSERT IGNORE INTO usuarios (nombre_usuario, email, password_hash, tipo_usuario) VALUES
('admin', 'admin@tiendita.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'jefe'),
('empleado1', 'empleado1@tiendita.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'empleado');

-- Insertar empleados
INSERT IGNORE INTO empleados (usuario_id, nombres, apellidos, telefono, fecha_contratacion, salario) VALUES
(1, 'Administrador', 'Principal', '555-0001', CURDATE(), 15000.00),
(2, 'Juan Carlos', 'Pérez', '555-0002', CURDATE(), 8000.00);

-- Insertar categorías
INSERT IGNORE INTO categorias (nombre, descripcion) VALUES
('Bebidas', 'Refrescos, jugos y bebidas'),
('Snacks', 'Frituras y botanas'),
('Dulces', 'Chocolates y golosinas'),
('Limpieza', 'Productos de limpieza'),
('Lácteos', 'Leche, queso y derivados');

-- Insertar productos de ejemplo
INSERT IGNORE INTO productos (categoria_id, codigo_barras, nombre, descripcion, precio_compra, precio_venta, stock_minimo, stock_actual) VALUES
(1, '7501234567890', 'Coca Cola 600ml', 'Refresco de cola', 12.00, 18.00, 10, 50),
(1, '7501234567891', 'Agua Natural 1L', 'Agua purificada', 8.00, 12.00, 20, 100),
(2, '7501234567892', 'Sabritas Original', 'Papas fritas', 10.00, 15.00, 15, 75),
(3, '7501234567893', 'Chocolate Carlos V', 'Chocolate con leche', 5.00, 8.00, 25, 120),
(4, '7501234567894', 'Detergente Ariel 1kg', 'Detergente en polvo', 35.00, 55.00, 5, 25);

-- Insertar proveedores
INSERT IGNORE INTO proveedores (nombre, contacto, telefono, email, direccion) VALUES
('Coca Cola FEMSA', 'Juan Distribuidor', '555-1001', 'ventas@cocacola.com', 'Av. Principal 123'),
('Sabritas S.A.', 'María Comercial', '555-1002', 'contacto@sabritas.com', 'Zona Industrial 456'),
('Nestlé México', 'Carlos Ventas', '555-1003', 'pedidos@nestle.com', 'Col. Centro 789');

-- =====================================================
-- VERIFICAR DATOS
-- =====================================================

-- Mostrar resumen de datos insertados
SELECT 'DATOS INSERTADOS EN RAILWAY' AS Estado,
       (SELECT COUNT(*) FROM usuarios) AS Usuarios,
       (SELECT COUNT(*) FROM empleados) AS Empleados,
       (SELECT COUNT(*) FROM categorias) AS Categorias,
       (SELECT COUNT(*) FROM productos) AS Productos,
       (SELECT COUNT(*) FROM proveedores) AS Proveedores;

-- Mostrar algunos datos para verificar
SELECT 'USUARIOS' AS Tipo, nombre_usuario AS Nombre, email AS Detalle, tipo_usuario AS Extra FROM usuarios
UNION ALL
SELECT 'PRODUCTOS', nombre, CONCAT('$', precio_venta), categoria_id FROM productos
UNION ALL
SELECT 'CATEGORIAS', nombre, descripcion, estado FROM categorias;

-- Verificar conexión exitosa
SELECT 'RAILWAY DATABASE CONECTADA EXITOSAMENTE' AS Mensaje, NOW() AS Fecha;
