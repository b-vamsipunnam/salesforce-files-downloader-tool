# Configuration

Batch inputs and optional workbook flags are defined in `src/robot/orchestrator/download.robot`. Runtime paths, query size, and timeouts are defined in `src/robot/resources/configuration.robot`.

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

Failing early here is deliberate. A value such as `Yse` or `True` should not quietly disable an output that a migration operator expected to receive.

## Processing controls

| Setting                        | Default | Purpose                                  |
|--------------------------------|---------|------------------------------------------|
| `${METADATA_BATCH_SIZE}`       | `200`   | IDs per metadata query group             |
| `${ENABLE_API_CAPACITY_CHECK}` | `${TRUE}` | Check DailyApiRequests before processing |
| `${API_REQUEST_SAFETY_BUFFER}` | `25`    | Extra API requests reserved for estimation variance |
| `${MINIMUM_API_REQUESTS_REMAINING}` | `100` | Required API capacity left after estimated metadata calls |
| `${API_LIMIT_LOOKUP_MAX_ATTEMPTS}` | `3` | Maximum Salesforce CLI limits-command attempts |
| `${API_LIMIT_LOOKUP_RETRY_DELAY}` | `2s` | Delay between failed limits-command attempts |
| `${DOWNLOAD_APPEAR_TIMEOUT}`   | `60s`   | Wait for a browser download to appear    |
| `${DOWNLOAD_COMPLETE_TIMEOUT}` | `60s`   | Wait for temporary download state to end |
| `${FILE_STABILITY_MAX_CHECKS}` | `60`    | Maximum file stability checks            |
| `${FILE_STABILITY_INTERVAL}`   | `0.25s` | Delay between stability checks           |
| `${FILE_MOVE_TIMEOUT}`         | `15s`   | Maximum period for move retries          |
| `${FILE_MOVE_RETRY_INTERVAL}`  | `500ms` | Delay after a temporary file lock        |
| `${ENABLE_FAILED_ID_RETRY}`    | `${TRUE}` | Retry failed downloads before reporting them |
| `${FAILED_ID_RETRY_COUNT}`     | `2`     | Additional attempts for each retryable ID |
| `${FAILED_ID_RETRY_DELAY}`     | `5s`    | Delay between additional retry attempts  |

The default metadata batch size of 200 balances SOQL request efficiency with reliable query execution for large migrations.

The batch output directory and execution manifest are initialized before input reading and API preflight so early failures remain auditable. The preflight then reads `DailyApiRequests` through Salesforce CLI before creating migration workbooks or download directories. The limits command is serialized across Pabot workers and retried when it returns a nonzero exit code, empty output, invalid JSON, or no `DailyApiRequests` entry. Its minimum estimate counts one successful limits request, one `ContentDocument` query per metadata batch, and a second query per batch when ContentDocumentLink output is enabled. Paginated `nextRecordsUrl` requests are not predictable from the input count and are covered only by the configured safety buffer. Failed CLI attempts may also consume requests, so retain a buffer that reflects the expected relationship volume instead of treating the default as universally safe.

Suite setup reads org context from `org_info.json` and resolves the CLI path once per Robot process. Each batch still performs its own capacity lookup. This is a conservative per-batch check, not a global reservation across simultaneous workers. Use non-overlapping inputs and increase the buffer when parallel executions approach the org's daily API limit.

Increase timeouts only after checking file access, browser behavior, network throughput, and disk performance. Larger SOQL batches reduce request count but make each query longer.

Failed-ID retry is intended for temporary download problems, such as a slow browser response or an interrupted transfer. It does not repeat metadata queries, so invalid IDs and IDs without the required ContentDocument or ContentDocumentLink metadata remain failed. Set `${ENABLE_FAILED_ID_RETRY}` to `${FALSE}` to keep the original single-attempt behavior. `${FAILED_ID_RETRY_COUNT}` counts additional attempts after the first download attempt.

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
