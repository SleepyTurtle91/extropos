// Appwrite client
let client;
let databases;
let isConnected = false;

// Configuration
let config = {
    endpoint: 'http://localhost:8080',
    projectId: '689965770017299bd5a5',
    apiKey: 'standard_efb1a582dc22a5a476b13e2f36fccbbc7c48f88c3cfc8c60cc9c09a2ba49a2cacc644ecdd91ef618368804ac5db846d05f831e42b5c46d145faa682d2dfbe1e33ada0bba8b37548f8109ee504f86e7b89d672d15fa74fc8de7da580f1961e2a9acdedfccb38125bc9c506075ee9e1dde5678a5e6fd7fc107b1f3d6bae37b4456'
};

// Use proxy to bypass CORS
const USE_PROXY = true;
const PROXY_URL = 'http://localhost:9000/proxy';

function showGlobalAlert(message, type = 'info') {
    const container = document.getElementById('globalAlert');
    if (!container) return;
    const typeClass = type === 'error' ? 'alert-error' : type === 'success' ? 'alert-success' : 'alert-info';
    container.innerHTML = `<div class="alert ${typeClass}">${message}</div>`;
}

function clearGlobalAlert() {
    const container = document.getElementById('globalAlert');
    if (container) container.innerHTML = '';
}

function buildUrl(path) {
    const normalized = path.startsWith('/') ? path : `/${path}`;
    return USE_PROXY 
        ? `${PROXY_URL}?path=${encodeURIComponent(normalized)}`
        : `${config.endpoint}${normalized}`;
}

async function apiFetch(path, options = {}) {
    const url = buildUrl(path);
    const mergedHeaders = {
        'X-Appwrite-Project': config.projectId,
        'X-Appwrite-Key': config.apiKey,
        ...options.headers
    };

    try {
        const response = await fetch(url, { ...options, headers: mergedHeaders });
        if (!response.ok && response.status === 0) {
            throw new Error('Network error');
        }
        clearGlobalAlert();
        return response;
    } catch (error) {
        showGlobalAlert(`Proxy/connection error: ${error.message}`, 'error');
        throw error;
    }
}

async function createCollection(dbId, collectionId, name) {
    const resp = await apiFetch(`/v1/databases/${dbId}/collections`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            collectionId,
            name,
            permissions: [
                'read("any")',
                'write("any")',
                'create("any")',
                'update("any")',
                'delete("any")'
            ]
        })
    });

    if (!resp.ok) {
        const err = await resp.json().catch(() => ({}));
        throw new Error(err.message || `Failed to create collection ${collectionId}`);
    }
}

async function ensureAdminVault() {
    // Create admin database (id: admin)
    const dbResp = await apiFetch('/v1/databases', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ databaseId: 'admin', name: 'Admin' })
    });
    if (!(dbResp.status === 200 || dbResp.status === 201 || dbResp.status === 202 || dbResp.status === 409)) {
        const err = await dbResp.json().catch(() => ({}));
        throw new Error(err.message || 'Failed to create admin database');
    }

    // Create tenants_vault collection
    const colResp = await apiFetch('/v1/databases/admin/collections', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            collectionId: 'tenants_vault',
            name: 'Tenants Vault',
            permissions: [
                'read("any")',
                'write("any")',
                'create("any")',
                'update("any")',
                'delete("any")'
            ]
        })
    });
    if (!(colResp.status === 200 || colResp.status === 201 || colResp.status === 202 || colResp.status === 409)) {
        const err = await colResp.json().catch(() => ({}));
        throw new Error(err.message || 'Failed to create tenants vault');
    }
}

async function saveTenantToVault(tenantName, dbId, apiKeySecret) {
    await ensureAdminVault();

    const payload = {
        documentId: dbId,
        data: {
            tenantName,
            databaseId: dbId,
            apiKey: apiKeySecret,
            createdAt: new Date().toISOString()
        }
    };

    const createResp = await apiFetch('/v1/databases/admin/collections/tenants_vault/documents', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });

    if (createResp.status === 409) {
        // Document exists, update instead
        const patchResp = await apiFetch(`/v1/databases/admin/collections/tenants_vault/documents/${dbId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ data: payload.data })
        });
        if (!patchResp.ok) {
            const err = await patchResp.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to update tenant vault entry');
        }
    } else if (!createResp.ok) {
        const err = await createResp.json().catch(() => ({}));
        throw new Error(err.message || 'Failed to save tenant credentials');
    }
}

async function fetchTenantFromVault(dbId) {
    await ensureAdminVault();
    const resp = await apiFetch(`/v1/databases/admin/collections/tenants_vault/documents/${dbId}`);
    if (!resp.ok) {
        const err = await resp.json().catch(() => ({}));
        throw new Error(err.message || 'Credentials not found');
    }
    return resp.json();
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadStoredSettings();
    initializeAppwrite();
    setupMenuHandlers();
});

// Load settings from localStorage
function loadStoredSettings() {
    const stored = localStorage.getItem('appwriteConfig');
    if (stored) {
        config = JSON.parse(stored);
        document.getElementById('endpoint').value = config.endpoint;
        document.getElementById('projectId').value = config.projectId;
        document.getElementById('apiKey').value = config.apiKey;
    }
}

// Initialize Appwrite client
function initializeAppwrite() {
    try {
        client = new Appwrite.Client()
            .setEndpoint(config.endpoint)
            .setProject(config.projectId);

        databases = new Appwrite.Databases(client);
        
        updateConnectionStatus(true);
        console.log('Appwrite initialized successfully');
    } catch (error) {
        console.error('Failed to initialize Appwrite:', error);
        updateConnectionStatus(false);
    }
}

// Update connection status
function updateConnectionStatus(connected) {
    isConnected = connected;
    const indicator = document.getElementById('statusIndicator');
    const text = document.getElementById('statusText');
    
    if (connected) {
        indicator.classList.add('connected');
        text.textContent = 'Connected';
    } else {
        indicator.classList.remove('connected');
        text.textContent = 'Not Connected';
    }
}

// Test connection
async function testConnection() {
    const alertDiv = document.getElementById('settingsAlert');
    alertDiv.innerHTML = '';
    
    try {
        const response = await apiFetch('/v1/databases', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
            mode: 'cors'
        });

        const data = await response.text();
        
        // Check if we got HTML error page (domain routing issue)
        if (data.includes('<!DOCTYPE html>')) {
            updateConnectionStatus(false);
            alertDiv.innerHTML = `
                <div class="alert alert-error">
                    ❌ Appwrite domain configuration issue detected<br><br>
                    <strong>The Appwrite server is rejecting requests due to domain validation.</strong><br><br>
                    <strong>Workaround:</strong><br>
                    1. Use the Flutter Backend app instead (if on Windows/macOS)<br>
                    2. OR install Appwrite CLI to manage data<br>
                    3. OR access Appwrite console directly (if available)<br><br>
                    <strong>Technical Details:</strong><br>
                    Appwrite is configured to only accept requests from specific domains.
                    The web backend at localhost:8000 is being rejected.
                </div>
            `;
            return;
        }

        if (response.ok) {
            updateConnectionStatus(true);
            alertDiv.innerHTML = '<div class="alert alert-success">✅ Connection successful!</div>';
        } else {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
    } catch (error) {
        updateConnectionStatus(false);
        
        let errorMessage = error.message;
        let technicalHelp = '';
        
        if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
            errorMessage = 'Cannot reach Appwrite server';
            technicalHelp = `
                <br><br><strong>Possible causes:</strong><br>
                • Appwrite is not running (check: docker ps | grep appwrite)<br>
                • CORS blocking browser requests<br>
                • Wrong endpoint URL<br>
                • Firewall blocking connection
            `;
        }
        
        alertDiv.innerHTML = `
            <div class="alert alert-error">
                ❌ Connection failed: ${errorMessage}${technicalHelp}
            </div>
        `;
    }
}

// Save settings
function saveSettings() {
    config.endpoint = document.getElementById('endpoint').value.trim();
    config.projectId = document.getElementById('projectId').value.trim();
    config.apiKey = document.getElementById('apiKey').value.trim();
    
    localStorage.setItem('appwriteConfig', JSON.stringify(config));
    
    // Reinitialize Appwrite with new settings
    initializeAppwrite();
    
    const alertDiv = document.getElementById('settingsAlert');
    alertDiv.innerHTML = '<div class="alert alert-success">Settings saved successfully!</div>';
    
    setTimeout(() => {
        alertDiv.innerHTML = '';
    }, 3000);
}

// Setup menu navigation
function setupMenuHandlers() {
    const menuItems = document.querySelectorAll('.menu-item');
    const sections = document.querySelectorAll('.section');
    
    menuItems.forEach(item => {
        item.addEventListener('click', () => {
            // Remove active class from all items
            menuItems.forEach(mi => mi.classList.remove('active'));
            sections.forEach(sec => sec.classList.remove('active'));
            
            // Add active class to clicked item
            item.classList.add('active');
            
            // Show corresponding section
            const sectionId = item.getAttribute('data-section');
            document.getElementById(sectionId).classList.add('active');
            
            // Load data for specific sections
            if (sectionId === 'dashboard') loadDashboard();
            if (sectionId === 'categories') loadCategories();
            if (sectionId === 'products') loadProducts();
            if (sectionId === 'counters') loadCounters();
            if (sectionId === 'tenants') loadTenants();
        });
    });
}

// Load dashboard data
async function loadDashboard() {
    showLoading();
    
    try {
        const response = await apiFetch('/v1/databases');
        
        if (response.ok) {
            const data = await response.json();
            document.getElementById('totalTenants').textContent = data.total || 0;
        }
        
        // You can add more stats here
        document.getElementById('totalCategories').textContent = '0';
        document.getElementById('totalProducts').textContent = '0';
        document.getElementById('totalUsers').textContent = '0';
        
    } catch (error) {
        console.error('Failed to load dashboard:', error);
    } finally {
        hideLoading();
    }
}

// Create tenant database
async function createTenant() {
    const tenantName = document.getElementById('tenantName').value.trim();
    
    if (!tenantName) {
        alert('Please enter a tenant name');
        return;
    }
    
    showLoading();
    
    try {
        // Generate unique database ID
        const dbId = 'tenant_' + Date.now();
        
        const response = await apiFetch('/v1/databases', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                databaseId: dbId,
                name: tenantName
            })
        });
        
        if (response.ok) {
            alert(`Tenant database created successfully!\nDatabase ID: ${dbId}`);
            closeModal('tenantModal');
            loadTenants();
        } else {
            const error = await response.json();
            throw new Error(error.message || 'Failed to create tenant');
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    } finally {
        hideLoading();
    }
}

// Load tenants
async function loadTenants() {
    showLoading();
    
    try {
        const response = await apiFetch('/v1/databases');
        
        if (response.ok) {
            const data = await response.json();
            const tbody = document.querySelector('#tenantsTable tbody');
            tbody.innerHTML = '';
            
            if (data.databases && data.databases.length > 0) {
                data.databases.forEach(db => {
                    const row = `
                        <tr>
                            <td>${db.$id}</td>
                            <td>${db.name}</td>
                            <td>${new Date(db.$createdAt).toLocaleDateString()}</td>
                            <td>
                                <button class="btn btn-secondary" onclick="viewTenantCredentials('${db.$id}')">Credentials</button>
                                <button class="btn btn-danger" onclick="deleteTenant('${db.$id}')">Delete</button>
                            </td>
                        </tr>
                    `;
                    tbody.innerHTML += row;
                });
            } else {
                tbody.innerHTML = '<tr><td colspan="4">No tenants found</td></tr>';
            }
        }
    } catch (error) {
        console.error('Failed to load tenants:', error);
    } finally {
        hideLoading();
    }
}

// Delete tenant
async function deleteTenant(dbId) {
    if (!confirm(`Are you sure you want to delete tenant database: ${dbId}?`)) {
        return;
    }
    
    showLoading();
    
    try {
        const response = await apiFetch(`/v1/databases/${dbId}`, {
            method: 'DELETE',
        });
        
        if (response.ok) {
            alert('Tenant deleted successfully');
            loadTenants();
        } else {
            throw new Error('Failed to delete tenant');
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    } finally {
        hideLoading();
    }
}

// Load counters (placeholder)
function loadCounters() {
    const tbody = document.querySelector('#countersTable tbody');
    tbody.innerHTML = '<tr><td colspan="5">Select a tenant database first</td></tr>';
}

// Create counter (placeholder)
function createCounter() {
    alert('Please select a tenant database first from the Tenants section');
    closeModal('counterModal');
}

// Business info functions
function loadBusinessInfo() {
    const alertDiv = document.getElementById('businessAlert');
    alertDiv.innerHTML = '<div class="alert alert-info">Select a tenant database to load business information</div>';
}

function saveBusinessInfo() {
    const alertDiv = document.getElementById('businessAlert');
    alertDiv.innerHTML = '<div class="alert alert-success">Business information saved!</div>';
}

// Modal functions
function showModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

// Loading functions
function showLoading() {
    document.getElementById('loading').style.display = 'block';
}

function hideLoading() {
    document.getElementById('loading').style.display = 'none';
}

async function viewTenantCredentials(dbId) {
    const modal = document.getElementById('tenantCredsModal');
    const body = document.getElementById('tenantCredsBody');
    body.innerHTML = '';

    showLoading();
    try {
        const doc = await fetchTenantFromVault(dbId);
        const data = doc.data || {};
        body.innerHTML = `
            <div class="alert alert-info">
                <strong>Tenant Name:</strong> ${data.tenantName || '-'}<br>
                <strong>Database ID:</strong> ${data.databaseId || '-'}<br>
                <strong>API Key:</strong><br>
                <code>${data.apiKey || '-'}</code>
                <br><br>
                Endpoint: ${config.endpoint}<br>
                Project ID: ${config.projectId}
            </div>
        `;
        modal.classList.add('active');
    } catch (error) {
        body.innerHTML = `<div class="alert alert-error">❌ ${error.message}</div>`;
        modal.classList.add('active');
    } finally {
        hideLoading();
    }
}

async function provisionTenant() {
    const tenantName = document.getElementById('tenantName').value.trim();
    const resultDiv = document.getElementById('tenantProvisionResult');
    resultDiv.innerHTML = '';

    if (!tenantName) {
        alert('Please enter a tenant name');
        return;
    }

    showLoading();

    try {
        const dbId = 'tenant_' + Date.now();

        // 1) Create database
        const dbResp = await apiFetch('/v1/databases', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ databaseId: dbId, name: tenantName })
        });

        if (!dbResp.ok) {
            const err = await dbResp.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to create tenant database');
        }

        // 2) Provision core collections
        const collections = [
            { id: 'categories', name: 'Categories' },
            { id: 'products', name: 'Products' },
            { id: 'modifiers', name: 'Modifiers' },
            { id: 'orders', name: 'Orders' },
            { id: 'users', name: 'Users' },
            { id: 'counters', name: 'POS Counters' },
        ];

        for (const col of collections) {
            await createCollection(dbId, col.id, col.name);
        }

        // 3) Generate tenant-scoped API key
        const keyResp = await apiFetch(`/v1/projects/${config.projectId}/keys`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: `${tenantName} Tenant Key`,
                scopes: [
                    'databases.read',
                    'databases.write',
                    'collections.read',
                    'collections.write',
                    'documents.read',
                    'documents.write'
                ]
            })
        });

        if (!keyResp.ok) {
            const err = await keyResp.json().catch(() => ({}));
            throw new Error(err.message || 'Failed to create tenant API key');
        }

        const keyData = await keyResp.json();

        // 4) Save to vault
        await saveTenantToVault(tenantName, dbId, keyData.secret || '');

        resultDiv.innerHTML = `
            <div class="alert alert-success">
                ✅ Tenant provisioned.<br><br>
                <strong>Tenant DB ID:</strong> ${dbId}<br>
                <strong>API Key ID:</strong> ${keyData.$id || 'generated'}<br>
                <strong>API Key Secret (save now):</strong><br>
                <code>${keyData.secret || ''}</code>
                <br><br>
                Collections created: categories, products, modifiers, orders, users, counters.<br><br>
                Use these in the POS client for this tenant:<br>
                • Endpoint: ${config.endpoint}<br>
                • Project ID: ${config.projectId}<br>
                • Database ID: ${dbId}<br>
                • API Key: ${keyData.secret || ''}
            </div>
        `;

        loadTenants();
    } catch (error) {
        resultDiv.innerHTML = `<div class="alert alert-error">❌ ${error.message}</div>`;
    } finally {
        hideLoading();
    }
}
