#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("validate_release_docs.py")
SPEC = importlib.util.spec_from_file_location("validate_release_docs", SCRIPT)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ReleaseDocsValidatorTests(unittest.TestCase):
    def test_repository_release_documents_are_consistent(self) -> None:
        errors: list[str] = []
        MODULE.validate_store_doc(errors)
        MODULE.validate_device_log(errors)
        MODULE.validate_privacy_manifest(errors)
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
