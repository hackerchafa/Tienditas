-- =====================================================
-- SISTEMA DE BASE DE DATOS TIENDITA MEJORADA
-- Creado: 4 de agosto de 2025
-- Descripción: Sistema completo de gestión de tienda
-- Incluye: Tablas, Índices, Vistas, Procedimientos, Triggers y Funciones
-- =====================================================

-- Crear la base de datos
DROP DATABASE IF EXISTS tiendita_mejorada;
CREATE DATABASE tiendita_mejorada 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE tiendita_mejorada;

-- =====================================================
-- CREACIÓN DE TABLAS
-- =====================================================

-- Tabla de Tiendas
CREATE TABLE tiendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(20),
    email VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('activa', 'inactiva') DEFAULT 'activa',
    INDEX idx_tienda_estado (estado),
    INDEX idx_tienda_nombre (nombre)
) ENGINE=InnoDB;

-- Tabla de Usuarios (Jefes y Empleados)
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tienda_id INT NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    rol ENUM('jefe', 'empleado') NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_acceso TIMESTAMP NULL,
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE,
    INDEX idx_usuario_rol (rol),
    INDEX idx_usuario_estado (estado),
    INDEX idx_usuario_tienda (tienda_id),
    INDEX idx_usuario_email (email)
) ENGINE=InnoDB;

-- Tabla de Categorías de Productos
CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tienda_id INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('activa', 'inactiva') DEFAULT 'activa',
    FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_categoria_tienda (tienda_id, nombre),
    INDEX idx_categoria_estado (estado)
) ENGINE=InnoDB;

-- Tabla de Proveedores
CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tienda_id INT NOT NULL,
    empresa VARCHAR(100) NOT NULL,
    persona_contacto VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    direccion TEXT,
    productos_suministra TEXT,
    dias_entrega VARCHAR(100),
    notas TEXT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE,
    INDEX idx_proveedor_estado (estado),
    INDEX idx_proveedor_tienda (tienda_id),
    INDEX idx_proveedor_empresa (empresa)
) ENGINE=InnoDB;

-- Tabla de Productos
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tienda_id INT NOT NULL,
    categoria_id INT,
    proveedor_id INT,
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    marca VARCHAR(50),
    precio_compra DECIMAL(10,2) NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL,
    stock_actual INT DEFAULT 0,
    stock_minimo INT DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    estado ENUM('activo', 'inactivo') DEFAULT 'activo',
    FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE SET NULL,
    UNIQUE KEY uk_producto_codigo_tienda (tienda_id, codigo),
    INDEX idx_producto_categoria (categoria_id),
    INDEX idx_producto_proveedor (proveedor_id),
    INDEX idx_producto_stock (stock_actual),
    INDEX idx_producto_estado (estado),
    INDEX idx_producto_nombre (nombre),
    INDEX idx_producto_codigo (codigo)
) ENGINE=InnoDB;

-- Tabla de Movimientos de Inventario
CREATE TABLE movimientos_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    usuario_id INT NOT NULL,
    tipo_movimiento ENUM('entrada', 'salida', 'ajuste') NOT NULL,
    cantidad INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    motivo VARCHAR(100),
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_movimiento_producto (producto_id),
    INDEX idx_movimiento_tipo (tipo_movimiento),
    INDEX idx_movimiento_fecha (fecha_movimiento)
) ENGINE=InnoDB;

-- Tabla de Ventas
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tienda_id INT NOT NULL,
    empleado_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0.00,
    impuesto DECIMAL(10,2) DEFAULT 0.00,
    total_final DECIMAL(10,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'tarjeta', 'transferencia') DEFAULT 'efectivo',
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('completada', 'cancelada', 'pendiente') DEFAULT 'completada',
    notas TEXT,
    FOREIGN KEY (tienda_id) REFERENCES tiendas(id) ON DELETE CASCADE,
    FOREIGN KEY (empleado_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_venta_empleado (empleado_id),
    INDEX idx_venta_fecha (fecha_venta),
    INDEX idx_venta_estado (estado),
    INDEX idx_venta_total (total_final)
) ENGINE=InnoDB;

-- Tabla de Detalles de Venta
CREATE TABLE detalles_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    INDEX idx_detalle_venta (venta_id),
    INDEX idx_detalle_producto (producto_id)
) ENGINE=InnoDB;

-- Tabla de Sesiones de Usuario
CREATE TABLE sesiones_usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    token_sesion VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    estado ENUM('activa', 'expirada') DEFAULT 'activa',
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE KEY uk_token_sesion (token_sesion),
    INDEX idx_sesion_usuario (usuario_id),
    INDEX idx_sesion_estado (estado)
) ENGINE=InnoDB;

-- =====================================================
-- VISTAS
-- =====================================================

-- Vista de Productos con Información Completa
CREATE VIEW vista_productos_completa AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.descripcion,
    p.marca,
    c.nombre AS categoria,
    pr.empresa AS proveedor,
    p.precio_compra,
    p.precio_venta,
    p.stock_actual,
    p.stock_minimo,
    CASE 
        WHEN p.stock_actual <= 0 THEN 'Agotado'
        WHEN p.stock_actual <= p.stock_minimo THEN 'Stock Bajo'
        ELSE 'Disponible'
    END AS estado_stock,
    p.fecha_creacion,
    p.estado,
    t.nombre AS tienda
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN proveedores pr ON p.proveedor_id = pr.id
LEFT JOIN tiendas t ON p.tienda_id = t.id
WHERE p.estado = 'activo';

-- Vista de Ventas con Resumen
CREATE VIEW vista_ventas_resumen AS
SELECT 
    v.id,
    v.fecha_venta,
    u.nombre_completo AS empleado,
    v.total,
    v.descuento,
    v.total_final,
    v.metodo_pago,
    v.estado,
    COUNT(dv.id) AS cantidad_items,
    t.nombre AS tienda
FROM ventas v
JOIN usuarios u ON v.empleado_id = u.id
JOIN tiendas t ON v.tienda_id = t.id
LEFT JOIN detalles_venta dv ON v.id = dv.venta_id
GROUP BY v.id, v.fecha_venta, u.nombre_completo, v.total, v.descuento, 
         v.total_final, v.metodo_pago, v.estado, t.nombre;

-- Vista de Productos Más Vendidos
CREATE VIEW vista_productos_mas_vendidos AS
SELECT 
    p.id,
    p.nombre,
    p.codigo,
    c.nombre AS categoria,
    SUM(dv.cantidad) AS total_vendido,
    SUM(dv.subtotal) AS total_ingresos,
    COUNT(DISTINCT dv.venta_id) AS numero_ventas
FROM productos p
JOIN detalles_venta dv ON p.id = dv.producto_id
JOIN ventas v ON dv.venta_id = v.id
LEFT JOIN categorias c ON p.categoria_id = c.id
WHERE v.estado = 'completada'
GROUP BY p.id, p.nombre, p.codigo, c.nombre
ORDER BY total_vendido DESC;

-- Vista de Inventario Crítico
CREATE VIEW vista_inventario_critico AS
SELECT 
    p.id,
    p.codigo,
    p.nombre,
    p.stock_actual,
    p.stock_minimo,
    p.precio_venta,
    c.nombre AS categoria,
    t.nombre AS tienda,
    CASE 
        WHEN p.stock_actual <= 0 THEN 'Crítico - Agotado'
        WHEN p.stock_actual <= p.stock_minimo THEN 'Advertencia - Stock Bajo'
    END AS nivel_alerta
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN tiendas t ON p.tienda_id = t.id
WHERE p.stock_actual <= p.stock_minimo 
AND p.estado = 'activo'
ORDER BY p.stock_actual ASC;

-- =====================================================
-- FUNCIONES
-- =====================================================

DELIMITER //

-- Función para calcular el margen de ganancia
CREATE FUNCTION calcular_margen_ganancia(precio_compra DECIMAL(10,2), precio_venta DECIMAL(10,2))
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE margen DECIMAL(5,2);
    
    IF precio_compra = 0 THEN
        RETURN 0.00;
    END IF;
    
    SET margen = ((precio_venta - precio_compra) / precio_compra) * 100;
    RETURN ROUND(margen, 2);
END //

-- Función para obtener el stock total de una tienda
CREATE FUNCTION obtener_stock_total_tienda(tienda_id INT)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_stock INT DEFAULT 0;
    
    SELECT COALESCE(SUM(stock_actual), 0) INTO total_stock
    FROM productos 
    WHERE productos.tienda_id = tienda_id 
    AND estado = 'activo';
    
    RETURN total_stock;
END //

-- Función para validar stock disponible
CREATE FUNCTION validar_stock_disponible(producto_id INT, cantidad_solicitada INT)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE stock_disponible INT DEFAULT 0;
    
    SELECT stock_actual INTO stock_disponible
    FROM productos 
    WHERE id = producto_id;
    
    RETURN stock_disponible >= cantidad_solicitada;
END //

-- Función para obtener ventas del día
CREATE FUNCTION obtener_ventas_dia(fecha_consulta DATE, tienda_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(10,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(total_final), 0.00) INTO total_ventas
    FROM ventas 
    WHERE DATE(fecha_venta) = fecha_consulta 
    AND ventas.tienda_id = tienda_id
    AND estado = 'completada';
    
    RETURN total_ventas;
END //

DELIMITER ;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS
-- =====================================================

DELIMITER //

-- Procedimiento para registrar una venta completa
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
    
    -- Obtener la longitud del array JSON
    SET v_longitud = JSON_LENGTH(p_productos);
    
    -- Validar stock de todos los productos antes de procesar
    SET v_contador = 0;
    WHILE v_contador < v_longitud AND v_stock_suficiente DO
        SET v_producto_id = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id'));
        SET v_cantidad = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad'));
        
        SELECT stock_actual INTO v_stock_actual
        FROM productos 
        WHERE id = v_producto_id;
        
        IF v_stock_actual < v_cantidad THEN
            SET p_mensaje = CONCAT('Stock insuficiente para producto ID: ', v_producto_id);
            SET v_stock_suficiente = FALSE;
            ROLLBACK;
            LEAVE sp_label;
        END IF;
        
        SET v_contador = v_contador + 1;
    END WHILE;
    
    -- Si hay suficiente stock, proceder con la venta
    IF v_stock_suficiente THEN
        -- Calcular total
        SET v_contador = 0;
        WHILE v_contador < v_longitud DO
            SET v_producto_id = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id'));
            SET v_cantidad = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad'));
            
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
        VALUES (p_tienda_id, p_empleado_id, v_total, p_descuento, v_total_final, p_metodo_pago, p_notas);
        
        SET p_venta_id = LAST_INSERT_ID();
        
        -- Insertar detalles y actualizar stock
        SET v_contador = 0;
        WHILE v_contador < v_longitud DO
            SET v_producto_id = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].producto_id'));
            SET v_cantidad = JSON_EXTRACT(p_productos, CONCAT('$[', v_contador, '].cantidad'));
            
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
            SELECT v_producto_id, p_empleado_id, 'salida', v_cantidad, 
                   stock_actual + v_cantidad, stock_actual, 
                   CONCAT('Venta ID: ', p_venta_id)
            FROM productos WHERE id = v_producto_id;
            
            SET v_contador = v_contador + 1;
        END WHILE;
        
        COMMIT;
        SET p_mensaje = 'Venta registrada exitosamente';
    END IF;
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
    
    -- Calcular diferencia y tipo de movimiento
    SET v_diferencia = p_nueva_cantidad - v_stock_anterior;
    
    IF v_diferencia > 0 THEN
        SET v_tipo_movimiento = 'entrada';
    ELSEIF v_diferencia < 0 THEN
        SET v_tipo_movimiento = 'salida';
        SET v_diferencia = ABS(v_diferencia);
    ELSE
        SET v_tipo_movimiento = 'ajuste';
        SET v_diferencia = 0;
    END IF;
    
    -- Actualizar stock
    UPDATE productos 
    SET stock_actual = p_nueva_cantidad,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id = p_producto_id;
    
    -- Registrar movimiento
    INSERT INTO movimientos_inventario (
        producto_id, usuario_id, tipo_movimiento, cantidad, 
        stock_anterior, stock_nuevo, motivo
    ) VALUES (
        p_producto_id, p_usuario_id, v_tipo_movimiento, v_diferencia,
        v_stock_anterior, p_nueva_cantidad, p_motivo
    );
    
    COMMIT;
    SET p_mensaje = 'Stock actualizado correctamente';
END //

-- Procedimiento para obtener reporte de ventas
CREATE PROCEDURE sp_reporte_ventas(
    IN p_tienda_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_empleado_id INT
)
BEGIN
    SELECT 
        v.id,
        v.fecha_venta,
        u.nombre_completo AS empleado,
        v.total,
        v.descuento,
        v.total_final,
        v.metodo_pago,
        COUNT(dv.id) AS items_vendidos,
        SUM(dv.cantidad) AS productos_totales
    FROM ventas v
    JOIN usuarios u ON v.empleado_id = u.id
    LEFT JOIN detalles_venta dv ON v.id = dv.venta_id
    WHERE v.tienda_id = p_tienda_id
    AND DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
    AND (p_empleado_id IS NULL OR v.empleado_id = p_empleado_id)
    AND v.estado = 'completada'
    GROUP BY v.id, v.fecha_venta, u.nombre_completo, v.total, v.descuento, v.total_final, v.metodo_pago
    ORDER BY v.fecha_venta DESC;
END //

-- Procedimiento para obtener productos con stock bajo
CREATE PROCEDURE sp_productos_stock_bajo(IN p_tienda_id INT)
BEGIN
    SELECT 
        p.id,
        p.codigo,
        p.nombre,
        p.stock_actual,
        p.stock_minimo,
        c.nombre AS categoria,
        pr.empresa AS proveedor,
        pr.telefono AS proveedor_telefono
    FROM productos p
    LEFT JOIN categorias c ON p.categoria_id = c.id
    LEFT JOIN proveedores pr ON p.proveedor_id = pr.id
    WHERE p.tienda_id = p_tienda_id
    AND p.stock_actual <= p.stock_minimo
    AND p.estado = 'activo'
    ORDER BY p.stock_actual ASC;
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger para actualizar fecha de último acceso del usuario
CREATE TRIGGER tr_actualizar_ultimo_acceso
AFTER INSERT ON sesiones_usuario
FOR EACH ROW
BEGIN
    UPDATE usuarios 
    SET fecha_ultimo_acceso = CURRENT_TIMESTAMP
    WHERE id = NEW.usuario_id;
END //

-- Trigger para validar stock antes de venta
CREATE TRIGGER tr_validar_stock_venta
BEFORE INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock_disponible INT;
    
    SELECT stock_actual INTO v_stock_disponible
    FROM productos 
    WHERE id = NEW.producto_id;
    
    IF v_stock_disponible < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Stock insuficiente para el producto solicitado';
    END IF;
END //

-- Trigger para calcular subtotal automáticamente
CREATE TRIGGER tr_calcular_subtotal_detalle
BEFORE INSERT ON detalles_venta
FOR EACH ROW
BEGIN
    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END //

-- Trigger para actualizar precio de venta basado en margen
CREATE TRIGGER tr_actualizar_precio_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    -- Si se actualiza el precio de compra, mantener margen del 30%
    IF NEW.precio_compra != OLD.precio_compra AND NEW.precio_venta = OLD.precio_venta THEN
        SET NEW.precio_venta = NEW.precio_compra * 1.30;
    END IF;
END //

-- Trigger para auditoría de cambios en productos críticos
CREATE TRIGGER tr_auditoria_productos
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF OLD.stock_actual != NEW.stock_actual OR OLD.precio_venta != NEW.precio_venta THEN
        INSERT INTO movimientos_inventario (
            producto_id, usuario_id, tipo_movimiento, cantidad,
            stock_anterior, stock_nuevo, motivo
        ) VALUES (
            NEW.id, 1, 'ajuste', ABS(NEW.stock_actual - OLD.stock_actual),
            OLD.stock_actual, NEW.stock_actual, 'Actualización manual'
        );
    END IF;
END //

DELIMITER ;

-- =====================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- =====================================================

-- Insertar tienda de prueba
INSERT INTO tiendas (nombre, direccion, telefono, email) VALUES
('Tienda Don Carlos', 'Calle Principal 123, Centro', '555-0001', 'doncarlos@tienda.com');

-- Insertar usuarios de prueba
INSERT INTO usuarios (tienda_id, username, password_hash, nombre_completo, email, rol) VALUES
(1, 'jefe1', '$2y$10$example_hash_for_123456', 'Carlos Rodríguez', 'carlos@tienda.com', 'jefe'),
(1, 'empleado1', '$2y$10$example_hash_for_123456', 'Ana García López', 'ana.garcia@tienda.com', 'empleado'),
(1, 'empleado2', '$2y$10$example_hash_for_123456', 'Carlos Rodríguez', 'carlos.rodriguez@tienda.com', 'empleado');

-- Insertar categorías de prueba
INSERT INTO categorias (tienda_id, nombre, descripcion) VALUES
(1, 'Bebidas', 'Refrescos, jugos y bebidas en general'),
(1, 'Snacks', 'Frituras, dulces y botanas'),
(1, 'Lácteos', 'Leche, yogurt, quesos y derivados'),
(1, 'Panadería', 'Pan, pasteles y productos de panadería'),
(1, 'Limpieza', 'Productos de limpieza y aseo');

-- Insertar proveedores de prueba
INSERT INTO proveedores (tienda_id, empresa, persona_contacto, telefono, email, direccion, productos_suministra, dias_entrega) VALUES
(1, 'Distribuidora Central S.A.', 'María Elena Vásquez', '555-2001', 'ventas@distribuidoracentral.com', 'Av. Industrial 123, Zona Industrial', 'Bebidas, Snacks, Productos de limpieza', 'Lunes, Miércoles, Viernes'),
(1, 'Panadería Artesanal El Trigo', 'Roberto Martínez', '555-2002', 'pedidos@panaderiaeltrigo.com', 'Calle del Pan 45, Centro', 'Pan fresco, Pasteles, Productos de panadería', 'Martes, Jueves, Sábado'),
(1, 'Lácteos Valle Verde', 'Carmen Jiménez', '555-2003', 'distribución@valleverde.com', 'Km 15 Carretera Norte', 'Leche, Yogurt, Quesos, Mantequilla', 'Lunes, Miércoles, Viernes');

-- Insertar productos de prueba
INSERT INTO productos (tienda_id, categoria_id, proveedor_id, codigo, nombre, descripcion, marca, precio_compra, precio_venta, stock_actual, stock_minimo) VALUES
(1, 1, 1, 'CC600', 'Coca Cola 600ml', 'Refresco de cola en botella de 600ml', 'Coca Cola', 12.00, 18.00, 50, 10),
(1, 4, 2, 'PB001', 'Pan Bimbo Grande', 'Pan de caja grande integral', 'Bimbo', 25.00, 35.00, 30, 5),
(1, 3, 3, 'LL1000', 'Leche Lala 1L', 'Leche entera ultrapasteurizada 1 litro', 'Lala', 20.00, 28.00, 40, 8),
(1, 2, 1, 'SAB45', 'Sabritas Original 45g', 'Papas fritas sabor original', 'Sabritas', 8.00, 12.00, 60, 10),
(1, 5, 1, 'FAB1000', 'Fabuloso 1L', 'Limpiador multiusos aroma lavanda', 'Fabuloso', 30.00, 45.00, 25, 3);

-- Insertar algunas ventas de prueba
INSERT INTO ventas (tienda_id, empleado_id, total, descuento, total_final, metodo_pago) VALUES
(1, 2, 71.00, 0.00, 71.00, 'efectivo'),
(1, 2, 64.00, 0.00, 64.00, 'tarjeta');

INSERT INTO detalles_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 2, 18.00, 36.00),
(1, 2, 1, 35.00, 35.00),
(2, 3, 1, 28.00, 28.00),
(2, 4, 3, 12.00, 36.00);

-- =====================================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices compuestos para consultas frecuentes
CREATE INDEX idx_productos_tienda_categoria ON productos(tienda_id, categoria_id);
CREATE INDEX idx_productos_tienda_stock ON productos(tienda_id, stock_actual);
CREATE INDEX idx_ventas_tienda_fecha ON ventas(tienda_id, fecha_venta);
CREATE INDEX idx_ventas_empleado_fecha ON ventas(empleado_id, fecha_venta);
CREATE INDEX idx_movimientos_producto_fecha ON movimientos_inventario(producto_id, fecha_movimiento);

-- Índices de texto completo para búsquedas
ALTER TABLE productos ADD FULLTEXT(nombre, descripcion, marca);
ALTER TABLE proveedores ADD FULLTEXT(empresa, persona_contacto);

-- =====================================================
-- CONFIGURACIONES FINALES
-- =====================================================

-- Configurar el modo SQL
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- Establecer charset por defecto
ALTER DATABASE tiendita_mejorada CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Mensaje de finalización
SELECT 'Base de datos TienditaMejorada creada exitosamente' AS mensaje;
SELECT 'Tablas creadas: 9' AS tablas;
SELECT 'Vistas creadas: 4' AS vistas;
SELECT 'Funciones creadas: 4' AS funciones;
SELECT 'Procedimientos creados: 4' AS procedimientos;
SELECT 'Triggers creados: 5' AS triggers;
SELECT 'Datos de prueba insertados' AS datos;
