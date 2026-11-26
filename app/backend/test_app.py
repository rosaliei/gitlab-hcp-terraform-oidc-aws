from app import app


def test_hello():
    response = app.test_client().get("/api/hello")
    assert response.status_code == 200
    assert response.json["message"] == "Hello from backend"


def test_healthz():
    assert app.test_client().get("/healthz").status_code == 200
