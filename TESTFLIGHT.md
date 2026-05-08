# 🛫 MyVoyage → TestFlight (Weg B: Lokal mit Xcode)

Schritt-für-Schritt-Anleitung. Geht in dieser Reihenfolge vor – jeder Schritt baut auf dem vorigen auf. Hak ab, was erledigt ist.

## A. Vorbereitung (15 Min, einmalig)

- [ ] **A1.** Repo klonen / ZIP entpacken nach `~/Documents/Projekte/MyVoyage`
- [ ] **A2.** `cd ~/Documents/Projekte/MyVoyage`
- [ ] **A3.** `git init && git remote add origin git@github.com:Hoepker/MyVoyage.git`
- [ ] **A4.** `git add . && git commit -m "Initial scaffold"`
- [ ] **A5.** `git push -u origin main`
- [ ] **A6.** `npm install` (dauert 2-3 Min)

## B. Apple-Side Setup (15 Min, einmalig)

- [ ] **B1.** Bundle-ID registrieren: [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → **App IDs** → **App** → Description: `MyVoyage`, Bundle ID: `hoepker-consult.MyVoyage` (Explicit), keine Capabilities → **Continue** → **Register**
- [ ] **B2.** App Store Connect Eintrag: [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App** mit:
    - Platform: iOS
    - Name: MyVoyage
    - Primary Language: German
    - Bundle ID: `hoepker-consult.MyVoyage` (aus Dropdown)
    - SKU: `MYVOYAGE001`
    - User Access: Full Access
- [ ] **B3.** Datenschutzerklärung hosten – `privacy.html` aus dem Repo nehmen, auf eigene Domain laden (z.B. `https://hoepker.de/privacy/myvoyage` oder bei MyImmoPilot dazu). URL merken!
- [ ] **B4.** App Store Connect → MyVoyage → **App Privacy** → URL aus B3 eintragen
- [ ] **B5.** App Store Connect → MyVoyage → **Age Rating** → Fragebogen ausfüllen → 4+

## C. Lokal builden (45 Min, davon 30 Min Wartezeit)

- [ ] **C1.** `bash scripts/preflight.sh` – muss komplett grün durchgehen
- [ ] **C2.** `npx expo prebuild --platform ios` (3-5 Min, installiert auch CocoaPods)
- [ ] **C3.** `open ios/MyVoyage.xcworkspace` (achte auf `.xcworkspace`, nicht `.xcodeproj`!)
- [ ] **C4.** In Xcode: blaues Projekt-Icon links → **Signing & Capabilities** → ✅ "Automatically manage signing", Team: "Christian Hoepker"
    - Falls Fehler: Xcode → Settings → Accounts → prüfen, dass deine Apple ID mit dem Team verbunden ist
- [ ] **C5.** Toolbar oben: Schema-Selector → **Any iOS Device (arm64)** wählen (NICHT Simulator!)
- [ ] **C6.** Menü **Product** → **Archive** (5-15 Min Build-Zeit)
- [ ] **C7.** Wenn fertig: Organizer öffnet sich automatisch (sonst: Window → Organizer → Tab Archives)

## D. Hochladen zu TestFlight (15 Min)

- [ ] **D1.** Im Organizer: dein Archive auswählen → **Distribute App**
- [ ] **D2.** **App Store Connect** → **Next**
- [ ] **D3.** **Upload** → **Next**
- [ ] **D4.** Distribution Options: alles Default → **Next**
- [ ] **D5.** Re-sign: "Automatically manage signing" → **Next**
- [ ] **D6.** Review → **Upload** (2-10 Min)
- [ ] **D7.** Auf [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → MyVoyage → **TestFlight** → Build erscheint mit Status "Processing" (10-30 Min) → "Ready to Test"
- [ ] **D8.** Falls "Missing Compliance" angezeigt wird: klick drauf → "Does your app use encryption?" → **No** (haben wir in app.json schon gesetzt, ist nur Doppel-Bestätigung)

## E. Tester einladen (5 Min)

### Internal Testing (instant, max 100 Tester aus deinem Team)

- [ ] **E1.** TestFlight → **Internal Testing** → **+** Gruppe erstellen → Name z.B. "Family"
- [ ] **E2.** Build der Gruppe zuweisen
- [ ] **E3.** Tester per E-Mail einladen (müssen Apple ID haben, kein Developer-Account nötig wenn sie schon im Team sind)

### External Testing (max 10.000, mit Public Link)

- [ ] **E4.** TestFlight → **External Testing** → Gruppe erstellen → "Public Link" aktivieren
- [ ] **E5.** **Beim allerersten externen Build** muss Apple kurz reviewen (~24h, sehr leichtgewichtig)
- [ ] **E6.** Public Link an Tester schicken – die installieren TestFlight-App, klicken Link, Code wird automatisch eingegeben

## F. Tester-Onboarding

Was deine Tester machen müssen:
1. TestFlight-App aus dem App Store installieren
2. Einladungs-Mail öffnen oder Public Link tippen
3. "Accept" → MyVoyage installiert sich automatisch
4. App testen, Feedback direkt aus der TestFlight-App abschicken

## Häufige Stolpersteine

| Problem | Lösung |
|---------|--------|
| `Sandbox: rsync deny` beim Archive | Build Settings → `ENABLE_USER_SCRIPT_SANDBOXING` → **NO** |
| `Multiple commands produce` | Cmd+Shift+K (Clean Build Folder), neu archivieren |
| Hermes / Reanimated Fehler | `cd ios && pod install --repo-update && cd ..` |
| `Signing requires a development team` | Auch für Pods-Targets Team setzen, oder einmal Cmd+Shift+K |
| `ITMS-90683: Missing Purpose String` | In `app.json` unter `ios.infoPlist` die fehlende `NS...UsageDescription` ergänzen |
| Build erscheint nicht in TestFlight | 10-30 Min warten – Apple's "Processing" dauert |

## Folgende Builds (jeder weitere TestFlight-Update)

Nach dem ersten Mal sind das nur noch 3 Befehle:

```bash
# 1. Build-Number in app.json hochzählen (oder ios/MyVoyage/Info.plist)
# 2. Falls native Änderungen:
npx expo prebuild --platform ios --clean
# 3. In Xcode: Product → Archive → Distribute → Upload
```

Die `version` in `app.json` musst du nur erhöhen, wenn du eine neue marketing-version willst (1.0.0 → 1.0.1). Die `buildNumber` musst du **bei jedem TestFlight-Upload** erhöhen, sonst rejectet Apple.
