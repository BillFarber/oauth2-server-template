# OAuth2 Server Docker Template

A production-ready OAuth2 server template using **Ory Hydra** that can be easily deployed across multiple projects.

## 🚀 Quick Start

**👉 New to OAuth2 or need detailed setup instructions?** Check out **[QUICKSTART.md](QUICKSTART.md)** for a beginner-friendly guide!

**For experienced users:**

```bash
# Clone this template to your project
git clone <this-repo> oauth-server
cd oauth-server

# Set up and start the server
./scripts/setup.sh
```

The server will be available at:
- **OAuth2 Server (Public)**: http://localhost:4444
- **OAuth2 Server (Admin)**: http://localhost:4445  
- **Login/Consent App**: http://localhost:3000

## 📋 Features

- ✅ **OAuth 2.0 & OpenID Connect 1.0** compliant
- ✅ **Production-ready** with Ory Hydra
- ✅ **Docker containerized** for easy deployment
- ✅ **Multiple environments** (development & production)
- ✅ **Flexible configuration** via environment variables
- ✅ **Database support** (SQLite for dev, PostgreSQL for prod)
- ✅ **Automated setup** scripts
- ✅ **Example integrations** and test scripts
- ✅ **Security best practices** built-in

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client App    │───▶│  OAuth2 Server  │───▶│   Your App      │
│                 │    │   (Ory Hydra)   │    │ (Login/Consent) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    Database     │
                       │ (SQLite/Postgres│
                       └─────────────────┘
```

## 🛠️ Configuration

### Development Setup

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Customize settings** in `.env` (optional):
   ```bash
   # The setup script will generate secure secrets automatically
   SECRETS_SYSTEM=your-32-char-secret
   SECRETS_COOKIE=another-32-char-secret
   
   # Customize URLs if needed
   URLS_SELF_ISSUER=http://localhost:4444/
   URLS_LOGIN=http://localhost:3000/login
   ```

3. **Start services:**
   ```bash
   docker-compose up -d
   ```

### Production Setup

1. **Use production configuration:**
   ```bash
   cp .env.prod.example .env
   # Edit .env with your production settings
   ```

2. **Deploy with production compose:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 🔧 Usage Examples

### Test OAuth2 Flow

```bash
# Test the complete authorization code flow
./examples/test-oauth-flow.sh
```

### Test Client Credentials

```bash
# Test machine-to-machine authentication
./examples/test-client-credentials.sh
```

### Create Custom Clients

```bash
# Create a new OAuth2 client
curl -X POST http://localhost:4445/admin/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "my-app",
    "client_secret": "my-secret",
    "grant_types": ["authorization_code", "refresh_token"],
    "response_types": ["code"],
    "scope": "openid profile email",
    "redirect_uris": ["https://my-app.com/callback"]
  }'
```

## 🔗 Integration with Your Applications

### Node.js/Express Example

```javascript
const passport = require('passport');
const OAuth2Strategy = require('passport-oauth2');

passport.use('hydra', new OAuth2Strategy({
  authorizationURL: 'http://localhost:4444/oauth2/auth',
  tokenURL: 'http://localhost:4444/oauth2/token',
  clientID: 'your-client-id',
  clientSecret: 'your-client-secret',
  callbackURL: 'http://your-app.com/callback'
}, (accessToken, refreshToken, profile, done) => {
  // Handle user profile
  return done(null, profile);
}));
```

### Python/Flask Example

```python
from authlib.integrations.flask_client import OAuth

oauth = OAuth(app)
oauth.register(
    name='hydra',
    client_id='your-client-id',
    client_secret='your-client-secret',
    server_metadata_url='http://localhost:4444/.well-known/openid_configuration',
    client_kwargs={
        'scope': 'openid profile email'
    }
)
```

## 🗄️ Database Options

### SQLite (Development)
```yaml
# docker-compose.yml uses SQLite by default
DSN=sqlite:///var/lib/sqlite/db.sqlite?_fk=true
```

### PostgreSQL (Production)
```yaml
# Use docker-compose.prod.yml for PostgreSQL
DSN=postgres://hydra:secret@postgres:5432/hydra?sslmode=disable
```

### External Database
```bash
# Update .env file
DSN=postgres://user:pass@your-db-host:5432/hydra?sslmode=require
```

## 🔒 Security Considerations

### Secrets Management
- **Always change default secrets** in production
- Use **strong, random 32+ character secrets**
- Consider using **secret management tools** (HashiCorp Vault, AWS Secrets Manager)

### HTTPS/TLS
```yaml
# For production, ensure all URLs use HTTPS
URLS_SELF_ISSUER=https://your-domain.com/
URLS_LOGIN=https://your-app.com/login
```

### Network Security
- **Restrict admin port** (4445) access
- Use **reverse proxy** (nginx, Traefik) for TLS termination
- **Firewall** database ports from external access

## 🚀 Deployment Options

### Docker Compose (Local/Development)
```bash
docker-compose up -d
```

### Kubernetes
```yaml
# Example k8s deployment files in k8s/ directory
kubectl apply -f k8s/
```

### Cloud Platforms
- **AWS ECS/Fargate**: Use provided task definitions
- **Google Cloud Run**: Deploy with Cloud Build
- **Azure Container Instances**: Use ARM templates

## 📊 Monitoring & Logging

### Health Checks
```bash
# Health endpoints
curl http://localhost:4444/health/ready
curl http://localhost:4445/health/ready
```

### Metrics
```bash
# Prometheus metrics
curl http://localhost:4444/admin/metrics/prometheus
```

### Logs
```bash
# View logs
docker-compose logs -f hydra
docker-compose logs -f consent-app
```

## 🛠️ Management Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Complete setup and initialization |
| `scripts/create-client.sh` | Create OAuth2 clients |
| `examples/test-oauth-flow.sh` | Test authorization code flow |
| `examples/test-client-credentials.sh` | Test client credentials flow |

## 🔧 Customization

### Custom Login/Consent UI

Replace the default consent app with your own:

```yaml
# docker-compose.yml
consent-app:
  image: your-registry/your-consent-app:latest
  # ... your configuration
```

### Custom Configuration

Extend `config/hydra.yml` for advanced settings:

```yaml
# config/hydra.yml
ttl:
  access_token: 24h
  refresh_token: 720h
  
oauth2:
  pkce:
    enforced: true
```

## 📋 Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRETS_SYSTEM` | System secret (32+ chars) | Generated |
| `SECRETS_COOKIE` | Cookie secret (32+ chars) | Generated |
| `DSN` | Database connection string | SQLite |
| `URLS_SELF_ISSUER` | OAuth2 server public URL | http://localhost:4444/ |
| `URLS_LOGIN` | Login page URL | http://localhost:3000/login |
| `URLS_CONSENT` | Consent page URL | http://localhost:3000/consent |
| `LOG_LEVEL` | Logging level | debug |

## 🆘 Troubleshooting

### Common Issues

**Server won't start:**
```bash
# Check logs
docker-compose logs hydra

# Verify database migration
docker-compose logs hydra-migrate
```

**Client creation fails:**
```bash
# Ensure admin port is accessible
curl http://localhost:4445/health/ready
```

**OAuth flow fails:**
```bash
# Check configuration
curl http://localhost:4444/.well-known/openid_configuration
```

### Reset Everything
```bash
# Stop and remove all containers and volumes
docker-compose down -v
rm -f .env

# Start fresh
./scripts/setup.sh
```

## 📚 Additional Resources

- [Ory Hydra Documentation](https://www.ory.sh/hydra/docs/)
- [OAuth 2.0 RFC](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Specification](https://openid.net/connect/)
- [OAuth 2.0 Security Best Practices](https://tools.ietf.org/html/draft-ietf-oauth-security-topics)

## 📄 License

This template is released under the MIT License. See LICENSE file for details.

## 🤝 Contributing

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

**Need help?** Open an issue or check the troubleshooting section above.