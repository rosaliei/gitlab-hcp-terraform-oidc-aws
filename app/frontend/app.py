import json
import os
import urllib.request

from flask import Flask

app = Flask(__name__)
BACKEND_URL = os.environ.get("BACKEND_URL", "http://backend:8000")


def get_message():
    with urllib.request.urlopen(f"{BACKEND_URL}/api/hello", timeout=3) as response:
        return json.load(response)["message"]


@app.get("/")
def index():
    try:
        message = get_message()
    except Exception:
        message = "backend not reachable"
    return f"<h1>Open Innovation AI</h1><p>{message}</p>"


@app.get("/healthz")
def healthz():
    return "ok"
