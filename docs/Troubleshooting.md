# Troubleshooting

Start with the batch JSONL execution manifest and structured failed-ID workbook under `artifacts/`, then use `results/log.html` and `results/pabot_results/` for detailed execution context. Never publish manifests, `org_info.json`, tokens, customer data, or sensitive filenames.

## Salesforce CLI not found

**Symptoms**

The suite reports that `sf` is missing or the shell does not recognize the command.

**Likely cause**

Salesforce CLI is not installed or its executable is absent from `PATH`.

**Resolution**

Install Salesforce CLI, restart the shell if needed, and confirm `sf --version` succeeds.

## Invalid org alias

**Symptoms**

The API-capacity lookup reports that the alias is not authenticated or accessible, or later Salesforce requests fail authentication.

**Likely cause**

The alias is misspelled, belongs to another CLI environment, or its authorization is no longer valid.

**Resolution**

Run `sf org login web --alias <org_alias>`, verify `sf org display --target-org <org_alias>`, and regenerate `org_info.json`.

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

When failed-ID retry is enabled, the downloader attempts an eligible ID again after the primary pass. Repeated `RETRY FAILED` messages usually indicate that the problem is not a brief browser delay and needs investigation.

## Insufficient Salesforce API capacity

**Symptoms**

The batch stops before creating download or artifact directories and reports the remaining, estimated, buffered, and reserved API request counts.

**Likely cause**

The org's `DailyApiRequests` allocation cannot accommodate the estimated metadata calls while retaining the configured safety buffer and minimum reserve.

**Resolution**

Reduce the input batch, wait for API capacity to reset, or review `${API_REQUEST_SAFETY_BUFFER}` and `${MINIMUM_API_REQUESTS_REMAINING}` with the owners of other org integrations. Do not disable the check unless API consumption is managed externally. Parallel Pabot workers do not share a reservation counter, so use additional buffer when their combined demand approaches the limit.

The limits lookup automatically retries transient CLI failures using `${API_LIMIT_LOOKUP_MAX_ATTEMPTS}` and `${API_LIMIT_LOOKUP_RETRY_DELAY}`. Investigate Salesforce CLI authentication and local process behavior if every attempt fails.

The console intentionally says `Minimum Estimated Metadata Requests`. SOQL pagination depends on Salesforce response volume and cannot be predicted from the number of input IDs alone. If a batch has unusually high relationship volume, increase `${API_REQUEST_SAFETY_BUFFER}` rather than treating the estimate as an exact forecast.

## Salesforce org identity mismatch

**Symptoms**

The alias, org ID, username, or instance URL in `org_info.json` does not match the intended source org.

**Likely cause**

The alias was reassigned, the authentication file is stale, or multiple local aliases were confused. Different aliases are safe when they resolve to the same Salesforce org ID.

**Resolution**

Before starting Robot or Pabot, compare `result.id`, `result.username`, and `result.instanceUrl` from `sf org display --target-org <alias> --json`. Regenerate `org_info.json` from the intended org before rerunning the downloader. Worker setup deliberately does not repeat this CLI call because concurrent `sf org display` processes can contend for shared Salesforce CLI state.

## Temporary download never completes

**Symptoms**

A `.crdownload`, `.tmp`, or `.part` file remains until the completion timeout.

**Likely cause**

The transfer stalled, local storage is full, or browser/network activity was interrupted.

**Resolution**

Check network stability and free disk space, remove abandoned temporary output after the run, and retry the failed ID.

The automatic retry starts a fresh download; it does not continue the abandoned temporary file.

## Automatic retries do not recover an ID

**Symptoms**

The log shows `PERMANENT FAILURE`, or an ID appears in the failed-ID workbook after multiple attempts.

**Likely cause**

The underlying issue lasted through every attempt, or the ID was not retryable because it was invalid or lacked required metadata. An expired Salesforce session also remains expired because the retry pass uses the existing session.

**Resolution**

Use the failure reason in `log.html` to address access, authentication, network, browser, disk, or metadata problems. Regenerate `org_info.json` when the session has expired, then rerun the remaining IDs. Increase retry counts or delays only when failures are genuinely temporary; extra attempts cannot correct invalid IDs or missing permissions.

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

Migration workbook updates are staged and committed together. If the log reports an incomplete rollback, preserve the named `*_rollback_recovery_*.xlsx` file and use it to restore the affected workbook before rerunning the ID.

If a workbook transaction fails after the binary has moved, the downloader removes that binary and the per-ID directory before recording the failure. This cleanup is intentional: keeping a final binary without its migration rows would make the next run ambiguous. Use the failed-ID workbook to rerun the document after the workbook problem is resolved.

## Insufficient disk space

**Symptoms**

Downloads stop, files remain incomplete, or workbook/report writes fail.

**Likely cause**

The local volume lacks space for binaries, temporary browser files, and runtime output.

**Resolution**

Free space or move the configured output roots to a larger volume. Allow capacity above the expected source size for temporary files and reports.

## Pabot worker collision

**Symptoms**

Multiple workers process the same ContentDocumentId, shared runtime files disappear unexpectedly, or parallel workers report invalid Salesforce CLI JSON while sequential execution succeeds.

**Likely cause**

Input workbooks overlap, custom output paths are shared, a custom worker teardown removes `org_info.json` before all workers finish, or an older project version runs Salesforce CLI commands concurrently without a cross-process lock.

**Resolution**

Use non-overlapping input batches, retain UUID-based output paths, include `--pabotlib` in the Pabot command, and remove the shared authentication file only after the complete Pabot run. Current worker setup reads org context directly from `org_info.json`, and the limits lookup uses a PabotLib lock.

## GitHub Actions smoke-test failure

**Symptoms**

The CI smoke workflow fails even though no Salesforce connection is expected.

**Likely cause**

A dependency, Robot resource import, headless Chrome startup, SeleniumLibrary integration, or custom Excel operation regressed.

**Resolution**

Install both runtime and development dependencies, then reproduce the same checks locally:

```bash
python -m pip install -r requirements.txt
python -m pip install -r requirements-dev.txt
ruff check src ci
robocop check src ci
python -m unittest discover -s ci/tests -v
robot --outputdir results/smoke ci/robot/smoke.robot
```

The smoke suite uses mocked Salesforce responses for API-capacity, retry, pagination, metadata, and ID-validation scenarios. It does not require org credentials or download customer files.

---

[← Previous](Keyword-Documentation.md) | [Next →](FAQ.md)

[Back to README](../README.md)
