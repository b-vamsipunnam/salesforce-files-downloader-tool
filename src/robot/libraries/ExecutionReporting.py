"""Structured failure reporting and durable JSONL execution manifests."""

from __future__ import annotations

import json
import os
import re
import threading
import uuid
from datetime import datetime, timezone
from typing import Any
from urllib.parse import urlsplit, urlunsplit


FAILURE_CODES = frozenset(
    {
        "INVALID_CONTENT_DOCUMENT_ID",
        "CONTENT_DOCUMENT_NOT_FOUND",
        "CONTENT_DOCUMENT_LINK_NOT_FOUND",
        "SALESFORCE_API_FAILURE",
        "AUTH_SESSION_EXPIRED",
        "DOWNLOAD_NAVIGATION_FAILED",
        "DOWNLOAD_APPEAR_TIMEOUT",
        "DOWNLOAD_COMPLETION_TIMEOUT",
        "MULTIPLE_FILES_NO_SIZE_MATCH",
        "CONTENT_SIZE_MISMATCH",
        "FILE_NOT_STABLE",
        "FILE_MOVE_FAILED",
        "FINAL_FILE_VALIDATION_FAILED",
        "WORKBOOK_TRANSACTION_FAILED",
        "UNEXPECTED_ERROR",
    }
)

_SECRET_PATTERNS = (
    re.compile(r"(?i)(authorization\s*[:=]\s*bearer\s+)[^\s,;]+"),
    re.compile(r"(?i)(bearer\s+)[A-Za-z0-9._~+/=-]+"),
    re.compile(r'(?i)(["\']?accessToken["\']?\s*[:=]\s*["\']?)[^"\'\s,}]+'),
    re.compile(r"(?i)(\bsid=)[^&\s]+"),
)
_SPREADSHEET_FORMULA_PREFIXES = ("=", "+", "-", "@")


class ExecutionReporting:
    """Robot Framework library for per-batch reporting state."""

    ROBOT_LIBRARY_SCOPE = "TEST"
    ROBOT_AUTO_KEYWORDS = True

    def __init__(self) -> None:
        self.manifest_path: str | None = None
        self.run_id: str | None = None
        self.batch_id: str | None = None
        self.worker_id: str | None = None
        self._attempts: dict[str, int] = {}
        self._failures: dict[str, dict[str, Any]] = {}
        self._started: dict[str, dict[str, Any]] = {}
        self._reporting_errors: list[str] = []
        self._lock = threading.Lock()

    def initialize_execution_reporting(
        self,
        output_directory: str,
        batch_id: str,
        worker_id: str | None = None,
    ) -> str:
        os.makedirs(output_directory, exist_ok=True)
        self.run_id = uuid.uuid4().hex
        self.batch_id = str(batch_id)
        self.worker_id = str(worker_id or "local")
        safe_batch = re.sub(r"[^A-Za-z0-9_.-]+", "_", self.batch_id).strip("._")
        safe_batch = safe_batch or "batch"
        self.manifest_path = os.path.join(
            os.path.abspath(output_directory),
            f"{safe_batch}_execution_manifest.jsonl",
        )
        self._attempts.clear()
        self._failures.clear()
        self._started.clear()
        self._reporting_errors.clear()
        self._append_event("EXECUTION_STARTED", strict=True, Status="RUNNING")
        return self.manifest_path

    def start_document_attempt(
        self,
        content_document_id: str,
        content_version_id: str | None = None,
        original_title: str | None = None,
        local_file_name: str | None = None,
        local_path: str | None = None,
        expected_size: Any = None,
        content_document_link_count: Any = None,
    ) -> int:
        content_id = str(content_document_id)
        attempt = self._attempts.get(content_id, 0) + 1
        self._attempts[content_id] = attempt
        details = dict(self._started.get(content_id, {}))
        supplied = {
            "ContentDocumentId": content_id,
            "ContentVersionId": content_version_id,
            "OriginalTitle": original_title,
            "LocalFileName": local_file_name,
            "LocalPath": local_path,
            "ExpectedSize": self._as_int_or_none(expected_size),
            "ContentDocumentLinkCount": self._as_int_or_none(
                content_document_link_count
            ),
        }
        details.update(
            {key: value for key, value in supplied.items() if value is not None}
        )
        details.update(AttemptCount=attempt, StartedAt=self._utc_now())
        self._started[content_id] = details
        self._append_event("DOCUMENT_ATTEMPT_STARTED", Status="RUNNING", **details)
        return attempt

    def record_document_failure(
        self,
        content_document_id: str,
        failure_code: str,
        failure_message: Any,
        retryable: Any = True,
    ) -> dict[str, Any]:
        self._validate_failure_code(failure_code)
        content_id = str(content_document_id)
        record = dict(self._started.get(content_id, {}))
        record.update(
            {
                "ContentDocumentId": content_id,
                "FailureCode": failure_code,
                "FailureMessage": self.redact_sensitive_text(failure_message),
                "AttemptCount": self._attempts.get(content_id, 0),
                "Retryable": self._as_bool(retryable),
                "CompletedAt": self._utc_now(),
            }
        )
        self._failures[content_id] = record
        self._append_event("DOCUMENT_ATTEMPT_FAILED", Status="FAILED", **record)
        return dict(record)

    def record_document_success(
        self,
        content_document_id: str,
        actual_size: Any = None,
        local_path: str | None = None,
    ) -> dict[str, Any]:
        content_id = str(content_document_id)
        record = dict(self._started.get(content_id, {}))
        if local_path is not None:
            record["LocalPath"] = local_path
        record.update(
            {
                "ContentDocumentId": content_id,
                "ActualSize": self._as_int_or_none(actual_size),
                "AttemptCount": self._attempts.get(content_id, 0),
                "CompletedAt": self._utc_now(),
            }
        )
        self._failures.pop(content_id, None)
        self._started.pop(content_id, None)
        self._append_event("DOCUMENT_SUCCEEDED", Status="SUCCESS", **record)
        return dict(record)

    def record_execution_failure(self, failure_code: str, message: Any) -> None:
        self._validate_failure_code(failure_code)
        self._append_event(
            "EXECUTION_FAILED",
            Status="FAILED",
            FailureCode=failure_code,
            FailureMessage=self.redact_sensitive_text(message),
        )

    def complete_execution_reporting(
        self,
        successful_count: Any,
        failed_count: Any,
        total_count: Any,
        execution_failed: Any = False,
    ) -> None:
        if self.manifest_path:
            final_status = (
                "FAILED"
                if int(failed_count)
                or self._as_bool(execution_failed)
                or self._reporting_errors
                else "SUCCESS"
            )
            self._append_event(
                "EXECUTION_COMPLETED",
                Status=final_status,
                SuccessfulCount=int(successful_count),
                FailedCount=int(failed_count),
                TotalCount=int(total_count),
            )
        self._started.clear()
        self._attempts.clear()

    def get_execution_reporting_error(self) -> str | None:
        if not self._reporting_errors:
            return None
        return "; ".join(self._reporting_errors[:5])

    def get_failure_records(
        self, content_document_ids: list[Any]
    ) -> list[dict[str, Any]]:
        return [
            dict(self._failures[str(content_id)])
            for content_id in content_document_ids
            if str(content_id) in self._failures
        ]

    def get_document_failure_code(self, content_document_id: str) -> str | None:
        record = self._failures.get(str(content_document_id))
        return record.get("FailureCode") if record else None

    def is_document_failure_retryable(self, content_document_id: str) -> bool:
        record = self._failures.get(str(content_document_id))
        return bool(record and record.get("Retryable"))

    def redact_sensitive_text(self, value: Any) -> str:
        text = str(value)
        for pattern in _SECRET_PATTERNS:
            text = pattern.sub(r"\1[REDACTED]", text)
        try:
            parts = urlsplit(text)
            if parts.scheme and parts.netloc and parts.query:
                text = urlunsplit(
                    (parts.scheme, parts.netloc, parts.path, "", parts.fragment)
                )
        except ValueError:
            pass
        return text[:2000]

    def sanitize_spreadsheet_cell(self, value: Any) -> str:
        text = self.redact_sensitive_text(value)
        if text.startswith(_SPREADSHEET_FORMULA_PREFIXES):
            return f"'{text}"
        return text

    def is_salesforce_auth_failure(self, status_code: Any, response_text: Any) -> bool:
        if str(status_code) == "401":
            return True
        return "INVALID_SESSION_ID" in str(response_text).upper()

    def is_salesforce_login_url(self, url: Any) -> bool:
        try:
            parts = urlsplit(str(url))
        except ValueError:
            return False
        host = (parts.hostname or "").lower()
        path = parts.path.lower()
        login_host = host in {"login.salesforce.com", "test.salesforce.com"}
        login_path = path.startswith("/secur/login") or path.startswith("/login")
        stuck_at_frontdoor = path.startswith("/secur/frontdoor.jsp")
        return login_host or login_path or stuck_at_frontdoor

    def file_looks_like_html(self, path: str) -> bool:
        try:
            with open(path, "rb") as stream:
                prefix = stream.read(1024).lstrip().lower()
        except OSError:
            return False
        if not prefix.startswith((b"<!doctype html", b"<html")):
            return False
        login_markers = (
            b"/secur/login",
            b"/secur/frontdoor.jsp",
            b"login.salesforce.com",
            b"test.salesforce.com",
            b'name="username"',
            b'id="username"',
            b"salesforce login",
        )
        return any(marker in prefix for marker in login_markers)

    def _append_event(
        self, event_type: str, strict: bool = False, **fields: Any
    ) -> bool:
        if not self.manifest_path:
            return False
        if (
            self._reporting_errors
            and not strict
            and event_type != "EXECUTION_COMPLETED"
        ):
            return False
        event = {
            "SchemaVersion": 1,
            "RunId": self.run_id,
            "BatchId": self.batch_id,
            "WorkerId": self.worker_id,
            "EventType": event_type,
            "Timestamp": self._utc_now(),
            **{key: value for key, value in fields.items() if value is not None},
        }
        serialized = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
        try:
            with self._lock:
                with open(
                    self.manifest_path, "a", encoding="utf-8", newline="\n"
                ) as stream:
                    stream.write(serialized + "\n")
                    stream.flush()
            return True
        except OSError as error:
            message = self.redact_sensitive_text(
                f"Manifest event {event_type} could not be written: {error}"
            )
            if message not in self._reporting_errors:
                self._reporting_errors.append(message)
            if strict:
                raise RuntimeError(message) from error
            return False

    @staticmethod
    def _utc_now() -> str:
        return (
            datetime.now(timezone.utc)
            .isoformat(timespec="milliseconds")
            .replace("+00:00", "Z")
        )

    @staticmethod
    def _as_int_or_none(value: Any) -> int | None:
        if value is None or str(value).upper() == "NONE" or str(value) == "":
            return None
        return int(value)

    @staticmethod
    def _as_bool(value: Any) -> bool:
        if isinstance(value, bool):
            return value
        return str(value).strip().lower() not in {"false", "no", "0", "none", ""}

    @staticmethod
    def _validate_failure_code(failure_code: str) -> None:
        if failure_code not in FAILURE_CODES:
            raise ValueError(f"Unknown failure code: {failure_code}")
