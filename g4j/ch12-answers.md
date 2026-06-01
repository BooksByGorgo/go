# Chapter 13: Context and Concurrency Patterns --- Answers

**Exercise 1** (Think about it): In Java, cancelling an in-flight operation typically means calling `Future.cancel(true)` or interrupting a thread via `Thread.interrupt()`.
Describe how Go's `context.Context` model differs from Java's thread-interrupt approach.
What are the advantages of passing a context explicitly rather than relying on a thread-level interrupt mechanism?
Consider what happens when a Java thread is blocked in a third-party library that does not handle `InterruptedException`, compared to how a Go function using a context-aware library would behave.

Java's thread-interrupt model is **implicit and cooperative at the thread level**.
When you call `Thread.interrupt()`, a flag is set on the thread, and blocking calls like `Object.wait()`, `Thread.sleep()`, and `java.io.InputStream.read()` on some implementations throw `InterruptedException` when they notice it.
But not every blocking operation checks the flag: a thread blocked in a native call, a third-party lock, or a legacy `InputStream` implementation may never see the interrupt at all.
The interrupt propagates up the call stack only as long as every layer catches and re-throws (or re-sets) the flag, which is notoriously easy to accidentally swallow:

```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    // oops, swallowed it; the interrupt flag is now cleared
}
```

Go's `context.Context` is **explicit and uniform**.
Every function that can be cancelled must accept a `context.Context` parameter.
Cancellation is communicated by closing `ctx.Done()`, which is observable without any thread-local state.
Any function that calls another context-aware function simply passes the same context through; the propagation is visible in every function signature.

The advantages over thread interrupts are:

1. **Explicit propagation.** You can see in the function signature that a function is cancellable.
   In Java, there is no signature-level signal that a method checks `Thread.interrupted()`.
2. **Deadlines and timeouts as first-class values.** `context.WithTimeout` and `context.WithDeadline` associate a deadline with the context object itself, not with a thread.
   Multiple goroutines can share the same context and respect the same deadline without any shared mutable state.
3. **No accidental swallowing.** Because `ctx.Done()` is a channel, you either select on it or you do not --- there is no exception to catch and accidentally discard.
4. **Composability.** Derived contexts (`WithCancel`, `WithTimeout`) form a tree.
   Cancelling a parent automatically cancels all children.
   Java's thread-interrupt model is flat: each thread has exactly one interrupt flag.
5. **Request-scoped values.** `context.WithValue` lets you attach metadata (trace IDs, auth tokens) to a context and retrieve it anywhere in the call tree without global state.

If a Java thread is blocked in a third-party library that does not handle `InterruptedException` --- for example, a legacy JDBC driver --- calling `Thread.interrupt()` may have no effect.
The thread stays blocked, and the only recourse is to close the underlying socket from another thread or wait for the operation to time out at the OS level.
A Go function calling a database driver built on top of `database/sql` passes a context to `db.QueryContext`; the driver layer itself monitors `ctx.Done()` and closes the connection if the context is cancelled.
The library author opts in once; all callers benefit automatically.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func work(ctx context.Context, label string) {
    select {
    case <-time.After(500 * time.Millisecond):
        fmt.Println(label, "done")
    case <-ctx.Done():
        fmt.Println(label, "cancelled:", ctx.Err())
    }
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
    defer cancel()

    go work(ctx, "Flaming June")
    go work(ctx, "Saltwater")
    time.Sleep(400 * time.Millisecond)
    fmt.Println("main done")
}
```

Output (order of the first two lines may vary):
```
Flaming June cancelled: context deadline exceeded
Saltwater cancelled: context deadline exceeded
main done
```

The context has a 200 ms timeout.
Both `work` goroutines are launched immediately and block in their `select` statement waiting for either `time.After(500ms)` or `ctx.Done()`.
After 200 ms the timeout fires, `ctx.Done()` is closed, and both goroutines unblock on the `ctx.Done()` case.
Each prints its label with `"cancelled: context deadline exceeded"`.
The goroutines finish well before `main`'s `time.Sleep(400ms)` elapses, so `"main done"` appears last.

The two cancelled lines (`Flaming June` and `Saltwater`) may appear in either order because goroutine scheduling is not deterministic.
`main done` always appears last because `time.Sleep(400ms)` is longer than the 200 ms timeout and the goroutines' response time.

---

**Exercise 3** (Calculation): You run a worker pool with `workers = 3` and feed it a slice of 7 tasks.
Each task takes exactly 100 ms.
Assuming no overhead and perfect parallelism, how many milliseconds does the pool take to complete all 7 tasks?

**Answer: 300 ms.**

With 3 workers processing tasks that each take 100 ms:

| Round | Tasks processed   | Wall-clock time elapsed |
|-------|-------------------|------------------------|
| 1     | tasks 1, 2, 3     | 0 -- 100 ms            |
| 2     | tasks 4, 5, 6     | 100 -- 200 ms          |
| 3     | task 7 (+ 2 idle) | 200 -- 300 ms          |

Round 1 dispatches tasks 1--3 in parallel.
All three finish at T=100 ms.
Round 2 dispatches tasks 4--6 in parallel; all finish at T=200 ms.
Round 3 dispatches task 7 alone (only one task remains); it finishes at T=300 ms.

Total elapsed time = ceil(7 / 3) × 100 ms = 3 × 100 ms = **300 ms**.

General formula: `ceil(N / workers) × task_duration`.

---

**Exercise 4** (Where is the bug?):

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func fetchData(url string) <-chan string {
    ch := make(chan string)
    go func() {
        time.Sleep(2 * time.Second)
        ch <- "result for " + url
    }()
    return ch
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()

    ch := fetchData("https://example.com/songs")
    select {
    case result := <-ch:
        fmt.Println(result)
    case <-ctx.Done():
        fmt.Println("timed out")
    }
}
```

**The bug: goroutine leak in `fetchData`.**

`fetchData` launches a goroutine that sleeps for 2 seconds and then sends on `ch`.
When the context times out after 500 ms, `main` exits the `select` via `ctx.Done()` and prints `"timed out"`.
At this point `ch` is no longer being read by anyone.
The goroutine inside `fetchData` is still sleeping; when it wakes up at T=2 s and tries to send `ch <- "result for ..."`, it blocks forever because nobody will ever receive from `ch`.
The goroutine is leaked --- it will never exit.

**The fix:** pass the context into `fetchData` so the goroutine can bail out early.

```go
func fetchData(ctx context.Context, url string) <-chan string {
    ch := make(chan string, 1) // buffered so the goroutine can send even if nobody reads
    go func() {
        select {
        case <-time.After(2 * time.Second):
            ch <- "result for " + url // send result if we finish in time
        case <-ctx.Done():
            // context was cancelled; exit cleanly without sending
        }
    }()
    return ch
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()

    ch := fetchData(ctx, "https://example.com/songs")
    select {
    case result := <-ch:
        fmt.Println(result)
    case <-ctx.Done():
        fmt.Println("timed out")
    }
}
```

Using a buffered channel of capacity 1 also guards against a secondary leak: if the result arrives after `main`'s `select` exits the `ctx.Done()` branch (a narrow race), the goroutine can still send on `ch` without blocking, and then exit.

---

**Exercise 5** (Write a program):

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"

    "golang.org/x/sync/errgroup"
)

// fanOutFetch fetches all song titles concurrently using errgroup.
// Each fetch is simulated with a random sleep between 50 and 150 ms.
// The function returns the titles in the same order as songs, or an error
// if the context is cancelled before all fetches complete.
func fanOutFetch(ctx context.Context, songs []string) ([]string, error) {
    results := make([]string, len(songs))
    g, ctx := errgroup.WithContext(ctx)

    for i, song := range songs {
        i, song := i, song // capture for Go < 1.22
        g.Go(func() error {
            delay := time.Duration(50+rand.Intn(100)) * time.Millisecond
            select {
            case <-time.After(delay):
                results[i] = "fetched: " + song
                return nil
            case <-ctx.Done():
                return ctx.Err()
            }
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}

func main() {
    songs := []string{
        "Gouryella",
        "Flaming June",
        "Saltwater",
        "Gamemaster",
    }

    ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
    defer cancel()

    results, err := fanOutFetch(ctx, songs)
    if err != nil {
        fmt.Println("error:", err)
        return
    }
    for _, r := range results {
        fmt.Println(r)
    }
}
```

**Explanation:**

`errgroup.WithContext` derives a new context from the one passed in.
If any goroutine returns a non-nil error, `errgroup` cancels that derived context, causing all other goroutines that are still sleeping to unblock on `ctx.Done()` and return `ctx.Err()`.
`g.Wait()` returns the first error.

Because the outer `context.WithTimeout` fires after 300 ms, any fetch whose random delay exceeds the remaining budget will be cancelled.
Fetches with delays in the 50--150 ms range should all complete well within 300 ms under normal conditions; set the timeout lower (e.g., 100 ms) to reliably trigger a cancellation in testing.

Sample output when all fetches succeed:
```
fetched: Gouryella
fetched: Flaming June
fetched: Saltwater
fetched: Gamemaster
```

Sample output when the timeout fires:
```
error: context deadline exceeded
```
