#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# LOCALSTACK AWS IAM INITIALIZATION
# Crée utilisateurs, groupes, rôles, politiques AWS IAM
# ═══════════════════════════════════════════════════════════════

echo "🚀 Initialisation LocalStack AWS IAM..."

# Configuration AWS CLI pour LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566

# Attendre que LocalStack soit prêt
echo "⏳ Attente LocalStack..."
until awslocal iam list-users &> /dev/null; do
  sleep 2
done
echo "✅ LocalStack prêt !"

# ═══════════════════════════════════════════════════════════════
# UTILISATEURS AWS IAM (équipe LogiStock)
# ═══════════════════════════════════════════════════════════════

echo "👤 Création utilisateurs AWS IAM..."

# Alice (CEO) — Admin complet
awslocal iam create-user --user-name alice
awslocal iam create-access-key --user-name alice

# Bob (CTO) — Admin complet
awslocal iam create-user --user-name bob
awslocal iam create-access-key --user-name bob

# Charlie (Stock Manager) — PowerUser
awslocal iam create-user --user-name charlie
awslocal iam create-access-key --user-name charlie

# Dave (Développeur) — Lecture seule
awslocal iam create-user --user-name dave
awslocal iam create-access-key --user-name dave

# Eve (Comptable) — Lecture S3
awslocal iam create-user --user-name eve
awslocal iam create-access-key --user-name eve

# Frank (Stagiaire) — Très limité
awslocal iam create-user --user-name frank
awslocal iam create-access-key --user-name frank

echo "✅ 6 utilisateurs créés"

# ═══════════════════════════════════════════════════════════════
# GROUPES AWS IAM
# ═══════════════════════════════════════════════════════════════

echo "👥 Création groupes AWS IAM..."

awslocal iam create-group --group-name admins
awslocal iam create-group --group-name developers
awslocal iam create-group --group-name managers
awslocal iam create-group --group-name accountants
awslocal iam create-group --group-name viewers

echo "✅ 5 groupes créés"

# ═══════════════════════════════════════════════════════════════
# ASSIGNER UTILISATEURS AUX GROUPES
# ═══════════════════════════════════════════════════════════════

echo "🔗 Association utilisateurs → groupes..."

# Admins
awslocal iam add-user-to-group --user-name alice --group-name admins
awslocal iam add-user-to-group --user-name bob --group-name admins

# Managers
awslocal iam add-user-to-group --user-name charlie --group-name managers

# Developers
awslocal iam add-user-to-group --user-name dave --group-name developers

# Accountants
awslocal iam add-user-to-group --user-name eve --group-name accountants

# Viewers
awslocal iam add-user-to-group --user-name frank --group-name viewers

echo "✅ Utilisateurs assignés aux groupes"

# ═══════════════════════════════════════════════════════════════
# POLITIQUES AWS IAM MANAGÉES (Attacher aux groupes)
# ═══════════════════════════════════════════════════════════════

echo "📋 Attachement politiques managées..."

# Admins → AdministratorAccess
awslocal iam attach-group-policy \
  --group-name admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Managers → PowerUserAccess (tout sauf IAM)
awslocal iam attach-group-policy \
  --group-name managers \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Developers → ReadOnlyAccess
awslocal iam attach-group-policy \
  --group-name developers \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Viewers → ViewOnlyAccess
awslocal iam attach-group-policy \
  --group-name viewers \
  --policy-arn arn:aws:iam::aws:policy/job-function/ViewOnlyAccess

echo "✅ Politiques managées attachées"

# ═══════════════════════════════════════════════════════════════
# POLITIQUES CUSTOM (pour exercices)
# ═══════════════════════════════════════════════════════════════

echo "📝 Création politiques custom..."

# Politique S3 ReadOnly (pour comptables)
cat > /tmp/s3-readonly-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::logistock-*",
        "arn:aws:s3:::logistock-*/*"
      ]
    }
  ]
}
EOF

awslocal iam create-policy \
  --policy-name LogistockS3ReadOnly \
  --policy-document file:///tmp/s3-readonly-policy.json

# Politique EC2 Start/Stop (pour managers)
cat > /tmp/ec2-startstop-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF

awslocal iam create-policy \
  --policy-name LogistockEC2StartStop \
  --policy-document file:///tmp/ec2-startstop-policy.json

echo "✅ Politiques custom créées"

# Attacher politique S3 ReadOnly aux comptables
POLICY_ARN=$(awslocal iam list-policies --query 'Policies[?PolicyName==`LogistockS3ReadOnly`].Arn' --output text)
awslocal iam attach-group-policy --group-name accountants --policy-arn "$POLICY_ARN"

# ═══════════════════════════════════════════════════════════════
# RÔLES AWS IAM (pour exercices AssumeRole)
# ═══════════════════════════════════════════════════════════════

echo "🎭 Création rôles AWS IAM..."

# Rôle EC2 → S3 (instances EC2 peuvent accéder S3)
cat > /tmp/ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

awslocal iam create-role \
  --role-name LogistockEC2S3Role \
  --assume-role-policy-document file:///tmp/ec2-trust-policy.json

awslocal iam attach-role-policy \
  --role-name LogistockEC2S3Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Rôle Lambda → CloudWatch Logs
cat > /tmp/lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

awslocal iam create-role \
  --role-name LogistockLambdaLogsRole \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json

awslocal iam attach-role-policy \
  --role-name LogistockLambdaLogsRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Rôle cross-account (pour TP AssumeRole)
cat > /tmp/cross-account-trust.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::000000000000:user/alice"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "logistock-external-id-123"
        }
      }
    }
  ]
}
EOF

awslocal iam create-role \
  --role-name LogistockCrossAccountRole \
  --assume-role-policy-document file:///tmp/cross-account-trust.json

awslocal iam attach-role-policy \
  --role-name LogistockCrossAccountRole \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

echo "✅ 3 rôles IAM créés"

# ═══════════════════════════════════════════════════════════════
# CRÉER BUCKET S3 POUR TESTS
# ═══════════════════════════════════════════════════════════════

echo "🪣 Création buckets S3..."

awslocal s3 mb s3://logistock-data
awslocal s3 mb s3://logistock-backups
awslocal s3 mb s3://logistock-logs

# Ajouter quelques fichiers de test
echo "Test file 1" | awslocal s3 cp - s3://logistock-data/test1.txt
echo "Test file 2" | awslocal s3 cp - s3://logistock-data/test2.txt

echo "✅ 3 buckets S3 créés"

# ═══════════════════════════════════════════════════════════════
# CRÉER QUELQUES INSTANCES EC2 POUR TESTS
# ═══════════════════════════════════════════════════════════════

echo "💻 Création instances EC2..."

# Instance web (simulation)
awslocal ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=logistock-web-server}]' \
  > /dev/null 2>&1

# Instance api (simulation)
awslocal ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=logistock-api-server}]' \
  > /dev/null 2>&1

echo "✅ 2 instances EC2 créées"

# ═══════════════════════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ LOCALSTACK AWS IAM INITIALISÉ"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "👤 UTILISATEURS (6) :"
echo "  - alice (CEO, admins)"
echo "  - bob (CTO, admins)"
echo "  - charlie (Manager, managers)"
echo "  - dave (Dev, developers)"
echo "  - eve (Comptable, accountants)"
echo "  - frank (Stagiaire, viewers)"
echo ""
echo "👥 GROUPES (5) :"
echo "  - admins → AdministratorAccess"
echo "  - managers → PowerUserAccess"
echo "  - developers → ReadOnlyAccess"
echo "  - accountants → LogistockS3ReadOnly"
echo "  - viewers → ViewOnlyAccess"
echo ""
echo "🎭 RÔLES (3) :"
echo "  - LogistockEC2S3Role (EC2 → S3)"
echo "  - LogistockLambdaLogsRole (Lambda → CloudWatch)"
echo "  - LogistockCrossAccountRole (AssumeRole)"
echo ""
echo "🪣 S3 BUCKETS (3) :"
echo "  - s3://logistock-data"
echo "  - s3://logistock-backups"
echo "  - s3://logistock-logs"
echo ""
echo "💻 EC2 INSTANCES (2) :"
echo "  - logistock-web-server"
echo "  - logistock-api-server"
echo ""
echo "🔗 ENDPOINT : http://localhost:4566"
echo "📋 Commandes : awslocal (ou aws --endpoint-url=http://localhost:4566)"
echo ""
echo "═══════════════════════════════════════════════════════════"
