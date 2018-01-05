#!/bin/bash
file=${1}

while read name seq suffix; do
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
	url="https://www.thepiratebay.org/search/$name%20$seq%20$suffix/0/99/200" 
	echo "$url"
	magnet=$(curl "$url" | grep -m1 -o 'magnet:[^"]*')
	if [ -n "$magnet" ]; then
		echo "$magnet"
		echo "$magnet" >> $file.mags
	fi

done < $file

cat $file.mags

