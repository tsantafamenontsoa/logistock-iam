#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# VAULT FAST INIT (30 seconds)
# ═══════════════════════════════════════════════════════════════

echo "🚀 Vault Fast Init..."

VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="root"

# Wait for Vault
echo "⏳ Waiting for Vault..."
for i in {1..30}; do
  curl -s -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/health > /dev/null && break
  sleep 1
done

echo "✅ Vault ready"

# Enable SSH secret engine
echo "🔑 Enabling SSH engine..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  $VAULT_ADDR/v1/sys/mounts/ssh \
  -d '{"type":"ssh"}' > /dev/null 2>&1

echo "  ✓ SSH engine enabled"

# Create SSH role (bastion-admin)
echo "📝 Creating SSH roles..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  $VAULT_ADDR/v1/ssh/roles/bastion-admin \
  -d '{
    "key_type":"ca",
    "ttl":"30m",
    "max_ttl":"2h",
    "allowed_users":"root"
  }' > /dev/null

echo "  ✓ bastion-admin role created"

# Create SSH role (bastion-user)
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  $VAULT_ADDR/v1/ssh/roles/bastion-user \
  -d '{
    "key_type":"ca",
    "ttl":"15m",
    "max_ttl":"1h",
    "allowed_users":"logistock"
  }' > /dev/null

echo "  ✓ bastion-user role created"

echo ""
echo "✅ Vault initialized!"
echo ""
echo "Access: $VAULT_ADDR"
echo "Token: $VAULT_TOKEN"
echo "SSH Roles: bastion-admin, bastion-user"
echo ""
