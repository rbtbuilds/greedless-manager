# Troubleshooting

Start in the repository root with `make doctor`. Read the first error and preserve its log before changing anything. Setup and build failures should be fixed before launching the app.

## The package requires Swift tools 6.4

The selected compiler is too old. Install full Xcode 27 or later and complete its first run. Verify `xcodebuild -version`, `xcrun swift --version`, and `xcode-select -p`. Select that Xcode in **Xcode > Settings > Locations > Command Line Tools**, or set `DEVELOPER_DIR` to its existing `Contents/Developer` directory for this terminal session. Do not edit Package.swift to lower the requirement. See [Apple's supported macOS versions](https://developer.apple.com/xcode/system-requirements/).

## Xcode asks for an agreement or additional components

Open Xcode and finish setup. The account holder should review and accept Apple's agreement. `xcodebuild -checkFirstLaunchStatus` must succeed before the build. Installing Command Line Tools alone does not supply everything this app needs.

## Architecture is x86_64

Use a native terminal on Apple Silicon, with Rosetta disabled for that terminal. `uname -m` should print `arm64`. This checkout does not provide an Intel app build.

## GhosttyKit is missing, mismatched, or fails to download

Run `make setup` with network access. The framework and tools are pinned in `Scripts/dev-tools.env`; the linked archive has a second checksum in `Scripts/build-metadata.env`. A checksum failure is a stop condition. Do not replace the expected hash with the downloaded hash. If you intentionally installed a different framework, preserve it outside the checkout before rerunning setup. If a pinned upstream download becomes unavailable, report the exact URL and error in this fork's issues.

## Linker cannot find Ghostty or one of its libraries

Use `make app` or `make build`, which provide the linker environment. For tests, use the complete command:

```sh
LIBRARY_PATH="$(./Scripts/ghostty-preflight.sh print-library-dir)${LIBRARY_PATH:+:$LIBRARY_PATH}" swift test
```

## Localization catalogs do not match compiler metadata

On an unchanged release checkout, first verify the required Xcode and inspect `git status`. If you intentionally changed localized Swift strings, run `make localization-sync`, review the resulting catalog diff, then run `make verify`. Do not regenerate large catalogs just to hide an unrelated build error.

## The permissions window says Not Granted after rebuilding

Ad-hoc signing changes the app's identity requirements when its binary changes. An old enabled entry can still refer to the prior build. Quit Greedless Manager. In **System Settings > Privacy & Security**, remove only its stale entry from Accessibility and Input Monitoring, add the exact rebuilt `dist/Greedless Manager.app`, enable it, and reopen the app. Follow any quit/reopen prompt. Do not change permissions for unrelated apps or reset the privacy database.

Screen Recording is optional. **Continue Without Screen Recording** is expected when the required permissions are granted but capture access is off. Overview thumbnails, drag previews, and captured Hidden Bar glyphs will be unavailable. The app may show the optional permission screen again on a later launch.

## The CLI cannot connect

Launch the app bundle, finish the required permission flow, and enable **IPC / CLI > Enable IPC** in its status-bar menu. Use the bundled executable shown in BUILD.md. An old `omniwmctl` command targets a different identity. Check whether `GREEDLESS_SOCKET` is set to an intentional custom socket; do not copy socket overrides from another app. The in-app **Install CLI to PATH** action is optional.

## A command returns layout_mismatch

The command is not supported by the active layout. Niri scrolling columns use `command set-container-primary-span +10%` to grow the focused column. `command resize horizontal grow` is for Dwindle. Use `greedlessctl --help` and the active layout setting to choose the appropriate command.

## Windows move unexpectedly or another manager conflicts

Quit the other active tiling manager before starting this one. Review Greedless Manager's app rules and hotkeys with disposable windows first. Quit Greedless Manager from its menu to stop management. Avoid force-killing it as a normal exit path; normal termination runs its window-recovery logic.

## Some tests are skipped

The suite includes optional Fish/Nushell checks and opt-in tests that need a live macOS desktop. Record the reasons printed by the runner. Do not enable capture- or window-mutating tests on a working desktop merely to remove the skip count. A headless CI pass is not proof of gestures, permissions, or multi-monitor behavior.

## Reporting a problem

Use [this fork's issues](https://github.com/rbtbuilds/greedless-manager/issues) for ordinary bugs and [private security reports](https://github.com/rbtbuilds/greedless-manager/security/advisories/new) for vulnerabilities. Include the commit or release tag, macOS/Xcode/Swift versions, exact failing command, and a minimal reproduction. Review logs before uploading: diagnostics and CLI queries can contain window titles, application names, and settings.
