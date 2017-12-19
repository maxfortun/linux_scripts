#!/bin/bash
file=${1}

while read name seq; do
	if [[ "$seq" =~ ^S([0-9]{2})E([0-9]{2}) ]]; then
		S=${BASH_REMATCH[1]}
		E=${BASH_REMATCH[2]}
	fi
	while ls *$name*$seq* ; do
		E=${E##0}
		E=0$(( E + 1 ))
		L=${#E}
		L=$(( L - 2 ))
		E=${E:$L}
		seq=S${S}E${E}
	done

	if grep $name$seq $file.mags; then
		continue
	fi
	curl "https://www.thepiratebay.org/search/$$name$seq/0/99/200" | grep -m1 -o 'magnet:[^"]*' >> $file.mags

done < $file
