# Lab 7: ALB & Auto Scaling

> **The Smart Traffic Director** — When 20 customers become 200, automatically open more branches and send each person to the shortest queue.

---

## 🎯 Objective

- Create a Launch Template (the blueprint for new servers)
- Create an Auto Scaling Group (automatically add/remove servers)
- Create an Application Load Balancer (distribute traffic)
- Test automatic scaling under load

**The Analogy:** Your cybercafé normally serves 20 customers. On weekends, 200 show up. Instead of turning people away:
1. **Auto Scaling** = You automatically open 10 more branches
2. **Load Balancer** = A smart receptionist sends each customer to the branch with the shortest queue
3. When the crowd leaves, the extra branches close automatically — you only pay for what you use

---

## 💰 Cost Warning

- ALB costs ~**$0.022/hour** (~$16/month)
- t2.micro instances = Free Tier eligible
- This lab takes ~30 minutes = **~$0.02**
- **Delete the ALB and ASG when done!**

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export KEY_NAME="${MY_NAME}-lab7-key"
```

---

## 🔧 Step-by-Step

### Step 1: Create a Key Pair and Get AMI

```bash
aws ec2 create-key-pair --key-name $KEY_NAME     --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem

export AMI_ID=$(aws ec2 describe-images --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)
```

---

### Step 2: Create a Security Group for the Web Tier

```bash
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"     --query 'Vpcs[0].VpcId' --output text)

export WEB_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab7-web-sg"     --description "Lab 7 web tier SG"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress --group-id $WEB_SG     --protocol tcp --port 80 --cidr 0.0.0.0/0

# Allow SSH from your IP
export MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $WEB_SG     --protocol tcp --port 22 --cidr ${MY_IP}/32

echo "Web SG: $WEB_SG"
```

**Expected Output:**
```
Web SG: sg-0123456789abcdef0
```

---

### Step 3: Create a Launch Template

This is the blueprint AWS uses to create new servers automatically.

```bash
cat > launch-template.json << EOF
{
    "LaunchTemplateName": "${MY_NAME}-lab7-template",
    "LaunchTemplateData": {
        "ImageId": "$AMI_ID",
        "InstanceType": "t2.micro",
        "KeyName": "$KEY_NAME",
        "SecurityGroupIds": ["$WEB_SG"],
        "UserData": "$(echo '#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>🚀 Hello from Auto Scaling!</h1><p>Instance ID: $INSTANCE_ID</p><p>Built by: $MY_NAME</p>" > /usr/share/nginx/html/index.html' | base64 -w 0)",
        "TagSpecifications": [{
            "ResourceType": "instance",
            "Tags": [{"Key": "Name", "Value": "${MY_NAME}-lab7-web"}]
        }]
    }
}
EOF

aws ec2 create-launch-template --cli-input-json file://launch-template.json
export LT_ID=$(aws ec2 describe-launch-templates     --launch-template-names "${MY_NAME}-lab7-template"     --query 'LaunchTemplates[0].LaunchTemplateId' --output text)

echo "Launch Template ID: $LT_ID"
```

**Expected Output:**
```
Launch Template ID: lt-0123456789abcdef0
```

---

### Step 4: Get Subnets for the ASG

```bash
export SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"     --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')

echo "Subnets: $SUBNETS"
```

**Expected Output:**
```
Subnets: subnet-0aaa...,subnet-0bbb...,subnet-0ccc...,subnet-0ddd...,subnet-0eee...,subnet-0fff...
```

---

### Step 5: Create the Auto Scaling Group

```bash
aws autoscaling create-auto-scaling-group     --auto-scaling-group-name "${MY_NAME}-lab7-asg"     --launch-template LaunchTemplateId=$LT_ID,Version='$Latest'     --min-size 2     --max-size 4     --desired-capacity 2     --vpc-zone-identifier "$SUBNETS"     --health-check-type EC2     --health-check-grace-period 300     --tags Key=Name,Value="${MY_NAME}-lab7-asg-instance",PropagateAtLaunch=true

echo "✅ Auto Scaling Group created with 2 instances"
```

**Expected Output:**
```
✅ Auto Scaling Group created with 2 instances
```

---

### Step 6: Create the Application Load Balancer

```bash
# Create ALB Security Group
export ALB_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab7-alb-sg"     --description "Lab 7 ALB SG"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $ALB_SG     --protocol tcp --port 80 --cidr 0.0.0.0/0

# Create ALB
export ALB_ARN=$(aws elbv2 create-load-balancer     --name "${MY_NAME}-lab7-alb"     --subnets $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text)     --security-groups $ALB_SG     --scheme internet-facing     --type application     --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN

echo "✅ ALB created"
```

**Expected Output:**
```
Waiting for ALB to be active...
✅ ALB created
```

---

### Step 7: Create Target Group and Attach ASG

```bash
# Get VPC ID for target group
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"     --query 'Vpcs[0].VpcId' --output text)

# Create Target Group
export TG_ARN=$(aws elbv2 create-target-group     --name "${MY_NAME}-lab7-tg"     --protocol HTTP     --port 80     --vpc-id $VPC_ID     --target-type instance     --health-check-path "/"     --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create Listener (ALB → Target Group)
aws elbv2 create-listener     --load-balancer-arn $ALB_ARN     --protocol HTTP     --port 80     --default-actions Type=forward,TargetGroupArn=$TG_ARN

# Attach ASG to Target Group
aws autoscaling attach-load-balancer-target-groups     --auto-scaling-group-name "${MY_NAME}-lab7-asg"     --target-group-arns $TG_ARN

echo "✅ Target Group and Listener created"
```

**Expected Output:**
```
✅ Target Group and Listener created
```

---

### Step 8: Get the ALB DNS and Test

```bash
export ALB_DNS=$(aws elbv2 describe-load-balancers     --load-balancer-arns $ALB_ARN     --query 'LoadBalancers[0].DNSName' --output text)

echo "🌐 Load Balancer URL: http://$ALB_DNS"
echo ""
echo "Testing (refresh a few times to see different instances)..."

for i in {1..5}; do
    echo "--- Request $i ---"
    curl -s http://$ALB_DNS | grep "Instance ID"
    sleep 1
done
```

**Expected Output:**
```
🌐 Load Balancer URL: http://nkechi-lab7-alb-123456789.us-east-1.elb.amazonaws.com

Testing (refresh a few times to see different instances)...
--- Request 1 ---
<p>Instance ID: i-0abc123def4567890</p>
--- Request 2 ---
<p>Instance ID: i-0fedcba0987654321</p>
--- Request 3 ---
<p>Instance ID: i-0abc123def4567890</p>
--- Request 4 ---
<p>Instance ID: i-0fedcba0987654321</p>
--- Request 5 ---
<p>Instance ID: i-0abc123def4567890</p>
```

> The Load Balancer is distributing traffic between your 2 instances! Each request might hit a different server.

---

### Step 9: Create Scaling Policies (The Magic)

```bash
# Create scaling policy: Scale OUT when CPU > 70%
aws autoscaling put-scaling-policy     --auto-scaling-group-name "${MY_NAME}-lab7-asg"     --policy-name "${MY_NAME}-scale-up"     --policy-type TargetTrackingScaling     --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "TargetValue": 70.0
    }'

echo "✅ Scaling policy created: Scale out when CPU > 70%"
```

**Expected Output:**
```
✅ Scaling policy created: Scale out when CPU > 70%
```

---

### Step 10: Simulate Load and Watch It Scale

```bash
# Get one of the instance IPs to stress
export INSTANCE_IP=$(aws ec2 describe-instances     --filters "Name=tag:Name,Values=${MY_NAME}-lab7-asg-instance" "Name=instance-state-name,Values=running"     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Stressing instance: $INSTANCE_IP"
echo "(In another terminal, run: aws autoscaling describe-scaling-activities --auto-scaling-group-name ${MY_NAME}-lab7-asg)"

# SSH in and create CPU load
ssh -i ${KEY_NAME}.pem ec2-user@$INSTANCE_IP     "sudo dnf install -y stress-ng && sudo stress-ng --cpu 4 --timeout 300s &"

echo ""
echo "Load started. Wait 2-3 minutes, then check:"
echo "  aws autoscaling describe-scaling-activities --auto-scaling-group-name ${MY_NAME}-lab7-asg"
echo "  aws ec2 describe-instances --filters 'Name=tag:Name,Values=${MY_NAME}-lab7-asg-instance'"
```

**Expected Output (after 2-3 minutes):**
```
# Check scaling activities:
aws autoscaling describe-scaling-activities --auto-scaling-group-name ${MY_NAME}-lab7-asg --query 'Activities[0].[Description,StartTime,StatusCode]' --output table

----------------------------------
|     DescribeScalingActivities  |
+----------+---------------------+
| Launching a new EC2 instance   |
| 2024-08-11...                  |
| Successful                     |
+----------+---------------------+
```

> AWS detected high CPU, automatically launched a new instance, and the Load Balancer started sending traffic to it too!

---

## 🧠 What Just Happened?

| Component | The Analogy | What You Built |
|-----------|-------------|----------------|
| **Launch Template** | The blueprint for new branches | AMI, instance type, user data, tags |
| **Auto Scaling Group** | "Keep between 2 and 4 branches open" | Min=2, Max=4, Desired=2 |
| **Load Balancer** | Smart receptionist | Distributes traffic across all healthy instances |
| **Target Group** | The list of open branches | Health checks, registers instances |
| **Scaling Policy** | "Open more branches when it's crowded" | CPU > 70% = launch new instance |
| **Health Check** | "Is this branch still serving coffee?" | Unhealthy instances are replaced automatically |

---

## ✅ Verification Checklist

- [ ] 2 EC2 instances running from the ASG
- [ ] ALB DNS responds with the web page
- [ ] Multiple requests hit different instances (load balancing works)
- [ ] Scaling policy created and attached
- [ ] Under load, a 3rd instance launches automatically
- [ ] When load stops, instances terminate back to 2

---

## 🧹 Cleanup

```bash
# Delete Auto Scaling Group (this terminates all instances!)
aws autoscaling update-auto-scaling-group     --auto-scaling-group-name "${MY_NAME}-lab7-asg"     --min-size 0 --max-size 0 --desired-capacity 0

# Wait for instances to terminate
sleep 30

aws autoscaling delete-auto-scaling-group     --auto-scaling-group-name "${MY_NAME}-lab7-asg" --force-delete

# Delete Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
sleep 30

# Delete Target Group
aws elbv2 delete-target-group --target-group-arn $TG_ARN

# Delete Launch Template
aws ec2 delete-launch-template --launch-template-id $LT_ID

# Delete Security Groups
aws ec2 delete-security-group --group-id $WEB_SG
aws ec2 delete-security-group --group-id $ALB_SG

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem launch-template.json

echo "✅ Lab 7 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| ASG instances show `Unhealthy` in Target Group | Security Group doesn't allow HTTP from ALB. Allow port 80 from ALB SG or 0.0.0.0/0 |
| ALB returns 503 | No healthy targets. Check that instances are running and nginx is installed |
| Instances not scaling | Scaling policies take 2–3 minutes to trigger. Check CloudWatch alarms |
| `ResourceInUse` when deleting | Delete in order: ASG → Listener → ALB → Target Group |
| UserData didn't run | Only runs on first boot. If you manually launch from template, it should work |

---

## 🎯 Stretch Goals

1. **Add HTTPS** — Request a certificate from ACM and create an HTTPS listener:
   ```bash
   aws acm request-certificate --domain-name example.com --validation-method DNS
   ```
2. **Add a Scale-In Policy** — Reduce instances when CPU < 30% for 10 minutes
3. **Use Lifecycle Hooks** — Run a script BEFORE the instance terminates (drain connections)
4. **Enable Access Logs** — Store ALB logs in S3 for analysis

---

**Next → [Lab 8: Route 53](../lab-08-route53/)**
