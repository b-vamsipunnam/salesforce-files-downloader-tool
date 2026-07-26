# Examples

## Process one workbook

Set the input and worksheet in `src/robot/orchestrator/download.robot`:

```robot
${INPUT_EXCEL_PATH_1}    ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${SHEET_NAME}            Input
```

Then run only its batch:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

## Download without migration workbooks

Keep failed-ID reporting and downloaded binaries while disabling optional import files:

```robot
${GENERATE_CONTENT_VERSION_FILE}          No
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}    No
```

## Run four batch workers

Execute the four configured batch tests across up to four parallel worker processes:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Where practical, distribute a similar number of IDs across input workbooks to improve parallel execution efficiency. A small batch can finish while another worker continues processing a much larger input.

## Retry failures

Retries are enabled by default. After the normal download pass, each eligible failed ID receives up to two additional attempts with a five-second delay between retry attempts:

```robot
${ENABLE_FAILED_ID_RETRY}    ${TRUE}
${FAILED_ID_RETRY_COUNT}     2
${FAILED_ID_RETRY_DELAY}     5s
```

Each attempt downloads the complete file again; a partial binary is never resumed. Invalid IDs and IDs missing required metadata are not retryable. If an ID still fails, it is written to `<batch>_FAILED_IDs.xlsx`. Once the underlying access, authentication, network, or storage issue is resolved, copy those remaining IDs into an input workbook and run the batch again.

## Configure API capacity protection

The capacity preflight is enabled by default. This example retains 100 requests for other integrations and adds a 25-request estimation buffer:

```robot
${ENABLE_API_CAPACITY_CHECK}          ${TRUE}
${API_REQUEST_SAFETY_BUFFER}          25
${MINIMUM_API_REQUESTS_REMAINING}     100
${API_LIMIT_LOOKUP_MAX_ATTEMPTS}      3
${API_LIMIT_LOOKUP_RETRY_DELAY}       2s
```

Each batch counts one successful limits request plus estimated metadata requests. The limits lookup is serialized across Pabot workers and retries transient CLI or response failures. Failed lookup attempts and metadata pagination can consume additional calls, and parallel workers do not share a reservation counter, so increase the buffer when operating near the daily limit.

## Illustrative enterprise batch

The following numbers are an example only; they are not benchmark results or guaranteed output.

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
