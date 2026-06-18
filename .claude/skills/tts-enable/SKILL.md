---
name: tts-enable
description: "Turn on TTS. Use when the user says tts on, enable tts, turn on voice, start speaking, or read responses aloud."
---

# Enable TTS

1. Run:
   ```bash
   mkdir -p ~/.claude/toolkit && touch ~/.claude/toolkit/tts-on
   ```
2. Confirm with a TTS marker so the user gets immediate audible feedback:
   ```
   <!--TTS
   Text to speech is now on.
   -->
   ```
