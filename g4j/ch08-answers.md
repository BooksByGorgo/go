# Chapter 8: Error Handling --- Answers

**Exercise 1** (Think about it): Java uses checked exceptions to force callers to handle failures.
Go returns `error` values that the compiler does not require you to inspect.
What are the trade-offs of each approach?
In what situations does Go's approach lead to more reliable code, and in what situations might it lead to less reliable code compared to Java's checked exceptions?

Java's checked exceptions make the compiler your partner: if a method declares `throws IOException`, every caller must either catch it or re-declare the throws clause.
This guarantees that failure modes are documented in method signatures and that callers cannot silently ignore them --- the code will not compile otherwise.

Go takes the opposite position: `error` is a return value like any other.
The compiler does not prevent you from discarding it with `_` or simply not capturing it at all.
The discipline must come from the programmer and tooling (`errcheck`, `staticcheck`) rather than the language itself.

**Where Go tends to win:**

- Error handling becomes regular control flow, not exception propagation through a separate, parallel mechanism.
Errors can be stored in slices, combined with `errors.Join`, and processed with the same code that handles any other value.
- There is no checked-exception pollution: Java's `throws` clauses ripple upward through call chains, forcing every intermediate method to declare or re-wrap exceptions even when it has nothing meaningful to add.
Go functions that merely forward an error just `return err` --- no signature change required.
- Errors do not skip stack frames invisibly.
The flow of control through a Go program is always traceable by reading the `if err != nil` checks; no hidden stack unwinding occurs.

**Where Java's checked exceptions tend to win:**

- The compiler catches ignored errors at the call site.
A Go developer who writes `n, _ := parseTrackNumber(s)` has silently discarded the error, and the compiler says nothing.
- Checked exceptions create a discoverable, machine-readable contract: the method signature lists every failure mode.
Go's error convention requires reading documentation or source code to learn what errors a function may return.
- Refactoring is easier in Java when you add a new failure mode: the compiler identifies every call site that needs updating.
In Go, adding a new error condition to a function is invisible to callers.

**The bottom line:**
Go trades compile-time enforcement for simplicity and composability.
The approach works well in teams that run linters and review code carefully, and it shines in functions that produce or transform errors as data.
It can lead to less reliable code in projects where error checking is informal or tooling is not enforced.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "errors"
    "fmt"
)

var ErrNotFound = errors.New("not found")

type CatalogError struct {
    Track string
    Err   error
}

func (e *CatalogError) Error() string {
    return fmt.Sprintf("catalog: %s: %s", e.Track, e.Err)
}

func (e *CatalogError) Unwrap() error {
    return e.Err
}

func lookup(track string) error {
    return &CatalogError{Track: track, Err: ErrNotFound}
}

func main() {
    err := lookup("Tití Me Preguntó")
    fmt.Println(err)
    fmt.Println(errors.Is(err, ErrNotFound))

    var ce *CatalogError
    if errors.As(err, &ce) {
        fmt.Println(ce.Track)
    }
}
```

Output:

```
catalog: Tití Me Preguntó: not found
true
Tití Me Preguntó
```

**Line-by-line explanation:**

`lookup("Tití Me Preguntó")` returns a `*CatalogError` with `Track = "Tití Me Preguntó"` and `Err = ErrNotFound`.

`fmt.Println(err)` calls `err.Error()`, which returns `"catalog: Tití Me Preguntó: not found"`.
`fmt.Println` appends a newline, so the first line of output is `catalog: Tití Me Preguntó: not found`.

`errors.Is(err, ErrNotFound)` starts at `err` (a `*CatalogError`) and calls `==` against `ErrNotFound` --- no match.
It then calls `err.Unwrap()`, which returns `ErrNotFound` itself.
`ErrNotFound == ErrNotFound` is `true`.
So `errors.Is` returns `true`, and `fmt.Println(true)` prints `true`.

`errors.As(err, &ce)` checks whether `err` is assignable to `*CatalogError`.
It is, so `ce` is set to the `*CatalogError` value and `errors.As` returns `true`.
The `if` body prints `ce.Track`, which is `"Tití Me Preguntó"`.

---

**Exercise 3** (Calculation): Consider the following code.
How many distinct, non-nil error values does `validateSong` return for the input `Song{Title: "", Artist: "Karol G", Year: 2021, BPM: -1}`?
What is the output of `fmt.Println(err)` for that input?

```go
package main

import (
    "errors"
    "fmt"
)

type Song struct {
    Title  string
    Artist string
    Year   int
    BPM    int
}

func validateSong(s Song) error {
    var errs []error
    if s.Title == "" {
        errs = append(errs, errors.New("title required"))
    }
    if s.Year < 2000 || s.Year > 2030 {
        errs = append(errs, fmt.Errorf("year %d out of range", s.Year))
    }
    if s.BPM <= 0 {
        errs = append(errs, errors.New("BPM must be positive"))
    }
    return errors.Join(errs...)
}

func main() {
    s := Song{Title: "", Artist: "Karol G", Year: 2021, BPM: -1}
    err := validateSong(s)
    fmt.Println(err)
}
```

**Answer:** `validateSong` collects **2** distinct, non-nil error values.

Trace through the conditions for `Song{Title: "", Artist: "Karol G", Year: 2021, BPM: -1}`:

- `s.Title == ""` is `true` --- `errors.New("title required")` is appended. (1 error)
- `s.Year < 2000 || s.Year > 2030`: `2021 < 2000` is `false`; `2021 > 2030` is `false` --- condition is `false`, no error appended.
- `s.BPM <= 0`: `-1 <= 0` is `true` --- `errors.New("BPM must be positive")` is appended. (2 errors)

`errors.Join` receives a slice of 2 non-nil errors.
Its `Error()` method joins their messages with a newline between them.

Output:

```
title required
BPM must be positive
```

Note that `Artist` has no validation rule, so `"Karol G"` (a valid, non-empty value) does not contribute any error.
`Year = 2021` falls within the range `[2000, 2030]`, so no year error is produced either.

---

**Exercise 4** (Where is the bug?):

```go
package main

import (
    "errors"
    "fmt"
    "io"
)

func readAll(r io.Reader) ([]byte, error) {
    buf := make([]byte, 4)
    var result []byte
    for {
        n, err := r.Read(buf)
        result = append(result, buf[:n]...)
        if err == io.EOF {
            break
        }
        if err != nil {
            return nil, fmt.Errorf("readAll: %w", err)
        }
    }
    return result, nil
}

func main() {
    r := strings.NewReader("TQG")
    data, err := readAll(r)
    if err != nil {
        fmt.Println("error:", err)
        return
    }
    fmt.Println(string(data))
}
```

**The bug:** There are actually two problems.

**Bug 1 --- missing import:** `strings.NewReader` is used in `main` but `"strings"` is not in the import list.
The program will not compile.
The import block should be:

```go
import (
    "errors"
    "fmt"
    "io"
    "strings"
)
```

**Bug 2 --- comparing `err == io.EOF` directly instead of using `errors.Is`:** The sentinel check `if err == io.EOF` works correctly for `io.EOF` itself, but it will silently miss `io.EOF` if the reader ever wraps it (e.g., `fmt.Errorf("read: %w", io.EOF)`).
The idiomatic fix is:

```go
if errors.Is(err, io.EOF) {
    break
}
```

Using `errors.Is` is consistent, future-proof, and is what the chapter recommends.
The `errors` import is already present, so this is a zero-cost change.

**Corrected `readAll`:**

```go
func readAll(r io.Reader) ([]byte, error) {
    buf := make([]byte, 4)
    var result []byte
    for {
        n, err := r.Read(buf)
        result = append(result, buf[:n]...)
        if errors.Is(err, io.EOF) {
            break
        }
        if err != nil {
            return nil, fmt.Errorf("readAll: %w", err)
        }
    }
    return result, nil
}
```

With both fixes applied, the program compiles and prints:

```
TQG
```

---

**Exercise 5** (Write a program):

```go
package main

import (
    "errors"
    "fmt"
    "strconv"
    "strings"
)

var ErrInvalidTimecode = errors.New("invalid timecode")

func parseTimecode(s string) (int, int, int, error) {
    parts := strings.Split(s, ":")
    if len(parts) != 2 {
        return 0, 0, 0, fmt.Errorf("parseTimecode: expected MM:SS, got %q: %w", s, ErrInvalidTimecode)
    }

    minutes, err := strconv.Atoi(parts[0])
    if err != nil {
        return 0, 0, 0, fmt.Errorf("parseTimecode: invalid minutes %q: %w", parts[0], ErrInvalidTimecode)
    }

    seconds, err := strconv.Atoi(parts[1])
    if err != nil {
        return 0, 0, 0, fmt.Errorf("parseTimecode: invalid seconds %q: %w", parts[1], ErrInvalidTimecode)
    }

    if minutes < 0 {
        return 0, 0, 0, fmt.Errorf("parseTimecode: minutes %d is negative: %w", minutes, ErrInvalidTimecode)
    }
    if seconds < 0 || seconds > 59 {
        return 0, 0, 0, fmt.Errorf("parseTimecode: seconds %d out of range [0,59]: %w", seconds, ErrInvalidTimecode)
    }

    total := minutes*60 + seconds
    return minutes, seconds, total, nil
}

func main() {
    inputs := []string{"03:45", "345", "01:61"}

    for _, tc := range inputs {
        m, s, total, err := parseTimecode(tc)
        if err != nil {
            fmt.Printf("%-10s => error: %s\n", tc, err)
            fmt.Printf("           is ErrInvalidTimecode: %v\n", errors.Is(err, ErrInvalidTimecode))
        } else {
            fmt.Printf("%-10s => %dm %ds (%d total seconds)\n", tc, m, s, total)
        }
    }
}
```

Output:

```
03:45      => 3m 45s (225 total seconds)
345        => error: parseTimecode: expected MM:SS, got "345": invalid timecode
           is ErrInvalidTimecode: true
01:61      => error: parseTimecode: seconds 61 out of range [0,59]: invalid timecode
           is ErrInvalidTimecode: true
```

**Key design decisions explained:**

- `ErrInvalidTimecode` is a package-level sentinel declared with `errors.New`.
Exporting it (capital `E`) lets callers in other packages use `errors.Is` to distinguish timecode errors from other error kinds.

- Every error path uses `fmt.Errorf("...: %w", ErrInvalidTimecode)` to wrap the sentinel.
This means the returned error has a human-readable message that includes the context (the bad input, the specific reason) **and** a chain that `errors.Is` can walk to find `ErrInvalidTimecode`.

- The function returns four values: `(int, int, int, error)`.
The three `int` values are zero on error, consistent with the Go convention of returning zero values alongside a non-nil error.

- `strings.Split(s, ":")` with a check on `len(parts) != 2` is the idiomatic way to parse a two-part format.
Using `fmt.Sscanf` or a regex are also valid; `strings.Split` is the most readable for this simple case.
