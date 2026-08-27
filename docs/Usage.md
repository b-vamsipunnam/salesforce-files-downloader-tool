# Usage

Complete [Installation](Installation.md) and [Authentication](Authentication.md) before running a download. Run all commands below from the repository root with the Python virtual environment active.

## Prepare an input workbook

The downloader needs an `.xlsx` workbook; it does not discover Salesforce files by itself.

1. Open one of the templates under `input/`, such as `input/Inputfile_1.xlsx`.
2. Select the worksheet named `Input`.
3. Leave the existing `ContentDocumentID` header in cell A1. Header matching is case-insensitive; `ContentDocumentId` also works.
4. Paste one file ID in each row of column A, beginning at A2.
5. Save and close the workbook.

`ContentDocumentId` is the Salesforce ID of a logical file. A valid value starts with `069` and has 15 or 18 alphanumeric characters. Blank cells are ignored. Valid 15-character IDs are converted to their canonical 18-character form, and duplicates are removed within the workbook.

Obtain the IDs through an approved Salesforce query or export. Salesforce Data Loader, if your organization uses it, is a separate desktop application for exporting and importing Salesforce records; this downloader does not require Data Loader to run.

To create a workbook instead of using a template, create a worksheet named `Input`, put `ContentDocumentId` in A1, add IDs below it, and save the file as `.xlsx` under `input/`. Update the configured path if its name differs from the supplied template. See [Configuration](Configuration.md#batch-and-workbook-settings).

## Run a sequential download

The `robot` command runs the workflow. You do not need to know Robot Framework syntax to use a configured batch.

Run one batch first:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrators/download.robot
```

To run all four configured batch tests one after another:

```bash
robot --outputdir results src/robot/orchestrators/download.robot
```

Empty workbooks are skipped. Every test still receives its own artifact directory and manifest. The console ends with `Download summary: <successful> successful, <failed> failed, <total> total.` Robot reports the test as failed whenever an ID remains unresolved.

## Run parallel downloads

Pabot is Robot Framework's parallel runner. A **worker** is a separate process with its own Chrome session and batch output directories.

Because all four batches are tests inside one suite, `--testlevelsplit` is required to run them at the same time:

```bash
pabot --testlevelsplit --processes 4 --outputdir results src/robot/orchestrators/download.robot
```

`--processes 4` allows up to four workers. Without `--testlevelsplit`, this single suite is not split into concurrent batch tests.

Before a parallel run:

- place non-overlapping IDs in the configured workbooks;
- keep the workbooks reasonably balanced by expected file size or count;
- leave enough CPU, memory, disk, and network capacity for one Chrome process per worker;
- leave extra Salesforce API capacity for pagination and simultaneous workers; and
- keep the shared `org_info.json` until every worker finishes.

Each worker creates unique download and artifact directories. API-capacity checks are independent; there is no shared reservation across workers. See [Performance](Performance.md) before choosing a production worker count.

## Review the results

For a batch named `Download_Batch_1`, output resembles:

```text
downloads/
└── Download_Batch_1_<uuid>/
    └── 069.../
        └── filename.pdf

artifacts/
└── Download_Batch_1_<uuid>/
    ├── Download_Batch_1_ContentVersion_Import.xlsx
    ├── Download_Batch_1_ContentDocumentLink_Import.xlsx
    ├── Download_Batch_1_FAILED_IDs.xlsx
    └── Download_Batch_1_execution_manifest.jsonl

results/
├── log.html
├── output.xml
└── report.html
```

The download and artifact directories receive separate UUIDs, so the two `<uuid>` values normally differ.

Not every run creates every file:

- The download directory contains one validated binary per successful, unique `ContentDocumentId` in that batch. The filename can be shortened or sanitized for the local filesystem.
- A **migration workbook** is an optional Excel file that prepares data for a later destination-org import. The `ContentVersion` workbook contains `Title`, `VersionData`, and `PathOnClient` for successful files.
- The `ContentDocumentLink` workbook contains every visible source link for successful files. Its source `ContentDocumentId` values must be replaced with the new destination IDs before link import.
- A **failed-ID workbook** contains unresolved IDs plus `FailureCode`, `FailureMessage`, and `AttemptCount`. It is created only when the failure report has records.
- A **manifest** is the JSON Lines (`.jsonl`) audit record. It stores execution boundaries, attempts, failures, and committed `DOCUMENT_SUCCEEDED` events.
- `log.html` and `report.html` are Robot Framework reports. `output.xml` is the corresponding machine-readable result. Pabot can also keep worker details under `results/pabot_results/`.

If both migration flags are `No`, binaries, failures, and the manifest are still produced. If no document succeeds, empty migration workbooks are removed.

## What counts as success

A browser response alone is not success. The downloader waits for completion, checks that the file size stabilizes, compares the final size with Salesforce `ContentSize`, moves the binary to its ID folder, verifies the destination, and commits any requested workbook rows. A `DOCUMENT_SUCCEEDED` manifest event is written only after those steps pass.

If a requested workbook update fails, the tool removes the moved binary before recording the failure. This prevents a file without its matching migration rows from appearing complete. Failed or missing files must not be counted as downloaded.

One physical file is downloaded for each unique `ContentDocumentId` in a batch. A file can still produce several `ContentDocumentLink` rows because it can be linked to several records. The same ID in separate batch workbooks can be downloaded more than once.

## Recover unresolved IDs

1. Open the batch's `*_FAILED_IDs.xlsx` file and `results/log.html`.
2. Match the failure code to [Troubleshooting](Troubleshooting.md) and fix the underlying cause.
3. For `AUTH_SESSION_EXPIRED`, re-authenticate and regenerate `org_info.json`; automatic retry cannot renew the session.
4. Copy the failed workbook's first column into the `Input` worksheet of a configured input workbook. The generated failure workbook uses the worksheet name `Sheet`, so it is not a drop-in replacement for a workbook configured with `${SHEET_NAME}` set to `Input`.
5. Rerun the relevant batch. Every binary attempt starts from the beginning.

If execution stopped before a failure workbook could be written, use the original input together with the manifest and Robot log to identify incomplete IDs. Do not infer success from a folder or from the absence of a failure row; use the success events and validated outputs together.

Downloaded files, workbooks, manifests, and Robot reports can contain sensitive Salesforce metadata, filenames, IDs, and local paths. Apply your migration project's access, retention, and sharing rules.

[Back to README](../README.md)
