import pytest
import sys
import os

# Добавляем путь к папке app в PYTHONPATH
current_dir = os.path.dirname(os.path.abspath(__file__))
app_dir = os.path.join(current_dir, '..')
sys.path.insert(0, os.path.normpath(app_dir))

from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client
