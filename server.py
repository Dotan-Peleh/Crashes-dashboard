#!/usr/bin/env python3
"""
🚀 Universal Dashboard Server Template

A customizable CORS-enabled HTTP server for dashboard applications requiring
Google OAuth authentication and BigQuery integration.

Features:
- CORS headers for cross-origin requests
- Cross-Origin-Opener-Policy for OAuth popups
- Configurable port and logging
- Clean startup messages with status indicators
- Graceful shutdown handling

Usage:
    python3 server.py [--port PORT] [--quiet]
"""

import http.server
import socketserver
import os
import sys
import argparse
from datetime import datetime

def parse_args():
    parser = argparse.ArgumentParser(description='Universal Dashboard Server')
    parser.add_argument('--port', type=int, default=8000, help='Port to serve on (default: 8000)')
    parser.add_argument('--quiet', action='store_true', help='Suppress request logging')
    parser.add_argument('--host', default='localhost', help='Host to bind to (default: localhost)')
    return parser.parse_args()

class UniversalCORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, quiet=False, **kwargs):
        self.quiet_mode = quiet
        super().__init__(*args, **kwargs)
    
    def end_headers(self):
        # Essential CORS headers for dashboard functionality
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Authorization')
        
        # Critical for Google OAuth popups in dashboard applications
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin-allow-popups')
        self.send_header('Cross-Origin-Resource-Policy', 'cross-origin')
        
        # Security headers
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        
        super().end_headers()

    def do_OPTIONS(self):
        """Handle preflight requests for CORS"""
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        """Custom logging to suppress noise and enhance readability"""
        if self.quiet_mode:
            return
            
        # Suppress common noise requests
        message = format % args
        if any(noise in message for noise in ["/favicon.ico", "/.well-known/", "/apple-touch-icon"]):
            return
            
        # Enhanced logging with timestamps
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {message}")

def create_handler_class(quiet=False):
    """Factory function to create handler class with configuration"""
    class ConfiguredHandler(UniversalCORSRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, quiet=quiet, **kwargs)
    return ConfiguredHandler

def main():
    args = parse_args()
    
    # Ensure server runs from script's directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    print("🚀 Universal Dashboard Server Template")
    print("=" * 50)
    print(f"📡 Serving at: http://{args.host}:{args.port}/")
    print(f"🔐 Google OAuth: COOP headers enabled")
    print(f"🌐 CORS: Full cross-origin support")
    print(f"📁 Root: {os.getcwd()}")
    if args.quiet:
        print("🔇 Quiet mode: Request logging disabled")
    print("🛑 Press Ctrl+C to stop")
    print("=" * 50)
    
    # Create configured handler
    HandlerClass = create_handler_class(quiet=args.quiet)
    
    try:
        with socketserver.TCPServer((args.host, args.port), HandlerClass) as httpd:
            print(f"✅ Server started successfully on {args.host}:{args.port}")
            print()
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print("\n" + "=" * 50)
                print("🛑 Shutting down server...")
                httpd.server_close()
                print("✅ Server stopped gracefully")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Error: Port {args.port} is already in use")
            print(f"💡 Try: python3 server.py --port {args.port + 1}")
            print("💡 Or kill existing process:")
            print(f"   lsof -ti:{args.port} | xargs kill -9")
        else:
            print(f"❌ Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()