import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from scripts.simulation import experiment_driver, save_trials


class ReproductionTest(unittest.TestCase):
    def test_original_trial_files_reproduce_byte_for_byte(self):
        checks = json.loads(Path(__file__).with_name("trial-checksums.json").read_text())
        with tempfile.TemporaryDirectory() as directory:
            for bits in (8, 12, 16):
                rows = experiment_driver(900, bits, 37430101)
                path = save_trials(rows, Path(directory))
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), checks[path.name])
                self.assertEqual(len({row["trial_id"] for row in rows}), 900)


if __name__ == "__main__":
    unittest.main()
