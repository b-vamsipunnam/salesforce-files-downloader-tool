# Examples

## Process one workbook

Set the input and worksheet in `src/robot/orchestrators/download.robot`:

```robot
${INPUT_EXCEL_PATH_1}    ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${SHEET_NAME}            Input
```

Then run only its batch:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrators/download.robot
```

## Download without migration workbooks

Keep failed-ID reporting and downloaded binaries while disabling optional import files:

```robot
${GENERATE_CONTENT_VERSION_FILE}          No
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}    No
```

These values are case-insensitive and may contain surrounding whitespace, but they must resolve to `Yes` or `No`. A typo fails at the start of the batch rather than silently changing the requested output.

## Run four batch workers

Execute the four configured batch tests across up to four parallel worker processes:

```bash
pabot --testlevelsplit --processes 4 --outputdir results src/robot/orchestrators/download.robot
```

When practical, keep the workbooks similar in size so one large batch does not keep the run open after the other workers finish.

## Retry failures

Retries are enabled by default. After the normal download pass, each eligible failed ID receives up to two additional attempts with a five-second delay between retry attempts:

```robot
${ENABLE_FAILED_ID_RETRY}    ${TRUE}
${FAILED_ID_RETRY_COUNT}     2
${FAILED_ID_RETRY_DELAY}     5s
```

Each attempt downloads the whole file again. Invalid IDs and records missing required metadata are not retried. After fixing the underlying issue, use `<batch>_FAILED_IDs.xlsx` as the source for a new run.

## Configure API capacity protection

The capacity preflight is enabled by default. This example retains 100 requests for other integrations and adds a 25-request estimation buffer:

```robot
${ENABLE_API_CAPACITY_CHECK}          ${TRUE}
${API_REQUEST_SAFETY_BUFFER}          25
${MINIMUM_API_REQUESTS_REMAINING}     100
```

Each worker checks limits independently; there is no shared reservation counter. Pagination can add metadata requests, so increase the buffer when operating near the daily limit.

## Mix 15- and 18-character IDs safely

Exports from different Salesforce tools may contain both forms of the same ID:

```text
069AAAAAAAAAAAA
069AAAAAAAAAAAAY55
```

The downloader converts the valid 15-character value to its canonical 18-character form before deduplication. Within one workbook, this pair is processed as one ContentDocument.

## Illustrative enterprise batch

This is a sample outcome, not a benchmark or guarantee.

**Scenario:** A migration team processes one workbook containing 250 unique `ContentDocumentId` values.

**Illustrative output:**

- 247 files downloaded and validated
- 247 ContentVersion workbook rows
- 412 ContentDocumentLink workbook rows because some files have multiple links
- 3 IDs still failed after automatic retries and were written to the failure workbook
- Every downloaded file passed validation

## Prepare migration workbooks

1. Import the generated ContentVersion workbook into the destination org.
2. Obtain the destination `ContentDocumentId` for every inserted file.
3. Map source IDs in the generated ContentDocumentLink workbook to those destination IDs.
4. Import the remapped link rows.

---

[← Previous](Usage.md) | [Next →](Architecture.md)

[Back to README](../README.md)
