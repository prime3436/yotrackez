# 🥗 YOTRACKEZ

A nutrition tracking app I built because I got tired of manually logging food. Point your camera at what you're eating and it figures out the calories and macros for you. No subscriptions, no sign-ups, works offline.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What it does

- 📷 **Scan food with your camera** — it recognizes what you're eating using an on-device ML model (so no images leave your phone)
- 🔢 **Tracks your macros** — calories, protein, carbs, fats, fiber — all pulled from the USDA food database
- 💧 **Water intake tracker** — set a daily goal and log glasses throughout the day
- 🔥 **Streaks** — keeps track of your daily logging streak so you stay consistent
- 📊 **Dashboard** — see everything at a glance, daily progress, weekly history, the works
- 🔍 **Manual food search** — if scanning doesn't work, just search by name

Everything runs offline. No cloud, no API costs, no privacy concerns.

---

## Tech stuff

Built with **Flutter** so it runs on Android and iOS from the same codebase. The food recognition uses **MobileNet V2** running directly on-device — inference takes under 200ms which feels instant. Nutrition data comes from the **USDA FoodData Central** dataset bundled into a local SQLite database.

---

## Running it locally

```bash
git clone https://github.com/prime3436/yotrackez.git
cd yotrackez
flutter pub get
flutter run
```

You'll need Flutter installed. Connect a device or start an emulator and it should just work.

---

## Project layout

```
lib/
├── models/      # data models, nutrition calculations
├── screens/     # all the app screens
├── services/    # ML classifier, food lookup, local storage
├── theme/       # colors, typography, dark theme
├── widgets/     # reusable UI components
└── main.dart    # entry point
```

---

Built by **Mohan Sai** — [@prime3436](https://github.com/prime3436)
