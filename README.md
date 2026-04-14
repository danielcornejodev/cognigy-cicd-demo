# Cognigy CI/CD Pipeline — Proof of Concept

A GitHub Actions pipeline that automates the promotion of Cognigy.AI virtual agent builds across Dev, QA, and Production environments using snapshots.

## Overview
You merge code to main branch
↓
GitHub Actions automatically promotes Dev → QA
↓
Smoke test runs against QA endpoint
↓
You manually trigger promotion to Prod
↓
Prod endpoint updated to new snapshot

## Repository Structure
cognigy-cicd-demo/
├── .github/
│   └── workflows/
│       ├── deploy-qa.yml        # Auto-triggers on push to main
│       └── deploy-prod.yml      # Manual trigger with approval gate
├── scripts/
│   ├── create-and-download-snapshot.sh   # Uses Cognigy CLI to snapshot Dev
│   ├── upload-snapshot.sh                # Uploads .csnap to target environment
│   ├── update-endpoint.sh                # Points endpoint at new snapshot
│   └── smoke-test.sh                     # Sends test message, validates response
├── playbooks/
│   └── playbooks.json           # Cognigy playbook definitions for regression tests
├── snapshots/                   # Gitignored — temp storage during pipeline run
├── .gitignore
└── README.md

## Environments

| Environment | Cognigy Project | Purpose |
|---|---|---|
| Dev | cognigy-demo-dev | Where you build and make changes |
| QA | cognigy-demo-qa | Automatically receives every push to main |
| Prod | cognigy-demo-prod | Manually promoted, requires approval |

## Prerequisites

- Cognigy.AI trial tenant at [trial.cognigy.ai](https://trial.cognigy.ai)
- Three Cognigy projects created: `cognigy-demo-dev`, `cognigy-demo-qa`, `cognigy-demo-prod`
- Each project has a Main flow and a REST endpoint configured
- GitHub account (Free plan with public repo, or Pro/Enterprise for private repo with approval gates)
- Node.js 18+ (handled automatically by the pipeline runner)

## GitHub Secrets Required

Navigate to **Settings → Secrets and variables → Actions** and add the following:

| Secret Name | Description |
|---|---|
| `COGNIGY_BASE_URL` | `https://api-trial.cognigy.ai` |
| `DEV_API_KEY` | Cognigy API key for the Dev project |
| `QA_API_KEY` | Cognigy API key for the QA project |
| `PROD_API_KEY` | Cognigy API key for the Prod project |
| `DEV_PROJECT_ID` | Cognigy project ID for Dev |
| `QA_PROJECT_ID` | Cognigy project ID for QA |
| `PROD_PROJECT_ID` | Cognigy project ID for Prod |
| `QA_ENDPOINT_ID` | REST endpoint ID in QA project |
| `PROD_ENDPOINT_ID` | REST endpoint ID in Prod project |
| `QA_FLOW_ID` | Main flow ID in QA project |
| `PROD_FLOW_ID` | Main flow ID in Prod project |
| `QA_ENDPOINT_URL` | Full REST endpoint URL for QA |
| `PROD_ENDPOINT_URL` | Full REST endpoint URL for Prod |

## Pipeline Flow

### Deploy to QA (Automatic)

Triggered automatically on every push to the `main` branch.

1. Installs the Cognigy CLI
2. Generates a `config.json` from GitHub Secrets at runtime
3. Creates a named snapshot in Dev (e.g. `release-20260413-120000`)
4. CLI handles prepare-download and downloads the `.csnap` file
5. Uploads the `.csnap` to QA via REST API
6. Updates the QA endpoint to point at the new snapshot
7. Waits 20 seconds for the endpoint to stabilize
8. Runs a smoke test — sends `hello` to the QA bot and validates the response

### Deploy to Production (Manual)

Triggered manually via **Actions → Deploy to Production → Run workflow**.

Follows the same steps as QA but targets the Prod environment. If the repository is public, a required reviewer approval gate pauses the job before any changes reach Prod.

## How to Trigger a Deployment

### To QA
```bash
git add .
git commit -m "Your change description"
git push origin main
```
Then watch the run live under the **Actions** tab.

### To Production
1. Go to **Actions** tab in GitHub
2. Click **Deploy to Production** in the left sidebar
3. Click **Run workflow → Run workflow**
4. If approval gate is configured: click **Review deployments → Approve and deploy**

## How to Test the Bot Manually

After a successful QA deployment, send a test message to the QA endpoint:

```bash
curl -s -X POST "YOUR_QA_ENDPOINT_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "sessionId": "test-session-1",
    "text": "hello"
  }'
```

Expected response contains: `Hello from DEV`

## Proof of Concept Walkthrough

1. In `cognigy-demo-dev`, set your Say Node text to `Hello from DEV - Version 1.0`
2. Push any change to `main` — watch the pipeline promote it to QA automatically
3. Hit the QA endpoint — confirm it returns `Version 1.0`
4. Update the Say Node to `Hello from DEV - Version 2.0` in Cognigy
5. Push again — pipeline runs, QA updates without you touching it manually
6. Manually trigger the Prod deployment — confirm Prod now also returns `Version 2.0`

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Unable to authenticate via api key` | `DEV_API_KEY` secret missing or wrong value | Regenerate API key in Cognigy, update secret |
| `No config.json file found` | Script not writing config before CLI runs | Check that all three `CAI_*` env vars are set in the workflow step |
| Snapshot file not found after create | CLI saved to unexpected path | Check `find ./snapshots -type f` output in logs |
| Upload returns empty snapshot ID | API response field name different than expected | Log full upload response and check field name |
| Smoke test fails | Endpoint not yet serving new snapshot | Increase `sleep 20` to `sleep 40` in workflow |
| `jq: command not found` | jq not installed in runner | Confirm `sudo apt-get install -y jq` step runs before scripts |

## Dependencies

- [Cognigy CLI](https://github.com/Cognigy/Cognigy-CLI) — `@cognigy/cognigy-cli` via npm
- [jq](https://stedolan.github.io/jq/) — JSON parsing in bash scripts
- GitHub Actions ubuntu-latest runner
- Node.js 18

## Notes

- Snapshots do not include Endpoints — endpoint configuration stays per-environment, only the bot logic transfers
- The trial tenant has a limit of 10 snapshots per project — old snapshots should be cleaned up periodically in the Cognigy UI under **Deploy → Snapshots**
- `config.json` is generated at runtime and gitignored — never commit it as it contains your API key
- The `snapshots/` folder is gitignored — snapshot files are temporary and only exist during a pipeline run# re-trigger after API key refresh
# fix base URL to us regional endpoint
# trigger after adding QA_API_KEY secret
# trigger after endpoint id update
