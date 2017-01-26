#!/bin/sh
# Joerg Meyer, 2004-03-15

echo "SAP-Exportdateien zum Access-Import vorbereiten"

if [ x"$1" = x ]
then echo "usage: $0 filename(s)";
    exit 1;
fi

for fnm in $*; do

    nfn=imp_${fnm%.txt}.csv;

    echo Wandle Datei $fnm ... $nfn

    sed -e '1,3d' \
        -e '/^-/d' \
        -e '/^ *$/d' \
        -e 's/^|//' \
        -e 's/|$//' \
        -e 's/;/:/g' \
        -e 's/|/;/g' \
        -e '/^ *Angezeigte Felder/d' \
        -e '/^ *Anzahl der selektierten/d' \
        $fnm > $nfn;
done

echo "Fertig."
