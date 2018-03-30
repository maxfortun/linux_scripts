#!/bin/bash

if [ -z "$*" ]; then
	echo "Usage: $0 <file with a magnet link per line>"
	exit
fi

wanIp=$(dig +short myip.opendns.com @resolver1.opendns.com)
if [ -z "$wanIp" ]; then
	echo "Failed to identify wan ip."
	exit
fi

echo "Your ip is $wanIp"

if [ -f ~/.hideIps ]; then
	if grep $wanIp ~/.hideIps; then
		echo "$wanIp is not hidden. Not proceeding."
		exit
	fi
else
	sleep 1
fi

for file in $*; do
	rm $file.done
	while read link; do 
		transmission-cli -f ~/bin/transmission-f.sh "$link"
		rc="$?"
		echo "exit code: $rc"
	done < $file
	diff --unchanged-line-format= --old-line-format='%L' --new-line-format= $file $file.done > $file.left
	mv $file.left $file
done
