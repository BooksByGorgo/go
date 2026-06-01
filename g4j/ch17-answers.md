# Chapter 18: Generics --- Answers

**Exercise 1** (Think about it): Java generics use **type erasure**: at runtime, `List<String>` and `List<Integer>` are both just `List`.
Generic type information is only available at compile time.
Go generics use **monomorphization** (or a shared pointer-shaped representation): the compiler may generate distinct code for each instantiation.
Describe one concrete advantage and one concrete disadvantage of each approach.
How does type erasure affect what you can do with a Java generic type at runtime (e.g., `instanceof List<String>`)? Does Go have the same limitation?

**Type erasure (Java):**

*Advantage:* A single compiled class file handles all instantiations.
`ArrayList<String>` and `ArrayList<Integer>` share bytecode, which keeps the compiled output compact and means that libraries compiled against an older JDK are forward-compatible with new generic code without recompilation.

*Disadvantage:* The generic type argument is gone at runtime.
You cannot write `obj instanceof List<String>` --- the JVM sees only `List`.
Creating a generic array (`new T[]`) is illegal because the runtime cannot know the element type.
Working around these limitations requires unchecked casts and `@SuppressWarnings("unchecked")`, which reintroduces the `ClassCastException` risk that generics were designed to prevent.

**Monomorphization (Go):**

*Advantage:* The compiler generates type-specific code, so operations on value types like `int` or `float64` are never boxed.
A `Stack[int]` stores plain `int` values directly in the backing slice --- no `Integer` wrapper objects, no extra allocations, no GC pressure.
There is no unchecked cast at runtime; type safety is total.

*Disadvantage:* The compiler may produce multiple instantiations of the same function, increasing binary size.
For large programs with many instantiation combinations, compile times can grow.
(In practice, Go mitigates this by using a GC-shape-based approach that shares code for pointer-shaped types, but the tradeoff is still present for value types.)

**Runtime reflection:**

In Java, because of erasure, `List<String>.class` does not exist; you can only get `List.class`.
`instanceof List<String>` is a compile-time warning and a runtime check against `List`, not `List<String>`.
Accessing the actual type argument at runtime requires passing a `Class<T>` token explicitly.

In Go, you can use `reflect.TypeOf` to inspect the concrete type of a value, and since Go does not erase type information the way Java does, the concrete type is always available.
However, Go reflection operates on concrete values, not on type parameters themselves --- you cannot query "what was `T`?" from inside a generic function without passing the type explicitly.
Both languages have some limitations here, but the flavor of the limitation differs.

---

**Exercise 2** (What does this print?):

```go
package main

import "fmt"

func Filter[T any](s []T, keep func(T) bool) []T {
    var out []T
    for _, v := range s {
        if keep(v) {
            out = append(out, v)
        }
    }
    return out
}

type BPM int

func main() {
    beats := []BPM{72, 128, 96, 140, 80}
    fast := Filter(beats, func(b BPM) bool { return b >= 120 })
    fmt.Println(fast)

    words := []string{"Escape", "J'ai pas vingt ans !", "J'en ai marre !", "$100 Bills"}
    long := Filter(words, func(s string) bool { return len(s) > 7 })
    fmt.Println(long)
}
```

Output:
```
[128 140]
[J'ai pas vingt ans ! J'en ai marre ! $100 Bills]
```

For the first call, `T` is inferred as `BPM`.
The predicate keeps elements greater than or equal to 120.
`72`, `96`, and `80` are below 120 and are excluded.
`128` and `140` pass and are appended to `out`.

For the second call, `T` is inferred as `string`.
The predicate keeps strings longer than 7 characters.
`"Escape"` has 6 characters (excluded), `"J'ai pas vingt ans !"` has 20 (included), `"J'en ai marre !"` has 15 (included), and `"$100 Bills"` has 10 (included).

---

**Exercise 3** (Calculation): The function below has the signature `func Reduce[T, U any](s []T, init U, f func(U, T) U) U`.
Trace the execution of `Reduce([]int{1, 2, 3, 4}, 0, func(acc, v int) int { return acc + v })`.
What is the concrete type bound to `T`?
What is the concrete type bound to `U`?
What value does the function return, and what are the intermediate values of `acc` after each call to `f`?

`T` is bound to `int` (the element type of `[]int{1, 2, 3, 4}`).
`U` is also bound to `int` (the type of the initial accumulator `0` and the return type of `f`).

The function body would be:

```go
func Reduce[T, U any](s []T, init U, f func(U, T) U) U {
    acc := init
    for _, v := range s {
        acc = f(acc, v)
    }
    return acc
}
```

Tracing each call to `f`:

| Iteration | `acc` before | `v` | `acc` after (`acc + v`) |
|-----------|-------------|-----|------------------------|
| 1         | 0           | 1   | 1                      |
| 2         | 1           | 2   | 3                      |
| 3         | 3           | 3   | 6                      |
| 4         | 6           | 4   | 10                     |

The function returns **10**.

---

**Exercise 4** (Where is the bug?):

```go
package main

import "fmt"

type Playlist []string

func Dedupe[T any](s []T) []T {
    seen := make(map[T]bool)
    var out []T
    for _, v := range s {
        if !seen[v] {
            seen[v] = true
            out = append(out, v)
        }
    }
    return out
}

func main() {
    p := Playlist{"Escape", "J'ai pas vingt ans !", "Escape", "J'en ai marre !", "J'ai pas vingt ans !"}
    fmt.Println(Dedupe(p))
}
```

**The bug:** `T` is constrained to `any`, but `map[T]bool` requires `T` to be `comparable`.
The compiler rejects this with an error like:

```
invalid map key type T (missing comparable constraint)
```

Using a type as a map key requires that it support `==` and `!=`.
`any` does not guarantee this.

**The fix:** Change the constraint from `any` to `comparable`:

```go
func Dedupe[T comparable](s []T) []T {
    seen := make(map[T]bool)
    var out []T
    for _, v := range s {
        if !seen[v] {
            seen[v] = true
            out = append(out, v)
        }
    }
    return out
}
```

`string` and `Playlist` (whose underlying type is `[]string`) --- wait: `Playlist` is `[]string`, and slices are **not** comparable.
So even with `comparable`, passing `Playlist` would fail because `[]string` does not satisfy `comparable`.

The call in `main` passes `p` (of type `Playlist`, underlying type `[]string`) directly.
Slices are never comparable in Go.

The correct fix is to change the call to pass the string slice elements rather than the slice type:

```go
func main() {
    p := []string{"Escape", "J'ai pas vingt ans !", "Escape", "J'en ai marre !", "J'ai pas vingt ans !"}
    fmt.Println(Dedupe(p))
}
```

With `T comparable` and `p` as `[]string`, the output is:

```
[Escape J'ai pas vingt ans ! J'en ai marre !]
```

In summary, there are two bugs: the constraint must be `comparable`, and `Playlist` (a `[]string`) cannot be used as a map key because slices are not comparable.

---

**Exercise 5** (Write a program):

```go
package main

import "fmt"

// Set is a generic unordered collection of unique comparable values.
type Set[T comparable] struct {
    m map[T]struct{}
}

// Add inserts v into the set.
func (s *Set[T]) Add(v T) {
    if s.m == nil {
        s.m = make(map[T]struct{})  // lazy initialization
    }
    s.m[v] = struct{}{}
}

// Contains reports whether v is in the set.
func (s *Set[T]) Contains(v T) bool {
    _, ok := s.m[v]
    return ok
}

// Values returns all elements of the set as a slice in unspecified order.
func (s *Set[T]) Values() []T {
    out := make([]T, 0, len(s.m))
    for v := range s.m {
        out = append(out, v)  // iteration order is random
    }
    return out
}

func main() {
    var songs Set[string]
    songs.Add("Escape")
    songs.Add("$100 Bills")
    songs.Add("J'ai pas vingt ans !")
    songs.Add("J'en ai marre !")
    songs.Add("J'ai pas vingt ans !") // duplicate --- should be ignored

    fmt.Println("length:", len(songs.Values()))                              // 4
    fmt.Println("contains Escape:", songs.Contains("Escape"))               // true
    fmt.Println("contains Legend:", songs.Contains("Legend"))               // false
}
```

Output:
```
length: 4
contains Escape: true
contains Legend: false
```

`map[T]struct{}` is the standard Go idiom for a set.
An empty struct (`struct{}`) occupies zero bytes, so only the keys consume memory.
The second `Add("J'ai pas vingt ans !")` call is a no-op because the map key already exists --- map assignment is idempotent.
`Values()` returns four strings because the duplicate was silently dropped, but their order will vary between runs since Go map iteration is randomized.
