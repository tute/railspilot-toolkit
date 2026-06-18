#!/bin/bash
# SessionStart hook: stdout becomes session context.
# Always injected; whether the markers are spoken is gated by ~/.claude/toolkit/tts-on
# (see speak.sh). The marker is an HTML comment so it cannot break the markdown
# rendering of the response.

cat <<'EOF'
## Spoken summaries (TTS)
Add spoken-summary markers to your final response: HTML comments with the TTS
tag, the spoken text sandwiched on its own lines, like this:
<!--TTS
your spoken summary here
-->
- Short response: exactly one marker at the very end, 1-3 sentences.
- Long or structured response (multiple sections, code blocks, tables): one
  short marker after each major component, plus a brief closing one. They are
  all read aloud in order when the response finishes.
- Markers count only in the final response message: text emitted between tool
  calls is never spoken, so do not put markers there.
- Natural speech only: no filenames, paths, commands, code, markdown, or
  syntax. Distill the key point, not a recap of every detail.
- Never place a marker inside a code block or any other markdown structure.
EOF
