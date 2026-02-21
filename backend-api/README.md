# FlutterPOS Super Admin Backend API

This is the backend API service for Super Admin operations in FlutterPOS, specifically handling tenant database management.

## Overview

The Super Admin API provides secure endpoints for privileged operations that require elevated access, such as initiating database maintenance and backup processes for specific tenants.

## Features

- **Tenant Database Access**: Initiate maintenance access for tenant databases

- **Security**: JWT token authentication with API key fallback, rate limiting, audit logging

- **Health Monitoring**: Health check endpoints

- **Docker Support**: Containerized deployment with Traefik integration

## API Endpoints

### Health Check

```http
GET /health

```

Returns server health status.

### Authentication

#### Login

```http
POST /api/v1/auth/login

```

Authenticates super admin and returns JWT token.

**Request Body**:

```json
{
  "apiKey": "your-super-admin-api-key"
}

```

**Success Response (200 OK)**:

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h",
  "user": {
    "userId": "super-admin-user",
    "role": "super-admin"
  }
}

```

### Tenant Database Access

```http
POST /api/v1/superadmin/tenant/{tenantId}/db-access

```

Initiates database maintenance access for a specific tenant.

**Authentication**: Required (Authorization: Bearer {jwt-token} or X-API-Key header)

**Request Body**:

```json
{
  "action": "INITIATE_MAINTENANCE_ACCESS",
  "timestamp": "2025-12-15T01:50:00.000Z"
}

```

**Success Response (202 Accepted)**:

```json
{
  "status": "processing",
  "message": "Database maintenance initiation request accepted.",
  "requestId": "req_1734227400000_abc123def"
}

```

**Error Responses**:

- `403 Forbidden`: Super Admin authentication failed

- `503 Service Unavailable`: DB Ops service unavailable

## Security

### Authentication Methods

- **JWT Token Authentication**: Primary authentication method using Bearer tokens

- **API Key Fallback**: Backward compatibility with X-API-Key header

- **Login Endpoint**: `/api/v1/auth/login` to obtain JWT tokens using API key

- **Token Expiry**: JWT tokens expire after 24 hours

- Configured via `SUPER_ADMIN_API_KEY` and `JWT_SECRET` environment variables

### IP Restrictions (CIDR)

- CIDR-based IP whitelisting to restrict access to trusted networks

- Configured via `ALLOWED_CIDRS` environment variable

- Default ranges: `192.168.0.0/24,10.0.0.0/8,172.16.0.0/12` (private networks)

- Health endpoint (`/health`) is exempt from IP restrictions

### Rate Limiting

- 100 requests per 15-minute window per IP

- Applied to all `/api/v1/superadmin/*` endpoints

### Audit Logging

- All API access is logged with user ID, tenant ID, timestamp, and action

- Logs stored in `logs/` directory

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3001` |
| `NODE_ENV` | Environment | `production` |
| `SUPER_ADMIN_API_KEY` | API key for login authentication | Required |
| `JWT_SECRET` | Secret key for JWT token signing | Required |
| `ALLOWED_ORIGINS` | CORS allowed origins | `https://backend.extropos.org,https://appwrite.extropos.org` |
| `ALLOWED_CIDRS` | Comma-separated CIDR ranges for IP restrictions | `192.168.0.0/24,10.0.0.0/8,172.16.0.0/12` |
| `LOG_LEVEL` | Logging level | `info` |

## Development

### Local Development

```bash
cd backend-api
npm install
npm run dev

```

### Docker Build

```bash
docker build -t flutterpos-super-admin-api .

```

### Testing

```bash

# Health check

curl http://localhost:3001/health


# Login to get JWT token

curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"apiKey": "your-super-admin-api-key"}'


# API test with JWT token

curl -X POST http://localhost:3001/api/v1/superadmin/tenant/test-tenant/db-access \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-jwt-token" \
  -d '{"action": "INITIATE_MAINTENANCE_ACCESS", "timestamp": "2025-12-15T01:50:00.000Z"}'


# API test with API key (fallback)

curl -X POST http://localhost:3001/api/v1/superadmin/tenant/test-tenant/db-access \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"action": "INITIATE_MAINTENANCE_ACCESS", "timestamp": "2025-12-15T01:50:00.000Z"}'

```

## Deployment

The service is deployed as part of the FlutterPOS Docker Compose stack:

```bash
cd docker
docker-compose up -d super-admin-api

```

## Architecture

### Request Flow

1. **Authentication**: Validate API key
2. **Authorization**: Verify Super Admin role
3. **Validation**: Sanitize tenant ID and request data
4. **Audit**: Log the access attempt
5. **Processing**: Call DB Ops Service (simulated for now)
6. **Response**: Return appropriate HTTP status

### Future Enhancements

- JWT token authentication

- Database integration for audit logs

- Real DB Ops Service integration

- Tenant status monitoring endpoints

- Maintenance cancellation endpoints

## Logging

Logs are written to:

- `logs/error.log`: Error-level logs

- `logs/combined.log`: All logs

- Console (development only)

Log format: JSON with timestamps, service metadata, and structured data.
