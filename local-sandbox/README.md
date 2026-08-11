# 🏗 Local AWS Sandbox

> **Practice every lab on your laptop before touching real AWS.**

This sandbox uses [LocalStack](https://localstack.cloud/) to simulate AWS services locally via Docker. You get the full AWS CLI experience — **zero cost, zero risk, instant feedback.**

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose installed
- AWS CLI v2 installed (from Lab 0)
- `awslocal` CLI (install below)

### Step 1: Install `awslocal`

```bash
pip install awscli-local
```

> `awslocal` is a thin wrapper around `aws` that automatically points to `http://localhost:4566`.

### Step 2: Start the Sandbox

```bash
cd local-sandbox
docker-compose up -d
```

**Expected Output:**
```
[+] Running 2/2
 ⠿ Container aws-blueprint-sandbox  Started
 ⠿ Container aws-blueprint-web      Started
```

Wait 30 seconds for initialization, then verify:

```bash
awslocal s3 ls
```

**Expected Output:**
```
2024-08-11 10:00:00 localstack-sandbox-bucket
```

✅ **You're now running AWS on your laptop!**

---

## 🧪 How to Use with Labs

Every lab has a **"Local Sandbox Version"** section. The commands are identical to real AWS, just replace `aws` with `awslocal`.

### Example: Lab 1 (First EC2) in Sandbox

```bash
# Instead of:
aws ec2 create-key-pair --key-name my-key ...

# Use:
awslocal ec2 create-key-pair --key-name my-key ...
```

### The One Difference: No Real Costs

| Real AWS | Local Sandbox |
|----------|---------------|
| `aws` CLI | `awslocal` CLI |
| Costs money | **$0.00** |
| Takes minutes to provision | **Instant** |
| Needs internet | **Works offline** |
| Real public IPs | Simulated (use `localhost:4566`) |

---

## 📂 Sandbox Structure

```
local-sandbox/
├── docker-compose.yml          # Starts LocalStack + Web UI
├── init-scripts/               # Auto-runs when container starts
│   └── 01-init-resources.sh    # Pre-creates VPC, subnets, S3 bucket
├── scripts/
│   ├── setup-local-aws.sh      # Configure AWS CLI for local
│   ├── reset-sandbox.sh        # Wipe everything and restart
│   └── health-check.sh         # Verify all services are healthy
└── README.md                   # This file
```

---

## 🛠 Helper Scripts

### Configure AWS CLI for Local (One-Time)

```bash
./scripts/setup-local-aws.sh
```

This creates a `local` profile in `~/.aws/config` so you can also use:
```bash
aws --profile local s3 ls
```

### Reset the Sandbox

```bash
./scripts/reset-sandbox.sh
```

Wipes all data and restarts fresh. Useful between labs.

### Health Check

```bash
./scripts/health-check.sh
```

Checks which AWS services are responding.

---

## 🌐 Web UI (Optional)

Open http://localhost:8080 to see a visual dashboard of your local AWS resources.

---

## ⚠️ LocalStack Limitations

Not all AWS features work in LocalStack Community Edition:

| Service | LocalStack Support | Notes |
|---------|-------------------|-------|
| S3 | ✅ Full | Works perfectly |
| EC2 | ⚠️ Partial | Instances launch but don't "run" real OS |
| IAM | ✅ Full | Users, roles, policies all work |
| VPC | ⚠️ Partial | Basic networking works |
| RDS | ⚠️ Partial | Creates endpoints but no real DB engine |
| ALB | ⚠️ Partial | Creates but limited routing |
| Auto Scaling | ⚠️ Partial | Groups created but no real scaling |
| Route 53 | ✅ Full | DNS records work locally |
| CloudWatch | ⚠️ Partial | Metrics and logs work |
| Lambda | ✅ Full | Great for serverless labs |

> **The Strategy:** Practice commands and concepts locally. Do the **real deployment** for the capstone (Lab 10) on actual AWS.

---

## 🎯 Recommended Workflow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Learn Concept  │────▶│  Practice Local │────▶│  Deploy Real    │
│  (Read + Watch) │     │  (Sandbox)      │     │  (AWS Console)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
       Day 1                  Day 2-3                Day 4
```

1. **Read the lab** and understand the analogy
2. **Run it in the sandbox** — make mistakes, break things, fix them
3. **Run it on real AWS** — now you know exactly what to expect

---

## 🧹 Stopping the Sandbox

```bash
docker-compose down
```

To wipe all data:
```bash
docker-compose down -v
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Connection refused` | LocalStack isn't running. Run `docker-compose up -d` |
| `awslocal: command not found` | Run `pip install awscli-local` |
| Services not responding | Wait 30s after startup. Run `./scripts/health-check.sh` |
| Port 4566 already in use | Kill the process: `lsof -ti:4566 | xargs kill -9` |
| Docker out of memory | Increase Docker memory to 4GB in Docker Desktop settings |

---

## 📚 Resources

- [LocalStack Docs](https://docs.localstack.cloud/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [awslocal GitHub](https://github.com/localstack/awscli-local)

---

*"Practice locally. Deploy confidently."*
