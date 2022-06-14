#!/bin/sh
#
# from: https://github.com/bittorf/markdown-documentation-to-pdf
#
# see:
# https://vijual.de/2019/03/11/artikel-mit-markdown-und-pandoc-schreiben/
# apt-get -y install pandoc texlive-fonts-extra texlive-luatex texlive-lang-german

for FILE in $1 *.md; do break; done	# get first
[ -f "$FILE" ] || exit 1

PANDOC_LANG='de-DE'
TITLE="$( basename -- "$FILE" )"	# e.g. doc.md
TITLE="${FILE%.*}"			# e.g. doc

check_qpdf() { command -v 'qpdf' >/dev/null && return 0; echo "[ERROR] please install 'qpdf'"; exit 1; }
read -r PDF_USERPASS  2>/dev/null <PDF_USERPASS.txt  && check_qpdf
read -r PDF_OWNERPASS 2>/dev/null <PDF_OWNERPASS.txt && check_qpdf

grep -q ^'include@' "$FILE" && {
	TMPFILE="$( mktemp --suffix=.md )" || exit 1
	cp "$FILE" "$TMPFILE" && FILE="$TMPFILE"

	while LINE_NO="$( grep -m1 -n ^'include@' "$FILE" )"; do {
		LINE_NO="$( echo "$LINE_NO" | cut -d: -f1 )"
		INCLUDE="$( sed  -n "${LINE_NO}p" "$FILE" | cut -d@ -f2 )"

		if [ -f "$INCLUDE" ]; then
			MYFILE="$INCLUDE"
		else
			DOWNLOAD="$( mktemp --suffix=.md )" || exit 1
			printf '%s\n\n' "[Quelle]($INCLUDE)" >"$DOWNLOAD"
			wget --tries=3 --timeout=5 -O - "$INCLUDE" >>"$DOWNLOAD" || exit 1
			MYFILE="$DOWNLOAD"
		fi

		sed -i "\|^include@${INCLUDE}$|r $MYFILE" "$FILE" || exit 1
		sed -i "\|^include@${INCLUDE}$|d"         "$FILE" || exit 1
		rm -f "$DOWNLOAD" 2>/dev/null
	} done
}

[ -z "$FILE_DATE" ] && {
	FILE_UNIXTIME="$( date +%s -r "$TITLE.md" )"
	FILE_DATE="$( date -d "@$FILE_UNIXTIME" "+%Y-%m-%d" )"	# e.g. 2019-12-31
}

encrypt_pdf_maybe()
{
	[ -z "$PDF_USERPASS" ] && [ -z "$PDF_OWNERPASS" ] && return 0

	qpdf --object-streams=disable --encrypt "$PDF_USERPASS" "${PDF_OWNERPASS:-$PDF_USERPASS}" 256 \
		--print=none --modify=none --extract=n -- "$OUT" "$ENCRYPTED"
}

OUT="${FILE_DATE}_${TITLE}.pdf"
ENCRYPTED="${FILE_DATE}_${TITLE}-password.pdf"

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
  -V date="${FILE_DATE}" \
  -V links-as-notes \
  -V documentclass="report" \
  -f markdown -o "$OUT" "$FILE" && {
    encrypt_pdf_maybe "$OUT"
    rm -f "$TMPFILE" 2>/dev/null
    printf '%s\n' "[OK] generated '$OUT'"
    xdg-open "$OUT"
}
