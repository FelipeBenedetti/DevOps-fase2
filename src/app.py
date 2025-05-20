from flask import Flask, jsonify, request
import os
import time
import prometheus_client
from prometheus_client import Counter, Histogram
import logging

# Configuração de logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime )s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("devops-app")

# Métricas Prometheus
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
)

app = Flask(__name__)


# Middleware para métricas
@app.before_request
def before_request():
    request.start_time = time.time()


@app.after_request
def after_request(response):
    request_latency = time.time() - request.start_time
    REQUEST_LATENCY.labels(method=request.method, endpoint=request.path).observe(
        request_latency
    )

    REQUEST_COUNT.labels(
        method=request.method, endpoint=request.path, status=response.status_code
    ).inc()

    # Logging
    logger.info(
        f"Request: {request.method} {request.path} - "
        f"Status: {response.status_code} - "
        f"Latency: {request_latency:.4f}s"
    )

    return response


# Endpoint para métricas Prometheus
@app.route("/metrics")
def metrics():
    return prometheus_client.generate_latest()


@app.route("/health", methods=["GET"])
def health_check():
    """Endpoint para verificação de saúde da aplicação."""
    return jsonify({"status": "healthy", "version": "2.0.0"})


@app.route("/", methods=["GET"])
def home():
    """Página inicial da aplicação."""
    return jsonify(
        {
            "message": "Bem-vindo à API de demonstração do Projeto DevOps",
            "environment": os.environ.get("FLASK_ENV", "production"),
            "endpoints": [
                "/health - Verificação de saúde",
                "/metrics - Métricas Prometheus",
            ],
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
