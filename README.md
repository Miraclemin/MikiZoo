# MikiZoo

[中文版](README.zh.md)

![MikiZoo](pic.png)

A tiny AI companion that lives on your macOS desktop. It walks, wanders, thinks, and talks — powered by the AI of your choice.

---

## What is MikiZoo?

MikiZoo places an animated character called **Miki** on your Mac desktop. Click it to open a terminal-style AI chat. While you work, Miki quietly watches what you're doing — switching apps, copying text, writing code — and proactively offers help without being asked.

You can also upload your own PNG or GIF to create fully custom AI agents.

---

## Features

### Characters

- Built-in character **Miki**, rendered from a transparent HEVC video for smooth, natural animation
- Add unlimited custom agents: upload any PNG, JPEG, or animated GIF to create a new one
  - Example: upload a cat GIF and you have an animated cat AI assistant
- Each agent has its own accent color, persona, and independent chat history
- New agents are automatically assigned a distinct color from a curated palette

### Movement & Wandering

- **Idle mode** — Miki stays in a fixed spot on screen, quietly present
- **Moving mode** — Miki roams freely with realistic physics:
  - Smooth steering with random direction and speed changes every 5–10 seconds
  - Natural acceleration and deceleration — no teleporting
  - Stays within the central 60% of the screen, bouncing off boundaries
  - Multiple agents maintain spacing and never overlap
- **Drag to reposition** — long-press any character for 1 second to enter drag mode; position saves across restarts
- Per-character speed multiplier: 0.25× (slow stroll) to 3.0× (sprint)

### AI Chat

- Click any character to open a floating terminal-style chat window
- Real-time streaming output with typewriter effect
- Full conversation history labeled by role: user, assistant, tool use, tool results
- Code block display in responses
- Each character's chat history is independent and persists across restarts

### 4 AI Providers

| Provider | Details |
|---|---|
| **Claude** | Claude Code CLI, NDJSON streaming, custom system prompt injection |
| **Codex** | OpenAI Codex CLI, full-auto execution, multi-turn context reconstruction |
| **Copilot** | GitHub Copilot CLI, `--continue` flag for multi-turn sessions |
| **OpenClaw** | Local HTTP gateway, SSE streaming, configurable URL / Agent ID / Token |

Switch providers from the menu bar at any time — all sessions restart automatically.

### Proactive Smart Suggestions

Miki notices what you're doing and offers help at the right moment. **Zero API calls until you accept** — no quota consumed just from watching.

**Clipboard-aware:**
- Copy a long article → Miki bubbles up: "Summarize this?"
- Copy a code snippet → "Explain this code?"
- Copy English text → "Translate this?"

**App-aware:**
| App you switch to | Miki asks |
|---|---|
| Xcode / Cursor / VS Code | "Hit an error? Need help?" |
| Mail / Outlook / Spark | "Draft a reply?" |
| Notion / Obsidian / Bear | "Help structure your thoughts?" |
| Keynote / PowerPoint / Canva | "Want to polish the copy?" |
| Terminal / iTerm / Warp | "Need a command?" |
| Safari / Chrome / Firefox / Arc | "Want me to explain this?" |

- Each app category toggles on/off independently
- Configurable trigger delay: 15s / 30s / 1m / 3m / 5m (to avoid interrupting flow)
- Suggestions appear as a bubble above Miki; accept to run, dismiss to ignore

### Thinking Bubbles & Audio Feedback

- While AI is processing: a thinking bubble appears with rotating phrases, swapping every few seconds
- When done: switches to a completion phrase with a green bubble
- 9 distinct ping sounds play on completion, randomized with no immediate repeats
- Sounds can be toggled off globally
- No need to watch the screen — just listen for the ping

### Per-Character Customization

- **Custom image**: replace the default character with any PNG, JPEG, or GIF — your avatar, a pet, anything
- **Mirror**: flip the character to face left instead of right
- **Persona**: set a name and personality description per character, injected into the AI system prompt
  - Example: name "Miki", personality "blunt and sarcastic but helpful, speaks casually" — the AI will respond in that voice
- **Size & position**: adjustable size and vertical offset, saved per character
- **Speed**: independent speed multiplier per character

### Multi-Monitor Support

- Pin characters to a specific display
- Automatic dock detection (supports auto-hide and magnification)
- Characters hide automatically in fullscreen spaces and reappear when you exit

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

- **Local only.** No personal data, file paths, or usage analytics are collected or transmitted.
- **AI conversations.** All chat is handled by the CLI subprocess or gateway you configure. MikiZoo does not intercept or store conversation content.
- **Accessibility.** Smart Suggestions use the macOS Accessibility API to read window titles and selected text locally. This data never leaves your device.
- **No accounts.** No login, no user database.
- **Updates.** MikiZoo uses Sparkle for auto-updates, sending only your app version and macOS version.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

Originally based on [lil-agents](https://github.com/ryanstephen/lil-agents) by Ryan Stephen.
