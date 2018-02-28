#!/bin/bash

GPID=$(ps -o ppid= -p $PPID)
file=$TR_TORRENT_DIR/$(ps -o cmd= -p $GPID | awk '{ print $3 }')
echo "File: '$file'"
ps -f -p $PPID| grep -o 'magnet:.*' >> $file.done
kill $PPID
