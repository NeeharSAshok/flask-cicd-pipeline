import pytest
import sys
import os

# Add the app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_index_returns_200(client):
    """Home page should return HTTP 200."""
    response = client.get("/")
    assert response.status_code == 200


def test_health_endpoint(client):
    """Health check should return healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"


def test_api_info_endpoint(client):
    """API info should return app metadata."""
    response = client.get("/api/info")
    assert response.status_code == 200
    data = response.get_json()
    assert "app" in data
    assert "environment" in data
    assert "version" in data


def test_health_contains_version(client):
    """Health endpoint should include version field."""
    response = client.get("/health")
    data = response.get_json()
    assert "version" in data


def test_404_for_unknown_routes(client):
    """Unknown routes should return 404."""
    response = client.get("/this-route-does-not-exist")
    assert response.status_code == 404
