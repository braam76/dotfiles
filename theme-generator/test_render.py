import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

import render


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "themes").mkdir()
        (self.root / "templates").mkdir()
        self.output = self.root / "output"
        self.theme = {"name": "Test", "palette": {"bg": [192, 100, 5], "fg": "#ABCDEF"},
                      "roles": {"background": "bg", "foreground": "fg"}}
        self.config = {"theme": "themes/test.json", "templates": [
            {"template": "test.j2", "target": "app/colors.txt"}]}
        (self.root / "templates/test.j2").write_text("{{ roles.background }} {{ roles.foreground|rgb }}\n")
        self.save()

    def save(self):
        (self.root / "themes/test.json").write_text(json.dumps(self.theme))
        (self.root / "config.json").write_text(json.dumps(self.config))

    def test_hsl_and_hex(self):
        self.assertEqual(render.color([192, 100, 5]), "#00141a")
        self.assertEqual(render.color([0, 100, 50]), "#ff0000")
        self.assertEqual(render.color("#ABCDEF"), "#abcdef")
        self.assertEqual(render.color("NONE"), "NONE")
        for bad in ([0, 101, 50], [float("nan"), 0, 0], "not-a-color", [False, 0, 0]):
            with self.assertRaises(ValueError):
                render.color(bad)

    def test_check_idempotence_and_newline(self):
        self.assertEqual(render.render(self.root, self.output, check=True), 1)
        self.assertFalse(self.output.exists())
        self.assertEqual(render.render(self.root, self.output), 1)
        self.assertEqual((self.output / "app/colors.txt").read_text(), "#00141a 171,205,239\n")
        stamp = (self.output / "app/colors.txt").stat().st_mtime_ns
        self.assertEqual(render.render(self.root, self.output), 0)
        self.assertEqual((self.output / "app/colors.txt").stat().st_mtime_ns, stamp)

    def test_all_templates_render_before_any_write(self):
        self.config["templates"].append({"template": "bad.j2", "target": "bad.txt"})
        (self.root / "templates/bad.j2").write_text("{{ roles.typo }}")
        self.save()
        with self.assertRaises(Exception):
            render.render(self.root, self.output)
        self.assertFalse(self.output.exists())

    def test_invalid_json_does_not_replace_previous_outputs(self):
        render.render(self.root, self.output)
        before = (self.output / "app/colors.txt").read_bytes()
        (self.root / "themes/test.json").write_text("{")
        with self.assertRaises(ValueError):
            render.render(self.root, self.output)
        self.assertEqual((self.output / "app/colors.txt").read_bytes(), before)

    def test_output_escape_is_rejected(self):
        self.config["templates"][0]["target"] = "../escape.txt"
        self.save()
        with self.assertRaises(ValueError):
            render.render(self.root, self.output)
        self.output.mkdir()
        outside = self.root / "outside"
        outside.mkdir()
        (self.output / "link").symlink_to(outside)
        self.config["templates"][0]["target"] = "link/escape.txt"
        self.save()
        with self.assertRaises(ValueError):
            render.render(self.root, self.output)

    def test_duplicate_outputs_are_rejected(self):
        self.config["templates"] *= 2
        self.save()
        with self.assertRaises(ValueError):
            render.render(self.root, self.output)
        self.assertFalse(self.output.exists())

    def test_watch_updates_recovers_from_invalid_input_and_does_not_loop(self):
        process = subprocess.Popen([
            sys.executable, str(Path(render.__file__)), "--root", str(self.root),
            "--output-root", str(self.output), "--watch", "--interval", "0.05",
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        def stop():
            process.terminate()
            process.wait(timeout=5)
        self.addCleanup(stop)
        output = self.output / "app/colors.txt"
        def wait_for(expected):
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if output.exists() and output.read_text().startswith(expected):
                    return
                time.sleep(0.05)
            self.fail(f"Watcher did not generate {expected}")
        wait_for("#00141a")
        before = output.stat().st_mtime_ns
        (self.root / "themes/test.json").write_text("{")
        time.sleep(0.25)
        self.assertEqual(output.stat().st_mtime_ns, before)
        self.theme["palette"]["bg"] = "#123456"
        self.save()
        wait_for("#123456")
        before = output.stat().st_mtime_ns
        time.sleep(0.25)
        self.assertEqual(output.stat().st_mtime_ns, before)
        self.assertIsNone(process.poll())


if __name__ == "__main__":
    unittest.main()
