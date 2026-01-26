
# Contributing to Salesforce Files Downloader Tool

Thank you for your interest in contributing to this project!
We welcome bug reports, feature requests, documentation improvements, and code contributions.

Please read this guide before submitting any contributions.

---

## Getting Started

### 1. Fork the Repository

- Click the **Fork** button on GitHub
- Clone your fork locally:

```bash
git clone https://github.com/your-username/salesforce-files-downloader-tool.git
cd salesforce-files-downloader-tool
````

---

### 2. Set Up the Environment

Make sure you have the following installed:

* Python 3.10+
* Robot Framework
* Salesforce CLI

Install dependencies:

```bash
pip install -r requirements.txt
```

Configure Salesforce org authentication:

```bash
sf org login web
```

---

## Running Tests

Before submitting changes, ensure all tests pass:

```bash
robot tests/
```

For parallel execution:

```bash
pabot --pabotlib tests/
```

---

## How to Contribute

### Reporting Bugs

If you find a bug:

1. Check existing issues first
2. Create a new issue with:

   * Clear description
   * Steps to reproduce
   * Logs/screenshots
   * Environment details

---

### Suggesting Enhancements

We welcome feature ideas! Open an issue with:

* Problem statement
* Proposed solution
* Use cases

---

## Submitting Code Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Examples:

* `feature/download-timeout`
* `feature/batch-retry`
* `feature/update-readme`

---

### 2. Make Your Changes

* Follow existing coding patterns
* Keep commits focused
* Add comments where needed
* Update documentation if required

---

### 3. Commit Guidelines

Use meaningful commit messages:

```bash
git commit -m "Fix: Handle invalid ContentDocumentId"
```

Format:

```
Type: Short description

Examples:
Fix: ...
Feat: ...
Docs: ...
Refactor: ...
```

---

### 4. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then open a Pull Request on GitHub.

Your PR should include:

* Description of changes
* Related issue number (if any)
* Testing details

---

## Code Style Guidelines

### Robot Framework

* Use descriptive keyword names
* Keep keywords reusable
* Avoid hardcoded paths
* Use variables wherever possible

Example:

```robot
Download Salesforce File
    [Arguments]    ${content_id}
    Log    Downloading ${content_id}
```
---

## Security

Never commit:

* Access tokens
* Passwords
* `org_info.json` with secrets

Guidelines:

* Use `.gitignore` for sensitive files
* Report vulnerabilities privately

---

## Documentation

If your change impacts usage:

* Update `README.md`
* Add examples
* Update comments

Good documentation is highly valued!

---

## Community Guidelines

Please be respectful and constructive.

We follow these principles:

* Be professional
* Be inclusive
* Be helpful
* Accept feedback gracefully

---

## Contact

For major changes or discussions, please open an issue first.

Maintainer: **Bhimeswara Vamsi Punnam**

---

###   Thank you for contributing!

---
