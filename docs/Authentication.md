# Authentication

The downloader uses Salesforce CLI to sign in, then creates a local session file for REST metadata requests and an authenticated Chrome download session. Salesforce CLI is the `sf` command-line application installed in [Installation](Installation.md).

## 1. Log in and assign an org alias

An **org alias** is a short name stored by Salesforce CLI for an authenticated org. Choose a name that makes the source clear; this guide uses `source-org`.

```bash
sf org login web --alias source-org
```

The command opens a browser. Sign in as the Salesforce user who will run the extraction, then return to the terminal.

If the org requires a specific login or My Domain URL, add `--instance-url <login-url>`. See the Salesforce CLI reference for [`sf org login web`](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_org_login_web.html).

On Windows, replace `sf` with `sf.cmd` if PowerShell blocks `sf.ps1`.

## 2. Verify the alias and org

```bash
sf org display --target-org source-org --json
```

Check that the JSON result has status `0` and names the intended username, org ID, and instance URL. Stop if it points to the wrong org.

Current Salesforce CLI versions can hide the access token in this output. Do not redirect `sf org display` into `org_info.json`.

## 3. Create the downloader session file

From the repository root, run:

```bash
robot --variable ORG_ALIAS:source-org --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

The task combines the org details with a token obtained through Salesforce CLI, validates the result, and safely writes `org_info.json` in the repository root. It prints only:

```text
Generated a validated org_info.json for alias 'source-org'.
```

If either CLI call fails, the task does not replace an existing valid file.

## Required Salesforce access

The authenticated user must be allowed to:

- use the Salesforce API for the limits and metadata requests made by the tool;
- read each requested `ContentDocument` and the metadata fields queried by the downloader;
- see the relevant `ContentDocumentLink` records when link-workbook generation is enabled; and
- download each requested file through Salesforce.

Salesforce profiles, permission sets, sharing rules, and file visibility vary by org, so this repository cannot prescribe one permission set. Before a large run, test a small set of IDs with the same user and confirm that the user can open those files in Salesforce.

## Session lifetime and safety

`org_info.json` contains an access token plus the instance URL, API version, org ID, and alias used by the workers. It is excluded by `.gitignore`, but it must never be committed, printed, attached to an issue, or shared.

The downloader cannot refresh an expired REST or browser session. If a run reports `AUTH_SESSION_EXPIRED`:

1. Run `sf org display --target-org source-org --json`.
2. If the alias is no longer authorized, run `sf org login web --alias source-org` again.
3. Rerun the Robot authentication task to replace `org_info.json`.
4. Rerun the affected IDs; any partial binary download starts from the beginning.

Parallel workers share `org_info.json`. Keep it until the entire Robot or Pabot run has finished, then delete it according to your local security process.

[Back to README](../README.md)
