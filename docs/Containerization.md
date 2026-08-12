# Containerization

Docker is an optional execution method. Native Windows execution remains supported and is still the simplest choice for interactive Salesforce authentication.

## Prerequisites

- Docker Desktop or Docker Engine with Compose
- Salesforce CLI on the host
- An authenticated Salesforce org

The initial image targets Linux AMD64 because it installs Google Chrome's official Debian package.

## Authenticate and run

Authenticate on the host and generate a short-lived runtime file in the repository root:

```bash
sf org login web --alias source-org
sf org display --json --target-org source-org > org_info.json
docker compose run --rm downloader
```

In PowerShell, generate the file with:

```powershell
sf org display --json --target-org source-org | Out-File -Encoding utf8 org_info.json
docker compose run --rm downloader
```

Compose mounts `org_info.json` and `input` read-only. Downloads, migration artifacts, and Robot reports are persisted in the host's `downloads`, `artifacts`, and `results` directories. The image contains no authentication data or real workbooks.

The container does not need Salesforce CLI. It uses `org_info.json` for REST and browser authentication and checks daily API capacity through Salesforce's REST limits endpoint.

## Startup validation

The entrypoint stops before Robot Framework starts when:

- `org_info.json` is missing, malformed, or lacks required fields
- no `.xlsx` workbook is mounted under `input`
- an output directory is missing or not writable by container UID `10001`
- Chrome or Robot Framework is unavailable

An expired access token cannot be determined reliably from the file alone. The downloader reports an authentication-session failure when Salesforce rejects it; regenerate `org_info.json` and rerun.

## Chrome security and resources

The container runs Chrome as a non-root user and attempts to use Chrome's normal Linux sandbox. Sandbox availability ultimately depends on the host kernel and container runtime configuration. Compose also drops Linux capabilities and enables `no-new-privileges`, so Chrome must be able to use its unprivileged user-namespace sandbox. If a particular host cannot provide a usable Chrome sandbox, setting `CHROME_NO_SANDBOX=true` is an explicit compatibility fallback that weakens browser isolation:

```bash
CHROME_NO_SANDBOX=true docker compose run --rm downloader
```

The explicit Compose override is equivalent and can be useful in scripts:

```bash
docker compose run --rm -e CHROME_NO_SANDBOX=true downloader
```

In PowerShell:

```powershell
$env:CHROME_NO_SANDBOX = "true"
docker compose run --rm downloader
Remove-Item Env:CHROME_NO_SANDBOX
```

In Command Prompt:

```cmd
set CHROME_NO_SANDBOX=true
docker compose run --rm downloader
set CHROME_NO_SANDBOX=
```

When enabled, the fallback produces a warning in the Robot Framework log. Docker's outer isolation is not a substitute for Chrome's renderer sandbox.

Compose allocates 2 GB of shared memory for Chrome. Approximate starting points are:

| Workers |        Memory |       CPU |
|--------:|--------------:|----------:|
|       1 |          2 GB | 1–2 cores |
|       2 |          4 GB |   2 cores |
|       4 |          8 GB |   4 cores |
|       8 | 16 GB or more |   8 cores |

Actual needs depend on file sizes, worker count, network behavior, and Chrome. Monitor a representative run before choosing production limits.

## Parallel execution

For PowerShell, override the default command to use Pabot:

```powershell
docker compose run --rm -e CHROME_NO_SANDBOX=true downloader pabot --processes 2 --testlevelsplit --outputdir /app/results /app/src/robot/orchestrator/download.robot
```

If the suite relies on PabotLib, use the recommended standard Docker execution command:

```powershell
docker compose run --rm -e CHROME_NO_SANDBOX=true downloader pabot --pabotlib --processes 2 --testlevelsplit --outputdir /app/results /app/src/robot/orchestrator/download.robot
```

Delete `org_info.json` from the host after the complete run when it is no longer needed.

## Acceptance testing

Run acceptance tests in increasing order of cost. Do not begin with a large migration workload.

The `container-build` CI job automatically enforces these gates:

- the image builds successfully
- Python, Robot Framework, and Chrome report their versions
- the image runs as UID `10001`
- Chrome starts without `--no-sandbox` while all capabilities are dropped and `no-new-privileges` is enabled
- `input` and `org_info.json` reject writes
- files written under `downloads`, `artifacts`, and `results` persist on the host
- no authentication file is present in the built image
- Python unit tests pass inside the image
- the complete Robot smoke suite passes inside the image

The following gates require a dedicated Salesforce test org and short-lived `org_info.json`, so they are intentionally not run for untrusted pull requests:

- a one-file authenticated download succeeds
- the downloaded byte count equals Salesforce `ContentSize`
- the JSONL manifest and migration workbooks contain the expected terminal records
- a deliberately invalid ID produces the expected structured failure without stopping valid work
- an expired test session is classified as `AUTH_SESSION_EXPIRED` without exposing its token
- a two-worker Pabot run completes with isolated output directories
- the image history and generated logs contain no access token

Use this order for an authenticated release-candidate test:

1. Complete the automated `container-build` CI job.
2. Generate a fresh `org_info.json` for a dedicated test org.
3. Place one known, small `ContentDocumentId` in `Inputfile_1.xlsx` and leave the other input workbooks empty.
4. Run `docker compose run --rm downloader`.
5. Compare the downloaded file size with its Salesforce `ContentSize` and inspect the manifest and workbooks.
6. Add one invalid ID and confirm its structured failure result.
7. Regenerate credentials, deliberately expire the older session, and verify the session-expiry classification with the old file.
8. Search `results`, `artifacts`, and `docker history --no-trunc salesforce-files-downloader:test` for the exact access token; the search must return no matches.
9. Regenerate credentials again, prepare two small batches, and run the recommended standard command:

   ```powershell
   docker compose run --rm -e CHROME_NO_SANDBOX=true downloader pabot --pabotlib --processes 2 --testlevelsplit --outputdir /app/results /app/src/robot/orchestrator/download.robot
   ```

Record the image ID, Chrome version, test-org username, document IDs, expected sizes, and resulting manifest paths with the release evidence. Never record the access token itself.
