# 🚀 Flask CI/CD Pipeline

> Automated testing and deployment of a Flask web application using **GitHub Actions**, **Docker**, **Nginx**, and **AWS EC2**.

![CI/CD Pipeline](https://img.shields.io/github/actions/workflow/status/YOUR_USERNAME/flask-cicd-pipeline/ci-cd.yml?branch=main&label=CI%2FCD&style=flat-square)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.0-000000?style=flat-square&logo=flask&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=flat-square&logo=nginx&logoColor=white)
![AWS EC2](https://img.shields.io/badge/AWS_EC2-FF9900?style=flat-square&logo=amazonaws&logoColor=white)

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Pipeline Flow](#-pipeline-flow)
- [Local Development](#-local-development)
- [AWS EC2 Setup](#-aws-ec2-setup)
- [GitHub Secrets Setup](#-github-secrets-setup)
- [API Endpoints](#-api-endpoints)
- [Tech Stack](#-tech-stack)

---

## 🏗 Architecture

```
Developer
    │
    │  git push origin main
    ▼
┌─────────────────────────────────────────────────────┐
│                  GitHub Actions                     │
│                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────┐ │
│  │  Test    │──▶│ Build+Push   │──▶│  Deploy     │ │
│  │ (pytest) │   │ Docker Image │   │  via SSH    │ │
│  └──────────┘   └──────────────┘   └─────────────┘ │
└─────────────────────────────────────────────────────┘
                         │
                         │  SSH
                         ▼
               ┌─────────────────┐
               │    AWS EC2      │
               │                 │
               │  ┌───────────┐  │
               │  │   Nginx   │  │  ← Port 80
               │  │  (proxy)  │  │
               │  └─────┬─────┘  │
               │        │        │
               │  ┌─────▼─────┐  │
               │  │   Flask   │  │  ← Port 5000
               │  │  (gunicorn│  │
               │  └───────────┘  │
               └─────────────────┘
```

---

## 📁 Project Structure

```
flask-cicd-pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions pipeline (3 jobs)
│
├── app/
│   ├── app.py                 # Flask application
│   └── requirements.txt       # Python dependencies
│
├── tests/
│   └── test_app.py            # pytest unit tests
│
├── nginx/
│   └── nginx.conf             # Reverse proxy + security headers
│
├── scripts/
│   ├── setup_ec2.sh           # One-time EC2 bootstrap script
│   └── deploy.sh              # Manual deploy script
│
├── Dockerfile                 # Multi-stage build (builder → production)
├── docker-compose.yml         # Production stack
├── docker-compose.dev.yml     # Development overrides
├── .env.example               # Environment variables template
└── README.md
```

---

## 🔄 Pipeline Flow

Every `git push` to `main` triggers **3 sequential jobs**:

```
push to main
     │
     ▼
┌─────────────────┐
│  1. TEST        │  pytest tests/ -v
│                 │  (blocks build if tests fail)
└────────┬────────┘
         │ ✅ pass
         ▼
┌─────────────────┐
│  2. BUILD       │  docker build (multi-stage)
│                 │  docker push → Docker Hub
│                 │  Tags: latest + sha-XXXXXXX
└────────┬────────┘
         │ ✅ pushed
         ▼
┌─────────────────┐
│  3. DEPLOY      │  SSH into EC2
│                 │  docker pull latest
│                 │  docker compose up -d
│                 │  curl /health → verify
└─────────────────┘
```

> **Pull Requests**: Only the `test` job runs — PRs cannot deploy.

---

## 💻 Local Development

### Prerequisites
- Docker Desktop installed
- Python 3.12+

### Option A — Run with Docker (recommended)

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/flask-cicd-pipeline.git
cd flask-cicd-pipeline

# Start dev stack (live-reload enabled)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build

# App available at http://localhost:5000
```

### Option B — Run with Python directly

```bash
cd flask-cicd-pipeline

# Create virtual environment
python -m venv .venv
source .venv/bin/activate     # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r app/requirements.txt

# Run tests
pytest tests/ -v

# Start app
cd app && python app.py
```

### Run Tests Only

```bash
pytest tests/ -v --tb=short
```

---

## ☁️ AWS EC2 Setup

### 1. Launch EC2 Instance

| Setting        | Value                    |
|----------------|--------------------------|
| AMI            | Ubuntu Server 22.04 LTS  |
| Instance type  | t2.micro (free tier)     |
| Storage        | 20 GB gp3                |
| Security Group | SSH (22), HTTP (80)      |

### 2. Bootstrap the Server

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/flask-cicd-pipeline/main/scripts/setup_ec2.sh | bash

# Log out and back in (apply docker group)
exit
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

The script installs Docker, Docker Compose, clones your repo, and configures the firewall.

---

## 🔑 GitHub Secrets Setup

Go to **Settings → Secrets and variables → Actions** in your GitHub repo and add:

| Secret Name           | Value                            | Where to get it                        |
|-----------------------|----------------------------------|----------------------------------------|
| `DOCKER_HUB_USERNAME` | Your Docker Hub username         | hub.docker.com                         |
| `DOCKER_HUB_TOKEN`    | Docker Hub access token          | Hub → Account Settings → Security      |
| `EC2_HOST`            | Your EC2 public IP or DNS        | AWS Console → EC2 → Instance details   |
| `EC2_USER`            | `ubuntu`                         | Default for Ubuntu AMIs                |
| `EC2_SSH_KEY`         | Contents of your `.pem` key file | `cat your-key.pem`                     |

---

## 🛣 API Endpoints

| Method | Endpoint    | Description                    |
|--------|-------------|-------------------------------|
| GET    | `/`         | Web UI — pipeline status page |
| GET    | `/health`   | Health check (used by Docker) |
| GET    | `/api/info` | App metadata as JSON          |

### Example responses

```bash
# Health check
curl http://YOUR_EC2_IP/health
# → {"status": "healthy", "version": "1.0.0"}

# API info
curl http://YOUR_EC2_IP/api/info
# → {"app": "Flask CI/CD Demo", "environment": "production", "version": "1.0.0"}
```

---

## 🛠 Tech Stack

| Layer       | Technology            | Purpose                            |
|-------------|----------------------|------------------------------------|
| App         | Flask 3 + Gunicorn   | Python web app + WSGI server       |
| Tests       | pytest + pytest-flask | Unit & integration tests           |
| Containers  | Docker (multi-stage) | Reproducible, secure builds        |
| Orchestration | Docker Compose     | Multi-container management         |
| Proxy       | Nginx                | Reverse proxy, security headers    |
| CI/CD       | GitHub Actions       | Automated test → build → deploy    |
| Registry    | Docker Hub           | Docker image storage               |
| Cloud       | AWS EC2 (Ubuntu)     | Production server                  |

---


