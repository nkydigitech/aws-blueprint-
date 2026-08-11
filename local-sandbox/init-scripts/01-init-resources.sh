#!/bin/bash
# LocalStack Init Script — runs automatically when container starts
# This pre-creates common resources so labs work immediately

echo "🚀 Initializing AWS Blueprint Sandbox..."

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export ENDPOINT_URL=http://localhost:4566

# Create a default VPC and subnets for EC2/RDS
awslocal ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=localstack-default-vpc}]'
VPC_ID=$(awslocal ec2 describe-vpcs --filters "Name=cidr-block,Values=10.0.0.0/16" --query 'Vpcs[0].VpcId' --output text)

awslocal ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=localstack-public-1}]'
awslocal ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=localstack-public-2}]'
awslocal ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=localstack-private-1}]'
awslocal ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=localstack-private-2}]'

# Create Internet Gateway
IGW_ID=$(awslocal ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
awslocal ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create default security group rules
awslocal ec2 create-security-group --group-name default-web --description "Default web SG" --vpc-id $VPC_ID
awslocal ec2 create-security-group --group-name default-db --description "Default DB SG" --vpc-id $VPC_ID

# Pre-create an S3 bucket for Lab 5
awslocal s3 mb s3://localstack-sandbox-bucket

# Pre-create a CloudWatch log group
awslocal logs create-log-group --log-group-name /localstack/sandbox

# Pre-create an SNS topic
awslocal sns create-topic --name localstack-alerts

echo "✅ Sandbox initialized!"
echo "VPC ID: $VPC_ID"
echo "Ready for labs."
