#!/bin/bash

if [ -z "$*" ]; then
	echo "Usage: $0 <file with a magnet link per line>"
	exit
fi

wanIp=$(dig +short myip.opendns.com @resolver1.opendns.com)
echo "Your ip is $wanIp"
sleep 1
for file in $*; do
	while read link; do 
		transmission-cli -f ~/bin/transmission-f.sh "$link"
	done < $file
done
