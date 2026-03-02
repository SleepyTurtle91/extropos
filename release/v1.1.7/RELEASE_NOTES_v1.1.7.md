# ExtroPOS v1.1.7 (2026-03-03)

## Fixed

- Payment Processing: fixed `No active payment methods`
  - Updated `payment_methods` table schema to use `status` and `is_default`
  - Added default active methods seeding (Cash default, Credit Card, Debit Card, E-Wallet)

- Printer Management screen: restored non-working UI
  - Re-implemented split-screen UI sections (header, left list panel, right details/actions panel)
  - Removed duplicate in-class UI methods conflicting with part files
  - Fixed popup action handling and paper-size rendering

- Release build blocker: fixed stale imports in `training_mode_service.dart`
  - `business_info_model.dart`
  - `enum_models.dart`

## Verification

- Release APK built successfully
- APK installed successfully on Android device via ADB
- Changed files pass diagnostics

## Artifact

- `FlutterPOS-v1.1.7-20260303.apk`
