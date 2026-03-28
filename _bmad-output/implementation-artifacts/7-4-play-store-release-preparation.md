# Story 7.4: Play Store Release Preparation

Status: in-progress

## Story
As Laurus, I want release pipeline and Play Store setup ready so rollout can proceed safely after validation gate.

## Acceptance Criteria
1. Versioning and build-number strategy are configured.
2. Play App Signing/upload key setup is complete; secrets are gitignored.
3. Privacy policy and data safety declarations are prepared.
4. Release APK passes analyze/test gates.
5. Internal track submission is validated on Samsung S25.
6. Release progression plan (Internal -> Closed -> Production) is documented.

## Tasks
- [x] Finalize versioning and CI build-number flow.
- [x] Configure signing/keystore hygiene.
- [x] Prepare privacy policy + data safety form inputs.
- [ ] Validate internal-track submission on Samsung S25 and complete deploy verification.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 7, Story 7.4)

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.6

### Implementation Plan
Story 7.4 covers release infrastructure — CI/CD, signing, legal documents, and
process documentation. No runtime Dart code changes were required. All four
tasks were implemented as configuration, Groovy (Gradle), and Markdown artifacts.

**Task 1 — Versioning and CI build-number flow (AC: 1, 4)**
- `pubspec.yaml` already declares `version: 1.0.0+1` as the versionName baseline.
- CI now passes `--build-number ${{ github.run_number }}` to both `flutter build apk`
  and `flutter build appbundle` commands. This ensures a monotonically increasing
  `versionCode` for every build on `main` without manual intervention.
- The CI timeout was kept at 20 min; AAB build shares the same cached SDK/pub layers.

**Task 2 — Signing / keystore hygiene (AC: 2)**
- `android/app/build.gradle`: replaced the hardcoded `signingConfig = signingConfigs.debug`
  in the `release` buildType. The Groovy block now reads `key.properties` (gitignored)
  when present and configures a proper `signingConfigs.release`; falls back to debug only
  when the file is absent (debug-signed local builds / fork PRs).
- `spetaka/.gitignore`: added entries for `android/key.properties`, `android/upload-keystore.jks`,
  and `android/*.jks` / `android/*.keystore`.
- `android/key.properties.template`: non-sensitive template committed to guide setup.
- `ci.yml`: two signing steps added after tests — "Decode upload keystore" (base64 from
  `SIGNING_KEYSTORE_B64` secret) and "Write key.properties" (four secrets injected).
  Both steps are conditional on `env.SIGNING_KEYSTORE_B64 != ''` so unsigned builds
  on forks / without secrets still succeed.
- Job-level `env.SIGNING_KEYSTORE_B64` set from the secret so `if:` conditions can
  read it (GitHub Actions `if:` cannot directly reference `secrets.*`).

**Task 3 — Privacy policy + data safety form (AC: 3)**
- `docs/privacy-policy.md`: comprehensive 10-section policy covering data types,
  AES-256 encryption at rest, declared permissions (`READ_CONTACTS`, `INTERNET`),
  external dialer / SMS / WhatsApp launches, data sharing (none), deletion (uninstall),
  children's privacy, and contact info.
- `docs/play-store-data-safety.md`: structured Play Console form inputs for each
  collected data type (Contacts, Name/Phone, notes/events/tags, app activity),
  explicit list of non-collected types, submission checklist with AC5 validation steps.

**Task 4 — Release build + internal-track deploy steps (AC: 4, 5, 6)**
- CI updated to produce both an arm64 APK (`spetaka-release-apk-<n>`) and a universal
  AAB (`spetaka-release-aab-<n>`) as 30-day artifacts.
- `docs/release-process.md`: complete 10-section guide covering one-time keystore
  generation, GitHub Secrets setup, Play App Signing enrollment, versioning rules,
  local build commands, CI artifact flow, Samsung S25 validation checklist,
  Internal → Closed → Production track progression with crash-rate gates, hotfix
  process, and bilingual release notes template (FR + EN).

### Completion Notes
- Release preparation artifacts implemented and reviewed: `flutter analyze` returns "No issues found".
- No new Dart runtime code was introduced; all changes are CI/configuration/documentation.
- Signing infrastructure is conditional — CI works with or without secrets (graceful degradation).
- Privacy policy and data safety form were corrected during code review to match the current
  Android manifest and encryption implementation.
- AC5 (Samsung S25 validation and internal track submission) remains pending manual execution;
  the required checklist is documented in `docs/release-process.md` Section 7.
- Release progression plan (AC6) documented end-to-end in `docs/release-process.md` Section 8.

## File List
- `.github/workflows/ci.yml` — modified: job-level signing env, signing steps, versioned APK/AAB builds
- `spetaka/android/app/build.gradle` — modified: conditional signing config from key.properties
- `spetaka/android/key.properties.template` — created: non-secret template for developer onboarding
- `spetaka/.gitignore` — modified: added keystore/key.properties exclusions
- `docs/privacy-policy.md` — created: full data privacy policy for Play Store
- `docs/play-store-data-safety.md` — created: Play Console data safety form inputs and submission checklist
- `docs/release-process.md` — created: end-to-end release guide (keystore → Internal → Production)

## Change Log
- 2026-03-05: Story 7.4 deferred to backlog (do later). Release validation/submission remains pending.
- 2026-03-05: Story 7.4 implemented — CI versioning, signing hygiene, privacy policy,
  data safety form, release process documentation. AC1-4 and AC6 satisfied; AC5 requires manual
  Samsung S25 validation and internal track submission. (Story 7.4, dev: Amelia)
- 2026-03-25: Code review corrected release documentation to match manifest permissions,
  encryption key storage, and CI signing behavior; story returned to in-progress pending AC5.

