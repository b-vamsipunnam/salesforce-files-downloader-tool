# Contributing

Bug reports, documentation fixes, tests, and focused code changes are welcome. Keep each contribution limited to one clear problem.

Report vulnerabilities privately through [SECURITY.md](SECURITY.md). Follow the [Code of Conduct](CODE_OF_CONDUCT.md) in all project interactions.

## Development setup

For a substantial behavior or architecture change, open an issue before implementation so the approach can be discussed.

Fork the repository, clone your fork, and create a virtual environment:

```bash
git clone https://github.com/your-username/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
python -m venv venv
```

Activate the environment as described in [Installation](docs/Installation.md), then install runtime and development dependencies:

```bash
python -m pip install -r requirements.txt
python -m pip install -r requirements-dev.txt
python -m pip check
```

Python 3.10 or later is required. Authenticated end-to-end runs also require Chrome, Salesforce CLI, source-org access, and the session setup in [Authentication](docs/Authentication.md). Offline unit and smoke checks do not require Salesforce credentials.

Create a focused branch:

```bash
git checkout -b fix/download-timeout
```

## Validation

Run the same static analysis and offline tests used by the repository:

```bash
ruff check src ci
robocop check src ci
python -m unittest discover -s ci/tests -v
robot --outputdir results/smoke ci/robot/smoke.robot
```

Ruff checks Python. Robocop checks Robot Framework files using `robocop.toml`. The unit and smoke tests use local fixtures and mocked Salesforce responses; they must not require an access token or customer files.

If a change affects authentication, metadata requests, Chrome downloads, workbook output, retries, or worker isolation, also run the smallest relevant authenticated batch in a suitable test org:

```bash
robot --test Download_Batch_1 --outputdir results src/robot/orchestrators/download.robot
```

For parallel behavior, use non-sensitive, non-overlapping inputs:

```bash
pabot --testlevelsplit --processes 2 --outputdir results src/robot/orchestrators/download.robot
```

Review generated workbooks, manifests, `output.xml`, `log.html`, and `report.html` before sharing them. Remove Salesforce tokens, org details, record IDs, filenames, and other customer data.

## Change guidelines

For Robot Framework and Python changes:

- Keep reusable behavior in resource files or Python libraries.
- Use descriptive keyword names and explicit arguments.
- Avoid hard-coded local paths and sensitive logging.
- Preserve per-worker output isolation.
- Preserve the rule that a file is successful only after validation and any requested workbook commit.
- Keep test seams for mocked CLI and REST responses from weakening production defaults.
- Update [Keyword documentation](docs/Keyword-Documentation.md) when a public keyword contract changes.

For documentation changes:

- Use short, direct explanations and copy-paste-ready commands.
- Verify commands, paths, settings, and output names against the implementation.
- Put each explanation on its canonical page and link to it elsewhere.
- Do not present roadmap work as current behavior.

## Open a pull request

Use a concise commit subject, for example:

```bash
git commit -m "fix: handle invalid ContentDocumentId"
```

Push the branch to your fork:

```bash
git push origin fix/download-timeout
```

The pull request should state:

- the problem and the change;
- the related issue, if any;
- the validation commands and results; and
- any compatibility, security, performance, migration, or documentation impact.

All required CI checks must pass. Maintainers may request revisions before merge.

## Report a bug

Search existing issues first. Include a minimal reproduction, expected and actual behavior, relevant version information, and sanitized diagnostics. A small synthetic input is preferable to customer data.

For an enhancement, describe the problem, a representative use case, the proposed behavior, and important compatibility or migration constraints.
