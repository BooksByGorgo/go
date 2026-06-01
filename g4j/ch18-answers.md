# Chapter 19: Testing --- Answers

**Exercise 1** (Think about it): JUnit 5's `@ParameterizedTest` with `@CsvSource` and Go's table-driven tests with `t.Run` both let you run the same logic against many inputs.
Describe two concrete advantages that Go's table-driven approach gives you over `@CsvSource`.
Then explain the key behavioral difference between `t.Fatal` and `t.Error` inside a subtest, and describe a scenario where you would deliberately choose `t.Error` over `t.Fatal`.

**Table-driven tests vs `@CsvSource` --- two concrete advantages:**

1. **Structured, type-safe test cases.**
   With `@CsvSource`, each row is a comma-separated string; numeric values must be parsed at runtime and type errors surface only when the test runs.
   A Go table is a slice of structs --- the compiler checks every field at compile time.
   If you rename a field or change its type, the build breaks immediately.
   There is no equivalent compile-time safety in `@CsvSource`.

2. **Arbitrary Go values in each case.**
   `@CsvSource` can only express types that JUnit knows how to convert from strings: primitives, strings, enums.
   A Go table can hold any value --- a function, an `error`, a struct, a slice --- as a field in the test case struct.
   This lets you express cases like "given this pre-built request object, expect this error" without any serialization or custom converter.

**`t.Fatal` vs `t.Error` inside a subtest:**

Inside a `t.Run` subtest, `t.Fatal` stops only that subtest's goroutine --- it calls `runtime.Goexit()` on the subtest's goroutine.
The outer test loop continues and the next subtest runs normally.
`t.Error` also affects only the subtest: it marks it as failed but the subtest continues executing.

A scenario where you would choose `t.Error` over `t.Fatal`: when you are validating multiple independent fields of a response struct and you want to see all failures at once.
For example, if you call an HTTP handler and want to check both the status code and the response body, use `t.Error` for each.
If you used `t.Fatal` on the status code check, a wrong status code would hide a potentially wrong body --- you would have to fix and re-run to see the body error.
With `t.Error`, one failing run shows you everything that is wrong.

---

**Exercise 2** (What does this print?): Trace the output when this test is run with `go test -v`.

```go
package music_test

import "testing"

func checkPositive(t *testing.T, n int) {
    if n <= 0 {
        t.Errorf("expected positive, got %d", n)
    }
}

func TestSoundOfSilence(t *testing.T) {
    checkPositive(t, 1)
    t.Log("checked 1")
    checkPositive(t, -1)
    t.Log("checked -1")
    checkPositive(t, 2)
    t.Log("checked 2")
}
```

Output (with `go test -v`):

```
=== RUN   TestSoundOfSilence
    music_test.go:7: expected positive, got -1
    music_test.go:11: checked 1
    music_test.go:13: checked -1
    music_test.go:15: checked 2
--- FAIL: TestSoundOfSilence (0.00s)
FAIL
```

**Key points to trace:**

- `checkPositive(t, 1)`: `1 > 0`, so no error is recorded.
- `t.Log("checked 1")`: message is queued.
- `checkPositive(t, -1)`: `-1 <= 0`, so `t.Errorf` is called.
  `t.Errorf` is `t.Error` with formatting --- it records a failure message and marks the test failed, but **does not stop execution**.
  The test keeps running.
- `t.Log("checked -1")`: message is queued.
- `checkPositive(t, 2)`: `2 > 0`, no error.
- `t.Log("checked 2")`: message is queued.
- Because the test is marked failed, all `t.Log` output is printed (with `-v`, log output is always printed regardless of pass/fail).

The test finishes with `--- FAIL`.
Execution continues past the failing check because `t.Errorf` is used, not `t.Fatalf`.

**Note on `t.Helper()` absence:**
`checkPositive` does not call `t.Helper()`.
As a result, the failure line reported is inside `checkPositive` (the `t.Errorf` call), not in `TestSoundOfSilence` where `checkPositive(-1)` was called.
Adding `t.Helper()` as the first line of `checkPositive` would make the reported line point to `checkPositive(t, -1)` in `TestSoundOfSilence` instead.

---

**Exercise 3** (Calculation): A benchmark function has the following structure:

```go
func BenchmarkCrazyTrain(b *testing.B) {
    for range b.N {
        _ = processTrack("Crazy Train")
    }
}
```

On the first probe the framework sets `b.N = 1` and measures elapsed time.
It then sets `b.N = 100`, then `b.N = 10_000`, then `b.N = 1_000_000`.
The framework stops when the total elapsed time exceeds one second.
If `processTrack` takes exactly 500 ns per call, at which value of `b.N` does the total elapsed time first exceed one second?
What is the reported ns/op value?

**Answer:**

Total elapsed time = `b.N × 500 ns`.

| b.N       | Total time             |
|-----------|------------------------|
| 1         | 500 ns                 |
| 100       | 50,000 ns = 50 µs      |
| 10,000    | 5,000,000 ns = 5 ms    |
| 1,000,000 | 500,000,000 ns = 500 ms |

None of those values exceeds one second.
The framework continues increasing `b.N`.
The next typical value after 1,000,000 is 2,000,000:

| b.N       | Total time             |
|-----------|------------------------|
| 2,000,000 | 1,000,000,000 ns = 1 s |

At `b.N = 2,000,000` the total time is exactly 1 second, which meets (ties) the threshold.

**b.N = 2,000,000** is where the run stops (or the next step after, depending on exact rounding in the real framework).

**Reported ns/op:**
The framework reports `total_time / b.N = 1,000,000,000 ns / 2,000,000 = 500 ns/op`.

This matches `processTrack`'s actual per-call cost --- the benchmark is accurate.

---

**Exercise 4** (Where is the bug?): The following test helper is supposed to make failure output point to the call site in `TestBadApple`, but it does not.
Identify the bug and show the fix.

```go
package music_test

import "testing"

func assertNormalized(t *testing.T, input, want string) {
    got := normalize(input)
    if got != want {
        t.Fatalf("normalize(%q): got %q, want %q", input, got, want)
    }
}

func TestBadApple(t *testing.T) {
    assertNormalized(t, "bad apple!!", "Bad Apple!!")
    assertNormalized(t, "better off alone", "Better Off Alone")
}
```

**The bug:** `assertNormalized` does not call `t.Helper()`.

When `t.Fatalf` fires inside `assertNormalized`, Go's test framework records the file and line number of the `t.Fatalf` call inside the helper.
The reported failure location is something like:

```
music_test.go:8: normalize("bad apple!!"): got "bad Apple!!", want "Bad Apple!!"
```

That points inside `assertNormalized`, not to the line in `TestBadApple` that triggered the failure.
You have to manually trace back to find which call site is responsible.

**The fix:** add `t.Helper()` as the first statement in `assertNormalized`:

```go
func assertNormalized(t *testing.T, input, want string) {
    t.Helper()  // attribute failures to the caller, not this function
    got := normalize(input)
    if got != want {
        t.Fatalf("normalize(%q): got %q, want %q", input, got, want)
    }
}
```

With `t.Helper()` present, the reported failure location becomes:

```
music_test.go:13: normalize("bad apple!!"): got "bad Apple!!", want "Bad Apple!!"
```

That line number points directly to `assertNormalized(t, "bad apple!!", "Bad Apple!!")` in `TestBadApple`, which is exactly where the problematic call lives.

**Secondary note:** `t.Fatalf` inside a helper is fine when subsequent checks in the same test function would be meaningless if this check fails.
Here, if `normalize("bad apple!!")` returns a wrong value the second check can still run independently, so `t.Errorf` could be argued as a better choice --- but whether to use `Fatal` or `Error` is a judgment call; the `t.Helper()` omission is the clear bug.

---

**Exercise 5** (Write a program): Write a table-driven test for `TitleCase`.
Your test must include at least five cases covering normal input, empty string, all-caps input, and a multi-word title.
Use `t.Run` for each case and `t.Helper` in any helper you write.

```go
package music_test

import (
    "strings"
    "testing"
    "unicode"
)

// TitleCase converts a string to title case.
// Each word's first letter is uppercased; the rest are lowercased.
// Words are separated by spaces.
func TitleCase(s string) string {
    words := strings.Fields(s)
    for i, w := range words {
        if len(w) == 0 {
            continue
        }
        runes := []rune(w)
        runes[0] = unicode.ToUpper(runes[0])
        for j := 1; j < len(runes); j++ {
            runes[j] = unicode.ToLower(runes[j])
        }
        words[i] = string(runes)
    }
    return strings.Join(words, " ")
}

// assertEqual is a helper that reports mismatches at the caller's site.
func assertEqual(t *testing.T, got, want, label string) {
    t.Helper()
    if got != want {
        t.Errorf("%s: got %q, want %q", label, got, want)
    }
}

func TestTitleCase(t *testing.T) {
    cases := []struct {
        name  string
        input string
        want  string
    }{
        {name: "empty",         input: "",                      want: ""},
        {name: "single word",   input: "silence",               want: "Silence"},
        {name: "multi-word",    input: "better off alone",      want: "Better Off Alone"},
        {name: "all caps",      input: "BAD APPLE!!",           want: "Bad Apple!!"},
        {name: "mixed case",    input: "cRAzY tRaIn",           want: "Crazy Train"},
        {name: "already title", input: "Better Off Alone",      want: "Better Off Alone"},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            got := TitleCase(tc.input)
            assertEqual(t, got, tc.want, "TitleCase("+tc.input+")")
        })
    }
}
```

Running `go test -v` produces:

```
=== RUN   TestTitleCase
=== RUN   TestTitleCase/empty
=== RUN   TestTitleCase/single_word
=== RUN   TestTitleCase/multi-word
=== RUN   TestTitleCase/all_caps
=== RUN   TestTitleCase/mixed_case
=== RUN   TestTitleCase/already_title
--- PASS: TestTitleCase (0.00s)
    --- PASS: TestTitleCase/empty (0.00s)
    --- PASS: TestTitleCase/single_word (0.00s)
    --- PASS: TestTitleCase/multi-word (0.00s)
    --- PASS: TestTitleCase/all_caps (0.00s)
    --- PASS: TestTitleCase/mixed_case (0.00s)
    --- PASS: TestTitleCase/already_title (0.00s)
PASS
```

**Notes on the solution:**

- The `name` field in each case struct is passed to `t.Run`, producing descriptive subtest names in the output.
  A failing case shows up as `--- FAIL: TestTitleCase/all_caps` rather than just `--- FAIL: TestTitleCase`.
- `assertEqual` calls `t.Helper()` so that any failure message points to the line inside the `t.Run` body that called `assertEqual`, not to the `t.Errorf` line inside `assertEqual` itself.
- `t.Errorf` (not `t.Fatalf`) is used in the helper because each subtest has only one assertion; there is no reason to stop early.
  If the helper checked multiple things, `t.Fatalf` could be appropriate for a critical precondition.
- The six cases satisfy the problem requirements: empty string, single word (normal), multi-word, all-caps, and mixed case.
  The "already title" case is a bonus regression check.
