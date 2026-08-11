# Lab 5: S3 — Simple Storage Service

> **The Warehouse** — Store anything. Pay for what you use. Make some aisles public, keep others locked.

---

## 🎯 Objective

- Create S3 buckets
- Upload and download files
- Enable static website hosting
- Set bucket policies and access controls
- Understand storage classes

**The Analogy:** You have an infinite warehouse. You pay only for the boxes you use. Some aisles are open to the public (your website images). Some are locked in a vault (backups). Some boxes you rarely open, so you move them to cheaper shelves (Glacier).

---

## 💰 Cost Warning

- S3 Standard: **$0.023/GB/month**
- A small static website (< 10MB) = **practically free**
- This lab takes ~20 minutes = **$0.00**
- **Delete buckets when done!** (Empty them first)

---

## 📋 One-Liner Setup

```bash
export AWS_REGION="us-east-1"
export MY_NAME="nkechi"
export BUCKET_NAME="${MY_NAME}-lab5-bucket-$(date +%s)"
export WEBSITE_BUCKET="${MY_NAME}-lab5-website-$(date +%s)"
```

> Bucket names must be **globally unique** across ALL of AWS. That's why we add a timestamp.

---

## 🔧 Step-by-Step

### Step 1: Create a Bucket

```bash
aws s3 mb s3://$BUCKET_NAME
```

**Expected Output:**
```
make_bucket: nkechi-lab5-bucket-1691234567
```

---

### Step 2: Upload Files

```bash
# Create some test files
echo "Hello, this is file 1" > file1.txt
echo "Hello, this is file 2" > file2.txt
echo '{"name": "nkechi", "role": "DevOps Engineer"}' > data.json

# Upload them
aws s3 cp file1.txt s3://$BUCKET_NAME/
aws s3 cp file2.txt s3://$BUCKET_NAME/documents/
aws s3 cp data.json s3://$BUCKET_NAME/data/

# List contents
aws s3 ls s3://$BUCKET_NAME --recursive
```

**Expected Output:**
```
2024-08-11 10:00:00          0 documents/
2024-08-11 10:00:00         22 data.json
2024-08-11 10:00:00         22 documents/file2.txt
2024-08-11 10:00:00         22 file1.txt
```

---

### Step 3: Download a File

```bash
aws s3 cp s3://$BUCKET_NAME/file1.txt downloaded-file.txt
cat downloaded-file.txt
```

**Expected Output:**
```
Hello, this is file 1
```

---

### Step 4: Sync a Local Folder (Like `rsync`)

```bash
mkdir -p local-folder/subfolder
echo "A" > local-folder/a.txt
echo "B" > local-folder/subfolder/b.txt

# Sync UP to S3
aws s3 sync local-folder s3://$BUCKET_NAME/synced/

# Verify
aws s3 ls s3://$BUCKET_NAME/synced/ --recursive
```

**Expected Output:**
```
2024-08-11 10:00:00          2 synced/a.txt
2024-08-11 10:00:00          2 synced/subfolder/b.txt
```

---

### Step 5: Enable Versioning (Keep Every Version)

```bash
aws s3api put-bucket-versioning     --bucket $BUCKET_NAME     --versioning-configuration Status=Enabled

# Upload the same file twice (different content)
echo "Version 1" > versioned.txt
aws s3 cp versioned.txt s3://$BUCKET_NAME/

echo "Version 2" > versioned.txt
aws s3 cp versioned.txt s3://$BUCKET_NAME/

# List all versions
aws s3api list-object-versions --bucket $BUCKET_NAME --prefix versioned.txt     --query 'Versions[*].[VersionId,LastModified,IsLatest]' --output table
```

**Expected Output:**
```
----------------------------------
|       ListObjectVersions       |
+----------+---------------------+
|  null    |  2024-08-11...      |
|  true    |                     |
|  xxxxx   |  2024-08-11...      |
|  false   |                     |
+----------+---------------------+
```

> Even though you overwrote `versioned.txt`, both versions still exist. You can restore the old one anytime.

---

### Step 6: Build a Static Website

```bash
# Create the website bucket
aws s3 mb s3://$WEBSITE_BUCKET

# Create a simple website
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>My AWS Website</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
        h1 { color: #ff9900; }
    </style>
</head>
<body>
    <h1>🚀 Hello from S3!</h1>
    <p>This website is hosted entirely on Amazon S3</p>
    <p>Built by: <strong>nkechi</strong></p>
    <p>Region: <span id="region"></span></p>
    <script>
        document.getElementById('region').textContent = 'us-east-1';
    </script>
</body>
</html>
EOF

cat > error.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body>
    <h1>😕 Oops! Page not found</h1>
    <p>This is a custom error page from S3</p>
</body>
</html>
EOF

# Upload website files
aws s3 cp index.html s3://$WEBSITE_BUCKET/
aws s3 cp error.html s3://$WEBSITE_BUCKET/

# Enable static website hosting
aws s3api put-bucket-website --bucket $WEBSITE_BUCKET --website-configuration '{
    "IndexDocument": {"Suffix": "index.html"},
    "ErrorDocument": {"Key": "error.html"}
}'

# Make the bucket publicly readable (REQUIRED for website hosting)
aws s3api put-bucket-policy --bucket $WEBSITE_BUCKET --policy '{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::'$WEBSITE_BUCKET'/*"
    }]
}'

# Block public access must be disabled for this to work
aws s3api put-public-access-block --bucket $WEBSITE_BUCKET --public-access-block-configuration '{
    "BlockPublicAcls": false,
    "IgnorePublicAcls": false,
    "BlockPublicPolicy": false,
    "RestrictPublicBuckets": false
}'

# Get the website URL
export WEBSITE_URL="http://$WEBSITE_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo "🌐 Your website is live at: $WEBSITE_URL"
```

**Expected Output:**
```
🌐 Your website is live at: http://nkechi-lab5-website-1691234567.s3-website-us-east-1.amazonaws.com
```

> Open that URL in your browser. You should see your custom HTML page!

---

### Step 7: Test the Error Page

```bash
curl $WEBSITE_URL/nonexistent-page.html
```

**Expected Output:**
```html
<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body>
    <h1>😕 Oops! Page not found</h1>
    <p>This is a custom error page from S3</p>
</body>
</html>
```

---

### Step 8: Change Storage Class (Move to Cheaper Shelves)

```bash
# Upload a file with Glacier Deep Archive (cheapest, for backups)
echo "Important backup data" > backup.txt
aws s3 cp backup.txt s3://$BUCKET_NAME/backups/     --storage-class GLACIER_DEEP_ARCHIVE

# Check the storage class
aws s3api head-object --bucket $BUCKET_NAME --key backups/backup.txt     --query '[StorageClass,Size]' --output table
```

**Expected Output:**
```
----------
|head-obj|
+----------+
|DEEP_ARC..|
|  22      |
+----------+
```

> Glacier Deep Archive costs **$0.00099/GB/month** — 99% cheaper than Standard. Perfect for backups you rarely touch.

---

## 🧠 What Just Happened?

| Feature | The Analogy | What You Did |
|---------|-------------|--------------|
| **Bucket** | A warehouse section | Created globally unique buckets |
| **Object** | A box in the warehouse | Uploaded files, JSON, HTML |
| **Sync** | "Make my local folder match the warehouse" | `aws s3 sync` |
| **Versioning** | Keep every version of a box | Enabled, uploaded 2 versions |
| **Static Website** | Open showroom | Hosted HTML on S3 with public access |
| **Bucket Policy** | "Who can enter which aisles" | Allowed public read for website |
| **Storage Class** | Different shelf prices | Moved backup to cheapest shelf |

---

## ✅ Verification Checklist

- [ ] Bucket created successfully
- [ ] Files uploaded and listed
- [ ] File downloaded correctly
- [ ] Folder sync worked
- [ ] Versioning shows multiple versions
- [ ] Static website loads in browser
- [ ] Error page shows on 404
- [ ] Glacier backup has correct storage class

---

## 🧹 Cleanup

```bash
# Empty the buckets first (S3 won't delete non-empty buckets!)
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rm s3://$WEBSITE_BUCKET --recursive

# Delete the buckets
aws s3 rb s3://$BUCKET_NAME
aws s3 rb s3://$WEBSITE_BUCKET

# Clean up local files
rm -f file1.txt file2.txt data.json versioned.txt backup.txt
rm -f index.html error.html
rm -rf local-folder downloaded-file.txt

echo "✅ Lab 5 cleaned up!"
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `BucketAlreadyExists` | Bucket names are GLOBAL. Add more randomness to the name |
| `AccessDenied` on website | Check bucket policy AND public access block settings |
| `BucketNotEmpty` when deleting | Empty the bucket with `aws s3 rm --recursive` first |
| Website URL returns 403 | The bucket policy isn't allowing public read. Check Step 6 |
| Can't restore Glacier file | Glacier files take hours to retrieve. Use `aws s3api restore-object` |

---

## 🎯 Stretch Goals

1. **Enable S3 Event Notifications** — Trigger a Lambda when a file is uploaded:
   ```bash
   aws s3api put-bucket-notification-configuration --bucket $BUCKET_NAME        --notification-configuration '{"LambdaFunctionConfigurations": [...]}'
   ```
2. **Enable S3 Access Logging** — Track who accesses your files
3. **Use S3 Transfer Acceleration** — Speed up uploads from far away:
   ```bash
   aws s3api put-bucket-accelerate-configuration --bucket $BUCKET_NAME --accelerate-configuration Status=Enabled
   ```

---

**Next → [Lab 6: RDS Databases](../lab-06-rds/)**
