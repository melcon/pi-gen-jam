#!/bin/bash

export JACK_NO_AUDIO_RESERVATION=1

# Only start Jamulus in the VNC virtual desktop
if [ "$DISPLAY" != ":1" ]; then
  exit 0
fi

sleep 5

for i in $(seq 1 20); do
  if jack_lsp >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

exec /usr/bin/jamulus