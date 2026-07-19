# Installation

## Prerequisites

- Python 3.10 or later
- Robot Framework (installed by `requirements.txt`)
- Salesforce CLI (`sf`)
- Google Chrome
- Node.js, when installing Salesforce CLI through npm
- Read access to the requested Salesforce files and metadata

## Environment preparation

Clone the repository and create an isolated Python environment:

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate it on Windows:

```powershell
venv\Scripts\activate
```

Activate it on Linux or macOS:

```bash
source venv/bin/activate
```

Install the pinned dependencies:

```bash
python -m pip install -r requirements.txt
```

This installs Robot Framework, SeleniumLibrary, Pabot, RequestsLibrary, Selenium, OpenPyXL, and the Salesforce and utility packages used by the project.

## Salesforce CLI

Install the CLI with an official Salesforce installer or npm:

```bash
npm install --global @salesforce/cli
sf --version
```

## Chrome

Install a current Google Chrome release and confirm it can start in the execution environment. The project's browser helper configures Chrome for headless downloads; no separate driver setup is documented by this project.

## Verify the environment

```bash
python --version
robot --version
pabot --version
sf --version
```

Continue with Salesforce authentication before running the suite.

---

[← Previous](Introduction.md) | [Next →](Authentication.md)

[Back to README](../README.md)
