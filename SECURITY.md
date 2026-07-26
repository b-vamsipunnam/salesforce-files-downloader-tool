# Security policy

## Report a vulnerability

Do not disclose a suspected vulnerability in a public issue, discussion, social-media post, or shared log. Contact the maintainer privately through GitHub or the repository contact method. If no private channel is available, open a minimal issue asking the maintainer to contact you; do not include exploit details.

Include the following where available:

- A description of the vulnerability and its impact
- Affected versions or commits
- Minimal reproduction steps
- A proof of concept
- Suggested mitigations or fixes

The project aims to acknowledge a report within 72 hours and provide updates while it is investigated. Do not exploit the issue beyond what is necessary to demonstrate it.

## Protect credentials and data

This tool handles Salesforce access tokens, org identifiers, file metadata, and downloaded customer content. Treat its working directories and generated reports as sensitive.

- Never commit access tokens, passwords, OAuth secrets, or `org_info.json`.
- Use least-privilege Salesforce accounts and avoid production administrator credentials where possible.
- Keep `org_info.json` readable only by trusted users.
- Delete `org_info.json` only after every sequential or parallel worker has finished.
- Log out unused Salesforce sessions and rotate credentials according to your organization’s policy.
- Protect `downloads/`, `artifacts/`, and `results/` with appropriate filesystem permissions and retention rules.

Token-bearing operations are normally suppressed from Robot Framework logs. That protection does not remove the need to inspect `output.xml`, `log.html`, `report.html`, screenshots, and console output before sharing them. Unexpected failures or future regressions can expose tokens, customer IDs, filenames, or failure details.

If a token appears in a published artifact, remove the artifact where possible and revoke the Salesforce session immediately:

```bash
sf org logout --target-org <org_alias> --no-prompt
sf org login web --alias <org_alias>
```

Generate a new `org_info.json` before the next run.

## Maintain a secure environment

- Keep Python, Salesforce CLI, Chrome, ChromeDriver, and project dependencies current.
- Install packages only from trusted sources.
- Monitor dependencies for published vulnerabilities.
- Avoid processing sensitive data on public or shared machines.
- Encrypt stored files when required by organizational policy.
- Apply operating-system and endpoint-security updates.

## Disclosure and updates

After a report is verified, maintainers will assess the impact, develop and test a fix, publish an update, and disclose details when appropriate. Reporter credit is provided with permission. Security releases and advisories are published through GitHub Releases and repository documentation; a CVE may be requested for a qualifying issue.

## Warranty

This project is provided under the terms of the [MIT License](LICENSE). Users are responsible for securing their environments, credentials, downloaded data, and generated artifacts.
