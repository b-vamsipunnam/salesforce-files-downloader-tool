# Keyword documentation

`src/robot/resources/keywords.robot` imports the resource files below. Robot Framework exposes their keywords when that entry point is imported. Most callers should use the orchestration keyword rather than assemble the internal workflow directly.

This page covers the keywords that callers and maintainers are most likely to use. In each table, **What it does and when to use it** explains the intended role, while **Important behavior** calls out state changes, assumptions, and limits. Most projects should start with the orchestration keyword and use lower-level keywords only when extending or testing the workflow.

## Salesforce CLI and authentication

**Source**

`src/robot/resources/salesforce_cli.robot` and `src/robot/resources/salesforce_api.robot`

| Keyword                         | What it does and when to use it              | Arguments       | Return value  | Important behavior                                                      |
|---------------------------------|---------------------------------------------|-----------------|---------------|-------------------------------------------------------------------------|
| `Check Prerequisites`           | Validate the CLI and org context.           | `${ORG_ALIAS}`  | None          | Calls CLI resolution, version validation, and org loading.              |
| `Resolve Salesforce CLI`        | Find `sf` on `PATH`.                        | None            | None          | Sets suite variable `${sf_cli_path}`; fails when missing.               |
| `Validate Salesforce CLI`       | Verify the resolved CLI runs.               | None            | None          | Requires `${sf_cli_path}` and a zero exit code.                         |
| `Load Org Context`              | Validate an alias and read its org context. | `${ORG_ALIAS}`  | None          | Sets the API version, org ID, and target alias at suite scope.          |
| `Initialize Salesforce CLI Context From Org Info` | Load worker context from `org_info.json` during suite setup. | None | None | Sets the alias, org ID, and API version without running `sf org display`; resolves the CLI path for the capacity check. |
| `Get Salesforce Daily API Limits` | Read `DailyApiRequests` before a batch. | Optional process keyword for tests; defaults to `Run Process` | Maximum and remaining requests | Captures output in memory, runs under a PabotLib lock, and retries bounded CLI or response failures. |
| `Estimate Metadata API Requests` | Estimate batched metadata calls. | ID count and ContentDocumentLink generation flag | Batch and request counts | Uses `${METADATA_BATCH_SIZE}` and does not predict pagination. |
| `Check Salesforce API Capacity` | Run the preflight capacity guard. | ID count and ContentDocumentLink generation flag | None | Includes the limits call itself and fails before artifact creation when estimated use, buffer, and reserve exceed remaining capacity. |
| `Validate Salesforce API Capacity` | Validate already-calculated capacity values. | Remaining requests, estimated tool requests, safety buffer, and minimum reserve | None | Pure capacity decision used by the preflight and offline tests. |
| `Safe Parse Sf Json`            | Parse JSON from CLI output.                 | `${raw_output}` | Parsed object | Finds the first valid object or array without logging raw CLI output.   |
| `Try Parse First Json Value`    | Probe CLI output when invalid JSON is an expected retry condition. | `${raw_output}` | Boolean status and parsed value | Returns `${FALSE}` and `${NONE}` instead of raising for empty or invalid output. |
| `Initialize Salesforce Session` | Create an authenticated REST session.       | None            | Session alias | Reads `org_info.json`; uses a unique RequestsLibrary alias.             |
| `Get Salesforce Login Info`     | Prepare frontdoor browser authentication.   | None            | Login URL     | Sets `${org_domain}` and reads the token without ordinary log exposure. |

Minimal prerequisite example:

```robot
Check Prerequisites    source_org
${session}=    Initialize Salesforce Session
```

## Salesforce REST API and metadata

**Source**

`src/robot/resources/salesforce_api.robot`

| Keyword                                | What it does and when to use it               | Arguments                                         | Return value                      | Important behavior                                                         |
|----------------------------------------|----------------------------------------------|---------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| `Send Safe Salesforce GET Request`     | Send a REST GET through an existing session. | `${session_alias}`, `${url}`, `${params}=${NONE}` | Response or `${NONE}`             | Suppresses request logging and sanitizes failures.                         |
| `Execute SOQL Query`                   | Retrieve all records for a SOQL query.       | `${soql}`, `${session_alias}`, optional request keyword | List of records                   | Follows `nextRecordsUrl`; enforces a 10,000-page safety bound. The optional keyword supports offline tests and defaults to the production request path. |
| `Is Valid ContentDocument ID`          | Validate an input ID.                        | `${content_id}`                                   | Boolean                           | Accepts 15- or 18-character alphanumeric IDs beginning with `069`.         |
| `Get ContentDocument Metadata Map`     | Query document metadata in batches.          | `${content_ids}`, `${batch_size}=200`, optional query keyword | Map keyed by document ID          | Includes title, extension, description, latest version, and expected size. The query override is intended for tests. |
| `Get ContentDocumentLink Metadata Map` | Query all visible links in batches.          | `${content_ids}`, `${batch_size}=200`, optional query keyword | Map of document IDs to link lists | Preserves multiple relationships per document. The query override is intended for tests. |
| `Split List Into Batches`              | Partition a list.                            | `${items}`, `${batch_size}`                       | List of lists                     | No returned batch exceeds the requested size.                              |
| `Format IDs For SOQL IN Clause`        | Format IDs for an `IN` clause.               | `${ids}`                                          | Comma-separated quoted string     | Intended for already validated Salesforce IDs.                             |

```robot
${valid}=    Is Valid ContentDocument ID    069XXXXXXXXXXXXXXX
${documents}=    Get ContentDocument Metadata Map    ${content_ids}    200
```

## Excel input and output

**Source**

`src/robot/resources/excel_operations.robot` and `src/robot/libraries/ExcelLibrary.py`

| Keyword                                 | What it does and when to use it | Arguments                                                 | Return value            | Important behavior                                             |
|-----------------------------------------|---------------------------------|-----------------------------------------------------------|-------------------------|----------------------------------------------------------------|
| `Read Content IDs From Excel Sheet`     | Read IDs from the first column. | `${input_excel_path}`, `${sheet_name}`                    | Canonical, deduplicated ID list | Removes an optional header, blanks, and whitespace; converts valid 15-character IDs to 18 characters before deduplication. |
| `Create ContentVersion Excel File`      | Create an import workbook.      | `${download_directory}`                                   | First data row and path | Writes `Title`, `VersionData`, and `PathOnClient` headers.     |
| `Create ContentDocumentLink Excel File` | Create a relationship workbook. | `${download_directory}`                                   | First data row and path | Writes document, entity, share type, and visibility headers.   |
| `Write Migration Rows Atomically`       | Record one completed document.  | Workbook paths, starting rows, title, local path, links, and generation flags | None | Stages all requested rows and rolls back committed workbooks if a later replacement fails. |
| `Write ContentVersion Row`              | Write one version row directly. | `${cv_row}`, `${dst}`, `${cv_file_name}`, `${file_title}` | None                    | Compatibility keyword; the main workflow uses the atomic writer. |
| `Write ContentDocumentLink Row`         | Write one relationship directly. | `${cdl_row}`, `${content_link}`, `${cdl_file_name}`      | None                    | Compatibility keyword; the main workflow uses the atomic writer. |
| `Remove Empty Import Files`             | Remove unused import workbooks. | `${cv_file_name}`, `${cdl_file_name}`                     | None                    | Deletes existing files only when invoked after zero successes. |

```robot
${content_ids}=    Read Content IDs From Excel Sheet    ${INPUT_EXCEL_PATH_1}    Input
```

## Browser and download operations

**Source**

`src/robot/resources/download_operations.robot`

| Keyword                              | What it does and when to use it          | Arguments                                                                                | Return value                    | Important behavior                                                                   |
|--------------------------------------|------------------------------------------|------------------------------------------------------------------------------------------|---------------------------------|--------------------------------------------------------------------------------------|
| `Initialize Output Directory`        | Create isolated artifact output.         | None                                                                                     | Directory path                  | Uses the test name and a UUID.                                                       |
| `Initialize Download Directory`      | Create isolated browser output.          | None                                                                                     | Directory path                  | Uses the test name and a UUID.                                                       |
| `Configure Browser`                  | Start and authenticate Chrome.           | `${download_directory}`, `${login_url}`, `${org_domain}`, `${headless}=${True}`          | None                            | Configures the download directory and Salesforce session.                            |
| `Build ContentDocument Download URL` | Build a Shepherd document URL.           | `${org_domain}`, `${document_id}`                                                        | URL                             | Targets the ContentDocument download endpoint.                                       |
| `Create ContentDocument ID Folder`   | Create a final per-ID directory.         | `${content_id}`, `${download_directory}`                                                 | Directory path                  | Verifies that the directory exists.                                                  |
| `Sanitize Filename`                  | Make a title safe for local storage.     | `${name}`                                                                                | Sanitized name                  | Handles invalid characters, Windows reserved names, trailing dots or spaces, and empty values. |
| `Sanitize Local Filename For Directory` | Bound a complete filename for its destination. | `${filename}`, `${directory}`, optional fallback and length limits | Sanitized name | Preserves the extension while keeping the complete destination path within its configured limit. |
| `Download And Validate Content File` | Coordinate one transfer and its outputs. | Document ID, URL, metadata/link rows, paths, filenames, flags, and success/failure lists | `PASS` or `FAIL`                | Cleans the workspace, triggers navigation, validates, reports, and isolates failure. |
| `Find Completed Download File`       | Select a completed browser file.         | `${recent_files}`                                                                        | None                             | Sets test-scoped `${latest_filename}` and `${is_filename_proper}`. Does not return a value. Excludes recognized temporary suffixes. |
| `Cleanup Download Directory`         | Clear isolated download workspace files. | `${download_directory}`                                                                  | None                            | Removes top-level leftover files while preserving ContentDocument-specific subdirectories. |

## File validation

**Source**

`src/robot/resources/download_operations.robot`

| Keyword                                            | What it does and when to use it            | Arguments                                                                                          | Return value     | Important behavior                                           |
|----------------------------------------------------|--------------------------------------------|----------------------------------------------------------------------------------------------------|------------------|--------------------------------------------------------------|
| `Download Directory Should Contain Completed File` | Assert that a completed file exists.       | `${download_directory}`                                                                            | None             | Fails when only temporary or no files are present.           |
| `Wait Until Download File Appears`                 | Wait for an initial completed candidate.   | `${timeout}`, `${download_directory}`                                                              | None             | Uses a non-assertive Python wait so temporary states do not create expected `FAIL` entries. |
| `Wait Until File Download Completes`               | Wait for temporary state to end.           | `${download_directory}`                                                                            | None             | Polls until a file without a recognized temporary suffix appears. |
| `Move Downloaded File With Retry`                  | Move a file through temporary locks.       | `${src}`, `${dst}`                                                                                 | None             | Retries until `${FILE_MOVE_TIMEOUT}`.                        |
| `Validate And Move Downloaded File`                | Verify size, move, destination, and workbook state. | Source file, destination, expected size, document ID, link/workbook state, flags, and result lists | `PASS` or `FAIL` | Success is recorded only after the migration transaction commits. A transaction failure removes the moved binary and reports the ID as failed. |

## Workflow orchestration

**Source**

`src/robot/resources/download_workflow.robot`

Unless otherwise noted, call `Download Files Using Content Document IDs` rather than assembling the lower-level workflow.

| Keyword                                     | What it does and when to use it   | Arguments                                                                                                                                        | Return value                                                | Important behavior                                                                                                  |
|---------------------------------------------|-----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| `Download Files Using Content Document IDs` | Run one complete input batch.     | `${input_excel_path}`, `${sheet_name}`, `${GENERATE_CONTENT_VERSION_FILE}`, `${GENERATE_CONTENT_DOCUMENT_LINK_FILE}`                             | No return value; controls overall test execution.           | Initializes state, queries metadata, processes IDs, retries eligible failures, writes reports, and performs cleanup. |
| `Validate And Normalize Yes Or No Setting`  | Validate one workbook-generation flag. | Setting name and value | Normalized `Yes` or `No` | Trims whitespace, normalizes case, and fails before processing for any other value. |
| `Retry Failed ContentDocument IDs`          | Retry eligible failed downloads.  | `${content_doc_map}`, `${cdl_map}`, `${cv_row}`, `${cdl_row}`, `${download_directory}`                                                           | Updated ContentVersion and ContentDocumentLink row numbers  | Preserves non-retryable and unresolved IDs while removing successful retries from the failure list.                 |
| `Process ContentDocument Download`          | Prepare and process one document. | `${content_id}`, `${content_doc}`, `${content_links}`, `${record_number}`, `${cv_row}`, `${cdl_row}`, `${download_directory}`, `${failure_list}=${failed_content_ids}` | `PASS` or `FAIL`                               | Builds a safe filename and URL, then delegates transfer and validation; retries can supply an isolated failure list. |

```robot
Download Files Using Content Document IDs
...    ${INPUT_EXCEL_PATH_1}
...    ${SHEET_NAME}
...    Yes
...    Yes
```

## Failure reporting

**Source**

`src/robot/resources/download_operations.robot` and `src/robot/resources/excel_operations.robot`

| Keyword                                     | What it does and when to use it    | Arguments                                                                                              | Return value | Important behavior                                           |
|---------------------------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------|--------------|--------------------------------------------------------------|
| `Handle Download Failure`                   | Isolate a failed document.         | `${content_id}`, `${reason}`, `${failed_content_ids}`, `${content_id_folder}`, `${download_directory}` | `FAIL`       | Records the ID, logs a reason, and cleans incomplete output. |
| `Write Failed ContentDocument IDs To Excel` | Create the batch failure workbook. | `${unique_failed_content_ids}`, `${output_directory}`                                                  | None         | Writes only when at least one ID exists.                     |
| `Write Failed ContentDocument IDs`          | Populate a failure workbook.       | `${unique_failed_content_ids}`, `${excel_file}`                                                        | None         | Uses a `ContentDocumentId` header.                           |

## Cleanup

**Source**

`src/robot/resources/cleanup.robot`

These keywords are typically executed during suite teardown and normally do not require direct invocation.

| Keyword                     | What it does and when to use it            | Arguments | Return value | Important behavior                                                  |
|-----------------------------|--------------------------------------------|-----------|--------------|---------------------------------------------------------------------|
| `Cleanup Runtime Artifacts` | Remove recognized temporary runtime files. | None      | None         | Limits removal to known generated names in `${EXECDIR}` and intentionally preserves shared `org_info.json`. |
| `Cleanup Download Suite`    | Perform suite teardown.                    | None      | None         | Closes browsers and cleans runtime artifacts.                       |

---

[← Previous](Performance.md) | [Next →](Troubleshooting.md)

[Back to README](../README.md)
