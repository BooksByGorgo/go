# Chapter 9: Goroutines and Channels --- Answers

**Exercise 1** (Think about it): Java's `Thread` and `Runnable` model requires you to think about thread pool sizing.
Go's goroutine model mostly frees you from this.
Explain the runtime mechanism that makes goroutines cheap enough to use one per task.
What cost, if any, do goroutines impose that Java threads do not, and when might you still want to limit the number of running goroutines?

The key mechanism is **M:N scheduling**: the Go runtime multiplexes M goroutines onto N OS threads, where N defaults to the number of CPU cores (`GOMAXPROCS`).
The scheduler lives in user space, so switching between goroutines does not require a kernel mode transition --- it is many times faster than a Java thread context switch.

Goroutines start with a ~2 KB stack that grows dynamically as needed (up to a configurable maximum, typically 1 GB).
Java threads allocate their full stack (512 KB to 1 MB) up front, from virtual memory at minimum.
This means creating a million goroutines consumes roughly 2 GB of initial stack memory; creating a million Java threads would require 500 GB to 1 TB.
In practice, the OS would refuse long before that.

**Costs goroutines impose:** Each goroutine is a heap allocation tracked by the scheduler.
At very high goroutine counts (hundreds of thousands) the scheduler itself becomes a bottleneck, and GC pressure increases because goroutine stacks are heap-allocated.
There is also some overhead per goroutine in the runtime's internal bookkeeping structures.

**When to still limit goroutines:** Any time the goroutines are doing I/O-bound work that creates downstream resource pressure --- for example, goroutines that each open a database connection or a file descriptor.
Even if the goroutines themselves are cheap, the external resources they consume (connections, file descriptors, memory for outbound HTTP requests) are not.
The common Go idiom for bounding concurrency is a buffered channel used as a semaphore, or the worker-pool pattern covered in Chapter 11.

---

**Exercise 2** (What does this print?):

```go
package main

import "fmt"

func main() {
    ch := make(chan int, 3)

    ch <- 7
    ch <- 13
    ch <- 21
    close(ch)

    for v := range ch {
        fmt.Println(v)
    }

    v, ok := <-ch
    fmt.Println(v, ok)
}
```

Output:
```
7
13
21
0 false
```

**Why:**

The channel has capacity 3, so all three sends succeed without blocking --- no goroutine is needed.
`close(ch)` marks the channel closed; the three buffered values are still available to receive.

`range ch` drains the channel in FIFO order, printing `7`, `13`, and `21`.
When the buffer is empty and the channel is closed, `range` terminates.

After the loop, `<-ch` receives from a channel that is both closed and empty.
The comma-ok idiom returns the **zero value** of the element type (`0` for `int`) and `false` for `ok`, because the channel is exhausted.
`fmt.Println(v, ok)` prints `0 false`.

This demonstrates two important rules: buffered values survive a `close`, and receiving from an empty closed channel always returns `(zero, false)` rather than blocking or panicking.

---

**Exercise 3** (Calculation): Consider the following program.
Trace its execution and determine the exact output.
How many goroutines are alive (other than `main`) when the final `fmt.Println` in `main` runs?

```go
package main

import "fmt"

func double(in <-chan int, out chan<- int) {
    for v := range in {
        out <- v * 2
    }
    close(out)
}

func main() {
    src := make(chan int, 3)
    dst := make(chan int, 3)

    src <- 3
    src <- 5
    src <- 8
    close(src)

    go double(src, dst)

    for result := range dst {
        fmt.Println(result)
    }
    fmt.Println("done")
}
```

Output:
```
6
10
16
done
```

**Trace:**

1. `src` is a buffered channel with capacity 3.
   The three sends (`3`, `5`, `8`) all succeed immediately without blocking.
   `src` is then closed.

2. `go double(src, dst)` launches `double` as a goroutine.
   `double` reads from `src` using `range`, which drains the buffered values `3`, `5`, `8` in order and then exits when `src` is empty and closed.
   For each value, it sends the doubled result to `dst` (also buffered with capacity 3, so no blocking occurs).
   After the loop, `double` calls `close(dst)`.

3. Back in `main`, `for result := range dst` drains `dst`.
   The values arrive in order: `6`, `10`, `16`.
   When `dst` is closed and empty, the loop ends.

4. `fmt.Println("done")` runs last.

**Goroutines alive when `fmt.Println("done")` runs:** Zero (other than `main`).
The `double` goroutine has already returned --- it finished draining `src`, called `close(dst)`, and exited before `main`'s `range dst` loop could finish (since `close(dst)` is what caused the loop to terminate).

---

**Exercise 4** (Where is the bug?):

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    var wg sync.WaitGroup
    results := make(chan string, 3)
    tracks := []string{"rockstar", "Circles", "Earfquake"}

    for _, t := range tracks {
        wg.Add(1)
        go func() {
            defer wg.Done()
            results <- "Playing: " + t
        }()
    }

    wg.Wait()
    close(results)

    for r := range results {
        fmt.Println(r)
    }
}
```

**The bug:** The goroutine closure captures the loop variable `t` by reference, not by value.
By the time the goroutines run, the `for` loop has advanced `t` to the last value in the slice.
All three goroutines read the same final value --- `"Earfquake"` --- and send it three times.
The output is likely:

```
Playing: Earfquake
Playing: Earfquake
Playing: Earfquake
```

This is the **loop-closure capture bug** described in Chapter 2.

**Why it happens:** In Go, the range variable `t` is a single variable whose value is updated on each iteration.
All three goroutines close over the same `t` variable (a single memory address), not over a copy of its value at the time the goroutine was launched.
Because the goroutines are scheduled after the loop completes, `t` holds the last assigned value when they execute.

**The fix:** Capture the value at goroutine launch time by passing it as a parameter to the anonymous function, or by introducing a local copy:

```go
for _, t := range tracks {
    t := t  // new variable scoped to this iteration
    wg.Add(1)
    go func() {
        defer wg.Done()
        results <- "Playing: " + t
    }()
}
```

Or equivalently, pass `t` as a function argument:

```go
for _, t := range tracks {
    wg.Add(1)
    go func(track string) {
        defer wg.Done()
        results <- "Playing: " + track
    }(t)
}
```

Both fixes capture the value of `t` at the point of goroutine creation so each goroutine gets its own independent copy.

Note: In Go 1.22 and later, range variables are per-iteration by default, which eliminates this class of bug automatically.
If you are on Go 1.22 or newer, the original code would work correctly.
On earlier versions, the fix is required.

---

**Exercise 5** (Write a program):

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch1 := make(chan string, 1)
    ch2 := make(chan string, 1)
    ch3 := make(chan string, 1)

    go func() {
        time.Sleep(10 * time.Millisecond)
        ch1 <- "Post Malone: Circles"
    }()
    go func() {
        time.Sleep(20 * time.Millisecond)
        ch2 <- "Tyler: Wilder World"
    }()
    go func() {
        time.Sleep(30 * time.Millisecond)
        ch3 <- "Post Malone: rockstar"
    }()

    received := 0
    total := 3
    for received < total {
        select {
        case msg := <-ch1:
            fmt.Println(msg)
            received++
        case msg := <-ch2:
            fmt.Println(msg)
            received++
        case msg := <-ch3:
            fmt.Println(msg)
            received++
        case <-time.After(100 * time.Millisecond):
            fmt.Println("timeout")
            received = total  // exit the loop
        }
    }
}
```

Output (order reflects goroutine sleep durations):
```
Post Malone: Circles
Tyler: Wilder World
Post Malone: rockstar
```

**How it works:**

Each goroutine sleeps for a different duration before sending on its dedicated channel.
`main` loops using `select`, blocking until any of the four cases is ready.
Because the goroutines sleep for 10 ms, 20 ms, and 30 ms, the messages arrive in that order.

The `time.After(100 * time.Millisecond)` case provides a safety net.
`time.After` returns a receive-only channel (`<-chan time.Time`) that the `time` package sends a value on after the specified duration.
If no message arrives within 100 ms, that case fires, prints `"timeout"`, and sets `received = total` to exit the loop.

A subtle point: `time.After` creates a new timer on every call to `select`, which is fine for correctness but slightly wasteful.
In production code that needs tight control over timer lifetimes, you would create a `time.NewTimer` once and reuse it.
That is a concern for Chapter 13; the `time.After` form is idiomatic for simple timeouts.
