FROM python:3.12-slim

LABEL org.opencontainers.image.source=https://github.com/rosaliei/gitlab-hcp-terraform-oidc-aws

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

USER 1000
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
