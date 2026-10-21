import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class DisabledLegacyDevInstallTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="greedless-legacy-dev-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.scripts = self.root / "Scripts"
        self.scripts.mkdir()
        source = Path(__file__).resolve().parents[2] / "Scripts" / "omniwm-dev.sh"
        self.script = self.scripts / source.name
        shutil.copy2(source, self.script)
        self.dev_app = self.root / "Applications" / "OmniWM Dev.app"
        self.dev_app.mkdir(parents=True)
        self.sentinel = self.dev_app / "keep-me"
        self.sentinel.write_text("existing user app")
        tools = self.root / "tools"
        tools.mkdir()
        for name in ("osascript", "pgrep", "open", "rm", "mv", "make"):
            self.write_trap(tools / name)
        self.write_trap(self.scripts / "package-app.sh")
        self.environment = {
            **os.environ,
            "PATH": f"{tools}:{os.environ['PATH']}",
            "GREEDLESS_TEST_ROOT": str(self.root),
            "OMNIWM_DEV_INSTALL_DIR": str(self.dev_app.parent),
            "OMNIWM_RELEASE_APP": str(self.root / "Release.app"),
            "OMNIWM_DEV_APP_NAME": "OmniWM Dev",
            "OMNIWM_APP_NAME": "OmniWM Dev",
            "OMNIWM_BUNDLE_ID": "com.barut.OmniWM.dev",
        }

    @staticmethod
    def write_trap(path):
        path.write_text(
            "#!/bin/bash\n"
            'printf "%s\\n" "$0 $*" >> "$GREEDLESS_TEST_ROOT/invoked"\n'
            "exit 99\n"
        )
        path.chmod(0o755)

    def test_all_legacy_commands_fail_before_build_quit_or_install(self):
        for arguments in ((), ("install",), ("use", "dev"), ("use", "release"), ("help",)):
            with self.subTest(arguments=arguments):
                result = subprocess.run(
                    [str(self.script), *arguments],
                    env=self.environment,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 64)
                self.assertIn("disabled in Greedless Manager", result.stderr)
                self.assertIn("make app", result.stderr)
                self.assertIn("make run", result.stderr)
                self.assertEqual(self.sentinel.read_text(), "existing user app")
                self.assertFalse((self.root / "invoked").exists())
                self.assertFalse((self.root / "dist").exists())
