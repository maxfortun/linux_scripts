#!/bin/bash
file=${1}

declare -a sitePrefix
declare -a siteSuffix

[ -f setenv.sh ] && . setenv.sh

if [ ${#sitePrefix[@]} = 0 ]; then
	echo "setenv.sh must set at least one sitePrefix." 
	echo "e.g. sitePrefix[0]='https://host:port/search/'"
	echo "e.g. siteSuffix[0]='/more/params'"
	echo "e.g. siteEnable[0]=true"
	echo "e.g. siteMagPrefix[0]=/magnets/"
	exit
fi

[ -f $file.new ] && rm $file.new
results="$HOME/tmp/$(basename $0).out"
cookies="$HOME/tmp/$(basename $0).cookies"
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

		echo "Checking if already exists $prefix $seq $suffix."
		if grep "$prefix.*$seq.*$suffix" $file.mags; then
			echo "$prefix $seq $suffix exists. Next seq is $nextSeq."
			seq=$nextSeq
			continue
		fi

		sitesEnabled=${#sitePrefix[@]}
		echo "Looking for $prefix $seq $suffix."
		for siteId in ${!sitePrefix[@]}; do
			if [ "${siteEnable[$siteId]}" = "false" ]; then
				sitesEnabled=$(( sitesEnabled - 1 ))
				continue
			fi

			url="${sitePrefix[$siteId]}$prefix%20$seq%20$suffix${siteSuffix[$siteId]}"
			urlDepth=0
			rc=0
			while [ -n "$url" ] && [ "$urlDepth" -lt "${siteUrlDepth[$siteId]}" ] ; do
				echo curl -s -f -S -b "$cookies" -c "$cookies" -o "$results" "$url"
				curl -s -f -S -b "$cookies" -c "$cookies" -o "$results" "$url"
				rc=$?
				lastUrl="$url"
				unset url
				urlDepth=$(( urlDepth + 1 ))
				
				if [ "$rc" != "0" ]; then
					echo "Disabling site #$siteId: Error($rc): $lastUrl" 
					siteMaxErrs[$siteId]=$(( ${siteMaxErrs[$siteId]} - 1  ))
					if [ "${siteMaxErrs[$siteId]}" -lt 1 ]; then
						siteEnable[$siteId]=false
					fi
					sitesEnabled=$(( sitesEnabled - 1 ))
					if [ "$sitesEnabled" -lt "1" ]; then
						echo "All sites offline."
						exit
					fi
					continue 2
				fi
	
				if grep -q recaptcha "$results"; then
					echo "reCAPTCHA encountered for $results"
					checkSeq=false
					continue
				fi

				# no need for cat
				magnet=$(grep -m1 -o 'magnet:[^"]*' "$results")
				if [ -z "$magnet" ]; then
					echo "No magnet in results. Looking for a link."
					url=$(grep -P -o -m1 -i "href=['\"][^'\"]*?${siteMagPrefix[$siteId]}[^'\"]*?$prefix.*?$seq.*?$suffix[^'\"]*?['\"]" "$results" | tr "\"" "'" | cut -d"'" -f2 )
					# if link relative get base from url and append the link
					if [[ "$url" =~ ^/ ]]; then
						baseUrl=$(echo "$lastUrl" | cut -d/ -f1-3)
						url="$baseUrl$url"
					fi
				fi
			done
			[ -n "$magnet" ] && break
		done

		if [ -n "$magnet" ]; then
			#echo "$magnet"
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
