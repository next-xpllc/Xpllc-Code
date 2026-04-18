# test-generation

when_to_use: |
  User asks to write unit tests, integration tests, add test coverage, or
  asks for a failing test that reproduces a bug they just described.

## Philosophy

Tests are **executable documentation** of the intended behavior. A good test
tells the next developer *why* the code does what it does, not just *what*.

## Procedure

1. **Choose the layer** — smallest that still catches the bug:
   - **Unit**: pure function, no I/O, no network, no time.
   - **Integration**: real DB/HTTP, but in-process and hermetic.
   - **E2E**: full stack, only for flow-level invariants.

2. **Choose the framework** — match the project:
   - JS/TS: `vitest` if present, else `jest`, else the Node built-in `node:test`.
   - Python: `pytest` if config present, else `unittest`.
   - Rust: `#[cfg(test)] mod tests {}` in the same file for unit tests.
   - Go: `_test.go` alongside the file under test.

3. **Structure each test as Arrange / Act / Assert**:
   ```ts
   it('returns 0 for an empty basket', () => {
     // Arrange
     const basket = new Basket();
     // Act
     const total = basket.total();
     // Assert
     expect(total).toBe(0);
   });
   ```

4. **Name tests in the form `<subject>_<condition>_<expectation>`**
   - ✅ `total_emptyBasket_returnsZero`
   - ❌ `test1`, `itWorks`

5. **Cover these cases by default**:
   - Happy path with realistic input.
   - Boundary: empty, zero, max, min, one element.
   - Invalid input: null, wrong type, out-of-range.
   - Error path: dependency throws → does the SUT propagate/wrap correctly?
   - Idempotency if relevant: calling twice equals calling once.

6. **Never use `sleep()` for timing**. Use fake timers / `jest.useFakeTimers()`
   / `tokio::time::pause()` / `freezegun`.

7. **Isolate external dependencies**:
   - Network → in-process fake, MSW, `httptest.Server`, or recorded fixtures.
   - Time → inject a `Clock` interface.
   - Randomness → seed it.
   - Filesystem → `tmpdir()` fixture, cleaned up in teardown.

## For bug reports specifically

If the user says *"fix this bug"*:

1. **First write a failing test that reproduces the bug.**
2. Show the user the failing output.
3. Only then write the fix.
4. Show the now-passing output.
5. Commit with `fix(<area>): <one-line bug summary>` — reference the reporter.

## Coverage guidance

Don't chase 100%. Aim for **every branch of non-trivial logic covered by one
meaningful test**. A mutation-testing pass > a coverage-report pass.
