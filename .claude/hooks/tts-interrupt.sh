#!/bin/bash
# Stops TTS speech at the next sentence boundary. Used by the UserPromptSubmit
# hook (typing interrupts speech) and by /tts-disable.
# Signals are blocked inside the hook sandbox, so this works cooperatively:
# speak.sh's speaker loop re-reads the token file between sentences and exits
# when it no longer holds its own token. Mid-sentence speech cannot be cut.

TTS_DIR="$HOME/.claude/toolkit"
mkdir -p "$TTS_DIR"
printf 'stop' > "$TTS_DIR/tts-token"
exit 0
