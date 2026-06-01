# Chapter 14: Packages and Modules --- Answers

**Exercise 1** (Think about it): Maven and Gradle resolve transitive dependencies automatically and let two artifacts declare conflicting version requirements for the same library.
They use a strategy (nearest-wins in Maven, highest-requested in Gradle) to pick a single version at build time.
Go's module system takes a different approach called Minimum Version Selection (MVS): it always picks the minimum version that satisfies all requirements.
Compare these two philosophies.
What problems does MVS avoid?
What does it make harder?
When might the Go approach cause a surprise after running `go get pkg@latest`?

Go's Minimum Version Selection works by computing the maximum of the minimum required versions across all modules in the dependency graph.
If module A requires `library v1.2.0` and module B requires `library v1.3.0`, Go selects `v1.3.0` --- the minimum version that satisfies both.
No module ever gets a version newer than the one its author tested against, unless someone explicitly requests an upgrade.

**Problems MVS avoids:**

- **Silent upgrades.**
  In Maven's nearest-wins model, adding a new dependency can silently pull in a newer (or older) version of a transitive library, breaking unrelated code.
  MVS never introduces a version you did not ask for.
- **Build irreproducibility.**
  Because MVS is deterministic and recorded in `go.sum`, two developers checking out the same commit always get bit-for-bit identical dependencies.
  Maven can produce different builds depending on which dependencies happen to be in the local repository cache.

**What MVS makes harder:**

- **Staying current.**
  MVS actively resists upgrading.
  If your dependency graph has pinned a library at `v1.2.0`, you will stay there until someone runs `go get library@v1.4.0`.
  In a large organisation this can mean security patches go unnoticed.
- **Downgrading.**
  If you want to use an older version than the graph currently requires, you have to remove or downgrade every module that requires the newer version.

**Surprise from `go get pkg@latest`:**
After you run `go get pkg@latest`, the upgraded module may itself require newer versions of transitive dependencies.
MVS will bump those transitives to the versions the new module requires --- which might be substantially newer than before.
Your `go.mod` can change in unexpected ways beyond the single module you asked to upgrade.
Running `go mod tidy` afterward and reviewing the diff in `go.mod` and `go.sum` is a good habit.

---

**Exercise 2** (What does this print?):

Given the following three files in a module `github.com/angoscia/demo`:

File `lyrics/lyrics.go`:
```go
package lyrics

import "fmt"

func Print() {
    fmt.Println("Emerald Triangle 2012")
}
```

File `lyrics/internal/detail/detail.go`:
```go
package detail

import "fmt"

func Show() {
    fmt.Println("internal detail")
}
```

File `main.go`:
```go
package main

import (
    "github.com/angoscia/demo/lyrics"
    "github.com/angoscia/demo/lyrics/internal/detail"
)

func main() {
    lyrics.Print()
    detail.Show()
}
```

What happens when you run `go build`?
If the build succeeds, what does the program print?
If not, explain why.

**The build fails.**

`main.go` is at the module root, which means its parent directory for the purposes of the `internal` rule is `github.com/angoscia/demo`.
The `internal` package's full path is `github.com/angoscia/demo/lyrics/internal/detail`.
For `main.go` to import it, `main.go` must live inside `github.com/angoscia/demo/lyrics` or one of its subdirectories.
`main.go` lives at the module root, which is `github.com/angoscia/demo` --- it is not rooted under `github.com/angoscia/demo/lyrics`, so the compiler rejects the import.

The compiler error will say something like:
```
use of internal package github.com/angoscia/demo/lyrics/internal/detail not allowed
```

The import of `github.com/angoscia/demo/lyrics` (the public package) is fine.
Only the `internal/detail` import is rejected.

To fix this, either move `detail` out of `lyrics/internal/` into a location that `main.go` is allowed to reach (such as `internal/detail` directly under the module root), or move `main.go` into a directory under `lyrics/`.

---

**Exercise 3** (Calculation): A module's `go.mod` contains the following:

```
module github.com/angoscia/app

go 1.26

require (
    github.com/angoscia/audio v1.4.0
    github.com/angoscia/catalog v0.9.2
    golang.org/x/text v0.14.0 // indirect
)
```

`github.com/angoscia/audio v1.4.0` itself requires `golang.org/x/text v0.12.0`.
`github.com/angoscia/catalog v0.9.2` requires `golang.org/x/text v0.14.0`.

Under Go's Minimum Version Selection, which version of `golang.org/x/text` will the final build use?
Explain why.
Now suppose you add a new dependency that requires `golang.org/x/text v0.16.0`.
What version will MVS select then?

**First scenario: `v0.14.0`.**

MVS collects the minimum required version from every module in the graph:
- `github.com/angoscia/app` itself requires `v0.14.0` (explicit `// indirect` entry).
- `github.com/angoscia/audio` requires `v0.12.0`.
- `github.com/angoscia/catalog` requires `v0.14.0`.

MVS takes the maximum of these minimums: `max(v0.14.0, v0.12.0, v0.14.0)` = **`v0.14.0`**.
The `// indirect` entry in the main module's `go.mod` already encodes this selection; `go mod tidy` placed it there when one of the direct dependencies required `v0.14.0` and the other only `v0.12.0`.

**Second scenario: `v0.16.0`.**

Adding a new dependency that requires `golang.org/x/text v0.16.0` raises the minimum for that module in the graph.
MVS selects `max(v0.14.0, v0.12.0, v0.14.0, v0.16.0)` = **`v0.16.0`**.
After `go mod tidy`, the `// indirect` entry in `go.mod` is updated to `golang.org/x/text v0.16.0`.
No other dependency's version changes.

---

**Exercise 4** (Where is the bug?): The following module has this layout and code:

```
betteroffalone/
├── go.mod           (module github.com/djcobra/betteroffalone)
├── main.go
└── internal/
    └── config/
        └── config.go
```

`player/main.go`:
```go
package main

import (
    "fmt"
    "github.com/djcobra/betteroffalone/internal/config"
)

func main() {
    fmt.Println(config.DefaultRegion)
}
```

What happens when you run `go build ./...` inside the `player/` module?
Identify the bug and describe how to fix it without moving the `config` package out of `internal/`.

**The build fails.**

The `internal/` package belongs to the module `github.com/djcobra/betteroffalone`.
The compiler's rule is that only code whose import path has `github.com/djcobra/betteroffalone` as a prefix may import packages under that module's `internal/`.
The `player` module has path `github.com/djcobra/player`, which does not share that prefix.
The build error will be:

```
use of internal package github.com/djcobra/betteroffalone/internal/config not allowed
```

**The fix --- without moving `config` out of `internal/`:**

The `config` package contains information that `betteroffalone` treats as a private implementation detail.
If `player` genuinely needs access to it, the right solution is for `betteroffalone` to expose the data through a **public API**.
Create an exported package, for example `github.com/djcobra/betteroffalone/region`, that wraps or re-exports the value from `internal/config`:

```go
// betteroffalone/region/region.go
package region

import "github.com/djcobra/betteroffalone/internal/config"

// DefaultRegion is the default geographic region.
var DefaultRegion = config.DefaultRegion
```

`player` then imports `github.com/djcobra/betteroffalone/region` instead of the internal package.
The internal package remains private; its values are accessible only through the deliberately designed public surface.

Alternatively, if `player` and `betteroffalone` are developed together and the restriction is inconvenient, use a Go workspace (`go work init ./betteroffalone ./player`) and promote `config` to a shared module or to a non-`internal` path.

---

**Exercise 5** (Write a program):

A complete implementation:

File `children/go.mod`:
```
module github.com/robertdreamhouse/children

go 1.26
```

File `children/tracks/tracks.go`:
```go
package tracks

// Track holds the title and artist of a song.
type Track struct {
    Title  string // song title
    Artist string // performing artist
}

// Catalog is the list of tracks in this module.
var Catalog = []Track{
    {Title: "Children",        Artist: "Robert Dream House"},
    {Title: "Better Off Alone", Artist: "DJ Cobra"},
}
```

File `children/internal/format/format.go`:
```go
package format

import (
    "fmt"
    "github.com/robertdreamhouse/children/tracks"
)

// Label returns a human-readable label for a track.
func Label(t tracks.Track) string {
    return fmt.Sprintf("%s by %s", t.Title, t.Artist)
}
```

File `children/main.go`:
```go
package main

import (
    "fmt"
    "github.com/robertdreamhouse/children/internal/format"
    "github.com/robertdreamhouse/children/tracks"
)

func main() {
    for _, t := range tracks.Catalog {
        fmt.Println(format.Label(t))
    }
}
```

Output:
```
Children by Robert Dream House
Better Off Alone by DJ Cobra
```

**Key observations:**

- `main.go` can import `internal/format` because it is inside the same module (`github.com/robertdreamhouse/children`).
  An external module attempting the same import would receive a compile error.
- `format.Label` is exported (capital `L`) so `main.go` can call it; it is still unreachable from outside the module because the package itself is under `internal/`.
- The `tracks` package is public --- any module that depends on `github.com/robertdreamhouse/children` could import it.
  Only `internal/format` is module-private.
