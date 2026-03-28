# Spetaka — Release Process

**Last updated:** 2026-03-05

This document covers the end-to-end release flow for Spetaka on the Google Play
Store: from initial keystore generation through the Internal → Closed → Production
track progression.

---

## 1. One-Time Setup: Upload Keystore

Perform this once. Store the resulting files securely (password manager / hardware vault).

```bash
# Generate the upload keystore
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=Spetaka Upload Key, OU=Mobile, O=Laurus, C=FR"

# The tool will prompt for storePassword and keyPassword — use strong, unique passwords.
```

Move `upload-keystore.jks` to `spetaka/android/upload-keystore.jks` (gitignored).

Create `spetaka/android/key.properties` (gitignored):
```properties
storePassword=<store_password>
keyPassword=<key_password>
keyAlias=upload
storeFile=../android/upload-keystore.jks
```

> **NEVER commit** `upload-keystore.jks` or `key.properties` to version control.
> Both paths are listed in `spetaka/.gitignore`.

---

## 2. One-Time Setup: GitHub Secrets

Add the following secrets in **GitHub → Settings → Secrets and variables → Actions**:

| Secret name | Value |
|---|---|
| `SIGNING_KEYSTORE_B64` | `base64 upload-keystore.jks` (one-liner, no line breaks) |
| `SIGNING_STORE_PASSWORD` | Store password used during keytool generation |
| `SIGNING_KEY_PASSWORD` | Key password used during keytool generation |
| `SIGNING_KEY_ALIAS` | `upload` (as set with `-alias` above) |

Generate the base64 value:
```bash
base64 -w 0 upload-keystore.jks
```

---

## 3. One-Time Setup: Play App Signing

Google Play wraps your upload key with their own app signing key:

1. In Play Console → **Release → Setup → App signing**
2. Choose **"Use Google-managed key"** (recommended) or upload your own
3. Upload the certificate of your upload key when prompted
4. Google will re-sign APKs/AABs before delivery to devices

**This means users receive the app signed by Google's app signing key, while you
use your upload key to authenticate uploads.**

---

## 4. Versioning Strategy

| Field | Location | Strategy |
|---|---|---|
| `versionName` | `spetaka/pubspec.yaml` — `version: X.Y.Z+…` | Semantic version: bump manually before each public release |
| `versionCode` | Injected by CI as `--build-number $GITHUB_RUN_NUMBER` | Auto-increments with every CI run; always greater than previous release |

**Rule:** Every build uploaded to Play Store must have a strictly increasing
`versionCode`. The CI run number guarantees this for all builds on `main`.

---

## 5. Building a Release AAB Locally

```bash
cd spetaka

# Ensure key.properties is present (see Section 1)
flutter build appbundle --release --build-number <manual_number>
# Output: build/app/outputs/bundle/release/app-release.aab
```

For APK (sideloading / Samsung S25 validation):
```bash
flutter build apk --release --target-platform android-arm64 --build-number <manual_number>
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. CI-Generated Builds

Every push to `main` (or manual `workflow_dispatch`) produces:

- **APK artifact:** `spetaka-release-apk-<run_number>` (arm64 only, for direct install)
- **AAB artifact:** `spetaka-release-aab-<run_number>` (universal, for Play Store upload)

Both artifacts are retained for 30 days.

The build is signed when the `SIGNING_KEYSTORE_B64` secret is present; otherwise
it falls back to the debug key (debug-signed for CI PRs from forks, etc.).

---

## 7. Internal Track Validation on Samsung S25

Before promoting to a wider audience:

1. Download `app-release.apk` from the CI artifacts
2. Enable **Developer options → Install unknown apps** (or use ADB)
3. Install via ADB:
   ```bash
   adb install -r spetaka-release-apk-<n>/app-release.apk
   ```
4. Validate all AC manually:
   - Launch, onboarding (Sophie demo card visible)
   - Add/import a friend, assign tags, add event
   - Daily view prioritization and acquittement flow
   - Backup export and import round-trip
   - Settings: language, theme, cadence defaults

For Play Store internal track:
1. Upload `app-release.aab` to Play Console → **Internal testing**
2. Add yourself as an internal tester
3. Install via Play Store internal testing link
4. Run the same validation checklist above

---

## 8. Release Track Progression

```
Internal testing  →  Closed testing (beta)  →  Production
     (QA)              (trusted testers)        (public)
```

| Stage | Who | Criteria to advance |
|---|---|---|
| **Internal** | Laurus + designated testers | All ACs pass on Samsung S25; no crash reports in Play Console for 48 h |
| **Closed (beta)** | Invited group (≤ 100 users) | 48 h crash-free session rate ≥ 99% in Play Console → Android Vitals |
| **Production** | All users (staged rollout) | Begin at 10% rollout; monitor crash rate and ANR rate over 24 h; expand to 50% then 100% |

**Staged production rollout:** Use Play Console → Production → Manage rollout → Set percentage.
Halt the rollout immediately if Android Vitals crash rate exceeds 1%.

---

## 9. Hotfix Process

1. Create a `hotfix/vX.Y.Z` branch from the tag of the affected release
2. Apply the fix, bump `versionName` (patch increment), push to hotfix branch
3. Manually trigger CI on the hotfix branch (`workflow_dispatch`)
4. Download the signed AAB from CI artifacts and upload to the appropriate track
5. Once confirmed stable, merge hotfix branch back into `main`

---

## 10. Release Notes Template

Pre-fill for Play Store (FR + EN):

**FR:**
> Bienvenue dans Spetaka v{version} !
> — {Highlight 1}
> — {Highlight 2}
> Merci pour vos retours.

**EN:**
> Welcome to Spetaka v{version}!
> — {Highlight 1}
> — {Highlight 2}
> Thank you for your feedback.
