# Installation

This page covers local setup only. Complete [Authentication](Authentication.md) after these checks pass.

## Prerequisites

Install:

- [Git](https://git-scm.com/downloads)
- Python 3.10 or later
- [Google Chrome](https://www.google.com/chrome/)
- [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm), which provides the `sf` command
- A spreadsheet editor that can save `.xlsx` files

Use a current supported Salesforce CLI release. The official installers include their required runtime. Node.js is needed only if you choose the npm installation method; in that case, use a Node.js version allowed by the current `@salesforce/cli` package instead of relying on a version copied from this guide.

ChromeDriver does not need to be installed separately. Selenium is the browser automation library used by the project; its Selenium Manager resolves a driver for the installed Chrome version when the browser starts.

## Set up the Python environment

Clone the repository and create a virtual environment:

```bash
git clone https://github.com/b-vamsipunnam/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate it on Windows PowerShell:

```powershell
venv\Scripts\Activate.ps1
```

If PowerShell prevents script activation, use Command Prompt instead:

```batch
venv\Scripts\activate.bat
```

Activate it on Linux or macOS:

```bash
source venv/bin/activate
```

Install the pinned runtime packages:

```bash
python -m pip install -r requirements.txt
python -m pip check
```

`pip check` should finish with `No broken requirements found.`

The installation also provides Robot Framework, the task runner behind `robot`, and Pabot, its optional parallel runner.

## Verify the installation

```bash
python --version
robot --version
pabot --version
sf --version
```

Python must report 3.10 or later. The other commands should print version information without an error. On Windows, run `sf.cmd --version` if PowerShell blocks the `sf.ps1` wrapper.

Start Chrome once in the same desktop environment where the downloader will run. If the machine uses a proxy, endpoint security, or browser-management policy, make sure it permits Selenium Manager and automatic downloads.

Contributors also need the development packages and checks described in [CONTRIBUTING.md](../CONTRIBUTING.md).

[Back to README](../README.md)
