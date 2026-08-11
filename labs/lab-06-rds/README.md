# Lab 6: RDS — Managed Databases

> **The Robot Librarian** — You say "I need MySQL." AWS handles patches, backups, and 2 AM crashes.

---

## 🎯 Objective

- Launch an RDS MySQL instance
- Connect to it from an EC2 instance
- Create a database and table
- Understand Multi-AZ and Read Replicas

**The Analogy:** Instead of hiring a human librarian to manage your filing cabinets (install patches, make backups at 2 AM, fix crashes when they happen), AWS gives you a robot librarian. You just say "I need MySQL" and the robot handles everything — including making a copy of all files in a second building (Multi-AZ) in case the first one burns down.

---

## 💰 Cost Warning

- **db.t3.micro** is Free Tier eligible (750 hours/month for 12 months)
- This lab takes ~25 minutes = **$0.00**
- **Delete the DB instance when done!**

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export DB_NAME="${MY_NAME}lab6db"
export DB_USER="admin"
export DB_PASS="MySecurePass123!"
export KEY_NAME="${MY_NAME}-lab6-key"
```

> Use a real password. RDS won't accept weak passwords.

---

## 🔧 Step-by-Step

### Step 1: Create a DB Subnet Group

RDS needs to know which subnets to use. We'll use the default VPC's subnets for simplicity.

```bash
# Get default VPC
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"     --query 'Vpcs[0].VpcId' --output text)

# Get 2 subnets from the default VPC
export SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"     --query 'Subnets[0:2].SubnetId' --output text)

# Create DB Subnet Group
cat > db-subnet-group.json << EOF
{
    "DBSubnetGroupName": "${MY_NAME}-lab6-subnet-group",
    "DBSubnetGroupDescription": "Lab 6 DB subnet group",
    "SubnetIds": ["$(echo $SUBNETS | awk '{print $1}')", "$(echo $SUBNETS | awk '{print $2}')"]
}
EOF

aws rds create-db-subnet-group --cli-input-json file://db-subnet-group.json
echo "✅ DB Subnet Group created"
```

**Expected Output:**
```
✅ DB Subnet Group created
```

---

### Step 2: Create a Security Group for RDS

```bash
export DB_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab6-db-sg"     --description "RDS MySQL security group"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

# We'll add the EC2 security group as a source later
echo "DB Security Group: $DB_SG"
```

**Expected Output:**
```
DB Security Group: sg-0123456789abcdef0
```

---

### Step 3: Launch the RDS Instance

```bash
echo "Creating RDS instance (this takes 5-10 minutes)..."

aws rds create-db-instance     --db-instance-identifier $DB_NAME     --db-instance-class db.t3.micro     --engine mysql     --master-username $DB_USER     --master-user-password $DB_PASS     --allocated-storage 20     --storage-type gp2     --db-subnet-group-name "${MY_NAME}-lab6-subnet-group"     --vpc-security-group-ids $DB_SG     --publicly-accessible     --backup-retention-period 7     --tags Key=Name,Value=$DB_NAME

echo "Waiting for DB to be available (grab coffee ☕)..."
aws rds wait db-instance-available --db-instance-identifier $DB_NAME

echo "✅ RDS is ready!"
```

**Expected Output:**
```
Creating RDS instance (this takes 5-10 minutes)...
Waiting for DB to be available (grab coffee ☕)...
✅ RDS is ready!
```

---

### Step 4: Get the Database Endpoint

```bash
export DB_ENDPOINT=$(aws rds describe-db-instances     --db-instance-identifier $DB_NAME     --query 'DBInstances[0].Endpoint.Address' --output text)

echo "Database Endpoint: $DB_ENDPOINT"
```

**Expected Output:**
```
Database Endpoint: nkechilab6db.abc123xyz.us-east-1.rds.amazonaws.com
```

---

### Step 5: Launch an EC2 Instance to Connect

```bash
# Create key pair
aws ec2 create-key-pair --key-name $KEY_NAME     --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem

# Create EC2 security group
export EC2_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab6-ec2-sg"     --description "Lab 6 EC2 SG"     --vpc-id $VPC_ID     --query 'GroupId' --output text)

export MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $EC2_SG     --protocol tcp --port 22 --cidr ${MY_IP}/32

# Allow EC2 to talk to RDS
aws ec2 authorize-security-group-ingress --group-id $DB_SG     --protocol tcp --port 3306 --source-group $EC2_SG

# Get AMI and launch
export AMI_ID=$(aws ec2 describe-images --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

export INSTANCE_ID=$(aws ec2 run-instances     --image-id $AMI_ID --instance-type t2.micro     --key-name $KEY_NAME --security-group-ids $EC2_SG     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-lab6-client}]"     --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids $INSTANCE_ID
export PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "EC2 Client: $PUBLIC_IP"
```

**Expected Output:**
```
EC2 Client: 54.123.45.67
```

---

### Step 6: Install MySQL Client and Connect

```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP << 'REMOTESSH'
    # Install MySQL client
    sudo dnf update -y
    sudo dnf install -y mariadb105

    echo "=== MySQL client installed ==="
    mysql --version
REMOTESSH
```

**Expected Output:**
```
=== MySQL client installed ===
mysql  Ver 15.1 Distrib 10.5.22-MariaDB, for Linux (x86_64)
```

---

### Step 7: Create a Database and Table

```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP << REMOTESSH
    # Connect to RDS (replace with your actual endpoint)
    mysql -h $DB_ENDPOINT -u $DB_USER -p'$DB_PASS' << 'MYSQLCMD'
        CREATE DATABASE IF NOT EXISTS devops_students;
        USE devops_students;

        CREATE TABLE IF NOT EXISTS students (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100),
            email VARCHAR(100),
            course VARCHAR(50),
            enrolled_date DATE
        );

        INSERT INTO students (name, email, course, enrolled_date) VALUES
            ('Nkechi Ahanonye', 'nkechi@example.com', 'AWS Blueprint', '2024-08-11'),
            ('Adaobi Nwosu', 'adaobi@example.com', 'DevOps Fundamentals', '2024-08-10'),
            ('Chinedu Okafor', 'chinedu@example.com', 'Kubernetes Mastery', '2024-08-09');

        SELECT * FROM students;
MYSQLCMD
REMOTESSH
```

**Expected Output:**
```
id  name                email                course              enrolled_date
1   Nkechi Ahanonye     nkechi@example.com   AWS Blueprint       2024-08-11
2   Adaobi Nwosu        adaobi@example.com   DevOps Fundamentals 2024-08-10
3   Chinedu Okafor      chinedu@example.com  Kubernetes Mastery  2024-08-09
```

> 🎉 You just created a managed database, connected to it, and stored real data!

---

### Step 8: Check Automated Backups

```bash
aws rds describe-db-snapshots     --db-instance-identifier $DB_NAME     --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,Status]'     --output table
```

**Expected Output:**
```
----------------------------------
|       DescribeDBSnapshots      |
+----------+---------------------+
|  rds:... |  2024-08-11...      |
|  available|                     |
+----------+---------------------+
```

> AWS automatically created a snapshot when the DB was created. With `backup-retention-period=7`, it keeps 7 days of backups automatically.

---

### Step 9: Check CloudWatch Metrics

```bash
aws cloudwatch get-metric-statistics     --namespace AWS/RDS     --metric-name CPUUtilization     --dimensions Name=DBInstanceIdentifier,Value=$DB_NAME     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)     --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)     --period 3600     --statistics Average     --query 'Datapoints[*].[Average,Timestamp]' --output table
```

**Expected Output:**
```
----------------------------------
|    GetMetricStatistics         |
+----------+---------------------+
|  2.5     |  2024-08-11...      |
+----------+---------------------+
```

---

## 🧠 What Just Happened?

| Concept | The Analogy | What You Saw |
|---------|-------------|--------------|
| **RDS** | Robot librarian | Created MySQL without installing anything |
| **DB Subnet Group** | "Which buildings can host the library?" | Specified 2 subnets across AZs |
| **Security Group** | "Only staff can enter the library" | EC2 SG allowed to reach port 3306 |
| **Endpoint** | The library's address | `xxx.rds.amazonaws.com` |
| **Automated Backups** | Daily photocopies of all files | 7-day retention, snapshot created |
| **CloudWatch Metrics** | Health monitor for the robot | CPU usage tracked automatically |
| **Multi-AZ** | Second library building | RDS can be configured with standby |

---

## ✅ Verification Checklist

- [ ] RDS instance shows as `available`
- [ ] Can connect from EC2 using MySQL client
- [ ] Database `devops_students` created
- [ ] Table `students` created with 3 rows
- [ ] Automated snapshot exists
- [ ] CloudWatch shows CPU metrics

---

## 🧹 Cleanup

```bash
# Delete RDS instance (this takes ~5 minutes)
echo "Deleting RDS instance (takes ~5 min)..."
aws rds delete-db-instance     --db-instance-identifier $DB_NAME     --skip-final-snapshot     --delete-automated-backups

aws rds wait db-instance-deleted --db-instance-identifier $DB_NAME

# Terminate EC2
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# Delete security groups
aws ec2 delete-security-group --group-id $EC2_SG
aws ec2 delete-security-group --group-id $DB_SG

# Delete DB subnet group
aws rds delete-db-subnet-group --db-subnet-group-name "${MY_NAME}-lab6-subnet-group"

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem db-subnet-group.json

echo "✅ Lab 6 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `InvalidParameterValue: Password` | Password too weak. Use at least 8 chars with uppercase, lowercase, number, and symbol |
| `DBInstanceAlreadyExists` | Delete the old one first or use a different identifier |
| `Can't connect to MySQL` | Check SG rules. EC2 SG must be allowed as SOURCE on the DB SG |
| `Access denied` | Wrong username/password. Check `$DB_USER` and `$DB_PASS` |
| RDS creation takes forever | Normal. First creation takes 5–10 minutes. Use `aws rds wait` |

---

## 🎯 Stretch Goals

1. **Create a Read Replica** — A copy of the database for read-heavy workloads:
   ```bash
   aws rds create-db-instance-read-replica        --db-instance-identifier "${DB_NAME}-replica"        --source-db-instance-identifier $DB_NAME
   ```
2. **Enable Multi-AZ** — High availability with automatic failover:
   ```bash
   aws rds modify-db-instance --db-instance-identifier $DB_NAME --multi-az --apply-immediately
   ```
3. **Create a manual snapshot** before deleting:
   ```bash
   aws rds create-db-snapshot --db-instance-identifier $DB_NAME --db-snapshot-identifier "${DB_NAME}-manual-backup"
   ```

---

**Next → [Lab 7: ALB & Auto Scaling](../lab-07-alb-autoscaling/)**
