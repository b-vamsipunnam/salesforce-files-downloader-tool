# Configuration

The repository has four predefined batches and conservative runtime defaults. Change a setting only when the default does not fit the job, and test the change with a small input first.

## Where settings live

- `src/robot/orchestrators/download.robot` defines input workbooks, the worksheet name, optional migration outputs, and the four batch tests.
- `src/robot/resources/configuration.robot` defines shared paths, metadata query size, API-capacity protection, timeouts, and retry behavior.
- Pabot worker count is a command-line option described under [Parallel downloads](Usage.md#run-parallel-downloads); there is no worker-count variable in the resource files.

Robot Framework command-line variables can override these values for one run. For example:

```bash
robot --test Download_Batch_1 --variable SHEET_NAME:Input --variable GENERATE_CONTENT_DOCUMENT_LINK_FILE:No --outputdir results src/robot/orchestrators/download.robot
```

## Batch and workbook settings

A **batch** is one test case that reads one Excel workbook. Four batches are configured by default.

| Setting | Default | Meaning |
|---------|---------|---------|
| `${INPUT_EXCEL_PATH_1}` … `${INPUT_EXCEL_PATH_4}` | `input/Inputfile_1.xlsx` … `input/Inputfile_4.xlsx` | Workbook assigned to each batch |
| `${SHEET_NAME}` | `Input` | Worksheet read from every configured input workbook |
| `${GENERATE_CONTENT_VERSION_FILE}` | `Yes` | Create the optional `ContentVersion` migration workbook |
| `${GENERATE_CONTENT_DOCUMENT_LINK_FILE}` | `Yes` | Query visible links and create the optional `ContentDocumentLink` migration workbook |

The two workbook flags accept only `Yes` or `No`. Case and surrounding spaces are ignored. Any other value stops the batch before input processing.

Add or remove batch test cases in `download.robot` only when the four supplied definitions do not fit the execution plan. Inputs used by parallel batches should not overlap: deduplication happens inside one workbook, not across workers.

## Paths

These defaults are relative to `${EXECDIR}`, the directory from which Robot Framework starts:

| Setting | Default | Meaning |
|---------|---------|---------|
| `${ORG_INFO_FILE}` | `org_info.json` | Salesforce session file |
| `${INPUT_FOLDER}` | `${EXECDIR}/input` | Input workbook root |
| `${BASE_DOWNLOAD_FOLDER}` | `${EXECDIR}/downloads` | Validated file root |
| `${OUTPUT_FOLDER}` | `${EXECDIR}/artifacts` | Manifest and workbook root |

Run the documented commands from the repository root unless you intentionally override every relevant path. The full output layout is in [Usage](Usage.md#review-the-results).

## Metadata queries and API-capacity check

| Setting | Default | Meaning |
|---------|---------|---------|
| `${METADATA_BATCH_SIZE}` | `200` | Maximum IDs in one metadata query group |
| `${ENABLE_API_CAPACITY_CHECK}` | `${TRUE}` | Check `DailyApiRequests` before a non-empty batch |
| `${API_REQUEST_SAFETY_BUFFER}` | `25` | Extra requests allowed for estimation uncertainty |
| `${MINIMUM_API_REQUESTS_REMAINING}` | `100` | Capacity that must remain after the estimate |

For each non-empty batch, the minimum estimate includes one limits request, one `ContentDocument` query per metadata group, and one `ContentDocumentLink` query per group when link output is enabled. Salesforce can paginate a query, so the actual count can be higher.

Each parallel worker checks capacity independently. Workers do not reserve requests for one another, and Salesforce usage reporting can lag. Split or postpone work rather than lowering protection without an org-specific API plan.

## Download and filesystem timeouts

| Setting | Default | Meaning |
|---------|---------|---------|
| `${DOWNLOAD_APPEAR_TIMEOUT}` | `60s` | Wait for a completed browser-download candidate to appear |
| `${DOWNLOAD_COMPLETE_TIMEOUT}` | `60s` | Wait for temporary download state to end |
| `${FILE_STABILITY_MAX_CHECKS}` | `60` | Maximum file-size stability checks |
| `${FILE_STABILITY_INTERVAL}` | `0.25s` | Delay between stability checks |
| `${FILE_MOVE_TIMEOUT}` | `15s` | Total time allowed for retries when moving a locked file |
| `${FILE_MOVE_RETRY_INTERVAL}` | `500ms` | Delay between file-move attempts |

Increase a download timeout only after checking authentication, file permission, free disk space, Chrome policy, and network behavior. A longer timeout cannot fix a blocked or unauthorized download.

## Failed-download retries

| Setting | Default | Meaning |
|---------|---------|---------|
| `${ENABLE_FAILED_ID_RETRY}` | `${TRUE}` | Retry failure records marked as retryable |
| `${FAILED_ID_RETRY_COUNT}` | `2` | Extra full-download attempts after the first attempt |
| `${FAILED_ID_RETRY_DELAY}` | `5s` | Delay before later extra attempts |

Retries use the metadata and session already loaded for the batch. They apply only to failure codes the implementation marks as retryable. Invalid IDs, missing required metadata, and expired sessions are not retried. A retry starts the whole file again; it does not resume a partial transfer.

File-move retries are separate. They handle a temporary local file lock only until `${FILE_MOVE_TIMEOUT}` expires.

## Headless Chrome

The normal download workflow starts Chrome in headless mode, so no browser window is shown. The `Configure Browser` keyword accepts a `headless` argument, but the top-level downloader does not expose a `${HEADLESS}` configuration variable. Treat visible-browser execution as a code-level customization, not a documented runtime switch. See [Keyword documentation](Keyword-Documentation.md#browser-and-download-operations) for the keyword contract.

[Back to README](../README.md)
