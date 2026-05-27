#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# LOCALSTACK FAST INIT (30 seconds)
# ═══════════════════════════════════════════════════════════════

echo "🚀 LocalStack Fast Init..."

# Wait for LocalStack
echo "⏳ Waiting for LocalStack..."
for i in {1..30}; do
  curl -s http://localhost:4566/_localstack/health > /dev/null && break
  sleep 1
done

echo "✅ LocalStack ready"

# Create 6 IAM users (essential for TP2)
echo "📝 Creating IAM users..."
for user in alice bob charlie dave eve frank; do
  awslocal iam create-user --user-name $user 2>/dev/null && echo "  ✓ $user"
done

# Create 1 bucket (essential for TP2)
echo "📦 Creating S3 bucket..."
awslocal s3 mb s3://logistock-data 2>/dev/null && echo "  ✓ logistock-data"

echo ""
echo "✅ LocalStack initialized in 30 seconds!"
echo ""
echo "For TP2, you can add more users/groups/policies manually:"
echo "  awslocal iam create-group --group-name admins"
echo "  awslocal iam add-user-to-group --group-name admins --user-name alice"
echo ""
