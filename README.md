# Salesforce Files Downloader Tool

> Enterprise-grade Salesforce file migration and backup tool built with Robot Framework and Python.  
> Supports bulk ContentDocumentId downloads, parallel execution, CI/CD, and Data Loader integration.

---

## Built With

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.0.1-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Pabot](https://img.shields.io/badge/Pabot-2.18.0-blue?style=flat&logo=github&logoColor=white)](https://github.com/mkorpela/pabot)
[![SeleniumLibrary](https://img.shields.io/badge/SeleniumLibrary-6.8.0-green?style=flat&logo=selenium&logoColor=white)](https://github.com/robotframework/SeleniumLibrary)
[![webdriver-manager](https://img.shields.io/badge/webdriver--manager-4.0.2-blue?style=flat&logo=googlechrome&logoColor=white)](https://pypi.org/project/webdriver-manager/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce CLI](https://img.shields.io/badge/Salesforce%20CLI-2.116.6-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/sfdxcli)
[![Node.js](https://img.shields.io/badge/Node.js-18.20.4-339933?style=flat&logo=node.js&logoColor=white)](https://nodejs.org/)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-tests.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool?style=flat&color=orange&logo=github&logoColor=white)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat&logo=open-source-initiative&logoColor=white)](https://opensource.org/licenses/MIT)

---

## Introduction

The Salesforce Files Downloader Tool is an open-source, parallel-processing automation framework built with **Robot Framework** and **Python** for fast, reliable bulk downloads of Salesforce files using ContentDocument IDs.

Key features:

* Supports **any Salesforce org** (via Salesforce CLI authentication)
* Downloads files using the secure **Shepherd endpoint**
* Parallel execution using **Pabot**
* Preserves original filenames and directory structure
* Generates **Data Loader–ready Excel files**
* Tracks failures with detailed logs
* Fully isolated execution folders
* CI/CD compatible

## When to Use This Tool

This tool is ideal when you need to:

* Migrate large volumes of Salesforce files
* Perform org-to-org file migrations
* Back up attachments and documents
* Recover files after org refresh
* Generate upload-ready datasets
* Execute large downloads in parallel

## Why This Exists

Traditional Salesforce tools (Data Loader, Workbench, UI downloads) have limitations:

* No reliable bulk download support
* No parallel execution
* Slow UI-based downloads
* Limited retry and tracking

This framework provides **deterministic, scalable, and resumable downloads** optimized for enterprise environments.

---

## Target Audience

This tool is designed for:

- Salesforce Developers and Architects
- QA / Automation Engineers
- DevOps Engineers
- Data Migration Specialists
- Compliance and Audit Teams

---

## Architecture Overview

High-level architecture:

```text
Salesforce Org
      |
      | (CLI Authentication)
      v
Robot Framework
      |
      v
Custom Python Libraries
      |
      v
Headless Chrome
      |
      v
Local Storage + Excel Generator

```
---

## Quick Start

1. Authenticate to your Salesforce org *(replace `<org_name>` with your org alias)*:
   ```powershell
   sf org display --json --target-org <org_name> | Out-File -Encoding utf8 org_info.json
   ```
   
2. Run parallel downloads:
   ```powershell
   pabot --pabotlib --processes 2 --outputdir results src/robot/tests/Test.robot
   ```
3. Check results
   ```text
   Downloaded files: downloads/<test_name>_<uuid>/069.../<filename>
   Generated Excel files: output/
   Execution logs: results/
   ```
---

## Project Structure

```
salesforce-files-downloader-tool/
├── .github/
│   ├── workflows/
│   │   └── robot-tests.yml                                # GitHub Actions CI
│   └── PULL_REQUEST_TEMPLATE.md                           # Pull request template
├── ci/
│   └── robot/
│       └── Smoke.robot
├── docs/
│   └── architecture.md                                    # High-level design documentation
├── downloads/                                             # Runtime: downloaded Salesforce files
│   └── <test_name>_<uuid>/                                # One folder per pabot process
│       ├── 069xxxxxxxxxxxx/                               # ContentDocumentId folder
│       │   └── <original_filename>
│       └── 069yyyyyyyyyyyy/                               # ContentDocumentId folder
│           └── <original_filename>
├── input/                                                 # Input Excel files
│   ├── Inputfile_1.xlsx
│   └── Inputfile_2.xlsx
├── output/                                                # Runtime: Failed records + Data Loader-ready Excels
│   └── <test_name>__<uuid>/                               # One folder per test case
│       ├── <test_name>_Failed_IDs_List.xlsx
│       ├── <test_name>_ContentVersion_Inputfile.xlsx
│       └── <test_name>_ContentDocumentLink_Inputfile.xlsx
├── results/                                               # Robot execution results
│   ├── pabot_results/
│   ├── log.html
│   ├── output.xml
│   └── report.html
├── src/
│   └── robot/
│       ├── library/
│       │   ├── ExcelLibrary.py
│       │   ├── SalesforceSupport.py
│       │   └── WebdriverManager.py
│       └── tests/
│           ├── Support.robot
│           └── Test.robot
├── .gitignore
├── .pabotsuitenames                                       # Pabot suite cache file
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── README.md
├── requirements.txt
└── SECURITY.md

```
---

## First-Time Setup Checklist

Before running:

* Python installed (3.10+)
* Node.js installed
* Salesforce CLI installed
* Chrome installed
* Virtual environment activated
* Salesforce org authenticated

#### Note: Install Salesforce CLI using npm command:

```
   npm install -g @salesforce/cli
```

---
## Setup

1. Clone the repository
   ```bash
   git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
   cd salesforce-files-downloader-tool
   ```
   
2. Create and activate a virtual environment

   Environment Setup: 
   ```bash
   python -m venv venv
   ```
   
   Activate Virtual Environment: Linux / macOS
   ```bash
   source venv/bin/activate
   ```
   
   Activate Virtual Environment: Windows (PowerShell / CMD)
   ```bash
   venv\Scripts\activate
   ```
   
3. Install dependencies
   ```bash 
   pip install -r requirements.txt
   ```
   
4. Authenticate to your Salesforce org
   ```bash
   sf org login web --alias <org_name>
   ```
   
5. Check the org connection status
   ```bash
   sf org list
   ```
   
## Connected Salesforce Org

| Alias     | Username                  | Org Id           | Status    |
|-----------|---------------------------|------------------|-----------|
| org_name  | username@agentforce.com   | 00XXXXXXXXXXXXXX | Connected |

## Salesforce Authentication

Authenticate to your Salesforce org using Salesforce CLI and generate the org information file:

```
   sf org display --json --target-org <OrgAlias> | Out-File -Encoding utf8 org_info.json
```

This generates `org_info.json`, which is used by the automation for:
* Access token
* Instance URL
* API version
* Org alias

**Note:** Never commit org_info.json containing real tokens. Add it to .gitignore.

---

## Input Data Format

* Input files must be Excel `.xlsx` files
* First column should contain Salesforce ContentDocument IDs
* Sheet name must match the value configured in the test (`Input` by default)

Example:

| ContentDocumentId  |
|--------------------|
| 069XXXXXXXXXXXXXXX |
| 069YYYYYYYYYYYYYYY |
| 069ZZZZZZZZZZZZZZZ |

---

## Execution

The automation supports parallel execution using pabot.

### Run the multiple tests using below pabot command: (Recommended)
```
   pabot --pabotlib --processes 2 --outputdir results src/robot/tests/Test.robot
```
* Note: Adjust --processes based on your machine (e.g., 2-8 recommended)

---

### Run a Single Test (One Batch)

To execute **only one batch** (for example, a single Excel input file) without parallel processing, or when debugging and troubleshooting, use the standard `robot` command instead of `pabot`.

#### Prerequisite

Ensure that only **one batch** is enabled under the **Test Cases** section in `Test.robot` when running in single-test mode.

#### Run All Batches Sequentially (Single Process)

```bash
robot src/robot/tests/Test.robot
```

This command runs all defined test cases sequentially in a single browser session.

#### Run a Specific Batch (Example: Batch 1)

To execute only a specific test case from multiple batches, use the `--test` option:

```bash
robot --test Download_Batch_1 src/robot/tests/Test.robot
```

This is useful when validating a single input file or isolating failures.

---

## Execution details:

Each pabot process creates a unique download folder under `downloads/`
* Files are downloaded in headless Chrome sessions
* Results are consolidated under the `results/` directory
* Failed records are logged in `output/<test_name>_Failed IDs_List.xlsx`


## Execution Flow

See [Architecture Overview](docs/architecture.md) for a visual execution flow and component breakdown.

* Initialize Salesforce REST session using access token
* Read ContentDocument IDs from Excel input
* Create a unique download directory per process
* Launch headless Chrome and authenticate via frontdoor URL
* Build download URL for each ContentDocument
* Download file and validate completion
* Move file into a ContentDocument-specific folder
* Generate upload-ready Excel files
* Log failures and size mismatches
* Clean up temporary and partial files

---

## Generated Excel Files for Bulk Insert

The tool automatically creates **two Excel files** in the `output/` folder for every run. These files are designed to make it easy to **re-upload** or **associate** the downloaded files back into Salesforce (e.g., using Data Loader, Workbench, or Salesforce Flow).
Both files are generated **per test case / batch** (named using the test name + timestamp), so each run produces isolated, traceable files.

The generated Excel files are ready for bulk insert using tools like **Data Loader**, **Salesforce Import Wizard**, or **Workbench**. Below are the column details:

## 1. ContentVersion Input File

**Purpose**  
Prepare an Excel file to perform bulk insert into the **ContentVersion** object (to upload files into Salesforce).

**ContentVersion Input File Columns**

| Column       | Description                                                    | Example Value                                           |
|--------------|----------------------------------------------------------------|---------------------------------------------------------|
| Title        | The title/name of the file (from original file metadata)       | Invoice_2025.pdf                                        |
| VersionData  | Full local path to the downloaded file (ready for upload)      | C:\...\downloads\<test_name>_..\069...\Invoice_2025.pdf |
| PathOnClient | Original filename (used as the client-side path during upload) | Invoice_2025.pdf                                        |

**Usage**  
* Open the file in Excel → Save As → CSV (UTF-8)
* Use Data Loader / Salesforce Import Wizard / External Tools to insert into **ContentVersion**
* After insert, you will get new **ContentVersion IDs** (needed for linking)

## 2. ContentDocumentLink Input File

**Purpose**  

Prepare an Excel file to perform bulk insert into the **ContentDocumentLink** object (to associate uploaded files with records).

**ContentDocumentLink Input File Columns**

| Column            | Description                                                                 | Example Value                          |
|-------------------|-----------------------------------------------------------------------------|----------------------------------------|
| ContentDocumentId | ID of the ContentDocument (after upload/insert into ContentVersion)         | 069xxxxxxxxxxxxxxx                     |
| LinkedEntityId    | ID of the record to link the file to (e.g., Account, Opportunity, Case ID)  | 001xxxxxxxxxxxxxxx                     |
| ShareType         | Sharing type (V = Viewer, C = Collaborator, I = Inferred)                   | V                                      |
| Visibility        | Visibility (AllUsers, InternalUsers, SharedUsers)                           | AllUsers                               |

**Usage**  
* After successful ContentVersion insert, copy the new **ContentDocumentId** values
* Fill in **LinkedEntityId** (the record IDs where files should appear)
* Save As CSV → Use Data Loader / Bulk API to insert into **ContentDocumentLink**

**Important Notes**  
* These files are **generated automatically** during each run.
* They contain **only successful downloads** (failed ones are logged separately).
* Use them for **recovery / re-upload** scenarios or to associate files with records after migration.
* File names include the test/batch name for easy identification.

Example generated files in `output/`:
* `Download_Batch_1_ContentVersion_Inputfile.xlsx`
* `Download_Batch_1_ContentDocumentLink_Inputfile.xlsx`

---
## Output Files Generated

| File Type                          | Location                              | Purpose                              |
|------------------------------------|---------------------------------------|--------------------------------------|
| Failed Records Log                 | `output/*_Failed IDs_List.xlsx`       | List of failed ContentDocument IDs   |
| ContentVersion Insert Ready        | `output/*_ContentVersion_*.xlsx`      | Prepare bulk upload of files         |
| ContentDocumentLink Insert Ready   | `output/*_ContentDocumentLink_*.xlsx` | Prepare linking files to records     |

---
## Error Handling and Logging

* Failed downloads are logged to a timestamped file under `output/` (e.g., `<test_name>_Failed IDs_List.xlsx`)
* Partial, corrupted, or mismatched downloads are automatically cleaned
* File size validation is performed post-download
* Execution reports are generated in HTML and XML formats

---

## Parallel Execution Strategy

* pabot is used to split execution across multiple processes
* Each process uses an isolated download directory
* UUID-based folder naming prevents file collisions
* Suitable for large-scale migrations with thousands of files

---

## CI/CD Compatibility

* Designed for headless execution
* Suitable for GitHub Actions, Jenkins, Azure DevOps
* No manual browser or driver setup required

---

### CI Smoke Test
The CI pipeline runs a dedicated smoke test (ci/robot/Smoke.robot) to validate:
* Robot Framework startup
* Selenium + Chrome in headless CI
* Custom ExcelLibrary keywords
* The smoke test does not authenticate to Salesforce or download files

This test is isolated from Salesforce authentication to ensure deterministic CI runs.

---

## Troubleshooting

* If you see ChromeDriver errors → ensure you're using SeleniumLibrary ≥6.0 (included in requirements.txt)
* For network/proxy issues → add proxy arguments in WebdriverManager.py
* Check results/pabot_results/log.html for detailed execution logs

| Error | Cause | Fix |
|-------|-------|------|
| WinError 10061 | PabotLib not running | Use --pabotlib |
| No module ExcelLibrary | venv not active | Activate venv |
| sf not found | CLI not installed | Reinstall CLI |

---

##  Technology Stack

* Robot Framework 7.0.1
* SeleniumLibrary 6.8.0 (with built-in Selenium Manager support)
* webdriver-manager 4.0.2 (automatic ChromeDriver handling)
* pabot 2.18.0 (parallel test execution)
* Custom ExcelLibrary wrapper based on openpyxl (Excel input reading and Excel files generation)

---
## Security

- No credentials are hardcoded.
- Authentication is handled via Salesforce CLI.
- Auth files must never be committed.
- Sensitive files are excluded via .gitignore.

Rotate credentials immediately if exposure is suspected.

---
## Roadmap

Planned enhancements:

* OAuth-based auth (non-CLI)
* Resume from checkpoint
* S3 / Azure Blob export
* CLI wrapper
* Docker support

---

## Notes

* Browser runs in headless mode by default (optimized for CI/CD and servers)
* All ChromeDriver management is automatic — no need to download or maintain chromedriver.exe
* Designed for scalability: tested with thousands of files across multiple parallel processes
* Secure handling of authentication via Salesforce CLI (no hardcoded credentials)


## Contributing

Contributions are welcome!

* Open issues for bugs
* Submit pull requests for improvements
* Follow existing coding patterns

---

## Author

**Name:** **Bhimeswara Vamsi Punnam**

**Role:** Lead Software Development Engineer in Test (SDET)
 
**Contact:** [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/bvamsipunnam)

---

## License

This project is licensed under the MIT License.  
See the [LICENSE](LICENSE) file for full terms and conditions.
