#!/bin/bash

# Test OAuth2 Flow Example
set -e

HYDRA_PUBLIC_URL="http://localhost:4444"
CLIENT_ID="example-client"
CLIENT_SECRET="example-secret"
REDIRECT_URI="http://localhost:5555/callback"

echo "🧪 Testing OAuth2 Authorization Code Flow..."
echo ""

# Step 1: Generate authorization URL
echo "📋 Step 1: Authorization URL"
AUTH_URL="${HYDRA_PUBLIC_URL}/oauth2/auth?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=openid%20profile%20email&state=random-state-string"

echo "🔗 Open this URL in your browser:"
echo "${AUTH_URL}"
echo ""

echo "📝 After login, you'll be redirected to ${REDIRECT_URI}?code=..."
echo "📋 Copy the 'code' parameter from the URL and paste it below:"
read -p "Authorization Code: " AUTH_CODE

if [ -z "$AUTH_CODE" ]; then
    echo "❌ No authorization code provided"
    exit 1
fi

# Step 2: Exchange code for tokens
echo ""
echo "🔄 Step 2: Exchanging code for tokens..."

TOKEN_RESPONSE=$(curl -s -X POST \
  "${HYDRA_PUBLIC_URL}/oauth2/token" \
  -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&code=${AUTH_CODE}&redirect_uri=${REDIRECT_URI}")

if [ $? -eq 0 ]; then
    echo "✅ Token exchange successful!"
    echo ""
    echo "📄 Token Response:"
    echo "${TOKEN_RESPONSE}" | jq '.' 2>/dev/null || echo "${TOKEN_RESPONSE}"
    
    # Extract access token for further testing
    ACCESS_TOKEN=$(echo "${TOKEN_RESPONSE}" | jq -r '.access_token' 2>/dev/null)
    
    if [ "$ACCESS_TOKEN" != "null" ] && [ ! -z "$ACCESS_TOKEN" ]; then
        echo ""
        echo "🔍 Step 3: Testing userinfo endpoint..."
        
        USERINFO_RESPONSE=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" \
          "${HYDRA_PUBLIC_URL}/userinfo")
        
        echo "👤 User Info:"
        echo "${USERINFO_RESPONSE}" | jq '.' 2>/dev/null || echo "${USERINFO_RESPONSE}"
    fi
    
    # Save response for reference
    echo "${TOKEN_RESPONSE}" > examples/token-response.json
    echo ""
    echo "💾 Token response saved to examples/token-response.json"
else
    echo "❌ Token exchange failed"
    exit 1
fi

echo ""
echo "🎉 OAuth2 flow test completed successfully!"