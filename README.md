# CloudComputing Project

## Dependencies

Before running the container locally, ensure you have the following installed on your system:

- **Podman** – Required to pull, build, and run containers.  
  [Install Podman](https://podman.io/getting-started/installation)

- **Internet access** – Needed to pull the container image or download dependencies.

- *(Optional)* **Web browser** – To view the locally hosted web application (e.g., Chrome, Firefox, or Edge).

---

## Running the Project with Podman

This project provides a **web interface served by nginx** (displaying images from the `images/` directory) and includes services such as **MySQL**, **Redis**, **Kafka + Spark Mini**, **Prometheus**, **Grafana**, and **cAdvisor** for monitoring and analytics.

You can run the prebuilt container image directly from the GitHub Container Registry (published by the GitHub Actions pipeline) or build it locally.

---

### 🐋 Option 1: Pull and Run the Prebuilt Image (from GitHub CI/CD)

The GitHub Actions pipeline builds and publishes the image to **GitHub Container Registry (GHCR)** on every push to `main` and on version tags.

1. **Log in to GitHub Container Registry**  
   Replace `<OWNER>` and `<TOKEN>` as needed (a PAT or use a scoped token):
   ```bash
   podman login ghcr.io -u <OWNER> -p <TOKEN>
   ```

2. **Pull the latest image published by CI**  
   Replace `<OWNER>` and `<REPO>` with your GitHub org/user and repository name:
   ```bash
   podman pull ghcr.io/<OWNER>/<REPO>:latest
   # or a specific version/tag produced by the pipeline
   podman pull ghcr.io/<OWNER>/<REPO>:<GIT_TAG_OR_SHA>
   ```

3. **Run the container locally (nginx on port 80 inside the container)**  
   ```bash
   podman run -d      -p 8080:80      -p 9090:9090      -p 3000:3000      -p 8081:8081      -p 9092:9092      -p 3306:3306      -p 6379:6379      ghcr.io/<OWNER>/<REPO>:latest
   ```

4. **Open the web interface**  
   ```
   http://localhost:8080
   ```

---

### 🏗️ Option 2: Build and Run Locally

If you want to build your own image from the included `Dockerfile`:

1. **Build the container image**
   ```bash
   podman build -t cloudcomputing-app -f Dockerfile .
   ```

2. **Run it locally**
   ```bash
   podman run -d      -p 8080:80      -p 9090:9090      -p 3000:3000      -p 8081:8081      -p 9092:9092      -p 3306:3306      -p 6379:6379      cloudcomputing-app
   ```

3. **View in browser**
   ```
   http://localhost:8080
   ```

---

### 🧩 Using Podman Compose

Use the included `podman-compose.yml` to orchestrate the stack:

```bash
podman compose up --build
# To stop all services
podman compose down
```

This will start nginx (serving the site) plus Prometheus, Grafana, cAdvisor, Kafka, MySQL, and Redis.

---

## CI/CD via GitHub Actions (Build & Publish to GHCR)

A sample workflow is included at `.github/workflows/container-build.yml` to build the container and publish it to GHCR.

**Key points:**
- Publishes `ghcr.io/<OWNER>/<REPO>:latest` on pushes to `main`
- Publishes `ghcr.io/<OWNER>/<REPO>:$GIT_TAG` on tag pushes (e.g., `v1.0.0`)
- Uses the repository’s `GITHUB_TOKEN` with `packages: write` permission
- Requires the repository visibility to allow GHCR pushes (Organization settings may apply)

**After CI publishes the image, run locally:**
```bash
podman login ghcr.io -u <OWNER> -p <TOKEN>
podman pull ghcr.io/<OWNER>/<REPO>:latest
podman run -d -p 8080:80 ghcr.io/<OWNER>/<REPO>:latest
```

---

### ⚙️ Notes

- The container runs **nginx** to host `index.html` and static assets; caching and gzip are configured via `nginx.conf`.
- Exposed ports inside the container:
  - **80** (nginx) • **9090** (Prometheus) • **3000** (Grafana) • **8081** (cAdvisor) • **9092** (Kafka) • **3306** (MySQL) • **6379** (Redis) • **4040** (Spark UI)
- Use `podman ps` to view running containers and `podman logs <container_id>` to debug issues.
- Stop the container:
  ```bash
  podman stop <container_id>
  ```

---

### 🌐 Web Access

Once the container is running, open your browser to:
```
http://localhost:8080
```
