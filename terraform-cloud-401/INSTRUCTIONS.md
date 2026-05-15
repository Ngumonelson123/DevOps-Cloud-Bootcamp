# StegHub Terraform 401 — Terraform Cloud
## Complete End-to-End Project Guide

---

## Project Overview

This project migrates your existing Terraform AWS infrastructure to **Terraform Cloud** — HashiCorp's managed Terraform service. You will:

- Migrate `.tf` code to Terraform Cloud with VCS-driven workflows
- Use a **Public Module** from the Terraform Registry
- Build and publish a module to the **Private Module Registry**
- Configure branch-based workspaces, notifications, and automated plans
- Deploy and destroy a real S3 static website (Terramino game)

---

## Project Structure

```
terraform-cloud-401/
├── main.tf                        ← Root config (uses public + private modules)
├── backend.tf                     ← Terraform Cloud backend config
├── variables.tf                   ← All input variables
├── locals.tf                      ← Locals + AWS provider
├── outputs.tf                     ← All outputs
├── terraform.tfvars.example       ← Template (copy → terraform.tfvars)
├── .gitignore                     ← Excludes secrets + .terraform/
├── submissionfile.txt             ← Fill in and submit
│
├── terraform-aws-s3-webapp/       ← YOUR PRIVATE MODULE (publish this)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── README.md
│   └── assets/
│       └── index.html             ← Terramino game
│
└── modules/
    └── terraform-aws-compute/     ← Local EC2 module (reference)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## PHASE 1 — Prerequisites

### 1.1 Tools Required

Make sure these are installed locally:

```bash
# Check Terraform
terraform --version    # Must be >= 1.5.0

# Check Git
git --version

# Check AWS CLI
aws --version
```

Install Terraform if needed:
```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 1.2 AWS Credentials

You need an IAM user with programmatic access. Get your keys from AWS Console → IAM → Users → Security credentials.

Keep these ready:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## PHASE 2 — Terraform Cloud Setup

### 2.1 Create Account

1. Go to → https://app.terraform.io/signup/account
2. Fill in username, email, password
3. Verify your email
4. Log in

### 2.2 Create an Organization

1. Click **"Start from scratch"**
2. Organization name: `YOUR_NAME-steghub` (e.g. `nelson-steghub`)
3. Enter your email
4. Click **"Create organization"**

> ⚠️ Note your org name — you'll use it in `backend.tf` and module source paths.

---

## PHASE 3 — GitHub Repository Setup

### 3.1 Create the `terraform-cloud` Repository

Go to GitHub → New Repository:
- Name: `terraform-cloud`
- Visibility: Public
- Do NOT initialize with README (you'll push existing code)

### 3.2 Push This Project to GitHub

```bash
cd terraform-cloud-401

# Initialize git
git init
git add .
git commit -m "feat: initial terraform cloud migration - steghub 401"

# Add remote and push
git remote add origin git@github.com:Ngumonelson123/terraform-cloud.git
git branch -M main
git push -u origin main
```

### 3.3 Create the 3 Environment Branches (Practice Task No.1)

```bash
git checkout -b dev
git push origin dev

git checkout -b test
git push origin test

git checkout -b prod
git push origin prod

# Return to main
git checkout main
```

Verify on GitHub — you should see 4 branches: `main`, `dev`, `test`, `prod`

---

## PHASE 4 — Update backend.tf

Open `backend.tf` and replace `YOUR_ORG_NAME` with your actual org name:

```hcl
terraform {
  cloud {
    organization = "nelson-steghub"   # ← your actual org name

    workspaces {
      name = "terraform-cloud-dev"    # ← workspace name
    }
  }
  ...
}
```

Commit and push:
```bash
git add backend.tf
git commit -m "config: set terraform cloud org and workspace"
git push origin main
git push origin dev
```

---

## PHASE 5 — Configure Terraform Cloud Workspace

### 5.1 Create a Workspace (Version Control Workflow)

1. In Terraform Cloud → click **"New workspace"**
2. Choose **"Version control workflow"**
3. Click **"GitHub"** → authorize OAuth if prompted
4. Select your `terraform-cloud` repository
5. On "Configure settings":
   - **Workspace name**: `terraform-cloud-dev`
   - **VCS branch**: `dev`
   - Leave all other settings as default
6. Click **"Create workspace"**

### 5.2 Set Environment Variables

In your workspace → **Variables** tab → **Add variable**:

| Variable Name          | Value           | Category    | Sensitive |
|------------------------|-----------------|-------------|-----------|
| `AWS_ACCESS_KEY_ID`    | your_access_key | Environment | No        |
| `AWS_SECRET_ACCESS_KEY`| your_secret_key | Environment | ✅ Yes    |
| `AWS_DEFAULT_REGION`   | us-east-1       | Environment | No        |

Also add these as **Terraform variables**:

| Variable Name | Value               | Category  |
|---------------|---------------------|-----------|
| `prefix`      | nelson-steghub      | Terraform |
| `name`        | webapp              | Terraform |
| `environment` | dev                 | Terraform |

---

## PHASE 6 — Run Plan & Apply (Manual)

### 6.1 Trigger from Web Console

1. Go to your workspace → **Runs** tab
2. Click **"+ New run"** or **"Queue plan manually"**
3. Add description: `"Initial Terraform Cloud migration"`
4. Click **"Queue plan"**

Wait for plan to complete (green checkmark ✓).

### 6.2 Apply

1. Review the plan output — check what will be created
2. Click **"Confirm and apply"**
3. Add comment: `"Applying initial infrastructure - steghub 401"`
4. Click **"Confirm plan"**

Watch the logs. When complete you will see:
- S3 bucket created
- Website endpoint in outputs

> 📝 Copy the **website URL** from the outputs — paste it in your `submissionfile.txt`

### 6.3 Verify State

Workspace → **States** tab → click the latest state version to inspect resources.

---

## PHASE 7 — Test Automated Plan (VCS-Triggered)

### 7.1 Push a Small Change to `dev`

```bash
git checkout dev

# Make a small change - e.g. update the name variable default
# Open variables.tf and change the name default value slightly
# Or simply add a comment to main.tf

echo "# trigger automated plan - $(date)" >> main.tf

git add .
git commit -m "test: trigger automated terraform plan from vcs push"
git push origin dev
```

### 7.2 Watch the Auto-Triggered Plan

1. Go to Terraform Cloud → your workspace → **Runs** tab
2. A new plan should appear automatically within ~30 seconds
3. Note: `plan` triggers automatically, but `apply` still requires manual confirmation

> This is by design — always verify plan before applying to avoid surprise AWS charges.

---

## PHASE 8 — Notifications (Practice Task No.1, Steps 3-4)

### 8.1 Email Notifications

1. Workspace → **Settings** → **Notifications**
2. Click **"Create a notification"**
3. Destination: **Email**
4. Email address: your email
5. Select triggers:
   - ✅ Run needs attention
   - ✅ Plan errored
   - ✅ Apply errored
6. Click **"Create notification"**

### 8.2 Slack Notifications

**Get a Slack webhook URL:**
1. Go to https://api.slack.com/apps
2. Create new app → From scratch
3. App name: `Terraform Cloud`, workspace: your workspace
4. Go to **Incoming Webhooks** → toggle On
5. Click **"Add New Webhook to Workspace"**
6. Choose a channel (e.g. `#terraform-alerts`)
7. Copy the webhook URL

**Add to Terraform Cloud:**
1. Workspace → **Settings** → **Notifications** → **Create a notification**
2. Destination: **Slack**
3. Paste webhook URL
4. Select triggers:
   - ✅ Plan started
   - ✅ Plan errored
   - ✅ Apply errored
5. Click **"Create notification"** → **"Send a test"** to verify

### 8.3 Apply Destroy from Web Console

When you're done testing:
1. Workspace → **Settings** → **Destruction and Deletion**
2. Click **"Queue destroy plan"**
3. Type workspace name to confirm
4. Click **"Queue destroy plan"** → then confirm apply

---

## PHASE 9 — Private Module Registry (Practice Task No.2)

This is the main deliverable. You will publish the `terraform-aws-s3-webapp` module to your organization's Private Registry.

### Step 1 — Create a Separate GitHub Repo for the Module

> ⚠️ The repo name MUST follow this exact format: `terraform-<PROVIDER>-<MODULE_NAME>`

```
terraform-aws-s3-webapp
```

Go to GitHub → New Repository:
- Name: **`terraform-aws-s3-webapp`**
- Visibility: Public
- Do NOT initialize

### Step 2 — Push the Module Code

```bash
# Copy the module folder from this project
cp -r terraform-aws-s3-webapp /path/to/terraform-aws-s3-webapp
cd /path/to/terraform-aws-s3-webapp

git init
git add .
git commit -m "feat: initial s3 webapp module release"

git remote add origin git@github.com:Ngumonelson123/terraform-aws-s3-webapp.git
git branch -M main
git push -u origin main
```

### Step 3 — Tag a Release (Required by Terraform Registry)

```bash
git tag v1.0.0
git push origin v1.0.0
```

Verify on GitHub: Repository → Tags → you should see `v1.0.0`

### Step 4 — Import Module to Private Registry

1. Terraform Cloud → **Registry** (left sidebar)
2. Click **"Publish"** → **"Module"**
3. Click **"GitHub"**
4. Find and select `terraform-aws-s3-webapp`
5. Click **"Publish module"**

After publishing, your module will be available at:
```
app.terraform.io/YOUR_ORG_NAME/s3-webapp/aws
```

### Step 5 — Create a New Workspace for the Module

1. Terraform Cloud → **New workspace**
2. Choose **"Version control workflow"**
3. Select your `terraform-aws-s3-webapp` repo
4. Workspace name: `s3-webapp-workspace`
5. VCS branch: `main`
6. Click **"Create workspace"**

Set variables in this workspace:

| Variable              | Value          | Category    | Sensitive |
|-----------------------|----------------|-------------|-----------|
| `AWS_ACCESS_KEY_ID`   | your_key       | Environment | No        |
| `AWS_SECRET_ACCESS_KEY` | your_secret  | Environment | ✅ Yes   |
| `AWS_DEFAULT_REGION`  | us-east-1      | Environment | No        |
| `prefix`              | nelson-steghub | Terraform   | No        |
| `name`                | webapp         | Terraform   | No        |
| `region`              | us-east-1      | Terraform   | No        |

### Step 6 — Update main.tf to Use Private Registry Source

Once published, update `main.tf` to use the registry source instead of the local path:

```hcl
module "s3_webapp" {
  source  = "app.terraform.io/nelson-steghub/s3-webapp/aws"
  version = "1.0.0"

  region = var.aws_region
  prefix = var.prefix
  name   = var.name
}
```

Commit and push to trigger a plan:

```bash
git add main.tf
git commit -m "feat: use private registry module source for s3-webapp"
git push origin dev
```

### Step 7 — Deploy the Infrastructure

1. Go to `s3-webapp-workspace` → **Runs**
2. Queue a plan manually
3. Review: confirms S3 bucket + website will be created
4. Confirm and apply
5. Copy the `endpoint` output URL — this is your live Terramino game!

Open in browser: `http://BUCKET_NAME.s3-website-us-east-1.amazonaws.com`

### Step 8 — Destroy

1. `s3-webapp-workspace` → **Settings** → **Destruction and Deletion**
2. Queue destroy plan → confirm → apply

---

## PHASE 10 — Branch Auto-Run Strategy Summary

| Workspace              | Branch | Auto-Plan | Auto-Apply |
|------------------------|--------|-----------|------------|
| terraform-cloud-dev    | dev    | ✅ Yes    | ❌ Manual  |
| terraform-cloud-test   | test   | ✅ Yes    | ❌ Manual  |
| terraform-cloud-prod   | prod   | ❌ Manual | ❌ Manual  |

To configure per workspace:
- Workspace → **Settings** → **Version Control**
- Toggle "Automatic run triggering" as needed

---

## PHASE 11 — Fill in submissionfile.txt

Open `submissionfile.txt` and fill in:
- Terraform Cloud org URL
- GitHub repo URL
- Workspace run URL (from the Runs tab)
- State version number
- Trigger commit SHA (`git log --oneline -1`)
- S3 website URL from outputs

Commit and push:
```bash
git add submissionfile.txt
git commit -m "submission: terraform 401 complete"
git push origin main
```

---

## Quick Reference — Useful Commands

```bash
# Login to Terraform Cloud from CLI
terraform login

# Initialize (after setting backend.tf)
terraform init

# Validate config
terraform validate

# Format all files
terraform fmt -recursive

# Show current state
terraform show

# List all resources
terraform state list

# Tag and push a new module version
git tag v1.1.0 && git push origin v1.1.0
```

---

## Common Issues & Fixes

| Problem | Fix |
|---|---|
| `Error: Backend initialization required` | Run `terraform init` after changing `backend.tf` |
| `Error: No valid credential sources found` | Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as env vars in the workspace |
| Plan triggers but apply doesn't auto-run | This is correct — apply is always manual unless you enable auto-apply |
| Module not found in private registry | Check repo name format: must be `terraform-<PROVIDER>-<NAME>` and have a `v*` tag |
| S3 bucket already exists error | Change the `prefix` variable to something unique |
| `Error: org not found` | Double-check org name in `backend.tf` matches exactly what's in Terraform Cloud |

---

## Checklist Before Submitting

- [ ] Terraform Cloud account + org created
- [ ] `terraform-cloud` GitHub repo with `main`, `dev`, `test`, `prod` branches
- [ ] Workspace `terraform-cloud-dev` connected to `dev` branch via VCS
- [ ] AWS env vars set in workspace
- [ ] Successful manual plan + apply from web console
- [ ] Auto-triggered plan from git push to `dev`
- [ ] Email notification configured
- [ ] Slack notification configured + tested
- [ ] `terraform-aws-s3-webapp` repo created and pushed
- [ ] Module tagged `v1.0.0` and published to Private Registry
- [ ] New workspace `s3-webapp-workspace` created for the module
- [ ] Infrastructure deployed — website URL accessible
- [ ] Infrastructure destroyed
- [ ] `submissionfile.txt` filled in and pushed

---

*StegHub DevOps & Cloud Accelerator Programme | Terraform 401*
