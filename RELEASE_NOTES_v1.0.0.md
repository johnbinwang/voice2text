# Release v1.0.0

## Summary

Voice2Text v1.0.0 is the first stable release of the macOS menu-bar voice input app.

It provides a Chinese-first hold-to-talk voice input workflow with Apple Speech transcription, safe text injection, optional LLM refinement, and file-based transcription history.

## Highlights

- Menu-bar only macOS app (`LSUIElement`)
- Built-in keyboard support via `Fn`
- External keyboard fallback via `Alt / Option`
- Bottom-center floating HUD with live waveform and transcript preview
- Streaming speech recognition using Apple Speech framework
- Safe clipboard-based text injection with CJK input-source handling
- Optional OpenAI-compatible LLM refinement
- Transcription history saved to JSONL
- File-based debug logging mode for diagnostics

## Stability improvements included in v1.0.0

- Fixed repeated hotkey lifecycle issues after the first transcription
- Improved first-launch permission activation flow
- Hardened accessibility permission handling for menu-bar app behavior
- Stabilized recording session boundaries and processing lifecycle
- Added debug log mode for future investigation without relying on terminal output

## Build and install

```bash
make rebuild
make install
open /Applications/Voice2Text.app
```

## Debug mode

```bash
make run-debug
```

Debug log file:

```bash
~/Library/Application Support/Voice2Text/debug.log
```
