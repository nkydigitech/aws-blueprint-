# 🗺 Lab-to-LocalStack Mapping Guide

> **How to practice every AWS Blueprint lab locally before deploying to real AWS.**

---

## 🚀 Quick Start

```bash
# 1. Start the sandbox
cd local-sandbox
docker-compose up -d

# 2. Wait 30 seconds, then verify
awslocal s3 ls

# 3. For every lab, replace `aws` with `awslocal`
```

---

## Lab-by-Lab Mapping

### Lab 0: AWS CLI Setup
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws configure` | `awslocal configure` (use `test` / `test` for keys) |
| `aws sts get-caller-identity` | `awslocal sts get-caller-identity` |

**Local Setup:**
```bash
awslocal configure
# Access Key: test
# Secret Key: test
# Region: us-east-1
# Output: json
```

---

### Lab 1: First EC2
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws ec2 create-key-pair` | `awslocal ec2 create-key-pair` |
| `aws ec2 run-instances` | `awslocal ec2 run-instances` |
| SSH to real IP | N/A (LocalStack simulates, no real OS) |
| `curl http://$PUBLIC_IP` | N/A |

**Note:** LocalStack EC2 instances don't run real operating systems. Use this lab to practice the **CLI commands and workflow**, then do the real SSH experience on AWS.

---

### Lab 2: Regions & AZs
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws ec2 describe-availability-zones` | `awslocal ec2 describe-availability-zones` |
| Multi-region deployment | LocalStack only simulates one region |

**Note:** LocalStack supports one region at a time. Practice the commands, but real multi-region testing requires AWS.

---

### Lab 3: VPC & Networking
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws ec2 create-vpc` | `awslocal ec2 create-vpc` |
| `aws ec2 create-subnet` | `awslocal ec2 create-subnet` |
| `aws ec2 create-nat-gateway` | `awslocal ec2 create-nat-gateway` |
| SSH bastion host pattern | N/A (no real SSH) |

**Note:** VPC resources create successfully in LocalStack. Use this to practice the **resource relationships** (VPC → Subnet → IGW → Route Table).

---

### Lab 4: IAM & Security Groups
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws iam create-user` | `awslocal iam create-user` |
| `aws iam create-role` | `awslocal iam create-role` |
| `aws ec2 create-security-group` | `awslocal ec2 create-security-group` |
| Instance profile testing | N/A (no real EC2 OS) |

**Note:** IAM is fully supported in LocalStack. Practice **policies, roles, and users** completely locally.

---

### Lab 5: S3
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws s3 mb` | `awslocal s3 mb` |
| `aws s3 cp` | `awslocal s3 cp` |
| `aws s3 sync` | `awslocal s3 sync` |
| Static website hosting | ✅ Fully works! |
| `aws s3api put-bucket-versioning` | `awslocal s3api put-bucket-versioning` |

**Note:** S3 is one of LocalStack's **best-supported services**. You can practice EVERYTHING locally, including static websites!

**Test locally:**
```bash
awslocal s3 mb s3://my-local-bucket
awslocal s3 cp index.html s3://my-local-bucket/
awslocal s3api put-bucket-website-configuration --bucket my-local-bucket --website-configuration '{"IndexDocument":{"Suffix":"index.html"}}'
# Visit: http://my-local-bucket.s3.localhost.localstack.cloud:4566/index.html
```

---

### Lab 6: RDS
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws rds create-db-instance` | `awslocal rds create-db-instance` |
| Connect with MySQL client | N/A (no real DB engine) |
| Create tables and insert data | N/A |

**Note:** LocalStack creates RDS endpoints but doesn't run a real MySQL engine. Practice the **provisioning commands**, then do real DB work on AWS.

---

### Lab 7: ALB & Auto Scaling
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws autoscaling create-auto-scaling-group` | `awslocal autoscaling create-auto-scaling-group` |
| `aws elbv2 create-load-balancer` | `awslocal elbv2 create-load-balancer` |
| Real load balancing | ⚠️ Limited |
| Auto scaling under CPU load | N/A (no real instances) |

**Note:** Practice the **resource creation and relationships**. Real load testing requires AWS.

---

### Lab 8: Route 53
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws route53 create-hosted-zone` | `awslocal route53 create-hosted-zone` |
| `aws route53 change-resource-record-sets` | `awslocal route53 change-resource-record-sets` |
| Real DNS resolution | ⚠️ Local only |

**Note:** Route 53 works locally for testing. You won't get real internet DNS, but the API calls work identically.

---

### Lab 9: CloudWatch
| Real AWS | Local Sandbox |
|----------|---------------|
| `aws cloudwatch put-dashboard` | `awslocal cloudwatch put-dashboard` |
| `aws cloudwatch put-metric-alarm` | `awslocal cloudwatch put-metric-alarm` |
| `aws logs create-log-group` | `awslocal logs create-log-group` |
| Email notifications | N/A (no real email) |
| CloudWatch Agent | N/A (no real OS) |

**Note:** CloudWatch metrics and logs work locally. Alarms change state but won't send real emails.

---

### Lab 10: Capstone (Terraform)
| Real AWS | Local Sandbox |
|----------|---------------|
| `terraform apply` | `terraform apply` with LocalStack provider |
| Real infrastructure | Simulated infrastructure |
| `terraform destroy` | `terraform destroy` (instant!) |

**LocalStack Provider Config:**
```hcl
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    ec2         = "http://localhost:4566"
    s3          = "http://s3.localhost.localstack.cloud:4566"
    rds         = "http://localhost:4566"
    elbv2       = "http://localhost:4566"
    autoscaling = "http://localhost:4566"
    cloudwatch  = "http://localhost:4566"
    sns         = "http://localhost:4566"
    route53     = "http://localhost:4566"
    iam         = "http://localhost:4566"
    logs        = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
```

---

## ✅ LocalStack Service Support Matrix

| Service | Support Level | Notes |
|---------|--------------|-------|
| S3 | ⭐⭐⭐⭐⭐ | Full support — best for local practice |
| IAM | ⭐⭐⭐⭐⭐ | Full support — users, roles, policies |
| VPC | ⭐⭐⭐⭐ | Basic networking works |
| EC2 | ⭐⭐⭐ | Instances launch but no real OS |
| Security Groups | ⭐⭐⭐⭐ | Rules create and validate |
| Route 53 | ⭐⭐⭐⭐ | DNS records work locally |
| CloudWatch | ⭐⭐⭐⭐ | Metrics, logs, alarms work |
| SNS | ⭐⭐⭐⭐ | Topics and subscriptions work |
| RDS | ⭐⭐⭐ | Endpoints created, no real engine |
| ALB/ELB | ⭐⭐⭐ | Creates but limited routing |
| Auto Scaling | ⭐⭐⭐ | Groups created, no real scaling |
| Lambda | ⭐⭐⭐⭐⭐ | Full support |
| API Gateway | ⭐⭐⭐⭐ | Full support |
| SQS | ⭐⭐⭐⭐⭐ | Full support |

---

## 🎯 Recommended Practice Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    LEARNING PHASE                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Lab 0-4 (Basics)    →  Practice FULLY locally             │
│  Lab 5 (S3)          →  Practice FULLY locally             │
│  Lab 6 (RDS)         →  Practice commands locally,         │
│                        then real DB on AWS                  │
│  Lab 7 (ALB/ASG)     →  Practice resource creation         │
│                        locally, real scaling on AWS         │
│  Lab 8 (Route 53)    →  Practice locally, real domain      │
│                        on AWS                               │
│  Lab 9 (CloudWatch)  →  Practice locally, real alerts      │
│                        on AWS                               │
│  Lab 10 (Capstone)   →  Practice Terraform locally,        │
│                        then deploy to REAL AWS              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🐛 Common LocalStack Issues

| Issue | Fix |
|-------|-----|
| `Connection refused` | `docker-compose up -d` — LocalStack isn't running |
| `awslocal: command not found` | `pip install awscli-local` |
| S3 website not loading | Use `http://bucket-name.s3.localhost.localstack.cloud:4566` |
| Terraform provider errors | Add `skip_credentials_validation = true` |
| Out of memory | Increase Docker memory to 4GB |
| Services not responding | Wait 30s after `docker-compose up` |

---

*"Practice locally. Deploy confidently."*
