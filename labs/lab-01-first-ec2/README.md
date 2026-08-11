# Lab 1: Your First EC2 Instance

> **Renting Your First Computer** — In 5 minutes, you'll have a live web server running on AWS.

---

## 🎯 Objective

Launch an EC2 instance, SSH into it, install a web server, and see your website live on the internet.

**The Analogy:** You walk into a computer rental shop, pick a machine, turn it on, and within minutes it's serving customers. That's EC2.

---

## 💰 Cost Warning

- **t2.micro** is Free Tier eligible (750 hours/month for 12 months)
- This lab takes ~15 minutes = **$0.00**
- **Remember to terminate the instance when done!**

---

## 📋 One-Liner Setup

Run these once at the start. Change `MY_NAME` to your name:

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export KEY_NAME="${MY_NAME}-lab1-key"
export INSTANCE_NAME="${MY_NAME}-first-server"
```

---

## 🔧 Step-by-Step

### Step 1: Create an SSH Key Pair

This is like making a unique key for your rental computer. Without it, you can't open the door.

```bash
aws ec2 create-key-pair     --key-name $KEY_NAME     --query 'KeyMaterial'     --output text > ${KEY_NAME}.pem

chmod 400 ${KEY_NAME}.pem
```

**Expected Output:**
```
(nothing printed to terminal, but the file is created)
```

Verify the key file exists:
```bash
ls -la ${KEY_NAME}.pem
```

**Expected Output:**
```
-r-------- 1 user user 1678 Aug 11 10:00 nkechi-lab1-key.pem
```

---

### Step 2: Get the Amazon Linux 2023 AMI ID

```bash
export AMI_ID=$(aws ec2 describe-images     --owners amazon     --filters "Name=name,Values=al2023-ami-*-x86_64"     --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId'     --output text)

echo "AMI ID: $AMI_ID"
```

**Expected Output:**
```
AMI ID: ami-0abcdef1234567890
```

---

### Step 3: Create a Security Group (The Bouncer)

This defines who can talk to your server. We allow SSH (port 22) and HTTP (port 80).

```bash
export SG_ID=$(aws ec2 create-security-group     --group-name "${MY_NAME}-lab1-sg"     --description "Lab 1 security group"     --query 'GroupId'     --output text)

echo "Security Group ID: $SG_ID"
```

**Expected Output:**
```
Security Group ID: sg-0123456789abcdef0
```

Now add the rules:

```bash
# Allow SSH from your IP only (secure!)
export MY_IP=$(curl -s https://checkip.amazonaws.com)

aws ec2 authorize-security-group-ingress     --group-id $SG_ID     --protocol tcp     --port 22     --cidr ${MY_IP}/32

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress     --group-id $SG_ID     --protocol tcp     --port 80     --cidr 0.0.0.0/0

echo "Rules added. Your IP: $MY_IP"
```

**Expected Output:**
```
Rules added. Your IP: 102.89.x.x
```

---

### Step 4: Launch Your EC2 Instance

```bash
export INSTANCE_ID=$(aws ec2 run-instances     --image-id $AMI_ID     --instance-type t2.micro     --key-name $KEY_NAME     --security-group-ids $SG_ID     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]"     --query 'Instances[0].InstanceId'     --output text)

echo "Instance ID: $INSTANCE_ID"
```

**Expected Output:**
```
Instance ID: i-0123456789abcdef0
```

---

### Step 5: Wait for It to Be Ready

```bash
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

echo "Waiting for status checks to pass..."
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

echo "✅ Instance is ready!"
```

**Expected Output:**
```
Waiting for instance to be running...
Waiting for status checks to pass...
✅ Instance is ready!
```

---

### Step 6: Get the Public IP

```bash
export PUBLIC_IP=$(aws ec2 describe-instances     --instance-ids $INSTANCE_ID     --query 'Reservations[0].Instances[0].PublicIpAddress'     --output text)

echo "Your server is at: http://$PUBLIC_IP"
```

**Expected Output:**
```
Your server is at: http://54.123.45.67
```

---

### Step 7: SSH Into Your Server

```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP
```

**Expected Output (first time):**
```
The authenticity of host '54.123.45.67' can't be established.
Are you sure you want to continue connecting? (yes/no/[fingerprint]) yes

   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_ #####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
Last login: ...
[ec2-user@ip-172-31-xx-xx ~]$
```

You're now INSIDE your AWS server! 🎉

---

### Step 8: Install a Web Server

Still inside the SSH session, run:

```bash
sudo dnf update -y
sudo dnf install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Expected Output:**
```
Complete!
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
```

---

### Step 9: Create a Custom Homepage

```bash
echo "<h1>🎉 Hello from AWS! This is $(hostname -f)</h1>
<p>Served by Nginx on Amazon Linux 2023</p>
<p>Built by: $MY_NAME</p>" | sudo tee /usr/share/nginx/html/index.html
```

**Expected Output:**
```
<h1>🎉 Hello from AWS! This is ip-172-31-xx-xx.ec2.internal</h1>
<p>Served by Nginx on Amazon Linux 2023</p>
<p>Built by: nkechi</p>
```

Exit the SSH session:
```bash
exit
```

---

### Step 10: Visit Your Live Website

Open your browser and go to:
```
http://<YOUR_PUBLIC_IP>
```

Or from your terminal:
```bash
curl http://$PUBLIC_IP
```

**Expected Output:**
```html
<h1>🎉 Hello from AWS! This is ip-172-31-xx-xx.ec2.internal</h1>
<p>Served by Nginx on Amazon Linux 2023</p>
<p>Built by: nkechi</p>
```

**🎉 YOU HAVE A LIVE WEBSITE ON THE INTERNET!**

---

## 🧠 What Just Happened?

| What You Did | The Analogy | AWS Service |
|-------------|-------------|-------------|
| Created a key pair | Made a unique key for your rental computer | EC2 Key Pair |
| Created a security group | Hired a bouncer who only lets in certain people | Security Group |
| Launched t2.micro | Rented a small computer by the hour | EC2 Instance |
| SSH'd in | Walked into the shop and sat at the computer | SSH Protocol |
| Installed Nginx | Set up a signboard that shows your message | Web Server |
| Opened port 80 | Told the bouncer to let web visitors in | Security Group Rule |

---

## ✅ Verification Checklist

- [ ] `aws ec2 describe-instances` shows your instance as `running`
- [ ] You can SSH into the server
- [ ] `curl http://$PUBLIC_IP` returns your custom HTML
- [ ] You can see the page in your browser

---

## 🧹 Cleanup (DO THIS NOW)

```bash
# Terminate the instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Wait for it to terminate
echo "Waiting for termination..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# Delete the security group
aws ec2 delete-security-group --group-id $SG_ID

# Delete the key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem

echo "✅ Lab 1 cleaned up!"
```

**Expected Output:**
```
Waiting for termination...
✅ Lab 1 cleaned up!
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Permission denied (publickey)` | Your `.pem` file permissions are wrong. Run `chmod 400` on it |
| `Connection timed out` | Security group doesn't allow SSH from your IP. Check Step 3 |
| `No route to host` | Instance isn't running yet. Wait for `instance-status-ok` |
| `nginx: command not found` | Use `sudo dnf install nginx` (Amazon Linux 2023), not `yum` or `apt` |
| Browser shows nothing | Make sure you used `http://` not `https://` |

---

## 🎯 Stretch Goals

1. **Change the instance type** to `t3.micro` and see if it still works
2. **Add a tag** `Environment=Lab` and filter instances by it:
   ```bash
   aws ec2 describe-instances --filters "Name=tag:Environment,Values=Lab"
   ```
3. **Check the console log** (useful for debugging boot issues):
   ```bash
   aws ec2 get-console-output --instance-id $INSTANCE_ID
   ```

---

**Next → [Lab 2: Regions & Availability Zones](../lab-02-regions-azs/)**
