DATE := $(shell git -C .. log -1 --format="%ad" --date=format:"%B %d, %Y")
FILTER := --lua-filter=../g4j/callout.lua --lua-filter=lulu-codebreak.lua

FRONTMATTER := frontmatter-lulu.yaml
AUTHOR := .lulu-author.md
CHAPTERS := ../g4j/ch00.md ../g4j/ch01.md ../g4j/ch02.md ../g4j/ch03.md \
            ../g4j/ch04.md ../g4j/ch05.md ../g4j/ch06.md ../g4j/ch07.md \
            ../g4j/ch08.md ../g4j/ch09.md ../g4j/ch10.md ../g4j/ch11.md \
            ../g4j/ch12.md ../g4j/ch13.md ../g4j/ch14.md ../g4j/ch15.md \
            ../g4j/ch16.md ../g4j/ch17.md ../g4j/ch18.md ../g4j/ch19.md \
            ../g4j/appA.md ../g4j/appB.md ../g4j/appC.md

# Ghostscript flags to flatten transparency and cap image resolution at 600 PPI.
# Lossless FlateEncode keeps raster colors matching the vector background fill.
GS_LULU := gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
           -dCompatibilityLevel=1.3 \
           -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode \
           -dAutoFilterGrayImages=false -dGrayImageFilter=/FlateEncode \
           -dDownsampleColorImages=true -dColorImageResolution=600 \
           -dDownsampleGrayImages=true -dGrayImageResolution=600 \
           -dDownsampleMonoImages=true -dMonoImageResolution=600

SRCS := $(FRONTMATTER) $(AUTHOR) $(CHAPTERS)

PANDOC_OPTS := $(FILTER) \
               --pdf-engine=latexmk --pdf-engine-opt=-lualatex \
               --citeproc --bibliography=../g4j/references.bib --csl=../g4j/references.csl \
               --resource-path=.:../g4j \
               --top-level-division=chapter \
               -V documentclass=book \
               -M subtitle="$(DATE)" \
               -V geometry:"paperwidth=7in" \
               -V geometry:"paperheight=10in" \
               -V geometry:"top=0.6in" \
               -V geometry:"bottom=0.9in" \
               -V geometry:"footskip=0.3in" \
               -V geometry:"inner=0.8in" \
               -V geometry:"outer=0.7in" \
               -V fontsize=11pt

# Lulu Executive wraparound cover (back + spine + front with 0.125in bleed).
COVER_IMG := ../images/g4j-gorgo-cover.png
COVER_BADGE := ../images/gorgo-with-badge.png
COVER_BG := \#081c11

all: lulu-g4j.pdf lulu-cover.pdf

# --- Interior ---

.lulu-author.md: ../g4j/author-intro.md
	sed '1{/^\\newpage$$/d;}' $< > $@

lulu-g4j.pdf: $(SRCS) ../g4j/callout.lua lulu-codebreak.lua ../g4j/references.bib ../g4j/references.csl Makefile
	pandoc $(SRCS) -o $@ $(PANDOC_OPTS)

# --- Cover ---

$(COVER_IMG): $(COVER_BADGE)
	convert "$<" -fuzz 15% -fill '$(COVER_BG)' -opaque white "$@"

.commit-date.tex: FORCE
	@printf '\\def\\CommitDate{%s}\n' '$(DATE)' > $@

lulu-cover.pdf: lulu-cover-raw.pdf
	$(GS_LULU) -sOutputFile=$@ $<

lulu-cover-raw.pdf: lulu-cover.tex .commit-date.tex $(COVER_IMG)
	latexmk -lualatex -interaction=nonstopmode -jobname=lulu-cover-raw lulu-cover.tex
	latexmk -c -jobname=lulu-cover-raw lulu-cover.tex

# --- Clean ---

clean:
	rm -f lulu-g4j.pdf .lulu-author.md *.idx *.ilg *.ind
	rm -f lulu-cover.pdf lulu-cover-raw.pdf
	rm -f .commit-date.tex lulu-cover-raw.aux lulu-cover-raw.log lulu-cover-raw.fls lulu-cover-raw.fdb_latexmk

.PHONY: all clean FORCE
FORCE:
