import os
import tempfile
import unittest
from unittest.mock import Mock, patch

import openpyxl

from src.robot.libraries.ExcelLibrary import ExcelLibrary
from src.robot.libraries.SalesforceSupport import SalesforceSupport


class ExcelLibraryTransactionTests(unittest.TestCase):
    def setUp(self):
        self.temp_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_directory.cleanup)
        self.cv_path = os.path.join(self.temp_directory.name, "cv.xlsx")
        self.cdl_path = os.path.join(self.temp_directory.name, "cdl.xlsx")
        for path in (self.cv_path, self.cdl_path):
            workbook = openpyxl.Workbook()
            workbook.save(path)
            workbook.close()
        self.library = ExcelLibrary()
        self.links = [
            {
                "ContentDocumentId": "069000000000001",
                "LinkedEntityId": "001000000000001",
                "ShareType": "V",
                "Visibility": "AllUsers",
            }
        ]

    def write_rows(self):
        self.library.write_migration_rows_atomically(
            self.cv_path,
            2,
            "Title",
            "C:/download/file.bin",
            self.cdl_path,
            2,
            self.links,
            True,
            True,
        )

    def cell_value(self, path, row, column):
        workbook = openpyxl.load_workbook(path)
        try:
            return workbook.active.cell(row, column).value
        finally:
            workbook.close()

    def transaction_files(self):
        return [
            name
            for name in os.listdir(self.temp_directory.name)
            if name.startswith(".salesforce_migration_")
            or "_rollback_recovery_" in name
        ]

    def test_commits_both_workbooks_and_removes_temporary_files(self):
        self.write_rows()

        self.assertEqual(self.cell_value(self.cv_path, 2, 1), "Title")
        self.assertEqual(
            self.cell_value(self.cdl_path, 2, 1),
            "069000000000001",
        )
        self.assertEqual(self.transaction_files(), [])

    def test_staging_failure_leaves_originals_and_removes_temporary_files(self):
        with patch(
            "src.robot.libraries.ExcelLibrary.openpyxl.load_workbook",
            side_effect=OSError("simulated staging failure"),
        ):
            with self.assertRaisesRegex(OSError, "staging failure"):
                self.write_rows()

        self.assertIsNone(self.cell_value(self.cv_path, 2, 1))
        self.assertIsNone(self.cell_value(self.cdl_path, 2, 1))
        self.assertEqual(self.transaction_files(), [])

    def test_second_commit_failure_rolls_back_first_workbook(self):
        original_replace = os.replace

        def fail_second_commit(source, target):
            if (
                target == self.cdl_path
                and os.path.basename(source).startswith(
                    ".salesforce_migration_"
                )
            ):
                raise OSError("simulated second commit failure")
            return original_replace(source, target)

        with patch(
            "src.robot.libraries.ExcelLibrary.os.replace",
            side_effect=fail_second_commit,
        ):
            with self.assertRaisesRegex(OSError, "second commit failure"):
                self.write_rows()

        self.assertIsNone(self.cell_value(self.cv_path, 2, 1))
        self.assertIsNone(self.cell_value(self.cdl_path, 2, 1))
        self.assertEqual(self.transaction_files(), [])

    def test_failed_rollback_preserves_recovery_backup(self):
        original_replace = os.replace

        def fail_commit_and_rollback(source, target):
            source_name = os.path.basename(source)
            if (
                target == self.cdl_path
                and source_name.startswith(".salesforce_migration_")
            ):
                raise OSError("simulated second commit failure")
            if (
                target == self.cv_path
                and "_rollback_recovery_" in source_name
            ):
                raise OSError("simulated rollback failure")
            return original_replace(source, target)

        with patch(
            "src.robot.libraries.ExcelLibrary.os.replace",
            side_effect=fail_commit_and_rollback,
        ):
            with self.assertRaisesRegex(
                RuntimeError,
                "Preserved recovery backup",
            ):
                self.write_rows()

        recovery_files = [
            name
            for name in self.transaction_files()
            if "_rollback_recovery_" in name
        ]
        self.assertEqual(len(recovery_files), 1)
        recovery_path = os.path.join(
            self.temp_directory.name,
            recovery_files[0],
        )
        self.assertIsNone(self.cell_value(recovery_path, 2, 1))


class ExcelLibraryLifecycleTests(unittest.TestCase):
    def test_close_current_selects_next_workbook_after_close_failure(self):
        library = ExcelLibrary()
        first = Mock()
        first.close.side_effect = OSError("close failed")
        second = Mock()
        library._cache = {"first": first, "second": second}
        library._current_id = "first"

        with self.assertRaisesRegex(RuntimeError, "current Excel workbook"):
            library.close_current_excel_document()

        self.assertEqual(library._current_id, "second")
        self.assertEqual(library._cache, {"second": second})

    def test_close_all_attempts_every_workbook(self):
        library = ExcelLibrary()
        first = Mock()
        first.close.side_effect = OSError("close failed")
        second = Mock()
        library._cache = {"first": first, "second": second}
        library._current_id = "first"

        with self.assertRaisesRegex(RuntimeError, "1 Excel workbook"):
            library.close_all_excel_documents()

        first.close.assert_called_once_with()
        second.close.assert_called_once_with()
        self.assertEqual(library._cache, {})
        self.assertIsNone(library._current_id)


class SalesforceSupportJsonTests(unittest.TestCase):
    def setUp(self):
        self.support = SalesforceSupport()

    def test_try_parse_returns_false_for_empty_output(self):
        parsed, value = self.support.try_parse_first_json_value("")

        self.assertFalse(parsed)
        self.assertIsNone(value)

    def test_try_parse_returns_false_for_invalid_output(self):
        parsed, value = self.support.try_parse_first_json_value(
            "Salesforce CLI warning without JSON"
        )

        self.assertFalse(parsed)
        self.assertIsNone(value)

    def test_try_parse_returns_first_valid_json_value(self):
        parsed, value = self.support.try_parse_first_json_value(
            'Warning\n{"status": 0}\nTrailing text'
        )

        self.assertTrue(parsed)
        self.assertEqual(value, {"status": 0})


class SalesforceSupportPathTests(unittest.TestCase):
    def test_complete_filename_respects_destination_path_budget(self):
        support = SalesforceSupport()
        directory = os.path.join(
            tempfile.gettempdir(),
            "destination",
            "069000000000001",
        )

        filename = support.sanitize_local_filename_for_directory(
            f"{'x' * 300}.pdf",
            directory,
            max_filename_length=180,
            max_path_length=120,
        )

        complete_path = os.path.join(os.path.abspath(directory), filename)
        self.assertLessEqual(len(complete_path), 120)
        self.assertTrue(filename.endswith(".pdf"))

    def test_rejects_directory_without_filename_budget(self):
        support = SalesforceSupport()
        with self.assertRaisesRegex(ValueError, "no room"):
            support.sanitize_local_filename_for_directory(
                "file.txt",
                "x" * 30,
                max_path_length=10,
            )


class SalesforceSupportDownloadWaitTests(unittest.TestCase):
    def setUp(self):
        self.temp_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_directory.cleanup)
        self.support = SalesforceSupport()

    def test_accepts_completed_file_without_transient_failures(self):
        completed_path = os.path.join(self.temp_directory.name, "complete.pdf")
        with open(completed_path, "wb") as completed_file:
            completed_file.write(b"complete")

        result = self.support.wait_for_completed_download(
            self.temp_directory.name,
            0,
            [".crdownload", ".tmp", ".part"],
        )

        self.assertTrue(result)

    def test_times_out_when_only_temporary_file_exists(self):
        temporary_path = os.path.join(self.temp_directory.name, "pending.tmp")
        with open(temporary_path, "wb") as temporary_file:
            temporary_file.write(b"pending")

        with self.assertRaisesRegex(TimeoutError, "No completed download"):
            self.support.wait_for_completed_download(
                self.temp_directory.name,
                0,
                [".crdownload", ".tmp", ".part"],
            )
