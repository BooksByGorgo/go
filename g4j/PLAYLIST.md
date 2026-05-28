# Playlist

Tracks all song, artist, and lyric references used in the book, organized by chapter.
Do not repeat any reference already listed here.

## Chapter 1: Hello, Go

- Sabrina Carpenter --- "Espresso" (used in fmt.Println and fmt.Printf examples: "Espresso Gresso", "Track 1: Espresso")
- Sabrina Carpenter --- 6 Grammy nominations (used in fmt.Printf example)
- Taylor Swift --- "Anti-Hero" (used in format verbs %q example)
- Chappell Roan --- 1,500,000 plays (used in exercise 2)

## Chapter 2: Types and Variables

- StreamingTier iota block (Free/Standard/Premium/Lossless) --- fictional streaming tier names, no specific artist
- ChartPosition iota block --- fictional chart positions, no specific artist

## Chapter 3: Strings, Bytes, and Runes

- Miley Cyrus --- "Flowers" (used in strings.Contains/HasPrefix/HasSuffix/Count/Index example: "I can buy myself flowers")
- Sabrina Carpenter --- "Espresso" (used in strings.Builder example)
- Doja Cat --- album "Scarlet" (used in raw string literal JSON example)
- Beyoncé --- artist name with non-ASCII é (used in byte/rune calculation exercise)

## Chapter 4: Control Flow

*(no song/lyric references; Spanish vocabulary used: manzana, naranja, uva, lunes, sábado, domingo, fiebre, cancion)*

## Chapter 5: Functions

- Billie Eilish --- "Birds of a Feather" (used in the first-class function / transformer example)
- "hola, mundo!" --- Spanish greeting used in the middleware pattern example
- "martes" / "jueves" --- Spanish day names used as map keys in the `init()` example

## Chapter 6: Pointers

- Billie Eilish --- "Bad Guy" (used in Exercise 4: `msg := "Bad Guy"`)

## Chapter 7: Slices

- Glass Animals --- "Heat Waves" (used in slice aliasing example: `track` slice)
- Harry Styles --- "As It Was" (used in slice aliasing example and addTrack function example)
- Dua Lipa --- "Levitating" (used in addTrack function example)
- Olivia Rodrigo --- "Vampire" (used in slices.Sort example)
- SZA --- "Kill Bill" (used in slices.Sort example)
- Kendrick Lamar --- "Not Like Us" (used in slice aliasing example: reassigned track[0])

## Chapter 8: Maps and Structs

- The Weeknd --- "Blinding Lights" (used in map literal example: streams map)
- Ed Sheeran --- "Shape of You" (used in streams map literal)
- The Kid LAROI & Justin Bieber --- "Stay" (used in streams map literal and exercise 5 Song slice)
- Metro Boomin & The Weeknd --- "Creepin'" (used in catalog map comma-ok example)
- Steve Lacy --- "Bad Habit" (used in catalog map comma-ok example)
- Olivia Rodrigo --- "good 4 u" (used in catalog map comma-ok example)
- The Weeknd & Playboi Carti --- "Timeless" (used in named and positional struct literal examples)
- The Weeknd --- "Save Your Tears" (used in anonymous struct example and exercise 5 Song slice)
- Doja Cat --- "Agora Hills" (used in struct value-type copy example)
- Lola Young --- "Messy" (used in methods on structs example)
- Rosalía --- "MOTOMAMI" (used in embedding example)
- FloyyMenor & Cris MJ --- "Gata Only" (used in cmp.Compare / slices.SortFunc example)
- The Weeknd --- "Starboy" (used in cmp.Compare / slices.SortFunc example)
- JVKE --- "Golden Hour" (used in cmp.Compare / slices.SortFunc example and exercise 5 Song slice)
- Stephen Sanchez & Em Beihold --- "Until I Found You" (used in cmp.Compare / slices.SortFunc example)
- Peso Pluma --- "La Bebé" (used in exercise 2)
- Natanael Cano (used in exercise 2 as reassigned artist name)
- Denzel Curry --- "Gasoline" (used in exercise 4 catalog map)
- Lil Nas X & Jack Harlow --- "Industry Baby" (used in exercise 4 catalog map)
- Linkin Park --- "Numb" (used in exercise 4 catalog map)
- Sam Smith --- "Unholy" (used in exercise 5 Song slice)

## Chapter 9: Interfaces

- Lady Gaga & Bruno Mars --- "Die With A Smile" (used in Track struct Stringer example: title "Die With A Smile", 144 BPM)
- "sabor a mí" --- Spanish song title used in any/interface{} variable example
- "Bienvenidos!" --- Spanish greeting used in http.HandlerFunc example
- Chappell Roan --- "Good Luck, Babe!" (used in sort.Interface ByTitle example)
- Benson Boone --- "Beautiful Things" (used in sort.Interface ByTitle example)
- Gracie Abrams --- "That's So True" (used in sort.Interface ByTitle example)

## Chapter 15: Essential Standard Library

- Ariana Grande --- "positions" (used in Track struct %v/%+v/%#v example: title "positions", BPM 114; and exercise 4 titles list)
- Ariana Grande --- "thank u, next" (used in io.Pipe goroutine example: string written to pipe; and exercise 4 titles list)
- Dua Lipa --- "Physical" (used in slog.Info example: title "Physical", BPM 130; and exercise 2 scanner input; exercise 4 titles list; exercise 5 sample run)
- Dua Lipa --- "Don't Start Now" (used in bufio.NewWriter Flush example: string written to buffer; exercise 2 scanner input; exercise 4 titles list; exercise 5 sample run)

## Chapter 13: Context and Concurrency Patterns

- Laufey --- "From The Start" (used in fetchLyrics timeout example and fanOutFetch exercise)
- Laufey --- "Bewitched" (used in errgroup fan-out example and exercise 2)
- Laufey --- "Let You Break My Heart Again" (used in worker pool track list)
- Hozier --- "Too Sweet" (used in errgroup fan-out example, worker pool track list, exercise 2, and fanOutFetch exercise)
- Hozier --- "Work Song" (used in goroutine leak example, worker pool track list, and fanOutFetch exercise)
- Hozier --- "Cherry Wine" (used in worker pool track list and rate limiter example)
- Hozier --- "Someone New" (used in rate limiter example)

## Chapter 14: Packages and Modules

- Zach Bryan --- "Something in the Orange" (used in module path and import path examples, and exercise 2 lyrics output)
- Zach Bryan --- "I Remember Everything" (used as module name reference in go.mod example: remembereverything)
- Noah Kahan --- "Stick Season" (used as module name in exercise 5 multi-package project)
- Noah Kahan --- "Northern Attitude" (used in exercise 4 module name and exercise 5 catalog track)
- Noah Kahan --- "Northern Attitude" (track in exercise 5 Catalog slice)

## Chapter 10: Error Handling

- Bad Bunny --- "Un Verano Sin Ti" (used in errors.Join / validateAlbum example: album title)
- Bad Bunny --- "Tití Me Preguntó" (used in PlaybackError / custom error type example: track name; and exercise 2 lookup call)
- Karol G --- "TQG" (used in io.EOF sentinel read loop example: track title; and exercise 3 validateSong input)
- Karol G --- "Provenza" (used in io.EOF sentinel read loop example: track title; and safePlay example)
- Karol G --- "Mi Ex Tenía Razón" (used in io.EOF sentinel read loop example: track title)

## Chapter 11: Goroutines and Channels

- Tyler, The Creator --- "Earfquake" (used in goroutine launch example and source goroutine in fan-in example)
- Tyler, The Creator --- "Wilder World" (used in channel send example lyric, produce function, playlist slice, and exercise 5)
- Post Malone --- "Circles" (used in playTrack example, buffered channel example, playlist slice, and exercise 5)
- Post Malone --- "rockstar" (used in channel send example, playlist slice, and exercise 5)

## Chapter 12: Synchronization

- NewJeans --- "Ditto" (used in Playlist.Add example, sync.Map store/range example, sync.Once catalog map, WaitGroup fan-out, sync.Pool formatSong example)
- NewJeans --- "Hype Boy" (used in WaitGroup fan-out, sync.Map store example, sync.Pool formatSong example, race detector fix, exercise 4 key)
- NewJeans --- "ETA" (used in WaitGroup fan-out, sync.Map LoadOrStore example, sync.Pool formatSong example, atomic play counter example)
- BTS --- "Dynamite" (used in sync.Once catalog map, sync.Map store example, atomic play counter example, sync.Pool formatSong example)
- BTS --- "Butter" (used in sync.Pool formatSong example, atomic play counter example, exercise 4 map key, exercise 5 rate limiter)

## Chapter 16: JSON, HTTP, and the Web

- Rauw Alejandro --- "Todo De Ti" (used in json.Marshal/Unmarshal example: Song struct title, catalog map, exercise 5 pre-populated Song)
- Rauw Alejandro --- "Lokera" (used in struct tag omitempty example and POST body example)
- Kali Uchis --- "telepatía" (used in struct tag omitempty example and encoding/xml example)
- Kali Uchis --- "I Wish You Roses" (used in songHandler streaming Encoder example and catalog map)
- "Hola!" --- Spanish greeting used in minimal HTTP server handler example

## Chapter 17: Database Access

- Victoria Monét --- "On My Mama" (used in bulk insert example, complete music store example, and exercise 3 transaction trace)
- Victoria Monét --- "Coastin'" (used in bulk insert example and complete music store example; album "JAGUAR II")
- Victoria Monét --- album "JAGUAR II" (referenced as album value in Song struct inserts)
- Omar Apollo --- "Evergreen" (used in bulk insert example; album "IVORY"; Exercise 2 sql.Null example)
- Omar Apollo --- "Killing Me" (used in bulk insert example as NULL-album song; Exercise 2 sql.Null example)
- Omar Apollo --- album "IVORY" (referenced as album value in Song struct inserts)

## Chapter 18: Generics

- Tate McRae --- "greedy" (used in Map function example, Stack example, MapFromSlice example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Tate McRae --- "you broke me first" (used in Map function example, ArtistTitles iterator, Set exercise)
- Conan Gray --- "Heather" (used in Stack example, Map function example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Conan Gray --- "Astronomy" (used in Map function example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)

## Chapter 19: Testing

- Lizzo --- "About Damn Time" (used in test function name `TestAboutDamnTime`, table case name, and exercise 4 `assertNormalized` call)
- Lizzo --- "Good as Hell" (used in `TestGoodAsHell` table-driven test, `FuzzGoodAsHell` fuzz test, and exercise 1 discussion)
- Cleo Sol --- "Golden" (used in `TestGolden` exercise 2 what-does-this-print question)
- Cleo Sol --- "Woman" (used in `BenchmarkWoman` exercise 3 calculation question)

## Chapter 20: Reflection

- Morgan Wallen --- "Last Night" (used in TypeOf/ValueOf intro example as string value; and in exercise 3 SetString starting value)
- Morgan Wallen --- "Thought You Should Know" (used in Elem() / struct example: Song.Title field value)
- Jack Harlow --- "First Class" (solo; used in struct field iteration printFields example: Track.Title; exercise 3 SetString result; and StructToMap exercise answer: Track.Title)
- Jack Harlow --- album "Jackman" (used in exercise 2 Album struct: Album.Title = "Jackman")
