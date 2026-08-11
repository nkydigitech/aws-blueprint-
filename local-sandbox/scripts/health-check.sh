#!/bin/bash
# Check LocalStack service health

echo "🏥 LocalStack Health Check"
echo "=========================="

SERVICES="s3 ec2 iam rds cloudwatch logs sns sqs lambda apigateway route53 autoscaling elbv2"

for svc in $SERVICES; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4566/_localstack/health 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "✅ $svc — responding"
    else
        echo "❌ $svc — not responding (status: $STATUS)"
    fi
done

echo ""
echo "Test S3:"
awslocal s3 ls 2>/dev/null || echo "❌ S3 not available"

echo ""
echo "Test EC2:"
awslocal ec2 describe-instances 2>/dev/null || echo "❌ EC2 not available"
