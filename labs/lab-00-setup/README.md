# Lab 0: AWS CLI Setup

> **The Toolbox** — Before you build the cybercafé, you need your tools.

---

## 🎯 Objective

Install and configure the AWS CLI so you can talk to AWS from your terminal.

**The Analogy:** This is like getting the master key to all your branches before you open any of them.

---

## 📋 Prerequisites

- An AWS account (create one at [aws.amazon.com](https://aws.amazon.com))
- A terminal (Linux, macOS, or WSL)

---

## 🔧 Step-by-Step

### Step 1: Install AWS CLI v2

**macOS:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify installation:**
```bash
aws --version
```

**Expected Output:**
```
aws-cli/2.x.x Python/3.x.x Linux/5.x.x exe/x86_64.ubuntu.22
```

---

### Step 2: Create an IAM User (Not Your Root Account!)

**Never use your root account for daily work.** Create a dedicated user:

1. Log into the AWS Console → IAM → Users → **Create user**
2. User name: `aws-student`
3. Attach policies directly → **AdministratorAccess** (for learning only)
4. Click **Create user**
5. Go to the user → **Security credentials** → **Create access key**
6. Select **Command Line Interface (CLI)**
7. Copy the **Access key ID** and **Secret access key**

> ⚠️ **Save these keys NOW.** You can't see the secret key again.

---

### Step 3: Configure AWS CLI

```bash
aws configure
```

**You'll be prompted:**
```
AWS Access Key ID [None]: AKIAxxxxxxxxxxxxxxxx
AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Default region name [None]: us-east-1
Default output format [None]: json
```

> Use `us-east-1` for Labs 1–9. It's the oldest region with the most Free Tier support.

---

### Step 4: Verify Everything Works

```bash
aws sts get-caller-identity
```

**Expected Output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/aws-student"
}
```

If you see your account number and username, you're ready! 🎉

---

### Step 5: Set Your Lab Variables (Do This for Every Lab)

Create a file you'll reuse. These are the only things students change:

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"  # Change this to YOUR name or initials
export KEY_NAME="${MY_NAME}-aws-lab-key"
```

---

## 🧹 Cleanup

Nothing to clean up in this lab. But keep your credentials safe!

---

## 🐛 Troubleshooting

| Error | Fix |
|-------|-----|
| `aws: command not found` | Reinstall AWS CLI or restart your terminal |
| `Unable to locate credentials` | Run `aws configure` again |
| `AccessDenied` | Your IAM user doesn't have permissions. Attach `AdministratorAccess` policy |
| `InvalidClientTokenId` | Your Access Key ID is wrong. Copy it exactly from IAM |

---

## ✅ Checkpoint

Before moving to Lab 1, confirm:
- [ ] `aws --version` shows v2.x
- [ ] `aws sts get-caller-identity` returns your account info
- [ ] You have your Access Key and Secret Key saved securely

**Next → [Lab 1: Your First EC2](../lab-01-first-ec2/)**
