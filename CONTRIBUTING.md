# Contributing to Salesforce Files Downloader Tool

Bug reports, documentation fixes, and focused code contributions are welcome. This guide covers the checks and conventions used to keep changes easy to review and safe to merge.

## Before you start

For a substantial behavior or architecture change, open an issue first so the approach can be discussed before implementation. Security vulnerabilities must follow the private process in [SECURITY.md](SECURITY.md).

## Set up the project

Fork the repository, clone your fork, and create a virtual environment:

```bash
git clone https://github.com/your-username/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate the environment and install the pinned dependencies:

```bash
pip install -r requirements.txt
```

Python 3.10 or later is required. Authenticated download runs also require Salesforce CLI and Google Chrome; see [Installation](docs/Installation.md) and [Authentication](docs/Authentication.md).

## Make a focused change

Create a branch whose name describes the work:

```bash
git checkout -b fix/download-timeout
```

Keep the change limited to one concern. Follow the existing Robot Framework and Python patterns, avoid hardcoded paths, and update documentation whenever behavior or configuration changes.

Use a concise conventional commit subject:

```bash
git commit -m "fix: handle invalid ContentDocumentId"
```

Common types include `fix`, `feat`, `docs`, `test`, and `refactor`.

## Verify the change

Run the offline unit and smoke suites before opening a pull request:

```bash
python -m unittest discover -s ci/tests -v
robot --outputdir results/smoke ci/robot/smoke.robot
```

When the change affects the authenticated workflow, also run:

```bash
robot --outputdir results src/robot/orchestrator/download.robot
```

This suite requires an authenticated Salesforce CLI alias, a current `org_info.json`, Chrome, and valid input workbooks. To exercise worker isolation, use test-level Pabot splitting:

```bash
pabot --pabotlib --testlevelsplit --processes 2 --outputdir results src/robot/orchestrator/download.robot
```

Review `output.xml`, `log.html`, and `report.html` before sharing them. Remove customer data, tokens, org identifiers, filenames, and other sensitive values.

## Report a bug

Search existing issues before opening a new one. Include:

- A concise description of the observed and expected behavior
- Minimal steps to reproduce the problem
- Python, Robot Framework, Salesforce CLI, Chrome, and operating-system versions
- Sanitized logs or screenshots
- A small sample input when it can be shared safely

## Suggest an enhancement

Describe the problem first, then the proposed change and a representative use case. Calling out compatibility, migration, security, or performance constraints helps reviewers assess the proposal.

## Open a pull request

Push your branch and open a pull request against the repository:

```bash
git push origin fix/download-timeout
```

The pull request should explain:

- What changed and why
- Which issue it addresses, if applicable
- How the change was tested
- Any operational, compatibility, or documentation impact

All required CI checks must pass. A maintainer may request changes before merge.

## Code and documentation conventions

For Robot Framework changes:

- Use descriptive keyword names and explicit arguments.
- Keep reusable behavior in resource files or Python libraries.
- Prefer return values for expected states; reserve assertions for actual failures.
- Avoid exposing authentication data through logs.
- Preserve per-worker directory and workbook isolation.

For documentation changes:

- Use short, practical explanations and sentence-case headings.
- Keep examples aligned with the current commands and configuration.
- Link to the detailed guide instead of repeating the same explanation.
- Update [Keyword documentation](docs/Keyword-Documentation.md) when a public keyword changes.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md) in all project interactions.
