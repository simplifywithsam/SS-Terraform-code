"""Sample Python web service for the IEC ECS Fargate deployment."""
import os
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)

APP_NAME = os.getenv("APP_NAME", "iec-sample-app")
APP_ENV = os.getenv("APP_ENV", "dev")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")


@app.get("/")
def index():
    return jsonify(
        message=f"Hello from {APP_NAME} running on ECS Fargate",
        environment=APP_ENV,
        version=APP_VERSION,
        host=socket.gethostname(),
        time=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/health")
def health():
    # Used by the ALB target group and the ECS container health check
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    # Local development only; inside the container gunicorn serves the app
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
