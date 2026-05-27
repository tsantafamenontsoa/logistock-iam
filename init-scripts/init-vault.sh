#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# VAULT INITIALIZATION — JIT SSH ACCESS
# Configure Vault SSH secrets engine pour accès temporaire bastion
# Réutilise concepts CRYE857 (Vault dynamic secrets)
# ═══════════════════════════════════════════════════════════════

echo "🚀 Initialisation Vault SSH secrets engine..."

export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='root'

# Attendre que Vault soit prêt
echo "⏳ Attente Vault..."
until vault status &> /dev/null; do
  sleep 2
done
echo "✅ Vault prêt !"

# ═══════════════════════════════════════════════════════════════
# ACTIVER SSH SECRETS ENGINE
# ═══════════════════════════════════════════════════════════════

echo "🔧 Activation SSH secrets engine..."

vault secrets enable -path=ssh ssh

echo "✅ SSH secrets engine activé"

# ═══════════════════════════════════════════════════════════════
# CONFIGURER ROLE SSH (OTP)
# ═══════════════════════════════════════════════════════════════

echo "🎭 Configuration rôle SSH OTP..."

# Rôle bastion-admin (accès root bastion, 30 min)
vault write ssh/roles/bastion-admin \
  key_type=otp \
  default_user=root \
  cidr_list=10.2.0.0/24 \
  port=22 \
  ttl=30m \
  max_ttl=1h

echo "  ✅ Rôle bastion-admin créé (OTP, 30 min)"

# Rôle bastion-user (accès limité, 15 min)
vault write ssh/roles/bastion-user \
  key_type=otp \
  default_user=logistock \
  cidr_list=10.2.0.0/24 \
  port=22 \
  ttl=15m \
  max_ttl=30m

echo "  ✅ Rôle bastion-user créé (OTP, 15 min)"

echo "✅ Rôles SSH configurés"

# ═══════════════════════════════════════════════════════════════
# CONFIGURER POLITIQUES VAULT
# ═══════════════════════════════════════════════════════════════

echo "📋 Création politiques Vault..."

# Politique admin (accès bastion-admin)
cat > /tmp/vault-policy-admin.hcl << 'EOF'
# Politique pour admins (Alice, Bob)
path "ssh/creds/bastion-admin" {
  capabilities = ["create", "read", "update"]
}

path "ssh/roles/bastion-admin" {
  capabilities = ["read"]
}
EOF

vault policy write logistock-admin /tmp/vault-policy-admin.hcl

echo "  ✅ Politique logistock-admin créée"

# Politique developer (accès bastion-user)
cat > /tmp/vault-policy-developer.hcl << 'EOF'
# Politique pour developers (Dave)
path "ssh/creds/bastion-user" {
  capabilities = ["create", "read", "update"]
}

path "ssh/roles/bastion-user" {
  capabilities = ["read"]
}
EOF

vault policy write logistock-developer /tmp/vault-policy-developer.hcl

echo "  ✅ Politique logistock-developer créée"

echo "✅ Politiques créées"

# ═══════════════════════════════════════════════════════════════
# CRÉER TOKENS VAULT POUR UTILISATEURS
# ═══════════════════════════════════════════════════════════════

echo "🎫 Génération tokens utilisateurs..."

# Token Alice (admin)
ALICE_TOKEN=$(vault token create \
  -policy=logistock-admin \
  -display-name="alice-logistock" \
  -ttl=24h \
  -format=json | jq -r '.auth.client_token')

echo "  ✅ Token Alice : ${ALICE_TOKEN}"

# Token Bob (admin)
BOB_TOKEN=$(vault token create \
  -policy=logistock-admin \
  -display-name="bob-logistock" \
  -ttl=24h \
  -format=json | jq -r '.auth.client_token')

echo "  ✅ Token Bob : ${BOB_TOKEN}"

# Token Dave (developer)
DAVE_TOKEN=$(vault token create \
  -policy=logistock-developer \
  -display-name="dave-logistock" \
  -ttl=24h \
  -format=json | jq -r '.auth.client_token')

echo "  ✅ Token Dave : ${DAVE_TOKEN}"

echo "✅ Tokens générés"

# ═══════════════════════════════════════════════════════════════
# ACTIVER KV SECRETS ENGINE (pour OAuth2 secrets)
# ═══════════════════════════════════════════════════════════════

echo "🔧 Activation KV secrets engine..."

vault secrets enable -path=secret kv-v2

echo "✅ KV secrets engine activé"

# Stocker secrets OAuth2 Keycloak
vault kv put secret/keycloak/logistock-api \
  client_id=logistock-api \
  client_secret=api-secret-change-me

vault kv put secret/keycloak/logistock-admin \
  client_id=logistock-admin \
  client_secret=admin-secret-change-me

vault kv put secret/keycloak/logistock-proxy \
  client_id=logistock-proxy \
  client_secret=proxy-secret-change-me

echo "✅ Secrets OAuth2 stockés dans Vault"

# ═══════════════════════════════════════════════════════════════
# ACTIVER AUDIT LOG
# ═══════════════════════════════════════════════════════════════

echo "📝 Activation audit logs..."

vault audit enable file file_path=/vault/logs/audit.log

echo "✅ Audit logs activés"

# ═══════════════════════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ VAULT INITIALISÉ (JIT SSH ACCESS)"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🔧 SSH SECRETS ENGINE : ssh/"
echo ""
echo "🎭 RÔLES SSH (2) :"
echo "  - bastion-admin (root, 30 min, 10.2.0.0/24)"
echo "  - bastion-user (logistock, 15 min, 10.2.0.0/24)"
echo ""
echo "📋 POLITIQUES (2) :"
echo "  - logistock-admin → ssh/creds/bastion-admin"
echo "  - logistock-developer → ssh/creds/bastion-user"
echo ""
echo "🎫 TOKENS UTILISATEURS :"
echo "  - Alice : ${ALICE_TOKEN}"
echo "  - Bob   : ${BOB_TOKEN}"
echo "  - Dave  : ${DAVE_TOKEN}"
echo ""
echo "🔐 SECRETS OAuth2 STOCKÉS :"
echo "  - secret/keycloak/logistock-api"
echo "  - secret/keycloak/logistock-admin"
echo "  - secret/keycloak/logistock-proxy"
echo ""
echo "🔗 VAULT UI : http://localhost:8200"
echo "🔐 ROOT TOKEN : root"
echo ""
echo "📋 TEST JIT ACCESS :"
echo "  # Alice demande accès bastion (30 min)"
echo "  export VAULT_TOKEN=${ALICE_TOKEN}"
echo "  vault write ssh/creds/bastion-admin ip=10.2.0.10"
echo ""
echo "  # Sortie :"
echo "  # key             [OTP password]"
echo "  # username        root"
echo "  # ip              10.2.0.10"
echo "  # lease_duration  1800 (30 min)"
echo ""
echo "  # Se connecter avec OTP"
echo "  ssh root@<bastion-ip>"
echo "  # Password: [OTP from Vault]"
echo ""
echo "═══════════════════════════════════════════════════════════"
