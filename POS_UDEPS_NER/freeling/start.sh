#!/bin/sh
export FREELINGSHARE=/usr/share/freeling
analyzer -f /usr/share/freeling/config/${FREELING_LANGUAGE}.cfg --output xml --server --port $FREELING_PORT &
puma --port $SERVER_PORT
