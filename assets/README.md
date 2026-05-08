# Assets

Hier landen die Icons und Splash-Screen-Bilder.

Benötigte Dateien:

- `icon.png` — 1024×1024, App-Icon (PNG, kein Alpha-Kanal für iOS)
- `adaptive-icon.png` — 1024×1024, Android adaptive icon foreground
- `splash.png` — 1242×2436 oder 2048×2048, Splash-Screen
- `favicon.png` — 48×48, Web-Favicon

Bis du eigene Icons hast, kannst du Platzhalter generieren mit:

```bash
npx create-expo-app --template blank-typescript /tmp/expo-template
cp /tmp/expo-template/assets/* ./assets/
```

Oder direkt Anthropic-Image-Gen / dein eigenes Pilot-Branding (grün-zu-blau Verlauf passend zu MyScanPilot/MyOfficePilot/MyImmoPilot) verwenden.
