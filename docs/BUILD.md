# Build and run Greedless Manager

This guide builds the app on your own Mac. No paid signing membership is needed for the local ad-hoc build. The initial release is source-only; it does not include a notarized installer.

Using a coding agent? Give it [AGENT_SETUP.md](AGENT_SETUP.md), which includes a complete task prompt and verification checklist.

## 1. Check your Mac and toolchain

You need an **Apple Silicon Mac**, the full **Xcode 27 or later**, **Swift 6.4 or later**, Python 3, Git, and internet access for dependencies. Intel Macs, Linux, and Windows are not supported build hosts for this checkout.

The app's runtime minimum is macOS 26.0, but Xcode 27 and 27.1 require **macOS 26.6 or later**. Check [Apple's current compatibility table](https://developer.apple.com/xcode/system-requirements/) before updating your system. The release was tested locally with macOS 26.7.1 and Xcode 27.1.

Install Xcode from the Mac App Store or Apple Developer, open it, accept its agreement, and finish installing the required components. In Xcode's **Settings > Locations > Command Line Tools**, select the full Xcode installation. Standalone Command Line Tools are insufficient.

Run:

```sh
uname -m
sw_vers -productVersion
xcode-select -p
xcodebuild -version
xcrun swift --version
xcodebuild -checkFirstLaunchStatus
python3 --version
git --version
```

Expected: `arm64`, a compatible macOS version, Xcode 27+, Swift 6.4+, and first-launch status exit code 0. If several Xcode versions are installed, set `DEVELOPER_DIR` to the verified Xcode developer directory for your current terminal session. Do not lower `swift-tools-version` to work around an old compiler.

## 2. Get this fork

Choose a directory where `greedless-manager` does not already exist:

```sh
git clone --branch greedless --single-branch https://github.com/rbtbuilds/greedless-manager.git
cd greedless-manager
git log -1 --oneline
```

For the fixed 0.1.0 snapshot, use `--branch greedless-v0.1.0` instead. That checks out a release tag in detached-HEAD mode; create a branch before making changes.

The fork's working branch is `greedless`. The repository also retains upstream history. A checkout of upstream `main` does not contain the Greedless Manager changes.

## 3. Fetch dependencies and build

From the repository root:

```sh
make setup
make doctor
make app
codesign --verify --deep --strict "dist/Greedless Manager.app"
```

`make setup` downloads the pinned GhosttyKit framework, SwiftFormat, and SwiftLint and verifies their SHA-256 checksums. Swift Package Manager resolves the pinned TOML dependency while building. You do not need to compile Ghostty or install the formatter/linter globally. A fresh build needs network access; subsequent builds reuse local caches.

The result is **`dist/Greedless Manager.app`**. Packaging signs it ad hoc and includes the `greedlessctl` command-line executable. It does not install a login item or move the app into Applications.

For a clean checkout, `make localization-sync` is unnecessary. Use it when developing changes to localized Swift strings; it modifies the catalogs. To check the existing catalogs without rewriting them, run `make verify`.

## 4. Launch and grant permissions

Save your work and quit any other active tiling window manager first. Starting a window manager can rearrange open windows. Open the already-built bundle with:

```sh
open "dist/Greedless Manager.app"
```

`make run` is also available, but it rebuilds before launching. Use `open` when you only want to start the existing build.

Grant **Accessibility** and **Input Monitoring** to this Greedless Manager bundle in System Settings. These enable reading and arranging windows and global input. **Screen Recording is optional**; choose **Continue Without Screen Recording** to start without Overview thumbnails and other capture-based previews. Follow any macOS quit/reopen prompt after granting access. Do not run the bare internal `OmniWM` executable to launch the app; opening the bundle gives macOS the correct identity.

Keep the app in its build location for the first test. If you later move it into Applications, quit it first, reopen that exact copy, and check its permissions again. Do not run two copies simultaneously.

## 5. Try the controls

Open a few disposable windows. In settings, inspect **Niri Layout**, **Hotkeys**, and **Mouse & Trackpad** before changing shortcuts or gestures. Confirm focus, column scrolling, and resizing. Close and reopen Settings, then quit the app from its menu and check that your windows remain accessible.

For command-line control, turn on **Enable IPC** in the app's status-bar menu under **IPC / CLI**. Then run:

```sh
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" ping
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" --help
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" query windows --json
```

`ping` should return `pong`. Queries can include application and window information; keep their output private. The CLI is not added to your `PATH` automatically. Niri column sizing uses `command set-container-primary-span`; `command resize` is a Dwindle command and returns `layout_mismatch` in Niri.

## 6. Run the development checks

```sh
make verify
make test-dev-tools
LIBRARY_PATH="$(./Scripts/ghostty-preflight.sh print-library-dir)${LIBRARY_PATH:+:$LIBRARY_PATH}" swift test
```

`make verify` covers formatting, lint, strict compilation, and localization metadata. The Python suite checks development tooling. The Swift suite checks the app, layout engine, IPC, and CLI. Some shell and live desktop tests are explicitly skipped when their prerequisites are unavailable; report the actual counts, not an assumed full pass. See [verification.md](verification.md) for the recorded results and limits.

## Configuration, updates, and removal

Default editable settings are at `~/.config/greedless-manager/settings.toml`; runtime state is under `~/.local/state/greedless-manager/`. Absolute `XDG_CONFIG_HOME` and `XDG_STATE_HOME` overrides are supported. Relative overrides are ignored. Preserve both settings and state before experiments, and keep backups outside published source.

Updates are manual. Quit Greedless Manager, check `git status`, preserve local changes, then fast-forward the `greedless` branch and rebuild:

```sh
git pull --ff-only
make setup
make verify
make app
```

A tag checkout must switch to the desired newer tag or a tracking branch instead of running `git pull`. Rebuilding an ad-hoc app can require renewing its permission entries; see [troubleshooting](TROUBLESHOOTING.md).

To stop using it, quit the app, turn off any login item you enabled, and revoke its privacy permissions if desired. Remove only the app copy you installed. Settings and runtime state can be retained for a later reinstall; deleting them is a separate choice. The build process does not install or replace OmniWM.
