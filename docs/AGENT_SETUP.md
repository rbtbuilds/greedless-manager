# Compile Greedless Manager with your coding agent

Use an agent that can run commands on an Apple Silicon Mac. A cloud Linux container can review the source but cannot compile or exercise this macOS app. Start with [BUILD.md](BUILD.md); the exact prerequisites and human permission steps are the same whether a person or agent runs the commands.

## Copy-paste task

Paste this into Codex, Claude Code, or another coding agent with local terminal access:

```text
Build Greedless Manager from https://github.com/rbtbuilds/greedless-manager
on my Mac. Use its greedless branch, or greedless-v0.1.0 if I request the
fixed initial release. Read README.md, docs/BUILD.md, docs/AGENT_SETUP.md,
and docs/TROUBLESHOOTING.md before running setup.

1. Inspect the current directory and preserve existing work. Clone into a
   new directory if this checkout is absent; never overwrite an existing
   unrelated directory. Record the source commit and any local changes.
2. Verify arm64, compatible macOS, full Xcode 27+, Swift 6.4+, Python 3,
   Git, and completed Xcode first-run setup. Do not lower the package's
   toolchain requirement. If an OS/Xcode upgrade or agreement is needed,
   explain the exact prerequisite and let me handle or approve it.
3. Run make setup, make doctor, make verify, make test-dev-tools, and the
   documented serial swift test command with its Ghostty LIBRARY_PATH.
   Keep logs locally and report failures and explicit skips accurately.
4. Run make app and codesign --verify --deep --strict on the app bundle.
   Do not use the archived upstream installer or release scripts. Do not
   change global signing trust, disable Gatekeeper/SIP, or publish code.
5. Report the app's absolute path, source commit, build/signature result,
   and actual test counts. Compilation is not a desktop smoke test.
6. Before launching, tell me it will manage open windows and confirm I am
   ready for that. Let me grant Accessibility and Input Monitoring through
   macOS. Keep Screen Recording optional and off unless I request it.
7. If I authorize a live smoke test, use disposable windows. Preserve my
   settings and state, avoid changing my normal windows or shortcuts,
   test the affected controls, quit the test app, and restore temporary
   changes. Report exactly which interactive checks you completed.
```

## What an agent should recognize

- The user-facing app is **Greedless Manager**, bundle ID `org.greedless.manager`.
- The internal executable/module is still **OmniWM**. This is intentional.
- The bundled command is **greedlessctl**. IPC starts disabled by default; enable it only when needed for the requested test.
- Local compilation and ad-hoc signing need no paid signing membership. This does not produce a notarized public installer.
- `make setup` verifies pinned downloads and preserves a mismatched existing framework. Diagnose a mismatch instead of deleting user files or changing checksums to silence it.
- `make verify` does not run the test suites. Run the separate commands in BUILD.md.
- `make run` rebuilds and launches. `open "dist/Greedless Manager.app"` launches the existing bundle.
- A rebuilt ad-hoc signature can invalidate macOS permission records. Renew only this app's entries through System Settings; do not reset permissions globally.
- The original website and files under `docs/upstream/` describe OmniWM. They are historical context, not this fork's setup or publishing procedure.

## Verification handoff

A useful completion report includes the commit, host/toolchain versions, app path, commands and exit codes, passed/failed/skipped test counts, and whether a GUI session was actually tested. Name untested areas such as trackpad gestures, screen-capture previews, display hot-plugging, and VoiceOver. Include a link to the first failing log if the build stops; do not report success merely because an app bundle exists.

Use [CONTRIBUTING.md](../CONTRIBUTING.md) when modifying code. Preserve the GPL-2.0-only license and upstream copyright notices. Keep local machine paths, settings backups, window queries, and credentials out of commits and public issue attachments.
