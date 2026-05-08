#!/usr/bin/env bash
# MyVoyage initial setup
# Führt die Schritte aus, die nach dem ersten Klonen nötig sind.

set -e

echo "🛫 MyVoyage Setup"
echo ""

# Node-Version prüfen
required_major=20
node_major=$(node -v | sed 's/v//;s/\..*//')
if [ "$node_major" -lt "$required_major" ]; then
  echo "❌ Node $required_major+ wird benötigt (gefunden: v$node_major)"
  echo "   Installiere von https://nodejs.org oder via nvm"
  exit 1
fi
echo "✅ Node v$node_major"

# EAS CLI prüfen
if ! command -v eas &> /dev/null; then
  echo "📦 Installiere EAS CLI global..."
  npm install -g eas-cli
fi
echo "✅ EAS CLI $(eas --version)"

# Dependencies
echo ""
echo "📦 Installiere Dependencies..."
npm install

echo ""
echo "✨ Setup fertig!"
echo ""
echo "Nächste Schritte:"
echo "  1. eas login                              # Bei Expo einloggen"
echo "  2. eas init                                # Projekt mit EAS verknüpfen"
echo "  3. eas device:create                       # iPhone registrieren"
echo "  4. eas build -p ios --profile development  # Dev-Build erzeugen"
echo "  5. npm start                                # Metro starten"
echo ""
