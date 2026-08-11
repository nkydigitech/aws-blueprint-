# 📋 AWS Blueprint Cheatsheet

> **Quick reference for the most common AWS CLI commands.**

---

## 🔧 Setup & Config

```bash
# Configure AWS CLI
aws configure
aws configure --profile production

# Verify identity
aws sts get-caller-identity

# List profiles
aws configure list-profiles

# Switch profile
export AWS_PROFILE=production
```

---

## ☁️ EC2

```bash
# Create key pair
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
chmod 400 my-key.pem

# Launch instance
aws ec2 run-instances     --image-id ami-12345678     --instance-type t2.micro     --key-name my-key     --security-group-ids sg-xxx     --subnet-id subnet-xxx     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-server}]'

# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table

# Start / Stop / Terminate
aws ec2 start-instances --instance-ids i-xxx
aws ec2 stop-instances --instance-ids i-xxx
aws ec2 terminate-instances --instance-ids i-xxx

# Wait for status
aws ec2 wait instance-running --instance-ids i-xxx
aws ec2 wait instance-status-ok --instance-ids i-xxx
aws ec2 wait instance-terminated --instance-ids i-xxx

# Get latest Amazon Linux AMI
aws ec2 describe-images --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
```

---

## 🛡 Security Groups

```bash
# Create SG
aws ec2 create-security-group --group-name my-sg --description "My SG" --vpc-id vpc-xxx

# Add inbound rule (from IP)
aws ec2 authorize-security-group-ingress     --group-id sg-xxx     --protocol tcp --port 22 --cidr 192.168.1.1/32

# Add inbound rule (from another SG)
aws ec2 authorize-security-group-ingress     --group-id sg-xxx     --protocol tcp --port 3306 --source-group sg-yyy

# View rules
aws ec2 describe-security-groups --group-ids sg-xxx --query 'SecurityGroups[0].IpPermissions' --output table
```

---

## 🌐 VPC & Networking

```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'

# Create subnet
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a

# Create IGW
aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxx --vpc-id vpc-xxx

# Create route table and route
aws ec2 create-route-table --vpc-id vpc-xxx
aws ec2 create-route --route-table-id rtb-xxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxx
aws ec2 associate-route-table --subnet-id subnet-xxx --route-table-id rtb-xxx

# List AZs
aws ec2 describe-availability-zones --query 'AvailabilityZones[*].ZoneName' --output table
```

---

## 👤 IAM

```bash
# Create user
aws iam create-user --user-name my-user

# Attach policy
aws iam attach-user-policy --user-name my-user --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Create access keys
aws iam create-access-key --user-name my-user

# Create role
aws iam create-role --role-name my-role --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy --role-name my-role --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create instance profile
aws iam create-instance-profile --instance-profile-name my-profile
aws iam add-role-to-instance-profile --instance-profile-name my-profile --role-name my-role

# List policies
aws iam list-attached-user-policies --user-name my-user
```

---

## 📦 S3

```bash
# Create bucket
aws s3 mb s3://my-unique-bucket-name

# Upload file
aws s3 cp file.txt s3://my-bucket/
aws s3 cp folder/ s3://my-bucket/folder/ --recursive

# Download file
aws s3 cp s3://my-bucket/file.txt ./

# Sync (like rsync)
aws s3 sync local-folder s3://my-bucket/remote-folder/

# List contents
aws s3 ls s3://my-bucket/
aws s3 ls s3://my-bucket/ --recursive

# Delete
aws s3 rm s3://my-bucket/file.txt
aws s3 rm s3://my-bucket/ --recursive
aws s3 rb s3://my-bucket  # bucket must be empty

# Enable versioning
aws s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled

# Static website
aws s3api put-bucket-website --bucket my-bucket --website-configuration '{"IndexDocument":{"Suffix":"index.html"}}'
```

---

## 🗄 RDS

```bash
# Create DB instance
aws rds create-db-instance     --db-instance-identifier my-db     --db-instance-class db.t3.micro     --engine mysql     --master-username admin     --master-user-password MyPass123!     --allocated-storage 20

# Wait for available
aws rds wait db-instance-available --db-instance-identifier my-db

# Get endpoint
aws rds describe-db-instances --db-instance-identifier my-db     --query 'DBInstances[0].Endpoint.Address' --output text

# Delete DB
aws rds delete-db-instance --db-instance-identifier my-db --skip-final-snapshot
aws rds wait db-instance-deleted --db-instance-identifier my-db
```

---

## ⚖ Load Balancing & Auto Scaling

```bash
# Create target group
aws elbv2 create-target-group --name my-tg --protocol HTTP --port 80 --vpc-id vpc-xxx

# Create ALB
aws elbv2 create-load-balancer --name my-alb --subnets subnet-1 subnet-2 --security-groups sg-xxx

# Create listener
aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:... --protocol HTTP --port 80     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...

# Create launch template
aws ec2 create-launch-template --launch-template-name my-template --launch-template-data '{...}'

# Create ASG
aws autoscaling create-auto-scaling-group     --auto-scaling-group-name my-asg     --launch-template LaunchTemplateId=lt-xxx,Version='$Latest'     --min-size 1 --max-size 4 --desired-capacity 2     --vpc-zone-identifier "subnet-1,subnet-2"

# Attach to target group
aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name my-asg --target-group-arns arn:aws:elasticloadbalancing:...

# Set scaling policy
aws autoscaling put-scaling-policy --auto-scaling-group-name my-asg --policy-name scale-up     --policy-type TargetTrackingScaling     --target-tracking-configuration '{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":70.0}'
```

---

## 📊 CloudWatch

```bash
# Create dashboard
aws cloudwatch put-dashboard --dashboard-name my-dashboard --dashboard-body '{...}'

# Create alarm
aws cloudwatch put-metric-alarm     --alarm-name high-cpu     --metric-name CPUUtilization --namespace AWS/EC2     --statistic Average --period 300 --threshold 70     --comparison-operator GreaterThanThreshold     --dimensions Name=InstanceId,Value=i-xxx

# View metrics
aws cloudwatch get-metric-statistics     --namespace AWS/EC2 --metric-name CPUUtilization     --dimensions Name=InstanceId,Value=i-xxx     --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T23:59:59Z     --period 3600 --statistics Average

# Logs
aws logs create-log-group --log-group-name my-logs
aws logs describe-log-groups
aws logs get-log-events --log-group-name my-logs --log-stream-name my-stream
```

---

## 🌍 Route 53

```bash
# Create hosted zone
aws route53 create-hosted-zone --name example.com --caller-reference $(date +%s)

# Get name servers
aws route53 get-hosted-zone --id /hostedzone/xxx --query 'DelegationSet.NameServers'

# Create A record
aws route53 change-resource-record-sets --hosted-zone-id xxx --change-batch file://a-record.json

# List records
aws route53 list-resource-record-sets --hosted-zone-id xxx

# Create health check
aws route53 create-health-check --caller-reference $(date +%s)     --health-check-config '{"IPAddress":"1.2.3.4","Port":80,"Type":"HTTP","ResourcePath":"/"}'
```

---

## 🏗 Terraform Quick Commands

```bash
terraform init          # Initialize
terraform plan          # Preview changes
terraform apply         # Deploy
terraform apply -auto-approve   # Deploy without confirmation
terraform destroy       # Delete everything
terraform show          # Show current state
terraform state list    # List managed resources
terraform output        # Show outputs
terraform fmt           # Format code
terraform validate      # Validate syntax
```

---

## 🐛 Quick Troubleshooting

```bash
# Check AWS CLI version
aws --version

# Check which profile is active
aws sts get-caller-identity

# Debug a command
aws ec2 describe-instances --debug

# Check service health (LocalStack)
curl http://localhost:4566/_localstack/health

# Find your public IP
curl https://checkip.amazonaws.com
```

---

## 💰 Cost-Saving Tips

| Resource | Cost If Left Running | Cleanup Command |
|----------|---------------------|-----------------|
| EC2 t2.micro | Free Tier / ~$8/mo | `aws ec2 terminate-instances` |
| RDS db.t3.micro | ~$13/mo | `aws rds delete-db-instance` |
| ALB | ~$16/mo | `aws elbv2 delete-load-balancer` |
| NAT Gateway | ~$32/mo | `aws ec2 delete-nat-gateway` |
| Elastic IP (unattached) | ~$4/mo | `aws ec2 release-address` |
| Route 53 Zone | $0.50/mo | `aws route53 delete-hosted-zone` |

---

*"Keep this open. You'll need it."*
