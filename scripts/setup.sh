#!/bin/bash

# OAuth2 Server Setup Script
set -e

echo "🚀 Setting up OAuth2 Server..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "📋 Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ Please edit .env file with your specific configuration"
fi

# Generate secure secrets if using defaults
if grep -q "this_needs_to_be_the_same_always_and_also_very_\$3cuR3-._" .env; then
    echo "🔐 Generating secure secrets..."
    
    # Generate random secrets
    SYSTEM_SECRET=$(openssl rand -hex 32)
    COOKIE_SECRET=$(openssl rand -hex 32)
    
    # Replace in .env file
    sed -i.bak "s/SECRETS_SYSTEM=.*/SECRETS_SYSTEM=${SYSTEM_SECRET}/" .env
    sed -i.bak "s/SECRETS_COOKIE=.*/SECRETS_COOKIE=${COOKIE_SECRET}/" .env
    
    rm .env.bak
    echo "✅ Secrets generated and updated in .env"
fi

echo "🐳 Starting Docker containers..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 10

echo "🔧 Creating OAuth2 client..."
./scripts/create-client.sh

echo ""
echo "🎉 OAuth2 Server is ready!"
echo ""
echo "📍 Service URLs:"
echo "   - OAuth2 Server (Public):  http://localhost:4444"
echo "   - OAuth2 Server (Admin):   http://localhost:4445"
echo "   - Login/Consent App:       http://localhost:3000"
echo ""
echo "📖 Next steps:"
echo "   1. Check logs: docker-compose logs -f"
echo "   2. View example client: cat examples/test-client.sh"
echo "   3. Test OAuth flow: ./examples/test-oauth-flow.sh"
echo ""