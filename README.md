# Salesforce Files Bulk Downloader

[![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-orange?style=flat&logo=robotframework&logoColor=white)](https://robotframework.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![Salesforce CLI](https://img.shields.io/badge/Salesforce-CLI-00A1E0?style=flat&logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/salesforcecli)
[![CI](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions/workflows/robot-ci.yml/badge.svg)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/actions)
[![Release](https://img.shields.io/github/v/release/b-vamsipunnam/salesforce-files-downloader-tool.svg?style=flat&color=orange)](https://github.com/b-vamsipunnam/salesforce-files-downloader-tool/releases/latest)
[![License](https://img.shields.io/github/license/b-vamsipunnam/salesforce-files-downloader-tool?style=flat)](LICENSE)

Salesforce Files Bulk Downloader uses Robot Framework and Python to download Salesforce Files in bulk from `ContentDocumentId` lists. Use it for migration, backup, and archival work, from small batches to large data sets.

**Built with**

- Robot Framework
- Python
- SeleniumLibrary
- Salesforce REST API
- Salesforce CLI
- Google Chrome

## Why this tool exists

Salesforce Files span a logical file (`ContentDocument`), version and binary metadata (`ContentVersion`), and record associations (`ContentDocumentLink`). A migration must preserve those relationships while handling API limits, sessions, binary volume, validation, retries, parallel workers, and failures.

The downloader separates metadata queries from binary transfer. It isolates batch output, validates file sizes, reports failed IDs, and can create Data Loader-ready workbooks. See the [Introduction](docs/Introduction.md) for the data model and migration details.

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
- Escapes formula-like ContentVersion titles before writing migration workbooks
- Supports headless Chrome and Pabot test-level parallel execution
- Validates Python and Robot code with Ruff, Robocop, and cross-platform CI

## Quick start

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
python -m pip install -r requirements.txt
```

Before authenticating, complete the [Installation](docs/Installation.md) checks. New installations use the latest Node.js LTS, the latest compatible npm release, and the stable Salesforce CLI `latest` channel. The guide checks the current engine requirements instead of pinning short-lived patch versions. Follow [Authentication](docs/Authentication.md) to log in and generate a non-redacted `org_info.json`:

```bash
robot --variable ORG_ALIAS:<org_alias> --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

Add `ContentDocumentId` values to the first column of `input/Inputfile_1.xlsx`, then run the downloader:

```bash
robot --outputdir results src/robot/orchestrators/download.robot
```

Downloaded files appear in `downloads/`, migration and failure workbooks in `artifacts/`, and Robot Framework reports in `results/`.

## Architecture

![Salesforce Files Bulk Downloader execution architecture](docs/architecture.svg)

The tool queries metadata through Salesforce REST APIs and downloads binaries from Shepherd through an authenticated Selenium browser. Robot Framework handles validation and reporting; Pabot runs isolated batches in parallel. See [Architecture](docs/Architecture.md) for the full workflow and component diagram.

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
│       ├── orchestrators/
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
- `src/robot/orchestrators/` defines executable download batches.
- `src/robot/resources/` contains configuration and reusable workflow keywords.
- `input/` contains Excel workbooks listing source `ContentDocumentIds`.
- `downloads/` stores validated file binaries in isolated batch directories.
- `artifacts/` stores JSONL execution manifests, migration workbooks, and structured failed-ID workbooks.
- `results/` receives Robot Framework and Pabot execution reports.
- `requirements.txt` pins the Python dependencies used by the project.
- `requirements-dev.txt` pins the Ruff and Robocop versions used by contributors and CI.

## Contributing

Before opening an issue or pull request, read the [Contributing](docs/Contributing.md) guide, [Code of Conduct](CODE_OF_CONDUCT.md), and [Security Policy](SECURITY.md).

## License

Licensed under the [MIT License](LICENSE).
