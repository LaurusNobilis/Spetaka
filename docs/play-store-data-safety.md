# Play Store — Data Safety Form Inputs

**App:** Spetaka  
**Package ID:** dev.spetaka.spetaka  
**Prepared:** 2026-03-05

Use this document to fill in the **Data Safety** section of the Google Play
Console when creating or updating the store listing.

---

## Section 1 — Does your app collect or share any of the required user data types?

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Not applicable in v1.0** (the current release does not transmit user data over the network) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — uninstall removes all app data |

---

## Section 2 — Data Types Collected

### Contacts

| Field | Value |
|---|---|
| **Data type** | Contacts |
| **Collected?** | Yes (READ_CONTACTS, only on explicit import action) |
| **Shared?** | No |
| **Required / Optional** | Optional (import is an optional convenience feature) |
| **Purposes** | App functionality (pre-filling friend card form) |
| **Processed ephemerally?** | Yes — data is only stored if the user saves the friend card |

### Personal info — Name, Phone number

| Field | Value |
|---|---|
| **Data type** | Name; Phone number |
| **Collected?** | Yes (user-entered or imported from device contacts) |
| **Shared?** | No |
| **Encrypted on device?** | Yes (AES-256-GCM) |
| **Required / Optional** | Required (core app functionality) |
| **Purposes** | App functionality |

### Personal info — Other (notes, events, tags)

| Field | Value |
|---|---|
| **Data type** | Other personal info (freeform notes, event descriptions, category tags) |
| **Collected?** | Yes (user-entered) |
| **Shared?** | No |
| **Encrypted on device?** | Yes (AES-256-GCM for notes) |
| **Required / Optional** | Optional |
| **Purposes** | App functionality |

### App activity — App interactions

| Field | Value |
|---|---|
| **Data type** | App interactions (contact log, care score computations) |
| **Collected?** | Yes (auto-generated from user actions within the app) |
| **Shared?** | No |
| **Encrypted on device?** | Yes |
| **Required / Optional** | Required (core feature) |
| **Purposes** | App functionality |

---

## Section 3 — Data NOT Collected

The following data types listed in the Play Console form are **not** collected
by Spetaka:

- Location data (precise or approximate)
- Financial / payment info
- Health and fitness data
- Messages (SMS/WhatsApp content — only system intents are launched)
- Photos or videos
- Audio or voice files
- Device identifiers (Advertising ID, IMEI, etc.)
- Web browsing history
- Search history
- Crash logs / diagnostics sent to developer (no analytics SDK)

---

## Section 4 — Privacy Policy URL

Publish [docs/privacy-policy.md](privacy-policy.md) to a publicly accessible
URL before submitting the store listing.

**Suggested URL:** `https://spetaka.dev/privacy` *(set up redirect or hosting
before going live)*

---

## Section 5 — Permissions declared in AndroidManifest

The following permissions will appear in the Play Console review. Ensure each
has a visible justification:

| Permission | Justification shown to users |
|---|---|
| `READ_CONTACTS` | "Import a friend's name and number from your contacts" |
| `INTERNET` | Required by Flutter runtime; no external calls made in v1.0 |

Spetaka does not declare `CALL_PHONE` or `SEND_SMS`. Call, SMS, and WhatsApp
flows open external apps through system links and do not require dedicated
runtime permissions in the current implementation.

---

## Checklist Before Store Submission

- [ ] Privacy policy URL is live and publicly accessible
- [ ] Data safety form filled in Play Console matches this document
- [ ] Content rating questionnaire completed (General Audience expected)
- [ ] App category set: **Lifestyle** or **Productivity**
- [ ] Target audience confirmed: 18+
- [ ] Store listing screenshots prepared (at minimum: phone screenshots × 2)
- [ ] Short description (≤ 80 chars) and full description ready
- [ ] App icon (512 × 512 PNG) exported from SVG assets
- [ ] Feature graphic (1024 × 500 PNG) prepared
