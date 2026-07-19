# Frequently Asked Questions

## Why use Selenium?

Selenium establishes and manages the authenticated Chrome session required for Salesforce Shepherd downloads. REST remains responsible for structured metadata queries.

## Why use Robot Framework?

Robot Framework provides workflow orchestration, logging, reports, reusable keywords, teardown handling, and Pabot integration. Python libraries handle lower-level browser, Excel, filesystem, and validation operations.

## Why not use the Bulk API for binary files?

This project uses REST and SOQL for metadata and Shepherd for file delivery. Bulk-oriented APIs are useful for record operations, but this workflow requires authenticated binary delivery and local browser-download validation.

## Does the tool consume Salesforce API calls?

Yes. Metadata retrieval uses REST API query calls, including pagination when required. Binary transfer uses Shepherd rather than REST binary requests. API consumption depends on input volume, `${METADATA_BATCH_SIZE}`, query pagination, and failures.

## How are duplicate ContentDocument IDs handled?

Duplicate IDs within the same input workbook are removed before processing. Overlapping IDs in separate batch workbooks can still be processed by separate workers.

## How are multiple ContentDocumentLink records handled?

The metadata query retrieves all visible links for each requested document. When link-workbook generation is enabled, one output row is written for every retrieved relationship while the physical file is downloaded once per batch.

## Can interrupted executions be resumed?

Failed IDs can be rerun from the generated failure workbook. Downloads always restart from the beginning; partially downloaded files are not resumed automatically.

## How are downloads validated?

The downloader rejects temporary browser extensions, waits for completion and stable size, compares the file with Salesforce `ContentSize`, moves it into its final ID directory, and verifies the destination.

## Are Salesforce access tokens written to logs?

Token-bearing initialization and request operations suppress ordinary Robot logging. The token remains in the local `org_info.json`, which must not be committed or shared. Users should still sanitize diagnostic output before sharing logs publicly.

## Can files be uploaded directly to S3?

No. This repository writes downloaded files to local storage and does not upload them directly to Amazon S3.

## Which operating systems are supported?

The documentation provides environment commands for Windows, Linux, and macOS. Chrome is the primary browser path. Actual compatibility depends on Python, Chrome, Salesforce CLI, filesystem permissions, and headless-browser support in the environment; CI does not validate every operating system.

## How many workers should be used?

There is no universal value. Start with a small number of workers and increase gradually while monitoring CPU, memory, disk, network, Salesforce response behavior, and failure rate. Review the [performance guidance](Performance.md) before increasing workers.

---

[← Previous](Troubleshooting.md) | [Next →](Limitations.md)

[Back to README](../README.md)
