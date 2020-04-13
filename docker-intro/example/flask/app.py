from flask import Flask, render_template, request, make_response
import os
import socket

name = os.getenv('NAME', "Unknown")
hostname = socket.gethostname()

app = Flask(__name__)

@app.route("/", methods=['POST','GET'])
def hello():
    resp = make_response(render_template(
        'index.html',
        name=name,
        hostname=hostname,
    ))
    return resp


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=True, threaded=True)

