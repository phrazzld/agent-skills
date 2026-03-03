# Voiceover (ElevenLabs)

Generate high-quality voiceover audio with word-level timestamps for video sync.

## What This Does
- Accept script text or file path
- Preprocess for TTS: expand acronyms, normalize numbers
- Generate via ElevenLabs API
- Return audio + optional word timestamps

## Prerequisites
- `ELEVENLABS_API_KEY` env var set
- ElevenLabs Creator plan ~$5/mo for ~100k chars

## Usage
```
/ai-media voiceover "Welcome to Heartbeat..."
/ai-media voiceover demo-script.md --timestamps --voice adam
```

## Voices
Default: `adam` (clear, professional).

## Output
- `voiceover.mp3`
- `timestamps.json` (word-level timing when requested)

## Integration
Used by demo video pipeline for narration sync.
