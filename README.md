# fridge_food_managing
Personal app to manage food stored in the fridge to optimize cooking and not let food go bad

## Docker

- Dev server (web): `docker compose up dev` → http://localhost:8080
- Release web build with nginx: `docker compose up --build web` → http://localhost:8081
- Analyze + tests: `docker compose run --rm test`

Containers cover web/Linux-side tooling only; iOS/macOS builds need a Mac and Windows desktop builds need Windows.
