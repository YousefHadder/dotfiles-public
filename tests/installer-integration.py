#!/usr/bin/env python3
"""Exercise the installer CLI against disposable targets inside Docker.

Run after the tools phase. Uses real Stow, not package-manager or Stow mocks.
DOTFILES_TEST_PUBLIC_ROOT and optional DOTFILES_TEST_WORK_ROOT select checkouts.
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


PUBLIC = Path(os.environ.get("DOTFILES_TEST_PUBLIC_ROOT", "/home/vscode/dotfiles-public"))
WORK = os.environ.get("DOTFILES_TEST_WORK_ROOT")


class InstallerIntegrationTests(unittest.TestCase):
    def setUp(self):
        if not Path("/.dockerenv").is_file():
            self.fail("Run integration checks only inside a disposable Docker container")
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-integration-")
        self.addCleanup(self.temporary.cleanup)
        self.target = Path(self.temporary.name)

    def invoke(self, *arguments, overlay=None):
        command = [
            str(PUBLIC / "install.sh"), "--profile", "codespaces",
            "--target", str(self.target), *arguments,
        ]
        if overlay:
            command.extend(["--overlay", str(overlay)])
        return subprocess.run(command, text=True, capture_output=True, timeout=60)

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_plan_changes_nothing(self):
        result = self.invoke("--plan")
        self.assert_success(result)
        self.assertEqual(list(self.target.iterdir()), [])
        self.assertIn("Read-only filesystem plan complete", result.stdout)

    def test_conflict_preserves_existing_file_before_creating_state(self):
        existing = self.target / ".zshrc"
        existing.write_text("# preserve this user configuration\n")
        result = self.invoke("--config-only")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Conflict at", result.stderr)
        self.assertEqual(existing.read_text(), "# preserve this user configuration\n")
        self.assertEqual(list(self.target.iterdir()), [existing])
        self.assert_success(self.invoke("--plan", "--backup-file", ".zshrc"))
        self.assertEqual(list(self.target.iterdir()), [existing])
        self.assertFalse(existing.is_symlink())

    def test_apply_and_rerun_preserve_local_override_and_single_backup(self):
        existing = self.target / ".zshrc"
        existing.write_text("# original shell configuration\n")
        local = self.target / ".config/dotfiles-local/zsh/99-local.zsh"
        local.parent.mkdir(parents=True)
        local.write_text("export DOTFILES_TEST_MARKER=local\n")
        self.assert_success(self.invoke("--config-only", "--backup-file", ".zshrc"))
        self.assertEqual(existing.resolve(), PUBLIC / "zsh/.zshrc")
        self.assertEqual((self.target / ".config/git/config").resolve(),
                         PUBLIC / "git/.config/git/config")
        backups = list(self.target.glob(".local/state/dotfiles/*/backups/.zshrc"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "# original shell configuration\n")
        self.assert_success(self.invoke("--config-only"))
        self.assertEqual(list(self.target.glob(".local/state/dotfiles/*/backups/.zshrc")), backups)
        self.assertEqual(local.read_text(), "export DOTFILES_TEST_MARKER=local\n")
        self.assertFalse(local.is_symlink())

    def test_cross_layer_collision_is_rejected_before_writes(self):
        overlay = self.target / "overlay-source"
        (overlay / "profiles").mkdir(parents=True)
        (overlay / "profiles/codespaces.packages").write_text("work\n")
        (overlay / "profiles/required.commands").write_text("")
        (overlay / "Brewfile.essential").write_text("# no extra dependencies\n")
        (overlay / "work").mkdir()
        (overlay / "work/.zshrc").write_text("# conflicting owner\n")
        result = self.invoke("--plan", overlay=overlay)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Two packages own .zshrc", result.stderr)
        self.assertEqual(list(self.target.iterdir()), [overlay])

    def test_stow_failure_restores_authorized_backup(self):
        existing = self.target / ".zshrc"
        existing.write_text("# recover after a partial application\n")
        blocked = self.target / ".config"
        blocked.mkdir(mode=0o555)
        try:
            result = self.invoke("--config-only", "--backup-file", ".zshrc")
        finally:
            blocked.chmod(0o755)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("inspect recovery record", result.stderr)
        self.assertFalse(existing.is_symlink())
        self.assertEqual(existing.read_text(), "# recover after a partial application\n")
        self.assertEqual([path for path in self.target.rglob("*") if path.is_symlink()], [])

    @unittest.skipUnless(WORK, "This container intentionally has no private source")
    def test_work_layer_and_test_source_are_not_confused(self):
        self.assert_success(self.invoke("--config-only", overlay=WORK))
        extension = self.target / ".config/dotfiles-work/zsh/10-work.zsh"
        self.assertEqual(extension.resolve(), Path(WORK) / "work/.config/dotfiles-work/zsh/10-work.zsh")
        self.assertFalse((self.target / "tests").exists(), "Repository tests must not be deployed into HOME")
        result = self.invoke("--config-only")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Work extensions are already installed", result.stderr)
        self.assertTrue(extension.is_symlink())


if __name__ == "__main__":
    unittest.main(verbosity=2)
