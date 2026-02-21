# Key Generator - Quick Start Guide

## What is the Key Generator?

A dedicated app for generating and validating FlutterPOS license keys offline.

---

## Quick Build

```bash

# Debug build

./build_flavors.sh keygen debug


# Release build

./build_flavors.sh keygen release

```text

---


## Installation


**Android**:

1. Build APK: `./build_flavors.sh keygen release`
2. Install: `app-keygenapp-release.apk`

**Desktop (Windows/Linux/macOS)**:

1. Run directly: `flutter run -d windows --flavor keygenApp`
2. Or build: `flutter build windows --flavor keygenApp`

---


## Generate Keys



### 1-Month Trial Key


1. Select **1 Month** 🕐

2. Choose number of keys (1-100)
3. Click **Generate Keys**
4. Copy from list


### 3-Month Trial Key


1. Select **3 Months** 📅

2. Choose number of keys
3. Click **Generate Keys**
4. Copy from list


### Lifetime Key


1. Select **Lifetime** ♾️

2. Choose number of keys
3. Click **Generate Keys**
4. Copy from list

---


## Validate Keys


1. Paste key in validation field
2. Click **Validate Key**
3. View results:

   - ✅ Valid: Shows type, expiry, days remaining

   - ❌ Invalid: Shows error

---


## Key Format



```text
EXTRO-XXXX-XXXX-XXXX-XXXX

```text

**Example Keys**:


- Trial 1M: `EXTRO-1MTR-9F2A-0000-X7Y9`

- Trial 3M: `EXTRO-3MTR-A1B3-0000-K2M5`

- Lifetime: `EXTRO-LIFE-LIFE-0000-P8Q4`

---


## Copy Keys


**Single Key**: Click copy icon ⎘ next to key

**All Keys**: Click "Copy All" button at top

**Clipboard Format**:


```text
EXTRO-1MTR-9F2A-0000-X7Y9
EXTRO-1MTR-9F2A-A1B2-K3M4
EXTRO-1MTR-9F2A-C5D6-L7N8

```text

---


## Use in POS


1. Generate key in Key Generator app
2. Copy key to clipboard
3. Open POS app
4. Navigate to Activation screen
5. Paste key
6. Click Activate
7. POS validates and activates

---


## License Types


| Type | Duration | Use Case |
|------|----------|----------|
| 1 Month Trial | 30 days | Testing, demos |
| 3 Month Trial | 90 days | Extended evaluation |
| Lifetime | Unlimited | Paid customers |

---


## Batch Generation


Generate multiple keys at once:

1. Select license type
2. Set number: **1, 5, 10, 25, 50, or 100**
3. Click Generate
4. All keys appear in list
5. Use "Copy All" to get all keys

**Use Cases**:


- Distribute to resellers (10-50 keys)

- Customer promotions (5-25 keys)

- Trial programs (1-10 keys)

---


## Security Best Practices


✅ **DO**:


- Keep generator app secure

- Record generated keys

- Use lifetime for paid customers

- Validate suspicious keys

❌ **DON'T**:


- Share generator with customers

- Distribute publicly

- Reuse same key everywhere

- Hardcode keys in POS

---


## Troubleshooting



### Key Won't Validate


**Check**:


- Format: `EXTRO-XXXX-XXXX-XXXX-XXXX`

- No extra spaces

- Not expired (for trials)

- Copied correctly


### Can't Generate Keys


**Check**:


- License type selected

- Number of keys set

- App has permissions


### Build Failed


**Solutions**:


```bash

# Clean and rebuild

flutter clean
flutter pub get
./build_flavors.sh keygen debug

```text

---


## Technical Info


**Package**: `com.extrotarget.extropos.keygen`  
**Entry Point**: `lib/main_keygen.dart`  
**Key Logic**: `lib/services/license_key_generator.dart`  
**UI**: `lib/screens/keygen_home_screen.dart`

**Security**: HMAC-SHA256 checksums  
**Validation**: Offline, no internet required  

---


## Complete Documentation


See `docs/KEYGEN_FLAVOR_GUIDE.md` for:


- Detailed API reference

- Security details

- Integration guide

- Advanced features

---

**Quick Reference**:


- Build: `./build_flavors.sh keygen release`

- Format: `EXTRO-XXXX-XXXX-XXXX-XXXX`

- Types: 1MTR (30d), 3MTR (90d), LIFE (∞)

- No activation needed for generator itself
