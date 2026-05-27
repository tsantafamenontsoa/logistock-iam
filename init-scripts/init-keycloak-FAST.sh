#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# KEYCLOAK FAST INIT (1 minute)
# ═══════════════════════════════════════════════════════════════

echo "🚀 Keycloak Fast Init..."

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASS="logistockadmin"
REALM="logistock"

# Wait for Keycloak
echo "⏳ Waiting for Keycloak..."
for i in {1..60}; do
  curl -s $KEYCLOAK_URL/health/ready > /dev/null && break
  sleep 1
done

echo "✅ Keycloak ready"

# Get admin token
echo "🔐 Getting admin token..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASS" \
  -d "grant_type=password" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to get admin token"
  exit 1
fi

echo "✅ Token received"

# Create realm
echo "📝 Creating realm '$REALM'..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"realm\":\"$REALM\",\"enabled\":true}" > /dev/null

echo "  ✓ Realm created"

# Create users
echo "👥 Creating users..."
for user in alice bob charlie dave eve frank; do
  curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"enabled\":true,\"credentials\":[{\"type\":\"password\",\"value\":\"${user}123\",\"temporary\":false}]}" > /dev/null
  echo "  ✓ $user (password: ${user}123)"
done

echo ""
echo "✅ Keycloak initialized!"
echo ""
echo "Access: $KEYCLOAK_URL"
echo "Admin: $ADMIN_USER / $ADMIN_PASS"
echo ""
