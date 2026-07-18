# Salesforce Files Bulk Downloader

> An open-source Robot Framework and Python tool for downloading Salesforce Files in bulk by `ContentDocumentId`.

The tool combines Salesforce REST metadata queries with authenticated Shepherd downloads, validates every downloaded file, and optionally generates Data Loader-ready Excel workbooks for migration and recovery workflows. A version of this framework has been used to process millions of files in enterprise environments.

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce](https://img.shields.io/badge/Salesforce-CLI-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/salesforcecli)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-ci.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool?style=flat&color=orange&logo=github&logoColor=white)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat)](LICENSE)

## Features

- Downloads Salesforce Files using 15-character or 18-character `ContentDocumentId` values
- Uses Salesforce CLI authentication without storing usernames or passwords
- Queries `ContentDocument` and `ContentDocumentLink` metadata in batches
- Preserves every `ContentDocumentLink` associated with a file
- Downloads each physical file only once
- Runs in isolated, UUID-based download and artifact directories
- Validates completion, file stability, and size against Salesforce `ContentSize`
- Tracks failed IDs in a separate Excel workbook
- Optionally generates ContentVersion and ContentDocumentLink import workbooks
- Supports headless execution and Pabot-based parallel processing

## Quick Start

1. Clone the repository and install the dependencies:

   ```bash
   git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
   cd salesforce-files-downloader-tool
   python -m venv venv
   pip install -r requirements.txt
   ```

2. Authenticate to Salesforce and generate `org_info.json`:

   ```bash
   sf org login web --alias <org_alias>
   sf org display --json --target-org <org_alias> > org_info.json
   ```

3. Add ContentDocument IDs to the first column of `input/Inputfile_1.xlsx`. The default worksheet name is `Input`.

4. Run the downloader:

   ```bash
   robot --outputdir results src/robot/orchestrator/download.robot
   ```

5. Review downloaded files in `downloads/`, migration workbooks in `artifacts/`, and execution reports in `results/`.

## How It Works

The framework separates metadata retrieval from binary download:

1. Read and deduplicate ContentDocument IDs from Excel.
2. Validate each ID and query Salesforce metadata in SOQL batches.
3. Authenticate a headless Chrome session through Salesforce `frontdoor.jsp`.
4. Download the latest file through the Shepherd endpoint.
5. Validate the downloaded size and move the file into its ID-based folder.
6. Write optional migration workbooks and a failed-ID report.

For additional design details, see [Architecture Overview](docs/architecture.md) and the [technical walkthrough on Medium](https://medium.com/@b.vamsipunnam/how-i-built-an-enterprise-grade-salesforce-files-bulk-downloader-for-migration-and-backup-a7df0d60ddc3).

## Project Layout

```text
salesforce-files-downloader-tool/
├── ci/robot/                         # CI smoke test
├── docs/                             # Architecture documentation
├── input/                            # ContentDocument ID workbooks
├── src/robot/
│   ├── libraries/                    # Custom Python libraries
│   ├── orchestrator/download.robot   # Batch definitions and execution
│   └── resources/keywords.robot      # Download workflow keywords
├── artifacts/                        # Migration workbooks and failed IDs
├── downloads/                        # Downloaded Salesforce files
├── results/                          # Robot Framework reports
├── requirements.txt                  # Python dependencies
└── README.md
```

## Prerequisites

- Python 3.10 or later
- Google Chrome
- Node.js
- Salesforce CLI
- Access to a Salesforce org with permission to read the requested files and metadata

Install Salesforce CLI if needed:

```bash
npm install --global @salesforce/cli
```

## Installation

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate the virtual environment.

Windows:

```powershell
venv\Scripts\activate
```

Linux or macOS:

```bash
source venv/bin/activate
```

Install the dependencies:

```bash
pip install -r requirements.txt
```

## Salesforce Authentication

Authenticate and assign an org alias:

```bash
sf org login web --alias <org_alias>
```

Confirm the connection:

```bash
sf org display --target-org <org_alias>
```

Generate the authentication file in the project root.

Windows PowerShell:

```powershell
sf org display --json --target-org <org_alias> | Out-File -Encoding utf8 org_info.json
```

Linux or macOS:

```bash
sf org display --json --target-org <org_alias> > org_info.json
```

> **Security warning:** `org_info.json` contains a temporary Salesforce access token. Never commit, publish, or share this file. It is excluded by `.gitignore`.

## Input Files

Place the configured `.xlsx` files in `input/`. By default, the automation reads the first column of a worksheet named `Input`.

| ContentDocumentId |
|---|
| 069XXXXXXXXXXXXXXX |
| 069YYYYYYYYYYYYYYY |

The header is optional. Blank rows are ignored, duplicate IDs are removed, and invalid IDs are recorded as failures.

Configure the input paths and worksheet in `src/robot/orchestrator/download.robot`:

```robot
${INPUT_EXCEL_PATH_1}    ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${SHEET_NAME}            Input
```

Add or remove batch test cases based on the number of input files.

## Optional Migration Workbooks

Control workbook generation in `src/robot/orchestrator/download.robot`:

```robot
${GENERATE_CONTENT_VERSION_FILE}            Yes
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}      Yes
```

Accepted values are `Yes` and `No`.

## Configuration

The primary settings are located in `src/robot/orchestrator/download.robot` and `src/robot/resources/keywords.robot`.

| Setting | Default | Purpose |
|---|---:|---|
| `${SHEET_NAME}` | `Input` | Worksheet containing ContentDocument IDs |
| `${GENERATE_CONTENT_VERSION_FILE}` | `Yes` | Generate the ContentVersion import workbook |
| `${GENERATE_CONTENT_DOCUMENT_LINK_FILE}` | `Yes` | Generate the ContentDocumentLink import workbook |
| `${METADATA_BATCH_SIZE}` | `200` | Number of IDs included in each metadata query batch |
| `${DOWNLOAD_APPEAR_TIMEOUT}` | `60s` | Maximum time to wait for a completed file to appear |
| `${DOWNLOAD_COMPLETE_TIMEOUT}` | `60s` | Maximum time to wait for download completion |
| `${FILE_MOVE_TIMEOUT}` | `15s` | Maximum retry period for temporary file locks |

Input workbook paths are configured through `${INPUT_EXCEL_PATH_1}`, `${INPUT_EXCEL_PATH_2}`, and the other batch variables in `download.robot`.

## Execution

Run all batches sequentially:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

The following Pabot command also schedules at suite level. Because `download.robot` is one suite, its test cases remain sequential:

```bash
pabot --pabotlib --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Run individual batch tests concurrently:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Test-level splitting starts a separate Robot and browser environment for each worker. It is most useful for larger, evenly distributed batches. For small inputs, startup and result-merging overhead can make sequential execution faster.

Run one batch while debugging:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

Adjust `--processes` for available CPU, memory, disk throughput, network capacity, and Salesforce session limits.

## Output

Each batch receives unique download and artifact directories.

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

### ContentVersion workbook

Contains one row for every successfully downloaded file.

| Column | Description |
|---|---|
| `Title` | Original Salesforce file title |
| `VersionData` | Full local path to the downloaded file |
| `PathOnClient` | Full local path used for upload |

### ContentDocumentLink workbook

Contains one row for every original link associated with each successful file.

| Column | Description |
|---|---|
| `ContentDocumentId` | Source ContentDocument ID |
| `LinkedEntityId` | Record linked to the source file |
| `ShareType` | Viewer, Collaborator, or Inferred sharing value |
| `Visibility` | Salesforce visibility value |

After inserting new ContentVersion records in the destination org, replace the source `ContentDocumentId` values with the newly created destination IDs before importing the ContentDocumentLink rows.

### Failed-ID workbook

Contains unique IDs that failed validation, metadata retrieval, download, or final verification. If no file succeeds, empty migration workbooks are removed.

## Download Validation

A download is marked successful only after the framework:

- Detects a completed, non-temporary browser download
- Rejects `.crdownload`, `.tmp`, and `.part` files
- Verifies the downloaded size against Salesforce `ContentSize`
- Confirms the file size is stable
- Moves the file successfully, including retry handling for temporary Windows locks
- Verifies the final destination file and size

## Security

- Authentication is handled through Salesforce CLI.
- Credentials are not hardcoded.
- Token-bearing initialization steps are suppressed from ordinary Robot logs.
- `org_info.json` and runtime outputs must remain excluded from version control.
- Refresh the org information file if the Salesforce session expires.

Use a dedicated Salesforce integration user with only the permissions required for the migration whenever possible.

## Troubleshooting

| Problem | Recommended action |
|---|---|
| `sf` is not found | Install Salesforce CLI and confirm it is available on `PATH` |
| `ExcelLibrary` cannot be imported | Activate the virtual environment and reinstall `requirements.txt` |
| PabotLib connection fails | Include `--pabotlib` in the Pabot command |
| Salesforce session or frontdoor login fails | Regenerate `org_info.json` from the authenticated org |
| Chrome fails to start | Confirm Chrome is installed and compatible with the current Selenium setup |
| Downloads time out | Check Salesforce access, network stability, file size, and timeout configuration |

Review `results/log.html` and the batch-specific failed-ID workbook for detailed diagnostics.

## CI

The GitHub Actions workflow runs an isolated smoke test that validates Robot Framework, headless Chrome, SeleniumLibrary, and the custom Excel library. It does not authenticate to Salesforce or download Salesforce files.

## Limitations

- Browser-based downloads consume more CPU and memory than a pure REST implementation.
- Effective parallelism depends on workstation resources, network throughput, and Salesforce behavior.
- Partially downloaded files cannot currently resume from checkpoints.
- Chrome is required.

## Roadmap

- Checkpoint and resume support
- Direct S3 or Azure Blob export
- OAuth-based non-CLI authentication
- Command-line wrapper
- Docker support

## Contributing and Support

Contributions are welcome. Review [CONTRIBUTING.md](CONTRIBUTING.md), open an issue for defects or enhancements, and follow the existing project conventions when submitting a pull request.

If the project is useful, consider starring the repository and sharing feedback.

## Author

Created and maintained by [Bhimeswara Vamsi Punnam](https://www.linkedin.com/in/bvamsipunnam), Lead Software Development Engineer in Test.

## License

Licensed under the [MIT License](LICENSE).
