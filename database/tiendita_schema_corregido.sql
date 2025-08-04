-- =====================================================
-- SCRIPT CORREGIDO PARA MYSQL WORKBENCH
-- Base de Datos: TienditaMejorada
-- Sistema de Gestión de Tienda
-- Versión: 2.0 - Corregida
-- =====================================================

-- Crear base de datos
DROP DATABASE IF EXISTS tiendita_mejorada;
CREATE DATABASE tiendita_mejorada 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE tiendita_mejorada;

-- =====================================================
-- TABLAS PRINCIPALES
-- =====================================================

-- Tabla de usuarios del sistema
CREATE TABLE usuarios (
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
CREATE TABLE empleados (
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
CREATE TABLE categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_categoria_estado (estado)
) ENGINE=InnoDB;

-- Tabla de productos
CREATE TABLE productos (
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
CREATE TABLE proveedores (
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
CREATE TABLE ventas (
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
CREATE TABLE detalles_venta (
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
CREATE TABLE movimientos_inventario (
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
CREATE TABLE auditoria (
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
-- VISTAS
-- =====================================================

-- Vista de productos con información de stock
CREATE VIEW vista_productos_stock AS
SELECT 
    p.id,
    p.codigo_barras,
    p.nombre,
    p.descripcion,
    c.nombre AS categoria,
    p.precio_compra,
    p.precio_venta,
    p.stock_actual,
    p.stock_minimo,
    CASE 
        WHEN p.stock_actual <= p.stock_minimo THEN 'Bajo'
        WHEN p.stock_actual <= (p.stock_minimo * 1.5) THEN 'Medio'
        ELSE 'Alto'
    END AS nivel_stock,
    p.estado,
    p.fecha_actualizacion
FROM productos p
INNER JOIN categorias c ON p.categoria_id = c.id
WHERE p.estado = 'activo';

-- Vista de ventas con detalles
CREATE VIEW vista_ventas_detalle AS
SELECT 
    v.id AS venta_id,
    v.fecha_venta,
    CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
    v.total,
    v.descuento,
    v.total_final,
    v.metodo_pago,
    v.estado,
    COUNT(dv.id) AS items_vendidos,
    SUM(dv.cantidad) AS cantidad_total
FROM ventas v
INNER JOIN empleados e ON v.empleado_id = e.id
LEFT JOIN detalles_venta dv ON v.id = dv.venta_id
GROUP BY v.id, v.fecha_venta, e.nombres, e.apellidos, v.total, v.descuento, v.total_final, v.metodo_pago, v.estado;

-- Vista de empleados activos
CREATE VIEW vista_empleados_activos AS
SELECT 
    e.id,
    u.nombre_usuario,
    CONCAT(e.nombres, ' ', e.apellidos) AS nombre_completo,
    e.telefono,
    e.fecha_contratacion,
    e.salario,
    u.ultimo_acceso,
    u.tipo_usuario
FROM empleados e
INNER JOIN usuarios u ON e.usuario_id = u.id
WHERE e.estado = 'activo' AND u.estado = 'activo';

-- Vista de productos por categoría
CREATE VIEW vista_productos_categoria AS
SELECT 
    c.id AS categoria_id,
    c.nombre AS categoria,
    COUNT(p.id) AS total_productos,
    SUM(CASE WHEN p.estado = 'activo' THEN 1 ELSE 0 END) AS productos_activos,
    SUM(p.stock_actual * p.precio_compra) AS valor_inventario,
    AVG(p.precio_venta - p.precio_compra) AS margen_promedio
FROM categorias c
LEFT JOIN productos p ON c.id = p.categoria_id
GROUP BY c.id, c.nombre;

-- =====================================================
-- FUNCIONES
-- =====================================================

DELIMITER //

-- Función para calcular el margen de ganancia
CREATE FUNCTION fn_calcular_margen(precio_compra DECIMAL(10,2), precio_venta DECIMAL(10,2)) 
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE margen DECIMAL(5,2);
    
    IF precio_compra = 0 THEN
        RETURN 0;
    END IF;
    
    SET margen = ((precio_venta - precio_compra) / precio_compra) * 100;
    RETURN margen;
END //

-- Función para obtener el stock disponible
CREATE FUNCTION fn_stock_disponible(producto_id INT) 
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE stock INT DEFAULT 0;
    
    SELECT stock_actual INTO stock
    FROM productos 
    WHERE id = producto_id AND estado = 'activo';
    
    RETURN COALESCE(stock, 0);
END //

-- Función para calcular total de ventas por período
CREATE FUNCTION fn_total_ventas_periodo(fecha_inicio DATE, fecha_fin DATE) 
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(total_final), 0) INTO total
    FROM ventas 
    WHERE DATE(fecha_venta) BETWEEN fecha_inicio AND fecha_fin
    AND estado = 'completada';
    
    RETURN total;
END //

-- Función para obtener ventas por tienda
CREATE FUNCTION fn_ventas_por_tienda(tienda_id INT, fecha_inicio DATE, fecha_fin DATE) 
RETURNS DECIMAL(12,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(total_final), 0) INTO total_ventas
    FROM ventas 
    WHERE DATE(fecha_venta) BETWEEN fecha_inicio AND fecha_fin
    AND ventas.tienda_id = tienda_id
    AND estado = 'completada';
    
    RETURN total_ventas;
END //

DELIMITER ;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS
-- =====================================================

DELIMITER //

-- Procedimiento para registrar una venta completa (CORREGIDO)
CREATE PROCEDURE sp_registrar_venta(
    IN p_tienda_id INT,
    IN p_empleado_id INT,
    IN p_productos JSON,
    IN p_descuento DECIMAL(10,2),
    IN p_metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia'),
    IN p_notas TEXT,
    OUT p_venta_id INT,
    OUT p_mensaje VARCHAR(255)
)
sp_label: BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total_final DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_producto_id INT;
    DECLARE v_cantidad INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_stock_actual INT;
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_longitud INT;
    DECLARE v_stock_suficiente BOOLEAN DEFAULT TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al procesar la venta';
        SET p_venta_id = 0;
    END;

    START TRANSACTION;
    
    -- Inicializar valores
    SET p_venta_id = 0;
    SET v_longitud = JSON_LENGTH(p_productos);
    
    -- Validar que hay productos
    IF v_longitud = 0 THEN
        SET p_mensaje = 'No hay productos en la venta';
        ROLLBACK;
        LEAVE sp_label;
    END IF;
    
    -- Validar stock de todos los productos antes de procesar
    SET v_contador = 0;
    WHILE v_contador < v_longitud AND v_stock_suficiente DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad')));
        
        SELECT stock_actual INTO v_stock_actual
        FROM productos 
        WHERE id = v_producto_id AND estado = 'activo';
        
        IF v_stock_actual IS NULL THEN
            SET p_mensaje = CONCAT('Producto no encontrado ID: ', v_producto_id);
            SET v_stock_suficiente = FALSE;
        ELSEIF v_stock_actual < v_cantidad THEN
            SET p_mensaje = CONCAT('Stock insuficiente para producto ID: ', v_producto_id, '. Stock disponible: ', v_stock_actual);
            SET v_stock_suficiente = FALSE;
        END IF;
        
        SET v_contador = v_contador + 1;
    END WHILE;
    
    -- Si no hay suficiente stock, terminar
    IF NOT v_stock_suficiente THEN
        ROLLBACK;
        LEAVE sp_label;
    END IF;
    
    -- Calcular total
    SET v_contador = 0;
    WHILE v_contador < v_longitud DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad')));
        
        SELECT precio_venta INTO v_precio
        FROM productos 
        WHERE id = v_producto_id;
        
        SET v_subtotal = v_precio * v_cantidad;
        SET v_total = v_total + v_subtotal;
        
        SET v_contador = v_contador + 1;
    END WHILE;
    
    SET v_total_final = v_total - COALESCE(p_descuento, 0);
    
    -- Insertar venta
    INSERT INTO ventas (tienda_id, empleado_id, total, descuento, total_final, metodo_pago, notas)
    VALUES (p_tienda_id, p_empleado_id, v_total, COALESCE(p_descuento, 0), v_total_final, p_metodo_pago, p_notas);
    
    SET p_venta_id = LAST_INSERT_ID();
    
    -- Insertar detalles y actualizar stock
    SET v_contador = 0;
    WHILE v_contador < v_longitud DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad')));
        
        SELECT precio_venta INTO v_precio
        FROM productos 
        WHERE id = v_producto_id;
        
        SET v_subtotal = v_precio * v_cantidad;
        
        -- Insertar detalle
        INSERT INTO detalles_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
        VALUES (p_venta_id, v_producto_id, v_cantidad, v_precio, v_subtotal);
        
        -- Actualizar stock
        UPDATE productos 
        SET stock_actual = stock_actual - v_cantidad
        WHERE id = v_producto_id;
        
        -- Registrar movimiento de inventario
        INSERT INTO movimientos_inventario (producto_id, usuario_id, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, motivo)
        SELECT v_producto_id, 
               (SELECT usuario_id FROM empleados WHERE id = p_empleado_id), 
               'salida', 
               v_cantidad, 
               stock_actual + v_cantidad, 
               stock_actual, 
               CONCAT('Venta ID: ', p_venta_id)
        FROM productos WHERE id = v_producto_id;
        
        SET v_contador = v_contador + 1;
    END WHILE;
    
    COMMIT;
    SET p_mensaje = 'Venta registrada exitosamente';
END //

-- Procedimiento para actualizar stock de producto
CREATE PROCEDURE sp_actualizar_stock(
    IN p_producto_id INT,
    IN p_usuario_id INT,
    IN p_nueva_cantidad INT,
    IN p_motivo VARCHAR(100),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE v_stock_anterior INT;
    DECLARE v_diferencia INT;
    DECLARE v_tipo_movimiento ENUM('entrada', 'salida', 'ajuste');
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'Error al actualizar stock';
    END;

    START TRANSACTION;
    
    -- Obtener stock actual
    SELECT stock_actual INTO v_stock_anterior
    FROM productos 
    WHERE id = p_producto_id;
    
    IF v_stock_anterior IS NULL THEN
        SET p_mensaje = 'Producto no encontrado';
        ROLLBACK;
    ELSE
        -- Calcular diferencia y tipo de movimiento
        SET v_diferencia = p_nueva_cantidad - v_stock_anterior;
        
        IF v_diferencia > 0 THEN
            SET v_tipo_movimiento = 'entrada';
        ELSEIF v_diferencia < 0 THEN
            SET v_tipo_movimiento = 'salida';
        ELSE
            SET v_tipo_movimiento = 'ajuste';
        END IF;
        
        -- Actualizar stock
        UPDATE productos 
        SET stock_actual = p_nueva_cantidad
        WHERE id = p_producto_id;
        
        -- Registrar movimiento
        INSERT INTO movimientos_inventario 
        (producto_id, usuario_id, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, motivo)
        VALUES 
        (p_producto_id, p_usuario_id, v_tipo_movimiento, ABS(v_diferencia), v_stock_anterior, p_nueva_cantidad, p_motivo);
        
        COMMIT;
        SET p_mensaje = 'Stock actualizado correctamente';
    END IF;
END //

-- Procedimiento para obtener reporte de ventas
CREATE PROCEDURE sp_reporte_ventas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_empleado_id INT
)
BEGIN
    SELECT 
        v.id,
        v.fecha_venta,
        CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
        v.total,
        v.descuento,
        v.total_final,
        v.metodo_pago,
        COUNT(dv.id) AS items,
        SUM(dv.cantidad) AS cantidad_total
    FROM ventas v
    INNER JOIN empleados e ON v.empleado_id = e.id
    LEFT JOIN detalles_venta dv ON v.id = dv.venta_id
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
    AND (p_empleado_id IS NULL OR v.empleado_id = p_empleado_id)
    AND v.estado = 'completada'
    GROUP BY v.id
    ORDER BY v.fecha_venta DESC;
END //

-- Procedimiento para obtener productos con stock bajo
CREATE PROCEDURE sp_productos_stock_bajo()
BEGIN
    SELECT 
        p.id,
        p.codigo_barras,
        p.nombre,
        c.nombre AS categoria,
        p.stock_actual,
        p.stock_minimo,
        p.precio_venta,
        (p.stock_minimo - p.stock_actual) AS cantidad_necesaria
    FROM productos p
    INNER JOIN categorias c ON p.categoria_id = c.id
    WHERE p.stock_actual <= p.stock_minimo
    AND p.estado = 'activo'
    ORDER BY (p.stock_actual / NULLIF(p.stock_minimo, 0)) ASC;
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger para auditoría de productos
CREATE TRIGGER tr_productos_auditoria
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla_afectada, operacion, registro_id, datos_anteriores, datos_nuevos)
    VALUES (
        'productos',
        'UPDATE',
        NEW.id,
        JSON_OBJECT(
            'nombre', OLD.nombre,
            'precio_compra', OLD.precio_compra,
            'precio_venta', OLD.precio_venta,
            'stock_actual', OLD.stock_actual,
            'estado', OLD.estado
        ),
        JSON_OBJECT(
            'nombre', NEW.nombre,
            'precio_compra', NEW.precio_compra,
            'precio_venta', NEW.precio_venta,
            'stock_actual', NEW.stock_actual,
            'estado', NEW.estado
        )
    );
END //

-- Trigger para validar precios
CREATE TRIGGER tr_validar_precios
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio_venta <= NEW.precio_compra THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio de venta debe ser mayor al precio de compra';
    END IF;
    
    IF NEW.stock_minimo < 0 THEN
        SET NEW.stock_minimo = 0;
    END IF;
    
    IF NEW.stock_actual < 0 THEN
        SET NEW.stock_actual = 0;
    END IF;
END //

-- Trigger para actualizar último acceso
CREATE TRIGGER tr_actualizar_ultimo_acceso
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.ultimo_acceso IS NULL AND OLD.ultimo_acceso IS NOT NULL THEN
        SET NEW.ultimo_acceso = NOW();
    END IF;
END //

-- Trigger para validar stock en ventas
CREATE TRIGGER tr_validar_stock_venta
BEFORE INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual INT;
    
    SELECT stock_actual INTO v_stock_actual
    FROM productos 
    WHERE id = NEW.producto_id;
    
    IF v_stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para completar la venta';
    END IF;
END //

-- Trigger para calcular subtotal automáticamente
CREATE TRIGGER tr_calcular_subtotal
BEFORE INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END //

DELIMITER ;

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar usuarios por defecto
INSERT INTO usuarios (nombre_usuario, email, password_hash, tipo_usuario) VALUES
('admin', 'admin@tiendita.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'jefe'),
('empleado1', 'empleado1@tiendita.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'empleado');

-- Insertar empleados
INSERT INTO empleados (usuario_id, nombres, apellidos, telefono, fecha_contratacion, salario) VALUES
(1, 'Administrador', 'Principal', '555-0001', CURDATE(), 15000.00),
(2, 'Juan Carlos', 'Pérez', '555-0002', CURDATE(), 8000.00);

-- Insertar categorías
INSERT INTO categorias (nombre, descripcion) VALUES
('Bebidas', 'Refrescos, jugos y bebidas'),
('Snacks', 'Frituras y botanas'),
('Dulces', 'Chocolates y golosinas'),
('Limpieza', 'Productos de limpieza'),
('Lácteos', 'Leche, queso y derivados');

-- Insertar productos de ejemplo
INSERT INTO productos (categoria_id, codigo_barras, nombre, descripcion, precio_compra, precio_venta, stock_minimo, stock_actual) VALUES
(1, '7501234567890', 'Coca Cola 600ml', 'Refresco de cola', 12.00, 18.00, 10, 50),
(1, '7501234567891', 'Agua Natural 1L', 'Agua purificada', 8.00, 12.00, 20, 100),
(2, '7501234567892', 'Sabritas Original', 'Papas fritas', 10.00, 15.00, 15, 75),
(3, '7501234567893', 'Chocolate Carlos V', 'Chocolate con leche', 5.00, 8.00, 25, 120),
(4, '7501234567894', 'Detergente Ariel 1kg', 'Detergente en polvo', 35.00, 55.00, 5, 25);

-- Insertar proveedores
INSERT INTO proveedores (nombre, contacto, telefono, email, direccion) VALUES
('Coca Cola FEMSA', 'Juan Distribuidor', '555-1001', 'ventas@cocacola.com', 'Av. Principal 123'),
('Sabritas S.A.', 'María Comercial', '555-1002', 'contacto@sabritas.com', 'Zona Industrial 456'),
('Nestlé México', 'Carlos Ventas', '555-1003', 'pedidos@nestle.com', 'Col. Centro 789');

-- =====================================================
-- ÍNDICES ADICIONALES PARA RENDIMIENTO
-- =====================================================

-- Índices compuestos para consultas frecuentes
CREATE INDEX idx_ventas_fecha_empleado ON ventas(fecha_venta, empleado_id);
CREATE INDEX idx_productos_categoria_estado ON productos(categoria_id, estado);
CREATE INDEX idx_detalle_venta_producto ON detalles_venta(venta_id, producto_id);
CREATE INDEX idx_movimientos_producto_fecha ON movimientos_inventario(producto_id, fecha_movimiento);

-- =====================================================
-- CONFIGURACIÓN FINAL
-- =====================================================

-- Configurar el motor de almacenamiento por defecto
SET default_storage_engine = InnoDB;

-- Configurar charset por defecto
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Mostrar resumen de creación
SELECT 'Base de datos TienditaMejorada creada exitosamente' AS Estado,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'tiendita_mejorada') AS Tablas,
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'tiendita_mejorada') AS Vistas,
       (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'tiendita_mejorada' AND routine_type = 'FUNCTION') AS Funciones,
       (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'tiendita_mejorada' AND routine_type = 'PROCEDURE') AS Procedimientos;
