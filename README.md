# HCP Terraform + AWS OIDC — Infra Change Workflow

> 📐 **Full walkthrough:** every step, screen, setting and test is detailed in my Excalidraw board:
> https://link.excalidraw.com/l/9hD7S5FgGWN/7vcS89NuY35
>
> I drew every step of this board myself and tested each one from top to bottom. In a generative AI world, anyone can generate code and docs. My goal here was to actually understand how every piece works and why, not just to make it run.

Keyless AWS infrastructure delivery with **GitHub → HCP Terraform (OPA) → AWS**, tracked end to end in **Jira** with notifications in **Slack**.

No AWS access keys are stored anywhere. HCP Terraform proves who it is with a short-lived OIDC token, and AWS trusts that token to hand out temporary credentials for each run.

### AWS modules used

| Stack | Module | What it builds |
|-------|--------|----------------|
| `network/` | [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) | VPCs (`customer_profile_vpc`, `account_vpc`) and subnets |
| `security/` | [`terraform-aws-modules/security-group/aws`](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws) | Security groups for EC2, the jump host, and the account VPC |
| `compute/` | [`terraform-aws-modules/ec2-instance/aws`](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws) | EC2 instances (`customer_profile_ec2_instance`, `account_ec2_instance`) |
| `compute/` | [`terraform-aws-modules/key-pair/aws`](https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws) | SSH key pairs for the instances |

---

## High-Level Overview

<img width="1568" height="536" alt="High-level overview: GitHub → HCP Terraform (OPA) → AWS OIDC" src="https://github.com/user-attachments/assets/f04be46d-19f9-4037-9c5d-df21d6b62506" />

| # | Step |
|---|------|
| 1 | Developer commits and pushes Terraform changes to GitHub |
| 2 | GitHub webhook triggers a run in the HCP Terraform workspace |
| 3–4 | For **plan**, HCP Terraform sends `AssumeRoleWithWebIdentity` to AWS with its signed JWT |
| 5 | AWS IAM OIDC provider validates the token |
| 6–7 | `tfc-plan-role` (read-only) is assumed and Terraform reads AWS resources to build the plan |
| 8 | HCP Terraform receives the generated plan |
| — | **OPA policy check** runs on the plan (e.g. deny `0.0.0.0/0` inbound on security groups / jump host) |
| 9–11 | Only if policy **passes**: a second token is requested and `tfc-apply-role` (read/write) is assumed |
| 12 | Terraform applies the change to AWS. If policy is **denied**, the run stops and apply fails |

### Very important concept: two tokens

- **Plan token** is always generated, *before* the policy check. Terraform needs AWS read access to produce a plan, and OPA can only check a plan that already exists.
- **Apply token** is generated **only if the policy passes**. If OPA fails, the run stops in HCP Terraform and the apply token is never created.

---

## Infra Change Workflow (Request → Done)

<img width="1480" height="812" alt="Infra change workflow: Jira → GitHub → HCP Terraform (OPA) → Slack" src="https://github.com/user-attachments/assets/da2ecc75-b915-4b88-88bd-aeef07bae157" />

| Step | Tool | What happens | Jira status |
|------|------|--------------|-------------|
| 1. Request | Jira | Create a change request ticket (e.g. `KAN-5`) | To Do |
| 2. Develop & PR | GitHub | Create branch `feature/KAN-5-...` and open a PR whose title contains the key | Awaiting PR → Plan In Progress |
| 3. Plan + OPA | HCP Terraform | Speculative plan runs and OPA policies are checked | Awaiting Approval (pass) / Plan Failed (deny) |
| 4. Review & Merge | GitHub | Review the plan, approve, merge PR to `main` | — |
| 5. Apply | HCP Terraform | Plan + apply on `main` (auto-apply **off**, manual confirm) | Deploying |
| 6. Complete | Jira + Slack | Apply succeeded → ticket moves to Done | Done / Deployment Failed |

Every status change posts to the Slack channel `#devops-change-requests`.

**How the ticket is linked:** the Jira key (e.g. `KAN-5`) must appear in the branch name and PR title. GitHub links it to Jira automatically, and Jira automation finds the ticket from the HCP run message with a JQL like `key = {{webhookData.run_message.match("([A-Z]+-\d+)")}}`.

### Example: full successful flow

1. Jira: create `KAN-5` (To Do)
2. Branch `feature/KAN-5-remove-ssh-test` — remove `ssh_from_internet` from `security/terraform.tfvars`
3. PR `KAN-5: remove OPA test SSH rule` → **Plan In Progress** + Slack "PR received"
4. HCP plan → Needs Confirmation → **Awaiting Approval** + Slack "approval required"
5. Merge PR to `main`
6. HCP: Confirm & Apply → **Deploying** → **Done** + Slack "deployment successful"

---

## Repository Layout

```
.
├── runner/     # empty starter workspace — only job is to kick off the chain
├── network/    # VPC, subnets  → outputs vpc_id, subnet ids
├── security/   # security groups (needs vpc_id from network)
└── compute/    # EC2 (needs subnet id from network + SG id from security)
```

### Multi-workspace chain

HCP Terraform has no "run all" button, so `workspace-runner-admin` is the single starting point:

```
runner  ──run trigger──▶  network  ──▶  security  ──▶  compute
```

Each workspace runs after the one before it applies, so the order is always right. Outputs are passed with **remote state sharing**, shared only with the workspaces that need them:

- `network` → shared with `security` and `compute`
- `security` → shared with `compute`

---

## Setup Summary

### AWS side

1. **IAM OIDC provider** (once per account)
   - Provider URL: `https://app.terraform.io`
   - Audience: `aws.workload.identity`
2. **`tfc-plan-role`** — Web identity trust, `Run Phase: plan`, read-only policy
3. **`tfc-apply-role`** — Web identity trust, `Run Phase: apply`, write policy

### HCP Terraform side

1. Organization `kst-cie` → project `gitlab-hcp-terraform-oidc-aws`
2. Workspaces: `workspace-runner-admin`, `network`, `security`, `compute` (VCS-driven, working directory = folder name)
3. **Variable set** scoped to the project (environment variables):

   | Key | Value |
   |-----|-------|
   | `TFC_AWS_PROVIDER_AUTH` | `true` |
   | `TFC_AWS_PLAN_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/tfc-plan-role` |
   | `TFC_AWS_APPLY_ROLE_ARN` | `arn:aws:iam::<ACCOUNT_ID>:role/tfc-apply-role` |

   The AWS provider block has **no access keys and no `assume_role`** — HCP Terraform supplies the credentials.
4. **OPA policy** `deny-public-ssh` attached through a policy set (denies `0.0.0.0/0` and `::/0` inbound)
5. **Notifications** per workspace → Jira automation incoming webhooks
6. Apply method set to **Manual** so plans wait for approval

### Jira / GitHub / Slack

1. Jira Kanban space with statuses: To Do, Awaiting PR, Plan In Progress, Awaiting Approval, Plan Failed, Deploying, Done, Deployment Failed
2. **GitHub for Atlassian** app connects the repo to Jira
3. **Slack app** with the `incoming-webhook` scope on `#devops-change-requests`
4. **Jira automation rules** (incoming webhook triggers): PR opened, Plan ready for approval, Plan/OPA failed, Apply successful
5. **GitHub repo webhook** → Jira automation for PR events

---

## Integrations Inventory

| Type | Integration | Purpose |
|------|-------------|---------|
| **OIDC** | HCP Terraform → AWS IAM | Keyless AWS credentials for plan and apply |
| **OAuth** | GitHub ↔ HCP Terraform (OAuth App) | VCS connection, triggers runs |
| **OAuth** | GitHub ↔ Jira (GitHub for Atlassian) | Links branches / PRs to tickets |
| **OAuth** | Slack app (`incoming-webhook`) | Jira posts status updates to Slack |
| Token | Team API token (`TFE_TOKEN`) | Used by `workspace-runner-admin` |
| Webhook | GitHub → Jira automation | PR events update tickets |
| Webhook | HCP Terraform notifications → Jira | Run results update tickets |

**Total: 1 OIDC + 3 OAuth**, plus 1 API token and 2 webhook-secret integrations.

---

## Implementation Patterns Spotted (Least Privilege)

What works today, and where permissions are wider than they need to be.

| Area | Current | Risk | Recommended |
|------|---------|------|-------------|
| `tfc-apply-role` policy | AdministratorAccess | Any run can change anything in the account | Limit to services Terraform manages (EC2, VPC, SG) + permissions boundary |
| OIDC trust (both roles) | `Workspace Name: *` | Any workspace in the project can assume the role | Pin `sub` to `network`, `security`, `compute` — or one role per workspace |
| `tfc-plan-role` policy | ReadOnlyAccess | Can read S3 objects, SSM parameters, etc. | Custom read policy for only what the plan needs |
| GitHub OAuth App ↔ HCP | `repo` scope: read/write **all** public & private repos, admin on webhooks | Token compromise exposes every repo | Use HCP Terraform's **GitHub App** installed on this repo only |
| `TFE_TOKEN` (runner) | Owners team / "Manage workspaces" | Admin-level token in a workspace variable | Dedicated team scoped to this one project (queue runs, read outputs) |
| GitHub for Atlassian | All repos | Jira can read more than it needs | "Only select repositories" |
| Jira `org-admins` group | — | Too many admins | Keep membership minimal |
| Variable set | Scoped to whole project | Every workspace in project gets role ARNs | Scope per workspace |
| Webhook secrets | Secret is part of the URL | Anyone with the URL can post fake events | Treat URLs as secrets, store in a secret manager, rotate if exposed |

✅ **Already good**

- No static AWS keys — OIDC dynamic credentials only
- Separate plan (read) and apply (write) roles, split by `Run Phase`
- Apply token only issued after OPA passes
- Slack app has a single scope on a single channel
- Remote state shared only with the workspaces that need it
- Auto-apply off, so humans approve before changes land

### Next steps

- [ ] Replace AdministratorAccess on `tfc-apply-role` with a scoped policy
- [ ] Pin OIDC trust `sub` to specific workspaces
- [ ] Move GitHub ↔ HCP connection from OAuth App to GitHub App (single repo)
- [ ] Downscope `TFE_TOKEN` to a project-level team
- [ ] Rotate Jira webhook secrets that appear in screenshots / diagrams

---

## Security Notes

- Never commit AWS keys, `TFE_TOKEN`, Jira webhook URLs, or Slack webhook URLs.
- Webhook URLs contain secrets — keep them out of diagrams, screenshots, and issues.
