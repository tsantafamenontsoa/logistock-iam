#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# KEYCLOAK INITIALIZATION
# Crée realm, users, groups, roles, clients pour LogiStock IAM
# ═══════════════════════════════════════════════════════════════

echo "🚀 Initialisation Keycloak..."

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="logistockadmin"
REALM="logistock"

# Attendre que Keycloak soit prêt
echo "⏳ Attente Keycloak..."
until curl -sf "${KEYCLOAK_URL}/health/ready" > /dev/null; do
  sleep 5
done
echo "✅ Keycloak prêt !"

# Obtenir token admin
echo "🔐 Authentification admin..."
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "❌ Erreur : Impossible d'obtenir le token admin"
  exit 1
fi

echo "✅ Token obtenu"

# ═══════════════════════════════════════════════════════════════
# CRÉER REALM LOGISTOCK
# ═══════════════════════════════════════════════════════════════

echo "🏰 Création realm 'logistock'..."

curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "logistock",
    "enabled": true,
    "displayName": "LogiStock IAM",
    "accessTokenLifespan": 300,
    "ssoSessionIdleTimeout": 1800,
    "ssoSessionMaxLifespan": 36000,
    "registrationAllowed": false,
    "resetPasswordAllowed": true,
    "rememberMe": true,
    "verifyEmail": false,
    "loginWithEmailAllowed": true,
    "duplicateEmailsAllowed": false,
    "sslRequired": "none"
  }'

echo "✅ Realm créé"

# Obtenir nouveau token pour le realm logistock
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  | jq -r '.access_token')

# ═══════════════════════════════════════════════════════════════
# CRÉER UTILISATEURS LOGISTOCK
# ═══════════════════════════════════════════════════════════════

echo "👤 Création utilisateurs..."

# Fonction pour créer un utilisateur
create_user() {
  local username=$1
  local firstname=$2
  local lastname=$3
  local email=$4
  local password=$5
  
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"${username}\",
      \"firstName\": \"${firstname}\",
      \"lastName\": \"${lastname}\",
      \"email\": \"${email}\",
      \"enabled\": true,
      \"emailVerified\": true,
      \"credentials\": [{
        \"type\": \"password\",
        \"value\": \"${password}\",
        \"temporary\": false
      }]
    }"
  
  echo "  ✅ ${username} créé"
}

# Créer les 6 utilisateurs LogiStock
create_user "alice" "Alice" "Martin" "alice@logistock.com" "alice123"
create_user "bob" "Bob" "Dupont" "bob@logistock.com" "bob123"
create_user "charlie" "Charlie" "Lambert" "charlie@logistock.com" "charlie123"
create_user "dave" "Dave" "Bernard" "dave@logistock.com" "dave123"
create_user "eve" "Eve" "Dubois" "eve@logistock.com" "eve123"
create_user "frank" "Frank" "Moreau" "frank@logistock.com" "frank123"

echo "✅ 6 utilisateurs créés"

# ═══════════════════════════════════════════════════════════════
# CRÉER GROUPES
# ═══════════════════════════════════════════════════════════════

echo "👥 Création groupes..."

# Fonction pour créer un groupe
create_group() {
  local groupname=$1
  
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${groupname}\"
    }"
  
  echo "  ✅ Groupe ${groupname} créé"
}

create_group "admins"
create_group "managers"
create_group "developers"
create_group "accountants"
create_group "viewers"

echo "✅ 5 groupes créés"

# ═══════════════════════════════════════════════════════════════
# CRÉER RÔLES
# ═══════════════════════════════════════════════════════════════

echo "🎭 Création rôles..."

# Fonction pour créer un rôle
create_role() {
  local rolename=$1
  local description=$2
  
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${rolename}\",
      \"description\": \"${description}\"
    }"
  
  echo "  ✅ Rôle ${rolename} créé"
}

create_role "admin" "Administrateur système"
create_role "stock_manager" "Gestionnaire de stocks"
create_role "developer" "Développeur"
create_role "accountant" "Comptable"
create_role "viewer" "Lecteur seul"

echo "✅ 5 rôles créés"

# ═══════════════════════════════════════════════════════════════
# CRÉER CLIENTS OAUTH2 (3 services LogiStock)
# ═══════════════════════════════════════════════════════════════

echo "🔌 Création clients OAuth2..."

# Client 1 : logistock-web (Frontend public)
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "logistock-web",
    "name": "LogiStock Web Frontend",
    "description": "Frontend web LogiStock",
    "enabled": true,
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "http://localhost:5000/*",
      "http://localhost:4180/*"
    ],
    "webOrigins": [
      "http://localhost:5000",
      "http://localhost:4180"
    ],
    "protocol": "openid-connect"
  }'

echo "  ✅ Client logistock-web créé"

# Client 2 : logistock-api (API backend)
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "logistock-api",
    "name": "LogiStock API",
    "description": "API REST LogiStock",
    "enabled": true,
    "publicClient": false,
    "secret": "api-secret-change-me",
    "serviceAccountsEnabled": true,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "redirectUris": [
      "http://localhost:5001/*"
    ],
    "webOrigins": [
      "http://localhost:5001"
    ],
    "protocol": "openid-connect"
  }'

echo "  ✅ Client logistock-api créé"

# Client 3 : logistock-admin (Panel admin)
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "logistock-admin",
    "name": "LogiStock Admin Panel",
    "description": "Panel administration LogiStock",
    "enabled": true,
    "publicClient": false,
    "secret": "admin-secret-change-me",
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "redirectUris": [
      "http://localhost:5002/*"
    ],
    "webOrigins": [
      "http://localhost:5002"
    ],
    "protocol": "openid-connect"
  }'

echo "  ✅ Client logistock-admin créé"

# Client 4 : oauth2-proxy (Identity-Aware Proxy)
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "logistock-proxy",
    "name": "LogiStock OAuth2 Proxy",
    "description": "Identity-Aware Proxy pour Zero Trust",
    "enabled": true,
    "publicClient": false,
    "secret": "proxy-secret-change-me",
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "http://localhost:4180/oauth2/callback"
    ],
    "webOrigins": [
      "http://localhost:4180"
    ],
    "protocol": "openid-connect"
  }'

echo "  ✅ Client logistock-proxy créé"

echo "✅ 4 clients OAuth2 créés"

# ═══════════════════════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ KEYCLOAK INITIALISÉ"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🏰 REALM : logistock"
echo ""
echo "👤 UTILISATEURS (6) :"
echo "  - alice@logistock.com / alice123"
echo "  - bob@logistock.com / bob123"
echo "  - charlie@logistock.com / charlie123"
echo "  - dave@logistock.com / dave123"
echo "  - eve@logistock.com / eve123"
echo "  - frank@logistock.com / frank123"
echo ""
echo "👥 GROUPES (5) :"
echo "  - admins, managers, developers, accountants, viewers"
echo ""
echo "🎭 RÔLES (5) :"
echo "  - admin, stock_manager, developer, accountant, viewer"
echo ""
echo "🔌 CLIENTS OAuth2 (4) :"
echo "  - logistock-web (public)"
echo "  - logistock-api (confidential, secret: api-secret-change-me)"
echo "  - logistock-admin (confidential, secret: admin-secret-change-me)"
echo "  - logistock-proxy (confidential, secret: proxy-secret-change-me)"
echo ""
echo "🔗 CONSOLE : http://localhost:8080"
echo "🔐 ADMIN : admin / logistockadmin"
echo ""
echo "📋 PROCHAINES ÉTAPES :"
echo "  1. Assigner utilisateurs aux groupes (manuellement ou script)"
echo "  2. Assigner rôles aux utilisateurs/groupes"
echo "  3. Configurer MFA (Authentication → Required Actions)"
echo ""
echo "═══════════════════════════════════════════════════════════"
