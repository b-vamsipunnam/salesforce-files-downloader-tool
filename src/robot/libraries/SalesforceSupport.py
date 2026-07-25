"""
Adds functionality to Robot Framework SeleniumLibrary Browser Management.
E.g. from https://github.com/robotframework/SeleniumLibrary/blob/master/docs/extending/extending/InheritSeleniumLibrary.py
"""
import json
import platform
import re
from typing import Any

import selenium


_WINDOWS_RESERVED_NAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *(f"COM{i}" for i in range(1, 10)),
    *(f"LPT{i}" for i in range(1, 10)),
}


class SalesforceSupport:

    def patch_salesforce_chrome(self):
        """
        Patches salesforce chrome browser by adding an extra option
        """
        if platform.system() == "Linux":
            old_init = selenium.webdriver.chrome.options.Options.__init__
            def new_init(self, *args, **kwargs):
                old_init(self, *args, **kwargs)
                self.add_argument("--no-sandbox")
            selenium.webdriver.chrome.options.Options.__init__ = new_init

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

    def sanitize_local_filename(
        self,
        filename: str,
        fallback: str = "salesforce_file",
    ) -> str:
        """Return a cross-platform filename safe for local download storage."""
        sanitized = re.sub(r'[<>:"/\\|?*\x00-\x1F]', "_", str(filename))
        sanitized = sanitized.rstrip(" .")

        if not sanitized:
            sanitized = fallback

        base_name = sanitized.split(".", 1)[0].upper()
        if base_name in _WINDOWS_RESERVED_NAMES:
            sanitized = f"_{sanitized}"

        return sanitized
