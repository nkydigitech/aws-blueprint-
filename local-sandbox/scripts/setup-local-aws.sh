#!/bin/bash
# Configure AWS CLI for LocalStack

echo "🔧 Configuring AWS CLI for LocalStack..."

# Create local profile
aws configure set aws_access_key_id test --profile local
aws configure set aws_secret_access_key test --profile local
aws configure set region us-east-1 --profile local
aws configure set output json --profile local

# Add endpoint configuration
cat >> ~/.aws/config << 'EOF'

[profile local]
endpoint_url = http://localhost:4566
EOF

echo "✅ Profile 'local' created!"
echo ""
echo "Test it:"
echo "  aws --profile local s3 ls"
echo "  awslocal s3 ls"
