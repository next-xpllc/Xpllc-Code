# security-audit

when_to_use: |
  User asks about security, vulnerabilities, CVEs, auth, crypto, secrets,
  injection, XSS, CSRF, SSRF, or mentions a penetration test / compliance
  deadline (SOC2, HIPAA, ISO27001).

## Scope check before starting

Ask the user:
1. Is this a **pre-deploy review** (small diff) or a **codebase audit** (full repo)?
2. What's the **threat model** — public internet? internal-only? multi-tenant?
3. Are there **compliance obligations** that constrain the fix (e.g. can't log PII at all)?

If the user can't answer #2, push back before producing a report. A security
review without a threat model is just a linter run with scarier language.

## Procedure

1. **Automated sweep first** (cheap, high-signal):
   ```bash
   bash ~/.config/xpllc-code/scripts/linux_tools.sh deps_audit
   ```
   - npm: `npm audit --omit=dev`
   - Python: `pip-audit`
   - Rust: `cargo audit`
   - Container: `trivy image <img>` or `grype`
   - Secrets: `gitleaks detect --source .`

2. **Manual review — OWASP Top 10 checklist**
   For each item, grep the codebase and record findings:

   - **A01 Broken Access Control** — every authed endpoint: does it check
     *ownership* of the resource, not just that the user is logged in?
   - **A02 Cryptographic Failures** — search for `md5`, `sha1`, `DES`,
     hardcoded IVs, hardcoded secrets, `Math.random()` used for tokens.
   - **A03 Injection** — every string interpolation into SQL/shell/HTML/LDAP.
     `rg -n '(query|exec|execSync)\(.*\+.*\)'` is a good starting point.
   - **A04 Insecure Design** — missing rate limits on auth endpoints, password
     reset that reveals account existence, enumerable IDs in URLs.
   - **A05 Security Misconfiguration** — `DEBUG=True` in prod, directory listing
     enabled, default creds committed, CORS `*` with `credentials: true`.
   - **A06 Vulnerable Components** — output of step 1.
   - **A07 Auth / Session** — JWTs with `alg: none` accepted, password stored
     unhashed or with fast hash (use argon2id / bcrypt), session cookies
     without `HttpOnly`, `Secure`, `SameSite`.
   - **A08 Software/Data Integrity** — unpinned dependencies, CI running
     untrusted code, deserializing untrusted input (`pickle.load`, Java
     `ObjectInputStream`, `YAML.load` non-safe).
   - **A09 Logging** — PII or secrets in logs; no logging at all on auth
     failure; logs writable by the app user (tamperable).
   - **A10 SSRF** — any code that fetches a user-supplied URL without
     allowlist + link-local/metadata IP blocks (169.254.169.254).

3. **Format each finding**:
   ```
   ### [SEV-{CRITICAL|HIGH|MEDIUM|LOW}] <one-line title>
   **OWASP category:** A0X
   **File:** `path/to/file:LINE`
   **Description:** <what an attacker can do>
   **Proof of concept:**
   ```bash
   curl -X POST … # concrete exploit
   ```
   **Remediation:** <minimal patch>
   ```

4. **Never** rate something CRITICAL without an attack scenario that causes
   data loss, privilege escalation, RCE, or unbounded DoS.

## Secret-handling rules (always enforced)

- Secrets live in env vars, vault, or sealed secrets — never in source.
- If you find a committed secret: **rotate first, delete second**. Deleting
  the file without rotating leaves git history exposed.
- Log statements: `logger.info({ userId })` is fine; `logger.info({ user })`
  is not (serializes password hash + reset token).

## Red flags that demand a PAUSE

If during the audit you find any of:
- Hardcoded admin password or API key in source.
- Missing auth on an endpoint that mutates data.
- SQL injection in a production codepath.

→ **Stop the audit, surface this IMMEDIATELY to the user**, before continuing.
Don't bury a critical finding on page 4 of a 20-page report.
