# Deploying Nexoraa CleanSoft on AWS (EC2 + S3)

Replaces the Render deployment. Written for someone new to AWS.

```
 Phone app ──HTTPS──▶ EC2 server (Caddy) ──▶ 14 NestJS services (PM2) ──▶ MongoDB Atlas (unchanged)
 Download link ─────▶ S3 bucket (the APK file)
```

- **EC2** is one Linux server that runs all 14 backend services, like Render did but on one machine. Services never sleep.
- **Caddy** gives every service its own HTTPS address and renews certificates automatically.
  Addresses look like `https://order.13-233-10-20.sslip.io`. sslip.io is a free service that maps that name to your server's IP, so you don't have to buy a domain.
- **MongoDB Atlas** stays exactly as it is; your data doesn't move.
- **S3** hosts the APK so staff and tenants can download it from a link. The backend has no file uploads, so S3 isn't needed for anything else.

**Cost:** about **$20/month**. That's a t3.small at ~$15, plus the public IP (~$3.60) and a 30 GB disk (~$2.40). $100 of credits covers roughly 4–5 months. S3 costs cents.

---

## Part 1 — AWS account safety (5 min, do this first)

1. Sign in at <https://console.aws.amazon.com>. In the top-right region menu choose **Asia Pacific (Mumbai) ap-south-1** and use this region for everything below.
2. Search **Budgets** → **Create budget** → *Use a template* → **Monthly cost budget** → amount **$10** → enter your email → Create.
   AWS will email you before you spend real money.

## Part 2 — Create the server (EC2)

1. Search **EC2** → **Launch instance**.
2. **Name:** `nexoraa-server`
3. **Application and OS Images:** **Ubuntu** → *Ubuntu Server 24.04 LTS (64-bit x86)*.
4. **Instance type:** **t3.small** (2 GB RAM). If the list is filtered to "Free tier eligible", t3.small is in it.
5. **Key pair:** *Create new key pair* → name `nexoraa-key` → RSA → `.pem` → Create.
   The file downloads. Keep it safe; it's the key to your server.
6. **Network settings** → *Edit*. Keep "Create security group" and set the rules:
   - SSH, port 22, source **My IP**
   - Add rule → **HTTP**, port 80, source **Anywhere (0.0.0.0/0)**
   - Add rule → **HTTPS**, port 443, source **Anywhere (0.0.0.0/0)**

   Don't open ports 3001–3016. The services are only reachable through Caddy.
7. **Configure storage:** **30** GiB, **gp3**.
8. **Launch instance**.

### Give it a permanent IP (Elastic IP)
Without this, the IP changes every time the server restarts and the app's URLs break.

1. EC2 → left menu **Elastic IPs** → **Allocate Elastic IP address** → Allocate.
2. Select it → **Actions → Associate Elastic IP address** → Instance: `nexoraa-server` → Associate.
3. Note the IP, for example `13.233.10.20`.

## Part 3 — Let the server reach MongoDB Atlas

1. <https://cloud.mongodb.com> → your project → **Network Access** → **Add IP Address**.
2. Enter your Elastic IP (e.g. `13.233.10.20`) → Confirm.
   If `0.0.0.0/0` is already listed (Render usually needed that), this step is already done.

## Part 4 — Connect to the server

EC2 → Instances → select `nexoraa-server` → **Connect** → **EC2 Instance Connect** tab → **Connect**.
A terminal opens in your browser. Run every command below in that terminal.

## Part 5 — Get the code onto the server

The repository is private, so the server needs a read-only **deploy key**:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Copy the line it prints. On GitHub, open the repo → **Settings → Deploy keys → Add deploy key**. Title `aws-server`, paste the key, leave "Allow write access" **unticked**, then Add key.

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
git clone -b iuc git@github.com:official-nexoraatech/nexoraa-cleansoft.git
cd nexoraa-cleansoft
```

## Part 6 — Install everything (one command, ~5 min)

```bash
bash infra/aws-ec2/setup-server.sh
```

This installs Node.js 22, pnpm, PM2 and Caddy, adds 4 GB of swap memory, and creates `~/nexoraa-env/` with one settings file per service. It also generates random internal secrets automatically.

## Part 7 — Fill in the settings (copy from Render)

Render keeps your environment variables even though the services are suspended.
For **each** service, open Render → the service → **Environment**, copy its `MONGODB_URI`, and paste it into the matching file on the server:

```bash
nano ~/nexoraa-env/order-service.env
```

In nano, replace `FILL_ME` with the value, press **Ctrl+O** then Enter to save, and **Ctrl+X** to exit.

| File on server | Render service |
|---|---|
| `auth-service.env` | nexoraa-cleansoft-1 (auth) |
| `platform-admin-service.env` | nexoraa-cleansoft-j8k6 (platform admin) |
| `branch-service.env`, `customer-service.env`, `notification-service.env`, `tenant-service.env`, `order-service.env`, `report-service.env`, `expense-service.env`, `payment-service.env`, `service-service.env`, `user-service.env`, `settings-services.env`, `search-service.env` | the service with the same name |

Also copy these if Render has them:
- **auth-service:** `BREVO_API_KEY` (OTP / password-reset emails)
- **platform-admin:** `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`

**Copy each `MONGODB_URI` exactly.** Every service uses its own database name. If one is wrong, that service starts but looks empty.

You don't need to copy the internal keys (`PLATFORM_ADMIN_INTERNAL_KEY`, `AUTH_ACCESS_TOKEN_SECRET`, …). They were generated in Part 6 and are shared by every service. Everyone will need to log in again once.

To check nothing is left unfilled:
```bash
grep -l FILL_ME ~/nexoraa-env/*.env   # no output = all done
```

## Part 8 — Deploy (~15–25 min the first time)

```bash
bash infra/aws-ec2/deploy.sh
```

This builds all 14 services one at a time (slow on a small server, but it only happens on deploys), starts them with PM2, and sets up HTTPS.
At the end it prints something like this:

```
Put these lines in apps/mobile-app/.env, then rebuild the APK:
RENDER_AUTH_API_BASE_URL=https://auth.13-233-10-20.sslip.io/api
...
```

**Copy those lines.** You'll need them in Part 9.

Check that it works:
```bash
pm2 status                                                   # all 14 should say "online"
curl https://auth.<your-ip-with-dashes>.sslip.io/api/v1/health/live
```

## Part 9 — Point the mobile app at AWS

On your PC, replace the `RENDER_*_API_BASE_URL` lines in `apps/mobile-app/.env` with the lines from Part 8. The names still say RENDER, but that's just the variable name.
Keep `APP_ENV=production`. Then build:

```bash
cd apps/mobile-app
flutter build apk --release
```

## Part 10 — Share the APK with S3

1. Search **S3** → **Create bucket**. Name: `nexoraa-app-downloads-<something-unique>`, region Mumbai.
   **Untick "Block all public access"** and tick the acknowledgement. Create.
2. Open the bucket → **Permissions → Bucket policy → Edit**, paste this (use your bucket name) and save:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Sid": "PublicApkDownload",
       "Effect": "Allow",
       "Principal": "*",
       "Action": "s3:GetObject",
       "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/apk/*"
     }]
   }
   ```
   Only files inside the `apk/` folder become public.
3. **Objects → Create folder** `apk` → open it → **Upload** →
   `apps/mobile-app/build/app/outputs/flutter-apk/app-release.apk` → Upload.
4. Click the uploaded file and copy its **Object URL**. That's the download link to share.
   To publish a new version, upload over the same file name and the link stays the same.

---

## Everyday use

**Deploy new code:** push to `iuc` from your PC, then in the server terminal run:
```bash
cd ~/nexoraa-cleansoft && bash infra/aws-ec2/deploy.sh
```

**See what a service is doing (errors, crashes):**
```bash
pm2 logs order-service --lines 100
pm2 status
```

**Restart one service after editing its env file:**
```bash
pm2 restart order-service --update-env
```

**Server reboot:** PM2 and Caddy start by themselves. The Elastic IP keeps the URLs the same.

## Troubleshooting

| Symptom | Fix |
|---|---|
| A service keeps restarting in `pm2 status` | `pm2 logs <name> --lines 50`. Usually a wrong `MONGODB_URI` or Atlas Network Access missing the Elastic IP. |
| `curl https://…sslip.io` fails with a certificate error | Wait a minute (first certificate). Check ports 80 and 443 are open in the security group. `sudo journalctl -u caddy -n 50` |
| Build is killed / "JavaScript heap out of memory" | Run `free -h`. Swap should show 4 GB. Re-run `bash infra/aws-ec2/deploy.sh --no-pull`. |
| App says "Unable to reach …" | Check the APK was rebuilt after changing `.env`, and that the URLs match what deploy.sh printed. |
| Want your own domain later | Point `*.api.yourdomain.com` (A record) at the Elastic IP, create `~/nexoraa-env/deploy.conf` containing `PUBLIC_DOMAIN=api.yourdomain.com`, then re-run deploy.sh and update the app's `.env`. |

## Cleaning up Render
Once the app works against AWS, delete the Render services, so a Blueprint sync from `render.yaml` doesn't bring them back.
