# yotrackez 🥗

so basically i got tired of manually searching every food item i eat just to track my calories. built this app to fix that.

point your camera at food, it tells you the macros. that's it.

---

## what's in it

- scan food with your camera and it figures out what it is
- shows you calories, protein, carbs, fats, fiber right away
- track how much water you drank today
- daily streaks so you don't forget to log
- full dashboard with your day's progress
- search food manually if the camera gets it wrong

works offline. no account needed. nothing leaves your phone.

---

## how to run it

```bash
git clone https://github.com/prime3436/yotrackez.git
cd yotrackez
flutter pub get
flutter run
```

need flutter installed, connect a phone or start an emulator and you're good.

---

## built with

- Flutter (Android + iOS from one codebase)
- MobileNet V2 for the food recognition — runs on-device, super fast
- USDA food database for the nutrition data, stored locally in SQLite

---

made by Mohan Sai — [@prime3436](https://github.com/prime3436)
