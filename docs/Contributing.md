# Contributing

Contributions may include bug reports, feature proposals, documentation, tests, and code changes. Follow the repository [code of conduct](../CODE_OF_CONDUCT.md) and use [SECURITY.md](../SECURITY.md) for vulnerability reports.

## Before opening a change

Search existing issues. For a bug, provide reproducible steps, sanitized errors, the command used, and relevant environment versions. For a larger enhancement, describe the problem, use case, and proposed behavior before implementation.

## Development setup

Fork and clone the repository, create a virtual environment, and install dependencies as described in [Installation](Installation.md). Create a focused branch:

```bash
git checkout -b feature/short-description
```

Keep changes consistent with the existing project structure and naming conventions. Prefer descriptive reusable keywords, variables over hard-coded paths, focused commits, and documentation updates when behavior changes.

## Verification

Start with the offline checks. They cover the Python libraries, Robot syntax, mocked Salesforce CLI retries, API-capacity decisions, SOQL pagination, metadata grouping, canonical ID handling, workbook rollback, and a real local headless-Chrome startup without connecting to Salesforce:

```bash
ruff check src ci
robocop check src ci
python -m unittest discover -s ci/tests -v
robot --outputdir results/smoke ci/robot/smoke.robot
```

The main suite requires Salesforce access and valid input. Run it when the change affects authenticated behavior, and record the environment and test scope in the pull request:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

For parallel behavior:

```bash
pabot --pabotlib --testlevelsplit --processes 2 --outputdir results src/robot/orchestrator/download.robot
```

GitHub Actions runs the Python 3.10 and 3.11 matrix on Ubuntu and Windows. Ubuntu performs the real headless-Chrome smoke run; Windows performs unit tests, Robot dry-run validation, Ruff, and error-level Robocop checks. CI does not connect to Salesforce or download customer files.

## Pull requests

Keep each pull request focused on a single change. Use meaningful commit messages, link related issues, describe user-visible behavior, and summarize the verification performed. Never commit access tokens, passwords, `org_info.json`, runtime downloads, or customer data.

For repository policies and contribution expectations, refer to the root [CONTRIBUTING.md](../CONTRIBUTING.md).

---

[← Previous](Roadmap.md)

[Back to README](../README.md)
