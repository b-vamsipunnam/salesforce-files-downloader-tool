# Frequently Asked Questions

## Why use Selenium?

Selenium establishes and manages the authenticated Chrome session required for Salesforce Shepherd downloads. REST remains responsible for structured metadata queries.

## Why use Robot Framework?

Robot Framework provides workflow orchestration, logging, reports, reusable keywords, teardown handling, and Pabot integration. Python libraries handle lower-level browser, Excel, filesystem, and validation operations.

## Why not use the Bulk API for binary files?

This project uses REST and SOQL for metadata and Shepherd for file delivery. Bulk-oriented APIs are useful for record operations, but this workflow requires authenticated binary delivery and local browser-download validation.

## Does the tool consume Salesforce API calls?

Yes. Each batch normally uses one limits request for its API-capacity preflight, followed by REST API queries for metadata. A transient CLI failure can cause the limits request to be attempted again, and metadata pagination can add query calls. Binary transfer uses Shepherd rather than REST binary requests. API consumption therefore depends on input volume, `${METADATA_BATCH_SIZE}`, whether ContentDocumentLink metadata is requested, retry activity, and query pagination.

## How are duplicate ContentDocument IDs handled?

Valid 15-character IDs are converted to their canonical 18-character form before duplicates are removed. As a result, a workbook containing both forms of the same Salesforce ID produces one download, not two. Deduplication remains batch-local, so overlapping IDs in separate input workbooks can still be processed by separate workers.

## How are multiple ContentDocumentLink records handled?

The metadata query retrieves all visible links for each requested document. When link-workbook generation is enabled, one output row is written for every retrieved relationship while the physical file is downloaded once per batch.

## Can interrupted executions be resumed?

An individual failed download can be attempted again automatically during the same run. Downloads always restart from the beginning; partially downloaded files are not resumed. If the whole Robot execution is interrupted, or an ID remains unsuccessful after its configured attempts, rerun the IDs from the generated failure workbook.

## Which failures are retried automatically?

Valid ContentDocument IDs with the required metadata are eligible for another full download attempt. Invalid IDs and IDs missing ContentDocument or required ContentDocumentLink metadata are kept in the failure report without retrying. The retry pass reuses the metadata and authenticated sessions created for the batch; it does not refresh an expired session or repeat the metadata queries.

## How are downloads validated?

The downloader rejects temporary browser extensions, waits for completion and stable size, compares the file with Salesforce `ContentSize`, moves it into its final ID directory, and verifies the destination. If migration workbooks are enabled, their transaction must also commit before the ID is marked successful. A workbook failure removes the moved binary so a rerun starts from a consistent state.

## Are Salesforce access tokens written to logs?

Token-bearing initialization and request operations suppress ordinary Robot logging. The token remains in the local `org_info.json`, which must not be committed or shared. Review generated XML and HTML reports before sharing them because customer IDs, filenames, and diagnostic details may still be sensitive. Revoke the Salesforce session immediately if a token is ever exposed.

## Can files be uploaded directly to S3?

No. This repository writes downloaded files to local storage and does not upload them directly to Amazon S3.

## Which operating systems are supported?

The documentation provides environment commands for Windows, Linux, and macOS. Chrome is the primary browser path. CI exercises Python 3.10 and 3.11 on both Ubuntu and Windows, including a real headless-Chrome smoke run on Ubuntu and Robot validation on Windows. Actual compatibility still depends on Python, Chrome, Salesforce CLI, filesystem permissions, and headless-browser support in the deployment environment.

## How many workers should be used?

There is no universal value. Start with a small number of workers and increase gradually while monitoring CPU, memory, disk, network, Salesforce response behavior, and failure rate. Review the [performance guidance](Performance.md) before increasing workers.

---

[← Previous](Troubleshooting.md) | [Next →](Limitations.md)

[Back to README](../README.md)
