# Deploying `infra/` via GitHub Actions (OIDC, no stored AWS keys)

This wires up GitHub Actions so a push to `main` plans and applies the
Terraform in `infra/`. Authentication uses OpenID Connect — GitHub mints a
short-lived token, AWS trades it for temporary credentials via an IAM role.
No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` ever touch GitHub.

## How it fits together

```
bootstrap/   <- run ONCE, locally, with your own AWS credentials
                 creates: GitHub OIDC trust + IAM role + Terraform state bucket
infra/       <- what GitHub Actions deploys on every push
.github/workflows/deploy-infra.yml  <- the workflow that does it
```

The `bootstrap/` step has the same chicken-and-egg problem as anything
self-managing: *something* has to create the IAM role before GitHub can
assume it. That something is you, running Terraform locally, exactly once.
After that, GitHub Actions takes over for every future change to `infra/`.

## One-time setup

### 1. Push this repo to GitHub first

GitHub Actions needs the repo to exist (and the workflow file to be on the
default branch) before it can run. Push `app/`, `infra/`, `bootstrap/`,
and `.github/` as-is.

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

### 2. Run the bootstrap stack locally

```bash
cd bootstrap
terraform init
terraform apply \
  -var="github_owner=<your-github-username>" \
  -var="github_repo=<your-repo-name>" \
  -var="github_branch=main"
```

Note the two outputs:

```
github_actions_role_arn = "arn:aws:iam::<account-id>:role/retail-catalog-github-actions-role"
tf_state_bucket          = "retail-catalog-tfstate-<account-id>"
```

### 3. Add GitHub repository variables

In your repo: **Settings → Secrets and variables → Actions → Variables tab**
→ add these (they're not secret — the role ARN alone is useless without a
valid GitHub OIDC token, so plain repository *variables* are fine, not
secrets):

| Name | Value |
|---|---|
| `AWS_GITHUB_ACTIONS_ROLE_ARN` | the `github_actions_role_arn` output |
| `TF_STATE_BUCKET` | the `tf_state_bucket` output |
| `GH_OWNER` | your GitHub username (used as the `github_owner` Terraform variable) |

### 4. (Recommended) Add an approval gate

**Settings → Environments → New environment → `production`** → add
yourself as a required reviewer. The workflow's `apply` job targets this
environment, so every apply pauses for a manual click before it touches
your AWS account — cheap insurance against an unreviewed plan breaking
something.

### 5. If you already ran `terraform apply` locally against `infra/` before this

Your existing state is sitting in a local `infra/terraform.tfstate` file,
which GitHub Actions can't see. Migrate it into the new S3 backend once,
locally, so CI picks up where you left off instead of trying to recreate
everything:

```bash
cd infra
terraform init \
  -backend-config="bucket=<tf_state_bucket output>" \
  -backend-config="key=infra/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true" \
  -migrate-state
```

Terraform will ask to confirm copying state to the new backend — say yes.
If this is a fresh deployment with nothing applied yet, skip this step
entirely.

### 6. Push a change

Commit anything under `infra/` (or use the **Run workflow** button under
Actions → Deploy Infrastructure for a no-op test run) and watch the
**Actions** tab: a `plan` job runs automatically, then `apply` waits for
your approval (if you set up the environment gate) before rolling out.

## Notes

- This pipeline deploys the *infrastructure*. The app-level CI/CD (Docker
  build → ECR → ECS rollout) still runs through the AWS CodePipeline /
  CodeBuild setup created by `infra/` itself — that part isn't replaced by
  this workflow. If you'd rather have GitHub Actions build and push the
  container too (replacing CodeBuild/CodePipeline entirely), that's a
  bigger, separate change — say so and I'll build that path instead.
- The IAM policy attached to the GitHub Actions role is scoped to the AWS
  *services* this stack uses (ECS, ECR, IAM, CodeBuild, CodePipeline, S3,
  EC2/ASG, logs), not to individual resource ARNs — Terraform's dynamic IAM
  role creation makes ARN-level scoping unwieldy here. Tighten it if this
  ever moves past a lab/demo account.
- `terraform destroy` for `infra/` still works the same way — run it
  through the same workflow (or locally, once you've pointed at the S3
  backend) — but remember `bootstrap/` isn't managed by that destroy, so
  clean up the OIDC role and state bucket separately if you want to tear
  down completely.
