#!/bin/bash
file=${1}

declare -a sitePrefix
declare -a siteSuffix

[ -f setenv.sh ] && . setenv.sh

if [ ${#sitePrefix[@]} = 0 ]; then
	echo "setenv.sh must set at least one sitePrefix." 
	echo "e.g. sitePrefix[0]='https://www.thepiratebay.org/search/'"
	echo "e.g. siteSuffix[0]='/0/99/200'"
	exit
fi

[ -f $file.new ] && rm $file.new
results="$HOME/tmp/$(basename $0).out"
while read prefix startSeq suffix; do
	seq=$startSeq
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

		if grep "$prefix.*$seq.*$suffix" $file.mags; then
			echo "$prefix $seq $suffix exists. Next seq is $nextSeq."
			seq=$nextSeq
			continue
		fi

		echo "Looking for $prefix $seq $suffix."
		for siteId in ${!sitePrefix[@]}; do
			if [ "${siteEnable[$siteId]}" = "false" ]; then
				continue
			fi

			url="${sitePrefix[$siteId]}$prefix%20$seq%20$suffix${siteSuffix[$siteId]}"
			rc=0
			while [ -n "$url" ]; do
				echo "$url"
				curl -s -f -S -o "$results" "$url"
				rc=$?
				lastUrl="$url"
				unset url
				if [ "$rc" != "0" ]; then
					echo "Disabling site #$siteId: Error($rc): $lastUrl" 
					siteEnable[$siteId]=false
					continue 2
				fi
	
				if grep -q recaptcha "$results"; then
					echo "reCAPTCHA encountered for $results"
					continue
				fi

				# no need for cat
				magnet=$(cat "$results" | grep -m1 -o 'magnet:[^"]*')
				if [ -z "$magnet" ]; then
					echo "No magnet in results. Looking for a link."
					grep -m1 "$prefix.*$seq.*$suffix" "$results"
					# if link found set url
				fi
			done
		done
		
		if [ -n "$magnet" ]; then
			echo "$magnet"
			echo "$magnet" >> $file.mags
			echo "$prefix $seq $suffix found. Next seq is $nextSeq."
			seq=$nextSeq
		elif [[ "$startSeq" =~ ^S$S ]]; then
			echo "$prefix $seq $suffix not found."
			lastSeq=$seq
			S=0$(( S + 1 ))
			L=${#S}
			L=$(( L - 2 ))
			S=${S:$L}
			seq=S${S}E01
		else
			echo "$prefix $seq $suffix not found. Will try $lastSeq next time."
			echo "$prefix $lastSeq $suffix" >> $file.new
			checkSeq=false
		fi

	done
done < $file

mv $file $file.bak
mv $file.new $file
diff $file.bak $file

cat $file.mags

[ -f "$results" ] && rm "$results"
