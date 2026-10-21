# Greedless Manager CLI

Enable **IPC / CLI > Enable IPC** in the app's status-bar menu, then use the bundled command:

```sh
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" ping
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" --help
"dist/Greedless Manager.app/Contents/MacOS/greedlessctl" query windows --json
```

IPC is disabled by default. The optional **Install CLI to PATH** menu action makes `greedlessctl` available without the bundle path. `GREEDLESS_SOCKET` selects a custom socket; upstream `OMNIWM_SOCKET` does not configure this fork. Queries can include private window information.

For the full inherited command reference, read the version of [upstream CLI documentation in this checkout](../website/src/content/docs/reference/cli/). Substitute `greedlessctl` for `omniwmctl`, `GREEDLESS_SOCKET` for `OMNIWM_SOCKET`, and this fork's settings/state locations from [BUILD.md](BUILD.md). The executable's `--help` output describes the commands supported by your exact build.

For Niri, use `command set-container-primary-span +10%` to grow the focused column. `command resize horizontal grow` applies to Dwindle and returns `layout_mismatch` in Niri. Commands change real windows; try them with disposable windows first.
