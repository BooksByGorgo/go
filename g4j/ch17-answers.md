# Chapter 17: Database Access --- Answers

**Exercise 1** (Think about it): JDBC requires explicit transaction management and connection pooling through a `DataSource`, usually provided by an application server or a library like HikariCP.
Go's `database/sql` builds connection pooling directly into `sql.DB`.
What are the tradeoffs of each approach?
In what situations might you still want an external connection pool in a Go application?

Go's approach is simpler for the common case: you call `sql.Open`, tune a few settings (`SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`), and the pool manages itself.
There is no additional dependency, no configuration file, and no separate object to wire up.
This is consistent with Go's philosophy of including batteries for common needs.

JDBC's reliance on an external pool (HikariCP, DBCP, c3p0, or an application server pool) adds setup complexity but provides more configurability.
HikariCP, for example, offers connection validation queries, connection test-on-borrow, metric integration with Micrometer, and health check endpoints.

In a Go application you might still want an external or proxy pool in a few situations:

- **PgBouncer / ProxySQL:** These are database-side proxy pools that multiplex many application connections onto fewer server connections.
  They are useful when you have many application instances and the database itself limits total connections.
  `sql.DB`'s pool operates within one process; PgBouncer aggregates across many processes.
- **Serverless / short-lived processes:** If your Go binary starts and exits quickly (a CLI, a Lambda function), the in-process pool provides little benefit.
  A proxy pool keeps connections warm across many cold starts.
- **Observability:** Some proxy pools offer detailed query-level metrics and slow-query logging that are difficult to achieve from application code alone.

In most long-running Go services, the built-in pool is sufficient and external pooling adds unnecessary complexity.

---

**Exercise 2** (What does this print?):

```go
package main

import (
    "database/sql"
    "fmt"
)

func main() {
    a := sql.Null[string]{V: "Evergreen", Valid: true}
    b := sql.Null[string]{V: "Killing Me", Valid: false}
    c := sql.Null[int64]{V: 0, Valid: false}

    fmt.Println(a.Valid, a.V)
    fmt.Println(b.Valid, b.V)
    fmt.Println(c.Valid, c.V)
}
```

Output:
```
true Evergreen
false Killing Me
false 0
```

`sql.Null[T]` is a plain struct with two exported fields: `V` (the value) and `Valid` (a bool).
It has no logic in its fields; they are whatever you set them to.

- `a` has `Valid: true` and `V: "Evergreen"`, so `fmt.Println` prints `true Evergreen`.
- `b` has `Valid: false` but `V` is still `"Killing Me"` --- setting `Valid` to `false` does not zero out `V`.
  This might be surprising: the struct remembers the value even though it would represent `NULL` in the database.
  `fmt.Println` prints `false Killing Me`.
- `c` has `Valid: false` and `V: 0` (the zero value for `int64`).
  `fmt.Println` prints `false 0`.

The key takeaway: `Valid` controls whether the value is considered non-NULL; it does not affect what is stored in `V`.
When scanning from a database, `Scan` sets `V` to the zero value and `Valid` to `false` for a `NULL` column.

---

**Exercise 3** (Calculation): Trace the following transaction sequence.

```go
tx, _ := db.BeginTx(ctx, nil)
defer tx.Rollback()

_, err := tx.ExecContext(ctx, "INSERT INTO songs (title, artist) VALUES (?, ?)",
    "On My Mama", "Victoria Monét")
if err != nil {
    return err
}

return tx.Commit()
```

**Case A: `ExecContext` succeeds and `Commit` succeeds.**

The deferred `tx.Rollback()` fires after `tx.Commit()` returns.
`Rollback` on a committed transaction is a no-op --- it returns `sql.ErrTxDone`, which is silently discarded because the return value of a deferred call is not used here.
The row is **inserted and committed** permanently.

**Case B: `ExecContext` succeeds but `Commit` returns an error.**

`tx.Commit()` fails, so the function returns an error.
The deferred `tx.Rollback()` then fires.
However, when a commit fails at the database level, the transaction is typically already rolled back by the database.
`Rollback` here is a safety net that confirms the abort.
The row is **not inserted** --- the transaction was not committed.

**Case C: `ExecContext` returns an error.**

The `if err != nil { return err }` branch fires, returning the error.
The deferred `tx.Rollback()` fires before the function returns to the caller.
The `INSERT` is undone (or was never applied, depending on the database).
The row is **not inserted**.

In all three cases the deferred rollback provides a guarantee: the transaction is always cleaned up, regardless of which path the function takes.
This is the entire point of the deferred rollback pattern.

---

**Exercise 4** (Where is the bug?):

```go
func getArtistSongs(ctx context.Context, db *sql.DB, artist string) ([]string, error) {
    rows, err := db.QueryContext(ctx,
        "SELECT title FROM songs WHERE artist = ?", artist)
    if err != nil {
        return nil, err
    }

    var titles []string
    for rows.Next() {
        var title string
        if err := rows.Scan(&title); err != nil {
            return nil, err
        }
        titles = append(titles, title)
    }
    return titles, nil
}
```

**Two bugs:**

**Bug 1: `rows` is never closed.**
If `rows.Next()` completes the loop normally, `rows` is closed automatically.
But if `rows.Scan` returns an error and the function returns early via `return nil, err`, `rows` is never closed.
The connection borrowed from the pool is never returned, leaking it.
Under sustained load this exhausts the pool.

**Bug 2: `rows.Err()` is never checked.**
After the loop, `rows.Err()` may hold an error that caused iteration to stop early (e.g., a network failure mid-result-set).
Ignoring it means the function silently returns a partial result as if it were complete.

**Fixed version:**

```go
func getArtistSongs(ctx context.Context, db *sql.DB, artist string) ([]string, error) {
    rows, err := db.QueryContext(ctx,
        "SELECT title FROM songs WHERE artist = ?", artist)
    if err != nil {
        return nil, err
    }
    defer rows.Close() // always close, even on early return

    var titles []string
    for rows.Next() {
        var title string
        if err := rows.Scan(&title); err != nil {
            return nil, err
        }
        titles = append(titles, title)
    }
    if err := rows.Err(); err != nil { // check for iteration errors
        return nil, err
    }
    return titles, nil
}
```

`defer rows.Close()` immediately after checking the error from `QueryContext` is the standard pattern.
Calling `rows.Close()` on already-closed rows is a no-op, so it is always safe.

---

**Exercise 5** (Write a program):

```go
package main

import (
    "context"
    "database/sql"
    "fmt"
    "log"

    _ "github.com/mattn/go-sqlite3"
)

type Playlist struct {
    ID          int
    Name        string
    Owner       string
    Description sql.Null[string]
}

func main() {
    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    ctx := context.Background()

    if err := db.PingContext(ctx); err != nil {
        log.Fatal(err)
    }

    _, err = db.ExecContext(ctx, `
        CREATE TABLE playlists (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            owner       TEXT    NOT NULL,
            description TEXT
        )`)
    if err != nil {
        log.Fatal(err)
    }

    // insert three rows inside a single transaction
    if err := insertPlaylists(ctx, db); err != nil {
        log.Fatal(err)
    }

    // query and print all rows
    rows, err := db.QueryContext(ctx,
        "SELECT id, name, owner, description FROM playlists ORDER BY id")
    if err != nil {
        log.Fatal(err)
    }
    defer rows.Close()

    for rows.Next() {
        var p Playlist
        if err := rows.Scan(&p.ID, &p.Name, &p.Owner, &p.Description); err != nil {
            log.Fatal(err)
        }
        desc := "(no description)"
        if p.Description.Valid {
            desc = p.Description.V
        }
        fmt.Printf("%d: %s by %s --- %s\n", p.ID, p.Name, p.Owner, desc)
    }
    if err := rows.Err(); err != nil {
        log.Fatal(err)
    }
}

func insertPlaylists(ctx context.Context, db *sql.DB) error {
    tx, err := db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback() // no-op if Commit succeeds

    stmt, err := tx.PrepareContext(ctx,
        "INSERT INTO playlists (name, owner, description) VALUES (?, ?, ?)")
    if err != nil {
        return err
    }
    defer stmt.Close()

    playlists := []Playlist{
        {
            Name:        "Victoria Vibes",
            Owner:       "coastin_fan",
            Description: sql.Null[string]{V: "Best of Victoria Monét", Valid: true},
        },
        {
            Name:        "Omar After Midnight",
            Owner:       "coastin_fan",
            Description: sql.Null[string]{V: "Evergreen on repeat", Valid: true},
        },
        {
            Name:        "Late Night Mix",
            Owner:       "apollo_stan",
            Description: sql.Null[string]{}, // NULL description
        },
    }

    for _, p := range playlists {
        if _, err := stmt.ExecContext(ctx, p.Name, p.Owner, p.Description); err != nil {
            return err
        }
    }

    return tx.Commit()
}
```

Output:
```
1: Victoria Vibes by coastin_fan --- Best of Victoria Monét
2: Omar After Midnight by coastin_fan --- Evergreen on repeat
3: Late Night Mix by apollo_stan --- (no description)
```

Key points demonstrated:
- `sql.Open` + `PingContext` verifies connectivity before doing any work.
- The transaction uses the **deferred rollback pattern**: `defer tx.Rollback()` is unconditional; `Commit` at the end makes it a no-op on success.
- A prepared statement is created once inside the transaction and reused for each insert.
- `sql.Null[string]` handles the nullable `description` column; `Valid: false` results in a `NULL` stored in the database and scanned back correctly.
- `rows.Err()` is checked after the loop to catch any mid-stream errors.
