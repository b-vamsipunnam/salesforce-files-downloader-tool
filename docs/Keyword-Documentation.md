# Keyword Documentation

`src/robot/resources/keywords.robot` imports the resource files below. Robot Framework exposes their keywords when that entry point is imported. Most callers should use the orchestration keyword rather than assemble the internal workflow directly.

## Salesforce CLI and authentication

**Source**

`src/robot/resources/salesforce_cli.robot` and `src/robot/resources/salesforce_api.robot`

| Keyword                         | Purpose                                     | Arguments       | Return value  | Important behavior                                                      |
|---------------------------------|---------------------------------------------|-----------------|---------------|-------------------------------------------------------------------------|
| `Check Prerequisites`           | Validate the CLI and org context.           | `${ORG_ALIAS}`  | None          | Calls CLI resolution, version validation, and org loading.              |
| `Resolve Salesforce CLI`        | Find `sf` on `PATH`.                        | None            | None          | Sets suite variable `${sf_cli_path}`; fails when missing.               |
| `Validate Salesforce CLI`       | Verify the resolved CLI runs.               | None            | None          | Requires `${sf_cli_path}` and a zero exit code.                         |
| `Load Org Context`              | Validate an alias and read its API version. | `${ORG_ALIAS}`  | None          | Sets `${CLI_API_VERSION}` at suite scope.                               |
| `Safe Parse Sf Json`            | Parse JSON from CLI output.                 | `${raw_output}` | Parsed object | Tolerates leading CLI warnings or banners.                              |
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

| Keyword                                | Purpose                                      | Arguments                                         | Return value                      | Important behavior                                                         |
|----------------------------------------|----------------------------------------------|---------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| `Send Safe Salesforce GET Request`     | Send a REST GET through an existing session. | `${session_alias}`, `${url}`, `${params}=${NONE}` | Response or `${NONE}`             | Suppresses request logging and sanitizes failures.                         |
| `Execute SOQL Query`                   | Retrieve all records for a SOQL query.       | `${soql}`, `${session_alias}`                     | List of records                   | Follows `nextRecordsUrl`; enforces a 10,000-page safety bound.             |
| `Is Valid ContentDocument ID`          | Validate an input ID.                        | `${content_id}`                                   | Boolean                           | Accepts 15- or 18-character alphanumeric IDs beginning with `069`.         |
| `Get ContentDocument Metadata Map`     | Query document metadata in batches.          | `${content_ids}`, `${batch_size}=200`             | Map keyed by document ID          | Includes title, extension, description, latest version, and expected size. |
| `Get ContentDocumentLink Metadata Map` | Query all visible links in batches.          | `${content_ids}`, `${batch_size}=200`             | Map of document IDs to link lists | Preserves multiple relationships per document.                             |
| `Split List Into Batches`              | Partition a list.                            | `${items}`, `${batch_size}`                       | List of lists                     | No returned batch exceeds the requested size.                              |
| `Format IDs For SOQL IN Clause`        | Format IDs for an `IN` clause.               | `${ids}`                                          | Comma-separated quoted string     | Intended for already validated Salesforce IDs.                             |

```robot
${valid}=    Is Valid ContentDocument ID    069XXXXXXXXXXXXXXX
${documents}=    Get ContentDocument Metadata Map    ${content_ids}    200
```

## Excel input and output

**Source**

`src/robot/resources/excel_operations.robot`

| Keyword                                 | Purpose                         | Arguments                                                 | Return value            | Important behavior                                             |
|-----------------------------------------|---------------------------------|-----------------------------------------------------------|-------------------------|----------------------------------------------------------------|
| `Read Content IDs From Excel Sheet`     | Read IDs from the first column. | `${input_excel_path}`, `${sheet_name}`                    | Deduplicated ID list    | Removes an optional header, blanks, and whitespace.            |
| `Create ContentVersion Excel File`      | Create an import workbook.      | `${download_directory}`                                   | First data row and path | Writes `Title`, `VersionData`, and `PathOnClient` headers.     |
| `Create ContentDocumentLink Excel File` | Create a relationship workbook. | `${download_directory}`                                   | First data row and path | Writes document, entity, share type, and visibility headers.   |
| `Write ContentVersion Row`              | Record a successful local file. | `${cv_row}`, `${dst}`, `${cv_file_name}`, `${file_title}` | None                    | Saves and closes the workbook after the row.                   |
| `Write ContentDocumentLink Row`         | Record one source relationship. | `${cdl_row}`, `${content_link}`, `${cdl_file_name}`       | None                    | Writes one row for each supplied link.                         |
| `Remove Empty Import Files`             | Remove unused import workbooks. | `${cv_file_name}`, `${cdl_file_name}`                     | None                    | Deletes existing files only when invoked after zero successes. |

```robot
${content_ids}=    Read Content IDs From Excel Sheet    ${INPUT_EXCEL_PATH_1}    Input
```

## Browser and download operations

**Source**

`src/robot/resources/download_operations.robot`

| Keyword                              | Purpose                                  | Arguments                                                                                | Return value                    | Important behavior                                                                   |
|--------------------------------------|------------------------------------------|------------------------------------------------------------------------------------------|---------------------------------|--------------------------------------------------------------------------------------|
| `Initialize Output Directory`        | Create isolated artifact output.         | None                                                                                     | Directory path                  | Uses the test name and a UUID.                                                       |
| `Initialize Download Directory`      | Create isolated browser output.          | None                                                                                     | Directory path                  | Uses the test name and a UUID.                                                       |
| `Configure Browser`                  | Start and authenticate Chrome.           | `${download_directory}`, `${login_url}`, `${org_domain}`, `${headless}=${True}`          | None                            | Configures the download directory and Salesforce session.                            |
| `Build ContentDocument Download URL` | Build a Shepherd document URL.           | `${org_domain}`, `${document_id}`                                                        | URL                             | Targets the ContentDocument download endpoint.                                       |
| `Create ContentDocument ID Folder`   | Create a final per-ID directory.         | `${content_id}`, `${download_directory}`                                                 | Directory path                  | Verifies that the directory exists.                                                  |
| `Sanitize Filename`                  | Make a title safe for local storage.     | `${name}`                                                                                | Sanitized name                  | Replaces OS-restricted characters and trims whitespace.                              |
| `Download And Validate Content File` | Coordinate one transfer and its outputs. | Document ID, URL, metadata/link rows, paths, filenames, flags, and success/failure lists | `PASS` or `FAIL`                | Cleans the workspace, triggers navigation, validates, reports, and isolates failure. |
| `Find Completed Download File`       | Select a completed browser file.         | `${recent_files}`                                                                        | Selected file path or `${NONE}` | Excludes recognized temporary suffixes.                                              |
| `Cleanup Download Directory`         | Clear download workspace entries.        | `${download_directory}`                                                                  | None                            | Removes leftovers before or after an attempted transfer.                             |

## File validation

**Source**

`src/robot/resources/download_operations.robot`

| Keyword                                            | Purpose                                    | Arguments                                                                                          | Return value     | Important behavior                                           |
|----------------------------------------------------|--------------------------------------------|----------------------------------------------------------------------------------------------------|------------------|--------------------------------------------------------------|
| `Download Directory Should Contain Completed File` | Assert that a completed file exists.       | `${download_directory}`                                                                            | None             | Fails when only temporary or no files are present.           |
| `Wait Until Download File Appears`                 | Wait for an initial completed candidate.   | `${timeout}`, `${download_directory}`                                                              | None             | Uses Robot polling and the configured appearance bound.      |
| `Wait Until File Download Completes`               | Wait for temporary state to end.           | `${download_directory}`                                                                            | None             | Observes temporary suffixes and file stability limits.       |
| `Move Downloaded File With Retry`                  | Move a file through temporary locks.       | `${src}`, `${dst}`                                                                                 | None             | Retries until `${FILE_MOVE_TIMEOUT}`.                        |
| `Validate And Move Downloaded File`                | Verify size, move, and verify destination. | Source file, destination, expected size, document ID, link/workbook state, flags, and result lists | `PASS` or `FAIL` | Success is recorded only after final destination validation. |

## Workflow orchestration

**Source**

`src/robot/resources/download_workflow.robot`

| Keyword                                     | Purpose                           | Arguments                                                                                                                     | Return value               | Important behavior                                                                                        |
|---------------------------------------------|-----------------------------------|-------------------------------------------------------------------------------------------------------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------|
| `Download Files Using Content Document IDs` | Run one complete input batch.     | `${input_excel_path}`, `${sheet_name}`, `${GENERATE_CONTENT_VERSION_FILE}`, `${GENERATE_CONTENT_DOCUMENT_LINK_FILE}`          | None; test passes or fails | Initializes state, queries metadata, processes IDs, writes reports, and always performs teardown actions. |
| `Process ContentDocument Download`          | Prepare and process one document. | `${content_id}`, `${content_doc}`, `${content_links}`, `${record_number}`, `${cv_row}`, `${cdl_row}`, `${download_directory}` | `PASS` or `FAIL`           | Builds a safe filename and URL, then delegates transfer and validation.                                   |

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

| Keyword                                     | Purpose                            | Arguments                                                                                              | Return value | Important behavior                                           |
|---------------------------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------|--------------|--------------------------------------------------------------|
| `Handle Download Failure`                   | Isolate a failed document.         | `${content_id}`, `${reason}`, `${failed_content_ids}`, `${content_id_folder}`, `${download_directory}` | `FAIL`       | Records the ID, logs a reason, and cleans incomplete output. |
| `Write Failed ContentDocument IDs To Excel` | Create the batch failure workbook. | `${unique_failed_content_ids}`, `${output_directory}`                                                  | None         | Writes only when at least one ID exists.                     |
| `Write Failed ContentDocument IDs`          | Populate a failure workbook.       | `${unique_failed_content_ids}`, `${excel_file}`                                                        | None         | Uses a `ContentDocumentId` header.                           |

## Cleanup

**Source**

`src/robot/resources/cleanup.robot`

| Keyword                     | Purpose                                    | Arguments | Return value | Important behavior                                                  |
|-----------------------------|--------------------------------------------|-----------|--------------|---------------------------------------------------------------------|
| `Cleanup Runtime Artifacts` | Remove recognized temporary runtime files. | None      | None         | Limits removal to known names and UUID-named files in `${EXECDIR}`. |
| `Cleanup Download Suite`    | Perform suite teardown.                    | None      | None         | Closes browsers and cleans runtime artifacts.                       |

---

[← Previous](Performance.md) | [Next →](Troubleshooting.md)

[Back to README](../README.md)
