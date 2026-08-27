# Architecture

This page is an advanced overview of how one batch moves from an Excel ID list to validated local files and migration records.

<p align="center">
  <img src="architecture.svg" width="1200" alt="Salesforce Files Bulk Downloader architecture">
</p>

The diagram is stored as [`architecture.svg`](architecture.svg).

## Main components

- **Salesforce CLI** authenticates the source org and supplies the org context used to create `org_info.json`.
- **Salesforce REST API** returns `DailyApiRequests`, `ContentDocument` metadata, and visible `ContentDocumentLink` records through paginated Salesforce Object Query Language (SOQL) queries.
- **Selenium and Chrome** create the authenticated browser session and request file binaries from Salesforce Shepherd, Salesforce's file-delivery endpoint.
- **Robot Framework** coordinates each batch, reports test status, and calls the reusable resource keywords.
- **Python libraries** handle CLI JSON, ID canonicalization, filename safety, Excel transactions, manifests, and browser options.
- **Pabot** can run batch tests in separate worker processes.

## Batch flow

1. Create the batch artifact directory and start its JSONL manifest.
2. Read the workbook, convert valid 15-character IDs to 18 characters, and remove duplicates within the batch.
3. Create an authenticated REST session and check estimated API capacity.
4. Query `ContentDocument` metadata and, when requested, every visible `ContentDocumentLink` for the input IDs. Pagination is followed until Salesforce reports the query complete.
5. Start headless Chrome through the Salesforce frontdoor session and request each document from Shepherd.
6. Wait for a completed file, reject Salesforce HTML responses, confirm size stability, compare the size with `ContentSize`, and move the file into its `ContentDocumentId` directory.
7. Commit requested migration rows. Only then record `DOCUMENT_SUCCEEDED`.
8. Retry supported transient failures within the configured bound, write unresolved failures, complete the manifest, and close the browser.

The metadata request and binary request use different channels: REST supplies structured records; the authenticated browser supplies the file. Both remain subject to Salesforce permissions and session lifetime.

## Consistency rules

- **One physical file per document per batch:** equivalent 15- and 18-character IDs are canonicalized before deduplication. Separate batches are not globally deduplicated.
- **Separate relationship records:** a successful file can create several link rows because a `ContentDocument` can have several visible `ContentDocumentLink` records.
- **Validation before success:** completion, stable size, expected size, final movement, destination verification, and requested workbook commits all precede success reporting.
- **Transactional migration output:** if a requested workbook update fails, the moved binary is removed so the next run does not inherit an ambiguous partial success.
- **Explicit failure:** invalid IDs, missing metadata, expired sessions, failed validation, and unresolved transient errors remain failed. A missing binary is never converted to success.
- **Bounded recovery:** only structured failures marked as retryable receive extra full-download attempts. Sessions are not renewed and partial binaries are not resumed.
- **Worker isolation:** each batch receives unique download and artifact directories. Workers share `org_info.json` but do not share an API-capacity reservation.
- **Sensitive output handling:** token operations suppress normal logs, but manifests, workbooks, filenames, and reports can still contain Salesforce data.

For individual resource and library entry points, see [Keyword documentation](Keyword-Documentation.md).

[Back to README](../README.md)
