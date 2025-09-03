from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from the DevOps Project!"

@app.route('/api/status')
def status():
    return jsonify(status="healthy")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)