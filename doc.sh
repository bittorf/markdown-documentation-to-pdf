#!/bin/sh
#
# https://vijual.de/2019/03/11/artikel-mit-markdown-und-pandoc-schreiben/
# apt-get -y install pandoc texlive-fonts-extra texlive-luatex texlive-lang-german

for FILE in $1 *.md; do break; done
[ -f "$FILE" ] || exit

TITLE="$( basename -- "$FILE" )"
TITLE="${FILE%.*}"

PANDOC_LANG='de-DE'
FILE_UNIXTIME="$( date +%s -r "$TITLE.md" )"
FILE_DATE="$( date -d @$FILE_UNIXTIME "+%d-%m-%Y" )"

pandoc \
  --standalone \
  --highlight-style="zenburn" \
  --template default.latex \
  --listings \
  --top-level-division=chapter \
  --wrap=preserve \
  --number-sections \
  --pdf-engine=lualatex \
  -V geometry:margin=3cm \
  -V papersize=a4paper \
  -V fontfamily=libertine \
  -V monofont=inconsolata \
  -V fontsize=12pt \
  -V colorlinks \
  -V breakurl \
  -V hyphens=URL \
  -V lang="${PANDOC_LANG}" \
  -V toc \
  -V lof \
  -V lot \
  -V date="${FILE_DATE}" \
  -V links-as-notes \
  -V documentclass="report" \
  -f markdown -o "${TITLE}.pdf" "${TITLE}.md" && \
     printf '%s\n' "[OK] generated '$TITLE.pdf'"
