# Usage

A successful execution produces isolated download, artifact, and Robot Framework report directories similar to the following:

## Required preflight

Do not start Robot or Pabot until the environment and Salesforce commands pass independently. On Windows PowerShell:

```powershell
node --version
npm --version
sf.cmd --version
sf.cmd org display --target-org <org_alias> --json | Out-Null
```

Node.js and npm must satisfy the live engine declarations documented in [Installation](Installation.md), the CLI version output must name the active Node runtime, and the Salesforce command must exit successfully. Generate a current, non-redacted `org_info.json` with the Robot task in [Authentication](Authentication.md). If any preflight command fails, do not redirect its output into `org_info.json` and do not start parallel workers. Runtime API-capacity checks use authenticated REST calls and do not require `sf org list limits`.

## Basic execution

Refresh and validate `org_info.json`, populate the configured input workbooks with `ContentDocumentId` values, and run all configured batches sequentially:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

The first column may contain valid 15- or 18-character IDs. The downloader canonicalizes valid IDs to 18 characters before deduplication, so mixed representations of the same document are processed once within a batch.

Run one batch while debugging:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

## Parallel execution

Because `download.robot` is one suite, this command creates Pabot infrastructure but leaves its batch tests sequential:

```bash
pabot --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Add `--testlevelsplit` to execute the configured batch tests concurrently:

```bash
pabot --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Each worker starts its own Robot and Chrome environment and performs its own authenticated REST capacity check. Do not remove the shared `org_info.json` in worker-level teardown; remove it only after the complete Pabot run.

Each non-empty batch reads `org_info.json`, initializes its authenticated REST session, and calls `/services/data/v<version>/limits` before creating migration workbooks or starting Chrome. This retains a fresh per-batch capacity decision without starting Salesforce CLI subprocesses during downloads.

REST capacity checks do not reserve requests globally. Salesforce usage reporting can lag, so workers may observe similar remaining values. Treat the console value as a minimum estimate, retain a realistic safety buffer for pagination, and avoid running close to the org limit unless capacity is coordinated outside this tool.

## Expected directory structure

```text
downloads/
└── Download_Batch_1_<uuid>/
    └── 069xxxxxxxxxxxxxxx/
        └── original_filename.pdf

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

Every batch run creates new UUID-based download and artifact directories. These directories and Robot reports are retained for audit and recovery; review and remove historical runs according to local retention requirements only after all workers have finished.

## Output files

The ContentVersion workbook contains `Title`, `VersionData`, and `PathOnClient` for each successful file. The ContentDocumentLink workbook contains source `ContentDocumentId`, `LinkedEntityId`, `ShareType`, and `Visibility` for every original link. After inserting ContentVersion records into a destination org, replace source document IDs with the new destination IDs before importing links. The failed-ID workbook contains `ContentDocumentId`, `FailureCode`, `FailureMessage`, and `AttemptCount`; its first column remains directly reusable as downloader input.

The JSONL manifest is the machine-readable audit stream for one batch. It records execution boundaries, attempt starts, attempt failures, and committed successes with UTC timestamps, worker identity, metadata, paths, sizes, and structured failure details. A document receives `DOCUMENT_SUCCEEDED` only after binary validation and the requested workbook transaction commit. Treat manifests as migration data because they can contain filenames and local paths.

Local filenames are sanitized as complete `title.extension` values and shortened when necessary to keep the destination path within the configured safety limit. The original Salesforce title remains in the ContentVersion workbook.

After the primary pass, the downloader automatically retries eligible failed downloads when retry is enabled. An ID that succeeds during retry is treated like any other successful download and is removed from the failure list. The failed-ID workbook therefore contains only unique IDs that were invalid, lacked required metadata, or still failed after all configured attempts.

A file is not considered successful merely because it reached its destination folder. The migration-workbook update must also commit. If that transaction fails, the final binary is removed and the ID follows the normal failure-reporting path, which keeps the workbooks and filesystem consistent for a rerun.

If no file succeeds, empty import workbooks are removed. Robot Framework's `log.html`, `report.html`, and `output.xml` show each retry attempt and provide detailed diagnostic information.

---

[← Previous](Configuration.md) | [Next →](Examples.md)

[Back to README](../README.md)
