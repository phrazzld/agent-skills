#!/usr/bin/env python3
"""Minimal Gemini embeddings client using the REST API."""

from __future__ import annotations

import json
import os
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen


def api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not key:
        raise RuntimeError("GEMINI_API_KEY or GOOGLE_API_KEY required")
    return key


def embed_texts(
    *,
    model: str,
    texts: list[str],
    output_dimensionality: int,
    task_type: str,
    user_agent: str,
) -> list[list[float]]:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:batchEmbedContents?key={quote(api_key(), safe='')}"
    )
    payload = {
        "requests": [
            {
                "model": f"models/{model}",
                "content": {"parts": [{"text": text}]},
                "taskType": task_type,
                "outputDimensionality": output_dimensionality,
            }
            for text in texts
        ]
    }
    req = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": user_agent,
        },
        method="POST",
    )

    try:
        with urlopen(req, timeout=60) as resp:
            body = json.loads(resp.read())
    except HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Gemini embeddings request failed: {e.code} {detail}") from e

    embeddings = body.get("embeddings")
    if not isinstance(embeddings, list):
        raise RuntimeError(f"Unexpected embeddings response: {body}")

    values = []
    for embedding in embeddings:
        vector = embedding.get("values")
        if not isinstance(vector, list):
            raise RuntimeError(f"Unexpected embedding payload: {embedding}")
        values.append(vector)
    return values
