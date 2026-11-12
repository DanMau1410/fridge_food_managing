# Fridge Food Managing

Personal app to manage the food stored in the fridge, so you can plan your cooking and not let food go bad.

## Status

Early stage. The app currently shows an empty "My Fridge" screen (`lib/main.dart`); inventory, expiry tracking and recipe suggestions are still to be built.

## Tech stack

- Flutter (Dart SDK `^3.13.5`), targeting Android, iOS, web, Windows, macOS and Linux
- Lints: `flutter_lints` (see `analysis_options.yaml`)

## Project layout

- `lib/` – application code (entry point: `lib/main.dart`)
- `test/` – widget tests
- `Dockerfile`, `docker-compose.yml` – containerized web/Linux workflow
- `android/ ios/ web/ windows/ macos/ linux/` – platform runners

## Running locally

```bash
flutter pub get
flutter run
flutter analyze && flutter test
```

## Docker

- Dev server (web): `docker compose up dev` → http://localhost:8080
- Release web build with nginx: `docker compose up --build web` → http://localhost:8081
- Analyze + tests: `docker compose run --rm test`

Containers cover web/Linux-side tooling only; iOS/macOS builds need a Mac and Windows desktop builds need Windows. The Docker image pins Flutter via the `FLUTTER_VERSION` build arg.

## Branches

`main` is the stable branch; day-to-day work happens on `dev`.
