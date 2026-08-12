#!/usr/bin/env python3
"""Validate mounts and core executables before a containerized download run."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import sys


APP = Path("/app")
AUTH_FILE = APP / "org_info.json"
OUTPUT_DIRECTORIES = (APP / "downloads", APP / "artifacts", APP / "results")
REQUIRED_AUTH_KEYS = ("accessToken", "instanceUrl", "apiVersion", "id", "alias")


def fail(message: str) -> None:
    print(f"Container preflight failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_auth_file() -> None:
    if not AUTH_FILE.is_file():
        fail(f"{AUTH_FILE} must be mounted as a read-only file")
    try:
        document = json.loads(AUTH_FILE.read_text(encoding="utf-8-sig"))
        result = document["result"]
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as error:
        fail(f"{AUTH_FILE} is not valid Salesforce CLI JSON ({error})")
    missing = [key for key in REQUIRED_AUTH_KEYS if not result.get(key)]
    if missing:
        fail(f"{AUTH_FILE} is missing result keys: {', '.join(missing)}")


def validate_directories() -> None:
    input_directory = APP / "input"
    if not input_directory.is_dir():
        fail(f"{input_directory} must be mounted as a directory")
    if not any(input_directory.glob("*.xlsx")):
        fail(f"{input_directory} does not contain an .xlsx input workbook")

    for directory in OUTPUT_DIRECTORIES:
        if not directory.is_dir():
            fail(f"{directory} must be mounted as a directory")
        if not os.access(directory, os.W_OK):
            fail(f"{directory} is not writable by uid {os.geteuid()}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--startup", action="store_true")
    parser.parse_args()

    if shutil.which("google-chrome") is None:
        fail("google-chrome is not available")
    if shutil.which("robot") is None:
        fail("robot is not available")
    validate_auth_file()
    validate_directories()
    print("Container preflight passed.")


if __name__ == "__main__":
    main()
