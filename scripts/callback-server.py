#!/usr/bin/env python3
"""
Simple OAuth2 Callback Server
Listens on port 5555 for OAuth2 callbacks and automatically exchanges the authorization code for tokens.
"""

import http.server
import socketserver
import urllib.parse
import urllib.request
import json
import base64
import sys
from urllib.error import HTTPError

PORT = 5555
HYDRA_PUBLIC_URL = "http://localhost:4444"
CLIENT_ID = "example-client"
CLIENT_SECRET = "example-secret"
REDIRECT_URI = f"http://localhost:{PORT}/callback"


class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

    def do_GET(self):
        """Handle GET requests to /callback"""

        # Parse the URL and query parameters
        parsed_path = urllib.parse.urlparse(self.path)

        if parsed_path.path == "/callback":
            # Parse query parameters
            params = urllib.parse.parse_qs(parsed_path.query)

            # Check for authorization code
            if "code" in params:
                auth_code = params["code"][0]
                state = params.get("state", [""])[0]

                print(f"\n✅ Received authorization code: {auth_code[:20]}...")
                print(f"🔄 Exchanging code for tokens...\n")

                # Exchange code for tokens
                token_response = self.exchange_code_for_tokens(auth_code)

                if token_response:
                    # Send success response to browser
                    self.send_success_response(token_response)

                    # Print to terminal
                    print("=" * 60)
                    print("🎉 OAuth2 Flow Completed Successfully!")
                    print("=" * 60)
                    print(f"\n📄 Token Response:\n")
                    print(json.dumps(token_response, indent=2))

                    # Save to file
                    try:
                        with open("examples/token-response.json", "w") as f:
                            json.dump(token_response, f, indent=2)
                        print(
                            f"\n💾 Tokens saved to: examples/token-response.json"
                        )
                    except Exception as e:
                        print(f"\n⚠️  Could not save tokens: {e}")

                    print("\n" + "=" * 60)
                    print("✅ You can close this server with Ctrl+C")
                    print("=" * 60 + "\n")
                else:
                    self.send_error_response("Token exchange failed")

            elif "error" in params:
                error = params["error"][0]
                error_description = params.get("error_description", [""])[0]
                print(f"\n❌ OAuth error: {error}")
                if error_description:
                    print(f"   Description: {error_description}")
                self.send_error_response(f"OAuth Error: {error}")
            else:
                self.send_error_response("No authorization code received")

        elif parsed_path.path == "/":
            # Root path - show status page
            self.send_status_page()
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found")

    def exchange_code_for_tokens(self, auth_code):
        """Exchange authorization code for access tokens"""
        token_url = f"{HYDRA_PUBLIC_URL}/oauth2/token"

        # Prepare the request
        data = urllib.parse.urlencode(
            {
                "grant_type": "authorization_code",
                "code": auth_code,
                "redirect_uri": REDIRECT_URI,
            }
        ).encode("utf-8")

        # Create Basic Auth header
        credentials = f"{CLIENT_ID}:{CLIENT_SECRET}"
        b64_credentials = base64.b64encode(credentials.encode("utf-8")).decode(
            "utf-8"
        )

        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Basic {b64_credentials}",
        }

        try:
            request = urllib.request.Request(
                token_url, data=data, headers=headers
            )
            with urllib.request.urlopen(request) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as e:
            error_body = e.read().decode("utf-8")
            print(f"❌ Token exchange failed: {e.code}")
            print(f"   Response: {error_body}")
            return None
        except Exception as e:
            print(f"❌ Token exchange error: {e}")
            return None

    def send_success_response(self, token_response):
        """Send HTML success page to browser"""
        access_token = token_response.get("access_token", "N/A")
        token_type = token_response.get("token_type", "N/A")
        expires_in = token_response.get("expires_in", "N/A")
        scope = token_response.get("scope", "N/A")

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>OAuth2 Success</title>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: #f5f5f5;
                }}
                .container {{
                    background: white;
                    padding: 30px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }}
                h1 {{ color: #22c55e; }}
                .success-icon {{ font-size: 48px; margin-bottom: 20px; }}
                .token-info {{
                    background: #f9fafb;
                    padding: 15px;
                    border-radius: 4px;
                    margin: 20px 0;
                    font-family: 'Courier New', monospace;
                    font-size: 14px;
                }}
                .label {{ font-weight: bold; color: #6b7280; }}
                .value {{ color: #111827; word-break: break-all; }}
                .note {{
                    background: #fef3c7;
                    padding: 15px;
                    border-radius: 4px;
                    border-left: 4px solid #f59e0b;
                    margin-top: 20px;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="success-icon">🎉</div>
                <h1>OAuth2 Authentication Successful!</h1>
                <p>The authorization code has been successfully exchanged for access tokens.</p>
                
                <div class="token-info">
                    <div><span class="label">Token Type:</span> <span class="value">{token_type}</span></div>
                    <div><span class="label">Expires In:</span> <span class="value">{expires_in} seconds</span></div>
                    <div><span class="label">Scope:</span> <span class="value">{scope}</span></div>
                    <div style="margin-top: 10px;">
                        <span class="label">Access Token:</span><br>
                        <span class="value">{access_token[:50]}...</span>
                    </div>
                </div>
                
                <div class="note">
                    <strong>📝 Note:</strong> Check your terminal for the complete token response. 
                    Tokens have been saved to <code>examples/token-response.json</code>
                </div>
                
                <p style="margin-top: 20px; color: #6b7280;">
                    You can close this window and return to your terminal.
                </p>
            </div>
        </body>
        </html>
        """

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))

    def send_error_response(self, error_message):
        """Send HTML error page to browser"""
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>OAuth2 Error</title>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: #f5f5f5;
                }}
                .container {{
                    background: white;
                    padding: 30px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }}
                h1 {{ color: #ef4444; }}
                .error-icon {{ font-size: 48px; margin-bottom: 20px; }}
                .error-message {{
                    background: #fef2f2;
                    padding: 15px;
                    border-radius: 4px;
                    border-left: 4px solid #ef4444;
                    margin: 20px 0;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="error-icon">❌</div>
                <h1>OAuth2 Error</h1>
                <div class="error-message">
                    <strong>Error:</strong> {error_message}
                </div>
                <p>Please check your terminal for more details.</p>
            </div>
        </body>
        </html>
        """

        self.send_response(400)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))

    def send_status_page(self):
        """Send status page showing the server is running"""
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>OAuth2 Callback Server</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: #f5f5f5;
                }
                .container {
                    background: white;
                    padding: 30px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                h1 { color: #3b82f6; }
                .status { color: #22c55e; font-weight: bold; }
                code {
                    background: #f3f4f6;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'Courier New', monospace;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔐 OAuth2 Callback Server</h1>
                <p class="status">✅ Server is running and waiting for OAuth2 callbacks...</p>
                <p>This server is listening on <code>http://localhost:5555/callback</code></p>
                <p>Start the OAuth2 flow from your terminal to authenticate.</p>
            </div>
        </body>
        </html>
        """

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))


def main():
    """Start the callback server"""
    try:
        with socketserver.TCPServer(("", PORT), OAuthCallbackHandler) as httpd:
            print("=" * 60)
            print("🚀 OAuth2 Callback Server Started")
            print("=" * 60)
            print(f"\n📍 Listening on: http://localhost:{PORT}")
            print(f"📍 Callback URL: http://localhost:{PORT}/callback")
            print("\n💡 Instructions:")
            print("   1. Visit the authorization URL in your browser")
            print("   2. Login and grant consent")
            print("   3. You'll be redirected back here automatically")
            print("   4. Tokens will be displayed and saved")
            print("\n⏹️  Press Ctrl+C to stop the server")
            print("=" * 60 + "\n")

            httpd.serve_forever()
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Error: Port {PORT} is already in use!")
            print(
                f"   Please stop any other process using port {PORT} and try again."
            )
            sys.exit(1)
        else:
            raise
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped.")
        sys.exit(0)


if __name__ == "__main__":
    main()
