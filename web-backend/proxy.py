"""Lightweight Python proxy to forward web-backend requests to Appwrite.
Start with: python3 proxy.py --port 9000 --target http://localhost:8080
"""
import argparse
import http.client
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs


DEFAULT_TARGET = os.environ.get("APPWRITE_TARGET", "http://localhost:8080")
DEFAULT_PORT = int(os.environ.get("PORT", "9000"))


class ProxyHandler(BaseHTTPRequestHandler):
    """Minimal proxy handler for Appwrite REST calls."""

    def _set_cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS"
        )
        self.send_header(
            "Access-Control-Allow-Headers",
            "Content-Type, X-Appwrite-Project, X-Appwrite-Key",
        )

    def do_OPTIONS(self) -> None:  # noqa: N802 (http.server naming)
        self.send_response(200)
        self._set_cors()
        self.end_headers()

    def _proxy(self) -> None:
        parsed_path = urlparse(self.path)
        query = parse_qs(parsed_path.query)
        target_path = query.get("path", ["/v1/databases"])[0]

        target_url = urlparse(self.server.target)
        connection_cls = (
            http.client.HTTPSConnection if target_url.scheme == "https" else http.client.HTTPConnection
        )
        conn = connection_cls(target_url.hostname, target_url.port or (443 if target_url.scheme == "https" else 80))

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length else None

        forward_headers = {
            "Content-Type": self.headers.get("Content-Type", "application/json"),
            "X-Appwrite-Project": self.headers.get("X-Appwrite-Project", ""),
            "X-Appwrite-Key": self.headers.get("X-Appwrite-Key", ""),
        }

        try:
            conn.request(self.command, target_path, body=body, headers=forward_headers)
            resp = conn.getresponse()
            data = resp.read()

            self.send_response(resp.status)
            self._set_cors()
            self.send_header("Content-Type", resp.getheader("Content-Type", "application/json"))
            self.end_headers()
            self.wfile.write(data)
        except Exception as exc:  # pragma: no cover - runtime safety
            self.send_response(500)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            error_message = f"Proxy error: {exc}"
            self.wfile.write(f"{{\"error\": \"{error_message}\"}}".encode())
        finally:
            conn.close()

    # http.server requires method-specific handlers
    def do_GET(self) -> None:  # noqa: N802
        self._proxy()

    def do_POST(self) -> None:  # noqa: N802
        self._proxy()

    def do_PUT(self) -> None:  # noqa: N802
        self._proxy()

    def do_PATCH(self) -> None:  # noqa: N802
        self._proxy()

    def do_DELETE(self) -> None:  # noqa: N802
        self._proxy()


def run_server(port: int, target: str) -> None:
    server_address = ("", port)
    handler_cls = ProxyHandler
    httpd = HTTPServer(server_address, handler_cls)
    httpd.target = target  # type: ignore[attr-defined]
    print(f"Proxy forwarding to {target} on port {port} (CTRL+C to stop)")
    httpd.serve_forever()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Lightweight Appwrite proxy")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Proxy listen port")
    parser.add_argument(
        "--target",
        type=str,
        default=DEFAULT_TARGET,
        help="Appwrite endpoint base (e.g., http://localhost:8080)",
    )
    args = parser.parse_args()
    run_server(args.port, args.target)
