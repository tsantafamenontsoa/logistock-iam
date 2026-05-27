# 🚀 LOGISTOCK IAM — PHASE 1 : INFRASTRUCTURE

**Infrastructure Docker complète pour atelier IAM 14h**

---

## 📦 CONTENU PHASE 1

```
├── docker-compose-iam.yml       # Infrastructure complète
├── init-scripts/
│   ├── init-localstack.sh       # AWS IAM (6 users, 5 groups, 3 roles)
│   ├── init-keycloak.sh         # OAuth2/OIDC (6 users, 5 groups, 4 clients)
│   └── init-vault.sh            # JIT SSH Access (2 roles, policies)
└── policies/
    ├── rbac.rego                # Role-Based Access Control
    ├── abac.rego                # Attribute-Based Access Control
    └── zerotrust.rego           # Zero Trust policies
```

---

## 🎯 ARCHITECTURE

```
┌─────────────────────────────────────────────────┐
│  AUTHENTIFICATION                                │
│  ┌──────────┐          ┌──────────┐            │
│  │Keycloak  │          │LocalStack│            │
│  │OAuth2/SSO│          │ AWS IAM  │            │
│  └──────────┘          └──────────┘            │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  AUTHORIZATION                                   │
│  ┌──────────┐          ┌──────────┐            │
│  │   OPA    │          │  Vault   │            │
│  │RBAC/ABAC │          │JIT Access│            │
│  └──────────┘          └──────────┘            │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  SERVICES LOGISTOCK (SECE854 S3)                │
│  DMZ: web, api                                  │
│  Internal: db, monitoring                       │
│  Admin: bastion, nas, backup                    │
└─────────────────────────────────────────────────┘
```

---

## 🚀 DÉMARRAGE RAPIDE

### **1. Prérequis**

```bash
# Docker + Docker Compose
docker --version  # ≥ 20.10
docker-compose --version  # ≥ 1.29

# awslocal (AWS CLI pour LocalStack)
pip install awscli-local

# jq (pour scripts)
sudo apt install jq  # Linux
brew install jq      # macOS
```

### **2. Lancer l'infrastructure**

```bash
# Depuis le dossier contenant docker-compose-iam.yml
docker-compose -f docker-compose-iam.yml up -d

# Vérifier que tout tourne
docker-compose -f docker-compose-iam.yml ps
```

**Services attendus (16 conteneurs) :**
- ✅ logistock_localstack (AWS IAM)
- ✅ logistock_keycloak (OAuth2)
- ✅ logistock_opa (Policies)
- ✅ logistock_vault (JIT Access)
- ✅ logistock_postgres_iam (Keycloak DB)
- ✅ logistock_oauth2_proxy (Zero Trust)
- ✅ logistock_web (DMZ)
- ✅ logistock_api (DMZ)
- ✅ logistock_admin (Admin)
- ✅ logistock_db (Internal)
- ✅ logistock_monitoring (Internal)
- ✅ logistock_bastion (Admin)
- ✅ logistock_nas (Admin)
- ✅ logistock_backup (Admin)
- ✅ logistock_firewall (All networks)
- ✅ logistock_aws_cli (Utilitaire)

### **3. Initialiser les services**

```bash
# Attendre 30 secondes que tout démarre
sleep 30

# Initialiser LocalStack AWS IAM
chmod +x init-scripts/init-localstack.sh
./init-scripts/init-localstack.sh

# Initialiser Keycloak
chmod +x init-scripts/init-keycloak.sh
./init-scripts/init-keycloak.sh

# Initialiser Vault
chmod +x init-scripts/init-vault.sh
./init-scripts/init-vault.sh
```

---

## 🔍 VÉRIFICATION

### **LocalStack (AWS IAM)**

```bash
# Lister utilisateurs
awslocal iam list-users

# Lister groupes
awslocal iam list-groups

# Lister rôles
awslocal iam list-roles

# Tester accès S3 (Alice admin)
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE  # À récupérer du script
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
awslocal s3 ls s3://logistock-data
```

**Endpoints :**
- 🔗 LocalStack : http://localhost:4566
- 📋 Dashboard : http://localhost:4566/_localstack/health

---

### **Keycloak (OAuth2/OIDC)**

```bash
# Console admin
open http://localhost:8080

# Login : admin / logistockadmin
# Realm : logistock

# Tester OAuth2 Authorization Code Flow
curl -X POST "http://localhost:8080/realms/logistock/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=logistock-api" \
  -d "client_secret=api-secret-change-me" \
  -d "username=alice" \
  -d "password=alice123" \
  | jq
```

**Endpoints :**
- 🔗 Console : http://localhost:8080
- 🔐 Realm : http://localhost:8080/realms/logistock
- 📋 OIDC Config : http://localhost:8080/realms/logistock/.well-known/openid-configuration

**Utilisateurs (tous mot de passe = {username}123) :**
- alice@logistock.com / alice123
- bob@logistock.com / bob123
- charlie@logistock.com / charlie123
- dave@logistock.com / dave123
- eve@logistock.com / eve123
- frank@logistock.com / frank123

---

### **OPA (Policies)**

```bash
# Vérifier OPA
curl http://localhost:8181/health

# Tester politique RBAC
curl -X POST http://localhost:8181/v1/data/logistock/rbac/allow \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "user": {"role": "admin"},
      "action": "delete",
      "resource": {"type": "user"}
    }
  }' | jq

# Résultat attendu : {"result": true}
```

**Endpoints :**
- 🔗 API : http://localhost:8181
- 📋 Health : http://localhost:8181/health
- 📄 Policies : http://localhost:8181/v1/policies

---

### **Vault (JIT Access)**

```bash
# Vérifier Vault
curl http://localhost:8200/v1/sys/health

# Login
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='root'

vault status

# Tester JIT SSH (Alice admin)
vault write ssh/creds/bastion-admin ip=10.2.0.10

# Résultat :
# key             [OTP password]
# username        root
# lease_duration  1800 (30 min)
```

**Endpoints :**
- 🔗 UI : http://localhost:8200
- 🔐 Token : root
- 📋 Policies : vault policy list

---

### **Services LogiStock**

```bash
# Web (DMZ)
curl http://localhost:5000

# API (DMZ)
curl http://localhost:5001

# Admin (Admin)
curl http://localhost:5002

# Monitoring
open http://localhost:9090

# Bastion SSH
ssh root@localhost -p 2222
# Password : logistockadmin
```

---

## 📊 PORTS UTILISÉS

| Service | Port | Description |
|---------|------|-------------|
| **LocalStack** | 4566 | AWS API Gateway |
| **Keycloak** | 8080 | OAuth2/OIDC Provider |
| **OPA** | 8181 | Policy Engine |
| **Vault** | 8200 | Secrets Management |
| **OAuth2 Proxy** | 4180 | Identity-Aware Proxy |
| **LogiStock Web** | 5000 | Frontend |
| **LogiStock API** | 5001 | Backend API |
| **LogiStock Admin** | 5002 | Admin Panel |
| **Prometheus** | 9090 | Monitoring |
| **Bastion SSH** | 2222 | SSH Access |
| **Adminer** | 8081 | PostgreSQL UI |

---

## 🛠️ TROUBLESHOOTING

### **Conteneur ne démarre pas**

```bash
# Logs du conteneur
docker-compose -f docker-compose-iam.yml logs keycloak

# Redémarrer un service
docker-compose -f docker-compose-iam.yml restart keycloak
```

### **LocalStack ne répond pas**

```bash
# Vérifier santé
curl http://localhost:4566/_localstack/health

# Relancer init
./init-scripts/init-localstack.sh
```

### **Keycloak erreur DB**

```bash
# Vérifier PostgreSQL
docker-compose -f docker-compose-iam.yml logs postgres-iam

# Recréer DB
docker-compose -f docker-compose-iam.yml down -v
docker-compose -f docker-compose-iam.yml up -d
```

### **Reset complet**

```bash
# ATTENTION : Supprime toutes les données
docker-compose -f docker-compose-iam.yml down -v
docker-compose -f docker-compose-iam.yml up -d

# Relancer init scripts
./init-scripts/init-localstack.sh
./init-scripts/init-keycloak.sh
./init-scripts/init-vault.sh
```

---

## 📋 CHECKLIST VALIDATION PHASE 1

- [ ] ✅ 16 conteneurs running
- [ ] ✅ LocalStack : 6 users, 5 groups, 3 roles AWS IAM
- [ ] ✅ Keycloak : 6 users, 5 groups, 4 clients OAuth2
- [ ] ✅ OPA : 3 politiques chargées (RBAC, ABAC, Zero Trust)
- [ ] ✅ Vault : 2 rôles SSH, policies configurées
- [ ] ✅ Services LogiStock accessibles (5000, 5001, 5002)
- [ ] ✅ OAuth2 token obtenu depuis Keycloak
- [ ] ✅ Test RBAC OPA réussi
- [ ] ✅ Test JIT SSH Vault réussi

---

## 🚀 PROCHAINE ÉTAPE

**Phase 2 : Guide HTML (Structure + CSS)**

Une fois l'infrastructure validée, on passe à la création du guide pédagogique enrichi format LogiStock S3.

---

**Questions ? Problèmes ? Vérifie les logs avec `docker-compose logs <service>`**
