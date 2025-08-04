# 🚀 GUÍA COMPLETA PARA DESPLEGAR EN RENDER

## 📋 **Paso a Paso para GitHub + Render**

### **1. Subir a GitHub**

```bash
# En tu carpeta TienditaMejorada, ejecutar:

# Inicializar repositorio git
git init

# Agregar todos los archivos (excepto los del .gitignore)
git add .

# Hacer el primer commit
git commit -m "Sistema TienditaMejorada - Primera versión"

# Conectar con tu repositorio de GitHub
git remote add origin https://github.com/TU_USUARIO/tiendita-mejorada.git

# Subir los archivos
git push -u origin main
```

### **2. Configurar en Render**

1. **Ir a [render.com](https://render.com)**
2. **Conectar tu cuenta de GitHub**
3. **Crear nuevo Web Service**
4. **Seleccionar tu repositorio: `tiendita-mejorada`**

### **3. Configuración del Servicio en Render**

**IMPORTANTE: Configurar como PHP Web Service, NO como Node.js**

**Build & Deploy:**
- **Environment:** `PHP`
- **Build Command:** (dejar vacío o poner: `echo "No build required"`)
- **Start Command:** `php -S 0.0.0.0:$PORT server.php`
- **Auto-Deploy:** `Yes`

**Si aparece error "Token inesperado '<'":**
- Verificar que está seleccionado **PHP** como runtime
- El start command debe ser: `php -S 0.0.0.0:$PORT server.php`
- NO debe intentar ejecutar Node.js

**Environment Variables (CRÍTICO):**
```
DB_HOST=switchback.proxy.rlwy.net
DB_PORT=31739
DB_NAME=railway
DB_USER=root
DB_PASSWORD=DcFHhdYINqDJuvHxKZOeOLcbsIGf
APP_ENV=production
APP_DEBUG=false
```

### **4. Variables de Entorno Detalladas**

Copiar exactamente estas variables en Render:

| Variable | Valor |
|----------|-------|
| `DB_HOST` | `switchback.proxy.rlwy.net` |
| `DB_PORT` | `31739` |
| `DB_NAME` | `railway` |
| `DB_USER` | `root` |
| `DB_PASSWORD` | `DcFHhdYINqDJuvHxKZOeOLcbsIGf` |
| `APP_ENV` | `production` |
| `APP_DEBUG` | `false` |

### **5. Verificar Base de Datos**

Antes del despliegue, asegurar que Railway tenga las tablas:

```sql
-- Ejecutar en Railway:
-- Contenido de database/railway_setup.sql
```

### **6. URLs del Proyecto**

Después del despliegue tendrás:

- **Aplicación:** `https://tu-app.onrender.com`
- **API:** `https://tu-app.onrender.com/api/auth/login`
- **Login:** `admin` / `admin123`

### **7. Archivos Clave Creados**

- ✅ `server.php` - Servidor principal para Render
- ✅ `.gitignore` - Protege archivos sensibles
- ✅ `package.json` - Configuración del proyecto
- ✅ `render.yaml` - Configuración de Render
- ✅ Config actualizado - Usa variables de entorno

### **8. Comandos Git Útiles**

```bash
# Para actualizar el proyecto después de cambios:
git add .
git commit -m "Descripción de cambios"
git push origin main

# Render se actualizará automáticamente
```

### **9. Troubleshooting**

**Si hay errores:**

1. **Revisar logs en Render Dashboard**
2. **Verificar variables de entorno**
3. **Confirmar que Railway está funcionando**
4. **Verificar que todas las tablas existen**

### **10. Testing**

Una vez desplegado, probar:

- ✅ Página principal carga
- ✅ Login funciona (admin/admin123)
- ✅ Productos se muestran
- ✅ API responde

---

## 🎯 **Resumen de Acciones**

1. **Subir a GitHub** con los archivos preparados
2. **Crear Web Service** en Render
3. **Configurar variables** de entorno
4. **Verificar base de datos** Railway
5. **Desplegar y probar**

**¡Tu TienditaMejorada estará disponible 24/7 en la web!** 🎉
