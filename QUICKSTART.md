# 🚀 OAuth2 Server - Quick Start Guide

**A beginner-friendly guide to get your OAuth2 server up and running in 5 minutes!**

---

## 📦 What You'll Need

Before you start, make sure you have these installed on your computer:

- ✅ **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
- ✅ **Git** - [Download here](https://git-scm.com/downloads)
- ✅ **Terminal/Command Line** - Already on your computer!
  - Mac: Use "Terminal" app
  - Windows: Use "Git Bash" (comes with Git) or "PowerShell"

> 💡 **Tip**: After installing Docker Desktop, make sure it's running (you should see the Docker icon in your system tray/menu bar).

---

## 🎯 Step 1: Get the Code

Open your terminal and run these commands:

```bash
# Go to where you keep your projects
cd ~/Documents  # or wherever you like to work

# Clone this OAuth2 server template
git clone <this-repo-url> oauth-server

# Go into the project folder
cd oauth-server
```

**What just happened?** You downloaded the OAuth2 server code to your computer.

---

## ⚡ Step 2: Run the Setup Script

This is the easiest part! Just run one command:

```bash
./scripts/setup.sh
```

**What does this do?**
1. ✅ Creates a configuration file (`.env`)
2. ✅ Generates secure random secrets automatically
3. ✅ Starts all the Docker containers
4. ✅ Creates a test OAuth2 client for you to use

You should see output like this:
```
🚀 Setting up OAuth2 Server...
🔐 Generating secure secrets...
✅ Secrets generated and updated in .env
🐳 Starting Docker containers...
⏳ Waiting for services to be ready...
🔧 Creating OAuth2 client...
🎉 OAuth2 Server is ready!
```

> ⏱️ **Wait time**: This takes about 30-60 seconds the first time (Docker needs to download images).

---

## 🎉 Step 3: Verify It's Working

Let's make sure everything is running properly.

### Option A: Quick Health Check (Easy)

Run this simple command:

```bash
./scripts/health-check.sh
```

You should see all green checkmarks ✅ if everything is working!

### Option B: Manual Check (If you're curious)

Open your browser and visit:
- http://localhost:4444/.well-known/openid-configuration

If you see a bunch of JSON text, it's working! 🎊

---

## 🧪 Step 4: Test the OAuth2 Flow

Now let's test that OAuth actually works!

### Test #1: Automatic OAuth Flow (Recommended for Beginners)

This test opens your browser automatically:

```bash
./examples/test-oauth-flow-auto.sh
```

**What will happen:**
1. 🌐 Your browser will open automatically
2. 📝 You'll see a login page (just click "Accept")
3. ✅ You'll see a green success page
4. 🎫 Your terminal will show the access token

> 💡 **Why this is cool**: This is how users would log into your app using OAuth!

### Test #2: Machine-to-Machine (No Browser Needed)

This test works entirely in the terminal:

```bash
./examples/test-client-credentials.sh
```

You should see output like:
```
✅ Successfully obtained access token
Access Token: ory_at_abc123...
Token Type: bearer
Expires In: 3599 seconds
```

> 💡 **Why this matters**: This is how servers/APIs talk to each other securely!

---

## 📍 Important URLs to Remember

Once your server is running, these are the key URLs:

| Service | URL | What it does |
|---------|-----|--------------|
| **OAuth2 API** | http://localhost:4444 | Main OAuth2 server (your apps connect here) |
| **Admin API** | http://localhost:4445 | Create/manage OAuth2 clients |
| **Login/Consent** | http://localhost:3000 | Where users log in and approve access |

> ⚠️ **Note**: Don't expect to see a webpage at `http://localhost:4444/` directly - it's an API, not a website! Use the health check or test scripts instead.

---

## 🛠️ Common Tasks

### Stop the Server

```bash
docker-compose down
```

**When to use:** When you're done working and want to free up resources.

### Start the Server Again

```bash
docker-compose up -d
```

**When to use:** After you've stopped it and want to start it back up.

### View Logs (See what's happening)

```bash
docker-compose logs -f
```

**When to use:** If something isn't working and you want to debug.
**To exit:** Press `Ctrl + C`

### Reset Everything (Start Fresh)

```bash
# Stop and remove everything
docker-compose down -v

# Delete configuration
rm .env

# Run setup again
./scripts/setup.sh
```

**When to use:** When things are broken and you want a clean slate.

---

## 🔑 Default Test Client Credentials

The setup script creates a test client for you automatically:

```
Client ID:       test-client
Client Secret:   test-secret
Redirect URL:    http://localhost:5555/callback
Scopes:          openid profile email
```

> 💡 **For testing only!** Create your own clients for real applications (see next section).

---

## 🎨 Create Your Own OAuth2 Client

When you're ready to connect your own app, create a client like this:

```bash
./scripts/create-client.sh
```

Then follow the prompts to enter:
- **Client ID**: A unique name (e.g., "my-app")
- **Client Secret**: A secure password (generate one or use a strong password)
- **Redirect URIs**: Where to send users after login (e.g., "http://localhost:3000/callback")

Or do it manually with curl:

```bash
curl -X POST http://localhost:4445/admin/clients \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "my-app",
    "client_secret": "my-super-secret-password",
    "grant_types": ["authorization_code", "refresh_token"],
    "response_types": ["code"],
    "scope": "openid profile email",
    "redirect_uris": ["http://localhost:3000/callback"]
  }'
```

---

## 🆘 Troubleshooting

### Problem: "Permission denied" when running scripts

**Solution:**
```bash
chmod +x scripts/*.sh examples/*.sh
```

### Problem: "Port already in use"

**Solution:** Something else is using ports 4444, 4445, or 3000.
```bash
# Find what's using the port (Mac/Linux)
lsof -i :4444

# Kill the process or change ports in docker-compose.yml
```

### Problem: Docker containers won't start

**Solution:**
1. Make sure Docker Desktop is running
2. Try restarting Docker Desktop
3. Run `docker-compose down -v` and try setup again

### Problem: "curl: command not found"

**Solution:**
- **Mac**: curl comes pre-installed, you should have it
- **Windows**: Install Git Bash or use PowerShell with `Invoke-WebRequest`
- **Linux**: `sudo apt-get install curl` or `sudo yum install curl`

### Problem: Test scripts show "invalid_client" error

**Solution:** This was already fixed! Make sure you're using the latest scripts.
The client authentication uses HTTP Basic Auth now.

---

## 📚 Understanding OAuth2 (5-Minute Version)

**What is OAuth2?**
Think of it like a hotel key card system:
- 🏨 The hotel (OAuth2 server) gives you a key card (token)
- 🚪 The key card opens certain doors (scopes/permissions)
- ⏰ The key card expires after checkout (token expiration)
- 🔄 You can get a new key card without checking in again (refresh token)

**Two Main Flows:**

1. **Authorization Code Flow** (for apps with users)
   - User clicks "Login with OAuth"
   - User approves permissions
   - App gets a token to access user's data
   - **Example**: "Login with Google" on a website

2. **Client Credentials Flow** (for server-to-server)
   - Server authenticates with client ID and secret
   - Server gets a token
   - Server uses token to call APIs
   - **Example**: Automated backup service accessing your files

---

## 🎓 Next Steps

Now that you have OAuth2 running, here's what to learn next:

1. **Read the main README.md** - More detailed documentation
2. **Check TROUBLESHOOTING.md** - Solutions to common issues
3. **Try the example integrations** - See how to connect your app (Node.js, Python examples in README)
4. **Learn about scopes and permissions** - Control what apps can access
5. **Deploy to production** - Use `docker-compose.prod.yml` with PostgreSQL

---

## 🤝 Getting Help

- 📖 **Full Documentation**: See `README.md` in this folder
- 🐛 **Troubleshooting Guide**: See `TROUBLESHOOTING.md` in this folder
- 🔧 **Ory Hydra Docs**: https://www.ory.sh/hydra/docs/
- 💬 **OAuth2 Explained**: https://www.oauth.com/

---

## ✅ Quick Reference Cheat Sheet

### Starting Fresh
```bash
cd oauth-server
./scripts/setup.sh
```

### Daily Use
```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Testing
```bash
# Test with browser
./examples/test-oauth-flow-auto.sh

# Test without browser
./examples/test-client-credentials.sh

# Health check
./scripts/health-check.sh
```

### Managing Clients
```bash
# Create new client
./scripts/create-client.sh

# List all clients
curl http://localhost:4445/admin/clients | jq

# Delete a client
curl -X DELETE http://localhost:4445/admin/clients/client-id
```

---

**🎉 Congratulations!** You now have a working OAuth2 server. Start building amazing apps! 🚀

---

*Last updated: October 2025*
