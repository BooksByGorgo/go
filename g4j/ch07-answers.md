# Chapter 5: Maps and Slices --- Answers

**Exercise 1** (Think about it): In Java, `HashMap<K,V>` requires keys to implement `hashCode()` and `equals()`, and `ArrayList<E>` stores references to boxed objects on the heap.
Go's `map[K]V` requires `K` to be comparable at the language level, and a `[]E` slice stores values directly in the backing array.
What are the trade-offs of Go's approach for each collection type?
Give one example of a Java key type you cannot use directly as a Go map key, and explain one scenario where storing values directly in a slice (rather than as heap references) matters for performance.
When would you feel the difference most?

A Java `ArrayList<Integer>` stores a pointer (reference) to each boxed `Integer` object, and each `Integer` object lives somewhere on the heap.
Iterating over the list means following a pointer for every element, and those `Integer` objects may be scattered around memory --- poor cache locality.
Each `Integer` also carries object header overhead (typically 16 bytes) even though the actual integer value is just 4 bytes.

A Go `[]int` stores the integer values **directly** and **contiguously** in the backing array.
Iterating is a sequential scan through a flat region of memory: the CPU prefetcher handles this extremely well.
There is no per-element allocation overhead and no pointer chasing.

You feel the difference most in:

- **Tight loops** that process large slices: the sequential memory access pattern is cache-friendly, and modern CPUs can vectorize flat integer arrays.
- **Memory usage**: a Go `[]int` of a million elements is roughly 8 MB (64-bit ints).
  A Java `ArrayList<Integer>` of a million elements is the list's pointer array (8 MB of references) plus a million `Integer` objects on the heap (at least 16 MB more), for a minimum of 24 MB --- and GC pressure from all those small objects.
- **GC pauses**: the Go garbage collector has no pointers to trace inside a `[]int`, so it scans the array in constant time.
  A Java `ArrayList<Integer>` forces the GC to follow a million references.

The trade-off is that Go's approach works for slices of value types (`int`, `float64`, structs).
For slices of interfaces or pointers, Go has the same indirection that Java does.

---


**Exercise 2** (What does this print?):

```go
package main

import "fmt"

func main() {
    catalog := map[string]int{
        "Saltwater":       1_200_000_000,
        "Out Of The Blue":  980_000_000,
    }
    hits := []string{"Out Of The Blue", "Watermelon Sugar", "Saltwater"}
    for _, title := range hits {
        if plays, ok := catalog[title]; ok {
            fmt.Printf("%s: %d\n", title, plays)
        } else {
            fmt.Printf("%s: not found\n", title)
        }
    }
}
```

Output:
```
Out Of The Blue: 980000000
Watermelon Sugar: not found
Saltwater: 1200000000
```

The loop iterates the `hits` slice in order.
`"Out Of The Blue"` is in the catalog and its play count is printed.
`"Watermelon Sugar"` is not in the catalog, so the comma-ok idiom sets `ok = false` and the `else` branch runs.
`"Saltwater"` is in the catalog and is printed last.
Map lookup order is random, but slice range iteration is always in index order, so the output is deterministic here.

---

**Exercise 3** (Calculation): Given the following code, trace the value of `len(s)` and `cap(s)` after each line.

```go
s := make([]int, 2, 5)
s = append(s, 10)
s = append(s, 20)
s = append(s, 30)
s = append(s, 40)
```

| After line | `len(s)` | `cap(s)` | New array? |
|---|---|---|---|
| `make([]int, 2, 5)` | 2 | 5 | Yes (initial) |
| `append(s, 10)` | 3 | 5 | No |
| `append(s, 20)` | 4 | 5 | No |
| `append(s, 30)` | 5 | 5 | No |
| `append(s, 40)` | 6 | ≥10 | **Yes** |

`make([]int, 2, 5)` allocates a backing array with capacity 5.
The first three `append` calls fit within the existing capacity (len grows 2 → 3 → 4 → 5).
The fourth `append` exceeds capacity 5, so the runtime allocates a new array (typically double, so cap ≥ 10) and copies the existing elements.
The exact new capacity is implementation-defined but at least 6; in current Go runtimes it is 10.

---

**Exercise 4** (Where is the bug?):

```go
package main

import "fmt"

func main() {
    words := []string{"Gouryella", "Gamemaster", "Flaming June", "Gamemaster", "Sandstorm"}
    var freq map[string]int
    for _, w := range words {
        freq[w]++
    }
    for word, count := range freq {
        if count > 1 {
            fmt.Println(word, count)
        }
    }
}
```

**The bug:** `var freq map[string]int` declares a nil map.
Reading from a nil map returns the zero value (`0` for `int`), which is harmless.
But **writing to a nil map panics** at runtime.
The program panics at `freq[w]++` on the first iteration:

```
panic: assignment to entry in nil map
```

**Fix:** Initialise the map with `make` before the loop:

```go
freq := make(map[string]int)
for _, w := range words {
    freq[w]++
}
```

With the fix, the program prints:

```
Gamemaster 2
```

---

**Exercise 5** (Write a program): Write a program that reads a slice of song titles and builds a map from the first letter to a slice of titles starting with that letter, then prints each letter and its titles in sorted order.

```go
package main

import (
    "fmt"
    "maps"
    "slices"
)

func main() {
    titles := []string{
        "Sandstorm", "Bad Apple!!", "Gouryella",
        "Better Off Alone", "Flaming June", "Sandstorm",
    }

    byLetter := make(map[string][]string)
    for _, t := range titles {
        letter := string(t[0]) // first byte; safe because all titles start with ASCII
        byLetter[letter] = append(byLetter[letter], t)
    }

    for _, ts := range byLetter {
        slices.Sort(ts) // sort titles within each group
    }

    letters := slices.Collect(maps.Keys(byLetter))
    slices.Sort(letters) // sort the letter keys

    for _, letter := range letters {
        fmt.Printf("%s: %v\n", letter, byLetter[letter])
    }
}
```

Output:
```
B: [Bad Apple!! Better Off Alone]
F: [Flaming June]
G: [Gouryella]
S: [Sandstorm Sandstorm]
```

Key points: always initialise a map with `make` before writing; `maps.Keys` returns an iterator (Go 1.23+) that `slices.Collect` converts to a sortable slice.
