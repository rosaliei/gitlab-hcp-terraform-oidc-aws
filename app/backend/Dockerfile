# ---- build stage: normal python image, install dependencies into /app/deps ----
FROM python:3.11-slim-bookworm AS build

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt
COPY app.py .

# ---- run stage: distroless = only python, no shell / apt / pip, runs as non-root ----
# python version must match the build stage (3.11, Debian 12)
FROM gcr.io/distroless/python3-debian12:nonroot

LABEL org.opencontainers.image.source=https://github.com/rosaliei/gitlab-hcp-terraform-oidc-aws

WORKDIR /app
COPY --from=build /app /app
ENV PYTHONPATH=/app/deps

EXPOSE 8000
# the image entrypoint is already python3, so we only pass the arguments
CMD ["-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
