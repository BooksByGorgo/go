# Chapter 12: Synchronization --- Answers

**Exercise 1** (Think about it): Java's `synchronized` keyword locks an object's monitor, which is built into every Java object.
Go has no per-object monitor; instead you declare explicit `sync.Mutex` fields.
What are the practical advantages and disadvantages of each approach?
Consider: what happens when you need to protect two independent fields in the same struct, and how would you do it with each language's mechanism?

Java's per-object monitor is convenient for simple cases: every object already has a lock, so you can write `synchronized (this)` with no extra declarations.
The downside is that the monitor is coarse-grained --- there is only one per object.
If a struct (class in Java) has two independent fields that can be updated concurrently without affecting each other, locking the whole object monitor for either field creates unnecessary contention.
Java programmers work around this with separate `java.util.concurrent.locks.Lock` objects or by using a dedicated inner lock object:

```java
private final Object tracksLock = new Object();
private final Object playsLock  = new Object();

synchronized (tracksLock) { tracks.add(track); }
synchronized (playsLock)  { plays.increment(); }
```

Go's approach makes this natural: you simply declare two independent mutex fields.

```go
type Catalog struct {
    tracksMu sync.Mutex
    tracks   []string

    playsMu sync.Mutex
    plays   map[string]int
}
```

Each mutex protects only the field it is paired with, and neither blocks the other.
This is less magic but more explicit.

The practical advantages of Go's approach:

- **Granularity:** You can have as many independent mutexes as you need at zero structural cost.
- **Clarity:** The pairing between a mutex and the data it protects is visible in the struct definition.
- **No accidental sharing:** In Java, every synchronized method on the same object uses the same monitor, even if they protect unrelated state. In Go, each mutex is independent by default.

The practical disadvantage:

- **Verbosity:** You must declare, name, and document each mutex.
  Java's implicit monitor requires no declaration.
- **Copy hazard:** Go structs are value types. Copying a struct that contains a `sync.Mutex` is a bug; the struct must always be passed and stored by pointer.
  Java objects are always references, so this hazard does not exist.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    var once sync.Once
    var wg sync.WaitGroup
    results := make([]string, 3)

    for i := 0; i < 3; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            once.Do(func() {
                results[n] = "loaded"
            })
            if results[n] == "" {
                results[n] = "skipped"
            }
        }(i)
    }

    wg.Wait()
    loaded := 0
    skipped := 0
    for _, r := range results {
        if r == "loaded" {
            loaded++
        } else if r == "skipped" {
            skipped++
        }
    }
    fmt.Printf("loaded=%d skipped=%d\n", loaded, skipped)
}
```

The output is:

```
loaded=1 skipped=2
```

Here is why.

`sync.Once` guarantees that the function passed to `Do` runs **exactly once** across all goroutines.
One of the three goroutines (say goroutine with `n=0`, `n=1`, or `n=2` --- the scheduler decides which wins) will execute `results[n] = "loaded"`, setting one slot of the `results` slice.

The other two goroutines call `once.Do` as well, but their function bodies are silently dropped because the once is already done.
They proceed past `once.Do` and check `results[n] == ""` for their own slot `n`.
Because the winning goroutine wrote to a **different** index than these two, their slots are still empty, so they set `results[n] = "skipped"`.

The final tally is always exactly one `"loaded"` and two `"skipped"`, regardless of which goroutine wins the `once.Do` race.

Note: even though goroutines access different indices of `results` concurrently, this specific program is **not** a data race because each goroutine always writes to its own `results[n]` (where `n` is passed by value), and no two goroutines write to the same index.

---

**Exercise 3** (Calculation):

```go
var counter atomic.Int64
var wg sync.WaitGroup

for i := 0; i < 4; i++ {
    wg.Add(1)
    go func() {
        defer wg.Done()
        counter.Add(10)
    }()
}
wg.Wait()
fmt.Println(counter.Load())
```

**(a)** `counter.Load()` always prints `40`.

`atomic.Int64.Add` is an atomic read-modify-write operation.
No matter what order the four goroutines execute, each `Add(10)` is applied to the current value atomically, and all four additions will complete before `wg.Wait()` returns.
The final value is always 4 × 10 = 40.
This would **not** be true with a plain `int` counter and no synchronization --- that would be a data race with unpredictable results.

**(b)** Replacing `counter.Add(10)` with `counter.Add(int64(i))` introduces a **closure capture bug**.

The goroutine closure captures the **variable** `i`, not its value at the moment the goroutine was launched.
By the time the goroutines run, the loop may have already incremented `i` past the value it had when `go func()` was called.
In the worst case, all four goroutines see `i == 4` (the value after the loop ends) and print `4 * 4 = 16`.
In the best case, they each capture a different value (0, 1, 2, 3) and print 0 + 1 + 2 + 3 = 6.
Any value between 0 and 16 is possible, and the result is non-deterministic.

The fix is the same as described in Chapter 2 (closures): pass `i` as a parameter to the goroutine function.

```go
go func(n int) {
    defer wg.Done()
    counter.Add(int64(n))
}(i) // pass i by value here
```

With this fix the result is always 0 + 1 + 2 + 3 = 6.

---

**Exercise 4** (Where is the bug?):

```go
type SafeMap struct {
    mu sync.Mutex
    m  map[string]int
}

func NewSafeMap() SafeMap {
    return SafeMap{m: make(map[string]int)}
}

func (s SafeMap) Inc(key string) {
    s.mu.Lock()
    defer s.mu.Unlock()
    s.m[key]++
}

func (s SafeMap) Get(key string) int {
    s.mu.Lock()
    defer s.mu.Unlock()
    return s.m[key]
}
```

The bug is that `Inc` and `Get` have **value receivers** (`s SafeMap`), not pointer receivers (`s *SafeMap`).

When a method has a value receiver, Go passes a **copy** of the struct.
Each call to `Inc` locks the mutex in its own private copy --- a different mutex instance than the one in `sm` in `main`.
The lock is acquired and released on a throwaway copy, providing no mutual exclusion on the real `sm`.
One hundred goroutines therefore write to `sm.m["Butter"]` concurrently without any synchronization, which is a data race.

The map itself (`sm.m`) is a reference type, so the map operations do land on the shared map --- but they are completely unprotected, and concurrent writes to a Go map without synchronization is undefined behavior (the runtime will panic with a "concurrent map writes" message).

The fix is to use pointer receivers throughout:

```go
func (s *SafeMap) Inc(key string) {
    s.mu.Lock()
    defer s.mu.Unlock()
    s.m[key]++
}

func (s *SafeMap) Get(key string) int {
    s.mu.Lock()
    defer s.mu.Unlock()
    return s.m[key]
}
```

And in `main`, take the address of `sm` (or change `NewSafeMap` to return `*SafeMap`):

```go
func NewSafeMap() *SafeMap {
    return &SafeMap{m: make(map[string]int)}
}

func main() {
    sm := NewSafeMap() // *SafeMap; no copy needed
    ...
    sm.Inc("Butter")
    ...
    fmt.Println(sm.Get("Butter")) // 100
}
```

With pointer receivers and a pointer variable, every call to `Inc` and `Get` locks the **same** mutex, and the output is reliably `100`.

---

**Exercise 5** (Write a program): Implement a concurrent-safe `RateLimiter` struct that uses a `sync.Mutex` to protect a counter and a `time.Time` field tracking when the window resets.
The struct should have a method `Allow(n int) bool` that returns `true` if `n` tokens are available in the current one-second window, deducting them if so, and `false` otherwise (without deducting).
Write a `main` function that launches 10 goroutines, each calling `Allow(1)` in a loop 5 times, and prints how many calls were allowed versus denied across all goroutines combined.
Use `sync.WaitGroup` to wait for all goroutines to finish.

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
    "time"
)

// RateLimiter allows at most Limit tokens per one-second window.
type RateLimiter struct {
    mu      sync.Mutex
    limit   int
    used    int
    resetAt time.Time
}

func NewRateLimiter(limit int) *RateLimiter {
    return &RateLimiter{
        limit:   limit,
        resetAt: time.Now().Add(time.Second),
    }
}

// Allow returns true and deducts n tokens if they are available.
// It returns false without deducting if the window is exhausted.
func (r *RateLimiter) Allow(n int) bool {
    r.mu.Lock()
    defer r.mu.Unlock()

    now := time.Now()
    if now.After(r.resetAt) {
        r.used = 0
        r.resetAt = now.Add(time.Second)
    }

    if r.used+n > r.limit {
        return false
    }
    r.used += n
    return true
}

func main() {
    limiter := NewRateLimiter(25) // allow 25 calls per second
    var wg sync.WaitGroup
    var allowed, denied atomic.Int64

    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for j := 0; j < 5; j++ {
                if limiter.Allow(1) {
                    allowed.Add(1)
                } else {
                    denied.Add(1)
                }
            }
        }()
    }

    wg.Wait()
    fmt.Printf("allowed=%d denied=%d total=%d\n",
        allowed.Load(), denied.Load(), allowed.Load()+denied.Load())
}
```

Sample output (with a limit of 25 and 50 total calls):

```
allowed=25 denied=25 total=50
```

Key points of the implementation:

- The `sync.Mutex` in `RateLimiter` protects both `used` and `resetAt` together as a single invariant.
  Neither field can be read or written outside the lock.
- `Allow` checks the current time inside the lock so that the window reset and the token deduction are one atomic decision.
  If the check and the deduction were in separate lock acquisitions, another goroutine could sneak in between them.
- The `allowed` and `denied` counters in `main` use `atomic.Int64` rather than a mutex because they are independent single-variable updates --- a perfect atomic use case.
- `wg.Add(1)` is called in the outer loop, before the goroutine is launched, not inside the goroutine --- following the `WaitGroup` rule from the chapter.
