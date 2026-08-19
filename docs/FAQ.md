# Frequently Asked Questions

## Why use Selenium?

Salesforce Shepherd downloads need an authenticated browser session. Selenium creates and manages that Chrome session, while the REST API handles metadata queries.

## Why use Robot Framework?

Robot Framework ties the workflow together and provides readable logs, reports, reusable keywords, cleanup, and Pabot support. Python handles the lower-level browser, Excel, filesystem, and validation work.

## Why not use the Bulk API for binary files?

The Bulk API is well suited to record operations, but this project also needs authenticated binary delivery and local download validation. It therefore uses REST and SOQL for metadata and Shepherd for the files themselves.

## Does the tool consume Salesforce API calls?

Yes. Each non-empty batch checks the REST limits endpoint and then runs its metadata queries. Pagination may add more calls, but Shepherd delivers the binaries, so retrying a download does not repeat the metadata queries. See [Configuration](Configuration.md#processing-controls) for the full estimate.

## How are duplicate ContentDocument IDs handled?

The tool converts valid 15-character IDs to their canonical 18-character form before removing duplicates. If a workbook contains both versions of the same ID, the file is downloaded once. Deduplication applies within a batch; separate workbooks can still process the same document.

## How are multiple ContentDocumentLink records handled?

The metadata query collects every link visible to the authenticated user. When link-workbook generation is enabled, each relationship gets its own row, but the file is still downloaded only once per batch.

## Can interrupted executions be resumed?

Only within a limited sense. Failed downloads can be retried during the same run, but each attempt starts from the beginning. After an interrupted run—or when retries are exhausted—use the generated failure workbook as the input for a new run.

## Which failures are retried automatically?

Valid IDs with the required metadata are eligible for another download attempt. Invalid IDs and records missing required metadata go straight to the failure report. Retries reuse the batch's metadata and session, so they cannot repair an expired session.

## How are downloads validated?

The tool waits for the browser's temporary file to disappear, checks that the size has stopped changing, and compares it with Salesforce `ContentSize`. It then moves the file to its final directory and verifies the destination. When migration workbooks are enabled, their update must also succeed; otherwise, the moved file is removed so the next run starts cleanly.

## Are Salesforce access tokens written to logs?

Operations that handle the access token suppress normal Robot logging. The token is stored locally in `org_info.json`, so never commit or share that file. Reports may still contain customer IDs, filenames, and diagnostic details; review them before sharing. If a token is exposed, revoke the Salesforce session immediately. The safe credential-generation steps are in [Authentication](Authentication.md).

## Can files be uploaded directly to S3?

No. The downloader writes files to local storage. It does not upload directly to S3 or another cloud-storage service.

## Which operating systems are supported?

The setup guide covers Windows, Linux, and macOS, with Chrome as the supported browser path. CI tests Python 3.10 and 3.11 on Ubuntu and Windows. Your environment must still provide compatible Python, Chrome, and Salesforce CLI versions, along with the required filesystem and headless-browser permissions.

## How many workers should be used?

Start small and increase the worker count while watching CPU, memory, disk, network use, Salesforce response times, and failures. The [performance guide](Performance.md) includes a benchmark and scaling advice.

---

[← Previous](Troubleshooting.md) | [Next →](Limitations.md)

[Back to README](../README.md)
