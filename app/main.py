
from flask import Flask, jsonify, request, abort

app = Flask(__name__)

users = {}
next_user_id = 1

@app.route('/', methods=['GET'])
def hello_world():
    return jsonify({'message': 'Hello, World!'})

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'ok'}), 200

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({'users': list(users.values())}), 200

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()

    # Проверка обязательных полей
    if not data or 'name' not in data:
        abort(400, description="Field 'name' is required")

    global next_user_id
    user_id = next_user_id
    next_user_id += 1

    user ={
        "id": user_id,
        "name": data['name'],
        "email": data.get('email', '')
    }

    users[user_id] = user
    return jsonify({'user': user}), 201


@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in users:
        return jsonify({'error': 'User not found'}), 404

    del users[user_id]
    return jsonify({}),204

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
