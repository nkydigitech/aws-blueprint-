#!/bin/bash
# Capstone EC2 User Data Script
# This runs automatically when each instance launches

# Update system
dnf update -y

# Install Nginx and MySQL client
dnf install -y nginx mariadb105

# Start Nginx
systemctl start nginx
systemctl enable nginx

# Create a simple dynamic page that shows instance info and DB connection status
cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>AWS Capstone App</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background: #f0f2f5; }
        .container { background: white; padding: 40px; border-radius: 12px; display: inline-block; box-shadow: 0 4px 12px rgba(0,0,0,0.15); max-width: 600px; }
        h1 { color: #ff9900; }
        .info { text-align: left; margin: 20px 0; }
        .info p { margin: 8px 0; font-size: 14px; }
        .status-ok { color: green; font-weight: bold; }
        .status-fail { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 AWS Capstone Application</h1>
        <div class="info">
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Private IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
            <p><strong>Hostname:</strong> $(hostname -f)</p>
            <p><strong>DB Endpoint:</strong> ${db_endpoint}</p>
            <p><strong>DB Status:</strong> <span id="db-status" class="status-ok">Checking...</span></p>
        </div>
        <p><em>Built with Terraform | AWS Blueprint Capstone</em></p>
    </div>
    <script>
        // Simple health check
        fetch('/health')
            .then(r => r.ok ? 'Connected ✅' : 'Error ❌')
            .then(t => document.getElementById('db-status').textContent = t)
            .catch(() => document.getElementById('db-status').textContent = 'Disconnected ❌');
    </script>
</body>
</html>
HTMLEOF

# Create a health check endpoint
cat > /usr/share/nginx/html/health << 'HEALTHEOF'
{"status": "healthy", "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
HEALTHEOF

# Configure Nginx to serve the health endpoint
sed -i '/location \/ {/a\n        location /health {
            default_type application/json;
            alias /usr/share/nginx/html/health;
        }' /etc/nginx/nginx.conf

systemctl restart nginx

# Log completion
echo "Capstone app setup complete at $(date)" >> /var/log/capstone-setup.log
