# GC and Runtime Tuning

\index{garbage collector}
\index{GC!design philosophy}
Java programmers arrive at Go expecting a dashboard full of GC knobs: `-Xms`, `-Xmx`, `-XX:+UseG1GC`, `-XX:MaxGCPauseMillis`, survivor ratios, generation sizes.
Go's answer is intentional minimalism.
The runtime ships with a concurrent, tricolor mark-and-sweep collector that is designed from the ground up for **low latency**: it runs concurrently with your program, targets sub-millisecond stop-the-world pauses, and tunes itself automatically.
The design goal is to make GC invisible in most programs.
When it is not invisible --- container memory limits, latency spikes, allocation-heavy hot paths --- there are a small number of high-leverage controls available.
This appendix covers all of them.

## Escape Analysis: Stack vs Heap

\index{escape analysis}
\index{stack}
\index{heap}
Chapter 2 introduced escape analysis in the context of pointers.
\index{memory pressure}
Here we revisit it from a performance perspective, because whether a variable lives on the stack or the heap has a direct effect on GC pressure.

Stack allocations are essentially free: the stack pointer advances, and when the function returns, the pointer retreats.
There is no GC involvement at all.
Heap allocations must be tracked by the GC, scanned during collection, and eventually freed --- all of which costs CPU time.

The Go compiler performs escape analysis at compile time and promotes a variable to the heap only when it must: when a pointer to the variable outlives the function, when the variable is too large for the stack, or when the compiler cannot prove the value is short-lived.
The rest stays on the stack.

::: {.tip}
**Tip:** The practical implication is that small, short-lived values --- loop variables, intermediate results, small structs returned by value --- usually stay on the stack and cost nothing extra.
You pay heap allocation costs only for things that genuinely need to survive their creating function or that you explicitly share via pointer.
:::

### Reading Escape Analysis Output

\index{escape analysis!gcflags}
\index{go build}
You can ask the compiler to annotate every allocation decision with:

```bash
go build -gcflags=-m ./...
```

For more detail (why something escaped, not just that it did), use `-gcflags='-m -m'`:

```bash
go build -gcflags='-m -m' ./...
```

The output looks like:

```
./songs.go:12:6:  moved to heap: buf
./songs.go:18:14: &s does not escape
./songs.go:24:12: make([]string, n) escapes to heap
```

`moved to heap` means the variable was promoted because a pointer to it outlives the current stack frame.
`does not escape` means the address was taken but the pointer never leaves the function, so the variable stays on the stack.

::: {.tip}
**Tip:** You do not need to read this output in daily work.
It becomes useful when profiling (Appendix C) shows unexpected heap allocations, or when you are tuning a hot inner loop and want to confirm that temporary values are not leaking to the heap.
:::

::: {.tip}
**Trap:** Storing a value in an `interface{}` (or `any`) almost always causes the value to escape to the heap, because the runtime cannot know the concrete type's size at the call site.
This is why `fmt.Sprintf` and `fmt.Println` are not appropriate for hot paths --- every argument boxes into an `any`, which triggers a heap allocation.
:::

## `GOGC`: Controlling GC Frequency

\index{GC!GOGC}
\index{GOGC}
`GOGC` is the primary knob for GC tuning in Go.
It is an environment variable that controls the **GC target ratio**: how much the heap is allowed to grow (relative to the live heap after the last collection) before triggering the next GC cycle.

The default is `100`, which means "trigger a GC when the total heap size reaches twice the live heap after the last collection."
If 10 MB of objects survived the last GC, the next GC triggers at ~20 MB.

Increasing `GOGC` lets the heap grow larger before collecting, which reduces the **frequency** of GC cycles at the cost of higher peak memory:

```bash
GOGC=200 ./myserver   # collect when heap reaches 3× live; fewer, longer pauses
GOGC=50  ./myserver   # collect when heap reaches 1.5× live; more frequent, smaller pauses
GOGC=off ./myserver   # disable GC entirely (dangerous; only for benchmarks)
```

::: {.tip}
**Tip:** The JVM analog is the ratio between young-gen size and old-gen promotion threshold, or the G1 `-XX:InitiatingHeapOccupancyPercent` flag.
`GOGC` is simpler: one number, one meaning.
:::

::: {.tip}
**Trap:** `GOGC=off` disables garbage collection completely.
The heap will grow without bound until the process is killed.
Never use it in production; it is only safe for short-lived benchmarks where you want to isolate allocation cost from collection cost.
:::

### JVM Comparison

| Go | JVM equivalent |
|---|---|
| `GOGC=100` (default) | default heap growth ratio |
| `GOGC=200` | `-XX:InitiatingHeapOccupancyPercent=66` (roughly) |
| `GOGC=off` | `-XX:+DisableExplicitGC` (not quite the same, but spirit) |

The JVM has generational collectors (G1, ZGC, Shenandoah) that divide the heap into short-lived and long-lived regions and tune each independently.
Go's collector is non-generational by design: the tricolor algorithm handles the whole heap uniformly, trading generational throughput for simpler tuning and more predictable latency.

## `GOMEMLIMIT`: The Memory Ceiling

\index{GOMEMLIMIT}
\index{GC!GOMEMLIMIT}
Go 1.19 introduced `GOMEMLIMIT`, a **soft memory ceiling** for the Go runtime.
It tells the runtime: "do not let the total memory footprint of the Go heap exceed this value."
When the heap approaches the limit, the GC increases its collection frequency aggressively to stay under the ceiling.

```bash
GOMEMLIMIT=512MiB ./myserver    # keep Go heap under 512 MiB
GOMEMLIMIT=1GiB   ./myserver    # 1 GiB ceiling
```

The value accepts `B`, `KiB`, `MiB`, `GiB`, and `TiB` suffixes.
The default is `math.MaxInt64` --- effectively unlimited.

::: {.tip}
**Tip:** `GOMEMLIMIT` is essential for **container deployments**.
Without it, the Go heap can grow past the container's memory limit, triggering an OOM kill from the kernel before the GC has a chance to collect.
Set `GOMEMLIMIT` to 80--90% of the container's memory limit to leave headroom for the stack, CGo, and OS overhead.
:::

::: {.tip}
**Wut:** `GOMEMLIMIT` is a soft limit, not a hard cap.
If the program genuinely needs more memory than the limit allows --- because the live heap is larger than the limit --- the GC will thrash (collecting constantly) rather than violating the limit.
If you see CPU time dominated by GC in a memory-constrained environment, either the limit is set too low or the program genuinely needs more memory.
:::

The JVM equivalent is `-Xmx`, the maximum heap size.
The key difference: `-Xmx` is a hard cap enforced by the JVM; `GOMEMLIMIT` is a target that the GC works toward, not a wall that throws `OutOfMemoryError`.

```bash
# JVM equivalent pattern
java -Xmx512m -jar myapp.jar

# Go equivalent
GOMEMLIMIT=512MiB ./myapp
```

### Using Both `GOGC` and `GOMEMLIMIT`

The two knobs compose well.
A common container tuning pattern is:

```bash
GOGC=off GOMEMLIMIT=450MiB ./myserver
```

Setting `GOGC=off` disables the ratio-based trigger entirely, so the GC only runs when the heap approaches `GOMEMLIMIT`.
This gives maximum throughput when memory is abundant and still protects against OOM kills.
The Go documentation calls this the "memory-limit-only" strategy and recommends it for latency-sensitive services running in containers with known memory budgets.

## Programmatic Control: `runtime/debug`

\index{runtime/debug}
\index{runtime/debug!SetGCPercent}
\index{runtime/debug!SetMemoryLimit}
The environment variables set GC policy at process startup.
The `runtime/debug` package exposes the same controls at runtime, so you can adjust them based on application state.

```go
import "runtime/debug"

// SetGCPercent sets the GC target ratio, equivalent to GOGC.
// A negative value disables GC. Returns the previous setting.
func SetGCPercent(percent int) int

// SetMemoryLimit sets the soft memory ceiling, equivalent to GOMEMLIMIT.
// Returns the previous limit.
func SetMemoryLimit(limit int64) int64
```

A common pattern is to read `GOMEMLIMIT` from an environment variable (or a configuration system) at startup and apply it programmatically:

```go
package main

import (
    "fmt"
    "os"
    "runtime/debug"
    "strconv"
)

func applyMemoryLimit() {
    raw := os.Getenv("APP_MEM_LIMIT_MB")
    if raw == "" {
        return
    }
    mb, err := strconv.ParseInt(raw, 10, 64)
    if err != nil {
        fmt.Fprintf(os.Stderr, "invalid APP_MEM_LIMIT_MB: %v\n", err)
        return
    }
    prev := debug.SetMemoryLimit(mb * 1024 * 1024)
    fmt.Printf("memory limit set to %d MiB (was %d bytes)\n", mb, prev)
}
```

::: {.tip}
**Tip:** Prefer `GOMEMLIMIT` for container deployments where the limit is set by the orchestrator (Kubernetes, Docker).
Use `debug.SetMemoryLimit` when the limit comes from your own configuration system or needs to change at runtime (for example, in a multi-tenant server where each tenant has a different quota).
:::

You can also trigger a manual GC cycle (for benchmarking or after releasing a large data structure) with:

\index{runtime.GC}
```go
import "runtime"

runtime.GC() // force an immediate GC cycle
```

::: {.tip}
**Trap:** Do not call `runtime.GC()` in production code as a workaround for allocation pressure.
It blocks until the cycle completes, adding latency.
Fix the allocation pattern instead; `runtime.GC()` is a diagnostic tool, not a solution.
:::

## `GOMAXPROCS` Revisited: CPU-Bound Tuning

\index{GOMAXPROCS}
\index{GC!GOMAXPROCS}
Chapter 12 introduced `GOMAXPROCS` as the number of OS threads the Go scheduler uses to run goroutines.
The default is `runtime.NumCPU()` --- the number of logical CPUs the process can see.
For most programs this default is correct and you should leave it alone.

There are two cases where tuning matters:

**Containerized CPU limits.**
If your container is allowed only 0.5 CPUs (`--cpus=0.5` in Docker), the OS reports the host CPU count to `runtime.NumCPU()`, not 0.5.
`GOMAXPROCS` defaults to, say, 32, but the scheduler is only getting half a CPU of actual time.
The result is excessive context switching and scheduler overhead.
Set `GOMAXPROCS` to match the actual CPU quota:

```bash
GOMAXPROCS=1 ./myserver   # if container has 0.5--1 CPU quota
```

The `uber-go/automaxprocs` library reads the container's CPU quota from cgroups and sets `GOMAXPROCS` automatically at program start:

```go
import _ "go.uber.org/automaxprocs"  // sets GOMAXPROCS from cgroup CPU quota on import
```

**CPU-bound batch jobs.**
For programs doing purely CPU-bound work (number crunching, image processing, compression), increasing `GOMAXPROCS` beyond the CPU count is never helpful and usually hurts.
Stick with the default.

::: {.tip}
**Tip:** The JVM analog is `-XX:ActiveProcessorCount`, which was added in JDK 10 specifically to handle the container CPU quota problem.
Go's solution is the same: set the parallelism to match what the OS will actually schedule, not what the hardware has.
:::

You can also read and set `GOMAXPROCS` at runtime:

\index{runtime.GOMAXPROCS}
```go
import "runtime"

n := runtime.GOMAXPROCS(0)   // 0 means "query, do not change"; returns current value
runtime.GOMAXPROCS(4)        // set to 4 OS threads
```

## `sync.Pool` Revisited: Reducing Allocation Pressure

\index{sync!Pool}
\index{allocation pressure}
Chapter 11 introduced `sync.Pool` as a way to reuse temporary objects.
Here we revisit it from the GC tuning perspective: `sync.Pool` is one of the most effective tools for reducing **allocation pressure** --- the rate at which new objects are added to the heap, forcing more frequent GC cycles.

The pattern is most valuable when:

- The same type of object is allocated and discarded at high frequency (per-request buffers, encoder/decoder state, scratch slices).
- The allocation is large enough that creating a new one every time is measurable.
- The object can be safely reset between uses.

```go
package main

import (
    "bytes"
    "fmt"
    "sync"
)

var encodeBufPool = sync.Pool{
    New: func() any {
        b := make([]byte, 0, 4096) // pre-size to typical payload
        return &b
    },
}

func encodeTrack(title string) []byte {
    bp := encodeBufPool.Get().(*[]byte) // retrieve a buffer
    buf := (*bp)[:0]                    // reset length, keep capacity
    buf = append(buf, []byte(title)...)
    buf = append(buf, '\n')
    result := make([]byte, len(buf)) // copy out before returning to pool
    copy(result, buf)
    *bp = buf
    encodeBufPool.Put(bp) // return to pool
    return result
}

func main() {
    fmt.Printf("%s", encodeTrack("Espresso"))
    fmt.Printf("%s", encodeTrack("Greedy"))
}
```

::: {.tip}
**Wut:** The GC can drain a `sync.Pool` at any collection cycle.
Pooled objects are not cached between GC cycles --- they are temporary scratch space.
If the pool is drained between requests (under low load), `New` is called again.
This is expected behavior, not a bug.
:::

::: {.tip}
**Tip:** The standard library uses `sync.Pool` extensively internally --- `encoding/json`, `compress/gzip`, `net/http`, and `fmt` all pool their internal buffers.
When you profile a Go service and see `sync.Pool.Get` in the trace, that is the standard library doing the right thing.
:::

### When Not to Use `sync.Pool`

Do not use `sync.Pool` as a general-purpose object cache.
It is not a cache: objects can disappear at any GC cycle, and there is no eviction policy.
If you need objects to survive across GC cycles (a connection pool, an LRU cache), use a purpose-built structure --- a buffered channel, a `sync.Map`, or an explicit free list guarded by a mutex.

## Quick Reference

\index{GC!quick reference}
The table below lists every Go runtime tuning variable covered in this appendix alongside its closest JVM equivalent.

| Go env var / API | Default | What it does | JVM equivalent |
|---|---|---|---|
| `GOGC` | `100` | Heap growth ratio before GC triggers (% of live heap) | `-XX:InitiatingHeapOccupancyPercent` (G1) |
| `GOGC=off` | --- | Disable GC entirely | `-XX:+DisableExplicitGC` (not identical) |
| `GOMEMLIMIT` | unlimited | Soft memory ceiling for the Go heap | `-Xmx` |
| `GOMAXPROCS` | CPU count | OS threads running Go code | `-XX:ActiveProcessorCount` |
| `debug.SetGCPercent(n)` | `100` | Programmatic equivalent of `GOGC` | `ManagementFactory.getMemoryMXBean()` (no direct equiv) |
| `debug.SetMemoryLimit(n)` | `MaxInt64` | Programmatic equivalent of `GOMEMLIMIT` | no direct equivalent |
| `runtime.GOMAXPROCS(n)` | CPU count | Programmatic equivalent of `GOMAXPROCS` | `ForkJoinPool.commonPool().setParallelism(n)` (rough) |
| `runtime.GC()` | --- | Force an immediate GC cycle | `System.gc()` (advisory) |

Go deliberately has fewer knobs than the JVM.
There is no generational tuning, no collector selection (`-XX:+UseG1GC`, `-XX:+UseZGC`), no survivor ratio, no metaspace size.
The Go team's position is that a well-tuned concurrent collector with sensible defaults is preferable to a configuration space large enough to misconfigure.
For the vast majority of Go programs, the right answer is: set `GOMEMLIMIT` to match your container budget, leave everything else at the default, and let the profiler tell you if something is actually wrong.
