# Salesforce Files Bulk Downloader

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.4.2-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce CLI](https://img.shields.io/badge/Salesforce-CLI-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/salesforcecli)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-ci.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool.svg?style=flat&color=orange)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases/latest)
[![License](https://img.shields.io/github/license/b-vamsipunnam/salesforce-files-downloader-tool?style=flat)](LICENSE)

Downloads the files named by Salesforce `ContentDocumentId` lists and helps developers or migration teams review, archive, or prepare those files for a separate Salesforce migration.

A Salesforce File has one logical `ContentDocument` record, identified by a `ContentDocumentId`, plus version and record-link data. This tool downloads the current file content to local storage; it does not discover file IDs or upload files to another org.

## What you need

- Git
- Python 3.10 or later
- Google Chrome
- Salesforce CLI (`sf`), which is the command-line tool used to sign in to Salesforce
- A spreadsheet editor that can save `.xlsx` files
- A Salesforce user who can use the API, read the requested file records and links, and download the files
- Enough local disk space for the downloads and generated reports

See [Installation](docs/Installation.md) for platform-specific setup notes.

## Quick start

### 1. Download and install the project

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate the virtual environment on Windows PowerShell:

```powershell
venv\Scripts\Activate.ps1
```

On Linux or macOS:

```bash
source venv/bin/activate
```

Install the required Python packages:

```bash
python -m pip install -r requirements.txt
```

This installs Robot Framework, the task runner behind the `robot` command, along with the browser and Excel libraries used by the downloader.

### 2. Sign in to Salesforce

Choose a short local name for the source org. This name is an **org alias**; `source-org` is used below as an example.

```bash
sf org login web --alias source-org
sf org display --target-org source-org --json
```

The first command opens a browser for sign-in. The second should return a JSON result with status `0`. On Windows, use `sf.cmd` instead of `sf` if PowerShell blocks `sf.ps1`.

Create the session file used by the downloader:

```bash
robot --variable ORG_ALIAS:source-org --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

Expect this confirmation and a new `org_info.json` file in the repository root:

```text
Generated a validated org_info.json for alias 'source-org'.
```

`org_info.json` contains an access token. It is ignored by Git, but you must not commit, print, or share it. See [Authentication](docs/Authentication.md) for sandbox login, permissions, and session-expiry guidance.

### 3. Prepare the input workbook

Open `input/Inputfile_1.xlsx` and select the worksheet named `Input`.

Leave the existing `ContentDocumentID` header in cell A1. Header matching is case-insensitive; this guide uses Salesforce's usual `ContentDocumentId` spelling. Starting in A2, paste one Salesforce file ID per row in the first column:

| ContentDocumentId |
|-------------------|
| `069...`          |
| `069...`          |

A `ContentDocumentId` is the Salesforce record ID for a logical file. Valid IDs start with `069` and contain 15 or 18 alphanumeric characters. You can obtain them through your approved Salesforce query or export process; the downloader does not search the org for files.

Save the workbook as `.xlsx` and close it before running the tool. Blank cells are ignored. Duplicate forms of the same valid ID are processed once within this batch.

### 4. Run the first batch

A **batch** is one input workbook processed by one Robot Framework test. Run only the first configured batch:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrators/download.robot
```

The console prints progress and finishes with a count of successful, failed, and total IDs. The command reports a failed test if any file remains unresolved; that prevents a missing file from looking successful.

## How it works

![Salesforce Files Bulk Downloader architecture](docs/architecture.svg)

Salesforce REST APIs provide the metadata, and an authenticated Selenium browser downloads the binaries from Shepherd. Robot Framework handles the workflow and reporting, while Pabot can run isolated batches in parallel. See [Architecture](docs/Architecture.md) for details.

## Where results are saved

Each output root uses a new batch directory whose name ends in a unique ID. The download and artifact IDs are generated separately, so their directory names do not necessarily match.

- **Downloaded files**

  Location: `downloads/Download_Batch_1_<uuid>/<ContentDocumentId>/`

  Contains the validated file bytes, stored once for each unique document in the batch.

- **Migration workbooks (optional)**

  Location: `artifacts/Download_Batch_1_<uuid>/`

  Contains Excel files for a later `ContentVersion` import and `ContentDocumentLink` mapping. Salesforce Data Loader is a separate desktop import and export tool.

- **Failed-ID workbook**

  Location: `artifacts/Download_Batch_1_<uuid>/Download_Batch_1_FAILED_IDs.xlsx`

  Lists unresolved IDs with a failure code, message, and attempt count. This workbook is created only when failures are recorded.

- **Manifest**

  Location: `artifacts/Download_Batch_1_<uuid>/Download_Batch_1_execution_manifest.jsonl`

  Provides a line-by-line JSON audit log of the batch, its attempts, and committed successes.

- **Robot reports**

  Location: `results/log.html`, `results/report.html`, and `results/output.xml`

  Provides human-readable details and Robot Framework's machine-readable result file.

A file counts as successful only after the download finishes, its size matches Salesforce `ContentSize`, it is moved to its final folder, and any requested migration rows are saved. A missing, partial, or failed file is not reported as downloaded. One physical file is downloaded per unique `ContentDocumentId` in a batch, while several link records may be written because one file can be attached to several Salesforce records.

All of these outputs can contain sensitive Salesforce IDs, metadata (descriptive record data), filenames, and local paths. Store and share them as migration data.

## If a download fails

1. Open the failed-ID workbook and `results/log.html`.
2. Use `FailureCode` and `FailureMessage` to find the cause in [Troubleshooting](docs/Troubleshooting.md).
3. Fix the cause. If the Salesforce session expired, sign in again if needed and regenerate `org_info.json`.
4. Copy the failed workbook's `ContentDocumentId` column into the `Input` worksheet of an input template, then rerun that batch.

Automatic retry applies only to failure types marked as transient by the tool. It does not repair invalid IDs, missing metadata, permissions, or expired sessions, and each retried download starts from the beginning.

## Documentation

| Guide | Responsibility |
|-------|----------------|
| [Introduction](docs/Introduction.md) | Salesforce Files concepts and when to use the tool |
| [Installation](docs/Installation.md) | Prerequisites and local setup |
| [Authentication](docs/Authentication.md) | Salesforce login, org aliases, sessions, and permissions |
| [Configuration](docs/Configuration.md) | Paths, batches, timeouts, API checks, and retries |
| [Usage](docs/Usage.md) | Input preparation, sequential and parallel runs, and result review |
| [Examples](docs/Examples.md) | A few practical migration scenarios |
| [Architecture](docs/Architecture.md) | Advanced design overview |
| [Performance](docs/Performance.md) | Recorded benchmark and its limits |
| [Keyword documentation](docs/Keyword-Documentation.md) | Robot Framework keyword reference |
| [Troubleshooting](docs/Troubleshooting.md) | Exact checks and fixes for common failures |
| [FAQ](docs/FAQ.md) | Questions not covered by the workflow guides |
| [Limitations](docs/Limitations.md) | Supported behavior and recovery boundaries |
| [Roadmap](docs/Roadmap.md) | Possible future work |
| [Contributing](CONTRIBUTING.md) | Development setup and contribution process |

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md) and report security issues through the [Security Policy](SECURITY.md).

This project is licensed under the [MIT License](LICENSE).
