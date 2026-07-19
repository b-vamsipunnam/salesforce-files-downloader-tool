# Usage

## Basic execution

Refresh `org_info.json`, populate the configured input workbooks, and run all batches sequentially:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

Run one batch while debugging:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

## Parallel execution

Because `download.robot` is one suite, this command creates Pabot infrastructure but leaves its batch tests sequential:

```bash
pabot --pabotlib --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Use test-level splitting to execute batch tests concurrently:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Each worker starts its own Robot and Chrome environment. Do not remove the shared `org_info.json` in worker-level teardown; remove it only after the complete Pabot run.

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
    └── Download_Batch_1_FAILED_IDs.xlsx

results/
├── log.html
├── output.xml
└── report.html
```

## Output files

The ContentVersion workbook contains `Title`, `VersionData`, and `PathOnClient` for each successful file. The ContentDocumentLink workbook contains source `ContentDocumentId`, `LinkedEntityId`, `ShareType`, and `Visibility` for every original link. After inserting ContentVersion records into a destination org, replace source document IDs with the new destination IDs before importing links.

The failed-ID workbook contains unique IDs rejected during validation, metadata retrieval, download, or final verification. If no file succeeds, empty import workbooks are removed. Robot's `log.html` contains execution detail.

---

[← Previous](Configuration.md) | [Next →](Examples.md)

[Back to README](../README.md)
