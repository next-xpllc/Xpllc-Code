# dependency-audit

when_to_use: |
  User asks about outdated packages, licenses, supply-chain risk,
  "update dependencies", "why is npm install so slow", or mentions Dependabot.

## Goals

1. Know what we depend on and why.
2. Know which deps have known CVEs.
3. Know which deps are abandoned / maintained by a single weekend hobbyist.
4. Upgrade the ones that matter, pin the ones that don't.

## Procedure

1. **Inventory**
   ```bash
   # JS/TS
   npm list --all --depth=0
   # Python
   pip list --format=columns
   # Rust
   cargo tree --depth 1
   # Go
   go list -m all
   ```

2. **Vulnerability scan**
   ```bash
   bash ~/.config/xpllc-code/scripts/linux_tools.sh deps_audit
   ```

3. **Outdated check** (needs triage, not blind `npm update`):
   ```bash
   npm outdated
   pip list --outdated
   cargo outdated
   ```

   For each outdated dep ask:
   - Is there a CVE in the installed version? → **must upgrade**.
   - Major version bump? → read the CHANGELOG, estimate migration effort,
     open a ticket; don't auto-merge.
   - Minor/patch with no behavior change? → batch-upgrade in one PR.

4. **License audit**
   ```bash
   # JS/TS
   npx license-checker --production --summary
   # Python
   pip-licenses --format=markdown
   ```
   Flag anything in `GPL-*`, `AGPL-*`, `SSPL`, or `BUSL` for legal review
   if the parent project is proprietary.

5. **Supply-chain health** — for any dep in the top-20 transitive list, check:
   - **Last release date** — >18 months → at-risk / abandoned.
   - **Maintainers** — single maintainer → bus-factor of 1.
   - **Download count vs. star count** — 10M downloads, 50 stars = reconsider
     (often a typosquat or a zero-effort re-export).
   - **Install scripts** — `postinstall` / `preinstall` hooks should be
     reviewed manually. Known vector for supply-chain attacks.

6. **Report format**
   ```
   ## Dependency Audit

   ### Must-upgrade (has CVE)
   - lodash 4.17.20 → 4.17.21 (CVE-2021-23337, cmd injection in template)

   ### Should-upgrade (outdated + active maintenance)
   - express 4.18 → 5.0 (see migration guide: ...)

   ### Consider removing
   - `left-pad` — unused (grep found 0 imports)
   - `moment` — maintenance mode; migrate to `dayjs` or `date-fns`

   ### License concerns
   - `<pkg>` is GPL-3.0 — incompatible with closed-source distribution.

   ### Supply-chain risk
   - `<pkg>` last published 3 years ago, single maintainer, 2M weekly dl.
     Recommend vendoring or seeking an alternative.
   ```

## Lockfile discipline

- Always commit the lockfile (`package-lock.json`, `poetry.lock`, `Cargo.lock`, `go.sum`).
- `npm ci` in CI, never `npm install` — the former respects the lockfile, the latter can change it.
- Dependabot / Renovate: enable, but gate on green tests. Auto-merging security
  patches is fine; auto-merging major version bumps is reckless.

## Never

- Add a dependency to do something trivial the stdlib already does.
- Upgrade "because it's old" without reading the changelog.
- Pin a dep to `latest` — that's not pinning.
