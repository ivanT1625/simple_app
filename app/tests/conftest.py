import pytest
import sys
import os

# Получаем путь к корневой директории проекта (simple_app/)
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Добавляем корневую директорию в начало sys.path, если её там ещё нет
if project_root not in sys.path:
    sys.path.insert(0, project_root)


@pytest.fixture
def client():
    # Импортируем app только после настройки путей
    from app.main import app
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client
