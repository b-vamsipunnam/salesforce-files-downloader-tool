"""
Adds functionality to Robot Framework SeleniumLibrary Browser Management.
E.g. from https://github.com/robotframework/SeleniumLibrary/blob/master/docs/extending/extending/InheritSeleniumLibrary.py
"""
import json
import os
import platform
import re
import time
from typing import Any

import selenium
from robot.utils import timestr_to_secs


_INVALID_FILENAME_CHARACTERS = re.compile(r'[<>:"/\\|?*\x00-\x1F]')
_CONTENT_DOCUMENT_ID = re.compile(r"069[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?")
_SALESFORCE_ID_CHECKSUM_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"
_WINDOWS_RESERVED_NAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *(f"COM{i}" for i in range(1, 10)),
    *(f"LPT{i}" for i in range(1, 10)),
}
_CHROME_OPTIONS_PATCHED = False


class SalesforceSupport:

    def canonicalize_content_document_id(self, content_id: Any) -> str:
        """Return the canonical 18-character form of a valid document ID."""
        normalized = str(content_id).strip()
        if not _CONTENT_DOCUMENT_ID.fullmatch(normalized):
            return normalized
        if len(normalized) == 18:
            return normalized

        checksum = []
        for chunk_start in range(0, 15, 5):
            flags = 0
            for offset, character in enumerate(
                normalized[chunk_start : chunk_start + 5]
            ):
                if character.isupper():
                    flags |= 1 << offset
            checksum.append(_SALESFORCE_ID_CHECKSUM_CHARACTERS[flags])
        return f"{normalized}{''.join(checksum)}"

    def patch_salesforce_chrome(self) -> None:
        """Add the Linux no-sandbox option to Chrome once per process."""
        global _CHROME_OPTIONS_PATCHED

        if platform.system() == "Linux" and not _CHROME_OPTIONS_PATCHED:
            options_class = selenium.webdriver.chrome.options.Options
            old_init = options_class.__init__

            def new_init(self, *args, **kwargs):
                old_init(self, *args, **kwargs)
                self.add_argument("--no-sandbox")

            options_class.__init__ = new_init
            _CHROME_OPTIONS_PATCHED = True

    def parse_first_json_value(self, raw_output: str) -> Any:
        """Return the first valid JSON object or array found in CLI output."""
        if not isinstance(raw_output, str):
            raise TypeError("Salesforce CLI output must be a string.")

        decoder = json.JSONDecoder()
        candidate_positions = [
            index
            for index, character in enumerate(raw_output)
            if character in "{["
        ]

        for position in candidate_positions:
            try:
                value, _ = decoder.raw_decode(raw_output[position:])
                return value
            except json.JSONDecodeError:
                continue

        raise ValueError(
            "No valid JSON object or array found in Salesforce CLI output."
        )

    def try_parse_first_json_value(
        self,
        raw_output: str,
    ) -> tuple[bool, Any | None]:
        """Try to parse CLI JSON without raising for expected invalid output."""
        try:
            return True, self.parse_first_json_value(raw_output)
        except (TypeError, ValueError):
            return False, None

    def sanitize_local_filename(
        self,
        filename: str | None,
        fallback: str = "salesforce_file",
        max_length: int = 180,
    ) -> str:
        """Return a bounded, cross-platform filename safe for local storage."""
        max_length = int(max_length)
        if max_length < 1:
            raise ValueError("max_length must be at least 1.")

        sanitized = self._normalize_filename_candidate(filename, max_length)
        if not sanitized:
            sanitized = self._normalize_filename_candidate(fallback, max_length)
        if not sanitized:
            sanitized = self._normalize_filename_candidate(
                "salesforce_file",
                max_length,
            )

        return sanitized

    def sanitize_local_filename_for_directory(
        self,
        filename: str | None,
        directory: str,
        fallback: str = "salesforce_file",
        max_filename_length: int = 180,
        max_path_length: int = 240,
    ) -> str:
        """Sanitize a filename using the remaining destination path budget."""
        max_filename_length = int(max_filename_length)
        max_path_length = int(max_path_length)
        directory_length = len(os.path.abspath(str(directory)))
        available_length = max_path_length - directory_length - 1
        bounded_length = min(max_filename_length, available_length)
        if bounded_length < 1:
            raise ValueError(
                "Destination directory leaves no room for a filename within "
                f"the configured {max_path_length}-character path limit."
            )
        return self.sanitize_local_filename(
            filename,
            fallback=fallback,
            max_length=bounded_length,
        )

    def wait_for_completed_download(
        self,
        download_directory: str,
        timeout: str | float,
        temp_suffixes: list[str],
        interval: str | float = "0.5s",
    ) -> bool:
        """Wait without emitting transient assertion failures into Robot logs."""
        timeout_seconds = float(timestr_to_secs(timeout))
        interval_seconds = float(timestr_to_secs(interval))
        if timeout_seconds < 0 or interval_seconds <= 0:
            raise ValueError(
                "Download timeout cannot be negative and interval must be positive."
            )

        directory = os.path.abspath(str(download_directory))
        suffixes = tuple(str(value).lower() for value in temp_suffixes)
        deadline = time.monotonic() + timeout_seconds
        while True:
            if os.path.isdir(directory):
                for name in os.listdir(directory):
                    path = os.path.join(directory, name)
                    if os.path.isfile(path) and not name.lower().endswith(suffixes):
                        return True
            if time.monotonic() >= deadline:
                raise TimeoutError(
                    "No completed download appeared within "
                    f"{timeout_seconds:g} seconds."
                )
            time.sleep(min(interval_seconds, max(0, deadline - time.monotonic())))

    @staticmethod
    def _normalize_filename_candidate(
        value: str | None,
        max_length: int,
    ) -> str:
        """Normalize one candidate while preserving the final file extension."""
        if value is None:
            return ""

        sanitized = _INVALID_FILENAME_CHARACTERS.sub("_", str(value))
        sanitized = sanitized.rstrip(" .")
        if not sanitized:
            return ""

        stem, extension = os.path.splitext(sanitized)
        stem = stem.rstrip(" .")
        if not stem:
            extension = ""
            stem = sanitized.rstrip(" .")

        if len(stem) + len(extension) > max_length:
            if extension and len(extension) < max_length:
                stem = stem[: max_length - len(extension)].rstrip(" .")
            else:
                stem = sanitized[:max_length].rstrip(" .")
                extension = ""

        if not stem:
            return ""

        if stem.upper() in _WINDOWS_RESERVED_NAMES:
            available_stem_length = max_length - len(extension)
            stem = f"_{stem}"[:available_stem_length].rstrip(" .")

        return f"{stem}{extension}"
