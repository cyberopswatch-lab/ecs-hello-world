# CloudScale Global — Retail Catalog CI/CD (IaC version)

This replaces the manual, click-through-the-console version of the lab with a
repeatable Terraform deployment. Same end result: a GitHub commit triggers
CodePipeline -> CodeBuild (builds & pushes a Docker image to ECR) -> ECS
(EC2 launch type) rolls out the new container.

## Layout

```
app/                  <- push this to your GitHub repo (e.g. "ecs-hello-world")
  index.html
  Dockerfile
  buildspec.yml

infra/                <- Terraform package; provisions all AWS resources
  versions.tf
  variables.tf
  vpc.tf
  ecr.tf
  iam.tf
  s3.tf
  ecs-cluster.tf
  ecs-asg.tf
  ecs-task-service.tf
  codebuild.tf
  codestar-connection.tf
  codepipeline.tf
  outputs.tf
  terraform.tfvars.example

bootstrap/             <- run ONCE locally: sets up GitHub OIDC + state bucket
                           for the GitHub Actions deployment path (see
                           GITHUB_ACTIONS_SETUP.md)

.github/workflows/      <- GitHub Actions workflow that plans/applies infra/
  deploy-infra.yml         on every push (after the one-time bootstrap)
```

> **Want infra/ to deploy itself on every `git push`, no manual `terraform apply`?**
> See [`GITHUB_ACTIONS_SETUP.md`](./GITHUB_ACTIONS_SETUP.md) for the OIDC-based
> GitHub Actions setup — no AWS keys stored in GitHub, just an IAM role it
> assumes per run.

## What gets created

- **ECR** repository for the Docker images
- **ECS cluster** on EC2 (Auto Scaling group, 1x instance, ECS-optimized AMI,
  EC2 capacity provider) — mirrors the lab's free-tier `t2.micro`/`t3.micro` host
- **ECS task definition + service** running the `web-container` on port 80
- **CodeBuild** project, privileged mode enabled (required for `docker build`)
- **CodePipeline** with three stages: Source (GitHub via CodeStar Connections
  V2) -> Build (CodeBuild) -> Deploy (ECS)
- **IAM roles** scoped to what each service actually needs
- **S3 bucket** for pipeline artifacts

## One-time setup

### 1. Create the GitHub repo and push the app code

```bash
# from this package's root
cd app
git init
git add .
git commit -m "Initial commit: index.html, Dockerfile, buildspec.yml"
git branch -M main
git remote add origin https://github.com/<your-username>/ecs-hello-world.git
git push -u origin main
```

(You can also just create the repo on GitHub.com and upload these 3 files
through the web UI — either way, the pipeline only cares that they exist on
the branch you configure.)

### 2. Deploy the infrastructure

`infra/` is configured for a remote S3 backend (needed for the GitHub
Actions path below), so it needs backend values at `init` time — there's
no plain `terraform init && terraform apply` anymore. Pick one:

**Option A — GitHub Actions (recommended):** follow
[`GITHUB_ACTIONS_SETUP.md`](./GITHUB_ACTIONS_SETUP.md) end to end. It walks
through the one-time `bootstrap/` step (creates the state bucket + an IAM
role GitHub can assume via OIDC) and wires up `.github/workflows/deploy-infra.yml`
so every push plans/applies automatically.

**Option B — apply locally:** run the same `bootstrap/` step from
`GITHUB_ACTIONS_SETUP.md` first (it's what creates the state bucket even if
you don't use GitHub Actions), then:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set github_owner, adjust github_repo/branch/region/instance_type if needed

terraform init \
  -backend-config="bucket=<tf_state_bucket output from bootstrap>" \
  -backend-config="key=infra/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="use_lockfile=true"

terraform apply
```

### 3. Authorize the GitHub connection (the one step that can't be automated)

AWS requires a human to complete the OAuth handshake for CodeStar
Connections — Terraform can create the connection but it comes up
`PENDING`. After `terraform apply`:

1. Go to **AWS Console -> Developer Tools -> Settings -> Connections**
2. Click the connection named `<project_name>-github`
3. Click **Update pending connection**
4. Authorize AWS to access your GitHub account and select the `ecs-hello-world` repo
5. Status should flip to **Available**

### 4. Trigger the first pipeline run

The pipeline runs automatically once the connection is available, but if it
errored out while the connection was still pending, just go to
**CodePipeline -> `<project_name>-pipeline`** and click **Release change**.

Watch all three stages turn green (Source -> Build -> Deploy).

### 5. Find the live site

```bash
terraform output autoscaling_group_name
```

Look up that Auto Scaling group in the **EC2 console -> Instances**, copy
its **Public IPv4 address**, and browse to `http://<that-ip>/`.

## Testing the CI/CD loop

Edit `index.html` (either locally and `git push`, or directly in the GitHub
web UI) and commit to `main`. CodePipeline picks it up within about a
minute, rebuilds the image, and rolls it out — refresh the EC2 IP in your
browser to see the change.

## Cleanup

```bash
cd infra
terraform destroy
```

`force_delete`/`force_destroy` are set on the ECR repo and the S3 artifact
bucket so destroy works cleanly even if images/artifacts are still present.

## Notes / exam-relevant details carried over from the original lab

- **Privileged mode** on the CodeBuild project is required — without it,
  `docker build` fails with a permissions error.
- **imagedefinitions.json** must be named exactly that, and contain the
  container name + new image URI — this is the bridge artifact between
  CodeBuild and the ECS deploy action.
- This package uses an **in-place ECS rolling update**, matching the lab. If
  you need blue/green with traffic shifting and rollback, swap the ECS
  deploy action for **CodeDeploy Blue/Green** fronted by an ALB — that's a
  bigger change (separate target groups, listener, CodeDeploy application/
  deployment group) and isn't included here.
