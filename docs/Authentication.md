# Authentication

Finish the compatibility checks in [Installation](Installation.md) before signing in. Use `sf.cmd` on Windows and `sf` on Linux or macOS.

Authenticate through Salesforce CLI and assign an alias:

```powershell
sf.cmd org login web --alias <org_alias>
```

Verify that the authenticated alias returns JSON successfully before generating credentials or starting Robot:

```powershell
sf.cmd org display --target-org <org_alias> --json
```

The downloader retrieves `DailyApiRequests` through its authenticated REST session during each non-empty batch, so `sf org list limits` is not a required authentication step.

Create `org_info.json` in the repository root shortly before each run. Because current Salesforce CLI versions redact the access token from `sf org display`, do not redirect that command into the file.

Instead, use the Robot authentication task below. It combines the org metadata with the token, validates both responses, and safely replaces `org_info.json`. Result files are disabled so the authentication step does not create reports:

```powershell
robot --variable ORG_ALIAS:<org_alias> --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

The task prints only this non-secret confirmation:

```text
Generated a validated org_info.json for alias '<org_alias>'.
```

The task writes to a temporary file first. If either CLI command or validation fails, the existing `org_info.json` is left untouched.

`org_info.json` provides the instance URL, access token, API version, org ID, and authenticated alias used during execution. Pabot workers read this context directly instead of running concurrent `sf org display` commands.

> **Security:** `org_info.json` contains an access token. It is excluded by `.gitignore`; never commit, publish, attach, print, or include it in logs. The Robot task captures the CLI output internally and does not return or print the token. Regenerate the file whenever the Salesforce session expires or a new access token is required. Prefer a dedicated user with only the permissions required for the migration.

The downloader does not remove `org_info.json` during suite teardown because parallel workers share it. Delete it manually only after the complete Robot or Pabot execution has finished.

Salesforce CLI handles the sign-in, so the downloader never stores a Salesforce username or password. It also cannot refresh an expired session. Token lifetime depends on the org's session settings; if authentication expires, regenerate `org_info.json` and rerun the failed IDs.

---

[← Previous](Installation.md) | [Next →](Configuration.md)

[Back to README](../README.md)
