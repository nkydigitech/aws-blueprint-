# Lab 2: Regions & Availability Zones

> **Opening Branches Worldwide** — Deploy the same app in two continents and feel the speed difference.

---

## 🎯 Objective

Deploy a simple web server in **US East (N. Virginia)** and **Europe (Ireland)**, then compare response times.

**The Analogy:** Your cybercafé is booming in Lagos. You open branches in London and New York so customers there don't wait for signals to travel across the ocean. Each branch has 3 separate buildings (AZs) so if one floods, the others keep serving coffee.

---

## 💰 Cost Warning

- 2x t2.micro instances = still Free Tier eligible
- This lab takes ~20 minutes = **$0.00**
- **Terminate both instances when done!**

---

## 📋 One-Liner Setup

```bash
export MY_NAME="nkechi"
export KEY_NAME="${MY_NAME}-lab2-key"
```

---

## 🔧 Step-by-Step

### Step 1: Create One SSH Key (Reused in Both Regions)

```bash
aws ec2 create-key-pair     --key-name $KEY_NAME     --query 'KeyMaterial'     --output text > ${KEY_NAME}.pem

chmod 400 ${KEY_NAME}.pem
echo "✅ Key created"
```

---

### Step 2: Deploy in US East (N. Virginia) — `us-east-1`

```bash
export REGION_US="us-east-1"

# Get AMI for this region
export AMI_US=$(aws ec2 describe-images     --region $REGION_US     --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId'     --output text)

# Create Security Group
export SG_US=$(aws ec2 create-security-group     --region $REGION_US     --group-name "${MY_NAME}-lab2-us-sg"     --description "Lab 2 US security group"     --query 'GroupId'     --output text)

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress     --region $REGION_US     --group-id $SG_US     --protocol tcp --port 80 --cidr 0.0.0.0/0

# Launch instance
export INSTANCE_US=$(aws ec2 run-instances     --region $REGION_US     --image-id $AMI_US     --instance-type t2.micro     --key-name $KEY_NAME     --security-group-ids $SG_US     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-us-server},{Key=Region,Value=us-east-1}]"     --query 'Instances[0].InstanceId'     --output text)

# Wait and get IP
aws ec2 wait instance-running --region $REGION_US --instance-ids $INSTANCE_US
export IP_US=$(aws ec2 describe-instances     --region $REGION_US     --instance-ids $INSTANCE_US     --query 'Reservations[0].Instances[0].PublicIpAddress'     --output text)

echo "🇺🇸 US Server: http://$IP_US"
```

**Expected Output:**
```
🇺🇸 US Server: http://54.123.45.67
```

---

### Step 3: Deploy in Europe (Ireland) — `eu-west-1`

```bash
export REGION_EU="eu-west-1"

# Get AMI for this region (different AMI ID!)
export AMI_EU=$(aws ec2 describe-images     --region $REGION_EU     --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId'     --output text)

# Create Security Group
export SG_EU=$(aws ec2 create-security-group     --region $REGION_EU     --group-name "${MY_NAME}-lab2-eu-sg"     --description "Lab 2 EU security group"     --query 'GroupId'     --output text)

aws ec2 authorize-security-group-ingress     --region $REGION_EU     --group-id $SG_EU     --protocol tcp --port 80 --cidr 0.0.0.0/0

# Launch instance
export INSTANCE_EU=$(aws ec2 run-instances     --region $REGION_EU     --image-id $AMI_EU     --instance-type t2.micro     --key-name $KEY_NAME     --security-group-ids $SG_EU     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-eu-server},{Key=Region,Value=eu-west-1}]"     --query 'Instances[0].InstanceId'     --output text)

aws ec2 wait instance-running --region $REGION_EU --instance-ids $INSTANCE_EU
export IP_EU=$(aws ec2 describe-instances     --region $REGION_EU     --instance-ids $INSTANCE_EU     --query 'Reservations[0].Instances[0].PublicIpAddress'     --output text)

echo "🇪🇺 EU Server: http://$IP_EU"
```

**Expected Output:**
```
🇪🇺 EU Server: http://34.251.78.90
```

---

### Step 4: Install Web Servers on Both (User Data)

Instead of SSH'ing in, let's use **User Data** — a script that runs automatically when the instance boots. This is how you automate in production.

**First, terminate the old instances and relaunch with user data:**

```bash
# Terminate old ones
aws ec2 terminate-instances --region $REGION_US --instance-ids $INSTANCE_US
aws ec2 terminate-instances --region $REGION_EU --instance-ids $INSTANCE_EU
aws ec2 wait instance-terminated --region $REGION_US --instance-ids $INSTANCE_US
aws ec2 wait instance-terminated --region $REGION_EU --instance-ids $INSTANCE_EU

# Create user data script
cat > user-data.sh << 'EOF'
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>🌍 Hello from $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</h1>
<p>Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>
<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" > /usr/share/nginx/html/index.html
EOF

# Launch US with user data
export INSTANCE_US=$(aws ec2 run-instances     --region $REGION_US     --image-id $AMI_US     --instance-type t2.micro     --key-name $KEY_NAME     --security-group-ids $SG_US     --user-data file://user-data.sh     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-us-server}]"     --query 'Instances[0].InstanceId'     --output text)

# Launch EU with user data
export INSTANCE_EU=$(aws ec2 run-instances     --region $REGION_EU     --image-id $AMI_EU     --instance-type t2.micro     --key-name $KEY_NAME     --security-group-ids $SG_EU     --user-data file://user-data.sh     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-eu-server}]"     --query 'Instances[0].InstanceId'     --output text)

# Wait for both
echo "Waiting for US server..."
aws ec2 wait instance-status-ok --region $REGION_US --instance-ids $INSTANCE_US
echo "Waiting for EU server..."
aws ec2 wait instance-status-ok --region $REGION_EU --instance-ids $INSTANCE_EU

# Get new IPs
export IP_US=$(aws ec2 describe-instances --region $REGION_US --instance-ids $INSTANCE_US --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
export IP_EU=$(aws ec2 describe-instances --region $REGION_EU --instance-ids $INSTANCE_EU --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "🇺🇸 US Server: http://$IP_US"
echo "🇪🇺 EU Server: http://$IP_EU"
```

**Expected Output:**
```
Waiting for US server...
Waiting for EU server...
🇺🇸 US Server: http://54.123.45.67
🇪🇺 EU Server: http://34.251.78.90
```

---

### Step 5: Test Response Times

```bash
echo "=== Testing US Server ==="
time curl -s http://$IP_US
echo ""
echo "=== Testing EU Server ==="
time curl -s http://$IP_EU
```

**Expected Output (varies by your location):**
```
=== Testing US Server ===
<h1>🌍 Hello from us-east-1a</h1>
<p>Region: us-east-1</p>
<p>Instance ID: i-0123456789abcdef0</p>
real    0m0.234s

=== Testing EU Server ===
<h1>🌍 Hello from eu-west-1a</h1>
<p>Region: eu-west-1</p>
<p>Instance ID: i-0fedcba0987654321</p>
real    0m1.876s
```

> Notice the time difference? The server closer to you responds faster. That's why regions matter.

---

### Step 6: Discover Availability Zones

```bash
echo "=== US East AZs ==="
aws ec2 describe-availability-zones --region us-east-1 --query 'AvailabilityZones[*].ZoneName' --output table

echo ""
echo "=== EU West AZs ==="
aws ec2 describe-availability-zones --region eu-west-1 --query 'AvailabilityZones[*].ZoneName' --output table
```

**Expected Output:**
```
=== US East AZs ===
-------------------
|  ZoneNames      |
+-----------------+
|  us-east-1a     |
|  us-east-1b     |
|  us-east-1c     |
|  us-east-1d     |
|  us-east-1e     |
|  us-east-1f     |
+-----------------+

=== EU West AZs ===
-------------------
|  ZoneNames      |
+-----------------+
|  eu-west-1a     |
|  eu-west-1b     |
|  eu-west-1c     |
+-----------------+
```

---

## 🧠 What Just Happened?

| Concept | The Analogy | What You Saw |
|---------|-------------|--------------|
| **Region** | A city where you have a branch | `us-east-1`, `eu-west-1` |
| **Availability Zone** | Separate buildings in that city | `us-east-1a`, `us-east-1b` |
| **AMI** | The operating system image | Different AMI IDs per region |
| **User Data** | Instructions left for the staff before opening | Script ran automatically on boot |
| **Latency** | How long the coffee takes to arrive | US was faster if you're in Africa/Americas |

---

## ✅ Verification Checklist

- [ ] Two instances running in different regions
- [ ] Both show a webpage with their AZ and Region
- [ ] `time curl` shows different response times
- [ ] You can list AZs for any region

---

## 🧹 Cleanup

```bash
# Terminate instances
aws ec2 terminate-instances --region $REGION_US --instance-ids $INSTANCE_US
aws ec2 terminate-instances --region $REGION_EU --instance-ids $INSTANCE_EU
aws ec2 wait instance-terminated --region $REGION_US --instance-ids $INSTANCE_US
aws ec2 wait instance-terminated --region $REGION_EU --instance-ids $INSTANCE_EU

# Delete security groups
aws ec2 delete-security-group --region $REGION_US --group-id $SG_US
aws ec2 delete-security-group --region $REGION_EU --group-id $SG_EU

# Delete key pair (in both regions)
aws ec2 delete-key-pair --region $REGION_US --key-name $KEY_NAME
aws ec2 delete-key-pair --region $REGION_EU --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem user-data.sh

echo "✅ Lab 2 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `InvalidKeyPair.NotFound` | Key pairs are region-specific. You must create/import in each region |
| User data didn't run | It only runs on FIRST boot. If you reboot, it won't run again |
| Can't see the webpage | Wait for `instance-status-ok`. User data takes 1–2 minutes |
| Different AMI IDs | AMIs are region-specific. Always query per region |

---

## 🎯 Stretch Goals

1. **Deploy in a 3rd region** (e.g., `af-south-1` for South Africa)
2. **Use `--placement AvailabilityZone=`** to force an instance into a specific AZ
3. **Check instance metadata** from inside the server:
   ```bash
   curl http://169.254.169.254/latest/meta-data/
   ```

---

**Next → [Lab 3: VPC & Networking](../lab-03-vpc/)**
