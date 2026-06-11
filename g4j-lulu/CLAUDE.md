# project description

lulu print build for `Gorgo Go for Java Programmers`. produces both the interior PDF (`lulu-g4j.pdf`) and the wraparound cover PDF (`lulu-cover.pdf`).

## building

run `make` in g4j-lulu/ to build both PDFs. the Makefile automatically injects the last commit date as the subtitle.

- `make lulu-g4j.pdf` --- interior only
- `make lulu-cover.pdf` --- cover only
- `make clean` --- remove all build artifacts

none of the build outputs are committed (see the repo .gitignore); upload the two PDFs to lulu manually.

## interior (`lulu-g4j.pdf`)

- builds the g4j chapters (ch00--ch19, appA--appC) straight from ../g4j/ --- no content is duplicated here
- lulu executive trim: 7x10in (paperwidth=7in, paperheight=10in)
- margins: inner=0.8in, outer=0.7in, top=0.6in, bottom=0.9in, footskip=0.3in (footer must stay 0.5in+ from the trim edge for lulu; changing the text block reflows pages and invalidates the cover spine width)
- text width is 5.5in --- g4j body code lines run up to 96 monospace characters, so code blocks are set at `\scriptsize` via `\fvset{fontsize=\scriptsize}` (96 chars = 392.9pt vs 397.5pt text width); callout code must stay within 80 chars
- `lulu-codebreak.lua` splits long inline code spans with `\allowbreak` after `/`, `.` and `(` --- without it, prose with tokens like `github.com/darude/sandstorm/cmd/server` overflows the narrow measure by up to 90pt
- verbatim overflow produces no overfull warning in the LaTeX log --- check by counting characters in the markdown; emoji render roughly double width
- when a code line is too wide, first tighten the whitespace before aligned trailing `//` comments, then trim the comment text; restructure the code itself only as a last resort
- dedication page after the title page (centered reader message, links to https://gorgo.dev/go)
- the index from appC.md's `\printindex` stays in the print book

## cover (`lulu-cover.pdf`)

### content

- front cover: the `g4j-gorgo-cover.png` image (background color `#081c11` --- dark green --- matched to the full-bleed cover background). title is `Gorgo Go for Java Programmers`. subtitle is the date of the last commit. no author name on the front.
- spine: title centered, `Gorgo Books` at the base of the spine
- back cover: a cheetsheet with tables from the g4j book (spelled `Cheetsheet` on purpose to indicate it is not for actual cheating --- do not correct it):
    - fmt verbs (ch01 and ch14)
    - Go types and their Java equivalents (ch02)
    - zero values (ch02)
    - the go tool commands (ch01 and ch13)
    - slices and maps operations (ch07)
    - channel operations (ch10)
- back cover bottom left: `https://gorgo.dev/go`
- spine width is computed from the interior page count at lulu's 0.0023773in per page (derived from the sc++c book: 440 pages = 1.046in); rebuild the interior and recompute before uploading if the page count changes --- the layout coordinates in lulu-cover.tex are documented in its header comment

### cover image

`g4j-gorgo-cover.png` is a make target --- it is generated from `gorgo-with-badge.png` by flood-filling the white background with `#081c11` (the full-bleed cover background color). it is gitignored; `make` regenerates it.

## lulu compliance

- no transparency in final PDFs (ghostscript flattens the cover with `-dCompatibilityLevel=1.3`)
- image resolution capped at 600 PPI
- lossless image encoding to avoid color shifts between raster images and vector fills
- all cover text stays 0.5in inside the trim edges; the barcode exclusion zone on the back cover bottom-left area stays empty except the URL
