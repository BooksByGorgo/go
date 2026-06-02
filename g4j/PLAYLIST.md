# Playlist

Tracks all song, artist, and lyric references used in the book, organized by chapter.
Do not repeat any reference already listed here.

## Chapter 1: Hello, Go
- Darude --- "Sandstorm" (used in fmt.Println and fmt.Printf examples)
- Darude --- Grammy award count (used in fmt.Printf example)
- Disturbed --- "The Sound of Silence" (used in format verbs %q example)
- Ozzy Osbourne --- "Crazy Train" (used in exercise 2)
- Miley Cyrus --- "Flowers" (artist name used in fmt.Scanf example)

## Chapter 2: Types and Variables
- StreamingTier iota block (Free/Standard/Premium/Lossless) --- fictional names, no specific artist
- ChartPosition iota block --- fictional, no specific artist
- BT --- "Flaming June" (used in := short declaration and multiple-assignment examples)
- Gouryella & Ferry Corsten --- "Gouryella" (used in named and positional struct literal examples; abbreviated to "Gouryella" in code)
- System F --- "Out Of The Blue" (used in anonymous struct example and exercise 5 Song slice)
- Matt Darey & Lost Tribe --- "Gamemaster" (used in struct value-type copy example)
- Chicane --- "Saltwater (feat. Moya Brennan)" (used in methods on structs example)
- Angoscia --- "Emerald Triangle 2012" (used in embedding example)
- Energy 52 --- "Café Del Mar (Three 'n One Remix)" (used in cmp.Compare / slices.SortFunc example)
- Disturbed --- "The Sound of Silence" (used in cmp.Compare / slices.SortFunc example)
- Robert Dream House & Miles Stone --- "Children (Miles Stone Remix Edit)" (used in cmp.Compare / slices.SortFunc example; abbreviated to "Robert Dream House" in code)
- DJ Analyzer, Cary August, Gimbal & Sinan --- "Insomnia" (used as map key in clear() example; abbreviated to "DJ Analyzer" in code)
- Darude --- "Sandstorm" (used in exercise 2)
- Ozzy Osbourne --- "Crazy Train" (used in exercise 2 as reassigned artist name)
- BT --- "Flaming June" (used in exercise 4 catalog map)
- Darude --- "Sandstorm" (used in exercise 4 catalog map)
- DJ Analyzer --- "Insomnia" (used in exercise 4 catalog map)
- Chicane --- "Saltwater" (used in exercise 5 Song slice)
- Angoscia --- "Emerald Triangle 2012" (used in exercise 5 Song slice)
- System F --- "Out Of The Blue" (used in exercise 7 code snippet)

## Chapter 3: Strings, Bytes, and Runes
- Richaadeb & Cristina Vee --- "Bad Apple!!" (used in strings.Contains/HasPrefix/HasSuffix/Count/Index examples)
- Darude --- "Sandstorm" (used in strings.Builder example)
- DJ Cobra --- "Better Off Alone (feat. Jacinta)" (used in strings.Trim example)
- BT --- album "ESCM" (used in raw string literal JSON example)
- Alizée --- artist name with non-ASCII é (used in byte/rune calculation exercise)

## Chapter 4: Control Flow
- Darude --- "Sandstorm" (used in if-init-statement example)
- *(Spanish vocabulary used elsewhere: manzana, naranja, uva, lunes, sábado, domingo, fiebre, cancion)*

## Chapter 5: Functions
- Ozzy Osbourne --- "Crazy Train" (used in pointer mutation examples)
- DJ Cobra --- "Better Off Alone" (used in the first-class function / transformer example)
- "hola, mundo!" --- Spanish greeting used in the middleware pattern example
- "martes" / "jueves" --- Spanish day names used as map keys in the init() example

## Chapter 6: Methods and Embedding
- BT --- "Flaming June" (used in receiver and methods examples)
- Angoscia --- "Emerald Triangle 2012" (used in Playlist embedding examples)
- Matt Darey & Lost Tribe --- "Gamemaster" (used in embedding and constructor examples)
- Alizée --- artist name (used as featured artist in FeaturedTrack embedding example)
- System F --- "Out Of The Blue" (used in exercise 4 nil embedded pointer bug: Song title)

## Chapter 7: Maps and Slices
- BT --- "Flaming June" (used in slice aliasing example: track slice)
- Darude --- "Sandstorm" (used in slice aliasing example, addTrack function, slices.Sort example, and exercise 5)
- Gouryella & Ferry Corsten --- "Gouryella" (used in addTrack function example; abbreviated to "Gouryella" in code)
- Disturbed --- "The Sound of Silence" (used in slices.Sort example)
- Richaadeb & Cristina Vee --- "Bad Apple!!" (used in slices.Sort example and exercise 5)
- Ozzy Osbourne --- "Crazy Train" (used in slice aliasing example: reassigned track[0])
- Chicane --- "Saltwater" (used in map literal example: streams map and exercise 2 catalog map)
- System F --- "Out Of The Blue" (used in streams map literal and exercise 2 catalog map)
- Matt Darey & Lost Tribe --- "Gamemaster" (used in streams map literal and exercise 4 word-frequency input)
- Angoscia --- "Emerald Triangle 2012" (used in catalog map comma-ok example)
- DJ Cobra --- "Better Off Alone" (used in catalog map comma-ok example and exercise 5)
- Robert Dream House & Miles Stone --- "Children" (used in catalog map comma-ok example; abbreviated to "Robert Dream House" in code)
- Darude --- "Sandstorm" (used in exercise 5 grouped-by-letter map input)

## Chapter 8: Interfaces
- San Mehat --- "Sounds of Slashdot" (used in Track struct Stringer example: 144 BPM)
- Chicane --- "Saltwater" (used as string value in any/interface{} type assertion example)
- "Bienvenidos!" --- Spanish greeting used in http.HandlerFunc example
- Disturbed --- "The Sound of Silence" (used in sort.Interface ByTitle example)
- Darude --- "Sandstorm" (used in sort.Interface ByTitle example)
- DJ Cobra --- "Better Off Alone" (used in sort.Interface ByTitle example)

## Chapter 9: Error Handling
- Andrew Spencer et al. --- "Zombie (Ray Knox Remix Edit)" (used in errors.Join / validateAlbum example; abbreviated to "Andrew Spencer" in code)
- DJ Analyzer, Cary August, Gimbal & Sinan --- "Insomnia" (used in PlaybackError / custom error type example; abbreviated to "DJ Analyzer" in code)
- Robert Dream House & Miles Stone --- "Children" (used in io.EOF sentinel read loop; abbreviated to "Robert Dream House" in code)
- Darude --- "Sandstorm" (used in safePlay example)
- Chicane --- "Saltwater" (used in io.EOF sentinel read loop)

## Chapter 10: Goroutines and Channels
- Jaroslav Beck --- "Escape (feat. Summer Haze)" (used in goroutine launch example and source goroutine in fan-in)
- Jaroslav Beck --- "$100 Bills" (used in channel send example, playlist slice)
- Jaroslav Beck & Crispin --- "Legend (feat. Backchat)" (used in playTrack example, playlist slice)
- Jaroslav Beck --- "Turn Me On (feat. Tiny C)" (used in buffered channel example, playlist slice)
- DJ Cobra --- "Better Off Alone" (lyrics "Do you think you're better off alone?" used in fetchLyrics channel send example)

## Chapter 11: Synchronization
- Jaroslav Beck --- "Escape" (used in WaitGroup fan-out, sync.Once catalog map, atomic play counter)
- Jaroslav Beck --- "$100 Bills" (used in WaitGroup fan-out, atomic play counter, exercise 4 SafeMap key)
- Jaroslav Beck & Crispin --- "Legend" (used in WaitGroup fan-out, sync.Cond queue, atomic play counter)
- Alizée --- "J'ai pas vingt ans !" (used in sync.Once catalog map, atomic play counter, exercise 4 SafeMap key)
- Alizée --- "J'en ai marre !" (used in sync.Cond queue, atomic play counter)

## Chapter 12: Context and Concurrency Patterns
- Gouryella & Ferry Corsten --- "Gouryella" (used in fetchLyrics timeout example and errgroup fan-out; abbreviated to "Gouryella" in code)
- BT --- "Flaming June" (used in errgroup fan-out and exercise 2)
- Chicane --- "Saltwater" (used in errgroup fan-out and exercise 2)
- Matt Darey & Lost Tribe --- "Gamemaster" (used in goroutine leak example)

## Chapter 13: Packages and Modules
- Angoscia --- "Emerald Triangle 2012" (used in module path and import path examples, exercise 2)
- Darude --- "Sandstorm" (used as module name reference in go.mod example)
- Robert Dream House & Miles Stone --- "Children" (used as module name in exercise 5 multi-package project; abbreviated to "Robert Dream House" in code)
- DJ Cobra --- "Better Off Alone" (used in exercise 4 module name)

## Chapter 14: Essential Standard Library
- Ozzy Osbourne --- "Crazy Train" (used in Track struct %v/%+v/%#v example; and exercise 4 titles list)
- Disturbed --- "The Sound of Silence" (used in io.Pipe goroutine example; exercise 4 titles list)
- Energy 52 --- "Café Del Mar (Three 'n One Remix)" (used in slog.Info example; exercise 2 scanner input; exercise 4 titles list)
- Andrew Spencer et al. --- "Zombie (Ray Knox Remix Edit)" (used in bufio.NewWriter Flush example; exercise 2 scanner input; exercise 4 titles list; abbreviated to "Andrew Spencer" in code)
- Richaadeb & Cristina Vee --- "Bad Apple!!" (used in encoding/base64 and crypto/sha256 examples)

## Chapter 15: JSON, HTTP, and the Web
- Darude --- "Sandstorm" (used in json.Marshal/Unmarshal example: Song struct title, catalog map, exercise 5)
- System F --- "Out Of The Blue" (used in struct tag omitempty example and POST body example)
- BT --- "Flaming June" (used in struct tag omitempty example and encoding/xml example)
- Chicane --- "Saltwater (feat. Moya Brennan)" (used in songHandler streaming Encoder example and catalog map)
- "Hola!" --- Spanish greeting used in minimal HTTP server handler example

## Chapter 16: Database Access
- San Mehat --- "Sounds of Slashdot" (used in bulk insert example, complete music store, exercise 3)
- Matt Darey & Lost Tribe --- "Gamemaster" (used in bulk insert example, complete music store)
- "DJ Essentials: Trance" (fictional album used as album value in Song struct inserts)
- Alizée --- "J'ai pas vingt ans !" (used in bulk insert example; album "Mes Courants Électriques..."; Exercise 2)
- Gouryella & Ferry Corsten --- "Gouryella" (used in bulk insert example as NULL-album song; abbreviated to "Gouryella" in code)
- Alizée --- album "Mes Courants Électriques..." (referenced as album value)

## Chapter 17: Generics
- Jaroslav Beck --- "Escape" (used in Map function example, Stack example, MapFromSlice example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Jaroslav Beck --- "$100 Bills" (used in Map function example, ArtistTitles iterator, Set exercise)
- Alizée --- "J'ai pas vingt ans !" (used in Stack example, Map function example, ArtistTitles iterator, Filter exercise, Dedupe exercise, Set exercise)
- Alizée --- "J'en ai marre !" (used in Map function example, Filter exercise, Dedupe exercise, Set exercise)
- Jaroslav Beck --- "Legend" (used in Set exercise as a negative Contains test)

## Chapter 18: Testing
- Richaadeb & Cristina Vee --- "Bad Apple!!" (used in test function name TestBadApple, table case name, and exercise 4 assertNormalized call)
- DJ Cobra --- "Better Off Alone" (used in TestBetterOffAlone table-driven test, FuzzBetterOffAlone fuzz test, and exercise 1 discussion)
- Disturbed --- "The Sound of Silence" (used in TestSoundOfSilence exercise 2 what-does-this-print question)
- Ozzy Osbourne --- "Crazy Train" (used in BenchmarkCrazyTrain exercise 3 calculation question)

