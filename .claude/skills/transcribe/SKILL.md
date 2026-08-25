---
name: transcribe
description: Transcribe an audio file to text locally using whisper.cpp (no API, no cost). Use when asked to "transcribe" audio, a voice note, a WhatsApp/Telegram audio, or any .opus/.mp3/.m4a/.wav/.ogg/.webm file. Defaults to the most recent audio in ~/Downloads when no path is given.
---

# Transcribe

Transcribe audio to text locally with whisper.cpp. Runs entirely offline after
the model is downloaded: no API key, no per-minute cost.

## Requirements

The binary is `whisper-cli`, plus `ffmpeg`. Check with `which whisper-cli ffmpeg`.

On macOS: `brew install whisper-cpp ffmpeg`.

On Arch/Omarchy: do not use `pacman -S whisper-cpp`. It pulls `ggml`, which is
1.38 GB installed, and the Omarchy stable mirror snapshot has 404'd on that
package. Build a static CPU-only binary instead, no sudo needed:

bash
git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git "$SCRATCH/whisper.cpp"
cd "$SCRATCH/whisper.cpp"
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
  -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON
cmake --build build -j"$(nproc)" --target whisper-cli
install -Dm755 build/bin/whisper-cli ~/.local/bin/whisper-cli

`BUILD_SHARED_LIBS=OFF` matters: a shared build leaves whisper-cli linked
against libwhisper/libggml in the build directory, so it breaks once the
scratchpad is gone.

Model: ~/.cache/whisper-models/ggml-medium.bin (1.5 GB). If it is not there:

bash
mkdir -p ~/.cache/whisper-models && curl -L -o ~/.cache/whisper-models/ggml-medium.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin


Use ggml-large-v3-turbo.bin for better accuracy on long or noisy audio,
ggml-small.bin when speed matters more than accuracy.

## Steps

1. Resolve the target file(s):
   - If the user gave a path, use it.
   - Otherwise list recent audio in ~/Downloads. Avoid brace globs, zsh errors
     out on a pattern with no matches:
     bash
     cd ~/Downloads && /bin/ls -t | grep -iE '\.(opus|mp3|m4a|wav|ogg|oga|webm|mp4|mpeg|mpga|flac|aac|amr)$' | head -10

   - If the user says "the audios" (plural), transcribe all the recent ones.
     If the set is ambiguous, ask which.

2. Check duration first, to set a sensible timeout. The medium model runs
   roughly 3-5x faster than realtime on an M3, and about the same on 16 CPU
   threads (`-t 16`):
   bash
   ffprobe -v error -show_entries format=duration -of csv=p=0 "<file>"


3. Convert to 16 kHz mono WAV. whisper-cli only accepts WAV, and this handles
   .opus too:
   bash
   ffmpeg -nostdin -v error -y -i "<file>" -ar 16000 -ac 1 -c:a pcm_s16le "$SCRATCH/clip.wav"


4. Transcribe. -nt drops timestamps, -np drops the progress bar, -l auto
   detects the language:
   bash
   whisper-cli -m ~/.cache/whisper-models/ggml-medium.bin -f "$SCRATCH/clip.wav" \
     -l auto -nt -np 2>/dev/null

   Pass -l es (or another code) only if the user names a language.
   Backend init lines go to stderr, so 2>/dev/null leaves just the transcript.

5. Print the transcript to the user, labeled per file when there are several.
   Delete the temp WAVs.

## Notes

- Write temp WAVs to the session scratchpad, not ~/Downloads.
- -otxt / -osrt / -ovtt write output files next to the input when the user
  wants a saved transcript or subtitles.
- For a long file, run in the background and report when it finishes rather than
  blocking on a foreground timeout.
- Transcripts of personal voice notes are private: print them for the user,
  don't send them anywhere.
