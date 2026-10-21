# Architecture

Greedless Manager retains OmniWM's window-management architecture and internal Swift module names. Read the [upstream architecture guide preserved in this checkout](../website/src/content/docs/developers/architecture.md) for the engine, controllers, layout, and platform integration.

The fork changes the app's public identity, storage paths, CLI name/socket namespace, packaging defaults, and update/report destinations. It does not replace the upstream engine. [FORK.md](../FORK.md) records the base commit and intentional retained names; [verification.md](verification.md) records the behavior tested locally.

Start with [BUILD.md](BUILD.md) or the [agent setup brief](AGENT_SETUP.md) before following development commands in inherited website material. The original website describes OmniWM and is not deployed for this fork.
