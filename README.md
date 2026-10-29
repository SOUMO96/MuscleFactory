# Muscle Factory

A cross-platform gym and workout tracking app built with **Flutter** and **Supabase**. Log workouts set by set, follow or import a training plan, track meals against a real food database (with Indian dishes), book gym classes, and watch your progress over time.

![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Postgres%20%2B%20Auth-3ECF8E?logo=supabase&logoColor=white)
![Platforms](https://img.shields.io/badge/Tested-Android%20%7C%20Web-informational)

> **How it was built:** a human-led pair-programming project. The owner set the requirements, picked the design and product direction, and tested every feature on a real phone and in the browser. [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding assistant) wrote and reviewed much of the code alongside them, and commits it contributed to carry a `Co-Authored-By` trailer.

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Database and backend](#database-and-backend)
- [Security](#security)
- [Getting started](#getting-started)
- [Build and deploy](#build-and-deploy)
- [Testing and quality](#testing-and-quality)
- [Design system](#design-system)
- [Development history](#development-history)
- [Known limitations](#known-limitations)

---

## Features

### Accounts and onboarding
- **Email sign-up with a 6-digit verification code**, plus **Google sign-in**.
- **Two-step login:** password, then a one-time code sent to your email.
- Password reset by email link, with a screen to set the new password.
- Strong-password policy (8+ characters, upper and lower case, a digit) enforced on both client and server.
- A one-time **onboarding survey** after first sign-in: name, age, gender, height, weight, goal (gain / lose / stay fit), target weight and duration, and training days per week.
- Sessions persist, so returning users go straight to the app. A retry screen appears if the server can't be reached, instead of guessing.

### Home
- Today's workout from your active plan, with a one-tap **Start workout**.
- Weekly grid showing which days you trained, a day streak, and 7-day volume and hours.
- Quick actions: **log weight**, **water** (+250 ml), **add meal**, and a standalone **rest/interval timer**.
- Notifications screen.

### Train
- **Plans**
  - **Use our plan:** a rule-based pick from pre-authored templates (hypertrophy, conditioning, full body) based on your goal and days per week.
  - **Build my own:** choose training days and add exercises with sets and reps from the library.
  - **Import my plan:** paste a CSV, or upload a **.csv, .xlsx or .pdf** file. A built-in heuristic parser (no external AI API) reads days, exercises and sets/reps, fuzzy-matches names to the exercise catalog, removes duplicates within a day, and can fold the plan into the number of days you want.
  - **Delete plan** with a confirmation step. Logged workouts stay in your history.
- **Active workout:** a real set logger (weight and reps per set), a rest timer using your preferred rest time, and session save/discard.
- **Library:** a searchable, filterable catalog of **70 exercises** across legs, back, arms, shoulders, chest, cardio and core.
- **History:** past sessions, each opening to its logged sets.

### Nutrition
- **Food search** against a local catalog of **~50 Indian dishes and staples** (roti, dal, biryani, paneer dishes, idli, dosa and more) plus live **USDA FoodData Central** results.
- Enter a quantity in grams and get **calories, protein, carbs, fat, fiber, sugar and sodium** recalculated as you type.
- **Manual entry** when you'd rather type calories and macros yourself.
- One simple daily food list, daily progress bars, **favorites**, **copy yesterday's food**, edit or delete entries, and a 30-day **history**.
- Water tracking with a daily goal.

### Classes
- A weekly class schedule that extends itself automatically.
- **Book, cancel and waitlist.** Capacity is enforced in the database, not just the UI.

### Progress
- Charts (week / month / year) of training volume built from your logged sets.
- Personal records and workout counts calculated from real data.

### Profile and settings
- Personal information, goals and targets, achievements (first workout, streaks, workout counts, PRs), and a **membership QR pass**.
- **Appearance: light, dark or auto**, units (kg / lb), default rest timer and a workout-reminders preference.
- Help and support, and a privacy policy.

---

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart 3.3+) |
| Backend | Supabase: Postgres, Auth, Row Level Security, Realtime, Edge Functions |
| Hosting (web) | Firebase Hosting |
| Charts | `fl_chart` |
| Fonts | `google_fonts` (Archivo) |
| File import | `file_picker`, `excel`, `syncfusion_flutter_pdf` |
| Other | `qr_flutter` (membership pass), `url_launcher` |
| Food data | USDA FoodData Central, proxied through a Supabase Edge Function |

---

## Project structure

```
lib/
  main.dart
  supabase_options.dart        # Supabase URL + public publishable key
  core/
    navigation/                # bottom-nav shell and tab controller
    services/                  # Supabase-backed repositories + parsers
      auth_service.dart        user_repository.dart
      plan_repository.dart     workout_session_repository.dart
      exercise_repository.dart class_repository.dart
      nutrition_repository.dart food_repository.dart
      favorite_food_repository.dart water_repository.dart
      plan_text_parser.dart    file_text_extractor.dart   # plan import
    theme/                     # colors, text styles, light/dark theme
    widgets/                   # shared buttons, cards, headers
  features/
    splash/  onboarding/  auth/  survey/
    home/  train/  nutrition/  classes/
    progress/  profile/
  shared/
    models/                    # AppUser, WorkoutPlan, Food, NutritionEntry, ...
    data/plan_templates.dart   # rule-based plan templates
supabase/
  migrations/                  # the full database schema, in order
  functions/food-search/       # USDA proxy (Deno / TypeScript)
  templates/                   # email templates
  config.toml                  # auth and project configuration
test/
```

---

## Database and backend

All schema changes live in [`supabase/migrations`](supabase/migrations) and are applied in order.

| Migration | What it adds |
| --- | --- |
| `create_profiles` | `profiles` table, auto-created for each new user by a trigger |
| `add_training_features` | `exercises` (seeded), `workout_plans`, `plan_days`, `plan_exercises`, `workout_sessions`, `logged_sets`, `classes`, `class_bookings`, `nutrition_entries` |
| `add_water_logs` | `water_logs` |
| `recurring_class_schedule` | `class_templates` and `ensure_classes_through()`, so the schedule keeps itself populated |
| `lock_down_ensure_classes_through` | Restricts that function to signed-in users |
| `enforce_class_capacity` | A trigger that blocks bookings over capacity |
| `meal_nutrition_system` | `foods` (with seeded Indian dishes), `favorite_foods`, and `cache_usda_foods()` |
| `harden_nutrition_inputs` | Server-side validation and `CHECK` constraints on nutrition data |

**Edge Function `food-search`:** takes a search term, calls USDA FoodData Central with an API key kept on the server, normalises the nutrients per 100 g, and caches the results into `foods`. The key is never shipped in the app.

---

## Security

Security is enforced in Postgres, not just in the UI.

- **Row Level Security is on for every table.** Users can only read and write their own rows. Catalog tables (`exercises`, `foods`, `classes`) are read-only to clients.
- The Supabase key in the app is the **public publishable key**, which is safe to ship because RLS does the enforcement. The secret/service-role key is never in the client.
- **Password policy and secure password change** are enforced by the auth server.
- Privileged functions (`ensure_classes_through`, `cache_usda_foods`) are granted to **signed-in users only**, never to anonymous callers, and they validate their input.
- **Class capacity** is enforced by a database trigger.
- **Nutrition values are range-checked in the database** (calories, macros, quantity), so a modified client can't store negative or absurd numbers.
- The **USDA API key lives only in Edge Function secrets.** The SMTP password and Google OAuth secret are read from environment variables (`env(...)` in `config.toml`). `.gitignore` blocks `.env` files, keystores and `google-services.json`, so none of these get committed.
- Account-enumeration messages on sign-up were softened.
- Import is bounded: 15 MB file cap and a 200-row cap, so a bad file can't exhaust memory or flood the database.

This app has been through a manual security pass with live testing against its own backend. It has not had an independent professional audit.

---

## Getting started

### Prerequisites
- [Flutter](https://docs.flutter.dev/get-started/install) 3.19 or newer (Dart 3.3+)
- For Android: Android SDK with platform 36, and USB debugging on your phone
- **Windows only:** turn on **Developer Mode** (Settings → For developers). Flutter plugins need symlink support to build.
- [Supabase CLI](https://supabase.com/docs/guides/cli) if you want to run your own backend

### Run the app

```bash
git clone https://github.com/SOUMO96/MuscleFactory.git
cd MuscleFactory
flutter pub get

flutter run -d chrome        # web
flutter run -d <device-id>   # Android phone (see `flutter devices`)
```

The repo points at the author's Supabase project, so it runs as-is. To use **your own backend**:

1. Create a project at [supabase.com](https://supabase.com).
2. Put its URL and publishable key in [`lib/supabase_options.dart`](lib/supabase_options.dart). Never put the service-role key there.
3. Apply the schema:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
4. Push the auth settings (password policy, email OTP, templates):
   ```bash
   supabase config push
   ```
5. **Google sign-in (optional):** create a Google OAuth client, set its client ID in `supabase/config.toml`, and set the secret:
   ```bash
   supabase secrets set GOOGLE_OAUTH_CLIENT_SECRET=<secret>
   ```

### Enable live USDA food search (optional)

Without this, food search still works using the local catalog (including the Indian foods). The USDA lookup needs the Edge Function and a free API key from [fdc.nal.usda.gov](https://fdc.nal.usda.gov/api-key-signup.html):

```bash
supabase secrets set USDA_API_KEY=<your-key>
supabase functions deploy food-search
```

---

## Build and deploy

**Web, on Firebase Hosting**
```bash
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting --project <your-firebase-project-id>
```
[`firebase.json`](firebase.json) serves `build/web` and rewrites every route to `index.html`. Firebase is used for hosting only; auth and data are all Supabase. If you host it yourself, also set your site URL as `site_url` in `supabase/config.toml` so email links point to the right place.

**Android**
```bash
flutter build apk --release
```
Before publishing to the Play Store, change the placeholder `applicationId` (see [Known limitations](#known-limitations)) and set up release signing.

---

## Testing and quality

```bash
flutter analyze   # static analysis: reports no issues
flutter test      # one widget test (onboarding screen), passing
```

Features were also tested by hand on a real Android phone and in the browser, including edge cases (negative and oversized numbers, malformed import files) and the security checks above. Automated test coverage is currently thin: one widget test. Adding tests for the plan parser and the repositories is the most valuable next step.

---

## Design system

The "Modernist" look comes from a design handoff:

- **Archivo** typeface throughout
- One red accent: `#EC3013` (light) and `#F0391C` (dark)
- Sharp, zero-radius corners and 2 px rules instead of shadows
- Full **light and dark** themes, plus an **auto** mode that follows the device, switchable at runtime from Profile → Appearance

---

## Development history

How the project got to its current state:

1. **Foundation:** Flutter app shell, dark theme, onboarding, auth screens, bottom navigation.
2. **Backend move to Supabase:** replaced the initial Firebase Auth/Firestore setup with Supabase (Postgres, RLS, email OTP and Google sign-in). Firebase remains only for web hosting.
3. **Redesign:** rebuilt every screen to the Modernist design handoff, with real light/dark theming.
4. **Real data throughout:** replaced the original placeholder workout data with real tables, covering plans, exercises, workout sessions and logged sets, classes and bookings, nutrition and water.
5. **Train tab:** plan chooser (template / build / import), active workout logger with rest timer, exercise library, history with set-level detail.
6. **Stability fixes:** splash/routing and profile-loading reliability, a layout crash on Home, Android build setup (SDK, Gradle, plugin versions), theme switching across the whole app.
7. **Security pass:** live testing of auth and the database, then fixes: password policy, anonymous-RPC lockdown, class-capacity trigger, softened sign-up messages.
8. **Plan import:** CSV, Excel and PDF import with a self-contained heuristic parser, duplicate removal and day consolidation.
9. **Nutrition database:** USDA integration through an Edge Function, a seeded Indian food catalog, quantity-based calculation, favorites, copy-yesterday, history.
10. **Nutrition hardening:** database-level validation, inline error messages, safer file handling.
11. **Simplification:** removed meal-category grouping in favour of one daily food list; added plan deletion.

---

## Known limitations

- **Sign in with Apple is not implemented.** The button shows "not available yet". Google and email work.
- **Workout reminders** are saved as a preference, but the app does not send push notifications yet.
- **Membership QR** is a personal pass, with no door or turnstile integration.
- **Class schedule** is seeded and generated by the app, not synced from a gym-management system.
- **"Use our plan"** picks from pre-written templates by rule; it does not call an AI service.
- **Nutrition goals** (2200 kcal, 150 g protein, 250 g carbs, 70 g fat, 2 L water) are fixed reference targets, not personalised.
- **USDA search** needs the Edge Function deployed and an API key (see above); otherwise only the local catalog is searched.
- **Platforms:** developed and tested on Android and web. The iOS and Windows folders are Flutter scaffolding and have not been tested.
- **Android `applicationId`** is still the placeholder `com.example.ironpulse`. Change it before publishing.
- **Test coverage** is minimal (see above).
