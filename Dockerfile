# syntax=docker/dockerfile:1

ARG FLUTTER_VERSION=3.47.6

# ---- Base: Flutter SDK (Linux, web and Android-capable toolchain base) ----
FROM ubuntu:24.04 AS flutter-base
ARG FLUTTER_VERSION
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/root/.pub-cache
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME} \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

# ---- Dev: interactive environment (analyze, test, run web-server) ----
FROM flutter-base AS dev
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "8080"]

# ---- Build: release web bundle ----
FROM flutter-base AS build
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# ---- Runtime: serve the web app with nginx ----
FROM nginx:1.27-alpine AS web
COPY --from=build /app/build/web /usr/share/nginx/html
RUN printf 'server {\n  listen 80;\n  root /usr/share/nginx/html;\n  location / { try_files $uri $uri/ /index.html; }\n}\n' > /etc/nginx/conf.d/default.conf
EXPOSE 80
