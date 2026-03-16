# Neo Demos — Bunnyshell AWS Mono-Repo Demo

A mono-repo demo showcasing Bunnyshell Environments with an AWS stack: **EKS**, **Lambda**, **SQS**, and **MSK** (Kafka).

## Architecture

```
┌─────────────┐    POST /messages    ┌───────────┐
│   Client    │ ──────────────────▶  │  API      │  (EKS)
└─────────────┘                      │  Express  │
                                     └─────┬─────┘
                                           │
                                           ▼
                                     ┌───────────┐
                                     │   SQS     │  (AWS)
                                     │   Queue   │
                                     └─────┬─────┘
                                      ┌────┴────┐
                                      ▼         ▼
                                ┌──────────┐ ┌──────────┐
                                │  Worker  │ │  Lambda   │
                                │  (EKS)   │ │  (AWS)    │
                                └──────────┘ └──────────┘
```

**Components:**

| Component | Type | Description |
|-----------|------|-------------|
| `aws-infra` | Terraform | Provisions SQS queue, DLQ, Lambda function, IAM roles |
| `api` | Application (EKS) | Express.js REST API — accepts messages and sends to SQS |
| `worker` | Application (EKS) | SQS consumer — long-polls and processes messages |
| `processor` | Lambda | SQS-triggered function — processes messages serverlessly |

MSK (Kafka) configuration is included in `terraform/msk.tf` but disabled by default (`enable_msk = false`) due to cost (~$200/mo) and provisioning time (~20 min).

## Mono-Repo Structure

```
├── services/api/           # API service (EKS)
├── services/worker/        # Worker service (EKS)
├── functions/processor/    # Lambda function
├── terraform/              # AWS infrastructure (SQS, Lambda, MSK)
├── .github/workflows/      # GHA + Bunnyshell CI/CD
└── bunnyshell.yaml         # Environment definition
```

All components reference the same Git repository with different `gitApplicationPath` values — the core mono-repo pattern.

## Prerequisites

- A Bunnyshell organization, project, and connected EKS cluster
- AWS credentials with permissions for: SQS, Lambda, IAM, CloudWatch Logs
- GitHub repository with the following configured:

| Type | Name | Description |
|------|------|-------------|
| Secret | `BUNNYSHELL_ACCESS_TOKEN` | Bunnyshell API token |
| Variable | `BUNNYSHELL_PROJECT_ID` | Bunnyshell project ID |
| Variable | `BUNNYSHELL_CLUSTER_ID` | Connected EKS cluster ID |
| Variable | `BUNNYSHELL_ENV_ID` | Primary environment ID (for main branch deploys) |

## Setup

### 1. Update `bunnyshell.yaml`

Replace placeholder values:

```yaml
# Replace the git repo URL in all components
gitRepo: 'https://github.com/YOUR_ORG/neo-demos.git'

# Replace AWS credentials in environmentVariablesGroups
AWS_ACCESS_KEY_ID: SECRET["your-actual-key"]
AWS_SECRET_ACCESS_KEY: SECRET["your-actual-secret"]
```

### 2. Create the environment

```bash
bns environments create \
  --from-path bunnyshell.yaml \
  --name "neo-demos" \
  --project <PROJECT_ID> \
  --k8s <CLUSTER_ID>

bns environments deploy --id <ENV_ID> --no-wait
```

### 3. Verify

```bash
# Health check
curl https://api-<env-domain>/health

# Check environment wiring
curl https://api-<env-domain>/status

# Send a message through the pipeline
curl -X POST https://api-<env-domain>/messages \
  -H 'Content-Type: application/json' \
  -d '{"body": "Hello from the demo!"}'

# Check worker logs
bns logs --component <WORKER_COMPONENT_ID>
```

## CI/CD Workflows

### Push to `main`

Triggers `bunnyshell-deploy.yaml` — redeploys the primary environment. Only changed components are rebuilt.

### Pull Request opened

Triggers `bunnyshell-preview-deploy.yaml` — creates a fully isolated ephemeral environment with its own SQS queue, Lambda function, and EKS deployments. Posts the environment URL as a PR comment.

### Pull Request closed/merged

Triggers `bunnyshell-preview-cleanup.yaml` — destroys the ephemeral environment and all associated AWS resources.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check — `{ status: "ok", version: "1.0.0" }` |
| `GET` | `/status` | Environment info — shows SQS queue URL, region, env |
| `POST` | `/messages` | Send a message — body: `{ "body": "your message" }` |

## Bunnyshell Environment Flow

```
bunnyshell.yaml defines:

  Terraform (aws-infra)
      │
      ├── exports: SQS_QUEUE_URL
      ├── exports: LAMBDA_FUNCTION_NAME
      └── exports: AWS_REGION_OUT
              │
      ┌───────┴───────┐
      ▼               ▼
  Application       Application
  (api)             (worker)
      │
      └── hosts: api-{{ env.base_domain }}

Each environment gets isolated AWS resources via {{ env.unique }}.
Clone an environment → new SQS queue, new Lambda, new pods.
```
