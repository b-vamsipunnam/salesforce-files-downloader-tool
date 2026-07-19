# Contributing

Contributions may include bug reports, feature proposals, documentation, tests, and code changes. Follow the repository [code of conduct](../CODE_OF_CONDUCT.md) and use [SECURITY.md](../SECURITY.md) for vulnerability reports.

## Before opening a change

Search existing issues. For a bug, provide reproducible steps, sanitized errors, the command used, and relevant environment versions. For a larger enhancement, describe the problem, use case, and proposed behavior before implementation.

## Development setup

Fork and clone the repository, create a virtual environment, and install dependencies as described in [Installation](Installation.md). Create a focused branch:

```bash
git checkout -b feature/short-description
```

Follow the existing Robot Framework and Python patterns. Prefer descriptive reusable keywords, variables over hard-coded paths, focused commits, and documentation updates when behavior changes.

## Verification

The main suite requires Salesforce access and valid input. Run the scope appropriate to the change and record what was tested in the pull request:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrator/download.robot
```

For parallel behavior:

```bash
pabot --pabotlib --testlevelsplit --processes 2 --outputdir results src/robot/orchestrator/download.robot
```

The GitHub Actions workflow runs an isolated smoke test for Robot Framework, headless Chrome, SeleniumLibrary, and the custom Excel library. It does not connect to Salesforce or download customer files.

## Pull requests

Keep the change focused, use a meaningful commit message, link related issues, describe user-visible behavior, and state verification results. Never commit access tokens, passwords, `org_info.json`, runtime downloads, or customer data.

The root [CONTRIBUTING.md](../CONTRIBUTING.md) remains the repository policy reference.

---

[← Previous](Roadmap.md)

[Back to README](../README.md)
