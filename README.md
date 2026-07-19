# Salesforce Files Bulk Downloader

> An open-source Robot Framework and Python tool that makes it easier to download Salesforce Files in bulk using `ContentDocumentId` values.

It combines Salesforce REST metadata queries with authenticated Shepherd downloads, checks every downloaded file, and can generate Data Loader-ready Excel workbooks for migration and recovery work. A version of this framework has been used to process millions of files in enterprise environments.

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce](https://img.shields.io/badge/Salesforce-CLI-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/salesforcecli)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-ci.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool?style=flat&color=orange&logo=github&logoColor=white)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat)](LICENSE)

## Features

- Accepts both 15-character and 18-character `ContentDocumentId` values
- Authenticates through Salesforce CLI without storing usernames or passwords
- Retrieves `ContentDocument` and `ContentDocumentLink` metadata in batches
- Keeps every `ContentDocumentLink` associated with a file
- Downloads each physical file only once, even when it has multiple links
- Gives each batch its own UUID-based download and artifact directories
- Checks download completion, file stability, and size against Salesforce `ContentSize`
- Saves failed IDs in a separate Excel workbook for easier retry and review
- Can generate ContentVersion and ContentDocumentLink import workbooks
- Supports headless execution and Pabot-based parallel processing

## Quick Start

1. Clone the repository and install the dependencies:

   ```bash
   git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
   cd salesforce-files-downloader-tool
   python -m venv venv
   pip install -r requirements.txt
   ```

2. Authenticate to Salesforce:

   ```bash
   sf org login web --alias <org_alias>
   ```

   Then generate `org_info.json` using the platform-specific command in [Salesforce Authentication](#salesforce-authentication).

3. Add ContentDocument IDs to the first column of `input/Inputfile_1.xlsx`. The default worksheet name is `Input`.

4. Run the downloader:

   ```bash
   robot --outputdir results src/robot/orchestrator/download.robot
   ```

5. Review downloaded files in `downloads/`, migration workbooks in `artifacts/`, and execution reports in `results/`.

## How It Works

The downloader keeps metadata retrieval separate from the actual file download:

1. Read and deduplicate ContentDocument IDs from Excel.
2. Validate each ID and query Salesforce metadata in SOQL batches.
3. Authenticate a headless Chrome session through Salesforce `frontdoor.jsp`.
4. Download the latest file through the Shepherd endpoint.
5. Validate the downloaded size and move the file into its ID-based folder.
6. Write optional migration workbooks and a failed-ID report.

For a closer look at the design, see the [Architecture Overview](docs/architecture.md) and the [technical walkthrough on Medium](https://medium.com/@b.vamsipunnam/how-i-built-an-enterprise-grade-salesforce-files-bulk-downloader-for-migration-and-backup-a7df0d60ddc3).

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
- Access to a Salesforce org where you can read the requested files and metadata

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

Make sure the org is connected:

```bash
sf org display --target-org <org_alias>
```

Next, generate the authentication file in the project root.

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

The header is optional. The downloader ignores blank rows, removes duplicate IDs, and records invalid IDs as failures.

Configure the input paths and worksheet in `src/robot/orchestrator/download.robot`:

```robot
${INPUT_EXCEL_PATH_1}    ${INPUT_FOLDER}${/}Inputfile_1.xlsx
${SHEET_NAME}            Input
```

You can add or remove batch test cases to match the number of input files you want to process.

## Optional Migration Workbooks

Choose which migration workbooks to generate in `src/robot/orchestrator/download.robot`:

```robot
${GENERATE_CONTENT_VERSION_FILE}            Yes
${GENERATE_CONTENT_DOCUMENT_LINK_FILE}      Yes
```

Accepted values are `Yes` and `No`.

## Configuration

Most settings you may want to adjust are in `src/robot/orchestrator/download.robot` and `src/robot/resources/keywords.robot`.

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

Before starting a long-running job, regenerate `org_info.json` using the appropriate command in [Salesforce Authentication](#salesforce-authentication).

Run all batches sequentially:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

You can also run the suite through Pabot. Because `download.robot` is a single suite, its batch tests still run one after another with this command:

```bash
pabot --pabotlib --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

To run the individual batches at the same time, enable test-level splitting:

```bash
pabot --pabotlib --testlevelsplit --processes 4 --outputdir results src/robot/orchestrator/download.robot
```

Test-level splitting starts a separate Robot and browser environment for each worker. It works best with larger, evenly distributed batches. For small inputs, starting the workers and merging their results can take longer than simply running the batches sequentially.

> When using `--testlevelsplit`, do not delete the shared `org_info.json` from worker-level suite teardown. Remove it only after the complete Pabot execution finishes.

Run one batch while debugging:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

Choose the `--processes` value based on the CPU, memory, disk performance, network capacity, and Salesforce session limits available in your environment.

## Output

Each batch writes to its own download and artifact directories, so files from parallel runs do not overlap.

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

This workbook contains one row for every file downloaded successfully.

| Column | Description |
|---|---|
| `Title` | Original Salesforce file title |
| `VersionData` | Full local path to the downloaded file |
| `PathOnClient` | Full local path used for upload |

### ContentDocumentLink workbook

This workbook contains one row for every original link associated with each successfully downloaded file.

| Column | Description |
|---|---|
| `ContentDocumentId` | Source ContentDocument ID |
| `LinkedEntityId` | Record linked to the source file |
| `ShareType` | Viewer, Collaborator, or Inferred sharing value |
| `Visibility` | Salesforce visibility value |

After inserting the new ContentVersion records in the destination org, replace the source `ContentDocumentId` values with the newly created destination IDs. You can then import the ContentDocumentLink rows.

### Failed-ID workbook

This workbook lists the unique IDs that failed during validation, metadata retrieval, download, or final verification. If no files are downloaded successfully, the empty migration workbooks are removed.

## Download Validation

A file is marked as successfully downloaded only after the tool:

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
- Regenerate `org_info.json` immediately before long-running jobs and again if the Salesforce session expires.

When possible, use a dedicated Salesforce integration user with only the permissions needed for the migration.

## Troubleshooting

If something does not work as expected, start with `results/log.html`. It usually contains the most useful error details. For download failures, also check the batch-specific failed-ID workbook in `artifacts/`.

| Problem | What to try |
|---|---|
| Salesforce CLI is not recognized | Confirm that Salesforce CLI is installed and available on your system `PATH` |
| `ExcelLibrary` cannot be imported | Activate the virtual environment and run `pip install -r requirements.txt` |
| PabotLib cannot connect | Make sure the Pabot command includes `--pabotlib` |
| The Salesforce session or browser login fails | Regenerate `org_info.json` from the authenticated org and run the job again |
| Chrome does not start | Confirm that Google Chrome is installed and up to date |
| A download times out | Verify access to the file, check the network connection, and increase the configured timeouts if needed |

If the problem continues, open a GitHub issue and include the relevant error message, environment details, and steps needed to reproduce it. Never attach `org_info.json` or include Salesforce access tokens in logs or screenshots.

## CI

The GitHub Actions workflow runs an isolated smoke test for Robot Framework, headless Chrome, SeleniumLibrary, and the custom Excel library. It does not connect to Salesforce or download any Salesforce files.

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

Contributions are welcome. Please review [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request. You can also open an issue to report a problem or suggest an improvement.

If the project is useful, consider starring the repository and sharing feedback.

## Author

Created and maintained by [Bhimeswara Vamsi Punnam](https://www.linkedin.com/in/bvamsipunnam), Lead Software Development Engineer in Test.

## License

Licensed under the [MIT License](LICENSE).