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
- Teddy Swims --- "Lose Control" (used in `:=` short declaration and multiple-assignment examples)
- The Weeknd & Playboi Carti --- "Timeless" (used in named and positional struct literal examples)
- The Weeknd --- "Save Your Tears" (used in anonymous struct example and exercise 5 Song slice)
- Doja Cat --- "Agora Hills" (used in struct value-type copy example)
- Lola Young --- "Messy" (used in methods on structs example)
- Rosalía --- "MOTOMAMI" (used in embedding example)
- FloyyMenor & Cris MJ --- "Gata Only" (used in cmp.Compare / slices.SortFunc example)
- The Weeknd --- "Starboy" (used in cmp.Compare / slices.SortFunc example)
- JVKE --- "Golden Hour" (used in cmp.Compare / slices.SortFunc example and exercise 5 Song slice)
- Stephen Sanchez & Em Beihold --- "Until I Found You" (used in cmp.Compare / slices.SortFunc example)
- Harry Styles (name used as map key in clear() example)
- Peso Pluma --- "La Bebé" (used in exercise 2)
- Natanael Cano (used in exercise 2 as reassigned artist name)
- Denzel Curry --- "Gasoline" (used in exercise 4 catalog map)
- Lil Nas X & Jack Harlow --- "Industry Baby" (used in exercise 4 catalog map)
- Linkin Park --- "Numb" (used in exercise 4 catalog map)
- Billie Eilish --- "Bad Guy" (used in exercise 7 code snippet)
- The Kid LAROI & Justin Bieber --- "Stay" (used in exercise 5 Song slice)
- Sam Smith --- "Unholy" (used in exercise 5 Song slice)

## Chapter 3: Strings, Bytes, and Runes

- Miley Cyrus --- "Flowers" (used in strings.Contains/HasPrefix/HasSuffix/Count/Index example: "I can buy myself flowers")
- Sabrina Carpenter --- "Espresso" (used in strings.Builder example)
- Steve Lacy --- "Bad Habit" (used in strings.Trim example)
- Doja Cat --- album "Scarlet" (used in raw string literal JSON example)
- Beyoncé --- artist name with non-ASCII é (used in byte/rune calculation exercise)

## Chapter 4: Control Flow

- Miley Cyrus --- "Flowers" (used in if-init-statement example: `if n := len("Flowers"); n > 6`)
- *(Spanish vocabulary used elsewhere: manzana, naranja, uva, lunes, sábado, domingo, fiebre, cancion)*

## Chapter 5: Functions

- Harry Styles --- "As It Was" (used in pointer mutation examples)
- Billie Eilish --- "Birds of a Feather" (used in the first-class function / transformer example)
- "hola, mundo!" --- Spanish greeting used in the middleware pattern example
- "martes" / "jueves" --- Spanish day names used as map keys in the `init()` example

## Chapter 6: Methods and Embedding

- Lola Young --- "Messy" (used in receiver and methods examples)
- Rosalía --- "MOTOMAMI" (used in Playlist embedding examples)
- JVKE --- "Golden Hour" (used in embedding and constructor examples)
- Feid --- "Chorizo Asado" (used in exercise 4 nil embedded pointer bug: Song title)

## Chapter 7: Maps and Slices

- Glass Animals --- "Heat Waves" (used in slice aliasing example: `track` slice)
- Harry Styles --- "As It Was" (used in slice aliasing example, addTrack function, slices.Sort example, and exercise 5 input)
- Dua Lipa --- "Levitating" (used in addTrack function example, slice aliasing track slice, and exercise 4 word-frequency input)
- Olivia Rodrigo --- "Vampire" (used in slices.Sort example)
- SZA --- "Kill Bill" (used in slices.Sort example and exercise 5 input)
- Kendrick Lamar --- "Not Like Us" (used in slice aliasing example: reassigned track[0])
- The Weeknd --- "Blinding Lights" (used in map literal example: streams map and exercise 2 catalog map)
- Ed Sheeran --- "Shape of You" (used in streams map literal and exercise 2 catalog map)
- The Kid LAROI & Justin Bieber --- "Stay" (used in streams map literal and exercise 4 word-frequency input)
- Metro Boomin & The Weeknd --- "Creepin'" (used in catalog map comma-ok example)
- Steve Lacy --- "Bad Habit" (used in catalog map comma-ok example and exercise 5 input)
- Olivia Rodrigo --- "good 4 u" (used in catalog map comma-ok example)
- Bastille --- "As The World Caves In" (used in exercise 5 grouped-by-letter map input)

## Chapter 8: Interfaces

- Lady Gaga & Bruno Mars --- "Die With A Smile" (used in Track struct Stringer example: title "Die With A Smile", 144 BPM)
- Bizarrap --- "bzrp music session" (used as string value in any/interface{} type assertion example)
- "Bienvenidos!" --- Spanish greeting used in http.HandlerFunc example
- Chappell Roan --- "Good Luck, Babe!" (used in sort.Interface ByTitle example)
- Benson Boone --- "Beautiful Things" (used in sort.Interface ByTitle example)
- Gracie Abrams --- "That's So True" (used in sort.Interface ByTitle example)

## Chapter 9: Error Handling

- Bad Bunny --- "Un Verano Sin Ti" (used in errors.Join / validateAlbum example: album title)
- Bad Bunny --- "Tití Me Preguntó" (used in PlaybackError / custom error type example: track name; and exercise 2 lookup call)
- Karol G --- "TQG" (used in io.EOF sentinel read loop example: track title; and exercise 3 validateSong input)
- Karol G --- "Provenza" (used in io.EOF sentinel read loop example: track title; and safePlay example)
- Karol G --- "Mi Ex Tenía Razón" (used in io.EOF sentinel read loop example: track title)

## Chapter 10: Goroutines and Channels

- Tyler, The Creator --- "Earfquake" (used in goroutine launch example and source goroutine in fan-in example)
- Tyler, The Creator --- "Wilder World" (used in channel send example lyric, produce function, playlist slice, and exercise 5)
- Post Malone --- "Circles" (used in playTrack example, buffered channel example, playlist slice, and exercise 5)
- Post Malone --- "rockstar" (used in channel send example, playlist slice, and exercise 5)

## Chapter 11: Synchronization

- NewJeans --- "Ditto" (used in Playlist.Add mutex example, sync.Once catalog map, WaitGroup fan-out, sync.Cond queue)
- NewJeans --- "Hype Boy" (used in WaitGroup fan-out, atomic play counter, exercise 4 SafeMap key)
- NewJeans --- "ETA" (used in WaitGroup fan-out, sync.Cond queue, atomic play counter)
- BTS --- "Dynamite" (used in sync.Once catalog map, atomic play counter)
- BTS --- "Butter" (used in atomic play counter, exercise 4 SafeMap key)

## Chapter 12: Context and Concurrency Patterns

- Laufey --- "From The Start" (used in fetchLyrics timeout example and errgroup fan-out example)
- Laufey --- "Bewitched" (used in errgroup fan-out example and exercise 2)
- Hozier --- "Too Sweet" (used in errgroup fan-out example and exercise 2)
- Hozier --- "Work Song" (used in goroutine leak example)

## Chapter 13: Packages and Modules

- Zach Bryan --- "Something in the Orange" (used in module path and import path examples, and exercise 2 lyrics output)
- Zach Bryan --- "I Remember Everything" (used as module name reference in go.mod example: remembereverything)
- Noah Kahan --- "Stick Season" (used as module name in exercise 5 multi-package project)
- Noah Kahan --- "Northern Attitude" (used in exercise 4 module name)

## Chapter 14: Essential Standard Library

- Ariana Grande --- "positions" (used in Track struct %v/%+v/%#v example: title "positions", BPM 114; and exercise 4 titles list)
- Ariana Grande --- "thank u, next" (used in io.Pipe goroutine example: string written to pipe; and exercise 4 titles list)
- Dua Lipa --- "Physical" (used in slog.Info example: title "Physical", BPM 130; and exercise 2 scanner input; exercise 4 titles list)
- Dua Lipa --- "Don't Start Now" (used in bufio.NewWriter Flush example: string written to buffer; exercise 2 scanner input; exercise 4 titles list)
- Zach Bryan --- "Something in the Orange" (used in encoding/base64 example and crypto/sha256 example)

## Chapter 15: JSON, HTTP, and the Web

- Rauw Alejandro --- "Todo De Ti" (used in json.Marshal/Unmarshal example: Song struct title, catalog map, exercise 5 pre-populated Song)
- Rauw Alejandro --- "Lokera" (used in struct tag omitempty example and POST body example)
- Kali Uchis --- "telepatía" (used in struct tag omitempty example and encoding/xml example)
- Kali Uchis --- "I Wish You Roses" (used in songHandler streaming Encoder example and catalog map)
- "Hola!" --- Spanish greeting used in minimal HTTP server handler example

## Chapter 16: Database Access

- Victoria Monét --- "On My Mama" (used in bulk insert example, complete music store example, and exercise 3 transaction trace)
- Victoria Monét --- "Coastin'" (used in bulk insert example and complete music store example; album "JAGUAR II")
- Victoria Monét --- album "JAGUAR II" (referenced as album value in Song struct inserts)
- Omar Apollo --- "Evergreen" (used in bulk insert example; album "IVORY"; Exercise 2 sql.Null example)
- Omar Apollo --- "Killing Me" (used in bulk insert example as NULL-album song; Exercise 2 sql.Null example)
- Omar Apollo --- album "IVORY" (referenced as album value in Song struct inserts)

## Chapter 17: Generics

- Tate McRae --- "greedy" (used in Map function example, Stack example, MapFromSlice example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Tate McRae --- "you broke me first" (used in Map function example, ArtistTitles iterator, Set exercise)
- Conan Gray --- "Heather" (used in Stack example, Map function example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Conan Gray --- "Astronomy" (used in Map function example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Conan Gray --- "Maniac" (used in Set exercise as a negative Contains test)

## Chapter 18: Testing

- Lizzo --- "About Damn Time" (used in test function name `TestAboutDamnTime`, table case name, and exercise 4 `assertNormalized` call)
- Lizzo --- "Good as Hell" (used in `TestGoodAsHell` table-driven test, `FuzzGoodAsHell` fuzz test, and exercise 1 discussion)
- Cleo Sol --- "Golden" (used in `TestGolden` exercise 2 what-does-this-print question)
- Cleo Sol --- "Woman" (used in `BenchmarkWoman` exercise 3 calculation question)

## Chapter 19: Reflection

- Morgan Wallen --- "Last Night" (used in TypeOf/ValueOf intro example as string value; and in exercise 3 SetString starting value)
- Morgan Wallen --- "Thought You Should Know" (used in Elem() / struct example: Song.Title field value)
- Jack Harlow --- "First Class" (solo; used in struct field iteration printFields example: Track.Title; exercise 3 SetString result; and StructToMap exercise answer: Track.Title)
- Jack Harlow --- album "Jackman" (used in exercise 2 Album struct: Album.Title = "Jackman")
