# Usage

A successful execution produces isolated download, artifact, and Robot Framework report directories similar to the following:

## Basic execution

Refresh `org_info.json`, populate the configured input workbooks with `ContentDocumentId` values, and run all configured batches sequentially:

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
pabot --pabotlib --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Add `--testlevelsplit` to execute the configured batch tests concurrently:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Each worker starts its own Robot and Chrome environment. Do not remove the shared `org_info.json` in worker-level teardown; remove it only after the complete Pabot run.

Suite setup reads the alias, org ID, and API version directly from `org_info.json` and resolves the Salesforce CLI executable. It does not run `sf org display`, which avoids concurrent access to shared CLI state when Pabot starts several workers. The API-capacity lookup remains per batch because the remaining allocation can change during execution. A PabotLib lock serializes that CLI command across workers, and bounded retries handle empty, invalid, or failed CLI responses while browser downloads continue in parallel.

The lock protects CLI access, not capacity allocation. Salesforce usage reporting can lag, so workers may observe similar remaining values. Treat the console value as a minimum estimate, retain a realistic safety buffer for pagination, and avoid running close to the org limit unless capacity is coordinated outside this tool.

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
