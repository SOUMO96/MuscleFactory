# IronPulse

A cross-platform gym & workout tracking app skeleton built with Flutter.

## Status

This is a **UI/navigation skeleton** — screens are wired together and styled with
a cohesive dark, high-energy theme, using static placeholder data. No backend,
state management, or persistence is connected yet; that comes next.

## Structure

```
lib/
  core/
    theme/        # colors, text styles, ThemeData
    widgets/       # reusable UI building blocks (buttons, cards, headers)
    navigation/    # bottom-nav shell (MainShell)
  features/
    splash/        # animated splash / app boot screen
    onboarding/     # 3-page swipeable intro
    auth/           # login / sign up
    home/           # dashboard (today's stats, featured workout, recs)
    workouts/       # workout library + detail screen
    progress/       # charts, stats grid, achievements
    profile/        # profile + settings menu
  shared/
    models/         # plain data models (Workout, ExerciseItem)
    data/           # static dummy data used across screens
main.dart
```

## Getting started

```bash
flutter pub get
flutter run
```

## Design language

- Deep near-black backgrounds with elevated card surfaces
- Neon lime (`#CCFF00`) as the primary energy accent, orange as secondary
- Bold, condensed headings (Manrope) for a gym/athletic feel
- Rounded 16–20px corners, soft glow shadows on primary actions
- Bottom nav with a center "quick start" floating action button
