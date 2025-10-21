# Run with Docker

This repository was originally documented for Podman. The Compose file is runtime‑agnostic,
so you can use Docker with no functional changes.

## Quick start

```bash
# 1) Build the image (from repo root)
docker build -t cloudcomputing-app .

# 2) Run with Docker Compose (recommended)
docker compose up --build -d

# 3) Or run the single container manually
docker run -d --name cloudcomputing-app \
  -p 8080:80 \
  -p 9090:9090 \
  -p 3000:3000 \
  -p 8081:8081 \
  -p 9092:9092 \
  -p 3306:3306 \
  -p 6379:6379 \
  cloudcomputing-app

# 4) Access services
# - http://localhost:8080        (nginx)
# - http://localhost:9090        (Prometheus)
# - http://localhost:3000        (Grafana)
# - http://localhost:8081        (cAdvisor)
# - Kafka on localhost:9092
# - MySQL on localhost:3306
# - Redis on localhost:6379
```

> Tip: If you’re on Docker Desktop (Mac/Windows), replace `localhost` with the VM’s IP if needed.

## Notes

- The existing `podman-compose.yml` has been duplicated to `docker-compose.yml`.
- No Podman‑specific keys were used, so the file works unchanged with Docker Compose.
- The single Dockerfile builds a unified image that runs all services under one container.


## CI: Build & Push with GitHub Actions (GHCR)

This repo includes `.github/workflows/docker-ghcr.yml` which builds the Docker image on every push
to `main` and on tags (e.g. `v1.2.3`). It pushes to GHCR using the built-in `GITHUB_TOKEN`.

**Image name:** `ghcr.io/<OWNER>/<REPO>`

> After the workflow runs once, you can pull with:
```bash
docker pull ghcr.io/<OWNER>/<REPO>:latest
```

If you prefer Docker Hub instead of GHCR, add another login step and change `images:` in the metadata step:

```yaml
- uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
# and set
# images: <your-dockerhub-user>/<repo>
```
