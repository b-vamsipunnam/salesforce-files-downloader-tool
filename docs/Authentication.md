# Authentication

Complete the Node.js and Salesforce CLI compatibility checks in [Installation](Installation.md) before authenticating. On Windows, use `sf.cmd`; on Linux and macOS, use `sf`.

Authenticate through Salesforce CLI and assign an alias:

```powershell
sf.cmd org login web --alias <org_alias>
```

Verify that the authenticated alias returns JSON successfully before generating credentials or starting Robot:

```powershell
sf.cmd org display --target-org <org_alias> --json
```

The downloader retrieves `DailyApiRequests` through its authenticated REST session during each non-empty batch, so `sf org list limits` is not a required authentication step.

Generate `org_info.json` in the repository root just before a run. Current Salesforce CLI versions omit the real `result.accessToken` from `sf org display`, so do not redirect that command to `org_info.json`.

Use the Robot authentication task. It reads non-secret metadata with `org display`, gets the token with `org auth show-access-token`, validates both responses, and replaces `org_info.json` atomically. Disable Robot result files for this task so it does not create authentication reports:

```powershell
robot --variable ORG_ALIAS:<org_alias> --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

The task prints only this non-secret confirmation:

```text
Generated a validated org_info.json for alias '<org_alias>'.
```

Do not pipe a failing or redacted `sf org display` command into `org_info.json`: output redirection can replace a previously valid file with an empty or unusable one. The generator writes a temporary file first and preserves the existing file if either CLI command or validation fails.

`org_info.json` provides the instance URL, access token, API version, org ID, and authenticated alias used during execution. Pabot workers read this context directly instead of running concurrent `sf org display` commands.

> **Security:** `org_info.json` contains an access token. It is excluded by `.gitignore`; never commit, publish, attach, print, or include it in logs. The Robot task captures the CLI output internally and does not return or print the token. Regenerate the file whenever the Salesforce session expires or a new access token is required. Prefer a dedicated user with only the permissions required for the migration.

The downloader does not remove `org_info.json` during suite teardown because parallel workers share it. Delete it manually only after the complete Robot or Pabot execution has finished.

Salesforce CLI handles authentication. The downloader does not store Salesforce usernames or passwords or refresh expired sessions during execution.

Access tokens are short-lived, and their lifetime depends on your Salesforce organization's session timeout settings. If authentication fails because the session has expired, regenerate `org_info.json` before rerunning the downloader.

---

[← Previous](Installation.md) | [Next →](Configuration.md)

[Back to README](../README.md)
