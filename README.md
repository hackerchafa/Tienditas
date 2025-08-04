# TienditaMejorada - Sistema de Gestión de Tienda

## 🚀 Inicio Rápido

### Requisitos Previos
- XAMPP o WAMP instalado (incluye Apache, MySQL, PHP)
- MySQL Workbench (opcional, para gestión visual de la BD)
- Navegador web moderno (Chrome, Firefox, Edge)

### 📥 Instalación con Railway

#### 1. Configurar el Servidor Web
```bash
# Copiar el proyecto a la carpeta del servidor web
# Para XAMPP: C:\xampp\htdocs\TienditaMejorada
# Para WAMP: C:\wamp64\www\TienditaMejorada
```

#### 2. Configurar Base de Datos Railway
```sql
# Tu base de datos Railway ya está configurada:
# mysql://root:DcFHhdYINqDJuvHeurHxKZOeOLcbsIGf@switchback.proxy.rlwy.net:31739/railway

# Ejecutar en la consola de Railway:
# database/railway_setup.sql
```

#### 3. Verificar Configuración
```bash
# El archivo .env ya está configurado para Railway
# No necesitas cambiar nada
```

#### 4. Probar Conexión
```bash
# Abrir en navegador: 
# http://localhost/TienditaMejorada/test-railway.php
```

### 🌐 Acceso al Sistema

#### URLs de Acceso
- Sistema Principal: `http://localhost/TienditaMejorada/`
- API REST: `http://localhost/TienditaMejorada/api/`
- Panel de Administración: Login con usuario tipo 'jefe'

#### Usuarios por Defecto
```sql
-- Jefe (Administrador)
Usuario: admin
Contraseña: admin123

-- Empleado
Usuario: empleado1
Contraseña: emp123
```

### 🔧 Configuración

#### Base de Datos
La base de datos incluye:
- ✅ 9 Tablas principales
- ✅ 4 Vistas para reportes
- ✅ 4 Funciones personalizadas
- ✅ 4 Procedimientos almacenados
- ✅ 5 Triggers automáticos
- ✅ Índices optimizados
- ✅ Motor InnoDB

#### Funcionalidades
- 👤 **Autenticación**: Login seguro con roles
- 📦 **Productos**: CRUD completo con categorías
- 👥 **Empleados**: Gestión de personal
- 🏢 **Proveedores**: Administración de proveedores
- 💰 **Ventas**: Punto de venta con cálculos automáticos
- 📊 **Reportes**: Análisis de ventas y productos
- 🔄 **Sincronización**: Datos en tiempo real

### 📁 Estructura del Proyecto

```
TienditaMejorada/
├── index.html              # Página principal
├── database/
│   ├── tiendita_schema.sql  # Script de base de datos
│   └── config.php          # Configuración de conexión
├── api/
│   └── index.php           # API REST endpoints
├── js/
│   ├── database-connector.js # Conector de base de datos
│   ├── app.js              # Lógica principal
│   └── utils.js            # Utilidades
├── css/
│   └── styles.css          # Estilos principales
├── .env                    # Variables de entorno
├── .htaccess              # Configuración de Apache
└── README.md              # Este archivo
```

### 🛠️ Solución de Problemas

#### Error de Conexión a la Base de Datos
1. Verificar que MySQL esté ejecutándose
2. Comprobar credenciales en `.env`
3. Asegurar que la base de datos existe

#### Error 404 en API
1. Verificar que mod_rewrite esté habilitado en Apache
2. Comprobar que `.htaccess` esté en la raíz del proyecto
3. Verificar permisos de archivos

#### Funcionalidades Offline
- El sistema guarda datos en localStorage cuando no hay conexión
- Los datos se sincronizan automáticamente al restaurar conexión

### 📊 Características Técnicas

#### Frontend
- HTML5 semántico
- CSS3 con Flexbox/Grid
- JavaScript ES6+ (async/await)
- Responsive design
- PWA capabilities

#### Backend
- PHP 7.4+ con PDO
- MySQL 5.7+ con InnoDB
- REST API con JSON
- Prepared statements
- Transacciones ACID

#### Seguridad
- Prepared statements (SQL injection)
- CORS configurado
- Headers de seguridad
- Validación de datos
- Sanitización de entradas

### 🔄 Actualizaciones

Para actualizar el sistema:
1. Respaldar la base de datos
2. Reemplazar archivos del proyecto
3. Ejecutar scripts de migración (si los hay)
4. Limpiar cache del navegador

### 📞 Soporte

Si encuentras algún problema:
1. Revisar la consola del navegador (F12)
2. Verificar logs de Apache/PHP
3. Comprobar configuración de la base de datos
4. Asegurar que todos los archivos están presentes

### 🎯 Próximas Características

- [ ] Sistema de inventario automático
- [ ] Notificaciones push
- [ ] Reportes avanzados con gráficos
- [ ] Backup automático
- [ ] Multi-tienda
- [ ] API mobile

---

**¡Sistema TienditaMejorada listo para usar!** 🎉

Desarrollado con ❤️ para pequeños negocios.
