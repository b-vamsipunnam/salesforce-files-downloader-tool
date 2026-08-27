# Troubleshooting

Start with the batch's failed-ID workbook and manifest, then open `results/log.html`. The output layout is described in [Usage](Usage.md#review-the-results). Pabot worker errors can also appear under `results/pabot_results/`.

These files can contain Salesforce IDs, metadata, filenames, and local paths. Remove customer data before sharing them. Never share `org_info.json` or an access token.

## `sf` is not found

**Symptoms:** The shell does not recognize `sf`, or authentication says Salesforce CLI is missing.

**Likely cause:** Salesforce CLI is not installed, or its executable is not on `PATH`.

**Check:**

```bash
sf --version
```

On Windows, also try:

```powershell
sf.cmd --version
where.exe sf
```

**Fix:** Install or repair Salesforce CLI using [Installation](Installation.md), reopen the terminal, and repeat the version check. If `sf.cmd` works but `sf` does not, use `sf.cmd` in PowerShell.

## Every Salesforce CLI command fails with a JavaScript syntax error

**Symptoms:** Even `sf --version` fails with a Node.js parsing message such as `Invalid regular expression flags`.

**Likely cause:** An npm-installed Salesforce CLI is running on a Node.js version outside the package's supported engine range, or `PATH` points to an older runtime.

**Check:**

```bash
node --version
npm view @salesforce/cli@latest engines --json
```

On Windows, use `where.exe node`, `where.exe npm`, and `where.exe sf` to find conflicting installations.

**Fix:** Use the official Salesforce CLI installer, or activate a Node.js version allowed by the displayed engine range and reinstall `@salesforce/cli`. Reopen the terminal and confirm `sf --version` before retrying authentication.

## The input ID is invalid

**Symptoms:** The failed-ID workbook reports `INVALID_CONTENT_DOCUMENT_ID`.

**Likely cause:** The value is not a 15- or 18-character Salesforce `ContentDocumentId` beginning with `069`. A `ContentVersion` ID begins with `068` and is not accepted as input.

**Check:** Remove spaces and verify the value exported from `ContentDocument.Id`.

**Fix:** Replace the value with the correct `ContentDocumentId`. Automatic retry does not change or repair an invalid ID.

## The org alias is missing, stale, or points to the wrong org

**Symptoms:** `sf org display` fails, the authentication task fails, or the returned username, org ID, or instance URL is not the intended source.

**Likely cause:** The alias is misspelled, was reassigned, belongs to another local CLI setup, or is no longer authorized.

**Check:**

```bash
sf org display --target-org source-org --json
```

Inspect `result.username`, `result.id`, and `result.instanceUrl`. On Windows, use `sf.cmd` if needed.

**Fix:** Log in with the intended alias and then regenerate the session file:

```bash
sf org login web --alias source-org
robot --variable ORG_ALIAS:source-org --output NONE --log NONE --report NONE src/robot/orchestrators/authenticate.robot
```

## `org_info.json` has an empty or redacted token

**Symptoms:** CLI org display works, but the downloader rejects `org_info.json` or REST/browser authentication fails immediately.

**Likely cause:** `sf org display --json` was redirected into the file. Current CLI output can intentionally redact its token.

**Check:** Open only enough of `org_info.json` locally to confirm whether `result.accessToken` is absent, empty, or starts with `[REDACTED]`. Do not print the value or attach the file.

**Fix:** Run `sf org display --target-org source-org --json` without redirection. If it succeeds, use the Robot authentication command above to replace `org_info.json` safely.

## The Salesforce session expired

**Symptoms:** The manifest or failed-ID workbook reports `AUTH_SESSION_EXPIRED`; REST returns an invalid-session response; Chrome redirects to a Salesforce login page; or Salesforce returns HTML instead of the requested file.

**Likely cause:** The access token was revoked or expired under the org's session policy.

**Check:**

```bash
sf org display --target-org source-org --json
```

**Fix:** Re-authenticate the alias if that check fails, regenerate `org_info.json`, and rerun the affected IDs. The current batch cannot refresh either its REST or browser session, and automatic download retry cannot recover it.

## File or link metadata is missing

**Symptoms:** A failure reports `CONTENT_DOCUMENT_NOT_FOUND` or `CONTENT_DOCUMENT_LINK_NOT_FOUND`.

**Likely cause:** The record does not exist, the authenticated user cannot see it, no visible link was returned, or the relationship changed during the run.

**Check:** Sign in to Salesforce as the same user and try to open the file and its linked record. Confirm that the ID is a `ContentDocumentId`, not a version ID. If link output is enabled, confirm that at least one required link is visible to that user.

**Fix:** Correct the ID or grant the appropriate source-org access through your Salesforce administrator. Disable `ContentDocumentLink` workbook generation only when relationship export is intentionally outside the job. Missing metadata is not retried automatically.

## The API-capacity check stops the batch

**Symptoms:** The log reports insufficient Salesforce API capacity. The artifact directory and manifest exist, but migration workbooks and the download directory might not have been created.

**Likely cause:** Remaining `DailyApiRequests` cannot cover the estimated metadata calls, safety buffer, and required reserve.

**Check:** Read the logged values for remaining requests, estimated tool requests, safety buffer, and minimum reserve. The estimate is a lower bound because SOQL pagination cannot be predicted from workbook row count.

**Fix:** Reduce the input batch, wait for API capacity to reset, or agree on different buffer and reserve values with the owners of other integrations. Parallel workers check separately and do not reserve capacity for each other. Do not disable the check unless API use is controlled by another documented process.

## Chrome does not start

**Symptoms:** Browser creation fails with a driver, session, policy, or startup error.

**Likely cause:** Chrome is unavailable or outdated, Selenium Manager cannot resolve a driver, or proxy, endpoint-security, filesystem, or headless-browser policy blocks startup.

**Check:** Start Chrome manually in the same environment. Review the first Selenium error in `results/log.html` and check whether the machine can reach the resources required by Selenium Manager.

**Fix:** Update or repair Chrome, allow the required browser/driver process through the local policy, and retry a small batch. Do not install an arbitrary ChromeDriver version; the project uses Selenium Manager.

## A browser download does not appear or finish

**Symptoms:** The failure code is `DOWNLOAD_NAVIGATION_FAILED`, `DOWNLOAD_APPEAR_TIMEOUT`, or `DOWNLOAD_COMPLETION_TIMEOUT`; a `.crdownload`, `.tmp`, or `.part` file remains.

**Likely cause:** File access is denied, the session is no longer valid, Salesforce or the network did not deliver the file, disk space is exhausted, or Chrome download policy blocked it.

**Check:**

- Confirm the same Salesforce user can open and download that file interactively.
- Check for `AUTH_SESSION_EXPIRED` elsewhere in the batch.
- Check free disk space and Chrome automatic-download policy.
- Inspect the manifest attempt and the matching section of `results/log.html`.

**Fix:** Correct authentication, permissions, network, disk, or browser policy first. Increase the configured download timeout only when a valid transfer is simply slower than the current bound. Every retry starts a new download.

## File-size or final validation fails

**Symptoms:** The failure code is `CONTENT_SIZE_MISMATCH`, `FILE_NOT_STABLE`, `MULTIPLE_FILES_NO_SIZE_MATCH`, or `FINAL_FILE_VALIDATION_FAILED`.

**Likely cause:** The transfer is incomplete, source metadata changed during processing, more than one unexpected file appeared, or a local filesystem operation failed.

**Check:** Compare the expected and actual sizes in the log, confirm the source file did not change, and inspect disk and network errors.

**Fix:** Treat the file as failed. Remove no validated output manually during an active run; let the batch cleanup finish. Correct the underlying issue and rerun the ID from the beginning. Never count a mismatched or missing file as successful.

## An Excel workbook is locked or a transaction fails

**Symptoms:** An input workbook cannot be read, an output workbook cannot be saved, or the failure code is `WORKBOOK_TRANSACTION_FAILED`.

**Likely cause:** Excel or another process has the file open, antivirus or indexing holds a lock, the output path is not writable, or a staged workbook replacement failed.

**Check:** Close all input and output workbooks, confirm the output directory is writable, and read the complete transaction error in `results/log.html`.

**Fix:** Release the lock or correct the filesystem permission, then rerun the failed ID. If the log names a `*_rollback_recovery_*.xlsx` file, preserve it. The repository cannot decide automatically whether that recovery copy or the target workbook is authoritative; compare them before restoring or rerunning.

When a requested workbook commit fails, the downloader attempts to remove the moved binary and its per-ID directory. That cleanup is intentional: the file must not remain as a false success without its migration rows.

## A failed-ID workbook was not created

**Symptoms:** Robot reports a failed batch, but no `*_FAILED_IDs.xlsx` file is present.

**Likely cause:** Processing failed before IDs were loaded, or the failure report itself could not be written because of a lock, disk, or permission error.

**Check:** Read `results/log.html` for `Failed-ID report could not be created`, then inspect the batch manifest and original input workbook.

**Fix:** Correct the input or output problem. Use explicit `DOCUMENT_SUCCEEDED` manifest events to separate committed successes from IDs that need review; do not assume that the absence of a failure workbook means success.

## Parallel workers overlap, stall, or fail capacity checks

**Symptoms:** The same file is downloaded more than once, workers appear idle, or workers fail independently before download work begins.

**Likely cause:** Input workbooks overlap, one batch is much larger, machine resources are exhausted, or independent API checks see insufficient capacity.

**Check:** Compare the first columns of all active input workbooks. Review the combined Robot report and files such as `results/pabot_results/*/robot_stderr.out`.

**Fix:** Remove overlapping IDs, rebalance the workbooks, reduce `--processes`, and leave more API safety capacity. Keep UUID-based output paths and do not remove the shared `org_info.json` until all workers finish.

## Local storage is full

**Symptoms:** Downloads remain partial, file moves fail, or workbooks and reports cannot be saved.

**Likely cause:** The volume lacks room for the completed binaries, active browser temporary files, migration workbooks, manifests, and reports.

**Check:** Compare available disk space with the expected source data plus temporary working space.

**Fix:** Free space or point the configured output roots to a larger writable volume. The tool retains old run directories and does not remove them automatically.

For failures in contributor-only checks, use the validation commands in [CONTRIBUTING.md](../CONTRIBUTING.md).

[Back to README](../README.md)
