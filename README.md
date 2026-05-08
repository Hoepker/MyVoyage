# MyVoyage

Mehretappiger Reiseplaner für iOS und Android. Reisen mit beliebig vielen Etappen (Flug, Zug, Mietwagen, Bus, Hotel) planen und direkt zu Buchungsportalen springen – mit korrekter Übergabe von Reisenden, Kinderaltern und Datum.

Native App mit [Expo](https://expo.dev) (SDK 55) und [React Native](https://reactnative.dev). TypeScript, Expo Router, AsyncStorage für Persistenz.

## Voraussetzungen

- **Node.js** 20 LTS oder neuer
- **Xcode** 16+ (für iOS-Builds, nur macOS)
- **CocoaPods** (`brew install cocoapods`)
- **Apple Developer Account** (für Builds auf physischen Devices)
- **EAS CLI**: `npm install -g eas-cli`

## Erste Schritte

```bash
# 1. Dependencies installieren
npm install

# 2. Bei Expo einloggen (einmalig)
eas login

# 3. Projekt mit EAS verknüpfen (einmalig)
eas init

# 4. Native Code generieren (Continuous Native Generation)
npx expo prebuild
```

## Development Build aufs iPhone bringen

Du brauchst einen **Development Build** der App auf deinem iPhone. Den installierst du einmal, danach reicht `npm start` und QR-Code scannen.

### Variante A: Build in der EAS-Cloud (einfachster Weg)

```bash
# iPhone in Xcode → Device Portal registrieren (einmalig pro Gerät)
eas device:create

# Dev-Build in der Cloud erzeugen + per QR/Link aufs iPhone laden
eas build --profile development --platform ios
```

Wenn der Build fertig ist (10–20 Min), bekommst du einen Install-Link. Auf dem iPhone öffnen, Profil installieren, App startet. Ab dann genügt:

```bash
npm start
```

Die App auf dem iPhone öffnen, QR-Code aus dem Terminal scannen, fertig.

### Variante B: Lokal über Xcode bauen

```bash
npx expo run:ios --device
```

iPhone per Kabel verbinden, Xcode signiert und installiert. Kostenlos, aber langsamer beim ersten Mal.

## Projektstruktur

```
MyVoyage/
├── app/                      # Expo Router Screens (file-based routing)
│   ├── _layout.tsx           # Root Layout, Theme, Stack
│   └── index.tsx             # Hauptscreen (Reiseplaner)
├── src/
│   ├── components/           # Wiederverwendbare UI-Komponenten
│   │   ├── SegmentCard.tsx   # Einzelne Etappen-Karte
│   │   ├── SummaryBar.tsx    # Statistik-Header
│   │   ├── Timeline.tsx      # Etappen-Liste
│   │   └── TravelersSelector.tsx
│   ├── constants/            # Theme, Transporttypen
│   ├── lib/                  # Pure Helper-Funktionen
│   │   ├── helpers.ts
│   │   └── portals.ts        # Buchungsportal-Deeplink-Builder
│   ├── state/                # Hooks für State-Management
│   │   └── useTrip.ts        # Trip-Store mit AsyncStorage
│   └── types/                # TypeScript-Domänenmodelle
├── assets/                   # Icons, Splash-Screen
├── app.json                  # Expo-Konfiguration
├── eas.json                  # Build-Profile für EAS
└── tsconfig.json
```

## Wichtige Befehle

| Befehl | Was es macht |
|---|---|
| `npm start` | Metro-Bundler starten, QR-Code für Dev-Build |
| `npm run ios` | Lokal auf iOS-Simulator starten |
| `npm run android` | Lokal auf Android-Emulator starten |
| `npm run typecheck` | TypeScript ohne Build prüfen |
| `npm run lint` | Code-Style prüfen |
| `npx expo prebuild --clean` | Native Ordner neu generieren (nach plugin/config-Änderung) |
| `eas build --profile development -p ios` | Cloud-Dev-Build für iPhone |
| `eas build --profile preview -p ios` | Ad-hoc Build für TestFlight-Ersatz |
| `eas build --profile production -p ios` | Store-Build |

## Konventionen

- **Pfad-Aliasse**: Imports nutzen `@/...` statt relativer Pfade. Konfiguriert in `tsconfig.json`.
- **Strict TypeScript**: `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride` sind aktiv.
- **Komponenten**: Funktionskomponenten mit Hooks, kein Class-Component-Code.
- **State**: Lokal so weit wie möglich. Globaler State über Custom Hooks (z.B. `useTrip`).
- **Styles**: `StyleSheet.create` pro Komponente. Theme-Tokens aus `src/constants`.
- **Persistenz**: AsyncStorage mit versionierten Keys (`@myvoyage/<scope>/v1`).

## Bundle-IDs

- iOS: `de.hoepker.myvoyage`
- Android: `de.hoepker.myvoyage`

Konsistent mit der MyPilot-Suite (MyScanPilot, MyOfficePilot, MyImmoPilot).

## Roadmap

- [x] Mehretappiger Reiseplaner (Prototyp-Port aus React)
- [x] Travelers-Sheet inkl. Kinderaltern
- [x] Buchungsportal-Deeplinks (Skyscanner, DB, FlixBus, Booking.com etc.)
- [x] Persistierung über AsyncStorage
- [ ] Mehrere Reisen verwalten (List-View, Trip-Switcher)
- [ ] Drag-and-drop zur Etappen-Sortierung
- [ ] Hin-/Rückreise (mit Checkout-Datum bei Hotels)
- [ ] iCal/PDF-Export der Reise
- [ ] Foto-Anhänge pro Etappe (mit on-device-Storage)
- [ ] Cross-App-Sync mit MyOfficePilot Calendar
- [ ] Dark/Light-Mode (aktuell nur Dark)
- [ ] Lokalisierung Englisch
