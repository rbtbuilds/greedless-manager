# Contributing to Greedless Manager

Issues and pull requests belong in [rbtbuilds/greedless-manager](https://github.com/rbtbuilds/greedless-manager). Create branches from and target `greedless`, the fork's default branch. Upstream `main` is retained for provenance; it is not the fork's development branch.

## Build and verify

Use an Apple Silicon Mac with Xcode 27 or later and Swift 6.4. Complete Xcode's first-run setup, then follow the [README](README.md):

```sh
make setup
make verify
make test-dev-tools
LIBRARY_PATH="$(./Scripts/ghostty-preflight.sh print-library-dir)${LIBRARY_PATH:+:$LIBRARY_PATH}" swift test
make app
```

`make verify` checks formatting, lint, build, and compiler-generated localization metadata; tests are a separate step. `make app` creates an ad-hoc signed `dist/Greedless Manager.app`. Quit any running copy before opening a rebuilt app. `make run` builds and opens the packaged app; it does not install or switch an upstream OmniWM app.

Keep changes focused, preserve GPL notices and upstream attribution, and include what you tested. For window-management changes, exercise the affected flow with disposable windows and report any checks skipped. Changes to concurrency also need `swift test --parallel`. For new localized strings, run `make localization-sync` and review the catalog diff before `make verify`.

The GitHub workflow uses the public [`xcode-27` runner](https://github.com/actions/runner-images/issues/14404), pinned dependencies, and a read-only repository token. It builds and tests; it does not publish applications or use signing secrets. A hosted test result does not replace desktop validation.

## Bug reports and privacy

Search this fork's issues first. Include the app version, macOS version, reproduction steps, expected behavior, and actual behavior. The in-app report form copies a report locally; paste a reviewed copy into this fork's issue form. Diagnostics can contain application names, window titles, and settings. Remove private information before attaching them.

Use [private vulnerability reporting](https://github.com/rbtbuilds/greedless-manager/security/advisories/new) for security issues. See [SECURITY.md](SECURITY.md).

## Upstream and releases

Most of the implementation comes from OmniWM. See [FORK.md](FORK.md) and the preserved [upstream contribution guide](docs/upstream/CONTRIBUTING.md). The original website and release scripts are retained for provenance; their signing identities, destinations, and deployment instructions do not apply here. Upstream workflows and deployment configuration are archived under `docs/upstream/`.

The initial public release provides source. Developer ID signing, notarization, and an installer are not configured. Tags for this fork use `greedless-v<VERSION>` to avoid confusion with upstream version tags.
