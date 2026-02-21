#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os

class Handler(BaseHTTPRequestHandler):
    def _send_json(self, obj, code=200):
        self.send_response(code)
        self.send_header('Content-Type','application/json')
        self.end_headers()
        self.wfile.write(json.dumps(obj).encode('utf8'))

    def do_GET(self):
        if self.path == '/health':
            self._send_json({'status':'ok'})
            return

        if self.path == '/api/v1/sync/full_data':
            products = [
                {'id':'PROD-001','name':'Coffee','price':3.5,'category_id':'CAT-001'},
                {'id':'PROD-002','name':'Tea','price':2.5,'category_id':'CAT-001'},
                {'id':'PROD-003','name':'Sandwich','price':5.99,'category_id':'CAT-002'}
            ]
            categories = [
                {'id':'CAT-001','name':'Beverages'},
                {'id':'CAT-002','name':'Food'}
            ]
            self._send_json({'products':products,'categories':categories,'synced_at':''})
            return

        if self.path == '/api/v1/sync/products':
            products = [
                {'id':'PROD-001','name':'Coffee','price':3.5},
                {'id':'PROD-002','name':'Tea','price':2.5}
            ]
            self._send_json({'products':products,'synced_at':''})
            return

        if self.path == '/api/v1/sync/categories':
            categories = [
                {'id':'CAT-001','name':'Beverages'},
                {'id':'CAT-002','name':'Food'}
            ]
            self._send_json({'categories':categories,'synced_at':''})
            return

        self.send_response(404)
        self.end_headers()

if __name__ == '__main__':
    port = int(os.environ.get('PORT','8080'))
    server = HTTPServer(('0.0.0.0', port), Handler)
    print('Sync API listening on', port)
    server.serve_forever()
