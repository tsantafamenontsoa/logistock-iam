#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# LOGISTOCK IAM WORKSHOP - FAST INITIALIZATION
# All 3 services initialized in ~2 minutes
# ═══════════════════════════════════════════════════════════════

set -e

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     LOGISTOCK IAM WORKSHOP - FAST INITIALIZATION           ║"
echo "║            (LocalStack + Keycloak + Vault)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if scripts exist
if [ ! -f init-scripts/init-localstack-FAST.sh ]; then
  echo "❌ init-scripts/init-localstack-FAST.sh not found"
  echo "   Please copy the FAST init scripts to init-scripts/"
  exit 1
fi

# Start time
START=$(date +%s)

# 1. LocalStack
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/3: LocalStack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x init-scripts/init-localstack-FAST.sh
./init-scripts/init-localstack-FAST.sh

# 2. Keycloak
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/3: Keycloak"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x init-scripts/init-keycloak-FAST.sh
./init-scripts/init-keycloak-FAST.sh

# 3. Vault
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/3: Vault"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chmod +x init-scripts/init-vault-FAST.sh
./init-scripts/init-vault-FAST.sh

# End time
END=$(date +%s)
DURATION=$((END - START))

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║               ✅ INITIALIZATION COMPLETE!                  ║"
echo "║                   Duration: ${DURATION}s                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🎯 Ready for TPs!"
echo ""
echo "Services:"
echo "  • LocalStack   : http://localhost:4566"
echo "  • Keycloak     : http://localhost:8080  (admin/logistockadmin)"
echo "  • Vault        : http://localhost:8200  (token: root)"
echo "  • OPA          : http://localhost:8181"
echo ""
echo "📖 Open guide: logistock-iam-GUIDE-COMPLET.html"
echo ""
