# Greedless Manager verification

Status on 2026-10-21: version 0.1.0 (build 1) builds, passes the checks below, and runs locally. The initial release provides source; the local packaged app is ad-hoc signed and is not notarized. These results establish local development verification, not comprehensive production sign-off.

## Scope

Fork OmniWM v0.7.6 at `3c0783954604eaa9110d0bdb61fa29f953e738ee`, retaining the window-management engine and GPL-2.0-only notices. The fork has its own bundle ID, XDG settings/state paths, IPC socket, CLI name, and original icon. Internal Swift module names remain unchanged. No Chain source, binary, artwork, or private implementation was used.

Upstream update checks are disconnected from app bootstrap. Reports default to copying Markdown locally. Upstream authorship and support links are explicitly labeled. The old development installer is disabled before any side effects; its source is archived for provenance.

The existing native interface retains system typography, layout spacing, light/dark appearance, keyboard navigation, and Reduce Motion behavior. The new status icon is a monochrome template; the app icon uses deep green and ivory. General settings were visually reviewed in both themes, including alignment, spacing, labels, and contrast. This was not a complete accessibility audit.

## Environment and build

- macOS 26.7.1 (25G241), Apple Silicon.
- Xcode 27.1 (27A9275), Swift 6.4, macOS 27.0 SDK. Xcode agreement accepted with user authorization; first-run status exits 0.
- `make setup`, `make localization-sync`, `make verify`, and `make app` passed.
- App and test targets compiled with Swift 6 strict checking and warnings as errors. The source toolchain requirement was not lowered.
- Compiler-generated localization metadata was synchronized and checked. Original catalog key ordering was retained without changing parsed compiler output.
- Full formatter check passed. Lint passed with three type-length warnings: WorkspaceBarSettingsTab, CommandPaletteController, and ReportIssueViewModel.
- `codesign --verify --deep --strict` passed for the final app and bundled CLI. Bundle identifier is `org.greedless.manager`, version 0.1.0; both executables are arm64.
- Pinned GhosttyKit, SwiftFormat, and SwiftLint dependencies were SHA-256 verified. Tooling remains in the repository cache.

## Automated checks

The full Swift test run executed 5,158 tests: **5,124 passed, 34 skipped, zero failures**. This includes identity, IPC, CLI, launch conflicts, reporting, layout, and window lifecycle coverage. The development-tooling suite separately passed **113 tests**, including packaging fixtures and checks that the disabled legacy installer preserves existing applications.

The first full run exposed two failed assertions in one window-close test. Its synthetic fixture queued an asynchronous layout refresh that ran during the test's deliberate suspension. Resetting that pending fixture work isolated the intended close/rebind behavior. The isolated reproduction and full suite then passed; production behavior and assertions were unchanged.

The first hosted build passed compilation and localization, then exposed an inherited canary-notes test that rejected `c1` anywhere in the output, including inside a valid commit hash. A fixed-date fixture reproduced the failure locally. The test now compares the exact changelog subjects, preserving the requirement to exclude the previous release commit without depending on hash contents. The full 113-test tooling suite passed after that correction.

The 34 skips were explicit:

- 13 Nushell and 2 Fish checks: those shells are not installed.
- 1 opt-in AX write benchmark and 1 Finder Quick Look integration check.
- 2 live compositor, 5 live Overview preview, and 5 native Space checks.
- 2 live surface measurement, 2 WindowServer metadata-read, and 1 live subscription-semantics checks.

Earlier isolated CLI checks also covered completion generation, Bash/Zsh syntax, authenticated fixture-socket ping, and rejection of an inherited upstream socket override. Report destination checks covered local-only defaults and explicitly supplied destination URL encoding/overflow. Independent review found a legacy-installer hazard; its fix and regression test were re-reviewed successfully.

## Desktop smoke test

A disposable AppKit app supplied four ordinary resizable windows. Temporary Greedless Manager rules tiled only that app; all 43 other tracked windows were confirmed floating. Hotkeys, the workspace bar, Hidden Bar, mouse warping, and the Quake terminal were disabled for this isolated exercise.

Verified through the live app and its bundled `greedlessctl`:

- Launch and permission onboarding, plus live `ping` returning `pong`.
- Focus and scrolling the viewport to a selected column.
- Moving a column left and growing its width from 693 to 871 points.
- Switching a test window to floating and back to tiling.
- Closing the focused test window and recovering focus to a remaining window.
- Quit and relaunch, with a remaining disposable window accessible after quitting.
- Light/dark settings, keyboard selection in the theme picker, and theme persistence across relaunch.
- Opening, closing, and reopening Settings without leaving the redirect/loading window behind.

The first resize attempt used a Dwindle-only command and correctly returned `layout_mismatch`; the Niri `set-container-primary-span +10%` command passed. Desktop testing also found an inherited Settings redirect issue: redirection could finish before the host window existed, and SwiftUI retained its completion state on reopening. The redirect now waits for a host window and resets on appearance. The strict build, localization check, package signature, first open, and repeated open were verified after this fix. Before source publication, the full Swift suite, development-tooling suite, and `make verify` passed again on the final source tree.

On the final build, Accessibility and Input Monitoring were confirmed granted, and Screen Recording was confirmed not granted. Replacing an ad-hoc signed build required removing and re-adding its stale permission entries, then restarting the app. Toggling an old entry alone did not refresh its signature.

Both test applications were closed at the end. Original settings and runtime-state backups were restored byte-for-byte after confirming the only preference difference was the deliberate test theme change. The app is left quit, so restoring the normal configuration does not immediately retile the user's workspace.

## Remaining limits

No physical multi-finger gesture test, complete keyboard-navigation or VoiceOver audit, pause/resume test, display hot-plug test, sleep/wake test, or exhaustive multi-monitor/Space test was performed. Three displays were connected, but their arrangement was not changed. Screen-capture previews were not exercised. The app retains some secondary upstream wording. Ad-hoc builds may require permission renewal after each rebuild.

No Developer ID signing, notarization, or installer distribution was performed. The inherited upstream website and archived release automation remain provenance, not fork publishing instructions. The fork's active GitHub workflow builds and tests with a read-only token; local results here do not imply a hosted CI result.

## Evidence

Ignored local evidence is retained under `.tmp/verification/` and `.tmp/desktop-smoke/`. Key files are:

- `post-update-tooling.log`, `swift-test-final.log`, and `border-isolated-refresh.log`.
- `localization-sync.log`, `verify-settings-redirect-final.log`, and `package-app-final.log`.
- `publication-swift-test.log`, `publication-dev-tools.log`, and `publication-verify.log` from the final source checks.
- `actions-result.txt`, `final-window-query.json`, and `cleanup-result.txt` in the desktop-smoke directory.

Temporary window queries and configuration/state backups are local test artifacts and are not included in source publication.
