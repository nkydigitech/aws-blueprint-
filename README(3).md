# ☁️ AWS Blueprint for Beginners

![AWS Blueprint Zero to Hero Banner](./assets/aws_blueprint_banner.webp)

> **From zero to production-ready — one copy-paste lab at a time.**

<p align="center">
  <a href="https://github.com/nkydigitech/aws-blueprint-"><img src="https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS"></a>
  <a href="https://aws.amazon.com/free"><img src="https://img.shields.io/badge/Free%20Tier-Only-10b981?style=for-the-badge&logo=amazon&logoColor=white" alt="Free Tier"></a>
  <img src="https://img.shields.io/badge/11%20Labs-Hand--On-232F3E?style=for-the-badge&logo=awslambda&logoColor=FF9900" alt="Labs">
  <img src="https://img.shields.io/badge/Copy--Paste-100%25-FF9900?style=for-the-badge" alt="Copy Paste">
  <img src="https://img.shields.io/badge/Made%20for-Beginners-0a0e1a?style=for-the-badge" alt="Beginners">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT">
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/nkydigitech/aws-blueprint-?style=social" alt="Stars">
  <img src="https://img.shields.io/github/forks/nkydigitech/aws-blueprint-?style=social" alt="Forks">
  <img src="https://img.shields.io/badge/🇳🇬%20Built%20in-Ikorodu%2C%20Lagos-008751?style=flat-square" alt="Ikorodu">
  <img src="https://img.shields.io/badge/Analogy--Driven-Cybercafés%20%26%20Bouncers-FF9900?style=flat-square" alt="Analogies">
</p>

**Built by [Nkechi Anna Ahanonye](https://www.linkedin.com/in/nkechi-ahanonye) for DevOps students who need relatable examples, not textbook theory.**

If you've heard *"AWS is the best cloud"* but you have NO idea where to start — you're in the right place. This page explains cloud like NEPA vs generator, then we build.

🔗 **Live Site:** `https://nkydigitech.github.io/aws-blueprint-/` ← Now aligned with this README ✅

---

## 🤔 Chapter 00 — The Missing Manual (What the old page skipped)

### What is "Cloud" Really?
**Before cloud:** You buy a big generator, buy diesel, service it yourself just to power your small shop. That's **owning servers**.

**Cloud:** You connect to IKEDC. You use light when you need it, pay for what you use, someone else maintains the grid.

> **Cloud = renting computers, storage, and network on the internet** instead of buying your own.

### What is AWS then?
**AWS (Amazon Web Services)** is Amazon's IKEDC for computers. The biggest warehouse in the world renting you 200+ services:

- 🖥️ **EC2** — Rent-a-computer
- 📦 **S3** — Infinite warehouse for files
- 🪪 **IAM** — Bouncers & ID cards
- 🚦 **Load Balancer** — Traffic police
- 📖 **Route 53** — Phonebook (domain → IP)

33% of the whole internet runs on AWS — Netflix, Jumia, banks, your favorite apps.

### What is AWS FOR?
- Host websites without buying servers
- Store unlimited files (like Google Drive for apps)
- Run apps that auto-scale when 10k users rush in
- Keep data safe with auto-backups & alarms
- Send SMS alerts when your app has problem

### What Will YOU Have After This Repo?
After Lab 10 Capstone, you will have a **real production setup** employers pay for:
- Website with custom domain
- Auto-scaling when crowded
- Secure network (fenced estate)
- Managed database you never patch
- Monitoring CCTV + alarms
- Deployed via **Terraform** — exactly what DevOps engineers do.

---

## 🎯 Who Needs AWS? Be Honest

| Persona | Your Situation | What This Gives You |
|---|---|---|
| **👩‍💻 Complete Newcomer** | You only heard "AWS is lucrative", don't know EC2 from 2FA | Start from Lab 0, like setting up WhatsApp. No CS degree needed |
| **🔧 IT Support / Helpdesk** | You fix printers, reset passwords, configure routers | Translates your networking knowledge to Cloud Support Engineer. **Career upgrade** |
| **🎓 Student / NYSC / Switcher** | You need portfolio employers believe, not just certs | Say "I built production 3-tier app" — with link, not theory |
| **🏪 Small Business Ikorodu-Lekki** | Shop needs website, no money for server | S3 static hosting = ₦0 to start. Lab 5 saves ₦100k hosting |
| **🚀 Failed YouTube Learner** | You got billed $40 following a tutorial | Every lab has `cleanup.sh` + expected output. No surprise bills |

**Jobs in Lagos this unlocks:** Cloud Support Associate, Junior Cloud Engineer, Junior DevOps Engineer. JD says EC2, VPC, S3, IAM, RDS — exactly Labs 1-6.

---

## 🧠 7 Core Concepts You Must Know First (Googled at 2AM)

| Concept | Nigerian Analogy | Repo Lab |
|---|---|---|
| **EC2** | Rent-a-computer in Amazon's warehouse | Lab 1 |
| **Regions & AZs** | Lagos vs London = Regions. Ikeja vs Yaba = AZs. If one burns, other works | Lab 2 |
| **VPC** | Fenced estate — you decide which rooms are public/private | Lab 3 |
| **IAM + Security Groups** | Bouncers checking ID cards at gate | Lab 4 |
| **S3** | Infinite warehouse, never full | Lab 5 |
| **RDS** | Robot librarian — patches & backs up itself | Lab 6 |
| **ALB + Auto Scaling + CloudWatch** | Smart traffic director + CCTV alarms | Labs 7, 9 |

---

## 🚀 The Philosophy

You don't learn AWS by reading about it. You learn by **breaking things, fixing them, and watching them work**.

Every lab in this repo is:

- ✅ **Copy-paste ready** — change 2–3 variables, run the commands
- ✅ **Analogy-driven** — cybercafés, bouncers, warehouses, phonebooks
- ✅ **Free Tier friendly** — clean up after each lab, pay nothing
- ✅ **Output-verified** — every step shows what your terminal should look like

---

## 📚 The Journey — 11 Labs (Now Aligned: README = Webpage)

| Lab | Topic | Analogy | What You Build | Time |
|---|---|---|---|---|
| **Lab 0** | AWS CLI Setup | Getting your tools | Configure AWS CLI | 15 min |
| **Lab 1** | Your First EC2 | Renting your first computer | A live web server in 5 minutes | 30 min |
| **Lab 2** | Regions & AZs | Opening branches worldwide | Same app in 2 continents | 30 min |
| **Lab 3** | VPC & Networking | Building a fenced estate | Custom network with public/private rooms | 45 min |
| **Lab 4** | IAM & Security Groups | Bouncers & ID cards | Role-based access + firewall rules | 40 min |
| **Lab 5** | S3 Storage | The warehouse | Static website + file storage | 35 min |
| **Lab 6** | RDS Databases | The robot librarian | Managed MySQL you never patch | 40 min |
| **Lab 7** | ALB & Auto Scaling | Smart traffic director | App that scales when crowded | 45 min |
| **Lab 8** | Route 53 | The phonebook | Custom domain → your app | 30 min |
| **Lab 9** | CloudWatch | CCTV & alarms | Dashboards + SMS alerts | 35 min |
| **Lab 10** | **Capstone** | The full cybercafé chain | Production 3-tier with **Terraform** | 60 min |

> **Old webpage had 6 labs, README had 11 — now both say 11. Fixed ✅**

---

## 🛠 Prerequisites

- An AWS account ([Free Tier](https://aws.amazon.com/free))
- A terminal (Linux, macOS, or WSL on Windows)
- Curiosity and 30–45 minutes per lab
- For Nigeria: Virtual dollar card (Grey, Geegpay, Chipper) + 5GB data total for all labs

---

## 💰 Cost Warning — Read This Before You Start

**All labs are designed for AWS Free Tier.** However:

- Always run the **cleanup commands** at the end of each lab
- Don't leave EC2 instances, ALBs, or NAT Gateways running overnight — like leaving gen on
- Set up [AWS Budget Alerts](https://docs.aws.amazon.com/cost-management/latest/userguide/getting-started-ad.html) ($5 threshold)
- Use `aws sts get-caller-identity` to verify you're in right account

> *"The most expensive AWS resource is the one you forgot to delete."*

**For Nigeria:**
- Use virtual dollar card, set budget to $5
- Turn off resources after each lab
- Free Tier = t2.micro 750hrs, S3 5GB, RDS 750hrs — free if you clean up

---

## 🎓 How to Use This Repo

1. Start with **Lab 0** (setup your CLI)
2. Work through Labs 1–9 in order (each builds on the last)
3. Finish with **Lab 10** (the capstone) — this is where you experience real production patterns
4. If you get stuck, check the **Troubleshooting** section in each lab

```bash
# Clone this blueprint
git clone https://github.com/nkydigitech/aws-blueprint-.git
cd aws-blueprint-

# Start Lab 0
cd labs/lab-00-setup
cat README.md
```

---

## 📂 Repo Structure

```
aws-blueprint/
├── README.md                 # You are here — now with badges & beginner brain
├── index.html                # Dark theme landing page — now aligned with README
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

## ❓ Beginner FAQ — The Missing Manual

**Q: Do I need to know how to code?**
No. Labs use AWS CLI commands (copy-paste). Lab 10 uses Terraform explained line by line.

**Q: I'm scared of terminal, can I use console?**
Yes, but CLI teaches faster. We show both: console screenshot + CLI command.

**Q: How much internet data do I need?**
Very little. CLI is text. Lab 0 = ~30MB download. Each lab <5MB.

**Q: Webpage vs Repo confusion — fixed?**
Yes. This README = index.html. Lab list, philosophy, cost warning — all synced. No more two stories.

**Q: What job can this get me?**
Cloud Support Associate, Junior DevOps Engineer, Junior Cloud Engineer. In Lagos, those roles list EC2, VPC, S3, IAM — exactly Labs 1-6.

---

## 🙏 Contributing

Found a bug? Want to add a lab? PRs welcome!

- ⭐ Star this repo if it helped you
- 🐛 Open an issue for bugs
- 📝 PR for new analogies or labs

---

## 👩‍💻 Author

**Nkechi Anna Ahanonye — nkydigitech**

- Email: nkydigitech01@gmail.com
- LinkedIn: [Nkechi Anna Ahanonye](https://www.linkedin.com/in/nkechi-ahanonye)
- GitHub: [@nkydigitech](https://github.com/nkydigitech)

*"Reliability isn't a feature — it's the product."*

<p align="center">
  <img src="https://img.shields.io/badge/Built%20with%20💛%20for-Beginners%20who%20were%20confused%20before-FF9900?style=for-the-badge" alt="Built for beginners">
</p>
