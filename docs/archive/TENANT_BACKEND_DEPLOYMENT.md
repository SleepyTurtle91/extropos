# ExtroPOS Tenant Backend - Deployment Guide

## Overview

The Tenant Backend Access is a web-only application that allows restaurant owners (tenants) to log in and manage their POS system data remotely.

## Features

- **Tenant Authentication**: Login with registered email

- **Tenant-Specific Data**: Each tenant only sees their own data

- **Management Dashboard**: Access to categories, products, modifiers, counters, and licenses

- **Customer Information**: View associated customer details

- **Secure Access**: Email-based authentication with database validation

## Architecture

```text
┌─────────────────────────────────────────────────────┐
│            Tenant Backend (Web Only)                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. Tenant Login Screen (Entry Point)              │
│     ↓                                               │
│  2. Email Authentication                            │
│     ↓                                               │
│  3. Tenant Backend Home                             │
│     - Categories Management                         │

│     - Products Management                           │

│     - Modifiers Management                          │

│     - Registered Counters                           │

│     - License Generation                            │

│     - Business Settings                             │

│                                                     │
└─────────────────────────────────────────────────────┘

```

## Prerequisites

1. **Database Setup**: Ensure SQLite database is initialized
2. **Customer Registration**: Customers must be registered in dealer portal
3. **Tenant Creation**: Tenant databases must be created via dealer portal

## Build & Deploy

### Local Development

```bash

# Build the backend web app

flutter build web --no-tree-shake-icons -t lib/main_backend.dart


# Serve locally with Python

cd build/web && python3 -m http.server 8080


# Or serve with PHP

cd build/web && php -S localhost:8080


# Access at: http://localhost:8080

```

### Using Deployment Script

```bash

# Run the automated deployment script

./deploy_backend.sh


# Follow the on-screen instructions

```

## Deployment to Production

### Option 1: Apache Server

1. **Build the app**:

   ```bash
   flutter build web --no-tree-shake-icons -t lib/main_backend.dart
   ```

2. **Copy to web server**:

   ```bash
   sudo cp -r build/web/* /var/www/html/tenant-backend/
   ```

3. **Configure Apache** (`/etc/apache2/sites-available/tenant-backend.conf`):

   ```apache
   <VirtualHost *:80>
       ServerName tenant.yourdomain.com
       DocumentRoot /var/www/html/tenant-backend
       
       <Directory /var/www/html/tenant-backend>
           Options -Indexes +FollowSymLinks
           AllowOverride All
           Require all granted
           
           # Enable SPA routing

           RewriteEngine On
           RewriteBase /
           RewriteRule ^index\.html$ - [L]
           RewriteCond %{REQUEST_FILENAME} !-f
           RewriteCond %{REQUEST_FILENAME} !-d
           RewriteRule . /index.html [L]
       </Directory>
   </VirtualHost>
   ```

4. **Enable and restart**:

   ```bash
   sudo a2ensite tenant-backend
   sudo systemctl reload apache2
   ```

### Option 2: Nginx Server

1. **Build the app** (same as above)

2. **Copy to web server**:

   ```bash
   sudo cp -r build/web/* /usr/share/nginx/html/tenant-backend/
   ```

3. **Configure Nginx** (`/etc/nginx/sites-available/tenant-backend`):

   ```nginx
   server {
       listen 80;
       server_name tenant.yourdomain.com;
       root /usr/share/nginx/html/tenant-backend;
       index index.html;
       
       location / {
           try_files $uri $uri/ /index.html;
       }
       
       # Cache static assets

       location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
           expires 1y;
           add_header Cache-Control "public, immutable";
       }
   }
   ```

4. **Enable and restart**:

   ```bash
   sudo ln -s /etc/nginx/sites-available/tenant-backend /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

### Option 3: Firebase Hosting

1. **Install Firebase CLI**:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize Firebase**:

   ```bash
   firebase init hosting
   # Select build/web as public directory

   # Configure as single-page app: Yes

   ```

3. **Deploy**:

   ```bash
   flutter build web --no-tree-shake-icons -t lib/main_backend.dart
   firebase deploy --only hosting
   ```

### Option 4: GitHub Pages

1. **Build with base href**:

   ```bash
   flutter build web --no-tree-shake-icons -t lib/main_backend.dart --base-href /tenant-backend/
   ```

2. **Push to GitHub** (gh-pages branch or docs/ folder)

3. **Configure in repository settings**

## Database Configuration

The backend uses SQLite for tenant management. Ensure the following tables exist:

- `dealer_customers` - Customer registration data

- `tenants` - Tenant-customer associations

- Foreign key: `tenants.customer_id` → `dealer_customers.id`

## Usage Flow

### For Dealers (Setup)

1. Register customers in dealer portal
2. Create tenant databases via tenant onboarding
3. Provide tenant email to restaurant owner

### For Tenants (Daily Use)

1. Open tenant backend URL
2. Enter registered email address
3. Click "Sign In"
4. Access management dashboard
5. Manage categories, products, modifiers, etc.

## Testing

### Test Tenant Login

1. **Register a test customer**:

   - Open dealer portal

   - Go to "Customer Registration"

   - Fill in customer details

   - Save customer

2. **Create tenant database**:

   - Go to "Tenant Onboarding"

   - Select the registered customer

   - Create tenant database

3. **Test login**:

   - Open tenant backend

   - Enter customer email

   - Verify successful login

   - Check tenant home screen displays

## Security Considerations

- ✅ Email-based authentication

- ✅ Tenant-customer isolation in database

- ✅ Active status validation

- ✅ HTTPS recommended for production

- ⚠️ Consider adding password authentication

- ⚠️ Consider adding session management

- ⚠️ Consider adding 2FA for enhanced security

## Troubleshooting

### Issue: "No tenant found with this email"

**Solution**: Ensure tenant database was created via dealer portal tenant onboarding

### Issue: "This tenant account is inactive"

**Solution**: Check tenant status in database, reactivate if needed

### Issue: Database not found

**Solution**: Ensure SQLite database is initialized in web environment

### Issue: CORS errors

**Solution**: Configure proper CORS headers on web server

## Support

For issues or questions:

- Check logs in browser console (F12)

- Verify database tables exist

- Ensure customer and tenant records are properly linked

- Contact dealer portal administrator

## Version

- **Current Version**: 1.0.14

- **Last Updated**: December 11, 2025

- **Platform**: Web Only (Flutter Web)
