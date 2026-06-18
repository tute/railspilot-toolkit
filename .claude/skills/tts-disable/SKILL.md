---
name: tts-disable
description: "Turn off TTS. Use when the user says tts off, disable tts, turn off voice, stop speaking, mute, or shut up."
---

# Disable TTS

1. Run:
   ```bash
   rm -f ~/.claude/toolkit/tts-on; printf 'stop' > ~/.claude/toolkit/tts-token
   ```
   The second command interrupts any in-progress speech at the next sentence boundary.
2. Confirm in text only. No TTS marker.
3. Tell the user that markers will still appear in responses until the session is restarted.
