# Lab 10: Capstone — Production 3-Tier Architecture

> **The Full Cybercafé Chain** — Everything you've learned, automated end-to-end with Terraform.

---

## 🎯 Objective

Deploy a production-ready 3-tier web application using **Terraform** — zero manual console clicks, everything in code.

**What You Build:**
- 🌐 **Frontend:** Static website hosted on S3
- ⚙️ **Backend:** Auto-scaling EC2 instances behind an Application Load Balancer
- 🗄 **Database:** RDS MySQL in private subnets (Multi-AZ ready)
- 🔒 **Security:** Custom VPC, Security Groups, IAM roles
- 🌍 **Domain:** Route 53 (optional — requires a registered domain)
- 📊 **Monitoring:** CloudWatch dashboard and alarms

**The Analogy:** You've built a full cybercafé chain — reception desk (ALB), expandable branches (Auto Scaling), secure back office (RDS in private subnets), warehouse (S3), security system (IAM + Security Groups), and a phonebook entry (Route 53). Everything is documented, repeatable, and can be rebuilt in 10 minutes.

---

## 💰 Cost Warning

This is the **real production deployment**. Costs if left running:
- ALB: ~$16/month
- RDS db.t3.micro: ~$13/month
- 2x t2.micro EC2: Free Tier (or ~$15/month)
- NAT Gateway: ~$32/month
- S3: pennies
- Route 53: $0.50/month

**Total if left running: ~$75/month**

> ⚠️ **This lab creates REAL AWS resources. Run `terraform destroy` when done!**

---

## 📋 Prerequisites

- Terraform installed (`terraform --version` should show v1.5+)
- AWS CLI configured (from Lab 0)
- All previous labs completed (or understood)

---

## 📂 Project Structure

```
terraform-capstone/
├── main.tf           # Provider & backend config
├── variables.tf      # Input variables
├── vpc.tf            # VPC, subnets, IGW, NAT, route tables
├── security.tf       # Security groups (3-tier)
├── alb.tf            # Application Load Balancer
├── asg.tf            # Auto Scaling Group & Launch Template
├── rds.tf            # RDS MySQL instance
├── s3.tf             # S3 static website
├── route53.tf        # DNS records (optional)
├── cloudwatch.tf     # Dashboards & alarms
├── user-data.sh      # EC2 bootstrap script
└── outputs.tf        # Useful URLs and endpoints
```

---

## 🔧 Step-by-Step

### Step 1: Navigate to the Terraform Directory

```bash
cd terraform-capstone
```

---

### Step 2: Review Variables

Open `variables.tf` and customize:

```hcl
variable "my_name" {
  description = "Your name or identifier (used for all resource naming)"
  default     = "nkechi"
}

variable "aws_region" {
  description = "AWS region to deploy in"
  default     = "us-east-1"
}

variable "db_password" {
  description = "RDS master password (min 8 chars, must include uppercase, lowercase, number, symbol)"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Your registered domain name (optional — leave empty to skip Route 53)"
  default     = ""  # Example: "example.com"
}
```

---

### Step 3: Initialize Terraform

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

---

### Step 4: Plan the Deployment

```bash
terraform plan -var="db_password=YourSecurePass123!"
```

**Expected Output:**
```
Terraform will perform the following actions:

  # aws_autoscaling_group.main will be created
  + resource "aws_autoscaling_group" "main" {
      + desired_capacity          = 2
      + max_size                  = 4
      + min_size                  = 2
      ...
    }

  # aws_db_instance.main will be created
  + resource "aws_db_instance" "main" {
      + allocated_storage    = 20
      + engine               = "mysql"
      + instance_class       = "db.t3.micro"
      ...
    }

Plan: 25 to add, 0 to change, 0 to destroy.
```

> Review the plan carefully. You should see ~25 resources to create.

---

### Step 5: Apply the Deployment

```bash
terraform apply -var="db_password=YourSecurePass123!"
```

Type `yes` when prompted.

**Expected Output:**
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s [id=vpc-0abc123...]
...
aws_db_instance.main: Still creating... [4m30s elapsed]
aws_db_instance.main: Creation complete after 5m20s [id=nkechi-capstone-db]
...

Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

alb_dns_name = "nkechi-capstone-alb-123456789.us-east-1.elb.amazonaws.com"
rds_endpoint = "nkechi-capstone-db.abc123xyz.us-east-1.rds.amazonaws.com"
s3_website_url = "http://nkechi-capstone-static-a1b2c3d4.s3-website-us-east-1.amazonaws.com"
```

> 🎉 **Your production architecture is live!**

---

### Step 6: Verify the Deployment

**Test 1: Visit the Load Balancer**
```bash
export ALB_URL=$(terraform output -raw alb_dns_name)
curl http://$ALB_URL
```

**Expected Output:**
```html
<!DOCTYPE html>
<html>
<head><title>Capstone App</title></head>
<body>
<h1>🚀 AWS Capstone Application</h1>
<p>Instance: ip-10-0-1-45.ec2.internal</p>
<p>DB Status: <span id="db">Connected ✅</span></p>
</body>
</html>
```

**Test 2: Check Auto Scaling**
```bash
aws autoscaling describe-scaling-activities     --auto-scaling-group-name $(terraform output -raw asg_name)     --query 'Activities[0:3].[Description,StatusCode]' --output table
```

**Test 3: Verify RDS is in Private Subnet**
```bash
aws rds describe-db-instances     --db-instance-identifier $(terraform output -raw db_identifier)     --query 'DBInstances[0].[PubliclyAccessible,DBSubnetGroup]' --output table
```

**Expected Output:**
```
-------------------------
| DescribeDBInstances   |
+-----------------------+
|  false                |
|  nkechi-db-subnet...  |
+-----------------------+
```

> `PubliclyAccessible = false` means the database is NOT reachable from the internet. Only the web tier can talk to it.

**Test 4: Visit the S3 Static Website**
```bash
export S3_URL=$(terraform output -raw s3_website_url)
echo "Static site: $S3_URL"
```

Open that URL in your browser. You should see your static landing page.

---

### Step 7: Test Auto Scaling Under Load

```bash
# Get one instance IP and stress it
export INSTANCE_IP=$(aws ec2 describe-instances     --filters "Name=tag:Name,Values=nkechi-capstone-asg-instance" "Name=instance-state-name,Values=running"     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

ssh -i nkechi-capstone-key.pem ec2-user@$INSTANCE_IP     "sudo dnf install -y stress-ng && sudo stress-ng --cpu 4 --timeout 300s &"

echo "Load started. Watch for new instances:"
aws autoscaling describe-scaling-activities --auto-scaling-group-name $(terraform output -raw asg_name)
```

---

### Step 8: View the CloudWatch Dashboard

```bash
export DASHBOARD_URL="https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=$(terraform output -raw dashboard_name)"
echo "Dashboard: $DASHBOARD_URL"
```

Open the URL to see your live monitoring dashboard.

---

## 🧠 What You Built (The Full Picture)

```
                    ┌─────────────────────────────────────────┐
                    │           INTERNET                      │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │     Route 53 (your-domain.com)          │
                    │     → ALB DNS (optional)                │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │  Application Load Balancer (ALB)        │
                    │  Port 80 → Distributes traffic          │
                    └─────────────────┬───────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
┌───────▼────────┐          ┌────────▼────────┐          ┌────────▼────────┐
│  EC2 Instance  │          │  EC2 Instance   │          │  EC2 Instance   │
│  (t2.micro)    │          │  (t2.micro)     │          │  (auto-scaled)  │
│  Nginx + App   │          │  Nginx + App    │          │  Nginx + App    │
│  Public Subnet │          │  Public Subnet  │          │  Public Subnet  │
└───────┬────────┘          └────────┬────────┘          └─────────────────┘
        │                            │
        └────────────┬───────────────┘
                     │
        ┌────────────▼────────────┐
        │   Security Group: Web   │
        │   Port 3306 → DB only   │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │   RDS MySQL (db.t3.micro)│
        │   Private Subnet         │
        │   No public access       │
        │   Automated backups      │
        └─────────────────────────┘

        ┌─────────────────────────┐
        │   S3 Static Website     │
        │   (Landing page, assets)│
        │   Public read access    │
        └─────────────────────────┘
```

---

## ✅ Verification Checklist

- [ ] `terraform apply` completed with 0 errors
- [ ] ALB URL returns the web application
- [ ] Refreshing ALB URL shows different instance hostnames (load balancing)
- [ ] RDS is NOT publicly accessible
- [ ] S3 static website loads in browser
- [ ] Auto Scaling launches new instances under CPU load
- [ ] CloudWatch dashboard shows live metrics
- [ ] All resources are tagged with your name
- [ ] `terraform plan` shows 0 changes (infrastructure is stable)

---

## 🧹 Cleanup (CRITICAL)

```bash
terraform destroy -var="db_password=YourSecurePass123!"
```

Type `yes` when prompted.

**Expected Output:**
```
aws_db_instance.main: Destroying... [id=nkechi-capstone-db]
aws_db_instance.main: Still destroying... [id=nkechi-capstone-db, 2m elapsed]
...
aws_vpc.main: Destroying... [id=vpc-0abc123...]
aws_vpc.main: Destruction complete after 2s

Destroy complete! Resources: 25 destroyed.
```

> ⚠️ **Always run `terraform destroy` when done.** This is the beauty of IaC — one command cleans up everything.

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `terraform init` fails | Check internet connection. Terraform downloads providers from HashiCorp registry |
| RDS creation timeout | Normal. First RDS creation takes 5–10 minutes. Terraform will retry |
| `Error creating NAT Gateway` | NAT Gateway needs an Elastic IP. Check that `aws_eip.nat` was created first |
| ALB targets show `unhealthy` | Security group rules. Web SG must allow port 80 from ALB SG |
| Can't SSH to instances | Key pair not created. Check `tls_private_key` resource or use existing key |
| `terraform destroy` hangs on RDS | RDS deletion takes 5–10 minutes. Wait it out |

---

## 🎯 Stretch Goals

1. **Add HTTPS** — Request an ACM certificate and add an HTTPS listener:
   ```hcl
   resource "aws_acm_certificate" "main" {
     domain_name       = var.domain_name
     validation_method = "DNS"
   }
   ```
2. **Add a Bastion Host** — Secure SSH access to private instances:
   ```hcl
   resource "aws_instance" "bastion" {
     ami           = data.aws_ami.amazon_linux.id
     instance_type = "t2.micro"
     subnet_id     = aws_subnet.public_1.id
     key_name      = aws_key_pair.main.key_name
     # Security group allows SSH from your IP only
   }
   ```
3. **Enable RDS Multi-AZ** — High availability with automatic failover:
   ```hcl
   resource "aws_db_instance" "main" {
     multi_az = true
     # ... other config
   }
   ```
4. **Add WAF to ALB** — Protect against common web attacks
5. **Store state in S3** — Team collaboration with remote state:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "capstone/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

---

## 🏗 Local Sandbox Version

You can practice the Terraform structure locally with LocalStack:

```bash
cd local-sandbox
docker-compose up -d

# In another terminal, configure Terraform for LocalStack
cat > terraform-capstone/localstack-provider.tf << 'EOF'
provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    ec2            = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    rds            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    autoscaling    = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    sns            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    iam            = "http://localhost:4566"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
EOF

# Then run:
cd terraform-capstone
terraform init
terraform plan -var="db_password=LocalTest123!"
terraform apply -var="db_password=LocalTest123!"
```

> Note: LocalStack Community has limited support for some services. Use this to practice Terraform syntax and resource relationships, then deploy to real AWS for the full experience.

---

## 🎓 You've Completed the AWS Blueprint!

From `aws configure` to a production 3-tier architecture — you've built it all.

**What you can do now:**
- ✅ Explain AWS to beginners using relatable analogies
- ✅ Deploy EC2, VPC, S3, RDS, ALB, Auto Scaling from the CLI
- ✅ Secure resources with IAM and Security Groups
- ✅ Monitor with CloudWatch and set up alerts
- ✅ Automate infrastructure with Terraform
- ✅ Practice everything locally before production

**What's next?**
- Containerize the app with Docker (Lab 11?)
- Deploy to EKS (Kubernetes)
- Add CI/CD with GitHub Actions
- Get AWS Certified (Cloud Practitioner → Solutions Architect)

---

*"Reliability isn't a feature — it's the product."*
