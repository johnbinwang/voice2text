# Voice2Text

[English](./README.md) | [简体中文](./README.zh-CN.md)

A macOS 14+ menu-bar voice input app built with Swift and Swift Package Manager.

Voice2Text lets you hold a hotkey to record, release to transcribe, and automatically inject the recognized text into the currently focused input field. It is designed for fast dictation, Chinese-first usage, and mixed-language speech input.

## Features

- Menu-bar only app (`LSUIElement`) with no Dock icon
- Hold-to-talk voice input workflow
  - Built-in keyboard: `Fn`
  - External keyboard fallback: `Alt / Option`
- Streaming speech recognition using Apple Speech framework
- Elegant bottom-center floating HUD with live waveform and transcript preview
- Chinese-first out-of-the-box (`zh-CN` by default)
- Language switching in menu bar
  - English
  - Simplified Chinese
  - Traditional Chinese
  - Japanese
  - Korean
- Clipboard-based safe text injection with input-source switching for CJK IMEs
- Optional LLM refinement via OpenAI-compatible API
- File-based transcription history persistence (`jsonl`)
- Generated macOS app icon and signed `.app` bundle packaging

## Requirements

- macOS 14+
- Xcode Command Line Tools
- Microphone permission
- Speech Recognition permission
- Accessibility permission

## Build and Run

### Build release app bundle

```bash
make build
```

Outputs:

```bash
dist/Voice2Text.app
```

### Run existing app bundle

```bash
make run
```

`make run` opens the existing packaged app without rebuilding or re-signing it every time. This helps keep macOS permissions more stable during testing.

### Rebuild explicitly

```bash
make rebuild
```

### Install to Applications

```bash
make install
open /Applications/Voice2Text.app
```

## First Launch Permissions

On first launch, macOS may ask for:

- Microphone access
- Speech Recognition
- Accessibility

### Recommended first-launch flow

1. Install and open the app:

```bash
make install
open /Applications/Voice2Text.app
```

2. Grant all requested permissions.
3. If Accessibility must be added manually in System Settings, add `Voice2Text.app` there.
4. Wait a moment for the app to detect the updated permission state.

## Hotkeys

- Built-in Mac keyboard: hold `Fn`
- External keyboard: hold `Alt / Option`

Release the key to stop recording and inject text into the focused input.

## LLM Refinement

The menu bar includes an `LLM Refinement` submenu.

You can configure:

- API Base URL
- API Key
- Model

The LLM prompt is intentionally conservative:

- only fixes obvious recognition mistakes
- does not rewrite or polish valid text
- preserves correct text exactly as-is

## Transcription History

Voice2Text stores transcription history as JSON Lines.

Path:

```bash
~/Library/Application Support/Voice2Text/transcriptions.jsonl
```

Each line contains:

- `id`
- `timestamp`
- `text`

Currently stored history is:

- original transcription text
- timestamp

## Project Structure

```text
Sources/Voice2TextApp/
├── AppDelegate.swift
├── main.swift
├── Audio/
├── History/
├── Hotkey/
├── HUD/
├── Input/
├── LLM/
├── MenuBar/
├── Settings/
├── Speech/
└── Support/
```

## Notes

- This project currently uses ad-hoc signing for local builds:

```bash
codesign --deep --force --sign - dist/Voice2Text.app
```

- For long-term stable permission behavior, prefer launching the installed app from `/Applications`.

## License

MIT
