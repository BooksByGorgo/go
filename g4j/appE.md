# Unsafe and cgo

\index{unsafe}
\index{cgo}
Go's type system and memory model are designed to keep you safe: no pointer arithmetic, no manual memory management, no calling into arbitrary native code without oversight.
Sometimes, though, you need to step outside those guarantees --- to talk to a C library, to squeeze the last nanosecond out of a hot path, or to inspect memory layout for serialization.
The `unsafe` package and the `cgo` tool are the two escape hatches the language provides.
Both come with real costs, and both should be treated as last resorts rather than defaults.
If you have written Java, you will recognise the same uneasy feeling you get when you reach for JNI (Java Native Interface) --- that mix of power and dread.
This appendix covers what these tools do, how to use them correctly, and, most importantly, when not to reach for them at all.

## The unsafe Package

\index{unsafe!package}
The `unsafe` package is part of the Go standard library, but it is special: the compiler knows about it and the usual type-safety rules do not apply inside it.
Importing `unsafe` is a signal to reviewers that something unusual is happening and that extra scrutiny is warranted.

### unsafe.Pointer

\index{unsafe!Pointer}
`unsafe.Pointer` is Go's untyped pointer.
It can hold the address of any variable, regardless of type --- similar in spirit to `void *` in C.
Its signature is conceptually:

```go
type Pointer uintptr // conceptual; the compiler treats it specially
```

The Go specification defines exactly four conversions involving `unsafe.Pointer` that are legal:

1. A pointer of any type `*T` may be converted to `unsafe.Pointer`.
2. An `unsafe.Pointer` may be converted to a pointer of any type `*T`.
3. A `uintptr` may be converted to `unsafe.Pointer`.
4. An `unsafe.Pointer` may be converted to a `uintptr`.

::: {.tip}
**Trap:** `uintptr` is just an integer --- the garbage collector does not treat it as a live pointer reference.
If you convert an `unsafe.Pointer` to `uintptr`, store the result in a variable, and then use it later, the GC may have moved or collected the original object in between.
**Never store an intermediate `uintptr` across a statement boundary.**
The conversion from `uintptr` back to `unsafe.Pointer` must happen in a single expression.
:::

The classic use of `unsafe.Pointer` is reinterpreting the bytes of one type as another --- most often when bridging Go structs with C structs at an FFI boundary:

```go
package main

import (
    "fmt"
    "unsafe"
)

type Point32 struct {
    X, Y int32
}

type RawBytes [8]byte

func main() {
    p := Point32{X: 1, Y: 2}
    // reinterpret the bytes of p as a [8]byte --- only safe when layouts match
    raw := *(*RawBytes)(unsafe.Pointer(&p))
    fmt.Printf("%v\n", raw) // [1 0 0 0 2 0 0 0] on a little-endian system
}
```

::: {.tip}
**Tip:** Reinterpreting struct bytes is only safe when you know both types have identical size and compatible layout.
Use `unsafe.Sizeof` and `unsafe.Offsetof` (described below) to verify before you cast.
:::

### unsafe.Sizeof, unsafe.Alignof, and unsafe.Offsetof

\index{unsafe!Sizeof}
\index{unsafe!Alignof}
\index{unsafe!Offsetof}
Three functions in the `unsafe` package let you query the memory layout of types and struct fields at compile time.
All three return `uintptr` and are evaluated by the compiler --- they are not function calls at runtime.

```go
func Sizeof(x ArbitraryType) uintptr  // size in bytes of the type of x
func Alignof(x ArbitraryType) uintptr // alignment requirement in bytes of the type of x
func Offsetof(x ArbitraryType) uintptr // byte offset of a struct field from the struct's base
```

A quick example that mirrors what you might write with `sizeof`, `alignof`, and `offsetof` in C:

```go
package main

import (
    "fmt"
    "unsafe"
)

type Header struct {
    Magic   uint32
    Version uint16
    _       [2]byte // explicit padding
    Length  uint64
}

func main() {
    var h Header
    fmt.Println(unsafe.Sizeof(h))            // 16
    fmt.Println(unsafe.Alignof(h))           // 8
    fmt.Println(unsafe.Offsetof(h.Magic))    // 0
    fmt.Println(unsafe.Offsetof(h.Version))  // 4
    fmt.Println(unsafe.Offsetof(h.Length))   // 8
}
```

::: {.tip}
**Tip:** `unsafe.Offsetof` takes a field selector expression, not a field name string.
Write `unsafe.Offsetof(h.Length)`, not `unsafe.Offsetof(Header{}.Length)` (though the latter also works since only the type matters).
:::

::: {.tip}
**Wut:** Struct field ordering affects size because of alignment padding.
Go does not reorder fields for you --- unlike some C++ compilers with `__attribute__((packed))`.
If you are writing a struct that maps to a wire format or a C struct, order fields from largest to smallest alignment to minimise padding, and add explicit padding fields to document intentional gaps.
:::

## cgo: Calling C from Go

\index{cgo}
`cgo` is the mechanism Go provides for calling C functions from Go code and, to a lesser extent, for calling Go functions from C.
If you have worked with JNI, the comparison is apt: both let you cross the managed/native boundary, both require careful attention to memory ownership, and both impose a non-trivial overhead on each call.
`cgo` is arguably more ergonomic than JNI --- there is no `GetMethodID` ceremony --- but the fundamental risks are the same.

### Enabling cgo: `import "C"`

\index{cgo!import C}
You enable `cgo` in a Go file by writing a special import:

```go
import "C"
```

The `"C"` pseudo-package is not a real Go package.
It is a bridge to the C code you declare in the **preamble** --- a block of C code in a comment that immediately precedes the `import "C"` line with **no blank line** between them.

```go
package main

/*
#include <stdio.h>
#include <stdlib.h>

void say_hello(const char* name) {
    printf("Hola, %s!\n", name);
}
*/
import "C"

import "fmt"

func main() {
    cs := C.CString("mundo")
    defer C.free(unsafe.Pointer(cs))
    C.say_hello(cs)
    fmt.Println("back in Go")
}
```

::: {.tip}
**Trap:** There must be **no blank line** between the closing `*/` of the preamble comment and the `import "C"` line.
A single blank line silently disables the preamble and your C declarations will not be visible.
:::

The preamble can contain `#include` directives, `#cgo` directives (for compiler and linker flags), `typedef` declarations, inline function definitions, and anything else that is legal in a C translation unit.

### C Types in Go

\index{cgo!C types}
Inside Go code, C types are accessed through the `C` pseudo-package:

| C type          | Go name via cgo   |
|-----------------|-------------------|
| `int`           | `C.int`           |
| `long`          | `C.long`          |
| `unsigned int`  | `C.uint`          |
| `char`          | `C.char`          |
| `void *`        | `unsafe.Pointer`  |
| `size_t`        | `C.size_t`        |
| `char *`        | `*C.char`         |

Go's numeric types (`int`, `int32`, etc.) are **not** directly assignable to C types --- you must cast explicitly:

```go
var n C.int = C.int(42)
var m int   = int(n)
```

### String Conversion: CString and GoString

\index{cgo!CString}
\index{cgo!GoString}
The most common data crossing the Go/C boundary is strings.
Go strings are a length-prefixed byte slice; C strings are null-terminated `char *`.
`cgo` provides two conversion functions:

```go
func C.CString(s string) *C.char  // allocates a new C string (null-terminated); caller must free
func C.GoString(cs *C.char) string // copies a null-terminated C string into a Go string
```

`C.CString` allocates memory using the C allocator (`malloc`).
That memory is invisible to Go's garbage collector and **will never be freed automatically**.
You must always pair `C.CString` with `C.free`:

```go
import "C"
import "unsafe"

func greet(name string) {
    cs := C.CString(name)
    defer C.free(unsafe.Pointer(cs))
    C.say_hello(cs)
}
```

::: {.tip}
**Trap:** Forgetting `C.free` after `C.CString` is a memory leak.
The Go GC will never reclaim that allocation.
Make `defer C.free(unsafe.Pointer(cs))` the **second line** every time you write `C.CString`, immediately after the assignment.
:::

::: {.tip}
**Tip:** `C.GoString` copies the C string into a Go-managed `string` value.
After the copy, the Go string is owned by the Go runtime.
You do not need to free anything on the Go side, but you still need to free the original `*C.char` if you own it.
:::

Additional string-conversion helpers you may encounter:

```go
func C.GoStringN(cs *C.char, n C.int) string  // copy exactly n bytes (may contain nulls)
func C.GoBytes(p unsafe.Pointer, n C.int) []byte // copy n bytes from a C pointer into a []byte
```

### Memory Management and Ownership

\index{cgo!memory management}
The golden rule of `cgo` memory management is: **the side that allocates owns the memory**.

- Memory allocated by Go (via `new`, `make`, or a Go literal) is managed by the Go GC.
You may pass a pointer to that memory into C for the duration of a call, but C must not retain the pointer beyond the call --- the GC may move or free it.
- Memory allocated by C (`malloc`, `strdup`, etc.) must be freed by C (`free`).
In Go, that means calling `C.free`.

::: {.tip}
**Trap:** Passing a Go pointer to C and letting C store it beyond the call is illegal under Go's cgo rules.
The Go GC is allowed to move objects, and a stale C-held pointer will then point to garbage.
The `cgo` checker (`go vet`) catches many of these violations, but not all.
:::

### Build Constraints and Cross-Compilation

\index{cgo!build constraints}
\index{cgo!cross-compilation}
When you write `import "C"`, the Go toolchain delegates to a C compiler (typically `gcc` or `clang`) to compile the preamble.
This has several consequences:

- **A C compiler must be present** on the build machine.
Containers and CI images that have `go` but not `gcc` will fail to build `cgo` packages.
- **Cross-compilation is hard.**
Pure-Go programs cross-compile trivially: `GOOS=linux GOARCH=arm64 go build ./...`.
With `cgo` enabled, you need a cross-compiler toolchain for the target platform --- `CC=aarch64-linux-gnu-gcc` --- or you must disable `cgo` entirely with `CGO_ENABLED=0`.
- **Static binaries require extra work.**
By default, `cgo` programs link against glibc dynamically.
Producing a fully static binary requires `-ldflags '-extldflags "-static"'` and a musl or Alpine-based toolchain.

::: {.tip}
**Tip:** Set `CGO_ENABLED=0` in your CI build unless you explicitly need C interop.
This gives you trivial cross-compilation, a fully static binary, and the guarantee that no accidental `cgo` dependency has crept in.
:::

### Calling Go from C

\index{cgo!export}
You can also export Go functions to C using the `//export` directive:

```go
//export GoAdd
func GoAdd(a, b C.int) C.int {
    return a + b
}
```

The `//export` comment must appear directly before the function signature with no blank line.
The exported function is then callable from C as `GoAdd(a, b)`.
Mixing `//export` with a non-trivial preamble requires care --- see the `cgo` documentation for the `_cgo_export.h` header that `cgo` generates.

## When to Use (and Not Use) unsafe and cgo

\index{unsafe!when to use}
\index{cgo!when to use}

### Legitimate Uses of unsafe

`unsafe.Pointer` is appropriate in a narrow set of situations:

- **FFI boundaries.** When passing Go data to C or reading C-allocated memory, type-punning through `unsafe.Pointer` is unavoidable.
- **Performance-critical serialization.** When encoding millions of fixed-layout structs per second, `unsafe.Offsetof` and a direct memory copy can outperform reflection-based approaches by an order of magnitude.
- **Implementing low-level data structures.** Parts of the Go runtime itself (sync/atomic, the `reflect` package, `sync.Map`) use `unsafe` internally because there is no way to implement them without it.

For everything else, the standard library and the Go module ecosystem almost certainly have a safe alternative.
`encoding/binary`, `encoding/json`, `reflect`, and `google.golang.org/protobuf` cover the vast majority of serialization needs without a single `unsafe` call.

### Legitimate Uses of cgo

\index{cgo!legitimate uses}
`cgo` makes sense when:

- You need to call a mature, battle-tested C library (OpenSSL, SQLite, libpng) and there is no pure-Go port with equivalent features and quality.
- You are writing Go bindings for a C SDK provided by a hardware vendor.
- You are building a system-level tool that must call POSIX APIs that are not exposed by the `syscall` or `golang.org/x/sys` packages.

::: {.tip}
**Tip:** Before reaching for `cgo`, search pkg.go.dev for a pure-Go alternative.
The Go ecosystem has pure-Go TLS (`crypto/tls`), SQLite (`modernc.org/sqlite`), image codecs, compression, and much more.
Pure-Go libraries are faster to compile, trivially cross-compile, and produce no surprises at deployment.
:::

### "cgo is not Go"

\index{cgo!is not Go}
The Go community has a pithy saying: **cgo is not Go**.
It is worth taking seriously.

When you introduce `cgo` into a package:

- **Compile times increase** --- the C toolchain runs on every `go build`.
- **Go's race detector and sanitizers have limited visibility** into C code.
- **`go test -race` may miss data races** that cross the Go/C boundary.
- **Stack traces become harder to read** --- C frames appear as `<unknown>`.
- **Goroutine-local storage, the scheduler, and the GC** all operate differently at C call boundaries; C functions run on system (OS) threads, not goroutine stacks.
- **Static analysis tools** (`go vet`, `staticcheck`, `golangci-lint`) cannot reason about what happens inside C.

::: {.tip}
**Trap:** A single `import "C"` anywhere in a package's dependency graph disables cross-compilation for the entire binary unless `CGO_ENABLED=0` is set.
This can surprise you when a transitive dependency you do not control pulls in `cgo`.
Use `go list -f '{{.CgoFiles}}' ./...` to audit which packages in your module use `cgo`.
:::

The analogy to JNI is exact: JNI is powerful, sometimes necessary, and routinely regretted.
Java teams learned to hide JNI behind a narrow interface, wrap every native call in a try/catch, and document ownership explicitly.
Go teams should follow the same discipline with `cgo` --- keep it isolated in a single package, provide a safe Go-idiomatic API above it, and write tests that run with `CGO_ENABLED=1` and with `CGO_ENABLED=0` (the latter using a stub or build tag).

### Decision Checklist

Before adding `unsafe` or `cgo` to your code, work through this list:

1. Is there a pure-Go standard-library or well-maintained module that solves the problem?
Use it.
2. If performance is the driver, have you profiled and confirmed that the unsafe approach is actually faster?
Measure first.
3. If `cgo` is the driver, is the C library available on all your target platforms?
Is a cross-compiler available in your CI?
4. Can you isolate the `unsafe` or `cgo` code behind a clean Go interface so the rest of the codebase stays safe?
5. Have you run `go vet ./...` and confirmed there are no cgo pointer-passing violations?

If you can answer yes to the last four questions and no to the first, proceed --- but document why you made the choice, because the next person reading the code will not have your context.

```{=latex}
\printindex
```
