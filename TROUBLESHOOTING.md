# OAuth2 Server Troubleshooting Guide

## Common Issues and Solutions

### 1. "hydra-migrate-1 stopped running"

**✅ This is EXPECTED behavior!**

The `hydra-migrate` container is a one-time job that:
- Runs database migrations
- Exits with code 0 (success)
- Should NOT keep running

**How to verify it succeeded:**
```bash
docker-compose ps -a
# Look for: "Exited (0)" status for hydra-migrate
```

---

### 2. "404 Error on http://localhost:4444 or http://localhost:4445"

**✅ This is NORMAL!**

Hydra doesn't serve a homepage at the root path. Instead, it provides OAuth2/OIDC endpoints.

**Correct endpoints to test:**
```bash
# Health check
curl http://localhost:4444/health/ready
curl http://localhost:4445/health/ready

# OpenID Configuration
curl http://localhost:4444/.well-known/openid-configuration

# OAuth2 endpoints
# - http://localhost:4444/oauth2/auth (authorization)
# - http://localhost:4444/oauth2/token (token exchange)
# - http://localhost:4445/admin/clients (manage clients)
```

**Run the health check script:**
```bash
./scripts/health-check.sh
```

---

### 3. "Token Exchange Failed with 401 Unauthorized"

**❌ Issue:** Using wrong client authentication method

**Error message:**
```
"The OAuth 2.0 Client supports client authentication method 'client_secret_basic', 
but method 'client_secret_post' was requested."
```

**✅ Solution:** Use HTTP Basic Authentication

**Wrong way (client_secret_post):**
```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=example-client&client_secret=example-secret"
```

**Correct way (client_secret_basic):**
```bash
curl -X POST http://localhost:4444/oauth2/token \
  -u "example-client:example-secret" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials"
```

The `-u` flag uses HTTP Basic Auth, which is the default for Hydra clients.

---

### 4. Services Won't Start

**Check container logs:**
```bash
docker-compose logs hydra
docker-compose logs hydra-migrate
docker-compose logs consent-app
```

**Common causes:**
- Port conflicts (4444, 4445, 3000 already in use)
- Database migration failed
- Invalid configuration

**Solution - Restart everything:**
```bash
docker-compose down -v
docker-compose up -d
```

---

### 5. Client Already Exists Error

**Error when running setup.sh again:**
```
"Unable to insert or update resource because a resource with that value exists already"
```

**✅ Solution:** The client `example-client` already exists. This is fine!

**To recreate the client:**
```bash
# Delete the old client
curl -X DELETE http://localhost:4445/admin/clients/example-client

# Create a new one
./scripts/create-client.sh
```

---

### 6. Test Scripts Return Errors

**Make sure you're testing correctly:**

**1. For Client Credentials Flow:**
```bash
./examples/test-client-credentials.sh
```

**2. For Authorization Code Flow:**
```bash
./examples/test-oauth-flow.sh
# This is interactive - you'll need to:
# 1. Open the URL in a browser
# 2. Login (any username works in dev mode)
# 3. Grant consent
# 4. Copy the authorization code from the redirect
```

---

### 7. Reset Everything

**To start completely fresh:**

```bash
# Stop all containers and remove volumes
docker-compose down -v

# Remove any generated files
rm -f .env examples/*.json

# Start fresh
./scripts/setup.sh
```

---

## Verifying Everything Works

**Run this quick verification:**

```bash
# 1. Check services are running
docker-compose ps

# 2. Run health check
./scripts/health-check.sh

# 3. Test client credentials flow
./examples/test-client-credentials.sh

# 4. (Optional) Test authorization code flow
./examples/test-oauth-flow.sh
```

**Expected output:**
- ✅ All health checks pass
- ✅ `example-client` is listed
- ✅ Client credentials returns an access token
- ✅ Authorization code flow completes successfully

---

## Understanding the Architecture

```
┌─────────────────────┐
│   Your Browser      │
│  or Application     │
└──────────┬──────────┘
           │
           ├─────────────────┐
           │                 │
     ┌─────▼─────┐    ┌─────▼─────┐
     │  Public   │    │   Admin   │
     │  :4444    │    │   :4445   │
     └─────┬─────┘    └─────┬─────┘
           │                │
           └────────┬────────┘
                    │
           ┌────────▼────────┐
           │  Hydra Server   │
           │  (Container)    │
           └────────┬────────┘
                    │
           ┌────────▼────────┐
           │   SQLite DB     │
           │   (Volume)      │
           └─────────────────┘
```

**Port Usage:**
- **4444** - Public OAuth2/OIDC endpoints (for clients)
- **4445** - Admin API (for managing clients, etc.)
- **3000** - Login/Consent UI (for user interaction)

---

## Still Having Issues?

1. Check the logs: `docker-compose logs -f`
2. Verify Docker is running: `docker ps`
3. Check port availability: `lsof -i :4444,4445,3000`
4. Review the README.md for setup instructions
5. Open an issue with your error logs

---

## Quick Reference

**Useful commands:**
```bash
# View logs
docker-compose logs -f hydra

# Restart services
docker-compose restart

# Check service status
docker-compose ps

# Run health check
./scripts/health-check.sh

# Test OAuth2 flows
./examples/test-client-credentials.sh
./examples/test-oauth-flow.sh
```