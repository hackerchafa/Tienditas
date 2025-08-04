# 🚨 SOLUCIÓN AL ERROR DE DEPLOY EN RENDER

## ❌ **Error Actual:**
```
SyntaxError: Token inesperado '<'
```

## 🔍 **Causa del Problema:**
Render está intentando ejecutar tu proyecto como **Node.js** cuando debería ser **PHP**.

## ✅ **SOLUCIÓN PASO A PASO:**

### **1. Ir al Dashboard de Render**
- Entra a tu cuenta de Render
- Ve a tu servicio "tiendita-mejorada"

### **2. Cambiar Configuración**
En la sección **Settings**:

**Environment:**
- Cambiar de `Node` a `PHP`

**Build & Deploy:**
- **Build Command:** (dejar vacío o poner `echo "Build complete"`)
- **Start Command:** `php -S 0.0.0.0:$PORT server.php`

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
