# Authentication

Authenticate through Salesforce CLI and assign an alias:

```bash
sf org login web --alias <org_alias>
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

The file supplies the instance URL, access token, API version, and alias. REST requests use the token as a Bearer credential. Chrome receives the authenticated session through a Salesforce `frontdoor.jsp` URL before Shepherd downloads begin.

> **Security:** `org_info.json` contains an access token. It is excluded by `.gitignore`; never commit, publish, attach, or include it in logs. Regenerate it if the session expires. Prefer a dedicated user with only the permissions required for the migration.

Authentication is external to the downloader. The framework does not store a username or password and does not refresh an expired session during execution.

---

[← Previous](Installation.md) | [Next →](Configuration.md)

[Back to README](../README.md)
