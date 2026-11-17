# Benchmark: REST vs GraphQL on the same backend

**Measured:** 2026-11-17 · **Tool:** `BenchmarkTests` (`Packages/Core/Tests/ContractTests`) · 5 runs per scenario, averaged, after one warm-up run.

Each scenario uses a fresh stack: a new `NetworkLog` and an ephemeral `URLSession` with **no `URLCache`**, so HTTP caching can't flatter REST. Requests and bytes come from the same `NetworkLog` the in-app network log shows. Bytes are **decoded body bytes**, not on-the-wire (gzip) size. REST runs with the app's `RetryMiddleware`, and every attempt (each `429` included) is counted. There's a 4 s cool-down between runs.

> ⚠️ **Environment:** this was measured from a Mac (macOS host process) on home Wi-Fi, not on a real iPhone yet. Expect absolute times to differ on a device or cellular network. The *ratios* and request/byte counts are what matter. Re-run on a device and replace the table.

## Results

| Scenario | REST naive (sequential) | REST naive (6 concurrent) | REST batch | GraphQL (network) | GraphQL (cache) |
|---|---|---|---|---|---|
| Rick detail (51 episodes): requests | 52 | 52 | 2 | 1 | 0 |
| Rick detail: total time (ms) | 23939 | 20597 | 191 | 751 | 75 |
| Rick detail: bytes (decoded body) | 71.0 KB | 71.0 KB | 71.0 KB | 6.1 KB | 0.0 KB |
| Rick detail: failed loads (of 5, after retries) | 0 | 2 | 0 | 0 | 0 |
| Rick detail: 429s per load (rate limited) | 4.4 | 28.0 | 0.0 | 0.0 | 0.0 |
| Episode detail (cast grid): requests | n/a | n/a | 2 | 1 | 0 |
| Episode detail: total time (ms) | n/a | n/a | 160 | 606 | 24 |
| Episode detail: bytes (decoded body) | n/a | n/a | 16.2 KB | 3.1 KB | 0.0 KB |

## Analysis

- **N+1 isn't just slow, it gets you throttled.** The live API rate-limits bursts (HTTP `429`, no `Retry-After`, after ~30 rapid requests). The naive 52-request load hit it **even sequentially** (4.4 × `429` per load). With 6 in flight it averaged 28 × `429` and **failed 2 of 5 loads even after 5 retry attempts**. Retry backoff, not the requests themselves, is why the naive times are ~20 s.
- **REST batch is the latency winner.** 2 requests in ~190 ms, about **4× faster** than GraphQL's single request (~750 ms). GraphQL doesn't remove N+1, it moves it to the server: resolving `character.episode { … }` still means the server fetches 51 episodes. A simple, CDN-friendly REST endpoint answers faster.
- **GraphQL is the bandwidth winner.** 6.1 KB vs 71 KB for Rick (**11× less**) and 3.1 KB vs 16.2 KB for an episode (**5× less**). REST over-fetches every episode's 20+ character URLs, `url`, `created`, and so on. On a slow or metered connection, bytes can matter more than server time.
- **The normalized cache makes a revisit free.** 0 requests and ~75 ms for Rick's detail (most of that is Apollo reading and assembling ~55 normalized records, not I/O). REST has no equivalent here without building one.
- **The trade-off in one sentence:** with a good batch endpoint, REST wins on latency and simplicity, while GraphQL wins on payload size, round trips, and client-side caching. The right choice depends on the network and on whether you control the backend.

## Reproduce

```bash
cd Packages/Core
RUN_BENCHMARKS=1 BENCHMARK_OUTPUT=$PWD/benchmark-table.md swift test --filter BenchmarkTests
```
It takes ~7–8 minutes because of the cool-downs, and makes ~700 requests to the public API, so don't run it in a loop.
