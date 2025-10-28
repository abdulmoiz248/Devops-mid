## DevOps Report

This document summarizes the DevOps-related aspects of the Image Processing System: technologies used, pipeline design, secret management, testing process, and lessons learned.

---

### 1) Technologies used

- Application: Python 3.x, Flask
- Background tasks: Celery
- Message broker / result backend: Redis (can be replaced by RabbitMQ for queuing)
- Database: PostgreSQL
- ORM / Migrations: SQLAlchemy, Alembic / Flask-Migrate
- Containerization (recommended): Docker
- CI/CD: GitHub Actions (example pipeline below) or other CI systems (GitLab CI, Azure DevOps)
- Secrets management: environment variables, Docker secrets, GitHub Actions Secrets, HashiCorp Vault (optional)
- Testing: pytest for unit tests and integration tests

---

### 2) Pipeline design

The CI/CD pipeline is designed for continuous integration and continuous deployment. The goals are: run tests, linting and security scans on PRs, build artifacts and optionally deploy to staging/production on merge to main.

High-level steps (per push/PR):

1. Checkout code
2. Set up Python environment
3. Install dependencies
4. Run linters (optional: flake8, pylint)
5. Run unit tests (pytest)
6. Build Docker image (optional)
7. Push image to registry (for main branch)
8. Deploy to environment using infrastructure automation (e.g., GitHub Actions + Terraform / Helm)


flowchart LR
  A[Push / PR] --> B[CI: Setup Python]
  B --> C[Install deps]
  C --> D[Lint & Static Analysis]
  D --> E[Run pytest]
  E --> F{Tests pass?}
  F -- No --> G[Fail & Report]
  F -- Yes --> H[Build Docker image]
  H --> I[Push image to registry]
  I --> J[Deploy to staging / production]
For deployments, add a separate `deploy` job that runs on pushes to `main` and uses secrets to authenticate to the container registry and cloud provider.

---

### 3) Secret management strategy

Principles:
- Never commit secrets to the repository.
- Use environment variables at runtime.
- Use per-environment secrets (separate for dev/staging/prod).
- Rotate secrets regularly and log access.



1. Local development
   - Use a local `.env` file (gitignored) and `python-dotenv` or `flask`'s instance folder to load env vars.
   - Example: `instance/.env` with `DATABASE_URL`, `CELERY_BROKER_URL`, etc. Ensure `instance/` is in `.gitignore`.

2. CI (GitHub Actions)
   - Store secrets in GitHub Actions Secrets and reference them as `secrets.MY_SECRET` in workflows.

3. Containerized production
   - Use Docker secrets with orchestrators (Docker Swarm, Kubernetes). For Kubernetes, use Secrets or integration with Vault.

4. Centralized secrets manager (recommended for production)
   - HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, or GCP Secret Manager.
   - The pipeline retrieves short-lived credentials at deploy time.

Short list of practical steps to implement now:
- Ensure `.env` and `instance/` are in `.gitignore`.
- Use `config.py` to read from environment variables; provide `config_test.py` for CI.
- Configure GitHub Actions to read critical values from repository or organization secrets.

---

### 4) Testing process

Testing layers:

1. Unit tests
   - Fast, isolated tests for functions and utilities.
   - Use pytest and fixtures; mock external network calls (e.g., image downloads) with `requests-mock` or `responses`.

2. Integration tests
   - Tests that exercise multiple components: Flask routes + DB (use a test database or test containers).
   - Use `app/config_test.py` to point to a temporary test DB (SQLite in-memory or a dedicated Postgres test instance).

3. End-to-end tests (optional)
   - Deploy to a staging environment and run e2e flows (upload CSV, process images, webhook notifications).

Test automation recommendations:

- Run unit tests on every PR via CI.
- Run integration tests on PR merge to staging (may require standing services or ephemeral test containers).
- Use test data and fixtures; avoid calling real external services by mocking or using VCR-like recordings.



### 5) Lessons learned

- Keep configuration environment-driven: minimize direct config edits and centralize sensitive values in environment variables.
- Use small, focused CI jobs that fail early (linting and unit tests first) to provide fast feedback.
- Mock external network calls in unit tests — network-dependent tests are flaky and slow.
- Provide a lightweight `config_test.py` to make tests reproducible in CI without real third-party services.
- Use containerization (Docker) to make local and CI environments more consistent.

---


