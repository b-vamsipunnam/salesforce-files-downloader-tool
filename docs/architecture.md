# Architecture

## Overview

The **Salesforce Files Downloader Tool** is a Robot Framework–based automation solution designed to reliably download large volumes of Salesforce files using ContentDocument IDs. The architecture cleanly separates **source code**, **inputs**, **runtime artifacts**, and **documentation**, making the project easy to maintain, scale, and execute in parallel.

The solution combines:
* Salesforce REST APIs for metadata and validation
* Headless browser automation for secure file downloads
* Parallel execution using pabot
* Deterministic folder isolation to avoid file collisions
* Dynamic Excel generation for ContentVersion and ContentDocumentLink records

---

## High-Level Architecture

```
┌──────────────────────────────┐
│ Excel Input Files            │
│ (ContentDocumentId)          │
└──────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Robot Test Suite             │  Test.robot
│ (Orchestration)              │
└──────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Support Keywords (Robot)     │  Support.robot
│ - Auth & Session Handling    │
│ - Download Orchestration     │
│ - Validation & Cleanup       │
└──────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Python Libraries             │
│ - SalesforceSupport.py       │
│ - WebdriverManager.py        │
└──────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Salesforce Platform          │
│ - REST API (SOQL)            │
│ - File Delivery (Shepherd)   │
└──────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Local Runtime Storage        │
│ - downloads/process_<uuid>   │
│ - output/Failed Records      │
│ - output/Data Loader files   │
└──────────────────────────────┘
```


## Repository Structure

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

## Folder Responsibilities

* **docs/**       – Architecture, design decisions, and technical documentation
* **src/robot/**  – Core Robot Framework test suites & support keywords (Robot + Python)
* **input/**      – Excel files containing ContentDocument IDs
* **downloads/**  – Runtime download workspace (isolated per pabot process)
* **output/**     – Failed records, validation warnings, generated Excel files to upload to data loader
* **results/**    – Robot Framework execution artifacts includes Pbot results

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
* Separate output/ folder per test case for traceability

### Download Flow

1. Read ContentDocument IDs from Excel
2. Initialize Salesforce REST session
3. Query metadata using SOQL (ContentDocument & ContentDocumentLink)
4. Launch headless Chrome with a custom download directory
5. Download files using Shepherd endpoints
6. Validate file completion and size
7. Move files into ContentDocument-specific folders
8. Generate Excel files for ContentVersion and ContentDocumentLink
9. Log failures and create separate failed IDs Excel
10. Clean temporary artifacts

---

## Runtime vs Source Separation

| Category            | Location     | Notes                        |
|---------------------| ------------ | ---------------------------- |
| Source code         | `src/robot/` | Version-controlled           |
| Input data          | `input/`     | Replaceable, non-runtime     |
| Downloads           | `downloads/` | Runtime only, ignored by git |
| Failed logs & Excel | `output/`    | Runtime artifacts            |
| Reports             | `results/`   | Robot Framework outputs      |
| Docs                | `docs/`      | Architecture & design        |

---

## Design Principles

* Deterministic folder isolation per process/test case
* Idempotent execution (safe to rerun)
* No credential hardcoding
* Clear separation of concerns
* Scalable to millions of files
* CI/CD and headless execution ready
* Automatic Excel generation for traceability & re-use

---

## Scalability Considerations

* Parallel execution with pabot
* Stateless browser sessions
* UUID + test-name-based directory isolation
* Streaming downloads instead of in-memory storage
* Safe cleanup of partial and corrupted files
* Separate output per test case avoids collisions

---

**Author:** Bhimeswara Vamsi Punnam

**Role:** Lead SDET / Automation Architect
