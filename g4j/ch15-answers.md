# Chapter 16: JSON, HTTP, and the Web --- Answers

**Exercise 1** (Think about it): In Java with Spring MVC or JAX-RS, you annotate a class method with `@GetMapping("/songs/{id}")` or `@GET @Path("/songs/{id}")` and the framework discovers handlers via reflection and classpath scanning.
In Go, you call `mux.HandleFunc("GET /songs/{id}/", getSong)` explicitly in `main`.
What are the tradeoffs of each approach?
Consider startup time, debuggability, IDE navigation, and what happens when two handlers are registered for the same pattern.

**Annotation/reflection-based frameworks (Spring, JAX-RS):**

- *Startup time:* The framework scans the classpath, processes annotations, and builds a routing table at startup.
  For large applications this can add seconds --- sometimes tens of seconds.
  Spring Boot's startup time is a well-known pain point for serverless and container workloads.
- *IDE navigation:* IDEs understand Spring annotations deeply; `@GetMapping` provides clickable navigation to the handler.
  However, understanding the full request path often requires tracing through a chain of `@RequestMapping` annotations on the class, the method, and any inherited base classes.
- *Debuggability:* Routing bugs can be subtle; the framework discovers handlers at runtime, so a typo in a path annotation compiles cleanly and only fails when a request is made.
  Error messages from annotation-driven frameworks can be verbose and hard to relate back to specific source lines.
- *Duplicate pattern:* Spring raises a `BeanDefinitionOverrideException` or similar at startup.

**Explicit registration (Go `ServeMux`):**

- *Startup time:* Registration happens in `main` --- it is just function calls.
  There is no scanning; startup overhead is negligible.
- *IDE navigation:* `mux.HandleFunc("GET /songs/{id}/", getSong)` --- `getSong` is a direct function reference.
  Your IDE can jump to it with a single click, with no framework-specific plugin needed.
- *Debuggability:* The routing table is built from ordinary Go code.
  If you register the wrong path, you can add a `fmt.Println` or set a debugger breakpoint in `main` and see exactly what is registered.
- *Duplicate pattern:* Go 1.22 `ServeMux` panics at registration time if two patterns conflict.
  This is a startup crash rather than a silent routing bug, which is the right trade-off --- it catches the mistake before any request is served.

The Go approach is more explicit and has less magic.
The annotation approach provides more convenience in large teams where developers add handlers in many files and rely on the framework to assemble the routing table.
Neither is universally better; the right choice depends on team size, application complexity, and how much framework overhead you are willing to accept.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "encoding/json"
    "fmt"
)

type Artist struct {
    Name    string `json:"name"`
    Country string `json:"country,omitempty"`
    Secret  string `json:"-"`
}

func main() {
    a := Artist{Name: "Kali Uchis", Country: "", Secret: "Colombia"}
    data, _ := json.Marshal(a)
    fmt.Println(string(data))

    var b Artist
    json.Unmarshal([]byte(`{"name":"Rauw Alejandro","secret":"Puerto Rico"}`), &b)
    fmt.Printf("Name: %s, Secret: %q\n", b.Name, b.Secret)
}
```

Output:
```
{"name":"Kali Uchis"}
Name: Rauw Alejandro, Secret: ""
```

**First `Println`:**
`a.Country` is `""`, which is the zero value for `string`.
The tag `json:"country,omitempty"` causes `encoding/json` to omit the `country` field from the output.
`a.Secret` is `"Colombia"`, but the tag `json:"-"` instructs the encoder to always skip this field regardless of its value.
The result is `{"name":"Kali Uchis"}` --- only `name` survives.

**Second `Printf`:**
The JSON input contains a `"secret"` key.
However, the Go struct has `Secret string \`json:"-"\``.
The `json:"-"` tag means `encoding/json` ignores this field during both marshalling **and** unmarshalling.
The `"secret"` key in the JSON is silently discarded; `b.Secret` remains the zero value `""`.
`b.Name` is correctly set to `"Rauw Alejandro"` from the `"name"` key.

`%q` formats a string with Go double-quote syntax, so an empty string prints as `""`.

---

**Exercise 3** (Calculation): Consider the following `ServeMux` registration and the three incoming requests.
For each request, state which handler function is called, or `404` if none matches.

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /tracks/",       listTracks)
mux.HandleFunc("GET /tracks/{id}/",  getTrack)
mux.HandleFunc("POST /tracks/",      createTrack)
```

a. `GET /tracks/` --- **`listTracks`**

The request method is `GET` and the path is exactly `/tracks/`.
The pattern `GET /tracks/` is a subtree match that includes the exact path `/tracks/`.
`GET /tracks/{id}/` requires at least one additional path segment between the slashes (e.g., `/tracks/42/`), so it does not match `/tracks/` alone.
`listTracks` is called.

b. `GET /tracks/42/` --- **`getTrack`**

The request method is `GET` and the path is `/tracks/42/`.
The pattern `GET /tracks/{id}/` matches: `{id}` captures `42`.
`r.PathValue("id")` would return `"42"` inside the handler.
`getTrack` is called.

c. `DELETE /tracks/7/` --- **`404`**

None of the three registered patterns match a `DELETE` method on any path.
`GET /tracks/{id}/` matches the path shape but requires `GET`.
`ServeMux` returns a 405 Method Not Allowed response in Go 1.22 when the path matches a pattern but the method does not.
Effectively the caller receives an HTTP error response, not a call to any registered handler.

(Note: technically Go 1.22 `ServeMux` sends `405 Method Not Allowed` with an `Allow` header listing valid methods when the path matches but the method does not --- this is more precise than a plain 404.)

---

**Exercise 4** (Where is the bug?):

```go
func fetchLyrics(url string) (string, error) {
    resp, err := http.Get(url)
    if err != nil {
        return "", err
    }
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return "", err
    }
    return string(body), nil
}
```

**The bug:** `resp.Body` is never closed.

When `http.Get` succeeds, `resp.Body` is a live network connection wrapped as an `io.ReadCloser`.
If the function returns the body as a string but never calls `resp.Body.Close()`, the underlying TCP connection is not returned to the connection pool --- it is leaked.
Under load, a server making many requests will exhaust its file descriptors and connection pool, eventually causing all new HTTP requests to fail.

Note that the early-return error path `return "", err` after `io.ReadAll` also leaks the body.

**The fix:**

```go
func fetchLyrics(url string) (string, error) {
    resp, err := http.Get(url)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()  // close on any return, success or error

    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return "", err
    }
    return string(body), nil
}
```

`defer resp.Body.Close()` immediately after the `err` check ensures the body is closed on every code path out of the function, including early returns.
This is the canonical Go idiom for HTTP client response bodies.

---

**Exercise 5** (Write a program):

```go
package main

import (
    "encoding/json"
    "net/http"
    "strconv"
)

type Song struct {
    ID     int    `json:"id"`
    Title  string `json:"title"`
    Artist string `json:"artist"`
}

var catalog = map[int]Song{
    1: {ID: 1, Title: "Todo De Ti",      Artist: "Rauw Alejandro"},
    2: {ID: 2, Title: "I Wish You Roses", Artist: "Kali Uchis"},
}

func listSongs(w http.ResponseWriter, r *http.Request) {
    songs := make([]Song, 0, len(catalog))
    for _, s := range catalog {
        songs = append(songs, s)
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(songs)
}

func getSong(w http.ResponseWriter, r *http.Request) {
    idStr := r.PathValue("id")
    id, err := strconv.Atoi(idStr)
    if err != nil {
        http.Error(w, "invalid id", http.StatusBadRequest)
        return
    }
    song, ok := catalog[id]
    if !ok {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(song)
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("GET /songs/",      listSongs)
    mux.HandleFunc("GET /songs/{id}/", getSong)
    http.ListenAndServe(":8080", mux)
}
```

**Testing the server** (with `curl` in a second terminal):

```
$ curl http://localhost:8080/songs/
[{"id":1,"title":"Todo De Ti","artist":"Rauw Alejandro"},{"id":2,"title":"I Wish You Roses","artist":"Kali Uchis"}]

$ curl http://localhost:8080/songs/1/
{"id":1,"title":"Todo De Ti","artist":"Rauw Alejandro"}

$ curl http://localhost:8080/songs/99/
not found
```

Key points illustrated by this solution:

- `json.NewEncoder(w).Encode(songs)` streams the JSON directly to the `http.ResponseWriter` without allocating an intermediate `[]byte`.
- `r.PathValue("id")` retrieves the wildcard captured by `{id}` in the Go 1.22 pattern.
- `strconv.Atoi` converts the string path segment to an integer; a malformed segment returns `400 Bad Request` rather than panicking.
- The `Content-Type` header is set before writing the body.
  Headers must be set before the first call to `Write` or `Encode` --- once the body starts, the headers are sent and cannot be changed.
- The map iteration order in `listSongs` is random (Chapter 8).
  In a real service you would sort the result before encoding it to give clients a stable response.
