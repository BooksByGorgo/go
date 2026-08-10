# Go Code Review Rules

\index{code review!rules}
\index{Go Code Review Comments}
The rules in this appendix are drawn from the official **Go Code Review Comments** wiki maintained by the Go team [@CodeReviewComments].
That document describes the kinds of issues that arise during code review of Go programs --- the things that automated tools like `gofmt` and `go vet` do not catch.
Each rule is numbered **CR-N** for ordering within this appendix and is given a **short-descriptive-name**.
The main text cites a rule by its short name in bold italics, written as ***[short-rule-name]*** (the convention introduced in Chapter 0), so you can find the matching entry here by name.

## Formatting

\index{gofmt}
\index{goimports}

**CR-1. gofmt** Run `gofmt` (or `go fmt`) on all code to automatically fix mechanical style issues before review.

**CR-2. goimports** Prefer `goimports` over `gofmt`; it is a superset that also adds missing and removes unused imports.

## Comments

\index{doc comment}

**CR-3. sentence-for-comments** Comments that document declarations must be complete sentences ending with a period.

**CR-4. name-starts-comment** A doc comment should begin with the name of the thing it describes: `// Request represents a request to run a command.`

**CR-5. all-top-comments** All exported top-level names must have doc comments; non-trivial unexported declarations should too.

## Context

\index{context.Context}

**CR-6. ctx-for-context** Functions that use `context.Context` should accept it as the first parameter, named `ctx`.

**CR-7. no-ctx-for-struct** Never store a `Context` in a struct; pass it as a method parameter instead (exception: signatures forced by third-party interfaces).

**CR-8. pass-ctx-by-default** Prefer passing `context.Context` even when you think you don't need it; only use `context.Background()` with a clear reason.

**CR-9. data-in-params-not-ctx** Keep application data in function parameters, receivers, or globals --- not in `Context` values --- unless it genuinely belongs to the request lifecycle.

**CR-10. ctx-safe-for-concurrent** A `Context` is safe to pass to concurrent calls that share its deadline and cancellation signal.

## Copying

\index{copying structs}

**CR-11. no-copy-pointer-type** Do not copy a value of type `T` if its methods are on `*T`; copying may cause unexpected aliasing of internal slice or pointer fields.

## Cryptographic Randomness

\index{crypto/rand}

\index{math/rand}
**CR-12. crypto-rand-for-keys** Never use `math/rand` or `math/rand/v2` to generate keys, tokens, or other security-sensitive values; use `crypto/rand.Reader`.

\index{encoding/base64}
**CR-13. crypto-rand-for-text** For random text output use `crypto/rand.Text()` or encode `crypto/rand.Reader` bytes with `encoding/hex` or `encoding/base64`.

## Declaring Empty Slices

\index{nil slice}

**CR-14. nil-slice-preferred** Prefer `var t []string` (nil slice) over `t := []string{}` (non-nil empty slice); they are functionally equivalent for `len` and `cap`, and nil is the idiomatic zero value --- but note a nil slice encodes to JSON `null` while a non-nil empty slice encodes to `[]`, so prefer the non-nil form when encoding JSON.

**CR-15. no-nil-vs-empty-api** Avoid API designs that distinguish between nil and empty slices; the distinction is subtle and causes bugs.

## Error Strings

\index{error string}

**CR-16. lowercase-error-strings** Error strings must not be capitalized (unless they begin with a proper noun or acronym) and must not end with punctuation, because they are typically embedded in larger messages: `fmt.Errorf("something bad")` not `fmt.Errorf("Something bad.")`.

## Don't Panic

\index{panic}

**CR-17. errors-not-panic** Normal error handling must use error return values and multiple return values rather than `panic`.

**CR-18. panic-for-exceptional** Reserve `panic` for truly exceptional situations that indicate programmer error or unrecoverable state.

## Examples

**CR-19. include-examples** When adding a new package, include examples of the intended usage: a runnable `Example*` test function, or a simple test demonstrating a complete call sequence.

## Goroutine Lifetimes

\index{goroutine!lifetime}
\index{goroutine!leak}

**CR-20. goroutine-must-exit** When you spawn a goroutine, make it clear when or whether it exits; goroutines that cannot exit are leaks.

**CR-21. leaked-goroutine-grows-memory** Goroutines block garbage collection of the values they close over; goroutines that leak repeatedly (e.g., one per request) cause unbounded memory growth.

**CR-22. obvious-goroutine-lifetimes** Keep concurrent code simple enough that goroutine lifetimes are obvious; document lifetime guarantees when simplicity is not achievable.

## Handle Errors

\index{error!handling}

**CR-23. no-discard-error** Never discard an error with `_`; if a function returns an error, check it.

**CR-24. handle-return-or-panic** When you receive an error, either handle it, return it to the caller, or (in truly exceptional cases) panic --- never silently ignore it.

## Imports

\index{import!organization}

**CR-25. no-rename-imports** Avoid renaming imports; a well-chosen package name should not require renaming at the call site.

**CR-26. rename-local-on-collision** When renaming is unavoidable (name collision), rename the most local or project-specific import, not the standard library one.

**CR-27. group-imports** Organize imports in groups separated by blank lines: standard library first, then third-party, then internal packages.

## Import Blank

\index{blank import}

**CR-28. blank-import-main-only** Packages imported only for side effects (`import _ "pkg"`) belong only in the `main` package of a program or in tests that require them.

## Import Dot

\index{import dot}

**CR-29. no-dot-import** Avoid `import .`; it makes code harder to read because it is unclear which identifiers come from the imported package. Use it only in tests that, due to circular dependencies, cannot be made part of the package being tested.

## In-Band Errors

\index{error!in-band}

**CR-30. no-in-band-errors** Do not use in-band error signals (returning `-1`, `""`, or `nil` to indicate failure) when those values are also valid results; use a second return value of type `error` or `bool` instead.

**CR-31. in-band-ok-if-unambiguous** An in-band sentinel value is acceptable only when the sentinel is unambiguously not a valid result (e.g., `strings.Index` returning `-1` for "not found").

## Indent Error Flow

\index{error!flow}

**CR-32. error-first-return-early** Keep the success (normal) code path at the minimum indentation level; handle errors first and return, so readers can scan the happy path without reading error branches.

**CR-33. no-else-after-error** Avoid the `if err != nil { ... } else { // success }` pattern; invert it so the error branch returns and the success code is unindented.

## Initialisms

\index{initialism}

**CR-34. consistent-initialism-case** Acronyms and initialisms must have consistent case throughout: `URL` not `Url`, `HTTP` not `Http`, `ID` not `Id`, `ServeHTTP` not `ServeHttp`.

**CR-35. lowercase-leading-initialism** When an initialism begins an unexported name, lowercase the whole initialism: `xmlHTTPRequest` or `urlPony`.

## Interfaces

\index{interface!location}

**CR-36. interface-in-consumer** Define interfaces in the package that *uses* them, not in the package that implements them; Go's implicit satisfaction makes this possible and keeps dependencies pointing the right way.

**CR-37. return-concrete-types** Implementing packages should return concrete types (structs or pointers to structs), not interface types; this allows new methods to be added without breaking callers.

**CR-38. no-interface-for-mocking** Do not define an interface solely to support mocking in tests; design your API so it can be tested through its real public surface, or use a consumer-side fake.

**CR-39. no-premature-interface** Do not define an interface before you have a realistic use case; premature interfaces lead to awkward, over-abstract designs.

## Line Length

**CR-40. no-hard-line-limit** There is no hard line-length limit; break lines for semantic clarity (a natural pause in the logic), not to satisfy an arbitrary character count.

**CR-41. name-before-wrap** If a line feels too long, first consider whether a better name or a local variable would eliminate the length problem before adding a line break.

## Mixed Caps

\index{MixedCaps}

**CR-42. mixed-caps-always** Use `MixedCaps` (or `mixedCaps`) for multi-word names in all contexts, including constants: `maxLength` not `MAX_LENGTH`.

## Named Result Parameters

\index{named return values}

**CR-43. name-results-for-clarity** Name result parameters when doing so genuinely clarifies the meaning of multiple same-typed return values: `func Location() (lat, long float64, err error)`.

**CR-44. no-name-for-naked-return** Do not name result parameters solely to enable naked returns in non-trivial functions; the clarity cost of naked returns in longer functions outweighs the brevity gain.

**CR-45. name-for-deferred-modify** Naming a result parameter is appropriate when a deferred closure needs to modify it (e.g., to capture a close error).

## Package Comments

\index{package comment}

**CR-46. comment-adjacent-to-package** Package comments must appear immediately above the `package` clause with no blank line between them.

**CR-47. package-comment-sentence** Package comments must begin with a capital letter and be complete sentences: `// Package math provides basic constants and mathematical functions.`

**CR-48. main-package-comment-forms** For `main` packages, acceptable forms include: "Binary seedgen ...", "Command seedgen ...", or "The seedgen command ...".

## Package Names

\index{package!naming}

**CR-49. no-package-name-in-export** Remove the package name from exported identifiers: in package `chubby`, use `File` not `ChubbyFile` (callers write `chubby.File`).

**CR-50. no-generic-package-names** Avoid generic package names such as `util`, `common`, `misc`, `api`, `types`, and `interfaces`; they communicate nothing about purpose.

## Pass Values

\index{pointer!unnecessary}

**CR-51. no-pointer-to-save-bytes** Do not pass a pointer just to save a few bytes; if the function only dereferences `*x` throughout, the argument should not be a pointer.

**CR-52. no-pointer-to-string-or-iface** Do not pass pointers to strings (`*string`) or interface values (`*io.Reader`) just to save bytes; both are small fixed-size values that can be passed directly.

**CR-53. pointer-for-large-structs** Exception: large structs or structs expected to grow should be passed by pointer for efficiency.

## Receiver Names

\index{method receiver!naming}

**CR-54. receiver-name-abbreviation** The receiver name should be a short abbreviation of the type name (one or two letters), not `this`, `self`, or `me`.

**CR-55. receiver-name-consistent** The receiver name must be consistent across all methods of a type: if one method uses `c`, all must use `c`.

## Receiver Type

\index{method receiver!type}

**CR-56. pointer-receiver-for-mutation** Use a pointer receiver when the method needs to mutate the receiver.

**CR-57. pointer-receiver-for-mutex** Use a pointer receiver when the struct contains a `sync.Mutex` or similar synchronization field, to avoid copying the lock.

**CR-58. pointer-receiver-for-large** Use a pointer receiver for large structs or arrays where copying on each call would be expensive.

**CR-59. value-receiver-for-immutable** Use a value receiver for small, immutable structs or basic types (integers, strings) that hold no pointers and do not need mutation.

**CR-60. no-mixed-receivers** Do not mix value and pointer receivers on the same type; if any method needs a pointer receiver, use pointer receivers for all methods so the method set is consistent regardless of how the value is stored.

**CR-61. default-pointer-receiver** When in doubt, use a pointer receiver.

## Synchronous Functions

\index{synchronous function}

**CR-62. prefer-synchronous** Prefer synchronous functions --- those that return results directly or finish callbacks/channel operations before returning --- over asynchronous ones.

**CR-63. caller-adds-concurrency** If callers need concurrency, they can call a synchronous function from a goroutine; removing unnecessary concurrency from an API is much harder after the fact.

## Useful Test Failures

\index{testing!failure messages}

**CR-64. test-failure-describes-wrong** Test failure messages must describe what was wrong: state the inputs, the actual output, and the expected output.

**CR-65. actual-before-expected** Write failure messages in the order `actual != expected`: `t.Errorf("Foo(%q) = %d; want %d", in, got, want)`.

**CR-66. table-driven-tests** Use table-driven tests to reduce repetition and to ensure every case produces an identifiable failure message.

**CR-67. t-helper-for-helpers** Ensure test helpers produce useful failure messages that identify which case failed; use `t.Helper()` to attribute failures to the call site.

## Variable Names

\index{variable!naming}

**CR-68. short-local-names** Prefer short variable names, especially for local variables with limited scope: `c` over `lineCount`, `i` over `sliceIndex`.

**CR-69. scope-determines-length** The further a variable's use is from its declaration, the more descriptive its name must be; single-letter names are appropriate only for very short scopes.

**CR-70. descriptive-global-names** Global variables and variables representing unusual or domain-specific concepts require descriptive names.

---

# References {.unnumbered}

::: {#refs}
:::

```{=latex}
\printindex
```
