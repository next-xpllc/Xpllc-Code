# code-review

when_to_use: |
  The user says "review this", "look at my diff/PR/code", asks for a second
  opinion on an implementation, or pastes code and asks what can be improved.

## Success criteria

- Every substantive finding is tied to a specific file + line range.
- Findings are categorized: CORRECTNESS, SECURITY, PERFORMANCE, STYLE, TESTS.
- CORRECTNESS and SECURITY issues are called out first and loudly.
- Style/nits are grouped at the end and marked as optional.

## Procedure

1. **Collect context**
   - If user points at a PR or branch: `git fetch && git log --oneline origin/main..HEAD`
   - If user points at files: read them end-to-end; don't skim the middle.
   - Read `CLAUDE.md`, `CONTRIBUTING.md`, `.editorconfig` to learn house style.

2. **Static sweep** (run all that apply):
   - JS/TS: `npx tsc --noEmit` + `npm run lint` (or `npx eslint .`)
   - Python: `ruff check . && mypy .` (skip mypy if project lacks config)
   - Rust: `cargo clippy --workspace --all-targets -- -D warnings`
   - Go: `go vet ./... && golangci-lint run`
   - Shell: `shellcheck <file>`

3. **Produce the review** — ONE markdown document with sections in this order:
   ```
   ## Blocking
   ## Correctness
   ## Security
   ## Performance
   ## Tests & coverage
   ## Style (optional)
   ## Things I liked
   ```

4. **Each finding follows this template**:
   ```
   ### [CATEGORY] <one-line title>
   **File:** `path/to/file.ts:LINE-LINE`
   **Issue:** What is wrong.
   **Why it matters:** Concrete failure mode (crash, wrong answer, leak…).
   **Suggested fix:**
   ```diff
   - old line
   + new line
   ```
   ```

5. **Never** just say "consider refactoring this" without a concrete proposal.
6. **Never** pad the review with generic advice. If there are no security
   issues, write "None found." — don't invent concerns.

## Anti-patterns to flag automatically

- `catch` blocks that swallow errors silently.
- Logging of secrets (keys, tokens, PII) — even at debug level.
- `any` in TypeScript public APIs; `unwrap()`/`expect()` in Rust library code.
- Blocking I/O on the async event loop.
- Mutable global state without an explicit synchronization story.
- Missing cleanup on error paths (file handles, DB transactions, locks).
- Off-by-one errors in loops over `len-1`.
- String concatenation building SQL / shell / HTML without escaping.

## Output length rule

Keep each finding ≤ 8 lines of prose. The diff is the proof; don't over-explain.
