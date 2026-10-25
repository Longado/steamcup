"""Exercise the web installer in a temporary directory without changing this Mac."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


INSTALLER = Path(__file__).resolve().parents[1] / "docs/install.sh"


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="steamcup-install-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.target = self.root / "Applications"
        self.env = dict(os.environ, STEAMCUP_INSTALL_DIR=str(self.target))
        self.env["PATH"] = str(self.bin) + os.pathsep + self.env["PATH"]
        self.command("uname", "echo Darwin")
        self.command("sw_vers", "echo 14.0")
        self.command("curl", "for arg; do last=$arg; done; touch \"$last\"")
        self.command("shasum", "cat >/dev/null")
        self.command("ditto", """if [ "$1" = -x ]; then
  mkdir -p "$4/Steamcup.app/Contents/MacOS"
  printf 'app' > "$4/Steamcup.app/Contents/MacOS/Steamcup"
  chmod +x "$4/Steamcup.app/Contents/MacOS/Steamcup"
  printf 'plist' > "$4/Steamcup.app/Contents/Info.plist"
else
  cp -R "$1" "$2"
fi""")
        self.command("defaults", "echo com.longado.steamcup")
        self.command("xattr", "exit 0")

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\nset -eu\n" + body + "\n")
        path.chmod(0o755)

    def run_installer(self):
        return subprocess.run(["/bin/bash", str(INSTALLER)], env=self.env,
                              text=True, capture_output=True, timeout=30)

    def test_linux_stops_before_installing(self):
        self.command("uname", "echo Linux")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("macOS 14", result.stderr)
        self.assertFalse(self.target.exists())

    def test_old_macos_stops_before_installing(self):
        self.command("sw_vers", "echo 13.7")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("macOS 14", result.stderr)

    def test_existing_app_is_preserved(self):
        app = self.target / "Steamcup.app"
        app.mkdir(parents=True)
        (app / "keep").write_text("existing app")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("已有", result.stderr)
        self.assertEqual((app / "keep").read_text(), "existing app")

    def test_existing_symlink_is_preserved(self):
        self.target.mkdir()
        app = self.target / "Steamcup.app"
        app.symlink_to(self.root / "missing")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(app.is_symlink())

    def test_download_failure_does_not_install(self):
        self.command("curl", "exit 22")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.target / "Steamcup.app").exists())

    def test_wrong_checksum_does_not_install(self):
        self.command("shasum", "exit 1")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.target / "Steamcup.app").exists())

    def test_wrong_bundle_does_not_install(self):
        self.command("defaults", "echo com.example.unrelated")
        result = self.run_installer()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.target / "Steamcup.app").exists())

    def test_installs_to_selected_directory(self):
        result = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.target / "Steamcup.app/Contents/MacOS/Steamcup").is_file())
        self.assertIn("隐私与安全性", result.stdout)


if __name__ == "__main__":
    unittest.main()
