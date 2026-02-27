# Story 6.1: WebDAV Configuration UI & Connection Test

Status: ready-for-dev

## Story
As Laurus, I want to configure and test WebDAV before enabling sync so setup is reliable and explicit.

## Acceptance Criteria
1. Setup screen includes URL, username, password, passphrase fields.
2. Test connection performs WebDAV probe and returns actionable status.
3. Success enables sync toggle; failures map to specific user messages.
4. Passphrase handling copy is explicit and passphrase is never stored.
5. Uses runtime permission/network behavior consistent with constraints.

## Tasks
- [ ] Build WebDAV setup form and secure field handling.
- [ ] Implement test-connection action + result mapping.
- [ ] Add sync-enable gating after successful test.
- [ ] Ensure secrets/passphrase are not persisted improperly.

## References
- `_bmad-output/planning-artifacts/epics.md` (Epic 6, Story 6.1)

## Dev Agent Record
### Agent Model Used
GPT-5.3-Codex
