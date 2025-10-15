#!/bin/bash

# Test Hydra Health and Configuration
set -e

HYDRA_PUBLIC_URL="http://localhost:4444"
HYDRA_ADMIN_URL="http://localhost:4445"

echo "🏥 OAuth2 Server Health Check"
echo "================================"
echo ""

echo "1️⃣  Testing Public API Health..."
PUBLIC_HEALTH=$(curl -s "${HYDRA_PUBLIC_URL}/health/ready")
if [ $? -eq 0 ]; then
    echo "✅ Public API is healthy"
    echo "   Response: ${PUBLIC_HEALTH}"
else
    echo "❌ Public API health check failed"
fi

echo ""
echo "2️⃣  Testing Admin API Health..."
ADMIN_HEALTH=$(curl -s "${HYDRA_ADMIN_URL}/health/ready")
if [ $? -eq 0 ]; then
    echo "✅ Admin API is healthy"
    echo "   Response: ${ADMIN_HEALTH}"
else
    echo "❌ Admin API health check failed"
fi

echo ""
echo "3️⃣  Testing OpenID Configuration..."
OIDC_CONFIG=$(curl -s "${HYDRA_PUBLIC_URL}/.well-known/openid-configuration")
if [ $? -eq 0 ]; then
    echo "✅ OpenID Configuration available"
    echo "   Issuer: $(echo "$OIDC_CONFIG" | jq -r '.issuer' 2>/dev/null)"
    echo "   Authorization endpoint: $(echo "$OIDC_CONFIG" | jq -r '.authorization_endpoint' 2>/dev/null)"
    echo "   Token endpoint: $(echo "$OIDC_CONFIG" | jq -r '.token_endpoint' 2>/dev/null)"
else
    echo "❌ OpenID Configuration unavailable"
fi

echo ""
echo "4️⃣  Listing OAuth2 Clients..."
CLIENTS=$(curl -s "${HYDRA_ADMIN_URL}/admin/clients")
if [ $? -eq 0 ]; then
    CLIENT_COUNT=$(echo "$CLIENTS" | jq 'length' 2>/dev/null)
    echo "✅ Found ${CLIENT_COUNT} client(s)"
    echo "$CLIENTS" | jq -r '.[] | "   - \(.client_id) (\(.client_name))"' 2>/dev/null || echo "$CLIENTS"
else
    echo "❌ Failed to list clients"
fi

echo ""
echo "================================"
echo "🎉 Health check complete!"
echo ""
echo "📍 Service URLs:"
echo "   Public API:  ${HYDRA_PUBLIC_URL}"
echo "   Admin API:   ${HYDRA_ADMIN_URL}"
echo "   OIDC Config: ${HYDRA_PUBLIC_URL}/.well-known/openid-configuration"