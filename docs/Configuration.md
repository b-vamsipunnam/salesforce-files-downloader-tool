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
| `${BASE_DOWNLOAD_FOLDER}`                         | `downloads/`         | Validated binary output root                 |
| `${OUTPUT_FOLDER}`                                | `artifacts/`         | Workbook output root                         |

Workbook generation flags accept `Yes` or `No` to enable or disable creation of the corresponding migration workbooks. Add, remove, or edit batch test cases in `download.robot` to match the number of input workbooks being processed.

## Processing controls

| Setting                        | Default | Purpose                                  |
|--------------------------------|---------|------------------------------------------|
| `${METADATA_BATCH_SIZE}`       | `200`   | IDs per metadata query group             |
| `${DOWNLOAD_APPEAR_TIMEOUT}`   | `60s`   | Wait for a browser download to appear    |
| `${DOWNLOAD_COMPLETE_TIMEOUT}` | `60s`   | Wait for temporary download state to end |
| `${FILE_STABILITY_MAX_CHECKS}` | `60`    | Maximum file stability checks            |
| `${FILE_STABILITY_INTERVAL}`   | `0.25s` | Delay between stability checks           |
| `${FILE_MOVE_TIMEOUT}`         | `15s`   | Maximum period for move retries          |
| `${FILE_MOVE_RETRY_INTERVAL}`  | `500ms` | Delay after a temporary file lock        |

The default metadata batch size of 200 balances SOQL request efficiency with reliable query execution for large migrations.

Increase timeouts only after checking file access, browser behavior, network throughput, and disk performance. Larger SOQL batches reduce request count but make each query longer.

## Input workbook format

Place one `ContentDocumentId` in the first column of the worksheet. A `ContentDocumentId` header is optional. Blank rows are ignored, and duplicate IDs are processed only once per batch.

Both 15-character and 18-character Salesforce `ContentDocumentId` values are supported.


| ContentDocumentId    |
|----------------------|
| `069XXXXXXXXXXXXXXX` |
| `069YYYYYYYYYYYYYYY` |

---

[← Previous](Authentication.md) | [Next →](Usage.md)

[Back to README](../README.md)
