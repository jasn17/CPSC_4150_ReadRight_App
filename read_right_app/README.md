## README.md
```md
# Solo 4 — Local Data Storage (Flutter)


## What the app stores and why
- **Items (title, note, isDone, createdAt)** in **SQLite** (sqflite). This satisfies the requirement to persist a list of at least 5 items and survive app restarts.
- **Theme preference (dark mode)** in **shared_preferences** as a simple key/value flag. This demonstrates user preferences saved across launches.


## Storage used
- Data: `sqflite` (SQLite) in `lib/data/db.dart`.
- Preferences: `shared_preferences` in `lib/prefs/theme_prefs.dart`.


## How to run
1. `flutter pub get`
2. `flutter run` (iOS Simulator, Android Emulator, or device)
3. Add items via **+**. Toggle done with checkbox. Edit/Delete via icons. Open drawer → toggle **Dark mode** to test prefs persistence.


## How to test persistence
- Add a few items. Close the app (or stop and re-run). The list should reload from SQLite in `initState()`.
- Toggle Dark mode in the drawer. Relaunch app — theme should be remembered via shared_preferences.


## Data format
- **SQLite table** `items` with columns: `id INTEGER PK`, `title TEXT`, `note TEXT?`, `is_done INTEGER(0/1)`, `created_at INTEGER(ms)`.
- **Prefs**: `pref_dark_mode: bool`.


## Edge case handled
- **Potential DB corruption or missing table**: `getAll()` wraps reads in try/catch and calls a **safe reset** to recreate the table, preventing crashes. App then continues with an empty list and shows a SnackBar on error.
- **Empty/first‑run**: Shows an empty state widget with guidance; buttons are disabled/enabled appropriately.


## Notes
- Code uses single quotes per course style.
- UI feedback via `SnackBar` on Save/Update/Delete/Clear and on errors.
- Separation of concerns: models in `data/`, prefs in `prefs/`, UI in `screens/` and `widgets/`.


## Optional extensions
- Add search and filtering.
- Migrate to Provider for state management.
- Add export/import JSON.
