# TienditaMejorada

Sistema de gestión de tienda con MySQL y PHP.

## 🚀 Despliegue en Render

Este proyecto está configurado para desplegarse automáticamente en Render.

### Variables de Entorno Requeridas

Configurar estas variables en Render:

```
DB_HOST=tu_host_mysql
DB_PORT=3306
DB_NAME=railway
DB_USER=tu_usuario
DB_PASSWORD=tu_password
APP_ENV=production
APP_DEBUG=false
```

### Configuración de Base de Datos

El proyecto está configurado para usar Railway MySQL. Asegúrate de que tu base de datos esté ejecutando el script `database/railway_setup.sql`.

### Archivos del Proyecto

- `index.html` - Frontend principal
- `api/` - API REST PHP
- `database/` - Scripts de base de datos
- `js/` - JavaScript del frontend
- `css/` - Estilos

### Usuarios por Defecto

- **Admin**: usuario `admin`, contraseña `admin123`
- **Empleado**: usuario `empleado1`, contraseña `emp123`

## 📝 Desarrollo Local

1. Configurar XAMPP/WAMP
2. Configurar variables en `.env`
3. Ejecutar `test-railway.php` para verificar conexión
4. Abrir `index.html`
