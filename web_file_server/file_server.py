import http.server
import socketserver
from urllib.parse import urlparse
from urllib.parse import parse_qs
import os
import base64

class MyHttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
        fileName = './' + self.path

        try:
        # list directories
            arr = os.listdir(fileName)
            for file in arr:
                self.wfile.write(bytes(file, "utf8"))
                self.wfile.write(bytes("\n", "utf8"))
        except:
        # list file content
            cond = fileName.lower().endswith(('.png', '.jpg', '.jpeg', '.tiff', '.bmp', '.gif', '.webp'))
            enc = "utf8"
            if cond:
                with open(fileName, "rb") as image:
                    f = image.read()
                    b = bytearray(f)
                    self.wfile.write(bytes(b))
                    image.close()
            else:
                try:
                    f = open(fileName, "r")
                    for x in f:
                        self.wfile.write(bytes(x, "utf8"))
                    f.close()
                except:
                    self.wfile.write(bytes("404", "utf8"))
        return
    def do_PUT(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.end_headers()

        fileName = './' + self.path
        content_len = int(self.headers.get('Content-Length'))
        post_body = self.rfile.read(content_len)
        str = post_body.decode("utf-8")

        f = open(fileName, "w")
        #create/update file + contents
        f.write(str)
        f.close()
        return
    def do_DELETE(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.end_headers()

        fileName = './' + self.path
        if os.path.exists(fileName):
            #delete file
            os.remove(fileName)
        return
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.end_headers()
        self.wfile.write(bytes("GET, POST, PUT, DELETE, OPTIONS", "utf8"))
        return

# Create an object of the above class
handler_object = MyHttpRequestHandler

PORT = 8001
my_server = socketserver.TCPServer(("", PORT), handler_object)

# Star the server
my_server.serve_forever()