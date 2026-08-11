# Lab 9: CloudWatch — Monitoring & Alerts

> **The CCTV & Alarm System** — Cameras in every room. If the kitchen gets too hot (CPU > 80%), the alarm rings and you get a text.

---

## 🎯 Objective

- Create a CloudWatch Dashboard
- Set up a CPU alarm that sends email via SNS
- Install the CloudWatch Agent and stream logs
- View custom metrics

**The Analogy:** You have CCTV cameras watching every room of your cybercafé. If the kitchen gets too hot (CPU > 80%), the alarm rings. If the queue gets too long (requests piling up), you get a text message. You can also replay the security footage (logs) to see exactly what happened.

---

## 💰 Cost Warning

- CloudWatch Dashboards: **$3.00/month per dashboard**
- CloudWatch Alarms: **$0.10/month per alarm**
- SNS Email notifications: **$2.00 per 100,000 emails**
- This lab takes ~20 minutes = **$0.00**
- **Delete the dashboard and alarm when done!**

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"  # From Lab 1 or 7
export KEY_NAME="${MY_NAME}-lab9-key"
export ALARM_EMAIL="your-email@example.com"  # CHANGE THIS
```

---

## 🔧 Step-by-Step

### Step 1: Create a CloudWatch Dashboard

```bash
aws cloudwatch put-dashboard     --dashboard-name "${MY_NAME}-lab9-dashboard"     --dashboard-body '{
        "widgets": [
            {
                "type": "metric",
                "x": 0, "y": 0, "width": 12, "height": 6,
                "properties": {
                    "metrics": [["AWS/EC2", "CPUUtilization", "InstanceId", "'$INSTANCE_ID'"]],
                    "period": 300,
                    "stat": "Average",
                    "region": "'$AWS_REGION'",
                    "title": "CPU Utilization",
                    "yAxis": {"left": {"min": 0, "max": 100}}
                }
            },
            {
                "type": "metric",
                "x": 12, "y": 0, "width": 12, "height": 6,
                "properties": {
                    "metrics": [["AWS/EC2", "NetworkIn", "InstanceId", "'$INSTANCE_ID'"]],
                    "period": 300,
                    "stat": "Average",
                    "region": "'$AWS_REGION'",
                    "title": "Network Traffic (Bytes In)"
                }
            },
            {
                "type": "metric",
                "x": 0, "y": 6, "width": 12, "height": 6,
                "properties": {
                    "metrics": [["AWS/EC2", "StatusCheckFailed", "InstanceId", "'$INSTANCE_ID'"]],
                    "period": 300,
                    "stat": "Sum",
                    "region": "'$AWS_REGION'",
                    "title": "Status Check Failures"
                }
            },
            {
                "type": "metric",
                "x": 12, "y": 6, "width": 12, "height": 6,
                "properties": {
                    "metrics": [["AWS/EC2", "DiskReadOps", "InstanceId", "'$INSTANCE_ID'"]],
                    "period": 300,
                    "stat": "Average",
                    "region": "'$AWS_REGION'",
                    "title": "Disk Read Operations"
                }
            }
        ]
    }'

echo "✅ Dashboard created: ${MY_NAME}-lab9-dashboard"
```

**Expected Output:**
```json
{"DashboardValidationMessages": []}
```

> View your dashboard at: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${MY_NAME}-lab9-dashboard

---

### Step 2: Create an SNS Topic for Alerts

```bash
export SNS_TOPIC=$(aws sns create-topic     --name "${MY_NAME}-lab9-alerts"     --query 'TopicArn' --output text)

echo "SNS Topic: $SNS_TOPIC"
```

**Expected Output:**
```
SNS Topic: arn:aws:sns:us-east-1:123456789012:nkechi-lab9-alerts
```

---

### Step 3: Subscribe Your Email

```bash
aws sns subscribe     --topic-arn $SNS_TOPIC     --protocol email     --notification-endpoint $ALARM_EMAIL

echo "📧 Check your email ($ALARM_EMAIL) and click 'Confirm subscription'"
```

**Expected Output:**
```json
{
    "SubscriptionArn": "pending confirmation"
}
```

> ⚠️ **You MUST check your email and click the confirmation link.** The alarm won't work until you do.

---

### Step 4: Create a CPU Alarm

```bash
aws cloudwatch put-metric-alarm     --alarm-name "${MY_NAME}-high-cpu"     --alarm-description "CPU > 70% for 2 consecutive minutes"     --metric-name CPUUtilization     --namespace AWS/EC2     --statistic Average     --period 120     --evaluation-periods 2     --threshold 70     --comparison-operator GreaterThanThreshold     --dimensions Name=InstanceId,Value=$INSTANCE_ID     --alarm-actions $SNS_TOPIC     --ok-actions $SNS_TOPIC     --tags Key=Name,Value="${MY_NAME}-high-cpu"

echo "✅ Alarm created: ${MY_NAME}-high-cpu"
```

**Expected Output:**
```
✅ Alarm created: nkechi-high-cpu
```

---

### Step 5: Test the Alarm (Create CPU Load)

First, make sure your instance from Lab 1 or 7 is still running. Then SSH in and create load:

```bash
export PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID     --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP << 'REMOTESSH'
    echo "Installing stress tool..."
    sudo dnf install -y stress-ng

    echo "Creating CPU load for 5 minutes..."
    sudo stress-ng --cpu 4 --timeout 300s &

    echo "Load started. PID: $!"
REMOTESSH
```

**Expected Output:**
```
Installing stress tool...
Creating CPU load for 5 minutes...
Load started. PID: 1234
```

---

### Step 6: Watch the Alarm Trigger

In another terminal, monitor the alarm state:

```bash
# Check alarm state every 30 seconds
for i in {1..10}; do
    echo "--- Check $i ---"
    aws cloudwatch describe-alarms --alarm-names "${MY_NAME}-high-cpu"         --query 'MetricAlarms[0].[StateValue,StateReason]' --output table
    sleep 30
done
```

**Expected Output (after 2–4 minutes):**
```
--- Check 1 ---
-------------------------
|  DescribeAlarms       |
+-----------------------+
|  OK                   |
|  Threshold Crossed: 0 |
+-----------------------+

--- Check 5 ---
-------------------------
|  DescribeAlarms       |
+-----------------------+
|  ALARM                |
|  Threshold Crossed: 2 |
+-----------------------+
```

> 📧 **You should receive an email:** "ALARM: nkechi-high-cpu in US East (N. Virginia)"

---

### Step 7: Install CloudWatch Agent for Custom Logs

SSH into your instance and install the agent:

```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP << 'REMOTESSH'
    # Download and install CloudWatch agent
    sudo dnf install -y amazon-cloudwatch-agent

    # Create configuration
    sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
    {
        "logs": {
            "logs_collected": {
                "files": {
                    "collect_list": [
                        {
                            "file_path": "/var/log/nginx/access.log",
                            "log_group_name": "nkechi-nginx-access",
                            "log_stream_name": "{instance_id}",
                            "timezone": "UTC"
                        },
                        {
                            "file_path": "/var/log/messages",
                            "log_group_name": "nkechi-system-messages",
                            "log_stream_name": "{instance_id}",
                            "timezone": "UTC"
                        }
                    ]
                }
            }
        },
        "metrics": {
            "namespace": "nkechi-custom-metrics",
            "metrics_collected": {
                "cpu": {
                    "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                    "metrics_collection_interval": 60
                },
                "disk": {
                    "measurement": ["used_percent"],
                    "metrics_collection_interval": 60,
                    "resources": ["*"]
                },
                "mem": {
                    "measurement": ["mem_used_percent"],
                    "metrics_collection_interval": 60
                }
            }
        }
    }
    EOF

    # Start the agent
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl         -a fetch-config -m ec2 -s         -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    echo "✅ CloudWatch Agent installed and running"
REMOTESSH
```

**Expected Output:**
```
✅ CloudWatch Agent installed and running
```

---

### Step 8: Verify Logs in CloudWatch

```bash
# List log groups
aws logs describe-log-groups     --query 'logGroups[*].logGroupName' --output table
```

**Expected Output:**
```
-------------------------
|  DescribeLogGroups    |
+-----------------------+
|  nkechi-nginx-access  |
|  nkechi-system-mess...|
+-----------------------+
```

```bash
# View recent log events
aws logs describe-log-streams --log-group-name nkechi-nginx-access     --query 'logStreams[0].logStreamName' --output text

export STREAM_NAME=$(aws logs describe-log-streams --log-group-name nkechi-nginx-access     --query 'logStreams[0].logStreamName' --output text)

aws logs get-log-events --log-group-name nkechi-nginx-access     --log-stream-name "$STREAM_NAME"     --limit 5     --query 'events[*].message' --output table
```

**Expected Output:**
```
-------------------------
|     GetLogEvents      |
+-----------------------+
|  192.168.1.1 - - [... |
|  192.168.1.2 - - [... |
+-----------------------+
```

---

### Step 9: View Custom Metrics

```bash
# View custom metrics from CloudWatch Agent
aws cloudwatch list-metrics --namespace "nkechi-custom-metrics"     --query 'Metrics[*].[MetricName,Dimensions[0].Value]' --output table
```

**Expected Output:**
```
-------------------------
|      ListMetrics      |
+-----------------------+
|  cpu_usage_idle       |
|  cpu_usage_user       |
|  cpu_usage_system     |
|  mem_used_percent     |
|  used_percent         |
+-----------------------+
```

---

## 🧠 What Just Happened?

| Component | The Analogy | What You Built |
|-----------|-------------|----------------|
| **Dashboard** | CCTV monitor wall | 4-panel view of CPU, network, health, disk |
| **Alarm** | Temperature alarm | Triggers when CPU > 70% for 2 periods |
| **SNS Topic** | The alarm system | Sends notifications to email |
| **CloudWatch Agent** | Extra sensors | Collects logs and custom metrics |
| **Log Group** | Filing cabinet for footage | Stores nginx and system logs |
| **Custom Metrics** | Specialized gauges | Memory, disk usage beyond default AWS metrics |

---

## ✅ Verification Checklist

- [ ] Dashboard visible in AWS Console with 4 widgets
- [ ] SNS topic created with email subscription (confirmed)
- [ ] CPU alarm created and in `OK` state
- [ ] Under load, alarm transitions to `ALARM`
- [ ] Email received when alarm triggers
- [ ] CloudWatch Agent installed and running
- [ ] Log groups visible (`nkechi-nginx-access`, `nkechi-system-messages`)
- [ ] Custom metrics namespace visible

---

## 🧹 Cleanup

```bash
# Delete alarm
aws cloudwatch delete-alarms --alarm-names "${MY_NAME}-high-cpu"

# Delete dashboard
aws cloudwatch delete-dashboards --dashboard-names "${MY_NAME}-lab9-dashboard"

# Delete SNS topic (also deletes subscriptions)
aws sns delete-topic --topic-arn $SNS_TOPIC

# Delete log groups
aws logs delete-log-group --log-group-name nkechi-nginx-access 2>/dev/null
aws logs delete-log-group --log-group-name nkechi-system-messages 2>/dev/null

# Stop the stress process on the instance
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP "sudo pkill stress-ng" 2>/dev/null

echo "✅ Lab 9 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| No email received | Check spam folder. You MUST click the confirmation link in the SNS email |
| Alarm never triggers | CloudWatch metrics update every 5 minutes. Wait 10 minutes total |
| `InstanceId not found` | Make sure `$INSTANCE_ID` is set to a running instance |
| CloudWatch Agent not starting | Check config JSON syntax. Use `sudo cat` to verify the file |
| No logs appearing | The agent needs a few minutes. Also verify the log file path exists |
| Custom metrics not showing | Namespace is case-sensitive. Check `nkechi-custom-metrics` exactly |

---

## 🎯 Stretch Goals

1. **Create a Composite Alarm** — Trigger only when BOTH CPU > 70% AND StatusCheckFailed > 0:
   ```bash
   aws cloudwatch put-composite-alarm        --alarm-name "${MY_NAME}-critical-failure"        --alarm-rule "ALARM(${MY_NAME}-high-cpu) AND ALARM(${MY_NAME}-status-failed)"        --alarm-actions $SNS_TOPIC
   ```
2. **Add SMS Alerts** — Subscribe a phone number:
   ```bash
   aws sns subscribe --topic-arn $SNS_TOPIC --protocol sms --notification-endpoint "+2348012345678"
   ```
3. **Create a Billing Alarm** — Get alerted before you spend money:
   ```bash
   aws cloudwatch put-metric-alarm --alarm-name "billing-alert"        --metric-name EstimatedCharges --namespace AWS/Billing        --statistic Maximum --period 86400 --threshold 10        --comparison-operator GreaterThanThreshold        --alarm-actions $SNS_TOPIC
   ```

---

## 🏗 Local Sandbox Version

Practice this lab locally with LocalStack:

```bash
# Start sandbox
cd local-sandbox && docker-compose up -d

# All commands are identical, just use awslocal:
awslocal cloudwatch put-dashboard --dashboard-name "${MY_NAME}-lab9-dashboard" --dashboard-body '...'
awslocal sns create-topic --name "${MY_NAME}-lab9-alerts"
awslocal cloudwatch put-metric-alarm --alarm-name "${MY_NAME}-high-cpu" ...
awslocal logs create-log-group --log-group-name nkechi-nginx-access

# Note: Email notifications won't work in LocalStack (no real email), but the alarm state changes will
```

---

**Next → [Lab 10: Capstone — Production 3-Tier Architecture](../lab-10-capstone/)**
