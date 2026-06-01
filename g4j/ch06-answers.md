# Chapter 6: Methods and Embedding --- Answers

**Exercise 1** (Think about it): In Java, a class bundles data and behavior together and inheritance lets you share both across a type hierarchy.
Go separates data (struct), behavior (methods), and code reuse (embedding) into three distinct mechanisms, and interfaces handle polymorphism independently of all three.
What advantages does Go's separated approach offer over Java's unified class model?
Can you think of a scenario where Java's approach is simpler or more convenient?

**Advantages of Go's separated approach:**

1. **You can attach methods to any type, not just classes.**
   In Java, methods live inside class bodies and you cannot add methods to types defined in other packages.
   In Go, you can define methods on any named type in the same package, including types imported from the standard library via type definitions (e.g., `type Seconds float64`).

2. **Code reuse without coupling.**
   Java inheritance forces an is-a relationship: `FeaturedTrack extends Track` means every `FeaturedTrack` is substitutable for a `Track`.
   Go embedding is a has-a relationship with no substitutability.
   You get promoted fields and methods without locking yourself into a hierarchy that may become wrong later.

3. **Interfaces decouple behavior from data completely.**
   A type satisfies a Go interface without knowing the interface exists.
   This lets you define interfaces in the consumer package, not the producer package, making dependencies flow the right way.

4. **No fragile base-class problem.**
   Java's virtual dispatch means a change to a superclass method can silently alter the behavior of all subclasses.
   Go's promoted methods are not virtual: calling a promoted method on an outer struct always calls the embedded type's method, unless the outer struct explicitly defines its own method with the same name.

**Where Java's approach is simpler:**

- When you genuinely want polymorphism through a type hierarchy (e.g., a UI widget tree), Java's `extends` gives you substitutability, virtual dispatch, and `instanceof` checks in one declaration.
  In Go you need an interface plus embedding, and you must ensure both the outer and inner types implement the interface explicitly.
- A `toString()` override in Java is automatic through the `Object` base class.
  In Go, `fmt.Stringer` requires you to implement `String() string` on each type that wants custom formatting; there is no default.

---

**Exercise 2** (What does this print?):

```go
package main

import "fmt"

type Base struct {
    ID int
}

func (b Base) Describe() string {
    return fmt.Sprintf("Base ID=%d", b.ID)
}

type Widget struct {
    Base
    Color string
}

func main() {
    w := Widget{
        Base:  Base{ID: 42},
        Color: "blue",
    }
    fmt.Println(w.ID)
    fmt.Println(w.Color)
    fmt.Println(w.Describe())
    fmt.Println(w.Base.Describe())
}
```

Output:
```
42
blue
Base ID=42
Base ID=42
```

`w.ID` is promoted from `w.Base.ID` --- accessing `w.ID` and `w.Base.ID` reach the same field.
`w.Color` is a direct field of `Widget`.
`w.Describe()` calls the promoted `Base.Describe()` method, because `Widget` has no `Describe` method of its own.
`w.Base.Describe()` calls the same method through the explicit path.
Both calls produce identical output.

---

**Exercise 3** (Calculation): Trace the following program by hand.

```go
package main

import "fmt"

type Track struct {
    Title  string
    Artist string
    BPM    int
}

func (t Track) String() string {
    return fmt.Sprintf("%s by %s", t.Title, t.Artist)
}

type FeaturedTrack struct {
    Track
    Feature string
}

func (ft FeaturedTrack) String() string {
    return ft.Track.String() + " ft. " + ft.Feature
}

func main() {
    t := Track{Title: "Gamemaster", Artist: "Matt Darey & Lost Tribe", BPM: 97}
    ft := FeaturedTrack{Track: t, Feature: "Alizée"}

    fmt.Println(t.String())
    fmt.Println(ft.String())
    fmt.Println(ft.Track.String())
    fmt.Println(ft.BPM)
}
```

Output:
```
Gamemaster by Matt Darey & Lost Tribe
Gamemaster by Matt Darey & Lost Tribe ft. Alizée
Gamemaster by Matt Darey & Lost Tribe
97
```

Step by step:

- `t.String()`: calls `Track.String()` directly on `t`. Returns `"Gamemaster by Matt Darey & Lost Tribe"`.
- `ft.String()`: `FeaturedTrack` has its own `String()` method, so the promoted `Track.String()` is shadowed.
  `FeaturedTrack.String()` calls `ft.Track.String()` (returns `"Gamemaster by Matt Darey & Lost Tribe"`) and appends `" ft. "` and `ft.Feature`.
  Returns `"Gamemaster by Matt Darey & Lost Tribe ft. Alizée"`.
- `ft.Track.String()`: calls `Track.String()` through the explicit embedded path, bypassing `FeaturedTrack.String()`.
  Returns `"Gamemaster by Matt Darey & Lost Tribe"`.
- `ft.BPM`: promoted from `ft.Track.BPM`. The value is `97`.

The key insight: writing `ft.String()` calls `FeaturedTrack.String()` (the outer type's method), while `ft.Track.String()` bypasses the outer method and calls `Track.String()` directly.

---

**Exercise 4** (Where is the bug?):

```go
package main

import "fmt"

type Artist struct {
    Name string
}

func (a Artist) Label() string {
    return "Artist: " + a.Name
}

type Song struct {
    *Artist
    Title string
}

func main() {
    s := Song{Title: "Out Of The Blue"}
    fmt.Println(s.Title)
    fmt.Println(s.Label()) // line A
}
```

**The bug:** `Song` is initialized without setting the `*Artist` pointer, so `s.Artist` is `nil`.
The first `fmt.Println(s.Title)` prints `"Out Of The Blue"` successfully.
The second call `s.Label()` is promoted from the embedded `*Artist`.
To call a method on the embedded type, Go dereferences the embedded pointer.
Dereferencing a `nil` pointer causes a runtime panic:

```
panic: runtime error: invalid memory address or nil pointer dereference
```

**Fix:** initialize the embedded pointer before use:

```go
s := Song{
    Artist: &Artist{Name: "System F"},
    Title:  "Out Of The Blue",
}
fmt.Println(s.Title)   // Out Of The Blue
fmt.Println(s.Label()) // Artist: System F
```

Alternatively, construct `Song` using `NewSong` to enforce initialization:

```go
func NewSong(title, artistName string) Song {
    return Song{Artist: &Artist{Name: artistName}, Title: title}
}
```

---

**Exercise 5** (Write a program):

```go
package main

import "fmt"

type Counter struct {
    Value int
}

func NewCounter(start int) *Counter {   // constructor: returns *Counter so callers can use pointer receivers
    return &Counter{Value: start}
}

func (c *Counter) Increment() {         // pointer receiver: mutates Value
    c.Value++
}

func (c *Counter) Reset() {             // pointer receiver: mutates Value
    c.Value = 0
}

func (c *Counter) String() string {     // pointer receiver for consistency
    return fmt.Sprintf("count: %d", c.Value)
}

func main() {
    c := NewCounter(10)
    c.Increment()
    c.Increment()
    c.Increment()
    fmt.Println(c)  // count: 13
    c.Reset()
    fmt.Println(c)  // count: 0
}
```

Output:
```
count: 13
count: 0
```

Notes:
- `NewCounter` returns `*Counter` so every method call works without taking an address at the call site.
- All three methods use pointer receivers for consistency --- since `Increment` and `Reset` must mutate `c.Value`, all methods on `*Counter` use the pointer form.
- `fmt.Println(c)` calls `c.String()` automatically because `*Counter` satisfies `fmt.Stringer` (which requires `String() string`).
