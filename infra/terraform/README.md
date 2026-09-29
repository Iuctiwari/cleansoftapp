# AWS infrastructure with Terraform + auto-deploy with GitHub Actions

This replaces the manual console clicks in [../aws-ec2/README.md](../aws-ec2/README.md) (Parts 1–3 and the S3 bucket).
Everything that runs **on** the server (setup-server.sh, env files, deploy.sh) stays the same.

**What Terraform creates** (region Mumbai `ap-south-1` by default):

| Resource | Purpose |
|---|---|
| EC2 `nexoraa-server` (t3.small, Ubuntu 24.04, 30 GB encrypted disk) | Runs the 14 backend services |
| Security group | 80/443 open to everyone; SSH only from the browser terminal (plus your IP, if set) |
| Elastic IP | Fixed public IP, so HTTPS URLs never change |
| IAM role for the server | Lets AWS Systems Manager run the deploy that GitHub requests |
| S3 bucket `nexoraa-app-downloads-<account-id>` | Public APK downloads (only the `apk/` folder is public) |
| Budget `nexoraa-monthly` | Emails you at 80% of $10, and when the month is forecast to exceed $10 |
| GitHub OIDC provider + role `nexoraa-github-deploy` | Lets GitHub Actions deploy **without storing any AWS keys**. Only the `iuc` branch of this repo can use it, and only to run commands on this one server. |

**How a deploy works after setup:** you `git push` to `iuc` → GitHub Actions signs in to AWS with a short-lived token → asks Systems Manager to run `infra/aws-ec2/remote-deploy.sh` on the server → waits for it to finish (15–25 min) → checks the HTTPS endpoints respond.

---

## Part A — One-time tools on your Windows PC

Open **PowerShell** and run:

```powershell
winget install --id Hashicorp.Terraform -e
winget install --id Amazon.AWSCLI -e
```

Close and reopen PowerShell, then check both work:

```powershell
terraform version
aws --version
```

## Part B — An AWS login for Terraform

Terraform needs access keys. Don't create keys for the root account (the email you signed up with).

1. AWS console → search **IAM** → **Users** → **Create user**.
2. User name: `terraform-admin` → Next.
3. **Attach policies directly** → tick **AdministratorAccess** → Next → **Create user**.
4. Open the user → **Security credentials** tab → **Create access key**.
5. Choose **Command Line Interface (CLI)** → tick the confirmation → Next → **Create access key**.
6. Keep the page open, then in PowerShell run:

```powershell
aws configure
```

| Prompt | Enter |
|---|---|
| AWS Access Key ID | the Access key from the page |
| AWS Secret Access Key | the Secret access key from the page |
| Default region name | `ap-south-1` |
| Default output format | `json` |

Test it. It should print your account number (636477547631):

```powershell
aws sts get-caller-identity
```

These keys can do anything in your account. Never commit them, paste them into chat, or share them. If they leak, delete them in IAM right away.

## Part C — Remove anything you created by hand

Terraform creates its own server, IP and bucket. Delete the manual ones first, or you'll pay for both.
Check **both** Mumbai and Stockholm (region menu, top-right):

- **EC2 → Elastic IPs:** select → Actions → **Disassociate**, then Actions → **Release**
- **EC2 → Instances:** select → Instance state → **Terminate**
- **S3:** empty and delete any bucket you made for the APK
- **Budgets:** delete a manual $10 budget, if you made one (optional; it just avoids duplicate emails)

## Part D — Create the infrastructure

```powershell
cd C:\Users\AYUSHI\Desktop\cleansoft\nexoraa-cleansoft\infra\terraform
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

In Notepad, set `budget_email = "your@email.com"`, then save and close. Then:

```powershell
terraform init
terraform plan
```

`plan` only **shows** what will be created and changes nothing. It should end with `Plan: 17 to add, 0 to change, 0 to destroy`; the exact number may differ slightly.

```powershell
terraform apply
```

Type `yes` when asked. It takes about 2 minutes. At the end, the outputs look like this:

```
apk_download_url = "https://nexoraa-app-downloads-636477547631.s3.ap-south-1.amazonaws.com/apk/app-release.apk"
public_domain    = "13-233-10-20.sslip.io"
public_ip        = "13.233.10.20"
github_actions_variables = { AWS_DEPLOY_ROLE_ARN = "...", AWS_INSTANCE_ID = "i-...", ... }
```

You can print them again any time with `terraform output`.

**Error `EntityAlreadyExists` for the OIDC provider:** your account already has one. Add `create_github_oidc_provider = false` to `terraform.tfvars` and run `terraform apply` again.

**Confirm the budget email:** AWS may send a confirmation email; click the link in it.

**Back up the state file:** Terraform records what it created in `infra/terraform/terraform.tfstate` on your PC. It's git-ignored on purpose. **Copy it somewhere safe** (Google Drive etc.) after every `apply`. Without it, Terraform can't update or delete what it created.

## Part E — MongoDB Atlas

cloud.mongodb.com → **Network Access**. If `0.0.0.0/0` isn't listed, add the `public_ip` from the outputs.

## Part F — First-time server setup (once)

This part is the same as the manual guide.

1. AWS console (Mumbai) → **EC2 → Instances** → `nexoraa-server` → **Connect** → **EC2 Instance Connect** → user `ubuntu` → **Connect**.
2. Follow [../aws-ec2/README.md](../aws-ec2/README.md) **Part 5 to Part 8**:
   - Part 5: deploy key + `git clone -b iuc ...`
   - Part 6: `bash infra/aws-ec2/setup-server.sh`
   - Part 7: fill in `~/nexoraa-env/*.env` from Render
   - Part 8: `bash infra/aws-ec2/deploy.sh`, which does the first deploy by hand so you can watch it
3. `pm2 status` should show 14 services **online**.

## Part G — Connect GitHub Actions

GitHub → the repo → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**.
Add each of these, with values from `terraform output github_actions_variables`:

| Name | Example value |
|---|---|
| `AWS_REGION` | `ap-south-1` |
| `AWS_DEPLOY_ROLE_ARN` | `arn:aws:iam::636477547631:role/nexoraa-github-deploy` |
| `AWS_INSTANCE_ID` | `i-0abc123...` |
| `PUBLIC_DOMAIN` | `13-233-10-20.sslip.io` |

These go under **Variables**, not Secrets. None of them is secret; access is controlled by the AWS role.

**Test it:** GitHub → **Actions** tab → **Deploy backend to AWS** → **Run workflow** → branch `iuc` → **Run workflow**.
Open the run to watch it. It polls every 20 s and takes 15–25 min, then prints the server's last 200 log lines. A green tick means it deployed and the HTTPS checks passed.

From now on, every push to `iuc` that changes `apps/backend/**`, `packages/**`, the lockfile or `infra/aws-ec2/**` deploys automatically.
Pushes that only change the mobile app or docs don't trigger a deploy.

## Part H — Mobile app + APK

1. Put the URLs printed at the end of `deploy.sh` into `apps/mobile-app/.env`. Keep `APP_ENV=production`.
2. `cd apps/mobile-app` → `flutter build apk --release`
3. Upload the APK to the bucket's `apk/` folder:
   ```powershell
   aws s3 cp build\app\outputs\flutter-apk\app-release.apk s3://<downloads_bucket>/apk/app-release.apk
   ```
4. Share `apk_download_url`. Uploading a new version to the same path keeps the link the same.

APKs are built on your PC, not in GitHub Actions, on purpose: the current app is signed with your PC's debug key.
An APK built elsewhere would have a different signature, and phones would refuse to install it as an update.

---

## Everyday commands

| What | Command |
|---|---|
| Deploy new backend code | `git push origin iuc` (automatic) |
| Re-run a deploy without new code | GitHub → Actions → Deploy backend to AWS → Run workflow |
| See service errors | Browser terminal → `pm2 logs order-service --lines 100` |
| See past deploy logs | Browser terminal → `ls ~/deploy-logs` then `less ~/deploy-logs/<file>` |
| Change infrastructure (e.g. bigger server) | Edit `terraform.tfvars` (e.g. `instance_type = "t3.medium"`) → `terraform plan` → `terraform apply` |
| Show outputs again | `terraform output` |

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Action fails at "Sign in to AWS": *Not authorized to perform sts:AssumeRoleWithWebIdentity* | The run isn't on branch `iuc`, or `AWS_DEPLOY_ROLE_ARN` is wrong. Only `iuc` may deploy. |
| Action fails with *InvalidInstanceId* | The SSM agent isn't registered yet (wait ~5 min after a new server), or `AWS_INSTANCE_ID` is wrong. Check **Systems Manager → Fleet Manager**: the server should be listed as *Online*. |
| Deploy status `Failed` | Read "Server output" in the run log; the full log is in `~/deploy-logs/` on the server. |
| Smoke test fails but deploy succeeded | Services may still be starting. Re-run the workflow, or check `pm2 status`. |
| `terraform apply` wants to **replace** the server | Stop and read the plan. Replacing the server wipes its setup (env files, deploy key). Ask before typing `yes`. |

## Deleting everything

`terraform destroy` deletes the server, IP, bucket, budget and roles.
Empty the S3 bucket first (`aws s3 rm s3://<bucket> --recursive`), or the destroy stops at the bucket.
