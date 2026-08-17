# Installation

## Prerequisites

- Python 3.10 or later
- Robot Framework (installed by `requirements.txt`)
- Latest stable Salesforce CLI (`sf`)
- Google Chrome
- Latest supported Node.js LTS release satisfying the Salesforce CLI and npm engine requirements
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

This installs Robot Framework, SeleniumLibrary, Pabot, RequestsLibrary, Selenium, OpenPyXL, and the project's HTTP client.

Contributors should also install the pinned development checks used by CI:

```bash
python -m pip install -r requirements-dev.txt
ruff --version
robocop --version
```

Runtime users do not need `requirements-dev.txt` unless they want to run the repository's static-analysis checks locally.

## Salesforce CLI

### Version policy

Use supported release channels instead of permanently pinning patch versions:

- NVM for Windows: latest stable release; 1.2.2 was current when this guide was verified on 2026-08-16.
- Node.js: latest LTS, not the non-LTS Current release; Node.js 24.18.0 was the latest LTS when verified.
- npm: latest stable version compatible with the active Node.js runtime; npm 12.0.2 was current when verified.
- Salesforce CLI: npm `latest` channel; `@salesforce/cli` 2.147.7 was current when verified and declared `node >=22.0.0`.

Patch versions change frequently. The dated versions above record what was verified; they are not installation pins. The commands below resolve and check current releases. See the [NVM for Windows releases](https://github.com/coreybutler/nvm-windows/releases), [Node.js release schedule](https://nodejs.org/en/about/previous-releases), [npm release guidance](https://docs.npmjs.com/about-npm-versions/), and [Salesforce CLI release notes](https://github.com/forcedotcom/cli/tree/main/releasenotes).

### Strict Windows installation with NVM

Node.js 18 is end-of-life and cannot run current Salesforce CLI releases. Install or update NVM for Windows first, then activate the latest Node.js LTS before updating npm or Salesforce CLI. NVM stores global npm packages separately for each Node version, so switching Node versions requires reinstalling global packages in the newly active runtime.

Install the latest signed [NVM for Windows release](https://github.com/coreybutler/nvm-windows/releases). To update an existing NVM installation, use the newest official installer and reopen the terminal. In an elevated Command Prompt or PowerShell, run:

```powershell
nvm version
nvm install lts
nvm use lts
nvm current
where.exe node
node --version
npm --version
```

Confirm that `node --version` reports the current LTS line. Check the live npm compatibility declaration before updating npm, then install its latest compatible stable release:

```powershell
npm view npm@latest version engines --json
npm install --global npm@latest
npm --version
```

Check the live Salesforce CLI version and Node.js requirement before installing it:

```powershell
npm view @salesforce/cli@latest version engines --json
npm install --global @salesforce/cli@latest
where.exe sf
sf.cmd --version
```

The Node version printed by `sf.cmd --version` must match the active `node --version` and satisfy the engine range returned by `npm view`. The output has this form, with versions resolved at installation time:

```text
@salesforce/cli/<current-version> win32-x64 node-v<active-LTS-version>
```

If `where.exe node`, `where.exe npm`, or `where.exe sf` shows unexpected installations before the active NVM path, correct `PATH` and reopen PowerShell and PyCharm. On Windows, use `sf.cmd` for direct validation commands; this avoids PowerShell choosing `sf.ps1` under a restrictive execution policy.

### Other platforms and installation methods

Install the latest Node.js LTS release, then install Salesforce CLI with an official Salesforce installer or npm. When using npm, verify both live engine declarations before upgrading:

```bash
npm view npm@latest version engines --json
npm install --global npm@latest
npm view @salesforce/cli@latest version engines --json
npm install --global @salesforce/cli@latest
sf --version
```

## Chrome

Install a current Google Chrome release and confirm it starts in the execution environment. The browser helper configures headless and automatic downloads and gives each session an isolated absolute download path. The project does not document a separate driver setup.

## Verify the environment

```bash
python --version
robot --version
pabot --version
node --version
sf.cmd --version  # Windows
sf --version      # Linux or macOS
```

Do not continue to authentication unless Node.js and npm satisfy the live engine declarations, the CLI version names the active Node runtime, and `sf org display --target-org <org_alias> --json` completes successfully.

Complete the [Authentication](Authentication.md) steps before running the downloader.

---

[← Previous](Introduction.md) | [Next →](Authentication.md)

[Back to README](../README.md)
