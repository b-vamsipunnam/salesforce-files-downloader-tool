# Salesforce Files Downloader Tool

---

## Built With

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.0.1-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![SeleniumLibrary](https://img.shields.io/badge/SeleniumLibrary-6.8.0-green?style=flat&logo=selenium&logoColor=white)](https://github.com/robotframework/SeleniumLibrary) 
[![Pabot](https://img.shields.io/badge/Pabot-2.18.0-blue?style=flat)](https://github.com/mkorpela/pabot) 
[![webdriver-manager](https://img.shields.io/badge/webdriver--manager-4.0.2-blue?style=flat)](https://pypi.org/project/webdriver-manager/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/) 
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-tests.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat)](https://opensource.org/licenses/MIT)

---

## Introduction

The Salesforce Files Downloader Tool is an open-source, parallel-processing automation framework built with **Robot Framework** and **Python** for fast, reliable bulk downloads of Salesforce files using ContentDocument IDs.

Key features:
- Works with **any Salesforce org** (authenticated via Salesforce CLI)
- Downloads files using the secure **Shepherd endpoint**
- Runs **multiple browsers in parallel** with Pabot
- Preserves original filenames and organizes per ContentDocumentId
- Generates **Data Loader–ready Excel files** (ContentVersion & ContentDocumentLink)
- Tracks failed downloads with retry-safe logs
- Fully isolated per-test output folders


## When to Use This Tool

Use this tool when you need to:
- Migrate or back up thousands of Salesforce files
- Re-upload files after org refresh or data loss
- Perform controlled file migrations between Salesforce orgs
- Generate Data Loader–ready input files automatically

---

## Quick Start

1. Authenticate to your Salesforce org: (`Replace <org_name> with your org alias`)
   ```powershell
   sf org display --json --target-org <org_name> | Out-File -Encoding utf8 org_info.json

2. Run parallel downloads:
   ```powershell
   pabot --pabotlib --processes 2 --outputdir results robot/tests/Test.robot

3. Check results
   ```powershell
   Downloaded files: downloads/<test_name>_<uuid>/069.../<filename>
   
   Generated Excels & logs: output/

---

## Project Structure

```
salesforce-files-downloader-tool/
├── .github/
│   └── workflows/
│        ├── robot-test.yml
│   └── PULL_REQUEST_TEMPLATE.md                               # GitHub Actions CI
├── ci/
│   └──  robot/
│        └── Smoke.robot
├── docs/
│   └── architecture.md                                        # High-level design documentation
├── downloads/                                                 # Runtime: downloaded Salesforce files
│   └── <test_name>_<uuid>/                                    # One folder per pabot process
│        ├── 069xxxxxxxxxxxx
│        └── 069yyyyyyyyyyyy 
│   └── <test_name>_<uuid>/                                    # One folder per pabot process
│        ├── 069xxxxxxxxxxxx
│        └── 069yyyyyyyyyyyy 
├── input/                                                     # Input Excel files
│   ├── Inputfile_1.xlsx
│   └── Inputfile_2.xlsx
├── output/                                                    # Failed record logs & generated Excels
│   └── <test_name>__<uuid>/
│        ├── <test_name>_Failed IDs_List.xlsx
│        ├── <test_name>_ContentVersion_Inputfile.xlsx
│        └── <test_name>_ContentDocumentLink_Inputfile.xlsx
│   └── <test_name>__<uuid>/
│        ├── <test_name>_Failed IDs_List.xlsx
│        ├── <test_name>_ContentVersion_Inputfile.xlsx
│        └── <test_name>_ContentDocumentLink_Inputfile.xlsx
├── results/                                                   # Robot execution results
│   ├── pabot_results/
│   ├── log.html
│   ├── output.xml
│   └── report.html
├── src/
│   └──  robot/
│        └── Library/
│            ├── ExcelLibrary.py
│            ├── SalesforceSupport.py
│            └── WebdriverManager.py
│        └── tests/
│            ├── Support.robot
│            └── Test.robot
├── .gitignore
├── .pabotsuitenames                                           # Generated auth file
├── org_info.json                                              # Salesforce org auth (generated)
├── PIPE
├── README.md                                                  # Read this file
└── requirements.txt                                           # Python dependencies

```
---

## Prerequisites

* Python 3.10 or higher
* Salesforce CLI (`sf`)
* Google Chrome browser
* Virtual environment (recommended)

---
## Setup

1. Clone the repository
   ```bash
   git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
   cd salesforce-files-downloader-tool
   
2. Create and activate a virtual environment
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   venv\Scripts\activate     # Windows
   
3. Install dependencies
    ```bash 
   pip install -r requirements.txt
   
4. Authenticate to your Salesforce org
    ```bash
   sf org login web --alias <org_name>
   
5. check the org connection status
   ```bash
   sf org list
   
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

Run the multiple tests using below pabot command:
```
   pabot --pabotlib --processes 2 --outputdir results src/robot/tests/Test.robot
```
* Note: Adjust --processes based on your machine (e.g., 2-8 recommended)

Running a Single Test Case (One Process)

If you want to execute **only one batch** (e.g., just one Excel file) without parallel execution, or if you're debugging/troubleshooting, use the standard `robot` command instead of `pabot`.

```
   robot robot/tests/Test.robot
```

* Or, to run a specific test case (e.g., only Batch 1):

```
   robot --test Download_Files_Batch_1 robot/tests/Test.robot
```
---

## Execution details:

Each pabot process creates a unique download folder under `downloads/`
* Files are downloaded in headless Chrome sessions
* Results are consolidated under the `results/` directory
* Failed records are logged in `output/<test_name>_Failed IDs_List.xlsx`


## Execution Flow

📌 See [Architecture Overview](docs/architecture.md) for a visual execution flow and component breakdown.

* Initialize Salesforce REST session using access token
* Read ContentDocument IDs from Excel input
* Create a unique download directory per process
* Launch headless Chrome and authenticate via frontdoor URL
* Build download URL for each ContentDocument
* Download file and validate completion
* Move file into a ContentDocument-specific folder
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

| Column       | Description                                                    | Example Value                                        |
|--------------|----------------------------------------------------------------|------------------------------------------------------|
| Title        | The title/name of the file (from original file metadata)       | Invoice_2025.pdf                                     |
| VersionData  | Full local path to the downloaded file (ready for upload)      | C:\...\downloads\process_...\069...\Invoice_2025.pdf |
| PathOnClient | Original filename (used as the client-side path during upload) | Invoice_2025.pdf                                     |

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
* `Download_Files_Batch_1_ContentVersion_Inputfile.xlsx`
* `Download_Files_Batch_1_ContentDocumentLink_Inputfile.xlsx`

---
## Output Files Generated

| File Type                          | Location                              | Purpose                              |
|------------------------------------|---------------------------------------|--------------------------------------|
| Failed Records Log                 | `output/*_Failed IDs_List.xlsx`       | List of failed ContentDocument IDs   |
| ContentVersion Insert Ready        | `output/*_ContentVersion_*.xlsx`      | Prepare bulk upload of files         |
| ContentDocumentLink Insert Ready   | `output/*_ContentDocumentLink_*.xlsx` | Prepare linking files to records     |

---
## Error Handling and Logging

* Failed downloads are logged to a timestamped file under `Output/` (e.g., `<test_name>_Failed IDs_List.xlsx`)
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

This test is isolated from Salesforce authentication to ensure deterministic CI runs.

---

## Troubleshooting

* If you see ChromeDriver errors → ensure you're using SeleniumLibrary ≥6.0 (included in requirements.txt)
* For network/proxy issues → add proxy arguments in WebdriverManager.py
* Check results/pabot_results/log.html for detailed execution logs

---

##  Key Technologies

* Robot Framework 7.0.1
* SeleniumLibrary 6.8.0 (with built-in Selenium Manager support)
* webdriver-manager 4.0.2 (automatic ChromeDriver handling)
* pabot 2.18.0 (parallel test execution)
* robotframework-excellib (Excel input reading and Excel files generation)

---

## Notes

* Browser runs in headless mode by default (optimized for CI/CD and servers)
* All ChromeDriver management is automatic — no need to download or maintain chromedriver.exe
* Designed for scalability: tested with thousands of files across multiple parallel processes
* Secure handling of authentication via Salesforce CLI (no hardcoded credentials)


## Contributing

* Found a bug or have an improvement?  
* Please open an issue or submit a pull request!

---

## Author

**Bhimeswara Vamsi Punnam**

Lead Software Development Engineer in Test
 
**Contact:** [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/bvamsipunnam)

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.
