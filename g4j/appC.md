# Profiling and Performance

\index{profiling}
\index{performance}
Go ships with a production-grade profiling toolchain built directly into the standard library and runtime.
If you are coming from Java, you have likely used JFR/JMC, async-profiler, or `-XX:+PrintGCDetails` to diagnose performance problems.
Go's toolchain covers the same ground --- CPU hotspots, memory allocation, goroutine contention, and scheduler behavior --- through the `pprof` package, `go tool pprof`, and `go tool trace`.
This appendix is a practical reference for reaching for the right tool at the right time.

## pprof: The Standard Profiler

\index{pprof}
The `runtime/pprof` package is Go's equivalent of Java's JFR event engine.
It records several profile types to `io.Writer` values; you decode and visualize them with `go tool pprof`.

### CPU Profile

\index{pprof!CPU profile}
A CPU profile samples the call stack at regular intervals (default: 100 Hz) and reports where your program spends time.
This is the direct analog of async-profiler's wall-clock or CPU mode.

```go
import (
    "os"
    "runtime/pprof"
)

func main() {
    f, _ := os.Create("cpu.pprof")
    defer f.Close()
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()

    // ... your code here
}
```

Start the profile, run your workload, stop it, then analyze:

```
go build -o myapp .
./myapp
go tool pprof cpu.pprof
```

Inside the `pprof` REPL, `top` shows the hottest functions and `web` opens a call graph in your browser (requires Graphviz).

### Memory Profile

\index{pprof!memory profile}
A memory profile records heap allocations.
Where Java's JFR Object Allocation events or async-profiler allocation profiling capture every allocation, Go's heap profile captures a statistical sample (1 in every `runtime.MemProfileRate` bytes, default 512 KB).

```go
import (
    "os"
    "runtime"
    "runtime/pprof"
)

// call this at the end of your program, or at a representative steady state
func writeHeapProfile() {
    f, _ := os.Create("mem.pprof")
    defer f.Close()
    runtime.GC()             // run GC first to get accurate live-object data
    pprof.WriteHeapProfile(f)
}
```

Analyze it the same way:

```
go tool pprof mem.pprof
```

The profile has four sample types: `alloc_objects`, `alloc_space`, `inuse_objects`, and `inuse_space`.
Use `-alloc_space` to find what allocates the most total bytes; use `-inuse_space` (the default) to find what is live at the moment the profile was written.

::: {.tip}
**Tip:** `inuse_space` is useful for finding memory leaks.
`alloc_space` is useful for finding GC pressure --- even allocations that are quickly freed drive collection pauses.
:::

### Goroutine Profile

\index{pprof!goroutine profile}
The goroutine profile prints the current call stack of every goroutine.
It is invaluable for diagnosing goroutine leaks --- the Go equivalent of a Java thread dump.

```go
pprof.Lookup("goroutine").WriteTo(os.Stdout, 1)
```

The second argument is the debug level: `1` gives a human-readable stack trace, `2` adds extra detail, `0` writes binary pprof format.

You can also capture it on demand via the HTTP endpoint described in the next section.

## net/http/pprof: Live Server Profiling

\index{net/http/pprof}
\index{pprof!HTTP endpoint}
For long-running services --- HTTP servers, gRPC services, background daemons --- you can expose a profiling endpoint by importing `net/http/pprof` for its side effects:

```go
import _ "net/http/pprof"
```

This blank import registers several handlers on `http.DefaultServeMux` under `/debug/pprof/`:

| Path | Description |
|------|-------------|
| `/debug/pprof/` | Index page with all available profiles |
| `/debug/pprof/profile?seconds=N` | N-second CPU profile |
| `/debug/pprof/heap` | Heap memory snapshot |
| `/debug/pprof/goroutine` | All goroutine stacks |
| `/debug/pprof/block` | Goroutine blocking events |
| `/debug/pprof/mutex` | Mutex contention |
| `/debug/pprof/trace?seconds=N` | Execution trace (see §go-tool-trace) |

If your service already uses `http.ListenAndServe` on `http.DefaultServeMux`, the endpoint is live immediately.
If your service uses a custom mux, start a separate listener:

```go
go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

::: {.tip}
**Trap:** Never expose `/debug/pprof` on a public-facing port.
The profile data leaks implementation details, and the CPU profile endpoint can be used as a denial-of-service vector.
Bind it to `localhost` only, or gate it behind authentication.
:::

Collect a 30-second CPU profile from a running service:

```
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30
```

This downloads the profile directly into the `pprof` interactive session --- no intermediate file needed.

## Block Profile and Mutex Profile

\index{block profile}
\index{mutex profile}
\index{runtime.SetBlockProfileRate}
\index{runtime.SetMutexProfileFraction}
Two profile types are disabled by default because they add per-event overhead.
You opt in at runtime.

### Block Profile

The block profile records where goroutines spent time blocked waiting on a channel receive, channel send, or `sync` primitive.
This is similar to Java's lock contention view in JFR, but covers all Go synchronization primitives.

```go
import "runtime"

runtime.SetBlockProfileRate(1) // sample every blocking event; rate=0 disables
```

The integer argument is a sample rate in nanoseconds: `1` means record every event, larger values reduce overhead by sampling.
After enabling, the profile accumulates until you read it via `/debug/pprof/block` or `pprof.Lookup("block")`.

```
go tool pprof http://localhost:6060/debug/pprof/block
```

### Mutex Profile

\index{pprof!mutex profile}
The mutex profile records where goroutines waited to acquire a `sync.Mutex` or `sync.RWMutex`.
It captures contention, not just blocking.

```go
runtime.SetMutexProfileFraction(1) // sample 1/N of mutex contentions; -1 disables
```

`SetMutexProfileFraction(1)` records every contention event.
Higher values (e.g., `5`) record 1 in 5 events, reducing overhead.

```
go tool pprof http://localhost:6060/debug/pprof/mutex
```

::: {.tip}
**Tip:** Enable block and mutex profiles only in development or in production under controlled load testing --- not by default in all production instances.
The overhead is low but not zero.
:::

## Flame Graphs with go tool pprof -http

\index{pprof!flame graph}
\index{go tool pprof}
The `go tool pprof -http` flag launches a local web server with an interactive UI --- including flame graphs, call graphs, and source annotation.
This is the Go equivalent of opening JMC or the async-profiler HTML report.

```
go tool pprof -http=:8080 cpu.pprof
```

Or directly against a live service:

```
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/profile?seconds=30
```

Your browser opens automatically.
The most useful views:

- **Flame Graph** --- the canonical view: wider bars mean more CPU time; click to zoom into a subtree.
  This is identical in interpretation to async-profiler's flamegraph.html output.
- **Top** --- a flat table of functions sorted by self or cumulative time.
- **Source** --- annotates each line with sample counts when source is available.
- **Peek** --- shows callers and callees of the selected function.

::: {.tip}
**Tip:** The flame graph y-axis is call depth (callers at the bottom, leaf functions at the top).
A wide bar at the top of a flame means that function is where time is actually spent.
A wide bar at the bottom means many different call paths funnel through that function.
:::

## go tool trace: Goroutine and Scheduler Tracing

\index{go tool trace}
\index{execution trace}
`pprof` tells you *where* time was spent.
`go tool trace` tells you *when* --- the precise sequence of goroutine scheduling, GC phases, network I/O, and system calls.
The Java equivalent is a JFR recording opened in JMC's thread view, but Go's trace is far more detailed about the scheduler itself.

Collect a trace from a running service:

```
curl -o trace.out http://localhost:6060/debug/pprof/trace?seconds=5
go tool trace trace.out
```

Or write one programmatically:

```go
import "runtime/trace"

f, _ := os.Create("trace.out")
defer f.Close()
trace.Start(f)
defer trace.Stop()
```

`go tool trace trace.out` opens a browser UI with several panels:

- **View trace** --- a timeline of every goroutine across all OS threads.
  You can see exactly when each goroutine was running, blocked, or runnable.
- **Goroutine analysis** --- lists goroutines with their total scheduling latency, execution time, and network or sync block time.
- **Minimum mutator utilization (MMU)** --- shows how much of the available CPU time was available to your program versus consumed by GC.
  A dip in the MMU chart reveals GC pauses.
- **Network blocking profile** and **Sync blocking profile** --- derived profiles extracted from the trace.

::: {.tip}
**Wut:** Trace files grow quickly --- a 5-second trace on a busy service can reach hundreds of megabytes.
Keep trace collection windows short, and use `pprof` for steady-state profiling.
:::

## Profile-Guided Optimization (PGO)

\index{PGO}
\index{profile-guided optimization}
\index{default.pgo}
Go 1.20 introduced profile-guided optimization (PGO).
The compiler reads a CPU profile from a previous run and uses the hot-path data to make better inlining and devirtualization decisions.
In practice this delivers **2--14% throughput improvement** with no code changes.

The workflow has three steps:

**Step 1 --- collect a representative CPU profile from production (or a realistic load test):**

```
curl -o default.pgo http://prod-service:6060/debug/pprof/profile?seconds=30
```

**Step 2 --- place `default.pgo` in the package directory and build:**

```
cp default.pgo ./cmd/myservice/default.pgo
go build -pgo=auto ./cmd/myservice
```

`-pgo=auto` (the default since Go 1.21) tells the compiler to look for `default.pgo` in the main package directory automatically.
Pass an explicit path with `-pgo=/path/to/profile.pprof` if the file lives elsewhere.

**Step 3 --- deploy and iterate:**
As your code changes, the profile stays useful as long as the hot paths do not shift dramatically.
Refresh the profile periodically --- once per release or when you change a hot function significantly.

::: {.tip}
**Tip:** PGO is additive with other optimizations.
You do not need to change your code at all --- just supply the profile file and rebuild.
The compiler handles the rest.
:::

::: {.tip}
**Wut:** The PGO profile does not need to be from the exact same binary version.
The compiler matches profiles to functions by name; unmatched functions are compiled normally.
Stale profiles are safe --- they just give fewer optimization opportunities.
:::

## GODEBUG: Runtime Knobs

\index{GODEBUG}
The `GODEBUG` environment variable exposes runtime diagnostics without recompiling.
It is the Go equivalent of the JVM's `-XX:+PrintGCDetails`, `-Xlog:gc*`, and `-XX:+PrintSafepointStatistics` flags.
Set it to a comma-separated list of `key=value` pairs before running your program.

### gctrace

\index{GODEBUG!gctrace}
`gctrace=1` prints a line to stderr on every GC cycle:

```
GODEBUG=gctrace=1 ./myapp
```

A typical output line looks like:

```
gc 12 @4.321s 0%: 0.12+1.4+0.03 ms clock, 0.97+0.41/1.1/0.22+0.22 ms cpu,
    8->9->4 MB, 9 MB goal, 0 MB stacks, 0 MB globals, 8 P
```

Reading left to right: GC number, time since program start, wall-clock time for each GC phase, heap size before/after/live, heap goal, and number of logical processors.
A healthy Go service spends less than 1% of wall time in GC.
If `gctrace` shows consistently high percentages, look at your allocation rate with `pprof -alloc_space`.

### schedtrace

\index{GODEBUG!schedtrace}
`schedtrace=N` prints scheduler state every N milliseconds:

```
GODEBUG=schedtrace=1000 ./myapp
```

Each line shows the number of goroutines, OS threads, and logical processors, plus how many goroutines are runnable, running, or waiting.
Use this to diagnose goroutine pile-ups or thread exhaustion:

```
SCHED 1000ms: gomaxprocs=8 idleprocs=0 threads=12 spinningthreads=1
              needspinning=0 idlethreads=0 runqueue=47 [3 4 5 6 7 8 4 5]
```

A large `runqueue` with `idleprocs=0` means the scheduler is saturated --- more goroutines want to run than there are processors available.

::: {.tip}
**Tip:** Combine `gctrace=1` and `schedtrace=1000` for a quick health check:
`GODEBUG=gctrace=1,schedtrace=1000 ./myapp 2>&1 | grep -E '^(gc|SCHED)'`
:::

## Summary: Quick-Reference Profiling Workflow

\index{profiling!workflow}
The following workflow covers the common case of profiling a running Go HTTP service.

**1. Add the profiling import (one line, no other changes):**

```go
import _ "net/http/pprof"
```

Ensure `http.ListenAndServe("localhost:6060", nil)` is running, or add it in a separate goroutine.

**2. Reproduce your workload** (send production-representative traffic, run your load test, etc.).

**3. Collect profiles while the workload is running:**

```
# CPU: 30-second sample
go tool pprof -http=:8080 'http://localhost:6060/debug/pprof/profile?seconds=30'

# Heap: current allocations
go tool pprof -http=:8081 http://localhost:6060/debug/pprof/heap

# Goroutine stacks: look for leaks
go tool pprof -http=:8082 http://localhost:6060/debug/pprof/goroutine
```

**4. Identify the hotspot** in the flame graph or `top` view.

**5. If you see excessive blocking**, enable the block or mutex profile:

```go
runtime.SetBlockProfileRate(1)
runtime.SetMutexProfileFraction(1)
```

Then collect:

```
go tool pprof -http=:8083 http://localhost:6060/debug/pprof/block
go tool pprof -http=:8084 http://localhost:6060/debug/pprof/mutex
```

**6. If you need scheduler-level detail**, collect a short execution trace:

```
curl -o trace.out 'http://localhost:6060/debug/pprof/trace?seconds=5'
go tool trace trace.out
```

**7. For a free throughput gain**, collect a production CPU profile as `default.pgo` and rebuild with `-pgo=auto`.

**8. For runtime sanity checks** without a full profile, use `GODEBUG`:

```
GODEBUG=gctrace=1,schedtrace=5000 ./myapp
```

| Tool | What it answers | Java equivalent |
|------|----------------|-----------------|
| `pprof` CPU | Where does CPU time go? | async-profiler, JFR CPU events |
| `pprof` heap | What is allocating memory? | JFR allocation profiling, async-profiler |
| `pprof` goroutine | Are goroutines leaking? | Java thread dump (`jstack`) |
| `pprof` block | What are goroutines waiting on? | JFR lock profile |
| `pprof` mutex | Which mutexes are contended? | JFR monitor events |
| `go tool trace` | When did everything happen? | JFR + JMC thread timeline |
| PGO | Free speedup from hot-path data | JIT with profiling feedback |
| `GODEBUG=gctrace=1` | GC frequency and pause times | `-Xlog:gc*` / PrintGCDetails |
| `GODEBUG=schedtrace` | Scheduler saturation | `-XX:+PrintSafepointStatistics` |
