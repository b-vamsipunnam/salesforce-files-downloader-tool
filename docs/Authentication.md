# Authentication

Authenticate through Salesforce CLI and assign an alias:

```bash
sf org login web --alias <org_alias>
```

(Optional) Verify the authenticated org:

```bash
sf org display --target-org <org_alias>
```

Generate `org_info.json` in the repository root immediately before execution.

Windows PowerShell:

```powershell
sf org display --json --target-org <org_alias> | Out-File -Encoding utf8 org_info.json
```

Linux or macOS:

```bash
sf org display --json --target-org <org_alias> > org_info.json
```

`org_info.json` provides the instance URL, access token, API version, and authenticated org alias used during execution.

> **Security:** `org_info.json` contains an access token. It is excluded by `.gitignore`; never commit, publish, attach, or include it in logs. Regenerate the file whenever the Salesforce session expires or a new access token is required. Prefer a dedicated user with only the permissions required for the migration.

Authentication is managed entirely through Salesforce CLI. The downloader never stores Salesforce usernames or passwords and does not refresh expired sessions during execution.

Access tokens are short-lived, and their lifetime depends on your Salesforce organization's session timeout settings. If authentication fails because the session has expired, regenerate `org_info.json` before rerunning the downloader.

---

[← Previous](Installation.md) | [Next →](Configuration.md)

[Back to README](../README.md)
