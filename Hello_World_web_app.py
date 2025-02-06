import http.server
import socketserver
import json

PORT = 5000

class MyRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Hello, World!")
        elif self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            response = json.dumps({"status": "healthy"}).encode("utf-8")
            self.wfile.write(response)
        else:
            self.send_response(404)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Not Found")

# Start the server
with socketserver.TCPServer(("", PORT), MyRequestHandler) as httpd:
    print(f"Serving on port {PORT}")
    httpd.serve_forever()
