# MyVoyage

Native iOS-App (SwiftUI) — Reiseplaner-Klickdummy.

Bundle Identifier: `hoepker-consult.MyVoyage`
Apple Team: `S4UB6HE54Y`
Mindestziel: iOS 17

## Setup

1. Xcode 26+ installiert
2. Projekt öffnen: `open MyVoyage.xcodeproj`
3. Schema "MyVoyage" wählen, Ziel: iPhone-Simulator oder echtes Gerät
4. ⌘R zum Starten

## TestFlight-Build

1. In Xcode: Schema **MyVoyage** → Ziel **Any iOS Device (arm64)**
2. **Product → Archive** (5–15 min)
3. Im Organizer: **Distribute App → App Store Connect → Upload**
4. App Store Connect: TestFlight → Build dem Tester-Set zuweisen

Vor jedem Upload **Build-Number** in den Target-Settings hochzählen, sonst rejectet Apple.

## Datenschutz

`privacy.html` für die Privacy-URL hosten (z.B. `hoepker.de/privacy/myvoyage`).
URL in App Store Connect → App Privacy eintragen.
