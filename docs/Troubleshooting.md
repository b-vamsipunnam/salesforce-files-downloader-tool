# Troubleshooting

Start with `results/log.html`, the batch-specific failed-ID workbook under `artifacts/`, and `results/pabot_results/` for parallel runs. Never publish `org_info.json`, tokens, customer data, or sensitive filenames.

## Salesforce CLI not found

**Symptoms**

The suite reports that `sf` is missing or the shell does not recognize the command.

**Likely cause**

Salesforce CLI is not installed or its executable is absent from `PATH`.

**Resolution**

Install Salesforce CLI, restart the shell if needed, and confirm `sf --version` succeeds.

## Invalid org alias

**Symptoms**

Prerequisite validation reports that the alias is not authenticated or accessible.

**Likely cause**

The alias is misspelled, belongs to another CLI environment, or its authorization is no longer valid.

**Resolution**

Run `sf org login web --alias <org_alias>`, then verify `sf org display --target-org <org_alias>`.

## Expired Salesforce session

**Symptoms**

REST requests or frontdoor browser authentication fail after authentication previously worked.

**Likely cause**

The access token in `org_info.json` expired or was revoked.

**Resolution**

Regenerate `org_info.json` from the authenticated alias and rerun failed IDs. The tool does not refresh a token during execution.

## Chrome startup or browser compatibility issues

**Symptoms**

Chrome fails during browser creation with a driver or session compatibility error.

**Likely cause**

Chrome is outdated, browser management cannot resolve a compatible driver, or the environment restricts browser startup.

**Resolution**

Update Chrome, verify headless Chrome can run, check proxy/network restrictions affecting driver management, and review the Selenium error in `log.html`.

## Browser download does not start

**Symptoms**

No file appears before `${DOWNLOAD_APPEAR_TIMEOUT}`.

**Likely cause**

The browser session is invalid, the user lacks file access, the Shepherd request is blocked, or the network is unavailable.

**Resolution**

Refresh authentication, verify the same user can access the file, and inspect browser and Robot errors before increasing the timeout.

## Temporary download never completes

**Symptoms**

A `.crdownload`, `.tmp`, or `.part` file remains until the completion timeout.

**Likely cause**

The transfer stalled, local storage is full, or browser/network activity was interrupted.

**Resolution**

Check network stability and free disk space, remove abandoned temporary output after the run, and retry the failed ID.

## File validation failure

**Symptoms**

The downloaded size does not match `ContentSize`, the size does not stabilize, or destination verification fails.

**Likely cause**

The transfer is incomplete, source metadata changed during processing, or a filesystem operation failed.

**Resolution**

Treat the download as failed. Verify the source metadata, local storage, and network conditions before rerunning the affected ID.

## Missing ContentDocumentLink metadata

**Symptoms**

A document is marked failed because link metadata is missing when ContentDocumentLink workbook generation is enabled.

**Likely cause**

No visible link was returned, permissions hide the relationship, or the relationship changed during the run.

**Resolution**

Confirm the source record links and querying user's visibility. Disable link-workbook generation only when relationship export is intentionally unnecessary.

## Permission-related errors

**Symptoms**

Metadata queries omit records, return authorization errors, or Shepherd downloads fail for selected IDs.

**Likely cause**

The authenticated user lacks object, record, file, or linked-entity access.

**Resolution**

Review the user's Salesforce permissions and sharing visibility. Use a least-privilege migration user with access to the required source data.

## Excel file locked

**Symptoms**

Input workbooks cannot be read or output workbooks cannot be saved or moved.

**Likely cause**

The file is open in Excel, indexed by another process, or blocked by antivirus or filesystem permissions.

**Resolution**

Close the workbook, verify directory permissions, and retry after the locking process releases it.

## Insufficient disk space

**Symptoms**

Downloads stop, files remain incomplete, or workbook/report writes fail.

**Likely cause**

The local volume lacks space for binaries, temporary browser files, and runtime output.

**Resolution**

Free space or move the configured output roots to a larger volume. Allow capacity above the expected source size for temporary files and reports.

## Pabot worker collision

**Symptoms**

Multiple workers process the same ContentDocumentId, or shared runtime files disappear unexpectedly.

**Likely cause**

Input workbooks overlap, custom output paths are shared, or worker teardown removes `org_info.json` before all workers finish.

**Resolution**

Use non-overlapping input batches, retain UUID-based output paths, and remove the shared authentication file only after the complete Pabot run.

## GitHub Actions smoke-test failure

**Symptoms**

The CI smoke workflow fails even though no Salesforce connection is expected.

**Likely cause**

A dependency, Robot resource import, headless Chrome startup, SeleniumLibrary integration, or custom Excel operation regressed.

**Resolution**

Review the failing GitHub Actions step and reproduce `ci/robot/smoke.robot` locally using the pinned dependencies. The smoke test does not require org credentials or download Salesforce files.

---

[← Previous](Keyword-Documentation.md) | [Next →](FAQ.md)

[Back to README](../README.md)
