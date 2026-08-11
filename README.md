# ☁️ AWS Blueprint for Beginners

> **From zero to production-ready — one copy-paste lab at a time.**

Built by [Nkechi Anna Ahanonye](https://github.com/nkydigitech) for DevOps students who need relatable examples, not textbook theory.

---

## 🚀 The Philosophy

You don't learn AWS by reading about it. You learn by **breaking things, fixing them, and watching them work**.

Every lab in this repo is:
- ✅ **Copy-paste ready** — change 2–3 variables, run the commands
- ✅ **Analogy-driven** — cybercafés, bouncers, warehouses, phonebooks
- ✅ **Free Tier friendly** — clean up after each lab, pay nothing
- ✅ **Output-verified** — every step shows what your terminal should look like

---

## 📚 The Journey

| Lab | Topic | Analogy | What You Build |
|-----|-------|---------|----------------|
| **Lab 0** | AWS CLI Setup | Getting your tools | Configure AWS CLI |
| **Lab 1** | Your First EC2 | Renting your first computer | A live web server in 5 minutes |
| **Lab 2** | Regions & AZs | Opening branches worldwide | Same app in 2 continents |
| **Lab 3** | VPC & Networking | Building a fenced estate | Custom network with public/private rooms |
| **Lab 4** | IAM & Security Groups | Bouncers & ID cards | Role-based access + firewall rules |
| **Lab 5** | S3 Storage | The warehouse | Static website + file storage |
| **Lab 6** | RDS Databases | The robot librarian | Managed MySQL you never patch |
| **Lab 7** | ALB & Auto Scaling | Smart traffic director | App that scales when crowded |
| **Lab 8** | Route 53 | The phonebook | Custom domain → your app |
| **Lab 9** | CloudWatch | CCTV & alarms | Dashboards + SMS alerts |
| **Lab 10** | Capstone | The full cybercafé chain | Production 3-tier architecture with Terraform |

---

## 🛠 Prerequisites

- An AWS account ([Free Tier](https://aws.amazon.com/free/))
- A terminal (Linux, macOS, or WSL on Windows)
- Curiosity and 30–45 minutes per lab

---

## 💰 Cost Warning

**All labs are designed for AWS Free Tier.** However:
- Always run the **cleanup commands** at the end of each lab
- Don't leave EC2 instances, ALBs, or NAT Gateways running overnight
- Set up [AWS Budget Alerts](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) ($5 threshold)

> _"The most expensive AWS resource is the one you forgot to delete."_

---

## 🎓 How to Use This Repo

1. Start with **Lab 0** (setup your CLI)
2. Work through Labs 1–9 in order (each builds on the last)
3. Finish with **Lab 10** (the capstone) — this is where you experience real production patterns
4. If you get stuck, check the **Troubleshooting** section in each lab

---

## 📂 Repo Structure

```
aws-blueprint/
├── README.md                 # You are here
├── labs/
│   ├── lab-00-setup/         # AWS CLI + credentials
│   ├── lab-01-first-ec2/     # Launch your first server
│   ├── lab-02-regions-azs/   # Multi-region deployment
│   ├── lab-03-vpc/           # Build a custom network
│   ├── lab-04-iam-security/  # IAM + Security Groups
│   ├── lab-05-s3/            # Static website on S3
│   ├── lab-06-rds/           # Managed database
│   ├── lab-07-alb-autoscaling/ # Scale automatically
│   ├── lab-08-route53/       # Custom domains
│   ├── lab-09-cloudwatch/    # Monitoring & alerts
│   └── lab-10-capstone/      # Full production deploy
├── diagrams/                 # Architecture diagrams
└── terraform-capstone/       # Terraform code for Lab 10
```

---

## 🙏 Contributing

Found a bug? Want to add a lab? PRs welcome!

---

*"Reliability isn't a feature — it's the product."*
