#!/bin/bash
# Reset LocalStack sandbox

echo "🧹 Resetting LocalStack sandbox..."

cd "$(dirname "$0")/.."

docker-compose down -v
rm -rf localstack-data

echo "🚀 Restarting..."
docker-compose up -d

echo "⏳ Waiting for initialization..."
sleep 30

echo "✅ Sandbox reset! Test with: awslocal s3 ls"
