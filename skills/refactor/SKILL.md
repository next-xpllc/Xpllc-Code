# refactor

when_to_use: |
  User asks to "clean this up", "simplify", "split this function",
  "extract a helper", "make this more readable", or "this function is too long".

## Hard rules

1. **Refactor with a safety net or don't refactor at all.** Before changing
   anything, confirm the target code has tests. If it doesn't, write
   characterization tests *first* (see the `test-generation` skill).
2. **One refactor per commit.** Never mix behavior changes with structural
   changes. Reviewers can't spot regressions in a 500-line diff.
3. **Match the existing style.** This is not the moment to introduce a new
   lint rule, a new framework, or "your" preferred pattern.

## Procedure

1. **Characterize current behavior**
   - Run existing tests: `bash ~/.config/xpllc-code/scripts/linux_tools.sh run_tests`.
   - If they're green, note the exact pass count — you'll compare later.
   - If there are no tests, stop and invoke `test-generation` skill first.

2. **Identify the target refactor** — pick exactly ONE:
   - **Extract function** — a block >15 lines with a clear single purpose.
   - **Rename** — a symbol whose current name misleads readers.
   - **Replace conditional with polymorphism** — when `if (type == X)` repeats.
   - **Inline** — a helper used in exactly one place with no added clarity.
   - **Replace magic number / string** — with a named constant.
   - **Guard clause** — flatten nested `if` into early returns.

3. **Execute**
   - Make the change.
   - Run tests again. Pass count must match exactly.
   - Run lint/typecheck. Must be clean (or at least: not newly-dirty).

4. **Write the commit**
   ```
   refactor(<area>): extract <helper> from <caller>

   No behavior change. Motivation: <caller> had 80 LOC and mixed
   input validation with domain logic. The extraction makes the
   validation unit-testable in isolation.

   Tests: 142 passed (unchanged).
   ```

## Anti-patterns to refuse

- "While I'm here, let me also fix this other thing." → Separate commit.
- "Let's rewrite this in `<trendy-framework>`." → That's a rewrite, not a refactor.
- "Let's add types everywhere." → Separate PR with a clear migration plan.

## When NOT to refactor

- The code is dead (unreferenced). Delete it; don't polish corpses.
- The module is scheduled for replacement. Leave it alone.
- The "ugliness" is actually domain-driven. Not all complexity is accidental.
