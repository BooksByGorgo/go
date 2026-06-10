# Tooling

\index{tooling}
Go ships with an unusually complete set of first-party tools, and the ecosystem adds a few more that every Go developer uses daily.
This appendix is a quick reference for all of them.

## gofmt and goimports

\index{gofmt}
\index{goimports}
Go formatting is not a style guide suggestion --- it is enforced.
`gofmt` is the official formatter, and idiomatic Go code is always `gofmt`-clean.
There is no equivalent debate in the Go community about brace placement or indentation because `gofmt` makes every decision for you.

The Java world has tools like Checkstyle and Google Java Format, but they are optional and configurable.
`gofmt` has almost no configuration on purpose: one canonical style for all Go code everywhere.

Run the formatter in place:

```sh
gofmt -w .          # rewrite all .go files under the current directory
gofmt -l .          # list files that differ from the canonical format
```

`goimports`\index{goimports} extends `gofmt` by also adding missing imports and removing unused ones.
It is a strict superset of `gofmt` and is preferred in editor integrations.

```sh
goimports -w .      # format and fix imports in place
```

Install it once:

```sh
go install golang.org/x/tools/cmd/goimports@latest
```

::: {.tip}
**Tip:** Configure your editor to run `goimports -w` on every save.
In VS Code this is the default when the Go extension is installed.
In IntelliJ IDEA with the Go plugin, enable **Reformat code on save** and set the formatter to `goimports`.
You should never need to run either tool manually once your editor is configured.
:::

::: {.tip}
**Trap:** Submitting un-formatted code in a Go project is a red flag.
Most Go CI pipelines run `gofmt -l .` and fail the build if any file differs.
Don't rely on reviewers to catch it.
:::

## go vet

\index{go vet}
`go vet` is a static analysis tool that catches mistakes the compiler deliberately ignores.
The compiler only rejects code that is syntactically or type-invalid; `go vet` catches things that compile fine but are almost certainly bugs.

Java programmers will recognize this role from SpotBugs or ErrorProne, but `go vet` is built in and requires no configuration.

```sh
go vet ./...        # vet all packages in the module
```

Common mistakes `go vet` catches:

- `Printf`-family format string mismatches (`fmt.Printf("%d", "hello")`)
- Passing a mutex by value (copying a `sync.Mutex` breaks its invariants)
- Unreachable code after `return`
- Misuse of `sync/atomic`, like `x = atomic.AddUint64(&x, 1)` (the assignment races with the atomic update)
- Calling `t.Fatal` or `t.FailNow` from a goroutine inside a test (`t.Error` is goroutine-safe)

::: {.tip}
**Tip:** Run `go vet ./...` as part of your normal build step, not just on CI.
It is fast enough that there is no reason to skip it locally.
Many Makefiles include a `vet` target that runs before tests.
:::

::: {.tip}
**Wut:** `go vet` is not a linter.
It reports only definite bugs or misuses, not style violations or suspicious patterns.
For broader coverage, use `golangci-lint` (see below).
:::

## golangci-lint

\index{golangci-lint}
\index{linter!aggregator}
`golangci-lint` is the standard linter aggregator for Go.
It runs dozens of individual linters in parallel, merges their output, and is fast enough to use in CI.
The closest Java equivalent is a combination of Checkstyle, SpotBugs, PMD, and ErrorProne --- all configured in one place.

Install it:

```sh
# macOS / Linux via the official installer (preferred)
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b $(go env GOPATH)/bin v2.12.2

# or via go install (slower, but always available)
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
```

Run it:

```sh
golangci-lint run ./...             # run all enabled linters
golangci-lint run --fix ./...       # auto-fix what can be auto-fixed
golangci-lint linters               # list all available linters and their status
```

### Configuration

\index{golangci-lint!configuration}
\index{.golangci.yml}
Configuration lives in `.golangci.yml` at the module root.
A minimal starting config:

```yaml
version: "2"

linters:
  enable:
    - govet        # go vet findings
    - errcheck     # unchecked errors
    - staticcheck  # advanced static analysis (now includes the old gosimple checks)
    - ineffassign  # assignments that are never read
    - unused       # unused code
  settings:
    govet:
      enable-all: true
```

In golangci-lint v2 the built-in exclusion presets are off by default, so there is no key to disable them.
If you *want* the common false-positive exclusions, opt in under `linters.exclusions.presets` (for example `common-false-positives` or `legacy`).

::: {.tip}
**Tip:** Start with a small, agreed-upon set of linters and expand over time.
Enabling every linter at once on an existing codebase produces a wall of noise that discourages use.
The linters `govet`, `errcheck`, `staticcheck`, and `unused` are a solid first set.
:::

::: {.tip}
**Trap:** Do not install `golangci-lint` with `go install` in CI.
The resulting binary depends on which Go version is in the environment, and linter behavior can change between releases.
Use the pinned version from the official install script or a pinned Docker image instead.
:::

## go doc and godoc

\index{go doc}
\index{godoc}
\index{documentation!Go}
Go uses plain comments immediately above declarations as documentation --- no annotation syntax, no XML tags.
The Java equivalent is Javadoc; the Go equivalent is much simpler.

A documented function looks like this:

```go
// Greet returns a greeting for the named person.
// If name is empty, it returns a generic greeting.
func Greet(name string) string {
    if name == "" {
        return "Hello, stranger."
    }
    return "Hello, " + name + "."
}
```

The `go doc` command reads these comments from source and displays them in the terminal:

```sh
go doc fmt                      # show package-level docs for fmt
go doc fmt.Println              # show docs for a specific function
go doc -all fmt                 # show all exported names and their docs
go doc -src fmt.Println         # show the source of the function
```

Since Go 1.25, `go doc` can also serve documentation as HTML in the same format as pkg.go.dev --- no extra install needed:

```sh
go doc -http=:6060              # serve docs at http://localhost:6060
```

(The deprecated `golang.org/x/tools/cmd/godoc` command was the way to do this before Go 1.25; you may still see it referenced.)

::: {.tip}
**Tip:** Write doc comments for every exported name.
`golangci-lint` includes the `godot` linter, which enforces that doc comments end with a period.
Treat a missing doc comment on an exported symbol the same way you would treat a missing Javadoc block.
:::

::: {.tip}
**Wut:** Unlike Javadoc, Go doc comments are plain text --- no HTML, no `@param`, no `@return` tags.
Since Go 1.19, the `go doc` format supports a lightweight markup (lists, code fences, links) but it is still far simpler than Javadoc.
:::

## gopls

\index{gopls}
\index{language server}
\index{LSP}
`gopls` (pronounced "go please") is the official Go language server.
It implements the Language Server Protocol (LSP), the same protocol that powers Java support in VS Code via the Eclipse JDT Language Server and in IntelliJ via its built-in engine.
Any editor that speaks LSP --- VS Code, Neovim, Emacs, Helix, and others --- can use `gopls` for Go support.

`gopls` provides:

- Code completion
- Go-to-definition and find-references
- Inline type information and documentation
- Rename refactoring
- Auto-import via `goimports`
- Real-time `go vet` and some `staticcheck` diagnostics
- Inlay hints for parameter names and return types

You rarely invoke `gopls` directly; your editor or its Go plugin manages it.
Install or update it:

```sh
go install golang.org/x/tools/gopls@latest
```

::: {.tip}
**Tip:** Keep `gopls` updated.
It improves rapidly and newer versions understand newer Go language features.
Running an old `gopls` against a module that uses a new Go version can produce confusing false errors.
:::

::: {.tip}
**Trap:** If `gopls` is slow or consuming too much memory on a large module, check that your `GOPATH` module cache is not inside a Dropbox or similar sync folder.
File-watcher conflicts with sync tools are a common source of `gopls` instability.
:::

## Delve

\index{Delve debugger}
\index{dlv}
Delve is the standard debugger for Go.
The Java equivalent is `jdb` on the command line, or the debugger built into IntelliJ IDEA and Eclipse.
Delve understands goroutines, deferred functions, and Go's calling conventions --- things that a generic C debugger like GDB cannot handle correctly.

Install Delve:

```sh
go install github.com/go-delve/delve/cmd/dlv@latest
```

### Key Commands

\index{Delve debugger!commands}
Start a debug session for a main package:

```sh
dlv debug ./cmd/myapp              # compile with debug info and attach
dlv debug ./cmd/myapp -- --port 8080  # pass flags to the program after --
```

Debug tests in a package:

```sh
dlv test ./pkg/mypackage           # debug test binary
dlv test ./pkg/mypackage -- -test.run TestFoo  # run only TestFoo under the debugger
```

Attach to an already-running process:

```sh
dlv attach <pid>                   # attach to a running process by PID
```

Inside a Delve session the most useful commands are:

```
break main.main       # set a breakpoint at a function
break myfile.go:42    # set a breakpoint at a file and line
continue              # run until the next breakpoint
next                  # step over the current line
step                  # step into the current call
stepout               # step out of the current function
print varname         # print a variable
locals                # print all local variables
goroutines            # list all goroutines
goroutine 3           # switch to goroutine 3
stack                 # print the current call stack
```

::: {.tip}
**Tip:** In VS Code with the Go extension, the **Run and Debug** panel uses Delve under the hood.
You get full GUI debugging --- breakpoints, watch expressions, call stack, goroutine list --- without leaving the editor.
IntelliJ IDEA's Go plugin also integrates Delve.
For day-to-day work you rarely need the `dlv` CLI directly.
:::

::: {.tip}
**Wut:** A plain `go build` keeps DWARF debug info but compiles with optimizations and inlining, which makes stepping jumpy and variables invisible.
`dlv debug` rebuilds with `-gcflags="all=-N -l"` to disable them, but if you attach to a production binary built with `-ldflags="-s -w"` you will have no symbols at all.
Keep an unstripped build around when you need to debug a production issue.
:::

### Goroutine Inspection

\index{Delve debugger!goroutines}
One of Delve's most useful capabilities over `jdb` is first-class goroutine support.
The `goroutines` command lists every live goroutine with its current state and top-of-stack location.
The `goroutine <id>` command switches your debugging context to that goroutine, and `stack` then shows its full call stack.
This makes diagnosing deadlocks and goroutine leaks far easier than thread dumps in Java.

## go build -gcflags=-m

\index{escape analysis}
\index{go tool compile}
\index{gcflags}
Every Go value is allocated either on the stack or on the heap.
Stack allocation is free; heap allocation requires the garbage collector to eventually reclaim it.
The compiler performs *escape analysis* to decide where each value lives: if a value's address outlives the function that created it, the value *escapes to the heap*.

You can see these decisions:

```sh
go build -gcflags='-m' ./...              # print escape analysis decisions
go build -gcflags='-m=2' ./...            # more verbose; show the reason for each decision
go build -gcflags='-m -l' ./...           # disable inlining, then show escape analysis
```

Sample output for a small function:

```
./main.go:12:6: can inline greet
./main.go:18:12: "hola " + name escapes to heap
./main.go:22:13: moved to heap: result
```

Java programmers do not usually think about stack vs. heap allocation explicitly because the JVM decides everything.
In Go the distinction matters for performance-sensitive code: a value that escapes forces a heap allocation and adds GC pressure.

::: {.tip}
**Tip:** Do not prematurely optimize by trying to prevent all escapes.
Run `-gcflags=-m` only when a profiler shows that allocations are a bottleneck, then look at the output to understand why specific values escape and whether anything can be restructured to avoid it.
:::

::: {.tip}
**Wut:** Passing a pointer to a function does not automatically cause the pointee to escape.
The compiler performs interprocedural analysis.
If it can prove the pointer does not outlive the call, the value stays on the stack.
This is why small structs passed by pointer in tight loops often don't show up as heap allocations.
:::

## Summary

\index{tooling!summary}
The table below maps each Go tool to its closest Java equivalent.

| Go Tool | Purpose | Java Equivalent |
|---|---|---|
| `gofmt` | Canonical code formatter | Google Java Format, Spotless |
| `goimports` | Format + manage imports | IntelliJ optimize imports, `google-java-format` |
| `go vet` | Built-in static analysis | SpotBugs, ErrorProne |
| `golangci-lint` | Linter aggregator | Checkstyle + SpotBugs + PMD combined |
| `go doc` | Terminal doc viewer | `javadoc` CLI output |
| `go doc -http` | Local documentation server (Go 1.25+) | `javadoc` HTML output, pkg.go.dev |
| `gopls` | LSP language server | Eclipse JDT LS, IntelliJ built-in engine |
| `dlv` (Delve) | Debugger with goroutine support | `jdb`, IntelliJ / Eclipse debugger |
| `go build -gcflags=-m` | Escape analysis output | JVM `-XX:+PrintEscapeAnalysis` (JIT only) |
