# Configuration

Batch inputs and optional workbook flags are defined in `src/robot/orchestrators/download.robot`. Runtime paths, query size, and timeouts are defined in `src/robot/resources/configuration.robot`.

## Inputs and outputs

| Setting                                           | Default              | Purpose                                      |
|---------------------------------------------------|----------------------|----------------------------------------------|
| `${INPUT_EXCEL_PATH_1}` … `${INPUT_EXCEL_PATH_4}` | Files under `input/` | Workbook assigned to each batch test         |
| `${SHEET_NAME}`                                   | `Input`              | Worksheet read from each workbook            |
| `${GENERATE_CONTENT_VERSION_FILE}`                | `Yes`                | Create a ContentVersion import workbook      |
| `${GENERATE_CONTENT_DOCUMENT_LINK_FILE}`          | `Yes`                | Create a ContentDocumentLink import workbook |
| `${ORG_INFO_FILE}`                                | `org_info.json`      | Salesforce CLI authentication data           |
| `${INPUT_FOLDER}`                                 | `input/`             | Root directory for configured input workbooks |
| `${BASE_DOWNLOAD_FOLDER}`                         | `downloads/`         | Validated binary output root                 |
| `${OUTPUT_FOLDER}`                                | `artifacts/`         | Workbook output root                         |

Workbook generation flags accept `Yes` or `No` (case-insensitive, with surrounding whitespace ignored) to enable or disable creation of the corresponding migration workbooks. Any other value fails before input processing or artifact creation. Add, remove, or edit batch test cases in `download.robot` to match the number of input workbooks being processed.

A typo such as `Yse` or `True` stops the batch instead of silently changing the output.

## Processing controls

| Setting                        | Default | Purpose                                  |
|--------------------------------|---------|------------------------------------------|
| `${METADATA_BATCH_SIZE}`       | `200`   | IDs per metadata query group             |
| `${ENABLE_API_CAPACITY_CHECK}` | `${TRUE}` | Check DailyApiRequests before processing |
| `${API_REQUEST_SAFETY_BUFFER}` | `25`    | Extra API requests reserved for estimation variance |
| `${MINIMUM_API_REQUESTS_REMAINING}` | `100` | Required API capacity left after estimated metadata calls |
| `${DOWNLOAD_APPEAR_TIMEOUT}`   | `60s`   | Wait for a browser download to appear    |
| `${DOWNLOAD_COMPLETE_TIMEOUT}` | `60s`   | Wait for temporary download state to end |
| `${FILE_STABILITY_MAX_CHECKS}` | `60`    | Maximum file stability checks            |
| `${FILE_STABILITY_INTERVAL}`   | `0.25s` | Delay between stability checks           |
| `${FILE_MOVE_TIMEOUT}`         | `15s`   | Maximum period for move retries          |
| `${FILE_MOVE_RETRY_INTERVAL}`  | `500ms` | Delay after a temporary file lock        |
| `${ENABLE_FAILED_ID_RETRY}`    | `${TRUE}` | Retry failed downloads before reporting them |
| `${FAILED_ID_RETRY_COUNT}`     | `2`     | Additional attempts for each retryable ID |
| `${FAILED_ID_RETRY_DELAY}`     | `5s`    | Delay between additional retry attempts  |

The downloader creates the batch artifact directory and execution manifest before reading the input, so even early failures are recorded. For each non-empty batch, it checks `DailyApiRequests` before creating migration workbooks or download directories. The estimate includes the limits request, one `ContentDocument` query per metadata batch, and—when link output is enabled—one `ContentDocumentLink` query per batch. Pagination cannot be predicted from the input count, so choose a safety buffer that reflects the expected number of relationships.

Parallel workers check capacity independently and do not reserve requests for one another. Use non-overlapping inputs and a larger buffer when a parallel run may approach the org's daily limit.

Increase timeouts only after checking file access, browser behavior, network throughput, and disk performance. Larger SOQL batches reduce request count but make each query longer.

Failed-ID retry is for temporary problems such as a slow browser response or interrupted transfer. It does not repeat metadata queries, so invalid IDs and records without required metadata remain failed. `${FAILED_ID_RETRY_COUNT}` is the number of extra attempts after the first; set `${ENABLE_FAILED_ID_RETRY}` to `${FALSE}` to make only one attempt.

## Input workbook format

Place one `ContentDocumentId` in the first column of the worksheet. A `ContentDocumentId` header is optional. Blank rows are ignored, and duplicate IDs are processed only once per batch.

Both 15-character and 18-character Salesforce `ContentDocumentId` values are supported. Valid 15-character IDs are converted to their canonical 18-character form before deduplication, so equivalent forms of the same record are processed once.


| ContentDocumentId    |
|----------------------|
| `069XXXXXXXXXXXXXXX` |
| `069YYYYYYYYYYYYYYY` |

---

[← Previous](Authentication.md) | [Next →](Usage.md)

[Back to README](../README.md)
