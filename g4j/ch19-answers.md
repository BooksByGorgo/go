# Chapter 20: Reflection --- Answers

**Exercise 1** (Think about it): Both Java's `java.lang.reflect` and Go's `reflect` package let you inspect types and values at runtime.
Name two ways they are fundamentally similar and two ways they differ.
In what situation would you reach for reflection in a Go program where a Java programmer might have reached for it as well, and in what situation would a Go programmer choose generics or interfaces instead?

**Two similarities:**

1. Both let you inspect a type's fields and methods at runtime without knowing the concrete type at compile time.
   Java's `Class.getDeclaredFields()` and Go's `reflect.Type.Field(i)` both return field descriptors you can iterate over.
2. Both require a form of "boxing" or indirection.
   Java reflection operates on `Object`; Go reflection operates on `interface{}` (`any`).
   In both languages, passing a primitive or a concrete value into the reflection API involves some overhead.

**Two differences:**

1. In Java, reflection can access private fields (with `setAccessible(true)`).
   In Go, unexported fields are never accessible or settable through reflection --- `CanSet()` returns `false` and `Interface()` panics on unexported fields.
   Go's encapsulation is enforced even through reflection.
2. Java reflection is a well-worn idiom used even in cases where generics would work; the historical prevalence of Java reflection is partly because pre-Java-5 code had no generics at all, and even post-Java-5 generics suffer from type erasure.
   Go was designed with generics from a later, cleaner standpoint, and Go generics have no erasure --- they work at compile time with full type information.
   The need for reflection in Go is therefore narrower than in Java.

**When to reach for reflection in Go (as in Java):**
Serialization and deserialization --- `encoding/json` walks struct fields and reads `json:"..."` tags to marshal and unmarshal arbitrary user types.
This is the same pattern Java developers use with Jackson or Gson.
The concrete struct type is unknown to the library at compile time, so reflection is the only option.

**When to choose generics or interfaces instead:**
If the set of types is bounded and known at compile time, use a generic function.
A function like `func Max[T cmp.Ordered](a, b T) T` works for all ordered types with zero runtime overhead and no possibility of a runtime panic.
A Java developer without generics might have reached for reflection or `Comparable` + casting; in Go the generic version is the correct tool.
Similarly, if the required behavior can be expressed as a method, define an interface and let the compiler verify correctness at compile time.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "fmt"
    "reflect"
)

type Album struct {
    Title  string
    Artist string
    Tracks int
}

func main() {
    a := Album{Title: "Jackman", Artist: "Jack Harlow", Tracks: 13}
    t := reflect.TypeOf(a)
    v := reflect.ValueOf(a)

    for i := range t.NumField() {
        f := t.Field(i)
        fmt.Printf("%s (%s): %v\n", f.Name, f.Type.Kind(), v.Field(i))
    }
}
```

Output:

```
Title (string): Jackman
Artist (string): Jack Harlow
Tracks (int): 13
```

`reflect.TypeOf(a)` returns the `reflect.Type` for `Album`.
`t.NumField()` returns `3` (the three exported fields).
Each iteration retrieves `reflect.StructField` (with `Name` and `Type`) and the corresponding `reflect.Value` via `v.Field(i)`.

`f.Type.Kind()` returns the underlying kind of the field's type.
For `string` fields the kind is `string`; for the `int` field the kind is `int`.
Because `string` and `int` are not user-defined types, `Type.Name()` and `Kind()` would return the same string in this example --- but for a user-defined type like `type BPM int`, `Type.Name()` would return `"BPM"` while `Kind()` would return `"int"`.

---

**Exercise 3** (Calculation): Trace through the following program step by step.
What does it print?

```go
package main

import (
    "fmt"
    "reflect"
)

func main() {
    n := 97
    v := reflect.ValueOf(n)
    fmt.Println(v.CanSet())

    p := reflect.ValueOf(&n).Elem()
    fmt.Println(p.CanSet())

    p.SetInt(99)
    fmt.Println(n)

    s := "Last Night"
    sv := reflect.ValueOf(&s).Elem()
    sv.SetString("First Class")
    fmt.Println(s)
}
```

Output:

```
false
true
99
First Class
```

Step-by-step trace:

1. `n := 97` --- `n` is an `int` with value `97`.
2. `v := reflect.ValueOf(n)` --- `ValueOf` receives a copy of `n` boxed into an `interface{}`.
   `v` describes that copy, not the original variable.
3. `v.CanSet()` --- `false`.
   The value was passed by value, so `v` does not refer to `n`'s address.
   You cannot set it.
4. `p := reflect.ValueOf(&n).Elem()` --- `&n` is a pointer to `n`.
   `ValueOf(&n)` gives a `reflect.Value` of kind `Ptr`.
   `.Elem()` dereferences the pointer, giving a `reflect.Value` that refers directly to `n`'s memory.
5. `p.CanSet()` --- `true`.
   `p` is addressable because it was obtained by dereferencing a pointer.
6. `p.SetInt(99)` --- sets the memory at `n`'s address to `99`.
7. `fmt.Println(n)` --- prints `99`.
   The underlying `int` variable was mutated through reflection.
8. `s := "Last Night"` --- `s` is a `string`.
9. `sv := reflect.ValueOf(&s).Elem()` --- same pattern: pointer -> `Elem()` -> settable value.
10. `sv.SetString("First Class")` --- replaces `s` with `"First Class"`.
11. `fmt.Println(s)` --- prints `First Class`.

---

**Exercise 4** (Where is the bug?): The following function is supposed to double every `int` field in a struct.
It compiles and runs without panicking, but the original struct is never modified.
Why?

```go
package main

import (
    "fmt"
    "reflect"
)

type Stats struct {
    Plays int
    Likes int
}

func doubleInts(s any) {
    v := reflect.ValueOf(s)
    t := v.Type()
    for i := range t.NumField() {
        f := v.Field(i)
        if f.Kind() == reflect.Int && f.CanSet() {
            f.SetInt(f.Int() * 2)
        }
    }
}

func main() {
    stats := Stats{Plays: 500_000, Likes: 12_000}
    doubleInts(stats) // bug is here
    fmt.Println(stats)
}
```

**The bug:** `doubleInts(stats)` passes `stats` by value, not by pointer.

When `stats` is passed to `doubleInts`, Go boxes it into an `interface{}` (the `any` parameter).
Inside `doubleInts`, `reflect.ValueOf(s)` holds a copy of the struct --- not the original variable.
The `CanSet()` check correctly returns `false` for every field on that copy, so the `if` body never executes and no values are set.
The function exits without error, but without doing anything useful.
`stats` in `main` is unchanged.

This is the silent-failure form of the "must pass a pointer" rule.
Without the `CanSet()` guard, calling `SetInt` on a non-addressable field would panic instead of doing nothing.
The guard makes the code safe but hides the problem: the caller gets no feedback that the operation was silently skipped.

**The fix:** pass a pointer so `reflect.ValueOf(s)` holds an addressable value, then call `Elem()` to dereference it:

```go
func doubleInts(s any) {
    v := reflect.ValueOf(s)
    if v.Kind() != reflect.Ptr || v.Elem().Kind() != reflect.Struct {
        panic("doubleInts: argument must be a pointer to a struct")
    }
    v = v.Elem()
    t := v.Type()
    for i := range t.NumField() {
        f := v.Field(i)
        if f.Kind() == reflect.Int && f.CanSet() {
            f.SetInt(f.Int() * 2)
        }
    }
}

func main() {
    stats := Stats{Plays: 500_000, Likes: 12_000}
    doubleInts(&stats) // pass a pointer
    fmt.Println(stats) // {1000000 24000}
}
```

With `&stats`, `reflect.ValueOf(s)` holds a `*Stats` (kind `Ptr`).
`.Elem()` dereferences it to the underlying `Stats` value, which is addressable.
`CanSet()` returns `true` for each field, and `SetInt` modifies the original struct through the pointer.

---

**Exercise 5** (Write a program): Implement `StructToMap(s any) map[string]any` that converts exported struct fields to a map, using a `map:"key"` tag when present and the field name otherwise.

```go
package main

import (
    "fmt"
    "reflect"
    "strings"
)

// StructToMap converts the exported fields of a struct into a map[string]any.
// If a field has a `map:"key"` tag, that key is used; otherwise the field name is used.
// Unexported fields and fields tagged with `map:"-"` are skipped.
func StructToMap(s any) map[string]any {
    v := reflect.ValueOf(s)
    t := reflect.TypeOf(s)

    // Accept a pointer to a struct as well as a struct directly.
    if t.Kind() == reflect.Ptr {
        v = v.Elem()
        t = t.Elem()
    }
    if t.Kind() != reflect.Struct {
        panic("StructToMap: argument must be a struct or pointer to struct")
    }

    result := make(map[string]any, t.NumField())

    for i := range t.NumField() {
        field := t.Field(i)

        // Skip unexported fields.
        if !field.IsExported() {
            continue
        }

        // Determine the map key from the tag or fall back to the field name.
        key := field.Name
        if raw, ok := field.Tag.Lookup("map"); ok {
            name, _, _ := strings.Cut(raw, ",")
            if name == "-" {
                continue // explicitly excluded
            }
            if name != "" {
                key = name
            }
        }

        result[key] = v.Field(i).Interface()
    }

    return result
}

type Track struct {
    Title    string `map:"title"`
    Artist   string `map:"artist"`
    BPM      int    `map:"bpm"`
    internal string // unexported --- should be skipped
}

func main() {
    tr := Track{
        Title:    "First Class",
        Artist:   "Jack Harlow",
        BPM:      97,
        internal: "hidden",
    }

    m := StructToMap(tr)
    fmt.Println(m)
    // map[artist:Jack Harlow bpm:97 title:First Class]

    // Also works with a pointer.
    m2 := StructToMap(&tr)
    fmt.Println(m2)
    // map[artist:Jack Harlow bpm:97 title:First Class]
}
```

Output:

```
map[artist:Jack Harlow bpm:97 title:First Class]
map[artist:Jack Harlow bpm:97 title:First Class]
```

Key points about the solution:

- `field.IsExported()` correctly skips `internal` --- no `CanInterface()` panic.
- `strings.Cut(raw, ",")` cleanly separates the key name from any future comma-separated options (e.g., `map:"title,omitempty"`), which is the same pattern used by `encoding/json`.
- `v.Field(i).Interface()` returns the field value as `any`; calling `Interface()` on an unexported field would panic, which is why the `IsExported()` check must come first.
- Accepting both `struct` and `*struct` by checking `t.Kind() == reflect.Ptr` at the top is a common convenience that mirrors how `encoding/json.Marshal` behaves.
- The `map:"-"` convention mirrors `json:"-"` for fields that should be explicitly excluded despite being exported.
