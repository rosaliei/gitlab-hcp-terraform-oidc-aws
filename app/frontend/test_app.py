import app as frontend


def test_index_shows_backend_message(monkeypatch):
    monkeypatch.setattr(frontend, "get_message", lambda: "hi from test")
    response = frontend.app.test_client().get("/")
    assert response.status_code == 200
    assert b"hi from test" in response.data


def test_index_when_backend_down(monkeypatch):
    def fail():
        raise OSError("down")

    monkeypatch.setattr(frontend, "get_message", fail)
    assert b"backend not reachable" in frontend.app.test_client().get("/").data
