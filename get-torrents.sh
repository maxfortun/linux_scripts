#!/bin/bash

if [ -z "$*" ]; then
	echo "Usage: $0 <file with a magnet link per line>"
	exit
fi

for file in $*; do
	while read link; do 
		transmission-cli -f ~/bin/transmission-f.sh "$link"
	done < $file
done
