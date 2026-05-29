# Go Code Review Rules

\index{code review!rules}
\index{Go Code Review Comments}
The rules in this appendix are drawn from the official **Go Code Review Comments** wiki maintained by the Go team [@CodeReviewComments].
That document describes the kinds of issues that arise during code review of Go programs --- the things that automated tools like `gofmt` and `go vet` do not catch.
Each rule is numbered **CR-N** so it can be cited precisely from the main text.

## Formatting

\index{gofmt}
\index{goimports}

**CR-1.** Run `gofmt` (or `go fmt`) on all code to automatically fix mechanical style issues before review.

**CR-2.** Prefer `goimports` over `gofmt`; it is a superset that also organizes import blocks.

## Comments

\index{doc comment}

**CR-3.** Comments that document declarations must be complete sentences ending with a period.

**CR-4.** A doc comment should begin with the name of the thing it describes: `// Request represents a request to run a command.`

**CR-5.** All exported top-level names must have doc comments; non-trivial unexported declarations should too.

## Context

\index{context.Context}

**CR-6.** Functions that use `context.Context` should accept it as the first parameter, named `ctx`.

**CR-7.** Never store a `Context` in a struct; pass it as a method parameter instead (exception: signatures forced by third-party interfaces).

**CR-8.** Prefer passing `context.Context` even when you think you don't need it; only use `context.Background()` with a clear reason.

**CR-9.** Keep application data in function parameters, receivers, or globals --- not in `Context` values --- unless it genuinely belongs to the request lifecycle.

**CR-10.** A `Context` is safe to pass to concurrent calls that share its deadline and cancellation signal.

## Copying

\index{copying structs}

**CR-11.** Do not copy a value of type `T` if its methods are on `*T`; copying may cause unexpected aliasing of internal slice or pointer fields.

## Cryptographic Randomness

\index{crypto/rand}

**CR-12.** Never use `math/rand` or `math/rand/v2` to generate keys, tokens, or other security-sensitive values; use `crypto/rand.Reader`.

**CR-13.** For random text output use `crypto/rand.Text()` or encode `crypto/rand.Reader` bytes with `encoding/hex` or `encoding/base64`.

## Declaring Empty Slices

\index{nil slice}

**CR-14.** Prefer `var t []string` (nil slice) over `t := []string{}` (non-nil empty slice); they are functionally equivalent for `len` and `cap` but a nil slice encodes to JSON `null` and is the idiomatic zero value.

**CR-15.** Avoid API designs that distinguish between nil and empty slices; the distinction is subtle and causes bugs.

## Error Strings

\index{error string}

**CR-16.** Error strings must not be capitalized (unless they begin with a proper noun or acronym) and must not end with punctuation, because they are typically embedded in larger messages: `fmt.Errorf("something bad")` not `fmt.Errorf("Something bad.")`.

## Don't Panic

\index{panic}

**CR-17.** Normal error handling must use error return values and multiple return values rather than `panic`.

**CR-18.** Reserve `panic` for truly exceptional situations that indicate programmer error or unrecoverable state.

## Examples

**CR-19.** When adding a new package, include a runnable `Example*` test function that demonstrates the intended usage.

## Goroutine Lifetimes

\index{goroutine!lifetime}
\index{goroutine!leak}

**CR-20.** When you spawn a goroutine, make it clear when or whether it exits; goroutines that cannot exit are leaks.

**CR-21.** Goroutines block garbage collection of the values they close over; a leaked goroutine causes unbounded memory growth.

**CR-22.** Keep concurrent code simple enough that goroutine lifetimes are obvious; document lifetime guarantees when simplicity is not achievable.

## Handle Errors

\index{error!handling}

**CR-23.** Never discard an error with `_`; if a function returns an error, check it.

**CR-24.** When you receive an error, either handle it, return it to the caller, or (in truly exceptional cases) panic --- never silently ignore it.

## Imports

\index{import!organization}

**CR-25.** Avoid renaming imports; a well-chosen package name should not require renaming at the call site.

**CR-26.** When renaming is unavoidable (name collision), rename the most local or project-specific import, not the standard library one.

**CR-27.** Organize imports in groups separated by blank lines: standard library first, then third-party, then internal packages.

## Import Blank

\index{blank import}

**CR-28.** Packages imported only for side effects (`import _ "pkg"`) belong only in the `main` package of a program or in tests that require them.

## Import Dot

\index{import dot}

**CR-29.** Avoid `import .`; it makes code harder to read because it is unclear which identifiers come from the imported package. Use it only in tests that have circular dependencies and cannot be part of the tested package.

## In-Band Errors

\index{error!in-band}

**CR-30.** Do not use in-band error signals (returning `-1`, `""`, or `nil` to indicate failure) when those values are also valid results; use a second return value of type `error` or `bool` instead.

**CR-31.** An in-band sentinel value is acceptable only when the sentinel is unambiguously not a valid result (e.g., `strings.Index` returning `-1` for "not found").

## Indent Error Flow

\index{error!flow}

**CR-32.** Keep the success (normal) code path at the minimum indentation level; handle errors first and return, so readers can scan the happy path without reading error branches.

**CR-33.** Avoid the `if err != nil { ... } else { // success }` pattern; invert it so the error branch returns and the success code is unindented.

## Initialisms

\index{initialism}

**CR-34.** Acronyms and initialisms must have consistent case throughout: `URL` not `Url`, `HTTP` not `Http`, `ID` not `Id`, `ServeHTTP` not `ServeHttp`.

**CR-35.** When an initialism begins an unexported name, lowercase the whole initialism: `xmlHTTPRequest` or `urlPony`.

## Interfaces

\index{interface!location}

**CR-36.** Define interfaces in the package that *uses* them, not in the package that implements them; Go's implicit satisfaction makes this possible and keeps dependencies pointing the right way.

**CR-37.** Implementing packages should return concrete types (structs or pointers to structs), not interface types; this allows new methods to be added without breaking callers.

**CR-38.** Do not define an interface solely to support mocking in tests; design your API so it can be tested through its real public surface, or use a consumer-side fake.

**CR-39.** Do not define an interface before you have a realistic use case; premature interfaces lead to awkward, over-abstract designs.

## Line Length

**CR-40.** There is no hard line-length limit; break lines for semantic clarity (a natural pause in the logic), not to satisfy an arbitrary character count.

**CR-41.** If a line feels too long, first consider whether a better name or a local variable would eliminate the length problem before adding a line break.

## Mixed Caps

\index{MixedCaps}

**CR-42.** Use `MixedCaps` (or `mixedCaps`) for multi-word names in all contexts, including constants: `maxLength` not `MAX_LENGTH`.

## Named Result Parameters

\index{named return values}

**CR-43.** Name result parameters when doing so genuinely clarifies the meaning of multiple same-typed return values: `func Location() (lat, long float64, err error)`.

**CR-44.** Do not name result parameters solely to enable naked returns in non-trivial functions; the clarity cost of naked returns in longer functions outweighs the brevity gain.

**CR-45.** Naming a result parameter is appropriate when a deferred closure needs to modify it (e.g., to capture a close error).

## Package Comments

\index{package comment}

**CR-46.** Package comments must appear immediately above the `package` clause with no blank line between them.

**CR-47.** Package comments must begin with a capital letter and be complete sentences: `// Package math provides basic constants and mathematical functions.`

**CR-48.** For `main` packages, acceptable forms include: "Binary seedgen ...", "Command seedgen ...", or "The seedgen command ...".

## Package Names

\index{package!naming}

**CR-49.** Remove the package name from exported identifiers: in package `chubby`, use `File` not `ChubbyFile` (callers write `chubby.File`).

**CR-50.** Avoid generic package names such as `util`, `common`, `misc`, `api`, `types`, and `interfaces`; they communicate nothing about purpose.

## Pass Values

\index{pointer!unnecessary}

**CR-51.** Do not pass a pointer just to save a few bytes; if the function only dereferences `*x` throughout, the argument should not be a pointer.

**CR-52.** Never pass pointers to strings (`*string`) or interface values (`*io.Reader`); both are already reference-sized values.

**CR-53.** Exception: large structs or structs expected to grow should be passed by pointer for efficiency.

## Receiver Names

\index{method receiver!naming}

**CR-54.** The receiver name should be a short abbreviation of the type name (one or two letters), not `this`, `self`, or `me`.

**CR-55.** The receiver name must be consistent across all methods of a type: if one method uses `c`, all must use `c`.

## Receiver Type

\index{method receiver!type}

**CR-56.** Use a pointer receiver when the method needs to mutate the receiver.

**CR-57.** Use a pointer receiver when the struct contains a `sync.Mutex` or similar synchronization field, to avoid copying the lock.

**CR-58.** Use a pointer receiver for large structs or arrays where copying on each call would be expensive.

**CR-59.** Use a value receiver for small, immutable structs or basic types (integers, strings) that hold no pointers and do not need mutation.

**CR-60.** Do not mix value and pointer receivers on the same type; if any method needs a pointer receiver, use pointer receivers for all methods so the method set is consistent regardless of how the value is stored.

**CR-61.** When in doubt, use a pointer receiver.

## Synchronous Functions

\index{synchronous function}

**CR-62.** Prefer synchronous functions --- those that return results directly or finish callbacks/channel operations before returning --- over asynchronous ones.

**CR-63.** If callers need concurrency, they can call a synchronous function from a goroutine; removing unnecessary concurrency from an API is much harder after the fact.

## Useful Test Failures

\index{testing!failure messages}

**CR-64.** Test failure messages must describe what was wrong: state the inputs, the actual output, and the expected output.

**CR-65.** Write failure messages in the order `actual != expected`: `t.Errorf("Foo(%q) = %d; want %d", in, got, want)`.

**CR-66.** Use table-driven tests to reduce repetition and to ensure every case produces an identifiable failure message.

**CR-67.** Ensure test helpers produce useful failure messages that identify which case failed; use `t.Helper()` to attribute failures to the call site.

## Variable Names

\index{variable!naming}

**CR-68.** Prefer short variable names, especially for local variables with limited scope: `c` over `lineCount`, `i` over `sliceIndex`.

**CR-69.** The further a variable's use is from its declaration, the more descriptive its name must be; single-letter names are appropriate only for very short scopes.

**CR-70.** Global variables and variables representing unusual or domain-specific concepts require descriptive names.

---

```{=latex}
\printindex
```
