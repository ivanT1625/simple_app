import pytest
import json

import app


# @pytest.fixture
# def client():
#     app.config['TESTING'] = True
#     with app.test_client() as client:
#         yield client

def test_get_root(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json == {"message": "Hello, World!"}

def test_get_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json == {"status": "ok"}

def test_get_users_empty(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    assert response.json == {"users": []}

def test_post_users_success(client):
    user_data = {"name": "John Doe", "email": "john@example.com"}
    response = client.post('/api/users',
                        data=json.dumps(user_data),
                        content_type='application/json')
    assert response.status_code == 201

    assert 'user' in response.json
    assert 'id' in response.json['user']
    assert response.json['user']['name'] == "John Doe"
    assert response.json['user']['email'] == "john@example.com"

# def test_post_users_validation_error(client):
#     invalid_data = {}
#     response = client.post('/api/users',
#                         data=json.dumps(invalid_data),
#                         content_type='application/json')
#     print("Status code:", response.status_code)
#     print("Response data (raw):", response.data)
#     print("JSON response:", response.get_json())
#     assert response.status_code == 400
#
#     json_response = response.get_json()
#     assert json_response is not None
#     expected_error_text = b'Field &#39;name&#39; is required'
#     assert expected_error_text in response.data

def test_delete_user_not_found(client):
    response = client.delete('/api/users/999')
    assert response.status_code == 404
    json_response = response.get_json()
    assert json_response is not None
    assert 'error' in json_response
    assert json_response['error'] == 'User not found'
