#!/bin/bash

# OAuth2 Server Setup Script with Fixed Secrets
# Use this when you want consistent secrets across multiple project copies for testing
set -e

echo "🚀 Setting up OAuth2 Server with fixed secrets for testing..."

# Fixed secrets for consistent testing (DO NOT use in production!)
SYSTEM_SECRET="e71fc2a0bbae7aee00c1a65455d4340fb8e8b2da53074311db03b611ba3c846a"
COOKIE_SECRET="337d8248c683e5108ee0113bf1cc46df174208bd3e62b1f3c05ebe71275151ca"

echo "⚠️  WARNING: Using fixed secrets for testing purposes only!"
echo "    DO NOT use this script in production environments."
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "📋 Creating .env file from .env.example..."
    cp .env.example .env
fi

echo "🔐 Setting fixed secrets for consistent testing..."

# Replace secrets in .env file
sed -i.bak "s/SECRETS_SYSTEM=.*/SECRETS_SYSTEM=${SYSTEM_SECRET}/" .env
sed -i.bak "s/SECRETS_COOKIE=.*/SECRETS_COOKIE=${COOKIE_SECRET}/" .env

rm .env.bak
echo "✅ Fixed secrets set in .env"

echo "🐳 Starting Docker containers..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 10

echo "🔧 Creating OAuth2 client..."
./scripts/create-client.sh

echo ""
echo "🎉 OAuth2 Server is ready with consistent secrets!"
echo ""
echo "📍 Service URLs:"
echo "   - OAuth2 Server (Public):  http://localhost:4444/health/ready"
echo "   - OAuth2 Server (Admin):   http://localhost:4445/admin/clients"
echo "   - Login/Consent App:       http://localhost:3000"
echo ""
echo "📖 Next steps:"
echo "   1. Check health: ./scripts/health-check.sh"
echo "   2. Test OAuth flow (automatic): ./examples/test-oauth-flow-auto.sh"
echo "   3. Test OAuth flow (manual): ./examples/test-oauth-flow.sh"
echo "   4. Test client credentials: ./examples/test-client-credentials.sh"
echo ""
echo "🔒 Remember: These fixed secrets are for TESTING only!"
echo "   Use ./scripts/setup.sh for production deployments."
echo ""