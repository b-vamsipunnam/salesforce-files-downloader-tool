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

Distribute the four configured test cases across up to four processes:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Use balanced workbooks where practical. A small batch can finish while another worker continues processing a much larger input.

## Retry failures

Copy the IDs from `<batch>_FAILED_IDs.xlsx` into a configured input workbook, refresh `org_info.json`, and run that batch again. The current implementation retries whole IDs; it does not continue a partially downloaded binary.

## Illustrative enterprise batch

The following numbers are an example only; they are not benchmark results or guaranteed output.

**Scenario:** A migration team processes one workbook containing 250 unique `ContentDocumentId` values.

**Illustrative output:**

- 247 files downloaded and validated
- 247 ContentVersion workbook rows
- 412 ContentDocumentLink workbook rows because some files have multiple links
- 3 failed IDs written to the failure workbook for review and rerun
- Validation completed successfully for every file reported as downloaded

## Prepare migration links

1. Import the generated ContentVersion workbook into the destination org.
2. obtain the destination `ContentDocumentId` for every inserted file.
3. Map source IDs in the generated ContentDocumentLink workbook to those destination IDs.
4. Import the remapped link rows.

---

[← Previous](Usage.md) | [Next →](Architecture.md)

[Back to README](../README.md)
