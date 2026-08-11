# Lab 3: VPC & Networking

> **Building a Fenced Estate** — Create your own private network in the cloud with public reception areas and private staff rooms.

---

## 🎯 Objective

Build a custom VPC with:
- 2 Public Subnets (for web servers — customers can reach these)
- 2 Private Subnets (for databases — hidden from the internet)
- An Internet Gateway (the main gate)
- A NAT Gateway (the back door for private servers to download updates)
- Route Tables (the signs that direct traffic)

**The Analogy:** You're building a secure estate. The front gate (Internet Gateway) lets visitors into the reception area (public subnets). Your staff quarters (private subnets) are behind a second fence. Staff can go out through the back door (NAT Gateway) to buy supplies, but strangers can't walk in.

---

## 💰 Cost Warning

- **NAT Gateway costs ~$0.045/hour** (~$32/month if left running)
- This lab takes ~30 minutes = **~$0.02**
- **Delete the NAT Gateway when done!** This is the most expensive part.

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export VPC_CIDR="10.0.0.0/16"
export PUBLIC_SUBNET_1_CIDR="10.0.1.0/24"
export PUBLIC_SUBNET_2_CIDR="10.0.2.0/24"
export PRIVATE_SUBNET_1_CIDR="10.0.3.0/24"
export PRIVATE_SUBNET_2_CIDR="10.0.4.0/24"
```

---

## 🔧 Step-by-Step

### Step 1: Create the VPC (The Fenced Estate)

```bash
export VPC_ID=$(aws ec2 create-vpc     --cidr-block $VPC_CIDR     --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${MY_NAME}-lab3-vpc}]"     --query 'Vpc.VpcId'     --output text)

# Enable DNS hostnames (so instances get public DNS names)
aws ec2 modify-vpc-attribute     --vpc-id $VPC_ID     --enable-dns-hostnames '{"Value":true}'

echo "VPC ID: $VPC_ID"
```

**Expected Output:**
```
VPC ID: vpc-0123456789abcdef0
```

---

### Step 2: Create Subnets (The Rooms)

```bash
# Get AZs
export AZ1=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
export AZ2=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[1].ZoneName' --output text)

# Public Subnet 1
export PUBLIC_SUBNET_1=$(aws ec2 create-subnet     --vpc-id $VPC_ID     --cidr-block $PUBLIC_SUBNET_1_CIDR     --availability-zone $AZ1     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${MY_NAME}-public-1}]"     --query 'Subnet.SubnetId' --output text)

# Public Subnet 2
export PUBLIC_SUBNET_2=$(aws ec2 create-subnet     --vpc-id $VPC_ID     --cidr-block $PUBLIC_SUBNET_2_CIDR     --availability-zone $AZ2     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${MY_NAME}-public-2}]"     --query 'Subnet.SubnetId' --output text)

# Private Subnet 1
export PRIVATE_SUBNET_1=$(aws ec2 create-subnet     --vpc-id $VPC_ID     --cidr-block $PRIVATE_SUBNET_1_CIDR     --availability-zone $AZ1     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${MY_NAME}-private-1}]"     --query 'Subnet.SubnetId' --output text)

# Private Subnet 2
export PRIVATE_SUBNET_2=$(aws ec2 create-subnet     --vpc-id $VPC_ID     --cidr-block $PRIVATE_SUBNET_2_CIDR     --availability-zone $AZ2     --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${MY_NAME}-private-2}]"     --query 'Subnet.SubnetId' --output text)

echo "Public 1:  $PUBLIC_SUBNET_1"
echo "Public 2:  $PUBLIC_SUBNET_2"
echo "Private 1: $PRIVATE_SUBNET_1"
echo "Private 2: $PRIVATE_SUBNET_2"
```

**Expected Output:**
```
Public 1:  subnet-0aaaaaaaaaaaaaaa
Public 2:  subnet-0bbbbbbbbbbbbbbb
Private 1: subnet-0ccccccccccccccc
Private 2: subnet-0ddddddddddddddd
```

---

### Step 3: Create Internet Gateway (The Main Gate)

```bash
export IGW_ID=$(aws ec2 create-internet-gateway     --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${MY_NAME}-lab3-igw}]"     --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway     --internet-gateway-id $IGW_ID     --vpc-id $VPC_ID

echo "IGW ID: $IGW_ID"
```

**Expected Output:**
```
IGW ID: igw-0123456789abcdef0
```

---

### Step 4: Create Route Tables & Associate

```bash
# Public Route Table
export PUBLIC_RT=$(aws ec2 create-route-table     --vpc-id $VPC_ID     --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${MY_NAME}-public-rt}]"     --query 'RouteTable.RouteTableId' --output text)

# Route: 0.0.0.0/0 → Internet Gateway ("If you don't know where it goes, send it to the main gate")
aws ec2 create-route     --route-table-id $PUBLIC_RT     --destination-cidr-block 0.0.0.0/0     --gateway-id $IGW_ID

# Associate public subnets with public route table
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_1 --route-table-id $PUBLIC_RT
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_2 --route-table-id $PUBLIC_RT

# Private Route Table (no internet route yet — we'll add NAT later)
export PRIVATE_RT=$(aws ec2 create-route-table     --vpc-id $VPC_ID     --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${MY_NAME}-private-rt}]"     --query 'RouteTable.RouteTableId' --output text)

aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_1 --route-table-id $PRIVATE_RT
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_2 --route-table-id $PRIVATE_RT

echo "Public RT:  $PUBLIC_RT"
echo "Private RT: $PRIVATE_RT"
```

**Expected Output:**
```
Public RT:  rtb-0aaaaaaaaaaaaaaa
Private RT: rtb-0bbbbbbbbbbbbbbb
```

---

### Step 5: Create NAT Gateway (The Back Door)

NAT Gateway needs a public IP (Elastic IP) to work.

```bash
# Allocate Elastic IP
export EIP_ID=$(aws ec2 allocate-address     --domain vpc     --query 'AllocationId' --output text)

# Create NAT Gateway in Public Subnet 1
export NAT_GW_ID=$(aws ec2 create-nat-gateway     --subnet-id $PUBLIC_SUBNET_1     --allocation-id $EIP_ID     --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${MY_NAME}-lab3-nat}]"     --query 'NatGateway.NatGatewayId' --output text)

echo "NAT Gateway: $NAT_GW_ID"
echo "Waiting for NAT Gateway to be available (this takes 2-3 minutes)..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

echo "✅ NAT Gateway is ready!"
```

**Expected Output:**
```
NAT Gateway: nat-0123456789abcdef0
Waiting for NAT Gateway to be available (this takes 2-3 minutes)...
✅ NAT Gateway is ready!
```

---

### Step 6: Add NAT Route to Private Route Table

```bash
aws ec2 create-route     --route-table-id $PRIVATE_RT     --destination-cidr-block 0.0.0.0/0     --nat-gateway-id $NAT_GW_ID

echo "✅ Private subnets can now reach the internet through NAT"
```

**Expected Output:**
```
✅ Private subnets can now reach the internet through NAT
```

---

### Step 7: Test It — Launch Instances in Both Subnets

```bash
export KEY_NAME="${MY_NAME}-lab3-key"

# Create key
aws ec2 create-key-pair --key-name $KEY_NAME     --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem

# Get AMI
export AMI_ID=$(aws ec2 describe-images --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

# Security Group for public instance
export SG_PUBLIC=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab3-public-sg"     --description "Public instance SG"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

export MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $SG_PUBLIC     --protocol tcp --port 22 --cidr ${MY_IP}/32
aws ec2 authorize-security-group-ingress --group-id $SG_PUBLIC     --protocol tcp --port 80 --cidr 0.0.0.0/0

# Launch PUBLIC instance (with public IP)
export PUBLIC_INSTANCE=$(aws ec2 run-instances     --image-id $AMI_ID --instance-type t2.micro     --key-name $KEY_NAME --security-group-ids $SG_PUBLIC     --subnet-id $PUBLIC_SUBNET_1     --associate-public-ip-address     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-public-server}]"     --query 'Instances[0].InstanceId' --output text)

# Security Group for private instance (NO inbound from internet!)
export SG_PRIVATE=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab3-private-sg"     --description "Private instance SG"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

# Only allow SSH from the VPC itself (from the public instance)
aws ec2 authorize-security-group-ingress --group-id $SG_PRIVATE     --protocol tcp --port 22 --cidr $VPC_CIDR

# Launch PRIVATE instance (NO public IP)
export PRIVATE_INSTANCE=$(aws ec2 run-instances     --image-id $AMI_ID --instance-type t2.micro     --key-name $KEY_NAME --security-group-ids $SG_PRIVATE     --subnet-id $PRIVATE_SUBNET_1     --no-associate-public-ip-address     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-private-server}]"     --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids $PUBLIC_INSTANCE $PRIVATE_INSTANCE

export PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $PUBLIC_INSTANCE     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
export PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $PRIVATE_INSTANCE     --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

echo "Public Server:  $PUBLIC_IP (SSH: ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP)"
echo "Private Server: $PRIVATE_IP (NO public IP — can only SSH through public server)"
```

**Expected Output:**
```
Public Server:  54.123.45.67 (SSH: ssh -i nkechi-lab3-key.pem ec2-user@54.123.45.67)
Private Server: 10.0.3.45 (NO public IP — can only SSH through public server)
```

---

### Step 8: Verify the Network

**Test 1: Public server can reach the internet**
```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP "curl -s https://checkip.amazonaws.com"
```

**Expected Output:**
```
54.123.45.67
```

**Test 2: SSH from public server to private server (using the private IP)**
```bash
# Copy key to public server
scp -i ${KEY_NAME}.pem ${KEY_NAME}.pem ec2-user@$PUBLIC_IP:/home/ec2-user/
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP "chmod 400 ${KEY_NAME}.pem && ssh -o StrictHostKeyChecking=no -i ${KEY_NAME}.pem ec2-user@$PRIVATE_IP 'curl -s https://checkip.amazonaws.com'"
```

**Expected Output:**
```
54.123.45.67   <-- Same IP! Because private server goes THROUGH NAT Gateway
```

> The private server has NO public IP, but it can still reach the internet through the NAT Gateway. And NO ONE from the internet can reach it directly.

---

## 🧠 What Just Happened?

| Component | The Analogy | What It Does |
|-----------|-------------|--------------|
| **VPC** | The fenced estate | Your private network (10.0.0.0/16) |
| **Public Subnet** | Reception area | Servers here have public IPs, visitors can reach them |
| **Private Subnet** | Staff quarters | Servers here are hidden, no direct internet access |
| **Internet Gateway** | Main gate | Allows traffic between your VPC and the internet |
| **NAT Gateway** | Back door | Lets private servers download updates without exposing them |
| **Route Table** | Direction signs | Tells traffic where to go |
| **Elastic IP** | Reserved parking spot | Static public IP for the NAT Gateway |

---

## ✅ Verification Checklist

- [ ] VPC created with CIDR 10.0.0.0/16
- [ ] 2 public subnets + 2 private subnets created
- [ ] Internet Gateway attached to VPC
- [ ] NAT Gateway created and available
- [ ] Public instance has public IP and serves HTTP
- [ ] Private instance has NO public IP
- [ ] Private instance can reach internet through NAT
- [ ] Private instance CANNOT be reached from internet

---

## 🧹 Cleanup (CRITICAL — NAT Gateway is expensive!)

```bash
# Terminate instances
aws ec2 terminate-instances --instance-ids $PUBLIC_INSTANCE $PRIVATE_INSTANCE
aws ec2 wait instance-terminated --instance-ids $PUBLIC_INSTANCE $PRIVATE_INSTANCE

# Delete NAT Gateway
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID
echo "Waiting for NAT Gateway deletion..."
sleep 30  # NAT Gateway takes time to delete

# Release Elastic IP
aws ec2 release-address --allocation-id $EIP_ID

# Delete security groups
aws ec2 delete-security-group --group-id $SG_PUBLIC
aws ec2 delete-security-group --group-id $SG_PRIVATE

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem

# Detach and delete IGW
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete route tables (main RT can't be deleted, but custom ones can)
# First, disassociate subnets from custom RTs (they'll use main RT)
# Then delete custom route tables
aws ec2 delete-route-table --route-table-id $PUBLIC_RT
aws ec2 delete-route-table --route-table-id $PRIVATE_RT

# Delete subnets
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_1
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_2
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_1
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_2

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "✅ Lab 3 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `DependencyViolation` when deleting VPC | Something is still attached (subnet, IGW, NAT GW). Delete in order: instances → NAT → IGW → subnets → VPC |
| NAT Gateway stuck in `pending` | Wait longer. It takes 2–3 minutes. Use `aws ec2 wait nat-gateway-available` |
| Can't SSH to private instance | Private instances have no public IP. You MUST SSH through the public instance (bastion host pattern) |
| Private instance can't reach internet | Check that the private route table has a route to the NAT Gateway, not the IGW |

---

## 🎯 Stretch Goals

1. **Add a Bastion Host** — The public server is now your "jump box." Document the SSH proxy command:
   ```bash
   ssh -J ec2-user@$PUBLIC_IP ec2-user@$PRIVATE_IP
   ```
2. **Create a VPC Flow Log** — See what traffic is moving through your network:
   ```bash
   aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC_ID --traffic-type ALL --log-destination-type cloud-watch-logs --log-group-name vpc-flow-logs
   ```
3. **Use VPC Peering** — Connect this VPC to another VPC

---

**Next → [Lab 4: IAM & Security Groups](../lab-04-iam-security/)**
