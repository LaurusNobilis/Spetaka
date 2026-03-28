# Privacy Policy — Spetaka

**Effective date:** 2026-03-05
**App name:** Spetaka
**Developer:** Laurus
**Contact:** privacy@spetaka.dev *(placeholder — update before release)*

---

## 1. Overview

Spetaka is a private friend-relationship intelligence app designed around a
single principle: **your personal data stays on your device**. The app does not
connect to any backend server operated by the developer and does not collect,
transmit, or sell personal information.

---

## 2. Data We Collect — and Where It Lives

| Data type | Source | Storage | Transmitted? |
|---|---|---|---|
| Friend names and phone numbers | You enter manually, or imported from your device contacts | Local SQLite database (encrypted on-device) | **No** |
| Personal notes, category tags, concern flags | You enter manually | Local SQLite database (encrypted) | **No** |
| Dated events and recurring check-in cadences | You enter manually | Local SQLite database (encrypted) | **No** |
| Contact history log entries | Auto-generated when you confirm a contact action | Local SQLite database (encrypted) | **No** |
| Backup archive (optional, explicit user action) | You trigger export | Encrypted `.enc` file written to device storage | Only if *you* manually share or upload it |
| App preferences (theme, display settings) | Auto-saved as you change settings | `SharedPreferences` on the device | **No** |

### Encryption

Sensitive fields (friend names, phone numbers, notes) are encrypted at rest
using **AES-256-GCM** with a per-install device key stored locally by the app.
The raw SQLite database file on disk cannot be read without app-level
decryption.

---

## 3. Contacts Permission

Spetaka requests the **READ_CONTACTS** permission *only* when you explicitly
start a "Import from contacts" flow. The permission is used to pre-fill the
friend name and phone number fields. Contact data is **not** stored beyond what
you explicitly save in the app.

---

## 4. Phone / Communication Permissions

Spetaka does **not** declare dedicated Android permissions such as
**CALL_PHONE** or **SEND_SMS**. Instead, it opens your device's native dialler,
SMS app, or WhatsApp via external links / intents that you confirm on the
device. The app does not intercept call state, record conversations, or
transmit communication data.

---

## 5. Internet Permission

Spetaka requests the **INTERNET** permission as a technical prerequisite of the
Flutter runtime and the optional future WebDAV sync feature (Phase 2). In the
current release **no network calls are made** by the app itself.

---

## 6. Data Sharing

We **do not** share personal data with third parties, advertisers, analytics
services, or any other external entity.

---

## 7. Data Deletion

To delete all your data, uninstall the app. The SQLite database and preferences
are removed as part of standard Android app uninstallation. Any exported `.enc`
files stored in your device's Downloads folder must be deleted manually.

---

## 8. Children's Privacy

Spetaka is not directed at children under 13 years of age. We do not knowingly
collect personal information from children.

---

## 9. Changes to This Policy

We may update this policy when new features are added. The effective date at the
top of the document will be updated accordingly. Significant changes will be
highlighted in the app's release notes.

---

## 10. Contact

For privacy-related questions or requests please contact:
**privacy@spetaka.dev** *(placeholder — update before release)*
