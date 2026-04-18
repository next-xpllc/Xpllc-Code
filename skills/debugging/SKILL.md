# debugging

when_to_use: |
  User reports a bug, pastes a stack trace, says "it's broken",
  "it crashes", "this doesn't work", or asks why output X happened.

## Diagnostic discipline

**Observe → Hypothesize → Test → Conclude.** Skipping any step turns debugging
into guessing. Good engineers debug; guessing wastes everyone's time.

## Procedure

1. **Reproduce it locally**
   - If you can't reproduce, you can't fix it. Get the exact command,
     input data, env vars, and OS from the user before touching code.
   - Capture the minimal reproducing case. If the bug needs 200 lines to
     trigger, shrink it first (bisect the input, bisect commits with
     `git bisect run`).

2. **Read the stack trace bottom-up**
   - Frame 0 is where the error was raised, not necessarily where it originated.
   - Look for the *first* frame inside the project's own code (ignore vendor / stdlib).
   - Note line numbers — they're data, not noise.

3. **Form ONE hypothesis at a time**
   - Write it down: "I think X is null because Y wasn't called on startup."
   - Design a test that would falsify it.
   - Run the test.
   - If the hypothesis survives → fix. If it dies → form a new one.

4. **Use the right tool**
   - **Logs**: fine for timing, bad for structure. Grep with `rg`.
   - **Debugger**: mandatory for null-pointer and race bugs. Node: `--inspect-brk`.
     Python: `python -m pdb`. Rust: `rust-lldb`. Go: `dlv debug`.
   - **Tracing**: for distributed / async bugs — add `traceId` fields and
     grep for one request across services.
   - **Memory**: `heaptrack` (C/C++), `memray` (Python), `--max-old-space-size`
     and `--heapsnapshot-signal=SIGUSR2` (Node).

5. **Write the fix**
   - Include a regression test. A fix without a test guarantees the bug
     will return within 6 months.
   - Commit message format:
     ```
     fix(<area>): <what the bug did, one line>

     Root cause: <one paragraph>
     Fix:        <one paragraph>
     Reproducer: <link or steps>
     ```

## Common bug patterns and their telltales

| Symptom                              | Usual cause                                  |
| ------------------------------------ | -------------------------------------------- |
| "Works on my machine"                | Env var, locale, path separator, or Node/Py version. |
| Intermittent failure                 | Race condition or shared mutable state.      |
| Works alone, fails in test suite     | Test order dependency / leaked global state. |
| Wrong data but no error              | Off-by-one, missing `await`, or wrong branch of `if`. |
| Works for one user, fails for others | Time zone, locale, or user-specific data shape. |
| Fast locally, slow in prod           | N+1 query, missing index, or cold cache.     |
| 404 from API that "worked yesterday" | Decommissioned endpoint / renamed model → invoke `groq-404-doctor` skill. |

## Never

- Ship a fix without reproducing the bug first.
- Wrap the crash in `try/catch` and log → move on. That's hiding, not fixing.
- "Fix" a flaky test by adding retries without finding the race.
