import os
import plistlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[2]


class ForkPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="greedless-packaging-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "Scripts").mkdir()
        (self.root / "Resources").mkdir()
        (self.root / "tools").mkdir()
        (self.root / ".bin/OmniWM_OmniWM.bundle").mkdir(parents=True)
        shutil.copy2(SOURCE / "Scripts/package-app.sh", self.root / "Scripts/package-app.sh")
        shutil.copy2(SOURCE / "Info.plist", self.root / "Info.plist")
        (self.root / "OmniWM.entitlements").write_text("entitlements")
        (self.root / "Resources/GreedlessIcon.icns").write_bytes(b"fork icon")
        (self.root / ".bin/OmniWM").write_bytes(b"app binary")
        (self.root / ".bin/greedlessctl").write_bytes(b"cli binary")
        self.command(
            self.root / "Scripts/ghostty-preflight.sh",
            'if [ "$1" = print-library-dir ]; then printf "%s\\n" "$PWD/.bin"; fi\n',
        )
        (self.root / "Scripts/localization.py").write_text("import sys\nsys.exit(0)\n")
        self.command(self.root / "tools/swift", 'if [ "${*: -1}" = --show-bin-path ]; then printf "%s\\n" "$GREEDLESS_TEST_ROOT/.bin"; fi\n')
        self.command(self.root / "tools/lipo", "exit 0\n")
        self.command(self.root / "tools/make", "exit 91\n")
        self.command(self.root / "tools/codesign", 'printf "%s\\n" "$*" >> "$GREEDLESS_TEST_ROOT/codesign.log"\n')
        self.command(
            self.root / "tools/plutil",
            'exec /usr/bin/python3 - "$@" <<\'PYTHON\'\n'
            "import plistlib, sys\n"
            "if sys.argv[1] == '-replace':\n"
            "    path = sys.argv[5]\n"
            "    with open(path, 'rb') as stream: data = plistlib.load(stream)\n"
            "    data[sys.argv[2]] = sys.argv[4]\n"
            "    with open(path, 'wb') as stream: plistlib.dump(data, stream)\n"
            "PYTHON\n",
        )
        self.environment = {
            **os.environ,
            "PATH": f"{self.root / 'tools'}:{os.environ['PATH']}",
            "GREEDLESS_TEST_ROOT": str(self.root),
        }
        for key in ("GREEDLESS_APP_NAME", "GREEDLESS_BUNDLE_ID", "GREEDLESS_SIGNING_IDENTITY", "GREEDLESS_NOTARIZE_PROFILE"):
            self.environment.pop(key, None)

    @staticmethod
    def command(path, body):
        path.write_text("#!/bin/bash\nset -eu\n" + body)
        path.chmod(0o755)

    def package(self, *args):
        return subprocess.run(
            ["/bin/bash", str(self.root / "Scripts/package-app.sh"), *args],
            cwd=self.root,
            env=self.environment,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_local_default_packages_fork_identity_and_signs_ad_hoc(self):
        result = self.package()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        app = self.root / "dist/Greedless Manager.app"
        with (app / "Contents/Info.plist").open("rb") as stream:
            info = plistlib.load(stream)
        self.assertEqual(info["CFBundleDisplayName"], "Greedless Manager")
        self.assertEqual(info["CFBundleName"], "Greedless Manager")
        self.assertEqual(info["CFBundleIdentifier"], "org.greedless.manager")
        self.assertEqual(info["CFBundleExecutable"], "OmniWM")
        self.assertEqual(info["CFBundleIconFile"], "GreedlessIcon")
        self.assertEqual(info["CFBundleShortVersionString"], "0.1.0")
        self.assertEqual(info["CFBundleVersion"], "1")
        self.assertEqual((app / "Contents/MacOS/greedlessctl").read_bytes(), b"cli binary")
        self.assertEqual((app / "Contents/MacOS/OmniWM").read_bytes(), b"app binary")
        self.assertEqual((app / "Contents/Resources/GreedlessIcon.icns").read_bytes(), b"fork icon")
        self.assertEqual(
            sum("--sign -" in line for line in (self.root / "codesign.log").read_text().splitlines()),
            3,
        )
        self.assertNotIn("Oliver Nikolic", (self.root / "codesign.log").read_text())

    def test_distribution_mode_requires_explicit_fork_credentials_before_build(self):
        result = self.package("release", "true")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("GREEDLESS_SIGNING_IDENTITY and GREEDLESS_NOTARIZE_PROFILE", result.stderr)
        self.assertFalse((self.root / "dist").exists())
        self.assertFalse((self.root / "codesign.log").exists())

    def test_make_run_uses_packaged_app_without_legacy_switcher(self):
        result = subprocess.run(
            ["/usr/bin/make", "-n", "run"], cwd=SOURCE,
            text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("./Scripts/package-app.sh debug dev", result.stdout)
        self.assertIn('open "', result.stdout)
        self.assertIn("/dist/Greedless Manager.app", result.stdout)
        self.assertNotIn("omniwm-dev.sh", result.stdout)
