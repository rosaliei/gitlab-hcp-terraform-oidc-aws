from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/api/hello")
def hello():
    return jsonify(message="Hello from backend")


@app.get("/healthz")
def healthz():
    return "ok"
