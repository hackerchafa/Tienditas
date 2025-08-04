/**
 * Conector JavaScript para TienditaMejorada
 * Integración entre el frontend HTML y la API MySQL
 */

class DatabaseConnector {
    constructor() {
        this.baseURL = './api/'; // Cambiar por la URL de tu API
        this.token = localStorage.getItem('auth_token');
        this.isOnline = navigator.onLine;
        this.setupOfflineDetection();
    }

    /**
     * Configurar detección de conexión
     */
    setupOfflineDetection() {
        window.addEventListener('online', () => {
            this.isOnline = true;
            this.syncOfflineData();
            this.showMessage('Conexión restaurada. Sincronizando datos...', 'success');
        });

        window.addEventListener('offline', () => {
            this.isOnline = false;
            this.showMessage('Sin conexión. Trabajando en modo offline.', 'warning');
        });
    }

    /**
     * Realizar petición HTTP
     */
    async makeRequest(endpoint, method = 'GET', data = null) {
        const config = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        // Agregar token de autorización si existe
        if (this.token) {
            config.headers['Authorization'] = `Bearer ${this.token}`;
        }

        // Agregar datos para POST/PUT
        if (data && (method === 'POST' || method === 'PUT')) {
            config.body = JSON.stringify(data);
        }

        try {
            const response = await fetch(this.baseURL + endpoint, config);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error en petición:', error);
            
            // Si no hay conexión, usar datos locales
            if (!this.isOnline) {
                return this.getOfflineData(endpoint, method, data);
            }
            
            throw error;
        }
    }

    /**
     * Autenticación - Login
     */
    async login(username, password) {
        try {
            const response = await this.makeRequest('auth/login', 'POST', {
                username: username,
                password: password
            });

            if (response.success) {
                this.token = response.token;
                localStorage.setItem('auth_token', this.token);
                localStorage.setItem('current_user', JSON.stringify(response.user));
                return response;
            } else {
                throw new Error(response.error || 'Error de autenticación');
            }
        } catch (error) {
            // Fallback a autenticación local si no hay conexión
            if (!this.isOnline) {
                return this.offlineLogin(username, password);
            }
            throw error;
        }
    }

    /**
     * Autenticación - Registro
     */
    async register(userData) {
        try {
            const response = await this.makeRequest('auth/register', 'POST', userData);
            return response;
        } catch (error) {
            if (!this.isOnline) {
                // Guardar registro para sincronizar después
                this.saveForSync('register', userData);
                throw new Error('Sin conexión. El registro se sincronizará cuando se restaure la conexión.');
            }
            throw error;
        }
    }

    /**
     * Manejar formulario de registro
     */
    async handleRegister(event) {
        if (event) {
            event.preventDefault();
        }

        const form = event ? event.target : document.getElementById('registerFormElement');
        if (!form) {
            console.error('Formulario de registro no encontrado');
            return false;
        }

        const formData = new FormData(form);
        const userData = {
            nombre_completo: formData.get('nombre_completo'),
            usuario: formData.get('usuario'),
            email: formData.get('email'),
            nombre_tienda: formData.get('nombre_tienda'),
            password: formData.get('password')
        };

        // Validaciones
        if (!userData.nombre_completo || !userData.usuario || !userData.email || !userData.password) {
            this.showMessage('Todos los campos son obligatorios', 'error');
            return false;
        }

        if (!DatabaseConnector.validateEmail(userData.email)) {
            this.showMessage('Por favor ingrese un email válido', 'error');
            return false;
        }

        try {
            const response = await this.register(userData);
            if (response.success) {
                this.showMessage('Registro exitoso. Ahora puede iniciar sesión.', 'success');
                form.reset();
                return true;
            } else {
                this.showMessage(response.error || 'Error en el registro', 'error');
                return false;
            }
        } catch (error) {
            this.showMessage('Error: ' + error.message, 'error');
            return false;
        }
    }

    /**
     * Productos - Obtener todos
     */
    async getProducts(filters = {}) {
        try {
            const queryParams = new URLSearchParams(filters).toString();
            const endpoint = 'products' + (queryParams ? '?' + queryParams : '');
            
            const response = await this.makeRequest(endpoint);
            
            // Guardar en localStorage para uso offline
            if (response.products) {
                localStorage.setItem('products_cache', JSON.stringify(response.products));
            }
            
            return response.products || [];
        } catch (error) {
            if (!this.isOnline) {
                // Retornar datos en caché
                const cached = localStorage.getItem('products_cache');
                if (cached) {
                    return JSON.parse(cached);
                }
                // Fallback a datos hardcodeados
                return this.getHardcodedProducts();
            }
            throw error;
        }
    }

    /**
     * Productos - Crear nuevo
     */
    async createProduct(productData) {
        try {
            const response = await this.makeRequest('products', 'POST', productData);
            
            if (response.success) {
                // Actualizar caché local
                this.updateLocalCache('products', productData, 'add');
            }
            
            return response;
        } catch (error) {
            if (!this.isOnline) {
                // Guardar para sincronizar después
                productData.id = 'temp_' + Date.now();
                productData._pendingSync = true;
                this.updateLocalCache('products', productData, 'add');
                this.saveForSync('createProduct', productData);
                return { success: true, product_id: productData.id, offline: true };
            }
            throw error;
        }
    }

    /**
     * Productos - Actualizar
     */
    async updateProduct(productId, productData) {
        try {
            const response = await this.makeRequest(`products/${productId}`, 'PUT', productData);
            
            if (response.success) {
                this.updateLocalCache('products', { id: productId, ...productData }, 'update');
            }
            
            return response;
        } catch (error) {
            if (!this.isOnline) {
                productData._pendingSync = true;
                this.updateLocalCache('products', { id: productId, ...productData }, 'update');
                this.saveForSync('updateProduct', { id: productId, data: productData });
                return { success: true, offline: true };
            }
            throw error;
        }
    }

    /**
     * Empleados - Obtener todos
     */
    async getEmployees() {
        try {
            const response = await this.makeRequest('employees');
            
            if (response.employees) {
                localStorage.setItem('employees_cache', JSON.stringify(response.employees));
            }
            
            return response.employees || [];
        } catch (error) {
            if (!this.isOnline) {
                const cached = localStorage.getItem('employees_cache');
                if (cached) {
                    return JSON.parse(cached);
                }
                return this.getHardcodedEmployees();
            }
            throw error;
        }
    }

    /**
     * Empleados - Crear nuevo
     */
    async createEmployee(employeeData) {
        try {
            const response = await this.makeRequest('employees', 'POST', employeeData);
            
            if (response.success) {
                this.updateLocalCache('employees', employeeData, 'add');
            }
            
            return response;
        } catch (error) {
            if (!this.isOnline) {
                employeeData.id = 'temp_' + Date.now();
                employeeData._pendingSync = true;
                this.updateLocalCache('employees', employeeData, 'add');
                this.saveForSync('createEmployee', employeeData);
                return { success: true, employee_id: employeeData.id, offline: true };
            }
            throw error;
        }
    }

    /**
     * Proveedores - Obtener todos
     */
    async getSuppliers() {
        try {
            const response = await this.makeRequest('suppliers');
            
            if (response.suppliers) {
                localStorage.setItem('suppliers_cache', JSON.stringify(response.suppliers));
            }
            
            return response.suppliers || [];
        } catch (error) {
            if (!this.isOnline) {
                const cached = localStorage.getItem('suppliers_cache');
                if (cached) {
                    return JSON.parse(cached);
                }
                return this.getHardcodedSuppliers();
            }
            throw error;
        }
    }

    /**
     * Ventas - Crear nueva
     */
    async createSale(saleData) {
        try {
            const response = await this.makeRequest('sales', 'POST', saleData);
            
            if (response.success) {
                // Actualizar stock local
                this.updateLocalStock(saleData.productos);
                // Guardar venta en historial local
                this.updateLocalCache('sales', saleData, 'add');
            }
            
            return response;
        } catch (error) {
            if (!this.isOnline) {
                // Procesar venta offline
                saleData.id = 'temp_' + Date.now();
                saleData.fecha_venta = new Date().toISOString();
                saleData.estado = 'pendiente_sync';
                saleData._pendingSync = true;
                
                this.updateLocalStock(saleData.productos);
                this.updateLocalCache('sales', saleData, 'add');
                this.saveForSync('createSale', saleData);
                
                return { 
                    success: true, 
                    venta_id: saleData.id, 
                    offline: true,
                    message: 'Venta procesada offline. Se sincronizará cuando se restaure la conexión.'
                };
            }
            throw error;
        }
    }

    /**
     * Dashboard - Obtener estadísticas
     */
    async getDashboardStats() {
        try {
            const response = await this.makeRequest('dashboard');
            
            if (response.dashboard) {
                localStorage.setItem('dashboard_cache', JSON.stringify(response.dashboard));
            }
            
            return response.dashboard || {};
        } catch (error) {
            if (!this.isOnline) {
                const cached = localStorage.getItem('dashboard_cache');
                if (cached) {
                    return JSON.parse(cached);
                }
                return this.getHardcodedDashboard();
            }
            throw error;
        }
    }

    /**
     * Manejo de datos offline
     */
    getOfflineData(endpoint, method, data) {
        // Mapear endpoints a datos en caché
        const cacheMap = {
            'products': 'products_cache',
            'employees': 'employees_cache',
            'suppliers': 'suppliers_cache',
            'dashboard': 'dashboard_cache'
        };

        const cacheKey = cacheMap[endpoint] || cacheMap[endpoint.split('?')[0]];
        
        if (cacheKey) {
            const cached = localStorage.getItem(cacheKey);
            if (cached) {
                return { [endpoint]: JSON.parse(cached) };
            }
        }

        // Retornar datos hardcodeados como fallback
        return this.getHardcodedData(endpoint);
    }

    /**
     * Login offline usando datos en localStorage
     */
    offlineLogin(username, password) {
        const users = JSON.parse(localStorage.getItem('users') || '{}');
        const user = users[username];
        
        if (user && user.password === password) {
            const response = {
                success: true,
                user: {
                    id: user.id,
                    username: user.username,
                    nombre_completo: user.fullName,
                    email: user.email,
                    rol: user.role,
                    tienda_nombre: user.storeName
                },
                token: 'offline_token_' + Date.now(),
                offline: true
            };
            
            this.token = response.token;
            localStorage.setItem('auth_token', this.token);
            localStorage.setItem('current_user', JSON.stringify(response.user));
            
            return Promise.resolve(response);
        }
        
        return Promise.reject(new Error('Credenciales inválidas (modo offline)'));
    }

    /**
     * Actualizar caché local
     */
    updateLocalCache(type, item, action) {
        const cacheKey = `${type}_cache`;
        let items = JSON.parse(localStorage.getItem(cacheKey) || '[]');
        
        switch (action) {
            case 'add':
                items.push(item);
                break;
            case 'update':
                const index = items.findIndex(i => i.id === item.id);
                if (index !== -1) {
                    items[index] = { ...items[index], ...item };
                }
                break;
            case 'delete':
                items = items.filter(i => i.id !== item.id);
                break;
        }
        
        localStorage.setItem(cacheKey, JSON.stringify(items));
    }

    /**
     * Actualizar stock local después de una venta
     */
    updateLocalStock(productos) {
        const products = JSON.parse(localStorage.getItem('products_cache') || '[]');
        
        productos.forEach(producto => {
            const productIndex = products.findIndex(p => p.id === producto.producto_id);
            if (productIndex !== -1) {
                products[productIndex].stock_actual -= producto.cantidad;
            }
        });
        
        localStorage.setItem('products_cache', JSON.stringify(products));
    }

    /**
     * Guardar datos para sincronizar cuando vuelva la conexión
     */
    saveForSync(action, data) {
        const pendingSync = JSON.parse(localStorage.getItem('pending_sync') || '[]');
        pendingSync.push({
            action: action,
            data: data,
            timestamp: Date.now()
        });
        localStorage.setItem('pending_sync', JSON.stringify(pendingSync));
    }

    /**
     * Sincronizar datos offline cuando vuelve la conexión
     */
    async syncOfflineData() {
        const pendingSync = JSON.parse(localStorage.getItem('pending_sync') || '[]');
        
        if (pendingSync.length === 0) return;
        
        console.log(`Sincronizando ${pendingSync.length} elementos pendientes...`);
        
        for (const item of pendingSync) {
            try {
                switch (item.action) {
                    case 'createProduct':
                        await this.makeRequest('products', 'POST', item.data);
                        break;
                    case 'createEmployee':
                        await this.makeRequest('employees', 'POST', item.data);
                        break;
                    case 'createSale':
                        await this.makeRequest('sales', 'POST', item.data);
                        break;
                    // Agregar más casos según sea necesario
                }
            } catch (error) {
                console.error('Error sincronizando:', error);
            }
        }
        
        // Limpiar datos sincronizados
        localStorage.setItem('pending_sync', '[]');
        
        // Refrescar cachés
        await this.refreshCaches();
        
        this.showMessage('Datos sincronizados exitosamente', 'success');
    }

    /**
     * Refrescar todos los cachés
     */
    async refreshCaches() {
        try {
            await Promise.all([
                this.getProducts(),
                this.getEmployees(),
                this.getSuppliers(),
                this.getDashboardStats()
            ]);
        } catch (error) {
            console.error('Error refrescando cachés:', error);
        }
    }

    /**
     * Datos hardcodeados como fallback
     */
    getHardcodedProducts() {
        return [
            { id: 1, codigo: 'CC600', nombre: 'Coca Cola 600ml', categoria: 'Bebidas', marca: 'Coca Cola', precio_venta: 18.00, stock_actual: 50, stock_minimo: 10 },
            { id: 2, codigo: 'PB001', nombre: 'Pan Bimbo Grande', categoria: 'Panadería', marca: 'Bimbo', precio_venta: 35.00, stock_actual: 30, stock_minimo: 5 },
            { id: 3, codigo: 'LL1000', nombre: 'Leche Lala 1L', categoria: 'Lácteos', marca: 'Lala', precio_venta: 28.00, stock_actual: 40, stock_minimo: 8 },
            { id: 4, codigo: 'SAB45', nombre: 'Sabritas Original 45g', categoria: 'Snacks', marca: 'Sabritas', precio_venta: 12.00, stock_actual: 60, stock_minimo: 10 },
            { id: 5, codigo: 'FAB1000', nombre: 'Fabuloso 1L', categoria: 'Limpieza', marca: 'Fabuloso', precio_venta: 45.00, stock_actual: 25, stock_minimo: 3 }
        ];
    }

    getHardcodedEmployees() {
        return [
            { id: 'emp_1', username: 'empleado1', nombre_completo: 'Ana García López', email: 'ana.garcia@tienda.com', telefono: '555-0101', estado: 'activo' },
            { id: 'emp_2', username: 'empleado2', nombre_completo: 'Carlos Rodríguez', email: 'carlos.rodriguez@tienda.com', telefono: '555-0102', estado: 'activo' }
        ];
    }

    getHardcodedSuppliers() {
        return [
            { id: 'sup_1', empresa: 'Distribuidora Central S.A.', persona_contacto: 'María Elena Vásquez', telefono: '555-2001', email: 'ventas@distribuidoracentral.com', estado: 'activo' },
            { id: 'sup_2', empresa: 'Panadería Artesanal El Trigo', persona_contacto: 'Roberto Martínez', telefono: '555-2002', email: 'pedidos@panaderiaeltrigo.com', estado: 'activo' }
        ];
    }

    getHardcodedDashboard() {
        return {
            total_productos: 5,
            productos_stock_bajo: 1,
            ventas_hoy: 3,
            total_ventas_hoy: 180.00,
            empleados_activos: 2
        };
    }

    /**
     * Mostrar mensaje al usuario
     */
    showMessage(message, type = 'info') {
        // Esta función debe estar disponible en el contexto global
        if (typeof window.authSystem !== 'undefined' && window.authSystem.showMessage) {
            window.authSystem.showMessage(message, type);
        } else {
            console.log(`${type.toUpperCase()}: ${message}`);
        }
    }

    /**
     * Cerrar sesión
     */
    async logout() {
        try {
            if (this.isOnline && this.token) {
                await this.makeRequest('auth/logout', 'DELETE');
            }
        } catch (error) {
            console.error('Error en logout:', error);
        } finally {
            this.token = null;
            localStorage.removeItem('auth_token');
            localStorage.removeItem('current_user');
        }
    }

    /**
     * Método estático para validar email
     */
    static validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    /**
     * Método estático para manejar registros
     */
    static handleRegister(event) {
        if (event) {
            event.preventDefault();
        }
        
        if (window.dbConnector && typeof window.dbConnector.handleRegister === 'function') {
            return window.dbConnector.handleRegister(event);
        } else {
            console.error('DatabaseConnector no está disponible');
            return false;
        }
    }
}

// Crear instancia global del conector
window.dbConnector = new DatabaseConnector();

// Exportar para uso en módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DatabaseConnector;
}
