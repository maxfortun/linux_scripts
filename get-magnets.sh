#!/bin/bash
file=${1}

while read name seq suffix; do
	checkSeq=true
	while [ "$checkSeq" = "true" ]; do
		if [[ "$seq" =~ ^S([0-9]{2})E([0-9]{2}) ]]; then
			S=${BASH_REMATCH[1]}
			E=${BASH_REMATCH[2]}
		fi

		E=${E##0}
		E=0$(( E + 1 ))
		L=${#E}
		L=$(( L - 2 ))
		E=${E:$L}
		nextSeq=S${S}E${E}

		if grep "$name.*$seq.*$suffix" $file.mags; then
			echo "$name $seq $suffix exists. Next seq is $nextSeq."
			seq=$nextSeq
			continue
		fi

		echo "Looking for $name $seq $suffix."
		url="https://www.thepiratebay.org/search/$name%20$seq%20$suffix/0/99/200" 
		#echo "$url"
		magnet=$(curl -s"$url" | grep -m1 -o 'magnet:[^"]*')
		if [ -n "$magnet" ]; then
			echo "$magnet"
			echo "$magnet" >> $file.mags
			echo "$name $seq $suffix found. Next seq is $nextSeq."
			seq=$nextSeq
		else
			echo "$name $seq $suffix not found."
			checkSeq=false
		fi

		echo "$name $seq $suffix" >> $file.new
	done
done < $file

mv $file $file.bak
mv $file.new $file
diff $file.bak $file

cat $file.mags

