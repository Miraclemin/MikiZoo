# MikiZoo

[中文版](README.zh.md)

![MikiZoo](pic.png)

Tiny AI companions that live on your macOS screen. They walk, wander, think, and talk — powered by the AI CLI of your choice.

---

## What is MikiZoo?

MikiZoo places animated desktop characters on your Mac that you can click to open a terminal-style AI chat. While you work, they proactively notice what you're doing — switching apps, copying text, writing code — and offer to help without you having to ask.

---

## Features

### Animated Characters

- 2 built-in characters (**Miki** and **Jazz**) rendered from transparent HEVC video
- Add unlimited custom agents using any PNG, JPEG, or animated GIF
- Each character has its own accent color, persona, and independent settings
- Characters automatically get distinct colors from a curated palette

### Movement

- **Idle mode** — character stays in a fixed position on screen
- **Moving mode** — freeform wandering with realistic physics: smooth steering, random velocity changes every 5–10 seconds, natural acceleration and deceleration
- Boundary-aware: agents stay in the central 60% of the screen and bounce off edges
- Sibling collision avoidance: characters maintain spacing and don't overlap
- **Drag to reposition** — long-press any character to drag it anywhere; position is saved across restarts
- Per-character speed multiplier: 0.25× to 3.0×

### AI Chat Popover

- Click any character to open a floating terminal-style chat window
- Real-time streaming responses
- Full conversation history with role labels (user, assistant, tool use, tool results)
- Code block display in message history
- Persists across app restarts per character

### 4 Visual Themes

| Theme | Style |
|---|---|
| **Peach** | Warm, rounded, character-tinted accents |
| **Midnight** | Dark with orange accents, SF Mono fonts |
| **Cloud** | Light blue/gray, minimal, system fonts |
| **Moss** | Retro green, Chicago/Geneva fonts, 3px corners |

Peach theme automatically tints to match each character's accent color.

### 4 AI Providers

| Provider | Type | How it works |
|---|---|---|
| **Claude** | CLI subprocess | `~/.claude/local/bin/claude`, NDJSON streaming, system prompt injection |
| **Codex** | CLI subprocess | `codex exec --json --full-auto`, multi-turn context reconstruction |
| **Copilot** | CLI subprocess | GitHub Copilot CLI, `--continue` flag for multi-turn, JSON streaming |
| **OpenClaw** | HTTP gateway | SSE streaming, configurable base URL, agent ID, bearer token auth |

Switch providers from the menu bar at any time. All active sessions restart automatically.

### Smart Suggestions (Proactive AI)

MikiZoo watches what you're doing and proactively offers help — no API calls until you accept.

**Clipboard analysis** (triggers on copy):
- Long text or article → "Summarize?"
- Code snippet → "Explain this code?"
- English text (non-Chinese) → "Translate?"

**App context** (triggers after you've been in an app for a configurable duration):
| App Category | Suggestion |
|---|---|
| Xcode / Cursor / VS Code | Error detected? Need help? |
| Mail / Outlook / Spark | Draft a reply? |
| Notion / Obsidian / Bear | Structure your thoughts? |
| Keynote / PowerPoint / Canva | Optimize copy? |
| Terminal / iTerm / Warp | Command help? |
| Safari / Chrome / Firefox / Arc | Explain this? |

- Each app category can be toggled on/off independently
- Context timer: configurable delay (15s / 30s / 1m / 3m / 5m) before checking app context
- Suggestions appear as a bubble above a character; accept or dismiss with one click

### Thinking Bubbles

- Animated bubble appears above a character while AI is processing
- Rotating phrases during thinking, completion phrase when done
- Green completion bubble with audio ping on finish
- 9 distinct ping sounds, randomized with no immediate repeats, globally toggleable

### Per-Character Customization

- **Custom image**: Replace the video with any PNG, JPEG, or animated GIF
- **Mirror**: Flip the character horizontally
- **Persona**: Give each character a custom name and personality description (injected into AI system prompt)
- **Size & position**: Adjustable size and vertical offset, saved per character
- **Speed**: Independent speed multiplier per character

### Menu Bar

- Per-character submenus: visibility, moving mode, speed slider, custom image, persona
- Global: AI provider selection, theme selection, smart suggestion settings, sounds toggle
- Add Agent: file picker to add a new custom character
- OpenClaw config panel: URL, agent ID (fetched live from `/v1/models`), auth token

### Multi-Monitor Support

- Pin characters to a specific display
- Automatic dock detection (supports auto-hide, magnification)
- Characters hide automatically in fullscreen spaces

---

## Requirements

- macOS Sonoma (14.0+)
- At least one supported CLI installed:
  - [Claude Code](https://claude.ai/download) — `curl -fsSL https://claude.ai/install.sh | sh`
  - [OpenAI Codex](https://github.com/openai/codex) — `npm install -g @openai/codex`
  - [GitHub Copilot CLI](https://github.com/github/copilot-cli) — `brew install copilot-cli`
  - Or an OpenClaw-compatible HTTP gateway running locally

---

## Building

Open `Miki.xcodeproj` in Xcode and hit Run.

---

## Privacy

MikiZoo runs entirely on your Mac.

- **Local only.** No personal data, file paths, or usage analytics are collected or transmitted by the app.
- **AI conversations.** All chat is handled by the CLI subprocess or gateway you configure. MikiZoo does not intercept or store conversation content. Data sent to AI providers is governed by their respective privacy policies.
- **Accessibility.** Smart Suggestions use the macOS Accessibility API to read window titles and selected text on your local machine only. This data never leaves your device.
- **No accounts.** No login, no user database.
- **Updates.** MikiZoo uses Sparkle for auto-updates, which sends your app version and macOS version only.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

Originally based on [lil-agents](https://github.com/ryanstephen/lil-agents) by Ryan Stephen.
