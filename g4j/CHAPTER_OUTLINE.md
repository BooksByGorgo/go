# Chapter Outline

Source: CONCEPTS_AND_IDIOMS.md
Audience: Java programmers learning Go for industry use

---

## Chapter 0: How to Use This Booklet
*Conventions used throughout the book --- read this first.*

- Code review rules --- the `[rule-name]` markers used in the text point to Appendix C
- Idioms, `Tip`/`Trap`/`Wut` callouts, and how function signatures are presented
- Chapter layout --- intro, body, `Try It`, key points, exercises; separate answer key

---

## Part I: Getting Off the Ground

### Chapter 1: Hello, Go
*Java programmers can write code immediately; this chapter maps familiar Java concepts to Go syntax.*

- Program structure --- `package main`, `func main()`, no class required
- `import` vs Java imports; grouped import blocks; blank import for side effects
- `go run`, `go build`, `go install`
- `go mod init` --- your first module; `go.mod` and `go.sum`
- Exported vs unexported identifiers (capitalization, not `public`/`private`)
- The `fmt` package --- `Println`, `Printf`, `Sprintf`, `Fprintf`, reading input (`Scan`/`Scanln`), format verbs
- Command-line arguments --- `os.Args[0]` is the binary; `os.Args[1:]` are the user's arguments

### Chapter 2: Types and Variables
*Go's type system is familiar but has several sharp distinctions from Java --- including structs and explicit pointers.*

- Basic types: `int`, `int8/16/32/64`, `uint*`, `float32/64`, `bool`, `string`, `byte`, `rune`
- `var` declarations and `:=` short declarations; when to use each
- Zero values --- every type has a meaningful zero; no null pointer surprises
- `const` and `iota` --- typed and untyped constants, enumeration patterns
- Type definitions vs type aliases (`type Celsius float64` vs `type = float64`)
- Explicit type conversions (`T(x)`) --- no implicit numeric coercion between types
- `new` --- `new(T)` returns a zeroed `*T`; `make` initializes slices, maps, and channels (covered in Chapters 7 and 10)
- Integer literal prefixes: `0b`, `0o`, `0x`; `_` digit separator
- `clear`, `min`, `max` built-ins (Go 1.21)
- Blank identifier (`_`)
- Structs --- struct literals, value semantics (methods and embedding come in Chapter 6)
- Pointers --- `&` (address-of), `*` (dereference); nil pointer; no pointer arithmetic

### Chapter 3: Strings, Bytes, and Runes
*Java's `char` is a UTF-16 code unit; Go's `rune` is a full Unicode code point. This matters.*

- Strings are immutable byte sequences; `len(s)` counts bytes, not characters
- `byte` (`uint8`) vs `rune` (`int32`); `s[i]` yields a byte
- `for range` over a string decodes UTF-8 runes; plain `for i` iterates bytes
- Raw string literals (backticks); rune literals (`'⌘'`)
- `strings` package: `Builder`, `Contains`, `Split`, `Join`, `TrimSpace`, `HasPrefix`
- `strconv`: `Itoa`, `Atoi`, `ParseFloat`, `FormatFloat`
- `bytes` package: mirrors `strings` for `[]byte`; `bytes.Buffer`
- `unicode/utf8`: `RuneCountInString`, `DecodeRuneInString`, `ValidString`

### Chapter 4: Control Flow
*`for` is the only loop. `switch` does not fall through. `defer` has no Java equivalent.*

- `if` / `else` --- same as Java; short init statement (`if err := f(); err != nil`)
- `for` --- the only loop; C-style, range, while-style, infinite
- `range` over slices, maps, strings, channels, integers (Go 1.22), iterators (Go 1.23)
- `switch` --- no `fallthrough` by default; expression-less `switch`; type switch preview
- `fallthrough` --- explicit, unconditional transfer; Java programmers expect the opposite
- Labeled `break` / `continue` --- Go's substitute for Java's labeled loops
- `goto` --- exists; niche
- `defer` --- LIFO order, runs on function exit; captures variables by reference
- `init()` --- runs before `main`; multiple allowed per file; execution order

---

## Part II: Go's Type System

### Chapter 5: Functions
*Multiple return values, closures, and first-class functions replace most Java callback boilerplate.*

- Multiple return values --- the primary error-handling mechanism
- Named return values --- useful for documentation and `defer`-modified returns
- Variadic functions (`...T`); passing a slice with `s...`
- First-class functions --- function types, function variables
- Closures --- capturing variables by reference; common gotcha in loop closures
- `init()` revisited --- ordering guarantees across files and packages
- Function types as parameters --- callbacks, dispatch tables, middleware, the strategy pattern
- Pointer vs value semantics --- pass-by-value, when mutation requires a pointer, reference-like types
- Escape analysis --- stack vs heap; `new(T)` and `&T{}` are equivalent; inspecting decisions with `-gcflags=-m`

### Chapter 6: Objects using Methods and Embedding
*Go separates data, behavior, and code reuse. Methods are declared outside struct bodies; constructors are plain functions; embedding replaces inheritance.*

- Receiver syntax --- value receivers and pointer receivers; method sets; calling methods
- Methods on non-struct named types --- any named type (including function and slice types) can have methods
- File organization --- methods can be in any file in the package; one file per type is a common convention
- `New*` constructor functions --- the Go convention replacing `new ClassName()`; constructors that validate
- Resource cleanup with `defer` instead of destructors; `runtime.SetFinalizer` (and why to avoid it)
- Embedding --- field and method promotion; embedded value vs embedded pointer; name collisions
- Embedding vs inheritance --- composition, not substitutability; how interfaces fill the gap


### Chapter 7: Maps and Slices
*Go maps replace Java `HashMap`; Go slices replace `ArrayList`. Both are value-oriented and built into the language.*

- Map literals, `make(map[K]V)`, operations (`m[k]`, delete, len)
- Comma-ok idiom: `v, ok := m[key]`
- Iteration order is random (by design)
- `clear` on a map --- deletes all entries
- Arrays --- value types, fixed size; `[3]int` vs `[]int`
- Slices --- pointer + length + capacity triplet; the backing array
- `make([]T, len, cap)`, `append`, `copy`
- Three-index slices `a[low:high:max]` --- capping capacity to prevent accidental sharing
- Slice aliasing --- re-slicing shares the backing array; when to `copy`
- Multidimensional slices
- `slices` package (Go 1.21): `Sort`, `SortFunc`, `Contains`, `Index`, `Compact`, `Collect`
- `clear` on a slice --- zeroes elements without changing length

### Chapter 8: Interfaces
*Go interfaces are satisfied implicitly. No `implements`. This changes everything.*

- Implicit interface satisfaction --- any type with the right methods satisfies an interface
- Interface composition (`io.ReadWriter` from `io.Reader` + `io.Writer`)
- `any` (`interface{}`) --- the top type; use sparingly
- Type assertions: `x.(T)`, panic form vs comma-ok form
- Type switches: `switch v := i.(type)`
- Key standard interfaces: `io.Reader`, `io.Writer`, `fmt.Stringer`, `error`, `sort.Interface`
- "Accept interfaces, return structs" idiom
- Interface nil traps --- typed nil vs untyped nil; the classic gotcha

---

## Part III: Error Handling

### Chapter 9: Error Handling
*Go has no exceptions. Errors are values returned from functions. This is the biggest mindset shift.*

- `error` is an interface: `Error() string`
- Convention: return `error` as the last value; check immediately
- `errors.New`, `fmt.Errorf`, `fmt.Errorf` with `%w` for wrapping
- `errors.Is` and `errors.As` --- unwrapping error chains; replacing `instanceof`
- `errors.Join` (Go 1.20) --- combine multiple errors; validation patterns
- Sentinel errors --- `io.EOF`, `sql.ErrNoRows`; comparing with `errors.Is`
- Custom error types --- implement `error`; add context fields
- `panic` / `recover` --- not for normal control flow; reserved for truly unrecoverable state
- The `must` idiom --- helper that panics on error; used at startup for things that must not fail
- Go proverbs: "Errors are values"; "Don't just check errors, handle them gracefully"

---

## Part IV: Concurrency

### Chapter 10: Goroutines and Channels
*Goroutines are not threads. Channels are not queues. The model is different from Java.*

- Goroutines --- `go f()`; lightweight, multiplexed onto OS threads
- Goroutines vs Java threads --- stack size, scheduling, cost
- Channels --- typed, synchronization built in; `make(chan T)`, `make(chan T, n)`
- Buffered vs unbuffered channels; directional types (`chan<-`, `<-chan`)
- Closing a channel --- only the sender closes; receiving from closed returns zero + false; sending to closed panics
- `select` statement --- fan-in, timeouts, non-blocking send/receive with `default`
- "Don't communicate by sharing memory; share memory by communicating"

### Chapter 11: Synchronization
*When channels are not the right tool, the `sync` package provides the primitives.*

- Go memory model --- visibility between goroutines; happens-before relationships
- `sync.Mutex` and `sync.RWMutex` --- same role as Java `synchronized`
- `sync.WaitGroup` --- fan-out/fan-in without a channel; `WaitGroup.Go` (Go 1.25)
- `sync.Once` --- lazy initialization; replaces double-checked locking
- `sync.Cond` --- condition variables; broadcast wakeup and state-change coordination
- `sync/atomic` --- typed atomics (Go 1.19+): `atomic.Int64`, `atomic.Pointer[T]`
- Race detector: `go test -race`; run in CI always

### Chapter 12: Context and Concurrency Patterns
*`context.Context` is how you cancel work across goroutine boundaries.*

- `context.Context` --- cancellation, deadlines, timeouts, value propagation
- `context.WithCancel`, `context.WithTimeout`, `context.WithDeadline`
- `context.WithValue` --- use unexported key types to prevent collisions; anti-pattern of string keys
- Context as first parameter convention: `func Foo(ctx context.Context, ...)`
- `golang.org/x/sync/errgroup` --- fan-out with error collection and context cancellation
- Goroutine leak detection --- every goroutine must have an exit path; `goleak` in tests
- `GOMAXPROCS` --- OS thread count; defaults to CPU count
- Worker pool --- bounded goroutines draining a jobs channel
- Rate limiting --- `time.Ticker` and token-bucket pacing of work

---

## Part V: The Ecosystem

### Chapter 13: Packages and Modules
*Go modules replace Maven/Gradle. The conventions are simpler but different.*

- Package naming --- short, lowercase, no underscores; package name matches directory
- Exported vs unexported symbols (recap)
- `go.mod` and `go.sum` --- `module`, `require`, `replace` (local overrides / forks)
- `go get`, `go mod tidy`, `go mod vendor`
- Internal packages (`internal/`) --- compiler-enforced visibility restriction
- Standard project layout: `cmd/` for executables, `internal/` for private packages
- Go workspaces (`go work`) --- multi-module local development without `replace`
- Major version suffixes --- `module github.com/foo/bar/v2`; import path includes `/v2`
- Build tags / build constraints
- `//go:embed` --- embed static files into the binary at compile time

### Chapter 14: Essential Standard Library
*A tour of the packages every Go programmer reaches for daily.*

- `fmt` --- verbs, `%v`, `%+v`, `%#v`, `%T`, `Fprintf` to any `io.Writer`
- `io` --- `Reader`, `Writer`, `ReadAll`, `Copy`; composition: `MultiReader`, `MultiWriter`, `TeeReader`, `LimitReader`, `Pipe`
- `bufio` --- `Scanner`, `NewReader`, `NewWriter`; buffering arbitrary `io.Reader`/`io.Writer`
- `os` --- `Open`, `Create`, `ReadFile`, `WriteFile`, `Args`, `Stdin/Stdout/Stderr`, `Getenv`
- `os/exec` --- `exec.Command`, `Cmd.Output`, `Cmd.Run`, piping stdio
- `flag` --- standard CLI flag parsing
- `time` --- `Duration`, `Time`, `Now`, `Since`, `After`, `Ticker`, `Timer`
- `path/filepath` --- cross-platform path manipulation
- `log/slog` (Go 1.21) --- structured logging: levels, `TextHandler`/`JSONHandler`, `LevelVar`, `SetDefault`, `slog.With`, `slog.Group`
- `regexp` --- compile once, use many times
- `cmp` (Go 1.21) --- `cmp.Compare`, `cmp.Or`; three-way comparison
- `maps` (Go 1.21) --- `Clone`, `Keys` (and the other map utilities)
- `iter` (Go 1.23) --- `iter.Seq`/`iter.Seq2`, range-over-func, `iter.Pull`
- `encoding/base64` --- `StdEncoding`, `URLEncoding`, `RawStdEncoding`, `RawURLEncoding`
- `crypto/rand` --- cryptographically secure random bytes; `math/rand/v2` for non-cryptographic use
- `crypto/sha256`, `crypto/aes`, `crypto/cipher` --- SHA-256 hashing; AES-256-GCM authenticated encryption

### Chapter 15: JSON, HTTP, and the Web
*`encoding/json` and `net/http` are the backbone of Go web services.*

- `encoding/json` --- `Marshal`, `Unmarshal`, streaming `Encoder`/`Decoder`, `DisallowUnknownFields`
- Struct tags for JSON: `json:"name,omitempty"`, `json:"-"`; tag mechanics
- `net/http` server --- `http.Handler`, `http.HandlerFunc`, `ListenAndServe`
- Go 1.22 `ServeMux` --- method routing (`GET /path/`), path wildcards (`/songs/{id}/`), `r.PathValue`
- Middleware chaining --- wrapping `http.Handler` for logging, auth, metrics; the `chain` helper
- Live profiling with `net/http/pprof` --- blank import registers `/debug/pprof/`; `go tool pprof -http`; keep off public ports
- `net/http` client --- `http.Get`, `http.Client`, `http.NewRequest`, response body must be closed
- `encoding/xml` --- XML marshalling; same tag mechanism as JSON
- `net` --- `net.Dial`, `net.Listen`, `net.Conn` (an `io.Reader`/`io.Writer`); TCP/UDP below the HTTP layer
- `crypto/tls` --- `http.ListenAndServeTLS`, `tls.Config`, custom CA trust; `tls.Dial`/`tls.Listen` for raw TLS

### Chapter 16: Database Access
*`database/sql` is Go's JDBC. Connection pooling is built in.*

- `sql.DB` --- connection pool, not a connection; safe for concurrent use
- `db.QueryContext`, `db.QueryRowContext`, `db.ExecContext` --- always use context variants
- `sql.Rows.Scan` --- scanning results into Go variables
- `sql.Tx` --- transactions; `Commit`, `Rollback`, deferred rollback pattern
- Prepared statements --- `db.PrepareContext`
- `sql.Null[T]` (Go 1.22) --- nullable column values
- Driver registration --- `import _ "github.com/lib/pq"` side-effect import pattern
- pgx (`github.com/jackc/pgx/v5`) --- idiomatic PostgreSQL driver; `pgxpool` for connection pooling

---

## Part VI: Advanced Go

### Chapter 17: Generics
*Go generics (1.18) are deliberately minimal. Know what they can and cannot do.*

- Type parameters: `func Map[T, U any](s []T, f func(T) U) []U`
- Constraints --- `any`, `comparable`, custom constraint interfaces
- `~T` tilde syntax --- "any type whose underlying type is T"; essential for user-defined types
- `comparable` vs `any` --- map keys require `comparable`
- `slices` package (Go 1.21): `Sort`, `SortFunc`, `Contains`, `Index`, `Compact`, `Collect`
- `maps` package (Go 1.21): `Clone`, `Keys`, `Values`
- `cmp` package: `cmp.Compare`, `cmp.Ordered`
- `iter` package (Go 1.23): `iter.Seq[V]`, `iter.Seq2[K,V]`; range-over-func; `yield` callbacks
- `unique` package (Go 1.23): value interning via `unique.Make`
- Generic type aliases (Go 1.24)
- When NOT to use generics --- prefer concrete types; generics add complexity

### Chapter 18: Testing
*Table-driven tests and the race detector are non-negotiable. Fuzzing is free coverage.*

- `testing.T` --- `t.Error`, `t.Fatal`, `t.Log`; test function naming
- Table-driven tests --- slice of structs; `t.Run` subtests
- `t.Helper()` --- clean failure attribution in helper functions
- `t.Cleanup` --- register teardown that runs at test end; the idiomatic alternative to `defer`
- `t.Parallel` --- running tests concurrently
- Benchmarks: `func BenchmarkFoo(b *testing.B)`; `b.Loop` (Go 1.24, the modern idiom), `b.ResetTimer`
- Fuzzing: `func FuzzFoo(f *testing.F)`; `f.Add` seed corpus; runs until failure
- Example tests --- `func ExampleFoo()` with `// Output:` comments
- Testing HTTP handlers with `httptest` --- `NewRecorder`, `NewServer`
- Race detector: `go test -race`; always on in CI
- Goroutine leak detection: `goleak.VerifyNone(t)` in `TestMain`
- Integration tests --- build tags to separate unit and integration tests
- `go test ./...`, `-count=1` (disable caching), `-timeout`, `-run`, `-bench`

---

## Appendices

### Appendix A: Go Proverbs
*Rob Pike's proverbs as a design guide.*

- "Don't communicate by sharing memory; share memory by communicating"
- "Concurrency is not parallelism"
- "The bigger the interface, the weaker the abstraction"
- "Accept interfaces, return concrete types"
- "Make the zero value useful"
- "The empty interface says nothing"
- "Errors are values"
- "Don't just check errors, handle them gracefully"
- "A little copying is better than a little dependency"
- "Clear is better than clever"
- "gofmt's style is no one's favorite, yet gofmt is everyone's favorite"
- "Cgo is not Go" --- and: cgo and `syscall` must always be guarded with build constraints
- "With the unsafe package there are no guarantees"
- "Reflection is never clear"
- Each proverb discussed in the context of Java habits to unlearn

### Appendix B: Tooling
*The Go toolchain is opinionated. Lean into it.*

- `gofmt` / `goimports` --- formatting is not negotiable; configure your editor to run on save
- `go vet` --- catches common mistakes the compiler misses
- `golangci-lint` --- the standard linter aggregator; configure in `.golangci.yml`
- `go doc` / `godoc` --- documenting and reading package docs
- `gopls` --- the official language server; powers IDE support
- Delve (`dlv`) --- the standard Go debugger; `dlv debug`, `dlv test`, goroutine inspection
- `go tool compile -gcflags=-m` --- see escape analysis decisions

### Appendix C: Go Code Review Rules
*The community code review rules, adapted for this book; the `[rule-name]` markers in the text link here.*

- Formatting, comments, context, copying, cryptographic randomness
- Declaring empty slices, error strings, "don't panic", examples
- Goroutine lifetimes, handling errors, imports (blank, dot), in-band errors
- Indent error flow, initialisms, interfaces, line length, mixed caps
- Named result parameters, package comments and names, passing values
- Receiver names and types, synchronous functions, useful test failures, variable names

---

## Index
*Built from `\index{}` markers via LaTeX `makeidx`; `\printindex` lives in appC.md.*
