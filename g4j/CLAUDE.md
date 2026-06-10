# Project Description

Gorgo Go for Java for programmers.
This book covers all the topics that a good Go programmer uses in daily life in industry from the perspective of a Java programmer.

## Chapters

- DO NOT MODIFY THE AUTHOR INTRO section
- each numbered element in `Content` represents a chapter
- do not spend a lot of time on concepts that are the same between Java and Go --- just mention the concept is the same and move on
- each chapter starts with an introducton to the topics covered. motivation for the topics highlighting things that are hard to do without knowledge of the topics, and a brief overview of the section
- each chapter ends with a brief highlight of key points
- each chapter has some exercises to test reader's comprehesion. there should be a mix of the following types of questions:
    - though provoking questions to make them think a little deeper about what they have read
    - what does this do type questions, where they get a snippet of code and predict what it will do
    - calculation questions to quickly and objectively test comprehension, like `what is the sizeof ilist for int ilist[4] on a system where int is 32-bit?`
    - where is the bug type questions, where you show some code and ask what the problem is
    - propose a short test program they should write to test their knowledge
- an answer key should be generated as a separate document from the main chapter content, containing each exercise question and its answer

## Examples

- for strings, use 2020s references, lyrics from PLAYLIST.md songs, and Spanish occasionally. Keep it short.
- cover up to Go 1.26
- avoid repeating lyrics in examples even across chapters
- Validate examples to make sure syntax and result is correct
- Create short example programs to illustrate the concepts covered

## Format and Style

- Use Pandoc markdown
- Use correct grammar and capitalizations
- All callouts use `::: {.tip}` as the div class --- `callout.lua` only handles `.tip`
- Differentiate callout types with a bold label on the first line inside the div:
    - `**Tip:**` for idioms and best practices
    - `**Trap:**` for common mistakes
    - `**Wut:**` for unexpected or counterintuitive rules
- Callouts are rendered as full-width `tcolorbox` boxes via `callout.lua` --- do not use `wrapfigure`
- Keep the tone professional but light --- occasional sarcasm, slang, and informal phrasing are welcome; don't strip them out or replace them with formal language
- Preserve emojis and text emojis (e.g., `:'(`) in the text --- do not remove them
- Refer to the reader as `you`
- do not wrap sentences in the markdown. every sentence gets its own line
- the first time a fuction or operator is mentioned show it's signature
    -if it is overloaded and the overloaded variants aren't mentioned later, mention at the end of the subsection concisely. show signatures but not examples
- when listing methods or functions in a signature block, add a short inline comment to each line explaining what it does

## Build

- Build with: `make` (or `make all` for both PDFs)
- Uses `pandoc` with `--lua-filter=callout.lua` and `--pdf-engine=latexmk --pdf-engine-opt=-lualatex`
- `latexmk` handles the multi-pass build needed for the index
- Requires `header-includes` for `\usepackage[most]{tcolorbox}` and `\usepackage{makeidx}` (already in frontmatter)

## Table of Contents and Index

- TOC is generated automatically via `toc: true` and `toc-depth: 2` in the YAML frontmatter
- index uses LaTeX `makeidx` package with `\index{}` markers throughout the text
- place `\index{term}` at the primary introduction/definition of a term, not inside code blocks
- use `\index{parent!child}` for sub-entries (e.g., `\index{pointer!arithmetic}`)
- in `\index{}`, escape double quotes by doubling them (e.g., `\index{extern ""C""}`)
- `\printindex` goes only in appC.md (the last file built into the book) --- do not add it to other chapters or appendices

## Playlist References

- PLAYLIST.md tracks all songs and references used in the text, organized by chapter
- do not repeat references already listed in PLAYLIST.md
- when adding or changing a reference in the text, update PLAYLIST.md to match
- avoid references to guns (including ammunition) and violence

## Cross-References Between Chapters

- when a concept is introduced in one chapter and used in a later chapter, reference the earlier chapter rather than re-explaining it
- after any chapter renumbering, run a cross-reference audit before the next structural change: `grep -rn "Chapter [0-9]" ch*.md app*.md | grep -v answers`
- push after each structural reorganization; do not stack multiple reorganizations before auditing

## Makefile Hygiene

- every ch*.md and app*.md file must appear in the CHAPTERS list in Makefile; omitted files are silently excluded from the PDF
- the last file in CHAPTERS must contain `\printindex` (currently appC.md)
- after renaming or deleting chapter files, update CHAPTERS, g4j-answers.md chapter headings, and PLAYLIST.md in the same commit

## Working with Claude

- use programmatic checks (Python/grep/bash) for mechanical validation before launching agents: callout balance, cross-reference numbers, exercise type coverage, receiver consistency
- validate in batches of 3--4 chapters rather than all at once to avoid rate limits and get actionable results sooner
- for large fan-outs (writing 10+ chapters), use the `/workflow` command rather than parallel Agent calls to get better failure handling and concurrency control
- when an agent writes a file that already exists, verify the original was not overwritten before running the build

## Verifying the Book

### mechanical checks (script these; do not delegate to agents)

- every `::: {.tip}` fence must be preceded by a blank line --- a non-blank line above it (even `\index{}`) makes the callout render as literal `::: {.tip}` text in the PDF
- every callout body starts with `**Tip:**`, `**Trap:**`, or `**Wut:**`; fence opens equal fence closes per file
- code-block lines must be at most 96 chars, and at most 80 inside callouts --- longer lines clip at the page edge and verbatim produces NO overfull warning, so the LaTeX log will not catch this
- no unicode em/en dashes outside code blocks; no `\index{}` inside code blocks
- every ch*.md/app*.md is in CHAPTERS; cross-reference audit via `grep -rn "Chapter [0-9]"`
- every chapter has Try It, Key Points, and Exercises; g4j-answers.md has a heading per chapter and restates every exercise question (including code snippets) before its answer

### PDF checks (the make build discards the LaTeX log)

- to get a log, pandoc the book to .tex in a temp dir and run latexmk there; ignore the `../images` not-found errors (path artifact) and look for Overfull hbox of 20pt+, "undefined", and "missing character"
- pdftotext the built PDF and grep for leftover markup: `:::`, `{.tip}`, `\index{`, `[@`, `??` --- then visually read any suspect page
- visually read every page containing a table (column overlap does not show up in any log or text scan)

### content checks (read-only finder agents, one per chapter)

- extract and actually run every Go example (`go run`/`go vet` in /tmp); claimed outputs in comments and prose must match observed output
- verify every "since Go 1.X" claim, install path, CLI flag, and third-party API name (pgx, golangci-lint, dlv) against the current toolchain --- several were stale or wrong on first audit
- check PLAYLIST.md in both directions: every reference in the text is listed under the right chapter, and every listed entry still exists in the text
- have agents return structured findings with severity (error/warning/suggestion) and verify each claim yourself before editing --- agents produce occasional false positives (e.g. flagging the intentional `***[rule-name]***` convention as an artifact)
- when an exercise is reworded, grep g4j-answers.md for the old wording and change both files in the same edit pass
- fix-up agents get exactly one file each and must not run git commands; review the full diff before committing

## Content

DO NOT MODIFY THE AUTHOR INTRO section before chapter 0. it is written in lowercase to match the author's informal writing

0. How to use this book:
    - conventions explained
    - chapter layout

