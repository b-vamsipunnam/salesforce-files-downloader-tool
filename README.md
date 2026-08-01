# Salesforce Files Bulk Downloader

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce CLI](https://img.shields.io/badge/Salesforce-CLI-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/salesforcecli)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-ci.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool.svg?style=flat&color=orange)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases/latest)
[![License](https://img.shields.io/github/license/b-vamsipunnam/salesforce-files-downloader-tool?style=flat)](LICENSE)

Salesforce Files Bulk Downloader uses Robot Framework and Python to download Salesforce Files in bulk from `ContentDocumentId` lists. It is intended for migration, backup, and archival work ranging from small batches to large data sets.

**Built with**

- Robot Framework
- Python
- SeleniumLibrary
- Salesforce REST API
- Salesforce CLI
- Google Chrome

## Why this tool exists

Salesforce Files combine a logical file (`ContentDocument`), version and binary metadata (`ContentVersion`), and record associations (`ContentDocumentLink`). Enterprise migration work must preserve these relationships while managing API limits, sessions, binary volume, validation, bounded retry handling, parallel workers, and failure reporting.

This project separates metadata retrieval from binary transfer and provides isolated batch outputs, size validation, failed-ID reporting, and optional Data Loader-ready workbooks. See the [Introduction](docs/Introduction.md) for the data model and migration challenges.

## Typical use cases

- Enterprise file migration projects
- Salesforce org consolidation
- Divestitures and acquisitions
- Backup and archival
- Migration validation and reconciliation
- Large-scale ContentDocument extraction
- Sandbox preparation
- Disaster recovery preparation

## Key features

- Accepts 15- and 18-character `ContentDocumentId` values, canonicalizes them to 18 characters, and removes duplicates
- Uses Salesforce CLI authentication without storing usernames or passwords
- Queries `ContentDocument` and all associated `ContentDocumentLink` records in batches
- Starts the batch audit manifest, then checks Salesforce daily API capacity before creating migration workbooks or download directories
- Downloads each physical file once into a ContentDocument-specific directory
- Isolates download and artifact directories for each batch and worker
- Checks completion, stability, and final size against Salesforce `ContentSize`
- Removes the final binary if its migration-workbook transaction cannot be committed
- Automatically retries transient download failures and writes structured failure codes, messages, and attempt counts for unresolved IDs
- Writes a per-batch JSONL execution manifest for programmatic reconciliation and audit
- Detects expired REST and browser sessions instead of reporting them as generic download failures
- Creates optional ContentVersion and ContentDocumentLink import workbooks
- Supports headless Chrome and Pabot test-level parallel execution
- Validates Python and Robot code with Ruff, Robocop, and cross-platform CI

## Quick start

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
pip install -r requirements.txt
sf org login web --alias <org_alias>
```

Follow the [Authentication](docs/Authentication.md) guide to generate `org_info.json`. Then add `ContentDocumentId` values to the first column of `input/Inputfile_1.xlsx` and run:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

Downloaded files appear in `downloads/`, migration and failure workbooks in `artifacts/`, and Robot Framework reports in `results/`.

## Architecture

![Salesforce Files Bulk Downloader execution architecture](docs/architecture.svg)

The tool uses Salesforce REST APIs for metadata and an authenticated Selenium browser for Shepherd file downloads. Robot Framework coordinates validation and reporting, while Pabot can isolate and run batches in parallel. See the [Architecture](docs/Architecture.md) guide for the complete workflow and detailed component diagram.

## Contents

| Documentation                                          | Description                                                                          |
|--------------------------------------------------------|--------------------------------------------------------------------------------------|
| [Introduction](docs/Introduction.md)                   | Salesforce Files concepts, enterprise migration challenges, and why this tool exists |
| [Installation](docs/Installation.md)                   | Prerequisites and environment setup                                                  |
| [Authentication](docs/Authentication.md)               | Salesforce CLI authentication and session handling                                   |
| [Configuration](docs/Configuration.md)                 | Runtime variables, paths, timeouts, and execution settings                           |
| [Usage](docs/Usage.md)                                 | Sequential and parallel execution instructions                                       |
| [Examples](docs/Examples.md)                           | Common execution scenarios                                                           |
| [Architecture](docs/Architecture.md)                   | End-to-end system design and component responsibilities                              |
| [Performance](docs/Performance.md)                     | Benchmark results, worker scaling, retries, and validation                           |
| [Keyword Documentation](docs/Keyword-Documentation.md) | Robot Framework keywords grouped by responsibility                                   |
| [Troubleshooting](docs/Troubleshooting.md)             | Common errors and recommended resolutions                                            |
| [FAQ](docs/FAQ.md)                                     | Frequently asked technical and usage questions                                       |
| [Limitations](docs/Limitations.md)                     | Current constraints and unsupported scenarios                                        |
| [Roadmap](docs/Roadmap.md)                             | Planned improvements and future direction                                            |
| [Contributing](docs/Contributing.md)                   | Development workflow and contribution guidelines                                     |

## Repository structure

```text
salesforce-files-downloader-tool/
├── docs/
├── src/
│   └── robot/
│       ├── libraries/
│       ├── orchestrator/
│       └── resources/
├── input/
├── downloads/
├── artifacts/
├── results/
├── requirements.txt
├── LICENSE
├── README.md
├── CODE_OF_CONDUCT.md
└── SECURITY.md

```

- `docs/` contains the project documentation and architecture diagram.
- `src/robot/libraries/` contains custom Python libraries used by Robot Framework.
- `src/robot/orchestrator/` defines executable download batches.
- `src/robot/resources/` contains configuration and reusable workflow keywords.
- `input/` contains Excel workbooks listing source `ContentDocumentIds`.
- `downloads/` stores validated file binaries in isolated batch directories.
- `artifacts/` stores JSONL execution manifests, migration workbooks, and structured failed-ID workbooks.
- `results/` receives Robot Framework and Pabot execution reports.
- `requirements.txt` pins the Python dependencies used by the project.
- `requirements-dev.txt` pins the Ruff and Robocop versions used by contributors and CI.

## Contributing

Bug reports, documentation improvements, and code contributions are welcome. Please read the [Contributing](docs/Contributing.md) guide, [Code of Conduct](CODE_OF_CONDUCT.md), and [Security Policy](SECURITY.md) before opening issues or pull requests.

## License

Licensed under the [MIT License](LICENSE).
