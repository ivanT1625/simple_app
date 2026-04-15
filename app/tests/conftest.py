import pytest
import sys
import os

# Добавляем путь к папке app в PYTHONPATH
current_dir = os.path.dirname(os.path.abspath(__file__))
app_dir = os.path.join(current_dir, '..')
app_dir_normalized = os.path.normpath(app_dir)

# Добавляем в sys.path только если его там ещё нет
if app_dir_normalized not in sys.path:
    sys.path.insert(0, app_dir_normalized)

@pytest.fixture
def client():
    # Импортируем app только после настройки путей
    from app.main import app  # Предполагаем, что app — переменная в main.py
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client
