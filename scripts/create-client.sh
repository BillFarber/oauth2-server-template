#!/bin/bash

# Create OAuth2 Client Script
set -e

HYDRA_ADMIN_URL="http://localhost:4445"

echo "🔧 Creating OAuth2 client..."

# Create a client
CLIENT_RESPONSE=$(curl -s -X POST \
  "${HYDRA_ADMIN_URL}/admin/clients" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "example-client",
    "client_name": "Example OAuth2 Client",
    "client_secret": "example-secret",
    "grant_types": ["authorization_code", "refresh_token", "client_credentials"],
    "response_types": ["code", "id_token"],
    "scope": "openid offline profile email",
    "redirect_uris": ["http://localhost:5555/callback"],
    "token_endpoint_auth_method": "client_secret_basic"
  }')

if [ $? -eq 0 ]; then
    echo "✅ OAuth2 client created successfully!"
    echo ""
    echo "📋 Client Details:"
    echo "   Client ID: example-client"
    echo "   Client Secret: example-secret"
    echo "   Redirect URI: http://localhost:5555/callback"
    echo "   Scopes: openid offline profile email"
    echo ""
    echo "💾 Response saved to examples/client-response.json"
    echo "${CLIENT_RESPONSE}" | jq '.' > examples/client-response.json 2>/dev/null || echo "${CLIENT_RESPONSE}" > examples/client-response.json
else
    echo "❌ Failed to create OAuth2 client"
    exit 1
fi