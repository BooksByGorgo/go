# Chapter 14: Essential Standard Library --- Answers

**Exercise 1** (Think about it): In Java, `InputStream`, `OutputStream`, `Reader`, and `Writer` are four separate abstract class hierarchies.
Go has two interfaces --- `io.Reader` and `io.Writer` --- and a set of composition functions.
What design decision makes Go's two-interface model work where Java needed four base classes?
What would be harder to express cleanly in Go's model?

The key difference is that Java's hierarchy distinguishes between **byte-oriented** I/O (`InputStream`/`OutputStream`) and **character-oriented** I/O (`Reader`/`Writer`), with four root types as a result.
Go does not make that split at the interface level: `io.Reader` and `io.Writer` always deal in `[]byte`.
Character encoding is handled separately --- either at the edges (e.g., `bufio.Scanner` which returns `string` tokens), or by explicit conversion.
This simplification is possible because Go treats `string` and `[]byte` as first-class, cheaply convertible types, so the language does not need a parallel hierarchy to make text feel natural.

The composition functions (`io.TeeReader`, `io.MultiWriter`, etc.) are ordinary functions that return an interface value.
In Java the same decorators are abstract classes (`FilterInputStream`, `BufferedInputStream`) because the language needed a concrete supertype to share implementation; Go can express the same patterns with zero-allocation wrappers because interfaces are structural.

What is harder in Go's model:

- **Seeking and positioning.** Java's `RandomAccessFile` supports `seek` directly.
  Go separates this into `io.Seeker` (a third interface) and requires callers to do a type assertion or accept an `io.ReadSeeker` parameter.
- **Buffered reads with unread/pushback.** Java's `PushbackInputStream` is a first-class class.
  In Go you use `bufio.Reader.UnreadByte()` or `bufio.Reader.UnreadRune()`, which requires wrapping in `bufio` first.
- **Encoding-aware text I/O.** Java's `InputStreamReader` bridges bytes to characters with a named charset.
  In Go you must use third-party packages (e.g., `golang.org/x/text/encoding`) or write the conversion yourself.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "bufio"
    "log/slog"
    "os"
    "strings"
    "time"
)

func main() {
    logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
        ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
            if a.Key == slog.TimeKey {
                return slog.Attr{}  // suppress the timestamp
            }
            return a
        },
    }))

    input := "Café Del Mar\nZombie\nCrazy Train\n"
    scanner := bufio.NewScanner(strings.NewReader(input))
    count := 0
    for scanner.Scan() {
        count++
    }

    logger.Info("scan complete",
        slog.Int("lines", count),
        slog.Duration("elapsed", 0*time.Millisecond),
    )
}
```

Output:
```
level=INFO msg="scan complete" lines=3 elapsed=0s
```

Step-by-step:

1. A `slog.TextHandler` is created writing to `os.Stdout`.
   The `ReplaceAttr` function strips the `time` attribute, so no timestamp appears.
2. `strings.NewReader` wraps the literal string as an `io.Reader`.
   `bufio.NewScanner` wraps that reader.
3. The scanner splits on newlines (the default).
   The input has three non-empty lines (`"Café Del Mar"`, `"Zombie"`, `"Crazy Train"`) followed by a trailing newline.
   `Scan` returns `true` three times and then `false` at EOF, so `count` ends up as `3`.
4. `logger.Info` emits a text-format log line.
   The `time` key is suppressed by `ReplaceAttr`.
   `slog.Int("lines", 3)` formats as `lines=3`.
   `slog.Duration("elapsed", 0)` formats as `elapsed=0s` --- `time.Duration` zero-value formats as `"0s"`.

The exact key ordering in `log/slog` text format is: `level`, `msg`, then attributes in the order they were passed.

---

**Exercise 3** (Calculation): You open a 10 MiB file and read it in three ways:
(a) `os.ReadFile` into a `[]byte`,
(b) `bufio.NewScanner` reading line by line,
(c) `io.Copy(io.Discard, f)` using the default 32 KiB copy buffer.
For each approach, estimate the peak heap allocation in MiB, assuming the file contains 100,000 lines of 100 bytes each.
Which approach is best for counting lines without storing the content?

The file is 100,000 lines × 100 bytes = 10,000,000 bytes ≈ **9.5 MiB**.

**(a) `os.ReadFile`**

`os.ReadFile` reads the entire file into a single `[]byte`.
Peak heap allocation: ≈ **9.5 MiB** (the whole file in one slice).
Additionally, if you process the result into strings or split on newlines, you may double or triple the allocation.
This is the simplest approach but the most memory-hungry for large files.

**(b) `bufio.NewScanner`**

`Scanner` uses an internal buffer (default 64 KiB maximum token size, starting at 4 KiB).
It reads the file in chunks, scanning for newline boundaries.
At any instant, only the current chunk plus the current token are in memory.
Peak heap allocation: ≈ **64 KiB** (the scanner's internal buffer) plus the length of the longest individual line.
For 100-byte lines this is well under 1 MiB.

**(c) `io.Copy(io.Discard, f)`**

`io.Copy` uses a single 32 KiB stack-allocated copy buffer (it uses `*[32*1024]byte` internally; in practice this ends up on the heap due to escape analysis, but it is still a single fixed allocation).
Peak heap allocation: ≈ **32 KiB**.
However, this approach does not count lines --- it just discards all bytes.

**Best for counting lines without storing content: `bufio.NewScanner`.**

`io.Copy(io.Discard, f)` uses the least memory but cannot count lines without inspecting the bytes.
`bufio.NewScanner` counts lines with a constant-size buffer (< 1 MiB peak) and is the idiomatic Go choice.
`os.ReadFile` uses the most memory and should be avoided for large files.

---

**Exercise 4** (Where is the bug?):

```go
package main

import (
    "fmt"
    "regexp"
)

func countMatches(texts []string, pattern string) int {
    total := 0
    for _, t := range texts {
        re := regexp.MustCompile(pattern)
        if re.MatchString(t) {
            total++
        }
    }
    return total
}

func main() {
    titles := []string{"Crazy Train", "Café Del Mar", "Zombie", "The Sound of Silence"}
    fmt.Println(countMatches(titles, `^[A-Z]`))
}
```

**The bug:** `regexp.MustCompile(pattern)` is called inside the `for` loop, so the pattern is compiled on every iteration.
With four strings this is merely wasteful, but inside a hot path processing millions of records it becomes a serious performance problem --- `regexp.MustCompile` parses the pattern, builds a finite automaton, and allocates memory each time.

The output is correct (it prints `4`, matching all four titles which start with an uppercase letter), so this is a **performance bug**, not a logic bug.

**The fix:** Compile the pattern once, before the loop.
If the pattern is constant, hoist it to a package-level variable:

```go
var startsUpperRE = regexp.MustCompile(`^[A-Z]`)

func countMatches(texts []string) int {
    total := 0
    for _, t := range texts {
        if startsUpperRE.MatchString(t) {
            total++
        }
    }
    return total
}
```

If the pattern is a runtime parameter, compile it once before the loop and return an error if the pattern is invalid:

```go
func countMatches(texts []string, pattern string) (int, error) {
    re, err := regexp.Compile(pattern)
    if err != nil {
        return 0, fmt.Errorf("invalid pattern %q: %w", pattern, err)
    }
    total := 0
    for _, t := range texts {
        if re.MatchString(t) {
            total++
        }
    }
    return total, nil
}
```

Note the switch from `MustCompile` to `Compile` with a returned error --- caller-supplied patterns should never `MustCompile` because a bad pattern would crash the program.
`MustCompile` is reserved for compile-time-constant patterns where a bad pattern is a programmer error, not a user error.

---

**Exercise 5** (Write a program):

```go
package main

import (
    "flag"
    "fmt"
    "io/fs"
    "log/slog"
    "os"
    "path/filepath"
    "strings"
)

func main() {
    dir     := flag.String("dir",     ".",   "directory to search")
    ext     := flag.String("ext",     ".go", "file extension to count")
    verbose := flag.Bool("verbose",   false, "log each matching file")
    flag.Parse()

    logger := slog.New(slog.NewTextHandler(os.Stderr, nil))

    count := 0
    err := filepath.WalkDir(*dir, func(path string, d fs.DirEntry, err error) error {
        if err != nil {
            return err
        }
        if !d.IsDir() && strings.HasSuffix(d.Name(), *ext) {
            count++
            if *verbose {
                logger.Info("match", slog.String("file", path))
            }
        }
        return nil
    })
    if err != nil {
        logger.Error("walk failed", slog.Any("error", err))
        os.Exit(1)
    }

    fmt.Printf("found %d %s file(s) in %s\n", count, *ext, *dir)
}
```

Sample runs:

```
$ go run main.go -dir . -ext .go -verbose
time=... level=INFO msg=match file=main.go
found 1 .go file(s) in .

$ go run main.go -dir /usr/local/go/src -ext .go
found 1847 .go file(s) in /usr/local/go/src
```

Key points in the solution:

- `flag.Parse()` is called at the start of `main`, after all flag variables are defined, so all flags are parsed before use.
- `slog.New(slog.NewTextHandler(os.Stderr, nil))` writes structured logs to stderr, leaving stdout clean for program output.
- `filepath.WalkDir` is preferred over `filepath.Walk` because it passes `fs.DirEntry` (which avoids an extra `os.Stat` call per entry).
- `strings.HasSuffix(d.Name(), *ext)` matches only the file name, not the full path, so `--ext .go` does not accidentally match a directory named `foo.go/`.
- The error from `WalkDir` is checked and reported; a non-nil error from the callback halts the walk.
