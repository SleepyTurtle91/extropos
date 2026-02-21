# Backend Flavor - Flutter Web Quick Start

This document explains how to run and test the Backend flavor of FlutterPOS on the web (Appwrite backend).

## Goals

- Run Backend flavor as a Flutter web app (local web server or build for production).

- Use Appwrite as the backend service (API endpoint + project ID). The `AppwriteService` reads endpoint/project from local preferences.

## Files added/changed

- `lib/main_backend_web.dart` — new web entrypoint tailored for web (skips native-only initializations)

- `lib/services/appwrite_service.dart` — Appwrite SDK wrapper for web/backend flavor

- `lib/screens/appwrite_settings_screen.dart` — UI to configure Appwrite endpoint + project ID

- `pubspec.yaml` — added `appwrite` dependency

## Local development (web)

1. Ensure you have Appwrite running (self-hosted or cloud). Note endpoint and project ID.
2. Configure Appwrite in the app (once running locally) using the Appwrite settings screen.

Run locally (development):

```bash

# Run the backend as a web app using the web entrypoint

flutter run -d chrome lib/main_backend_web.dart
```text

Build release (web):

```bash
flutter build web --release -t lib/main_backend_web.dart

# Output will be in build/web

```text


## Appwrite quick configuration


- Open Appwrite console → create project → copy Project ID

- Create API key (or use public guests if you prefer no key) and copy endpoint

- Open the Backend web app → Settings → Appwrite Integration and enter the values


### Quick test: hardcoded client + ping button


- For fast local verification, the repo contains a small, hardcoded Appwrite test client using the project details used by the team. See `lib/config/environment.dart` for the values (project id + endpoint) and `lib/services/appwrite_client.dart` for the exported `appwriteClient` and `pingAppwrite()` helper.

- The Backend home screen also has a convenient `Send a ping` button (top-right Cloud/Sync card) — click it to test connectivity with the Appwrite endpoint. The UI will show a SnackBar indicating success or failure.


## Notes & Limitations


- Not all backend desktop-only features are supported on web (e.g., direct SQLite file access, native window management). This entrypoint is intentionally conservative and designed to use cloud services like Appwrite where possible.

- Some features relying on local native integrations (printer bindings, low-level file access) will not work in the web build.


## Next steps


- Add Appwrite-specific services (collections, functions) for categories/products management.

- Add secure server-side Appwrite functions for admin operations when needed.
