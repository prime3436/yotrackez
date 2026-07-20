# YOTRACKEZ v2.0 — Task Checklist

## Phase 1: Meal Tracking & History
- [ ] Add dependencies (`sqflite`, `intl`, `path`)
- [ ] Create `MealEntry` model
- [ ] Create `UserSettings` model
- [ ] Create `MealDbService` (SQLite storage)
- [ ] Create `SettingsService` (calorie limit, gender)
- [ ] Update `ResultScreen` — add "Add to My Day" button
- [ ] Create `MealHistoryScreen` — daily timeline
- [ ] Update `HomeScreen` — add bottom navigation bar
- [ ] Add calorie limit progress bar to home screen
- [ ] Wire up navigation routes

## Phase 2: Anime Avatar System
- [ ] Generate avatar images (male/female × 5 states = 10 images)
- [ ] Create `AvatarWidget` with animated transitions
- [ ] Create `AvatarScreen` with stats overlay
- [ ] First-launch gender selection dialog
- [ ] Integrate avatar with daily calorie data
- [ ] Show avatar on home screen

## Phase 3: Step Counter
- [ ] Add `pedometer_2` dependency
- [ ] Create `StepCounterService`
- [ ] Create `StepCounterCard` widget
- [ ] Add Android permission for ACTIVITY_RECOGNITION
- [ ] Show steps on home screen
- [ ] Calculate calories burned from steps
- [ ] Update avatar based on net calories

## Phase 4: Build & Deploy
- [ ] Build release APK
- [ ] Test on Android
- [ ] Redeploy web to Firebase
- [ ] Update walkthrough
