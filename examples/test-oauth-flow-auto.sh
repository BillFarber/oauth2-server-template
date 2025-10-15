#!/bin/bash

# OAuth2 Authorization Code Flow with Callback Server
set -e

HYDRA_PUBLIC_URL="http://localhost:4444"
CLIENT_ID="example-client"
CLIENT_SECRET="example-secret"
REDIRECT_URI="http://localhost:5555/callback"
CALLBACK_PORT=5555

echo "🧪 Testing OAuth2 Authorization Code Flow (with callback server)..."
echo ""

# Step 1: Start a simple HTTP server to catch the callback
echo "🌐 Starting callback server on port ${CALLBACK_PORT}..."

# Create a temporary file to store the authorization code
TEMP_FILE=$(mktemp)

# Start a background HTTP server using Python
python3 -c "
import http.server
import socketserver
import urllib.parse
import sys

class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/callback'):
            # Parse the query string
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            
            if 'code' in params:
                code = params['code'][0]
                state = params.get('state', [''])[0]
                
                # Write the code to the temp file
                with open('${TEMP_FILE}', 'w') as f:
                    f.write(code)
                
                # Send a success response
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                html = '''
                <!DOCTYPE html>
                <html>
                <head>
                    <title>OAuth2 Success</title>
                    <style>
                        body { 
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                            display: flex;
                            justify-content: center;
                            align-items: center;
                            height: 100vh;
                            margin: 0;
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        }
                        .container {
                            background: white;
                            padding: 3rem;
                            border-radius: 1rem;
                            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                            text-align: center;
                            max-width: 500px;
                        }
                        h1 { color: #667eea; margin-bottom: 1rem; }
                        .success { 
                            font-size: 4rem; 
                            margin-bottom: 1rem;
                        }
                        .code {
                            background: #f4f4f4;
                            padding: 1rem;
                            border-radius: 0.5rem;
                            word-break: break-all;
                            font-family: monospace;
                            font-size: 0.9rem;
                            margin: 1rem 0;
                        }
                        .info {
                            color: #666;
                            margin-top: 1rem;
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="success">✅</div>
                        <h1>Authorization Successful!</h1>
                        <p>The authorization code has been received.</p>
                        <div class="code">''' + code + '''</div>
                        <p class="info">You can close this window. The token exchange is happening in the background...</p>
                    </div>
                </body>
                </html>
                '''
                self.wfile.write(html.encode())
                
                # Stop the server after handling the callback
                sys.exit(0)
            elif 'error' in params:
                error = params['error'][0]
                error_description = params.get('error_description', [''])[0]
                
                self.send_response(400)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                html = f'''
                <!DOCTYPE html>
                <html>
                <head><title>OAuth2 Error</title></head>
                <body>
                    <h1>❌ Authorization Failed</h1>
                    <p><strong>Error:</strong> {error}</p>
                    <p><strong>Description:</strong> {error_description}</p>
                </body>
                </html>
                '''
                self.wfile.write(html.encode())
                sys.exit(1)
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Suppress log messages

with socketserver.TCPServer(('', ${CALLBACK_PORT}), CallbackHandler) as httpd:
    httpd.serve_forever()
" &

SERVER_PID=$!

# Give the server a moment to start
sleep 1

# Check if the server started successfully
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "❌ Failed to start callback server on port ${CALLBACK_PORT}"
    echo "   Make sure the port is not already in use."
    exit 1
fi

echo "✅ Callback server running (PID: ${SERVER_PID})"
echo ""

# Step 2: Generate authorization URL
echo "📋 Step 1: Opening authorization URL in your browser..."
AUTH_URL="${HYDRA_PUBLIC_URL}/oauth2/auth?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=openid%20profile%20email&state=random-state-string"

echo "🔗 URL: ${AUTH_URL}"
echo ""
echo "🌐 Opening browser..."

# Try to open the URL in the default browser (works on macOS, Linux, WSL)
if command -v open &> /dev/null; then
    open "${AUTH_URL}"
elif command -v xdg-open &> /dev/null; then
    xdg-open "${AUTH_URL}"
else
    echo "⚠️  Could not auto-open browser. Please manually open:"
    echo "   ${AUTH_URL}"
fi

echo ""
echo "⏳ Waiting for authorization callback..."
echo "   (Complete the login and consent in your browser)"
echo ""

# Wait for the server process to exit (which happens after receiving the callback)
wait $SERVER_PID 2>/dev/null
SERVER_EXIT_CODE=$?

# Check if we got an authorization code
if [ ! -f "${TEMP_FILE}" ] || [ ! -s "${TEMP_FILE}" ]; then
    echo "❌ No authorization code received"
    rm -f "${TEMP_FILE}"
    exit 1
fi

AUTH_CODE=$(cat "${TEMP_FILE}")
rm -f "${TEMP_FILE}"

if [ -z "$AUTH_CODE" ]; then
    echo "❌ Authorization code is empty"
    exit 1
fi

echo "✅ Authorization code received!"
echo ""

# Step 3: Exchange code for tokens
echo "🔄 Step 2: Exchanging authorization code for tokens..."

TOKEN_RESPONSE=$(curl -s -X POST \
  "${HYDRA_PUBLIC_URL}/oauth2/token" \
  -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&code=${AUTH_CODE}&redirect_uri=${REDIRECT_URI}")

if [ $? -eq 0 ]; then
    # Check if we got an error
    ERROR=$(echo "${TOKEN_RESPONSE}" | jq -r '.error' 2>/dev/null)
    if [ "$ERROR" != "null" ] && [ ! -z "$ERROR" ]; then
        echo "❌ Token exchange failed!"
        echo ""
        echo "📄 Error Response:"
        echo "${TOKEN_RESPONSE}" | jq '.' 2>/dev/null || echo "${TOKEN_RESPONSE}"
        exit 1
    fi
    
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
echo "🎉 OAuth2 Authorization Code Flow completed successfully!"