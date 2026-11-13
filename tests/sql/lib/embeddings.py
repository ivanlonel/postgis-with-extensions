"""
A fake embeddings service for pg_vectorize's tests, run inside the extended test servers.

``python3 embeddings.py <port>`` serves, on 127.0.0.1, the API of vector-serve, the service
pg_vectorize's ``sentence-transformers/*`` models call (``vectorize.embedding_service_url``):

- ``GET /v1/info/?model_name=<model>`` gives the vectors' dimension;
- ``POST /v1/embeddings`` embeds its ``input`` texts, answering in OpenAI's format.

Each text becomes a bag-of-words vector: every lowercase word adds 1 to the dimension its CRC-32
selects. Texts sharing words are thus close, deterministically, without a model. Only the
standard library is used: the servers' Python has nothing else.
"""

from __future__ import annotations

import json
import re
import sys
import zlib
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Final
from urllib.parse import parse_qs, urlsplit

DIMENSIONS: Final = 384
"""Length of the vectors, as for sentence-transformers/all-MiniLM-L6-v2."""

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
    """Answers vector-serve's requests."""

    def _reply(self, payload: object) -> None:
        body = json.dumps(payload).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        """Describe a model: the dimension of its vectors (pg_vectorize requires every field)."""
        url = urlsplit(self.path)
        if url.path.rstrip("/") != "/v1/info":
            self.send_error(404)
            return
        model = parse_qs(url.query).get("model_name", [""])[0]
        self._reply({"model": model, "embedding_dimension": DIMENSIONS, "max_seq_len": 256})

    def do_POST(self) -> None:
        """Embed the request's ``input`` (a string or a list of strings)."""
        if urlsplit(self.path).path.rstrip("/") != "/v1/embeddings":
            self.send_error(404)
            return
        request = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
        texts = request["input"] if isinstance(request["input"], list) else [request["input"]]
        self._reply(
            {
                "object": "list",
                "data": [
                    {"object": "embedding", "index": index, "embedding": embed(text)}
                    for index, text in enumerate(texts)
                ],
                "model": request.get("model", ""),
                "usage": {"prompt_tokens": 0, "total_tokens": 0},
            }
        )


def main() -> None:
    """Serve on 127.0.0.1, at the port given as the only argument, until killed."""
    HTTPServer(("127.0.0.1", int(sys.argv[1])), EmbeddingsHandler).serve_forever()


if __name__ == "__main__":
    main()
