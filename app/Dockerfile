# Base image can be pulled through an Artifactory Docker remote repo, e.g.
#   --build-arg BASE_IMAGE=<artifactory-host>/<docker-remote>/python:3.12-slim
ARG BASE_IMAGE=python:3.12-slim
FROM ${BASE_IMAGE}

# Optional: point pip at an Artifactory PyPI remote repo
#   --build-arg PIP_INDEX_URL=https://<artifactory-host>/artifactory/api/pypi/<pypi-remote>/simple
ARG PIP_INDEX_URL=""

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Run as a non-root user
RUN groupadd --system app && useradd --system --gid app --no-create-home app

COPY requirements.txt .
RUN if [ -n "$PIP_INDEX_URL" ]; then \
      pip install --no-cache-dir --index-url "$PIP_INDEX_URL" -r requirements.txt; \
    else \
      pip install --no-cache-dir -r requirements.txt; \
    fi

COPY app.py .

USER app
EXPOSE 8080

# ECS uses the healthCheck in the task definition; this one helps with local runs
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health', timeout=3)" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", \
     "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "app:app"]
