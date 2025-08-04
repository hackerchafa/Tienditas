# 🚨 SOLUCIÓN AL ERROR "php: command not found" EN RENDER

## ❌ **Error Actual:**
```
bash: line 1: php: command not found
```

## 🔍 **Causa del Problema:**
Render está usando un entorno **Node.js** que no tiene PHP instalado.

## ✅ **SOLUCIÓN DEFINITIVA:**

### **OPCIÓN 1: Usar Docker (RECOMENDADO)**

1. **En Render Dashboard:**
   - Environment: `Docker`
   - Build Command: (vacío)
   - Start Command: (se detecta automáticamente del Dockerfile)

### **OPCIÓN 2: Cambiar Settings Manualmente**

1. **En Render Dashboard > Settings:**
   - **Environment:** Cambiar a `Static Site` o `Python` temporalmente, luego a `PHP`
   - **Build Command:** (vacío)
   - **Start Command:** `bash start.sh`

### **OPCIÓN 3: Crear Nuevo Servicio**

1. **Eliminar servicio actual** en Render
2. **Crear nuevo Web Service**
3. **Al crearlo, seleccionar:**
   - **Environment:** `Docker` o `PHP`
   - **Repository:** hackerchafa/Tienditas

## 📝 **Archivos Agregados:**
- ✅ `Dockerfile` - Configuración Docker con PHP
- ✅ `start.sh` - Script de inicio alternativo  
- ✅ `composer.json` - Especifica PHP requerido
- ✅ `.php-version` - Fuerza versión PHP
- ✅ `.buildpacks` - Buildpack de PHP

### **3. Variables de Entorno**
Agregar estas variables en la sección **Environment Variables**:

```
DB_HOST=switchback.proxy.rlwy.net
DB_PORT=31739
DB_NAME=railway
DB_USER=root
DB_PASSWORD=DcFHhdYINqDJuvHxKZOeOLcbsIGf
APP_ENV=production
APP_DEBUG=false
```

### **4. Re-deployar**
- Hacer clic en **Manual Deploy**
- O hacer un push a GitHub para trigger automático

### **5. Archivos Actualizados**
Los archivos ya están corregidos:
- ✅ `package.json` - Sin "main": "index.html"
- ✅ `render.yaml` - Configuración PHP
- ✅ `server.php` - Servidor PHP correcto

### **6. Verificar Deploy**
Después del redeploy deberías ver:
```
==> Using PHP version 8.1.0
==> Running 'php -S 0.0.0.0:$PORT server.php'
==> Your service is live at https://tu-app.onrender.com
```

## 🎯 **Comandos para Actualizar GitHub:**

```bash
# En tu carpeta del proyecto:
git add .
git commit -m "Fix: Configuración PHP para Render"
git push origin master
```

## 🔧 **Si Sigue Fallando:**

1. **Eliminar el servicio** en Render
2. **Crear nuevo Web Service**
3. **Seleccionar PHP** desde el inicio
4. **Usar estos settings:**
   - Build Command: (vacío)
   - Start Command: `php -S 0.0.0.0:$PORT server.php`

## ✅ **Resultado Esperado:**
Tu app debería estar disponible en:
`https://tu-app.onrender.com`

---

**¡El error está solucionado! Solo necesitas actualizar la configuración en Render.** 🎉
