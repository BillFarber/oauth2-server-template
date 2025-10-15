#!/bin/bash

# Simple Client Credentials Flow Example
set -e

HYDRA_PUBLIC_URL="http://localhost:4444"
CLIENT_ID="example-client"
CLIENT_SECRET="example-secret"

echo "🔐 Testing Client Credentials Flow..."

# Use HTTP Basic Auth (-u flag) instead of sending credentials in body
TOKEN_RESPONSE=$(curl -s -X POST \
  "${HYDRA_PUBLIC_URL}/oauth2/token" \
  -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&scope=profile")

if [ $? -eq 0 ]; then
    echo "✅ Client credentials flow successful!"
    echo ""
    echo "📄 Token Response:"
    echo "${TOKEN_RESPONSE}" | jq '.' 2>/dev/null || echo "${TOKEN_RESPONSE}"
    
    # Save response
    echo "${TOKEN_RESPONSE}" > examples/client-credentials-response.json
    echo ""
    echo "💾 Response saved to examples/client-credentials-response.json"
    
    # Check if we got an error
    ERROR=$(echo "${TOKEN_RESPONSE}" | jq -r '.error' 2>/dev/null)
    if [ "$ERROR" != "null" ] && [ ! -z "$ERROR" ]; then
        echo ""
        echo "⚠️  Warning: Response contains an error"
        exit 1
    fi
else
    echo "❌ Client credentials flow failed"
    exit 1
fi