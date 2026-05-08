#!/usr/bin/env bash
# Pre-Flight Check für MyVoyage
# Prüft, ob alle Voraussetzungen für `npx expo prebuild --platform ios` erfüllt sind.

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((errors++)); }

echo "🛫 MyVoyage Pre-Flight Check"
echo "============================"

errors=0

# -- Node Version --
if command -v node &>/dev/null; then
  node_major=$(node -v | sed 's/v//;s/\..*//')
  if [ "$node_major" -ge 20 ]; then
    ok "Node $(node -v)"
  else
    fail "Node $node_major.x ist zu alt – brauche v20 oder neuer"
  fi
else
  fail "Node.js nicht gefunden"
fi

# -- Xcode (nur Mac) --
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v xcodebuild &>/dev/null; then
    xcode_version=$(xcodebuild -version | head -1 | awk '{print $2}')
    xcode_major=$(echo "$xcode_version" | cut -d. -f1)
    if [ "$xcode_major" -ge 16 ]; then
      ok "Xcode $xcode_version"
    else
      warn "Xcode $xcode_version – iOS 17 SDK kann fehlen, lieber updaten"
    fi
  else
    fail "Xcode nicht installiert (App Store: 'Xcode')"
  fi

  # -- CocoaPods --
  if command -v pod &>/dev/null; then
    ok "CocoaPods $(pod --version)"
  else
    fail "CocoaPods nicht installiert: 'brew install cocoapods'"
  fi
fi

# -- app.json Config --
if [ -f app.json ]; then
  if grep -q '"appleTeamId": "[A-Z0-9]\{10\}"' app.json; then
    ok "Apple Team ID gesetzt"
  else
    fail "appleTeamId fehlt oder ist Platzhalter in app.json"
  fi
  if grep -q '"bundleIdentifier"' app.json; then
    ok "Bundle Identifier gesetzt: $(grep bundleIdentifier app.json | sed 's/.*: "\(.*\)".*/\1/')"
  else
    fail "bundleIdentifier fehlt in app.json"
  fi
else
  fail "app.json fehlt"
fi

# -- Assets --
for asset in icon.png splash.png adaptive-icon.png favicon.png; do
  if [ -f "assets/$asset" ]; then
    ok "assets/$asset"
  else
    fail "assets/$asset fehlt"
  fi
done

# -- node_modules --
if [ -d node_modules ]; then
  ok "node_modules installiert"
else
  warn "node_modules fehlt – führe 'npm install' aus"
fi

echo ""
if [ $errors -eq 0 ]; then
  echo -e "${GREEN}Alles bereit!${NC} Du kannst jetzt prebuild laufen lassen:"
  echo ""
  echo "  npx expo prebuild --platform ios"
  echo "  open ios/MyVoyage.xcworkspace"
  echo ""
  exit 0
else
  echo -e "${RED}$errors Probleme gefunden.${NC} Behebe sie und führe das Skript erneut aus."
  exit 1
fi
