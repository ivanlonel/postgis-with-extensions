"""
A fake OpenAI embeddings API for pg_vectorize's tests, run inside the extended test servers.

``python3 embeddings.py <port>`` serves ``POST /v1/embeddings`` on 127.0.0.1. Each input text
becomes a bag-of-words vector of :data:`DIMENSIONS` (what pg_vectorize expects from OpenAI's
models): every lowercase word adds 1 to the dimension its CRC-32 selects. Texts sharing words are
thus close, deterministically, without a model. Only the standard library is used: the servers'
Python has nothing else.
"""

from __future__ import annotations

import json
import re
import sys
import zlib
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Final

DIMENSIONS: Final = 1536
"""Length of the vectors, as for OpenAI's text-embedding-3-small."""

_WORD: Final = re.compile(r"\w+")


def embed(text: str) -> list[float]:
    """
    Turn a text into its bag-of-words vector.

    :param text: The text.
    :return: The vector.
    """
    vector = [0.0] * DIMENSIONS
    for word in _WORD.findall(text.lower()):
        vector[zlib.crc32(word.encode()) % DIMENSIONS] += 1.0
    return vector


class EmbeddingsHandler(BaseHTTPRequestHandler):
    """Answers embedding requests in OpenAI's format."""

    def do_POST(self) -> None:
        """Embed the request's ``input`` (a string or a list of strings)."""
        if self.path.rstrip("/") != "/v1/embeddings":
            self.send_error(404)
            return
        request = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        texts = request["input"] if isinstance(request["input"], list) else [request["input"]]
        body = json.dumps(
            {
                "object": "list",
                "data": [
                    {"object": "embedding", "index": index, "embedding": embed(text)}
                    for index, text in enumerate(texts)
                ],
                "model": request.get("model", ""),
                "usage": {"prompt_tokens": 0, "total_tokens": 0},
            }
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> None:
    """Serve on 127.0.0.1, at the port given as the only argument, until killed."""
    HTTPServer(("127.0.0.1", int(sys.argv[1])), EmbeddingsHandler).serve_forever()


if __name__ == "__main__":
    main()
