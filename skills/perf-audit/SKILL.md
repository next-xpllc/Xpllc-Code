# perf-audit

when_to_use: |
  User says "this is slow", "high latency", "high CPU", "OOM", "memory leak",
  "N+1 queries", or asks for a perf review of a specific endpoint / function.

## First law of perf work

> **Measure first. Optimize second. Verify third.**

If you "optimize" without a before-number and an after-number, you are not
doing performance work — you are doing astrology.

## Procedure

1. **Define the metric**
   - Latency? p50, p95, p99 — specify which.
   - Throughput? req/s under what concurrency?
   - Memory? peak RSS, or steady-state, or leak rate?
   - Write it down. The metric is the contract.

2. **Baseline measurement** (pick the right tool):

   | Concern       | JS/Node                  | Python                      | Rust                    | Go                     |
   | ------------- | ------------------------ | --------------------------- | ----------------------- | ---------------------- |
   | CPU profile   | `--cpu-prof` / clinic.js | `cProfile` + `snakeviz`     | `cargo flamegraph`      | `pprof` (`/debug/pprof`) |
   | Heap          | `--heapsnapshot-signal`  | `tracemalloc`, `memray`     | `dhat` / `heaptrack`    | `pprof -heap`          |
   | Benchmarks    | `tinybench`, `benny`     | `pytest-benchmark`          | `criterion`             | `testing.B`            |
   | HTTP load     | `autocannon`, `k6`       | `locust`, `k6`              | `wrk`, `oha`            | `hey`, `vegeta`        |

3. **Find the hot path** — the 3 functions that own >50% of time.
   Optimize those. Ignore the rest even if they're ugly.

4. **Common wins, ranked by effort:impact**

   - **Zero-cost**: remove redundant work (duplicate queries, recomputed values
     in loops, `JSON.parse`+`JSON.stringify` round-trips).
   - **Tiny**: add an index (DB), cache a computed-once value, use `Set`
     instead of `Array.includes` in hot loops.
   - **Small**: batch N+1 queries into one. Move I/O out of tight loops.
   - **Medium**: introduce a request-scoped cache. Stream instead of buffer.
   - **Large**: rewrite the algorithm (O(n²) → O(n log n)). Only if #1–4 didn't move the needle.

5. **Re-measure** with the exact same workload as the baseline.
   Report the ratio: "p95 went from 820ms → 180ms (-78%)."

## Red flags the agent should scan for automatically

- `await` inside a `for` loop — almost always should be `Promise.all` + `map`.
- `SELECT *` in hot-path queries.
- `for row in cursor.fetchall():` on a large table — stream it.
- String concatenation in a loop (Python, Java) — use a list + `join`.
- Locking a mutex around I/O — contention amplifier.
- Synchronous filesystem calls in a request handler.
- Unbounded LRU caches — they're not LRU, they're leaks.

## What to write in the commit

```
perf(<area>): <what changed> (<metric>: <before> → <after>)

Workload: <exact command or JMH / k6 scenario>
Baseline: p95=820ms, rps=120, mem=512MB
After:    p95=180ms, rps=520, mem=310MB
Method:   <one-paragraph explanation>
```

## Never

- Micro-optimize what the profiler didn't point at.
- Replace a clear algorithm with a cryptic one for 2% gain.
- Skip the "after" measurement "because obviously it's faster."
