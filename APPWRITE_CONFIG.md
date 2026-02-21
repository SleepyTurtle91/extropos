# FlutterPOS Appwrite Configuration

# Generated: 2025-12-10

## Development Setup (localhost)

### Configuration Values

- **Endpoint**: `http://localhost:8080`

- **Project ID**: `default`

- **API Key**: `standard` (development-only key)

### Test Command

```bash
curl -X GET http://localhost:8080/v1/health \
  -H "X-Appwrite-Key: standard"

```

### Next Steps

1. **Update Flutter App Settings**:

   - Go to Backend app → Settings → Appwrite Configuration

   - Endpoint: `http://localhost:8080`

   - Project ID: `default`

   - API Key: `standard`

   - Click "Test Connection"

2. **Access Appwrite Console** (when domain is fixed):

   - URL: `http://localhost:8080/console`

   - Generate proper API keys there

3. **For Production**:

   - Access console at: `https://appwrite.extropos.org/console`

   - Create projects and API keys

   - Update endpoint to production URL

### Why "standard" key works

- Appwrite's default development key

- Works for basic API operations

- For production, generate custom API keys in the console

### Troubleshooting

If the console shows blank page:

- Domain routing issue (cosmetic, API works fine)

- API is fully functional

- Configuration works through direct URL without console
