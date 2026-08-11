# Lab 4: IAM & Security Groups

> **Bouncers & ID Cards** — Control who can enter your estate and what they're allowed to do.

---

## 🎯 Objective

- Create IAM users with different permission levels
- Create IAM roles for EC2 instances
- Build Security Groups with precise rules
- Test access control in action

**The Analogy:** 
- **IAM Users** = Named employees with ID cards. The cleaner can't open the manager's office.
- **IAM Roles** = Temporary badges. A delivery driver gets a "Delivery" badge that expires after the job.
- **Security Groups** = The bouncer at each door. "Port 80? Everyone. Port 22? Only the boss's office IP."

---

## 💰 Cost Warning

- IAM is **100% free**
- This lab creates no billable resources
- **Cost: $0.00**

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
```

---

## 🔧 Step-by-Step

### Part A: IAM Users (Named Employees)

#### Step 1: Create an Admin User

```bash
# Create the user
aws iam create-user --user-name "${MY_NAME}-admin"

# Attach admin policy
aws iam attach-user-policy     --user-name "${MY_NAME}-admin"     --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access keys
aws iam create-access-key --user-name "${MY_NAME}-admin"     --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output table
```

**Expected Output:**
```
-------------------------
|     CreateAccessKey   |
+-----------------------+
|  AKIA...              |
|  wJalrXUtnFEMI...     |
+-----------------------+
```

---

#### Step 2: Create a Read-Only User

```bash
# Create the user
aws iam create-user --user-name "${MY_NAME}-readonly"

# Attach read-only policy
aws iam attach-user-policy     --user-name "${MY_NAME}-readonly"     --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Create access keys
aws iam create-access-key --user-name "${MY_NAME}-readonly"     --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output table
```

**Expected Output:**
```
-------------------------
|     CreateAccessKey   |
+-----------------------+
|  AKIA...              |
|  wJalrXUtnFEMI...     |
+-----------------------+
```

---

#### Step 3: Test the Read-Only User

```bash
# Save the readonly keys (replace with actual values from Step 2)
export READONLY_KEY="AKIAxxxxxxxxxxxxxxxx"
export READONLY_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Configure a temporary profile
aws configure set aws_access_key_id $READONLY_KEY --profile readonly
aws configure set aws_secret_access_key $READONLY_SECRET --profile readonly
aws configure set region $AWS_REGION --profile readonly

# Test: Can they READ?
aws ec2 describe-instances --profile readonly --query 'Reservations[*].Instances[*].InstanceId' --output table

# Test: Can they CREATE? (Should FAIL)
aws ec2 create-security-group --profile readonly     --group-name "${MY_NAME}-test-sg"     --description "Test"     --vpc-id vpc-12345678 2>&1
```

**Expected Output (Read works, Create fails):**
```
# describe-instances works:
-------------
|DescribeIn|
+-----------+
|  i-abc... |
+-----------+

# create-security-group fails:
An error occurred (AccessDenied) when calling the CreateSecurityGroup operation: ...
```

> The read-only user can SEE everything but can't CHANGE anything. Perfect for auditors or junior staff.

---

#### Step 4: Create a Custom Policy (S3 Only)

```bash
# Create a custom policy
cat > s3-only-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${MY_NAME}-lab4-bucket/*"
        }
    ]
}
EOF

# Create the policy
export POLICY_ARN=$(aws iam create-policy     --policy-name "${MY_NAME}-S3OnlyPolicy"     --policy-document file://s3-only-policy.json     --query 'Policy.Arn' --output text)

echo "Policy ARN: $POLICY_ARN"
```

**Expected Output:**
```
Policy ARN: arn:aws:iam::123456789012:policy/nkechi-S3OnlyPolicy
```

---

### Part B: IAM Roles (Temporary Badges)

#### Step 5: Create an EC2 Role That Can Read S3

```bash
# Trust policy — who can assume this role?
cat > ec2-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Create the role
export EC2_ROLE=$(aws iam create-role     --role-name "${MY_NAME}-ec2-s3-reader"     --assume-role-policy-document file://ec2-trust-policy.json     --query 'Role.Arn' --output text)

# Attach S3 read policy
aws iam attach-role-policy     --role-name "${MY_NAME}-ec2-s3-reader"     --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create instance profile (required to attach role to EC2)
aws iam create-instance-profile --instance-profile-name "${MY_NAME}-ec2-profile"
aws iam add-role-to-instance-profile     --instance-profile-name "${MY_NAME}-ec2-profile"     --role-name "${MY_NAME}-ec2-s3-reader"

echo "Role ARN: $EC2_ROLE"
```

**Expected Output:**
```
Role ARN: arn:aws:iam::123456789012:role/nkechi-ec2-s3-reader
```

---

#### Step 6: Test the Role on a Real EC2 Instance

```bash
export KEY_NAME="${MY_NAME}-lab4-key"
aws ec2 create-key-pair --key-name $KEY_NAME     --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem

export AMI_ID=$(aws ec2 describe-images --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

export SG_ID=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab4-sg"     --description "Lab 4 SG"     --query 'GroupId' --output text)

export MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress --group-id $SG_ID     --protocol tcp --port 22 --cidr ${MY_IP}/32

# Launch EC2 WITH the instance profile (the temporary badge!)
export INSTANCE_ID=$(aws ec2 run-instances     --image-id $AMI_ID --instance-type t2.micro     --key-name $KEY_NAME --security-group-ids $SG_ID     --iam-instance-profile Name="${MY_NAME}-ec2-profile"     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${MY_NAME}-lab4-role-test}]"     --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids $INSTANCE_ID
export PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance with Role: $PUBLIC_IP"
```

**Expected Output:**
```
Instance with Role: 54.123.45.67
```

---

#### Step 7: Verify the Role Works

SSH in and test S3 access WITHOUT any credentials:

```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP << 'REMOTESSH'
    echo "=== Who am I? ==="
    aws sts get-caller-identity

    echo ""
    echo "=== Can I list S3 buckets? ==="
    aws s3 ls

    echo ""
    echo "=== Can I create a bucket? (Should FAIL) ==="
    aws s3 mb s3://test-bucket-$(date +%s) 2>&1
REMOTESSH
```

**Expected Output:**
```
=== Who am I? ===
{
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/nkechi-ec2-s3-reader/i-0123456789abcdef0"
}

=== Can I list S3 buckets? ===
2025-01-15 10:00:00 my-bucket

=== Can I create a bucket? (Should FAIL) ===
make_bucket failed: s3://test-bucket-... An error occurred (AccessDenied)...
```

> The EC2 instance has NO hardcoded credentials. It uses the IAM Role (temporary badge) to get short-lived credentials automatically. It can READ S3 but can't CREATE buckets.

---

### Part C: Security Groups (The Bouncer)

#### Step 8: Build a Multi-Layer Security Group

```bash
# Web Tier SG: Allow HTTP/HTTPS from internet, SSH only from VPC
export WEB_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-web-tier-sg"     --description "Web tier security group"     --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $WEB_SG     --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG     --protocol tcp --port 443 --cidr 0.0.0.0/0

# App Tier SG: Only accept traffic from Web Tier
export APP_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-app-tier-sg"     --description "App tier security group"     --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $APP_SG     --protocol tcp --port 8080 --source-group $WEB_SG

# DB Tier SG: Only accept traffic from App Tier
export DB_SG=$(aws ec2 create-security-group     --group-name "${MY_NAME}-db-tier-sg"     --description "DB tier security group"     --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $DB_SG     --protocol tcp --port 3306 --source-group $APP_SG

# Show the rules
echo "=== Web Tier Rules ==="
aws ec2 describe-security-groups --group-ids $WEB_SG --query 'SecurityGroups[0].IpPermissions' --output table

echo ""
echo "=== App Tier Rules ==="
aws ec2 describe-security-groups --group-ids $APP_SG --query 'SecurityGroups[0].IpPermissions' --output table

echo ""
echo "=== DB Tier Rules ==="
aws ec2 describe-security-groups --group-ids $DB_SG --query 'SecurityGroups[0].IpPermissions' --output table
```

**Expected Output:**
```
=== Web Tier Rules ===
----------------------------------
|         IpPermissions          |
+----------+----------+----------+
|  FromPort|  ToPort  | IpRanges |
+----------+----------+----------+
|  80      |  80      |  0.0.0.0/0|
|  443     |  443     |  0.0.0.0/0|
+----------+----------+----------+

=== App Tier Rules ===
----------------------------------
|         IpPermissions          |
+----------+----------+----------+
|  FromPort|  ToPort  |UserIdGroup|
|  8080    |  8080    | sg-xxx... |
+----------+----------+----------+

=== DB Tier Rules ===
----------------------------------
|         IpPermissions          |
+----------+----------+----------+
|  FromPort|  ToPort  |UserIdGroup|
|  3306    |  3306    | sg-yyy... |
+----------+----------+----------+
```

> Notice: The DB tier only allows MySQL (port 3306) from the App tier. Even if a hacker gets into the web server, they can't touch the database directly.

---

## 🧠 What Just Happened?

| Concept | The Analogy | What You Built |
|---------|-------------|----------------|
| **IAM User** | Named employee with a permanent ID card | `nkechi-admin`, `nkechi-readonly` |
| **IAM Policy** | Job description (what they're allowed to do) | Admin = everything, ReadOnly = view only, S3Only = S3 only |
| **IAM Role** | Temporary badge for a specific task | EC2 can read S3 without storing credentials |
| **Instance Profile** | The lanyard that holds the badge | Attaches the role to the EC2 instance |
| **Security Group** | Bouncer at the door | Web = public, App = web-only, DB = app-only |
| **Source Group** | "Only let in people from the VIP room" | App tier only accepts from Web tier SG |

---

## ✅ Verification Checklist

- [ ] Admin user can create resources
- [ ] Read-only user can view but NOT create
- [ ] S3-only policy is attached and scoped to one bucket
- [ ] EC2 with role can list S3 buckets without credentials
- [ ] EC2 with role CANNOT create S3 buckets
- [ ] 3-tier security groups exist with proper rules
- [ ] DB tier only accepts from App tier (not from internet)

---

## 🧹 Cleanup

```bash
# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# Delete security groups
aws ec2 delete-security-group --group-id $SG_ID
aws ec2 delete-security-group --group-id $WEB_SG
aws ec2 delete-security-group --group-id $APP_SG
aws ec2 delete-security-group --group-id $DB_SG

# Delete key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem

# Remove role from instance profile
aws iam remove-role-from-instance-profile --instance-profile-name "${MY_NAME}-ec2-profile" --role-name "${MY_NAME}-ec2-s3-reader"
aws iam delete-instance-profile --instance-profile-name "${MY_NAME}-ec2-profile"

# Detach and delete role policies
aws iam detach-role-policy --role-name "${MY_NAME}-ec2-s3-reader" --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam delete-role --role-name "${MY_NAME}-ec2-s3-reader"

# Detach and delete user policies
aws iam detach-user-policy --user-name "${MY_NAME}-admin" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam detach-user-policy --user-name "${MY_NAME}-readonly" --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Delete access keys
for user in "${MY_NAME}-admin" "${MY_NAME}-readonly"; do
    keys=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].AccessKeyId' --output text)
    for key in $keys; do
        aws iam delete-access-key --user-name $user --access-key-id $key
    done
done

# Delete users
aws iam delete-user --user-name "${MY_NAME}-admin"
aws iam delete-user --user-name "${MY_NAME}-readonly"

# Delete custom policy
aws iam delete-policy --policy-arn $POLICY_ARN

# Clean up files
rm -f s3-only-policy.json ec2-trust-policy.json

echo "✅ Lab 4 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `DeleteConflict` when deleting user | Delete access keys first, then detach policies, THEN delete user |
| `DependencyViolation` on SG | Security groups can't be deleted if attached to instances. Terminate instances first |
| Role not working on EC2 | Make sure you used `--iam-instance-profile` not `--iam-role` at launch |
| `AccessDenied` with role | The role's trust policy must allow `ec2.amazonaws.com` to assume it |

---

## 🎯 Stretch Goals

1. **Create an IAM Group** — Add users to groups instead of attaching policies directly:
   ```bash
   aws iam create-group --group-name DevOps-Team
   aws iam attach-group-policy --group-name DevOps-Team --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   aws iam add-user-to-group --group-name DevOps-Team --user-name "${MY_NAME}-admin"
   ```
2. **Enable MFA** — Require multi-factor authentication for the admin user
3. **Use AWS IAM Policy Simulator** — Test policies before attaching them: [Policy Simulator](https://policysim.aws.amazon.com/)

---

**Next → [Lab 5: S3 Storage](../lab-05-s3/)**
