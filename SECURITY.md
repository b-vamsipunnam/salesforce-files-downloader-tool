# Security Policy

## Reporting Security Vulnerabilities

We take the security of the Salesforce Files Downloader Tool seriously.

If you discover a security vulnerability, please report it responsibly.

### Please Do NOT

- Open a public GitHub issue
- Share the vulnerability on social media
- Exploit the vulnerability

---

## How to Report

Please report security issues by contacting the project maintainer directly.

**Maintainer:** Bhimeswara Vamsi Punnam  
**Preferred Method:** GitHub private message or repository contact

If GitHub messaging is unavailable, please open a minimal issue requesting private contact.

We aim to acknowledge reports within **72 hours** and provide regular status updates during investigation.

When reporting, please include:

- Description of the vulnerability
- Steps to reproduce
- Proof of concept (if available)
- Impact assessment
- Affected versions
- Any suggested fixes

This helps us resolve issues faster and more effectively.

---

## Security Best Practices

To help keep your environment secure:

### Credentials & Secrets

- Never commit:
  - Access tokens
  - OAuth secrets
  - Passwords
  - `org_info.json` with credentials
- Use environment variables or secure vaults
- Add sensitive files to `.gitignore`

---

### Salesforce Access

- Use least-privilege Salesforce accounts
- Avoid using production admin credentials
- Rotate tokens regularly
- Log out unused sessions

---

### Dependencies

- Keep dependencies updated
- Monitor for known vulnerabilities
- Use trusted packages only

---

### Local Environment

- Protect your local machine
- Avoid running tools on public or shared systems
- Encrypt sensitive files if needed
- Restrict access to configuration files

---

## Disclosure Policy

We follow a responsible disclosure process:

1. Receive report privately
2. Verify vulnerability
3. Develop fix
4. Release patch
5. Publicly disclose (if appropriate)

Reporters will be credited when possible (with permission).

---

## Security Updates

Security patches and advisories will be announced via:

- GitHub Releases
- Repository changelog
- Project documentation

For critical vulnerabilities, CVE identifiers may be requested when appropriate.

---

## Disclaimer

This tool is provided "as-is" without warranty.

Users are responsible for securing their own environments, credentials, and data.

---

Thank you for helping keep this project secure!
