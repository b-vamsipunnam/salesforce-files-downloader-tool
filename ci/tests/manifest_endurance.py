"""Offline 100,000-document reporting endurance and reconciliation check."""

import json
import os
import tempfile
import time

from src.robot.libraries.ExecutionReporting import ExecutionReporting


DOCUMENT_COUNT = 100_000


def main() -> None:
    started = time.monotonic()
    with tempfile.TemporaryDirectory() as directory:
        reporting = ExecutionReporting()
        manifest = reporting.initialize_execution_reporting(
            directory, "endurance-100k", "simulation-worker"
        )
        expected_successes = 0
        expected_failures = 0

        for index in range(DOCUMENT_COUNT):
            content_id = f"069{index:015d}"
            reporting.start_document_attempt(
                content_id,
                f"068{index:015d}",
                f"Document {index}",
                f"document-{index}.bin",
                os.path.join(directory, content_id, f"document-{index}.bin"),
                1024 + index,
                index % 5,
            )
            if index % 10:
                reporting.record_document_success(content_id, 1024 + index)
                expected_successes += 1
                continue

            reporting.record_document_failure(
                content_id,
                "DOWNLOAD_APPEAR_TIMEOUT",
                "Simulated transient timeout",
            )
            reporting.start_document_attempt(content_id)
            if index % 50:
                reporting.record_document_success(content_id, 1024 + index)
                expected_successes += 1
            else:
                reporting.record_document_failure(
                    content_id,
                    "DOWNLOAD_COMPLETION_TIMEOUT",
                    "Simulated exhausted retry",
                )
                expected_failures += 1

        reporting.complete_execution_reporting(
            expected_successes, expected_failures, DOCUMENT_COUNT
        )

        event_counts: dict[str, int] = {}
        latest_document_events: dict[str, dict] = {}
        final_event = None
        line_count = 0
        with open(manifest, encoding="utf-8") as stream:
            for line in stream:
                event = json.loads(line)
                line_count += 1
                event_type = event["EventType"]
                event_counts[event_type] = event_counts.get(event_type, 0) + 1
                content_id = event.get("ContentDocumentId")
                if content_id and event_type in {
                    "DOCUMENT_ATTEMPT_FAILED",
                    "DOCUMENT_SUCCEEDED",
                }:
                    latest_document_events[content_id] = event
                final_event = event

        assert final_event is not None
        assert final_event["EventType"] == "EXECUTION_COMPLETED"
        assert final_event["SuccessfulCount"] == expected_successes
        assert final_event["FailedCount"] == expected_failures
        assert expected_successes + expected_failures == DOCUMENT_COUNT
        assert event_counts["DOCUMENT_SUCCEEDED"] == expected_successes
        assert event_counts["DOCUMENT_ATTEMPT_FAILED"] == 10_000 + expected_failures
        assert len(latest_document_events) == DOCUMENT_COUNT
        latest_successes = [
            event
            for event in latest_document_events.values()
            if event["EventType"] == "DOCUMENT_SUCCEEDED"
        ]
        latest_failures = [
            event
            for event in latest_document_events.values()
            if event["EventType"] == "DOCUMENT_ATTEMPT_FAILED"
        ]
        assert len(latest_successes) == expected_successes
        assert len(latest_failures) == expected_failures
        required_metadata = {
            "ContentVersionId",
            "OriginalTitle",
            "LocalFileName",
            "LocalPath",
            "ExpectedSize",
            "ContentDocumentLinkCount",
        }
        assert all(
            required_metadata <= event.keys()
            for event in latest_document_events.values()
        )
        assert all(
            event["AttemptCount"] in {1, 2} for event in latest_document_events.values()
        )

        elapsed = time.monotonic() - started
        size_mb = os.path.getsize(manifest) / (1024 * 1024)
        print(
            json.dumps(
                {
                    "documents": DOCUMENT_COUNT,
                    "successes": expected_successes,
                    "failures": expected_failures,
                    "events": line_count,
                    "manifestMiB": round(size_mb, 2),
                    "elapsedSeconds": round(elapsed, 2),
                    "jsonlValid": True,
                    "reconciliationValid": True,
                },
                indent=2,
            )
        )


if __name__ == "__main__":
    main()
