# Architecture

## Overview

The **Salesforce Files Bulk Downloader** is a Robot Framework–based automation solution designed to reliably download large volumes of Salesforce files using ContentDocument IDs. The architecture cleanly separates **source code**, **inputs**, **runtime artifacts**, and **documentation**, making the project easy to maintain, scale, and execute in parallel.

Browser-based downloads are used to leverage Salesforce’s Shepherd endpoint, which ensures reliable file delivery with original filenames and avoids API limitations associated with binary retrieval.

The solution combines:
* Salesforce REST APIs for metadata and validation
* Headless browser automation for secure file downloads
* Parallel execution using pabot
* Deterministic folder isolation to avoid file collisions
* Dynamic Excel generation for ContentVersion and ContentDocumentLink bulk insert workflows


### Why This Architecture

Salesforce file downloads involve both metadata retrieval and binary transfer.

* REST APIs efficiently provide metadata but are not optimal for large-scale binary extraction.
* Shepherd endpoints provide reliable file delivery but require browser session handling.

This architecture combines both approaches to:
* Reduce API consumption
* Preserve file integrity and naming
* Enable scalable parallel execution

---

## High-Level Architecture

<p align="center">
  <img src="architecture.png" width="700">
</p>

### Architecture Breakdown

The system follows a hybrid execution model:

* **Control Plane (REST API)**
  - Retrieves metadata using SOQL queries
  - Fetches ContentDocument and ContentDocumentLink details
  - Generates structured data for processing and re-upload

* **Data Plane (Browser Automation)**
  - Uses headless Chrome to download files via Shepherd endpoints
  - Handles authentication via frontdoor URL
  - Ensures reliable binary transfer without API limits

* **Execution Layer**
  - Robot Framework orchestrates workflow
  - pabot enables parallel execution across processes

* **Storage Layer**
  - downloads/: binary file storage
  - artifacts/: Excel outputs and failure logs
  - results/: execution logs and reports
  
## Repository Structure

```
salesforce-files-downloader-tool/
├── .github/
│   ├── workflows/
│   │   └── robot-ci.yml                                   # GitHub Actions CI
│   └── PULL_REQUEST_TEMPLATE.md                           # Pull request template
├── artifacts/                                             # Runtime: Failed records + Data Loader-ready Excels
│   └── <test_name>__<uuid>/                               # One folder per test case
│       ├── <test_name>_Failed_IDs.xlsx
│       ├── <test_name>_ContentVersion_Import.xlsx
│       └── <test_name>_ContentDocumentLink_Import.xlsx
├── ci/
│   └── robot/
│       └── smoke.robot
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
├── results/                                               # Robot execution results
│   ├── pabot_results/
│   ├── log.html
│   ├── output.xml
│   └── report.html
├── src/
│   └── robot/
│       ├── libraries/
│       │   ├── ExcelLibrary.py
│       │   ├── SalesforceSupport.py
│       │   └── WebdriverManager.py
│       ├── resources/
│       │   └── keywords.robot
│       └── orchestrator/
│           └── download.robot
├── .gitignore
├── .pabotsuitenames                                       # Pabot suite cache file
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── README.md
├── requirements.txt
└── SECURITY.md

```

## Folder Responsibilities

* **docs/**       – Architecture, design decisions, and technical documentation
* **src/robot/**  – Core Robot Framework test suites & support keywords (Robot + Python)
* **input/**      – Excel files containing ContentDocument IDs
* **downloads/**  – Runtime download workspace (isolated per pabot process)
* **artifacts/**     – Failed records, validation warnings, generated Excel files to upload to data loader
* **results/**    – Robot Framework execution artifacts including pabot results

---

## Execution Model

### Authentication

* Salesforce authentication is handled externally via Salesforce CLI
* `sf org display --json` generates `org_info.json`
* Access token–based authentication avoids username/password usage

### Parallel Execution

* pabot splits execution across multiple processes
* Each process creates a unique `<test_name>_<uuid>` download directory
* Browser instances and file operations are fully isolated
* Separate `artifacts/` folder per test case for traceability


### Download Flow

* Read ContentDocument IDs from Excel
* Initialize Salesforce REST session
* Query metadata using SOQL (ContentDocument & ContentDocumentLink)
* Launch headless Chrome with a custom download directory
* Download files using Shepherd endpoints
* Validate file completion and size 
* Move files into ContentDocument-specific folders 
* Generate Excel files for ContentVersion and ContentDocumentLink 
* Log failures and create separate failed IDs Excel 
* Clean temporary artifacts

---

## Failure and Recovery Model

* Failed downloads are logged per test case
* Partial files are cleaned automatically
* Execution can be resumed by rerunning failed batches using generated failure logs
* Output Excel files preserve successful records

---
## Security Architecture

* Authentication delegated to Salesforce CLI
* No credentials stored in source code
* Access tokens loaded at runtime
* Auth files excluded via .gitignore
* CI runs without org credentials

---
## Runtime vs Source Separation

| Category            | Location     | Notes                        |
|---------------------| ------------ | ---------------------------- |
| Source code         | `src/robot/` | Version-controlled           |
| Input data          | `input/`     | Replaceable, non-runtime     |
| Downloads           | `downloads/` | Runtime only, ignored by git |
| Failed logs & Excel | `artifacts/` | Runtime artifacts            |
| Reports             | `results/`   | Robot Framework outputs      |
| Docs                | `docs/`      | Architecture & design        |

---

## Design Principles

* Deterministic folder isolation per process/test case
* Idempotent execution (safe to rerun)
* No credential hardcoding
* Clear separation of concerns
* Scalable to very large datasets (thousands to millions of files)
* CI/CD and headless execution ready
* Automatic Excel generation for traceability & re-use
* Designed to operate within Salesforce API limits without retry amplification

---

## Scalability Considerations

* Designed to scale across multiple processes and machines for large-scale file extraction workloads (thousands to millions of files)
* Parallel execution with pabot
* Stateless browser sessions
* UUID + test-name-based directory isolation
* Streaming downloads instead of in-memory storage
* Safe cleanup of partial and corrupted files
* Separate artifacts per test case avoids collisions
* Parallel execution can scale throughput depending on CPU, memory, and network conditions

---

## Extensibility

The framework supports extension via:

* Additional Robot keywords
* New Python helper libraries
* Alternative storage backends
* Custom validation rules

---
## Observability and Monitoring

* Execution status available via Robot HTML reports
* Per-process logs under `results/pabot_results/`
* Failed records isolated in artifacts Excel files
* Timestamped execution artifacts enable auditing
* Per-test and per-process isolation enables easier debugging and failure tracing

---
## Deployment Model

* Local developer machines
* CI/CD pipelines (GitHub Actions, Jenkins)
* Headless server environments
* Containerized environments (planned)

---

**Author:** Bhimeswara Vamsi Punnam

**Role:** Lead Software Development Engineer in Test (SDET)
