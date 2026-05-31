\appendix

# Go Proverbs

\index{proverbs}

Rob Pike delivered a talk called *Go Proverbs* at Gopherfest in November 2015.
He listed a set of short, pithy sayings that capture the philosophy and idioms of Go --- not language rules, but ways of thinking that experienced Go programmers internalize over time.
If you search for "Rob Pike Go Proverbs" you will find the original talk and the companion site at [go-proverbs.github.io](https://go-proverbs.github.io).

The proverbs are memorable precisely because they are terse.
Each one encodes a design decision, a tradeoff, or a lesson learned from years of building large systems.
For Java programmers, several of them describe habits you need to actively unlearn.
This appendix states each proverb, unpacks what it means in practice, and connects it explicitly to the Java thinking it pushes back against.

## Don't communicate by sharing memory; share memory by communicating

\index{proverb!don't communicate by sharing memory}
\index{channel!communication}
\index{mutex}

This is the most famous Go proverb and the one that most directly contradicts the Java approach to concurrency.

In Java, the default concurrency model is shared mutable state.
Two threads access the same `ArrayList` or the same field, and you protect it with `synchronized`, `ReentrantLock`, or a `volatile` keyword.
The data lives in one place; the threads fight to access it; the locks prevent corruption.

Go's preferred model flips this around.
Instead of giving both goroutines a reference to the same piece of data and then locking it, you give the data to one goroutine and send it through a channel when another goroutine needs it.
At any moment, only one goroutine owns the data --- ownership transfers through communication, not through locking.

```go
// Java-style thinking in Go: don't do this
var counter int
var mu sync.Mutex

func increment() {
    mu.Lock()
    counter++
    mu.Unlock()
}

// Go-style thinking: send the work, not the shared state
jobs := make(chan int, 100)

go func() {
    total := 0
    for n := range jobs {
        total += n
    }
    fmt.Println(total)
}()

for i := 0; i < 100; i++ {
    jobs <- i
}
close(jobs)
```

The second version has no lock, no shared variable visible to multiple goroutines, and no data race.
The accumulator `total` is private to one goroutine; the channel is the communication mechanism.

::: {.tip}
**Tip:** The Go memory model guarantees that a send on a channel *happens before* the corresponding receive.
This means the channel itself acts as synchronization --- you do not need a separate lock when you use channels correctly.
:::

::: {.tip}
**Trap:** This proverb does not mean "never use `sync.Mutex`."
Mutexes are the right tool when a small critical section protects a shared counter or cache.
The proverb is about *default thinking*: reach for channels first when goroutines need to coordinate.
:::

## Concurrency is not parallelism

\index{proverb!concurrency is not parallelism}
\index{concurrency}
\index{parallelism}

Java programmers often use "concurrent" and "parallel" as synonyms.
Go draws a sharp distinction.

**Concurrency** is a property of program structure: you decompose a problem into independent pieces that *could* run simultaneously.
**Parallelism** is a property of execution: those pieces *actually* run simultaneously on multiple CPU cores.

A concurrent program written for a single-core machine will not run in parallel, but it is still concurrent --- the pieces are structured to be independent.
Conversely, you can run a non-concurrent program on many cores and get no benefit.

::: {.tip}
**Tip:** Rob Pike's memorable formulation is: "Concurrency is about *dealing with* lots of things at once.
Parallelism is about *doing* lots of things at once."
Write concurrent code first.
The runtime decides how much parallelism you get based on `GOMAXPROCS`.
:::

Goroutines give you concurrency cheaply.
How much parallelism you get is controlled by `runtime.GOMAXPROCS`, which defaults to the number of CPU cores.
You almost never set it manually --- the default is right.

The practical lesson for Java programmers: the goal of channels and goroutines is clean problem decomposition, not raw throughput.
A pipeline of three goroutines connected by channels is concurrent design even if it runs on one core.

## The bigger the interface, the weaker the abstraction

\index{proverb!bigger interface weaker abstraction}
\index{interface!size}

In Java, interfaces commonly carry dozens of methods.
`java.util.List` has 25 methods; `java.util.Collection` has 15.
Implementing them requires either a large amount of code or inheriting a skeletal implementation.

Go's standard library tells a different story.
`io.Reader` has one method.
`io.Writer` has one method.
`fmt.Stringer` has one method.
`error` has one method.

A one-method interface describes exactly one capability.
Anything that satisfies it --- a file, a network connection, a byte buffer, a custom type --- can be used wherever that interface is expected.
The abstraction is maximally general.

When an interface grows to ten methods, only a much narrower set of types can satisfy it.
The interface describes a specific *kind of thing* rather than a specific *capability*.
It has become less of an abstraction and more of a blueprint for a single concrete type.

```go
// Weak abstraction: only one type will ever implement this
type DatabaseService interface {
    Connect(dsn string) error
    Query(sql string, args ...any) (*Rows, error)
    Exec(sql string, args ...any) (Result, error)
    Begin() (*Tx, error)
    Rollback() error
    Commit() error
    Close() error
    Ping() error
    Stats() DBStats
}

// Strong abstraction: anything that can store a byte slice
type Storer interface {
    Store(key string, value []byte) error
}
```

::: {.tip}
**Tip:** When designing a Go interface, ask: "What is the *minimum* set of methods a caller actually needs?"
Often the answer is one or two.
Define the small interface at the call site rather than defining a large interface in the package that owns the implementation.
:::

## Accept interfaces, return concrete types

\index{proverb!accept interfaces return concrete types}
\index{interface!function parameters}

This proverb describes the idiomatic direction of abstraction in Go function signatures.

**Accept interfaces** because it makes your function flexible.
A function that accepts `io.Reader` works with a file, a byte buffer, a network socket, a gzip stream, or a test mock --- anything that implements `Read`.
The caller is not locked into a specific type.

**Return concrete types** because it gives the caller maximum information.
If your function returns `*os.File`, the caller can call `Stat`, `Seek`, `Sync`, and `Close`.
If you return `io.ReadCloser`, the caller can only `Read` and `Close`.
Returning an interface hides capability the caller might need.

```go
// Good: accepts interface (flexible), returns concrete type (informative)
func NewLoggedReader(r io.Reader) *LoggedReader {
    return &LoggedReader{r: r, count: 0}
}

// Avoid: returning an interface when the concrete type is more useful
func NewLoggedReader(r io.Reader) io.Reader { // loses access to Count()
    return &LoggedReader{r: r, count: 0}
}
```

::: {.tip}
**Trap:** Java programmers coming from "program to an interface, not an implementation" often want to return interface types everywhere.
In Go that habit hides the concrete type's full API from callers.
Return the concrete type; let the caller decide which interface to assign it to.
:::

The exception is the `error` interface: always return `error`, not a concrete error type, so callers use `errors.Is` and `errors.As` instead of type-asserting against a specific struct.

## Make the zero value useful

\index{proverb!zero value useful}
\index{zero value}

In Java, objects do not exist until you call a constructor.
Using an uninitialized field (null) causes a `NullPointerException`.
Java programmers habitually write defensive constructors and factory methods to ensure objects are always in a valid state.

In Go, every type has a **zero value** --- the value you get when you declare a variable without initializing it.
Numeric types zero to `0`, booleans to `false`, pointers to `nil`, strings to `""`, and struct fields to their respective zero values.

The proverb asks you to design your types so the zero value is *already useful*, not broken.

```go
var b bytes.Buffer        // zero value: empty buffer, ready to use
b.WriteString("Espresso") // no constructor needed

var mu sync.Mutex         // zero value: unlocked mutex, ready to use
mu.Lock()

var wg sync.WaitGroup     // zero value: counter at zero, ready to use
wg.Add(1)
```

None of these required a constructor call.
`bytes.Buffer`, `sync.Mutex`, and `sync.WaitGroup` are all designed so the zero value is fully operational.

::: {.tip}
**Tip:** When designing a new type, ask: "Is the zero value of this struct a sensible default state?"
If you can arrange for it to be, callers get a simpler API --- no constructor required, and no possibility of an "uninitialized" state.
:::

::: {.tip}
**Trap:** Pointers in Go zero to `nil`, just like Java references.
Calling a method on a nil pointer panics.
If your type relies on a pointer field being non-nil, either initialize it lazily on first use or document that the zero value is not usable and require a constructor.
:::

## The empty interface says nothing

\index{proverb!empty interface says nothing}
\index{interface!empty}
\index{any}

In Go, `interface{}` (written `any` since Go 1.18) is an interface with no methods.
Every type satisfies it.
A function that accepts `any` can receive literally anything --- an `int`, a `string`, a goroutine channel, a function value, a `nil`.

This flexibility is a warning sign, not a feature.
If you accept `any`, you have told the compiler nothing about what you intend to do with the value.
You will need a type assertion or a type switch to extract something useful, and that work happens at runtime with no compile-time safety.

```go
// Loses type safety; requires runtime type assertions
func PrintValue(v any) {
    switch x := v.(type) {
    case int:
        fmt.Println("int:", x)
    case string:
        fmt.Println("string:", x)
    default:
        fmt.Printf("unknown: %T\n", v)
    }
}

// Better: use a specific interface or generics (Go 1.18+)
func PrintStringer(v fmt.Stringer) {
    fmt.Println(v.String())
}
```

::: {.tip}
**Trap:** Java programmers who are used to `Object` as the universal base class reach for `any` when they want "any type."
In Go that is rarely the right answer.
Use a concrete type, a narrow interface, or a generic type parameter instead.
Reserve `any` for truly generic infrastructure like JSON serialization or logging frameworks where the type is genuinely unknown.
:::

## Errors are values

\index{proverb!errors are values}
\index{error!as value}

In Java, error signaling means throwing an exception --- an interruption of the normal control flow that unwinds the call stack.
The exception is caught somewhere above and the normal path and the error path are syntactically separate (`try` vs `catch`).

In Go, a function that can fail returns an `error` as an ordinary return value.
There is no stack unwinding, no separate exception handling syntax, and no checked-versus-unchecked distinction.
The error is just a value you assign to a variable and inspect with `if err != nil`.

Because errors are values, you can do everything with them that you can do with any other Go value: store them in a slice, pass them to a function, wrap them, compare them, build pipelines around them.

```go
// Errors as values enable this pattern: chain calls, accumulate the first error
type Writer struct {
    w   io.Writer
    err error
}

func (ew *Writer) write(p []byte) {
    if ew.err != nil {
        return
    }
    _, ew.err = ew.w.Write(p)
}

// Callers write without checking each time; check once at the end
ew := &Writer{w: os.Stdout}
ew.write(header)
ew.write(body)
ew.write(footer)
if ew.err != nil {
    log.Fatal(ew.err)
}
```

::: {.tip}
**Tip:** The Go blog post "Errors are Values" by Rob Pike (2015) shows this pattern in detail and demonstrates that "if err != nil" repetition is not inherent --- it is a consequence of how you structure the code.
:::

## Don't just check errors, handle them gracefully

\index{proverb!handle errors gracefully}
\index{error!handling}

This proverb follows directly from the previous one.
Because errors are values, you are responsible for deciding what to do with them.

Java programmers sometimes carry over two habits that do not translate well to Go:

1. Catching an exception and logging it before re-throwing, which adds noise without adding information.
2. Swallowing an error silently (catching `Exception` and doing nothing).

In Go, "handle gracefully" means: add context, decide whether to retry or abort, clean up resources, and propagate with enough information for the caller to make a decision.

```go
// Bad: ignore the error
data, _ := os.ReadFile("config.json")

// Bad: check but do nothing useful
data, err := os.ReadFile("config.json")
if err != nil {
    fmt.Println(err) // log and fall through; data is nil
}

// Good: add context, propagate clearly
data, err := os.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("loading config: %w", err)
}
```

Wrapping with `%w` preserves the original error so callers can use `errors.Is` or `errors.As` to inspect it.
Each layer adds its own context to the chain without hiding what happened.

::: {.tip}
**Trap:** Do not log an error *and* return it.
That causes the same error to be logged multiple times at different layers.
Either handle the error fully at one level (log it and stop propagating) or wrap and return it for the caller to handle.
:::

## A little copying is better than a little dependency

\index{proverb!copying better than dependency}
\index{dependency!avoiding}

In the Java ecosystem, adding a Maven or Gradle dependency is almost zero-friction.
The build system downloads transitive dependencies automatically, and the culture encourages reuse at the package level.
The result is dependency trees hundreds of packages deep for trivial utilities.

Go takes a more cautious position.
The module system (`go.mod`) makes dependencies explicit, and the community norm is to pull in a dependency only when the benefit clearly outweighs the cost of tracking it, auditing it for security, and waiting for it to update.

When you need ten lines of utility code from a package, consider copying those ten lines instead of adding the whole package as a dependency.
The copied code is stable, auditable, and has no surprise transitive dependencies.

```go
// Instead of importing a string utilities package for one function,
// copy the five-line helper you actually need:

// containsAny reports whether s contains any Unicode code point in chars.
func containsAny(s, chars string) bool {
    for _, c := range chars {
        if strings.ContainsRune(s, c) {
            return true
        }
    }
    return false
}
```

::: {.tip}
**Tip:** The Go standard library is intentionally rich so that most common tasks do not require third-party dependencies.
Before adding a dependency, scan `strings`, `bytes`, `slices`, `maps`, `sort`, `strconv`, and `unicode` --- the answer is often already there.
:::

::: {.tip}
**Wut:** This proverb applies to *small* utilities.
For a full TLS implementation, a database driver, or an HTTP client framework, copying is obviously not the answer.
The proverb targets the temptation to add a 50-package dependency to get one helper function.
:::

## Clear is better than clever

\index{proverb!clear is better than clever}
\index{readability}

Go was designed for large teams and long-lived codebases.
The person who reads your code in two years might be you after you have forgotten what it does, or a colleague who joined the project last week.

"Clever" code --- one-liners that pack multiple side effects into a single expression, or intricate use of the type system to eliminate a few lines of boilerplate --- imposes a cognitive tax on every future reader.
"Clear" code says what it does, even if it takes a few extra lines.

```go
// Clever: hard to see that this initializes and conditionally overwrites
x := map[string]int{"a": 1, "b": 2}["b"]

// Clear: two lines, obvious intent
m := map[string]int{"a": 1, "b": 2}
x := m["b"]
```

::: {.tip}
**Tip:** Go's `gofmt` enforces a uniform style so that no one spends mental energy on formatting.
The remaining style decisions --- naming, structure, abstraction level --- should all favor the reader.
If you find yourself writing a comment to explain what a line of code does, consider rewriting the code so the comment is unnecessary.
:::

Java programmers who have spent time with lambda chains, streams, and optional-chaining sometimes find Go's explicit loops and `if err != nil` checks verbose.
Over time most find the verbosity pays for itself in debuggability and readability.

## gofmt's style is no one's favorite, yet gofmt is everyone's favorite

\index{proverb!gofmt style}
\index{gofmt}

`gofmt` is Go's canonical formatter.
It rewrites your source code to match the one true style: tab indentation, specific brace placement, aligned spacing, consistent blank lines.
You have no configuration options.

No one gets exactly the style they would choose if left to their own preferences --- that is the point.
Because the style is universal and non-negotiable, no one argues about it.
Code review time is not spent on formatting.
Merge conflicts over whitespace disappear.
Every Go file in every repository in the world looks structurally the same.

```go
// You write:
func add(a int,b int)int{return a+b}

// gofmt produces:
func add(a int, b int) int { return a+b }
```

::: {.tip}
**Tip:** Run `gofmt -w .` before committing, or configure your editor to run it on save.
Most Go projects enforce `gofmt` compliance in CI and reject code that is not formatted.
The `goimports` tool does everything `gofmt` does and also manages import blocks.
:::

Java programmers accustomed to negotiating Checkstyle or Google Java Format rules with their team will appreciate that in Go the negotiation never happens.

## Cgo is not Go

\index{proverb!cgo is not Go}
\index{cgo}

Cgo is the mechanism that lets Go code call C libraries.
It is powerful and sometimes necessary --- for system-level APIs or existing C codebases --- but it comes with a significant cost.

Code that uses Cgo does not compile with the same toolchain as pure Go code.
Cross-compilation becomes complicated.
Build times increase.
The garbage collector and the C memory allocator coexist awkwardly.
Goroutine stacks cannot grow through Cgo frames.
Debugging is harder.

The proverb is a reminder that reaching for Cgo means stepping outside the Go ecosystem and accepting all of its constraints.
For most application code, a pure Go alternative exists.

::: {.tip}
**Wut:** Java programmers are familiar with JNI, which carries similar complexity costs.
The Go community's attitude toward Cgo mirrors the Java community's attitude toward JNI: use it when you must, avoid it when you can.
:::

## Cgo must always be guarded with build constraints

\index{proverb!cgo build constraints}
\index{build constraint!cgo}

When you do use Cgo, you must tell the Go build system which platforms your C code supports.
Without build constraints, your package will fail to compile on any platform where the C toolchain is absent or where the C code does not compile.

Build constraints live at the top of the file:

```go
//go:build linux && amd64

package mypackage

// #include <sys/mman.h>
import "C"
```

This constraint restricts the file to Linux on AMD64.
The rest of your package can still be compiled everywhere; only this file is gated.

::: {.tip}
**Tip:** Use `//go:build` (the modern syntax, Go 1.17+) rather than the older `// +build` comment.
Run `go build ./...` for a representative set of target platforms in CI to catch constraint gaps early.
:::

## Syscall must always be guarded with build constraints

\index{proverb!syscall build constraints}
\index{build constraint!syscall}
\index{syscall package}

The `syscall` package exposes operating-system system calls directly.
System calls are platform-specific: the numbers, arguments, and available calls differ between Linux, macOS, Windows, and other platforms.

A file that calls `syscall.Mmap` or `syscall.SIGTERM` will fail to compile on a platform where that call does not exist or has a different signature.
Build constraints ensure the file is only compiled on the platforms it supports.

```go
//go:build linux || darwin

package fileutil

import "syscall"

func lockFile(fd uintptr) error {
    return syscall.Flock(int(fd), syscall.LOCK_EX)
}
```

::: {.tip}
**Trap:** Java programmers are used to the JVM abstracting away platform differences.
In Go, once you use `syscall` or `golang.org/x/sys`, you own the platform compatibility problem.
Prefer higher-level standard library packages (`os`, `net`, `io`) that handle platform differences internally.
:::

## With the unsafe package there are no guarantees

\index{proverb!unsafe no guarantees}
\index{unsafe package}

The `unsafe` package lets you escape Go's type system: convert between pointer types, read the size of a value, perform pointer arithmetic.
Using it bypasses the memory safety guarantees that make Go programs reliable.

There is no specification for what `unsafe` code will do across Go versions, architectures, or runtime implementations.
Code that works today may break on the next Go release, on a different OS, or with a different garbage collector.

```go
import "unsafe"

// This compiles, but violates Go's memory model.
// The garbage collector may move objects; this pointer may become invalid.
p := (*int)(unsafe.Pointer(uintptr(unsafe.Pointer(&x)) + unsafe.Sizeof(x)))
```

::: {.tip}
**Trap:** Java programmers who have used `sun.misc.Unsafe` know this territory.
The pattern is the same: you get power, you lose guarantees, and you own all the consequences.
In Go, `unsafe` is almost never needed in application code.
The standard library and well-maintained packages handle the rare cases --- binary serialization, memory-mapped I/O --- where direct memory access is genuinely required.
:::

## Reflection is never clear

\index{proverb!reflection never clear}
\index{reflection}
\index{reflect package}

The `reflect` package lets you inspect and manipulate values at runtime without knowing their types at compile time.
It powers `encoding/json`, `fmt`, and `text/template`.
It is essential infrastructure.
It is also notoriously difficult to read and debug.

Reflection code trades compile-time type checking for runtime flexibility.
Errors that a compiler would catch become panics at runtime.
The code path through a reflective call is opaque to the reader.

```go
// Clear: the compiler knows the type, the reader knows the type
n := len(mySlice)

// Unclear: works, but why? what type is v? what if Kind() is wrong?
v := reflect.ValueOf(mySlice)
n := v.Len()
```

::: {.tip}
**Tip:** Before reaching for `reflect`, check whether generics (Go 1.18+) solve your problem.
A generic function preserves type safety and is readable.
Reflection is appropriate for cases where the types are genuinely unknown at compile time --- serialization, testing frameworks, dependency injection containers.
:::

::: {.tip}
**Trap:** Java programmers with a Spring or Hibernate background are accustomed to frameworks that do heavy annotation processing and reflection under the hood.
That is fine in frameworks you use but do not read.
In Go application code, reflective paths are yours to own and debug.
Keep them small, well-tested, and isolated from the rest of the codebase.
:::
