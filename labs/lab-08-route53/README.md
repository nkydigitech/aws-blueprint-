# Lab 8: Route 53 — DNS & Domains

> **The Phonebook** — Nobody memorizes IP addresses. They remember names. Route 53 translates `mycybercafe.com` → `192.168.1.1`.

---

## 🎯 Objective

- Create a hosted zone
- Create DNS records (A, CNAME, Alias)
- Point a domain to your ALB
- Understand health checks and routing policies

**The Analogy:** You have a phonebook. When someone looks up "Nkechi's Cybercafé," the phonebook tells them the address. If you move to a new building, you just update the phonebook — customers still use the same name. Route 53 also checks if your building is open (health checks) and can send Lagos customers to your Lagos branch (geolocation routing).

---

## 💰 Cost Warning

- Route 53 Hosted Zone: **$0.50/month**
- DNS queries: **$0.40 per million queries**
- This lab takes ~20 minutes = **$0.00** (if you delete the hosted zone)
- **You need a registered domain** (~$12/year). If you don't have one, use a subdomain or skip to the simulated section.

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export DOMAIN="example.com"  # CHANGE THIS to your real domain
```

> ⚠️ **If you don't have a domain:** You can still complete 80% of this lab using a simulated approach. See the "No Domain?" section at the end.

---

## 🔧 Step-by-Step

### Step 1: Create a Hosted Zone

A hosted zone is like a page in the phonebook for your domain.

```bash
export ZONE_ID=$(aws route53 create-hosted-zone     --name $DOMAIN     --caller-reference "$(date +%s)"     --query 'HostedZone.Id' --output text)

echo "Hosted Zone ID: $ZONE_ID"
```

**Expected Output:**
```
Hosted Zone ID: /hostedzone/Z1234567890ABC
```

---

### Step 2: Get the Name Servers

AWS gives you 4 name servers. You must update your domain registrar to use these.

```bash
aws route53 get-hosted-zone --id $ZONE_ID     --query 'DelegationSet.NameServers' --output table
```

**Expected Output:**
```
-------------------------
|      GetHostedZone    |
+-----------------------+
|  ns-1234.awsdns-56.org|
|  ns-7890.awsdns-12.com|
|  ns-3456.awsdns-78.net|
|  ns-9012.awsdns-34.co.uk|
+-----------------------+
```

> Go to your domain registrar (GoDaddy, Namecheap, etc.) and update the name servers to these 4 values. This can take 5–60 minutes to propagate.

---

### Step 3: Create an A Record (Point Domain to an IP)

For this demo, we'll create a simple A record. In production, you'd point to your ALB.

```bash
# First, let's get our ALB from Lab 7 (or create a simple target)
# If you don't have an ALB, use a simple EC2 IP:
export TARGET_IP=$(curl -s https://checkip.amazonaws.com)

cat > a-record.json << EOF
{
    "Comment": "A record for $DOMAIN",
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "$DOMAIN",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "$TARGET_IP"}]
        }
    }]
}
EOF

aws route53 change-resource-record-sets     --hosted-zone-id $ZONE_ID     --change-batch file://a-record.json

echo "✅ A record created: $DOMAIN → $TARGET_IP"
```

**Expected Output:**
```
✅ A record created: example.com → 102.89.x.x
```

---

### Step 4: Create a CNAME Record (Subdomain)

```bash
cat > cname-record.json << EOF
{
    "Comment": "CNAME for www",
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "www.$DOMAIN",
            "Type": "CNAME",
            "TTL": 300,
            "ResourceRecords": [{"Value": "$DOMAIN"}]
        }
    }]
}
EOF

aws route53 change-resource-record-sets     --hosted-zone-id $ZONE_ID     --change-batch file://cname-record.json

echo "✅ CNAME created: www.$DOMAIN → $DOMAIN"
```

**Expected Output:**
```
✅ CNAME created: www.example.com → example.com
```

---

### Step 5: Create an Alias Record (Point to ALB)

Alias records are AWS-specific. They point to AWS resources (like ALB) without exposing the underlying DNS name.

```bash
# If you have an ALB from Lab 7, use it. Otherwise, this is the syntax:
export ALB_DNS="nkechi-lab7-alb-123456789.us-east-1.elb.amazonaws.com"
export ALB_HOSTED_ZONE="Z35SXDOTRQ7X7K"  # Hosted zone ID for ALB in us-east-1

cat > alias-record.json << EOF
{
    "Comment": "Alias record for ALB",
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "app.$DOMAIN",
            "Type": "A",
            "AliasTarget": {
                "HostedZoneId": "$ALB_HOSTED_ZONE",
                "DNSName": "$ALB_DNS",
                "EvaluateTargetHealth": true
            }
        }
    }]
}
EOF

aws route53 change-resource-record-sets     --hosted-zone-id $ZONE_ID     --change-batch file://alias-record.json

echo "✅ Alias record created: app.$DOMAIN → $ALB_DNS"
```

**Expected Output:**
```
✅ Alias record created: app.example.com → nkechi-lab7-alb-123456789.us-east-1.elb.amazonaws.com
```

---

### Step 6: List All Records

```bash
aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID     --query 'ResourceRecordSets[*].[Name,Type,ResourceRecords[0].Value || AliasTarget.DNSName]'     --output table
```

**Expected Output:**
```
----------------------------------
|   ListResourceRecordSets       |
+----------+------+--------------+
|  example.|  NS  |  ns-1234...  |
|  com.    |      |              |
|  example.|  SOA |  ns-1234...  |
|  com.    |      |              |
|  example.|  A   |  102.89.x.x  |
|  com.    |      |              |
|  www.exam|  CNAME| example.com |
|  ple.com.|      |              |
|  app.exam|  A   |  nkechi-lab7 |
|  ple.com.|      |  -alb-...    |
+----------+------+--------------+
```

---

### Step 7: Test DNS Resolution

```bash
echo "=== Testing A record ==="
nslookup $DOMAIN

echo ""
echo "=== Testing CNAME ==="
nslookup www.$DOMAIN

echo ""
echo "=== Testing Alias ==="
nslookup app.$DOMAIN
```

**Expected Output:**
```
=== Testing A record ===
Server:  127.0.0.53
Address: 127.0.0.53#53

Non-authoritative answer:
Name: example.com
Address: 102.89.x.x

=== Testing CNAME ===
www.example.com canonical name = example.com.
Name: example.com
Address: 102.89.x.x

=== Testing Alias ===
app.example.com canonical name = nkechi-lab7-alb-123456789.us-east-1.elb.amazonaws.com.
```

---

### Step 8: Create a Health Check

Route 53 can monitor your endpoint and stop sending traffic if it's down.

```bash
export HEALTH_CHECK_ID=$(aws route53 create-health-check     --caller-reference "$(date +%s)"     --health-check-config '{
        "IPAddress": "'$TARGET_IP'",
        "Port": 80,
        "Type": "HTTP",
        "ResourcePath": "/",
        "FullyQualifiedDomainName": "'$DOMAIN'",
        "RequestInterval": 30,
        "FailureThreshold": 3
    }'     --query 'HealthCheck.Id' --output text)

echo "Health Check ID: $HEALTH_CHECK_ID"

# Check health status
aws route53 get-health-check-status --health-check-id $HEALTH_CHECK_ID     --query 'HealthCheckObservations[0].[Status,IPAddress]' --output table
```

**Expected Output:**
```
Health Check ID: 12345678-1234-1234-1234-123456789012

-------------------------
|  GetHealthCheckStatus |
+-----------------------+
|  INSUFFICIENT_DATA    |
|  102.89.x.x           |
+-----------------------+
```

> After a few minutes, status changes to `HEALTHY` or `UNHEALTHY`.

---

## 🧠 What Just Happened?

| Concept | The Analogy | What You Did |
|---------|-------------|--------------|
| **Hosted Zone** | A page in the phonebook | Created one for your domain |
| **A Record** | "The building's street address" | Pointed domain to an IP |
| **CNAME** | "Also known as..." | www.example.com → example.com |
| **Alias Record** | "AWS-only shortcut" | Pointed to ALB without exposing its DNS |
| **Name Servers** | "Which phonebook to use" | Updated registrar with AWS name servers |
| **Health Check** | "Is the building open?" | Monitors endpoint every 30 seconds |
| **TTL** | "How long to remember this address" | 300 seconds = 5 minutes |

---

## ✅ Verification Checklist

- [ ] Hosted Zone created
- [ ] Name servers retrieved and noted
- [ ] A record resolves to correct IP
- [ ] CNAME resolves to main domain
- [ ] Alias record points to ALB
- [ ] `nslookup` or `dig` returns correct values
- [ ] Health check created and monitoring

---

## 🧹 Cleanup

```bash
# Delete health check
aws route53 delete-health-check --health-check-id $HEALTH_CHECK_ID

# Delete all records (except NS and SOA which are managed by AWS)
# You must delete records before deleting the hosted zone

# Get all non-NS/SOA records and delete them
aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID     --query 'ResourceRecordSets[?Type!=`NS` && Type!=`SOA`].[Name,Type,ResourceRecords[0].Value || AliasTarget.DNSName]'     --output table

# Delete the hosted zone
aws route53 delete-hosted-zone --id $ZONE_ID

# Clean up files
rm -f a-record.json cname-record.json alias-record.json

echo "✅ Lab 8 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| DNS not resolving | Name server propagation takes 5–60 minutes. Wait, then try again |
| `No hosted zone found` | Hosted Zone IDs start with `/hostedzone/`. Remove that prefix in some CLI commands |
| Alias record fails | ALB must be in the same region. Check the ALB hosted zone ID matches your region |
| Health check shows UNKNOWN | Health checks need a few minutes to initialize. Check that port 80 is open |

---

## 🎯 Stretch Goals

1. **Geolocation Routing** — Send African users to `af-south-1`, European users to `eu-west-1`:
   ```bash
   aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{
       "Changes": [{
           "Action": "CREATE",
           "ResourceRecordSet": {
               "Name": "'$DOMAIN'",
               "Type": "A",
               "SetIdentifier": "Africa",
               "GeoLocation": {"ContinentCode": "AF"},
               "TTL": 300,
               "ResourceRecords": [{"Value": "AFRICA_IP"}]
           }
       }]
   }'
   ```
2. **Failover Routing** — Primary in us-east-1, secondary in us-west-2:
   ```bash
   # Create primary and secondary records with Failover type
   ```
3. **Weighted Routing** — Send 80% traffic to new version, 20% to old version (blue/green deployment)

---

## 📌 No Domain? No Problem!

If you don't have a registered domain, you can still practice:

```bash
# Use the AWS DNS simulation tool
# Or practice with these commands against any public domain:

# Query Google's DNS
nslookup google.com

# Use dig for detailed info
dig +short google.com A
dig +short google.com MX  # Mail servers
dig +short google.com NS  # Name servers

# Trace the full resolution path
dig +trace google.com
```

> Understanding DNS is the goal. You can apply the same Route 53 commands the moment you buy a domain.

---

**Next → [Lab 9: CloudWatch Monitoring](../lab-09-cloudwatch/)**
