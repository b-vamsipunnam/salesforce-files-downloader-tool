# Architecture

The downloader gets metadata from Salesforce REST APIs and binaries from Salesforce Shepherd through an authenticated browser session.

## Architecture diagram

The diagram follows a batch from input validation through metadata queries, download, workbook generation, and failure reporting.

<p align="center">
  <img src="architecture.svg" width="1200" alt="Salesforce Files Bulk Downloader architecture">
</p>

The editable source for the detailed diagram is [`architecture.svg`](architecture.svg).

## Component responsibilities

- **Salesforce CLI** authenticates the source org and generates the protected authentication file before execution. Runtime workers read that file and retrieve daily API limits directly from Salesforce REST, so parallel execution does not start CLI subprocesses.
- **Salesforce REST API** executes paginated SOQL queries for `ContentDocument` and `ContentDocumentLink` metadata.
- **Selenium and Chrome** establish the Salesforce session through `frontdoor.jsp` and initiate Shepherd downloads.
- **Robot Framework** coordinates strict configuration validation, per-batch initialization and API preflight, input normalization, metadata mapping, downloads, retry state, reporting, and teardown.
- **Python libraries** provide safe Salesforce CLI JSON parsing, 15-to-18-character ID canonicalization, destination-aware filename handling, Chrome configuration, transactional Excel updates, and filesystem support used by Robot keywords.
- **Pabot** can split batch tests across processes. UUID-based download and artifact directories separate their output.

Before contacting Salesforce, the downloader normalizes the workbook-generation flags and requires `Yes` or `No`. It then canonicalizes and deduplicates input IDs. Metadata queries follow Salesforce pagination. Because input count does not reveal how many pages Salesforce will return, the preflight reports only a minimum request estimate.

When a download appears, the workflow rejects temporary file suffixes, waits for completion and a stable size, compares the file with Salesforce `ContentSize`, moves it to its `ContentDocumentId` directory, and verifies the destination. It stages and commits migration rows as one transaction. The document succeeds only after that commit. If the commit fails, the downloader removes the moved binary and per-ID directory before reporting the failure.

## Why browser-based download is used

REST and SOQL provide the structured records and relationships needed for metadata processing. Binary transfer uses Salesforce's authenticated Shepherd flow, with Selenium maintaining the required browser session.

This avoids routing large volumes of binary download traffic through REST API requests while preserving Salesforce session behavior. It still consumes API calls for metadata, requires Chrome resources, and remains subject to session expiration, permissions, network conditions, and Salesforce response behavior.

## Why Robot Framework?

Robot Framework coordinates authentication, metadata queries, browser downloads, validation, reporting, and cleanup. Resource files share that workflow across batch tests, while Python libraries handle lower-level operations. Pabot runs the same batch tests in separate processes, so the project does not need another orchestration layer.

## Design principles

- **Deterministic processing:** valid 15-character IDs are canonicalized to 18 characters before validation and deduplication.
- **One physical download per ContentDocument:** repeated IDs within a batch do not trigger repeated transfers.
- **Preservation of multiple ContentDocumentLink records:** all retrieved links can be retained for migration mapping.
- **Validation before success reporting:** completion, stability, expected size, movement, destination checks, and workbook commit all precede success.
- **Structured failure isolation:** failed IDs are separated from successful outputs with stable failure codes, sanitized messages, and attempt counts.
- **Bounded recovery:** eligible download failures receive a configurable number of full-download retries before they are reported.
- **Parallel worker separation:** each test uses unique download and artifact directories.
- **Recoverable reporting:** only unresolved IDs are written to failure workbooks for controlled reruns.
- **Machine-readable reconciliation:** each batch writes an append-only JSONL event manifest; success events follow binary validation and workbook commit.
- **Authentication detection:** REST `401`/`INVALID_SESSION_ID`, browser login redirects, and downloaded Salesforce HTML login responses are classified as expired sessions.
- **Minimal exposure of sensitive authentication data:** token-bearing operations suppress ordinary logs and authentication files remain uncommitted.
- **Capacity protection:** after starting its audit manifest, each batch uses a conservative minimum estimate and preserves a configurable daily API reserve before creating migration workbooks or download directories. Pagination and concurrent workers are handled operationally through the safety buffer; workers do not share a reservation counter.

## Runtime locations

| Location                  | Responsibility                                            |
|---------------------------|-----------------------------------------------------------|
| `src/robot/orchestrators/` | Batch definitions and suite execution                     |
| `src/robot/resources/`    | Workflow, API, download, Excel, and cleanup keywords      |
| `src/robot/libraries/`    | Custom Python libraries                                   |
| `input/`                  | Source workbooks containing IDs                           |
| `downloads/`              | Validated binaries, isolated by test and UUID             |
| `artifacts/`              | Import workbooks, structured failures, and JSONL manifests |
| `results/`                | Robot Framework and Pabot reports                         |

---

[← Previous](Examples.md) | [Next →](Performance.md)

[Back to README](../README.md)
