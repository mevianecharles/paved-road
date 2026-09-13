# Satcorporation Paved Road

**A complete, working "paved road" — pre-approved infrastructure patterns,
automated hardening, and an AI assistant that helps developers do the
right thing without needing to be security experts.**

## What is a "paved road"?

A paved road is not one tool — it's a curated, opinionated set of
templates, automation, and guardrails that make the *secure* path also
the *easiest* path. Instead of every developer inventing their own way
to secure an S3 bucket or harden a server, they use the paved road:
pre-approved modules that already have security built in.

This repo contains all four pieces of a real paved road:

```
satcorporation-paved-road/
├── terraform/           # The "road surface" — secure-by-default infrastructure modules
├── ansible/              # Provisions the Terraform modules + baseline OS hardening
├── puppet/               # Alternative hardening path — same job as Ansible, different tool
├── ai-assistant/          # Reviews code and answers security questions in plain language
├── .github/workflows/     # Automatically blocks insecure code before it reaches production
└── Makefile               # The single entry point — developers just run `make <command>`
```

Satcorporation's stack mentions Puppet, Ansible, and Terraform explicitly — this repo
covers all three, so it fits regardless of which tool a given team or
legacy system already standardizes on.

## Quick start — this is all a developer needs to know

```bash
# See all available commands
make help

# Provision a secure S3 bucket + IAM role (Terraform, wrapped in Ansible)
make provision BUCKET=my-app-logs ENV=dev

# Apply baseline OS hardening to your servers
make harden

# Before committing custom code, ask the AI to review it
make review-terraform FILE=my-custom-resource.tf
make review-ansible FILE=my-playbook.yml

# Have a security question? Just ask.
make ask Q="How do I scope an IAM policy to a single S3 bucket?"

# Run the same scanners the CI/CD pipeline runs, locally, before pushing
make scan
```

## How the four pieces work together

### 1. Terraform (`terraform/`) — the paved road itself

Pre-built modules where encryption, access controls, and logging are
already correct by default. A developer calling `secure-s3-bucket`
doesn't need to know what "least privilege" means — the module already
enforces it.

### 2. Ansible (`ansible/`) — provisioning and ongoing hardening

`provision-paved-road.yml` does two things in one command:
- Runs the Terraform modules to create infrastructure
- Applies baseline OS hardening (SSH config, firewall, fail2ban) to any
  servers that need it

This means "provisioning" and "keeping secure over time" are the same
workflow, not two separate things a developer has to remember.

### 3. AI Assistant (`ai-assistant/`) — the explainer layer

Automated scanners (tfsec, checkov) are good at *finding* problems but
bad at *explaining* them. The AI assistant reads the same code and
explains, in plain language, what's wrong, why it matters, and exactly
how to fix it — turning a cryptic scanner error into a learning moment.

### 4. CI/CD (`.github/workflows/`) — the enforcement layer

Even if a developer skips the paved road and writes raw Terraform,
`tfsec`/`checkov` catch misconfigurations automatically at pull-request
time, before merge. The AI assistant and the CI pipeline aren't
competing — the assistant helps *before* you commit, the pipeline
catches anything that slips through.

## The philosophy in one sentence

> Make the secure path the path of least resistance — not by forcing
> developers to learn security, but by building it into the tools they
> already use, and having an assistant on hand when they need to go
> off the beaten path.

## Setup

```bash
# Terraform + Ansible must be installed
# For the AI assistant:
pip install anthropic --break-system-packages
export ANTHROPIC_API_KEY=your-key-here
```

## Honest limitations (worth knowing, not hiding)

- The AI assistant is a developer-facing helper, not a CI/CD gate on its
  own — it works alongside tfsec/checkov, not instead of them.
- Prompt injection guardrails would be needed before accepting arbitrary
  user-submitted code in a shared/multi-tenant setting.
- Ansible hardening tasks here are a baseline starting point, not an
  exhaustive CIS benchmark — extend as needed for your actual environment.
