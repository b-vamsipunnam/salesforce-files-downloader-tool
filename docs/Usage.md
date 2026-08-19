# Usage

## Required preflight

Before starting Robot or Pabot, run these checks in Windows PowerShell:

```powershell
node --version
npm --version
sf.cmd --version
sf.cmd org display --target-org <org_alias> --json | Out-Null
```

If any command fails, stop and fix the environment before starting parallel workers. Then generate a current `org_info.json` by following [Authentication](Authentication.md). The downloader checks API capacity through REST, so `sf org list limits` is not part of this preflight.

## Basic execution

Refresh and validate `org_info.json`, populate the configured input workbooks with `ContentDocumentId` values, and run all configured batches sequentially:

```bash
robot --outputdir results src/robot/orchestrators/download.robot
```

The first column may contain valid 15- or 18-character IDs. The downloader canonicalizes valid IDs to 18 characters before deduplication, so mixed representations of the same document are processed once within a batch.

Run one batch while debugging:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrators/download.robot
```

## Parallel execution

Because `download.robot` is one suite, this command creates Pabot infrastructure but leaves its batch tests sequential:

```bash
pabot --processes 4 --outputdir results src/robot/orchestrators/download.robot
```

Add `--testlevelsplit` to execute the configured batch tests concurrently:

```bash
pabot --testlevelsplit --processes 4 --outputdir results src/robot/orchestrators/download.robot
```

Each worker has its own Robot process, Chrome session, output directories, and REST capacity check. Workers share `org_info.json`, so do not remove it until the entire Pabot run has finished. Capacity is not reserved across workers, and Salesforce usage reporting can lag; leave enough buffer for pagination and simultaneous requests.

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

Each batch gets new UUID-based download and artifact directories. They are kept for auditing and recovery; remove old runs according to your retention policy after all workers finish.

## Output files

The ContentVersion workbook contains `Title`, `VersionData`, and `PathOnClient` for each successful file. The ContentDocumentLink workbook contains source `ContentDocumentId`, `LinkedEntityId`, `ShareType`, and `Visibility` for every original link. After inserting ContentVersion records into a destination org, replace source document IDs with the new destination IDs before importing links. The failed-ID workbook contains `ContentDocumentId`, `FailureCode`, `FailureMessage`, and `AttemptCount`; its first column remains directly reusable as downloader input.

The JSONL manifest is the machine-readable audit record for a batch. It captures run boundaries, attempts, failures, and committed successes with timestamps and supporting details. A `DOCUMENT_SUCCEEDED` event is written only after the file and requested workbook updates are complete. Manifests may contain filenames and local paths, so handle them as migration data.

Local filenames are sanitized as complete `title.extension` values and shortened when necessary to keep the destination path within the configured safety limit. The original Salesforce title remains in the ContentVersion workbook.

When retry is enabled, eligible failures receive another attempt after the first pass. Recovered IDs are removed from the failure list, so the failed-ID workbook contains only unresolved or non-retryable IDs.

A file is not considered successful merely because it reached its destination folder. The migration-workbook update must also commit. If that transaction fails, the final binary is removed and the ID follows the normal failure-reporting path, which keeps the workbooks and filesystem consistent for a rerun.

If no file succeeds, empty import workbooks are removed. Robot Framework's `log.html`, `report.html`, and `output.xml` show each retry attempt and provide detailed diagnostic information.

---

[← Previous](Configuration.md) | [Next →](Examples.md)

[Back to README](../README.md)
