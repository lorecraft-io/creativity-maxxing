<a id="top"></a>

<div align="center">

![creativity-maxxing](https://raw.githubusercontent.com/lorecraft-io/creativity-maxxing/main/creativitymaxxing.png)

# creativity-maxxing

**Turn Claude Code + your terminal into a creative studio — 
design, video, audio, transcription in one install.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

</div>

---

## Quick Navigation

| Link | Section | What it does | Time |
|---|---|---|---|
| [What this is](#what-this-is) | Overview | TL;DR — what the install actually does | ~1 min |
| [Why this exists](#why-this-exists) | Context | Why AI ships ugly UI by default and how this fixes it | ~2 min |
| [Cheat sheet](./CHEAT-SHEET.md) | Reference | Every slash command / skill / MCP call you'll use | ~2 min |
| [Install](#install) | Setup | One-liner (curl) or clone + run | ~1 min |
| [Manual steps](#manual-steps-oauth--accounts) | Setup | The 2-3 tools that want an OAuth click or API key | ~1 min |
| [What gets installed](#what-gets-installed) | Reference | Table of every skill / MCP / binary | ~1 min |
| [How I use each piece](#how-i-actually-use-each-piece) | Context | The reason each tool is in the box | ~3 min |
| [Taste skills](#taste-skills) | Reference | 7 variants, 3 knobs, when to pick which | ~2 min |
| [Update](#update) | Maintenance | Pull the latest without reinstalling | — |
| [Uninstall](#uninstall) | Maintenance | Reverse everything, prompt before touching `ffmpeg` | — |
| [The maxxing series](#the-maxxing-series) | Meta | Sibling repos: cli-maxxing + task-maxxing | — |
| [License](#license) | Meta | MIT | — |

---

## What this is

`creativity-maxxing` is a single-install creative studio for Claude Code. You run one script and your terminal picks up:

- **Taste-enforcing design skills** that stop Claude from shipping the usual centered-hero + three-card-grid slop.
- **A natural-language component generator** (21st.dev Magic) that pulls from a pro library instead of hallucinating JSX.
- **Canva** wired into your terminal — design work, brand kits, exports, conversational edits.
- **Remotion** so Claude writes React-native video compositions instead of re-inventing timing code every time.
- **A full transcription stack** — drop any YouTube / Instagram / TikTok link and get the transcript back, locally, no API key.
- **Higgsfield / Seedance 2.0 prompt skills** — 15 video-style prompt engineers pre-wired for Claude.

It's built for Claude Code in the terminal, not the desktop app.

---

## Why this exists

AI is genuinely bad at design out of the box. Every model defaults to the same centered hero, same three cards, same Lucide icon trio, same gradient. That's what `taste` exists to block, and what `21st.dev Magic` + `UI/UX Pro Max` exist to replace with actual pro references — some free, some paid, all better than the default output.

The other half is the thing I could never make work before: I hate every online transcription tool. They paywall the good ones, the free ones mangle timestamps, and nothing lets me drop a link and walk away. So this install wires up `yt-dlp` + local Whisper so you paste *any* link — a YouTube video, an Instagram Reel, a TikTok, a random tweet with audio — and Claude transcribes it locally. No API key, no upload, no paywall.

Add Canva into the terminal and the whole loop gets weird in a good way: you can design conversationally. "Make me a launch banner, three variants, green-leaning, thin slab font" — and it just happens. No tab-switching, no mouse, no starting from a blank template.

There's more in here (Remotion for programmatic video, the Higgsfield/Seedance prompt pack for short-form, the full taste pack), but those three — the taste filter, the transcription pipeline, and Canva-in-terminal — are the unlocks.

> [!IMPORTANT]
> **A few of these need one extra step after the install finishes** — typically an OAuth click in your browser or pasting a free API key. The install script tells you exactly which ones and gives you the command / link. See [Manual steps](#manual-steps-oauth--accounts).

---

## Install

One-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lorecraft-io/creativity-maxxing/main/install.sh)
```

Or clone and run locally:

```bash
git clone https://github.com/lorecraft-io/creativity-maxxing.git
cd creativity-maxxing
bash install.sh
```

The installer runs `design/install.sh` then `media/install.sh` in order, refuses to start if `claude` or `~/.claude/skills/` is missing, and is idempotent — re-run any time without duplicating installs. Idempotency marker: `~/.claude/.creativity-maxxing-installed` (delete to force a full reinstall).

### Manual steps (OAuth / accounts)

A few of the tools need an extra click after the installer runs. The script prints these as it goes, but for reference:

| Tool | What you need to do |
|------|--------------------|
| **21st.dev Magic MCP** | Sign up free at [21st.dev](https://21st.dev), grab your API key, follow their MCP setup one-liner |
| **Canva MCP** | First time you call it, Claude opens a browser for Canva OAuth — allow, done |
| **Morgen / Notion / Motion** | Not in this repo — those live in `cli-maxxing` |

Everything else installs with zero accounts and zero keys.

---

## What gets installed

| Tool | Kind | What it does |
|------|------|--------------|
| UI/UX Pro Max | Claude skill | Design reference library: 67 styles, 96 palettes, 57 font pairings, 13 stacks |
| Taste Skill pack | Claude skill | 8 variants that block generic LLM UI output |
| 21st.dev Magic MCP | MCP server | Natural-language component generator |
| Canva MCP | MCP server | Canva designs / brand kits / exports from the terminal |
| Higgsfield / Seedance 2.0 | Claude skills (15) | Style-specific video prompt engineers (cinematic, anime, product 360°, etc.) |
| Remotion best-practices | Claude skill | React-based programmatic video |
| YouTube Transcript MCP | MCP server | Transcripts from any public YouTube video |
| yt-dlp MCP | MCP server | Pull audio/video from IG, TikTok, YT, and 1000+ sites |
| yt-dlp CLI | Homebrew | The binary behind yt-dlp MCP |
| whisper-cpp | Homebrew | Local Whisper inference — no API key, runs offline |
| whisper-mcp | MCP server | Claude-side interface to whisper-cpp |
| ffmpeg | Homebrew | Video/audio glue (shared — prompted before uninstall) |

All targets are **idempotent**: check-and-skip if the target already exists.

### Also worth flipping on — claude.ai connectors

These live on claude.ai's hosted side (Settings → Connectors), not in this install script. Enable them there and they show up automatically in any Claude session alongside everything above. No local config, no keys, just a toggle + OAuth:

| Tool | What it does |
|------|--------------|
| [**Figma**](https://claude.ai) | Read Figma files, inspect frames, export design tokens, and convert designs to code. Paste any figma.com URL into Claude and it just resolves. Pair with `taste-skill` + `21st.dev Magic` to go from a frame to a working component in one loop. |
| [**Excalidraw**](https://claude.ai) | Generate and edit Excalidraw diagrams conversationally. "Draw the architecture" → actual `.excalidraw` file. Great for system sketches, flowcharts, whiteboard sessions. |
| [**Gamma**](https://claude.ai) | Generate presentations, docs, and landing pages from a prompt. Pairs well with `UI/UX Pro Max` context — Claude already knows what "looks expensive" and Gamma renders it. |

To enable: open [claude.ai](https://claude.ai) → click your avatar → **Settings** → **Connectors** → find each one → **Connect**. One OAuth click per tool. No CLI touch needed.

---

## How I actually use each piece

### Design

- **UI/UX Pro Max** — the encyclopedia. I don't call it directly much — it sits in context so Claude knows "these 13 stacks exist, these 96 palettes exist, these 57 font pairings work together." Lets me say "make it feel like Linear" and get something that actually looks like Linear.
- **Taste skill pack** — the anti-slop filter. Before Claude ships UI, the taste skill checks whether it's about to emit centered-hero-plus-three-card-grid. If yes, it rewrites. Different variants = different registers (see [Taste skills](#taste-skills) below).
- **21st.dev Magic MCP** — natural-language component generator. "Build me a pricing card with three tiers, popular tier highlighted" — Magic pulls from their library and returns actual JSX. I use this instead of letting Claude make up components.
- **Canva MCP** — the sleeper. Conversational design inside the terminal. I ask for banners, thumbnails, brand kit variants, exports — no tab-switching, no mouse. It's the fastest way to make three versions of anything and keep the one that lands.

### Video + audio

- **Higgsfield / Seedance 2.0 skills** — 15 skills, each a specialized prompt engineer for a video style (cinematic, anime, product 360°, fight scenes, fashion lookbook, etc). I describe what I want, Claude hands back a paste-ready Seedance prompt with the 2-second hook, timeline, camera moves, and sound design already tuned.
- **Remotion** — the skill ships the Remotion team's best-practices doc so Claude writes idiomatic React video instead of reinventing timing every session.
- **YouTube Transcript MCP** — drop a YT link, get the transcript. No credential needed.
- **yt-dlp + Whisper stack** — this is the one I actually wanted most. Paste an IG Reel / TikTok / tweet link and Claude transcribes it locally using Whisper. No uploads, no paywall, no mangled timestamps. Works on anything `yt-dlp` can download (~1000 sites).
- **ffmpeg** — the glue. Remotion needs it for rendering, yt-dlp uses it for postprocessing, Whisper uses it for audio conversion.

---

## Taste skills

The Taste Skill pack (`Leonxlnx/taste-skill`) ships 8 opinionated variants plus 3 global knobs. One `skills add` command expands it into 8 separate skill directories under `~/.claude/skills/` — each one is callable as a slash command by its installed name.

**The variants:**

| Slash command | When to use it |
|---|---|
| `/design-taste-frontend` | Default premium frontend rules + 3-knob tuner. Safe everywhere. |
| `/redesign-existing-projects` | Retrofit an existing project — audits current CSS first. |
| `/high-end-visual-design` | Premium agency-grade soft UI, spring animations. |
| `/full-output-enforcement` | Spec → finished build. Bans placeholder stubs. |
| `/minimalist-ui` | Editorial / Linear-Notion / typographic. |
| `/industrial-brutalist-ui` | Raw, mechanical, Swiss + terminal. Dashboards. |
| `/stitch-design-taste` | Google-Stitch-aligned `DESIGN.md` generator. |
| `/gpt-taste` | GPT-leaning variant of the taste filter. |

**The 3 knobs** (edit `design-taste-frontend/SKILL.md` to tune, 1–10 scale):

- `DESIGN_VARIANCE` — 1-3 centered/clean · 8-10 asymmetric/modern
- `MOTION_INTENSITY` — 1-3 simple hover · 8-10 scroll-triggered
- `VISUAL_DENSITY` — 1-3 spacious/luxury · 8-10 dense dashboards

**Combos I actually use:**

- Premium SaaS landing → `/design-taste-frontend` + `/high-end-visual-design`
- Cleaning up an old project → `/redesign-existing-projects`
- Editorial blog → `/minimalist-ui`
- Dashboard or data tool → `/industrial-brutalist-ui`
- Figma export → React → `/full-output-enforcement` + `/stitch-design-taste`

---

## Update

Pull the latest without reinstalling from scratch:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lorecraft-io/creativity-maxxing/main/update.sh)
```

Every target is idempotent — anything already up-to-date is skipped.

---

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/lorecraft-io/creativity-maxxing/main/uninstall.sh)
```

Or, from a clone:

```bash
bash uninstall.sh
```

Removes, in reverse order: UI/UX Pro Max, all 8 taste variants, 21st.dev Magic MCP, Canva MCP, Higgsfield/Seedance skills, Remotion skills, YouTube Transcript MCP, yt-dlp MCP, yt-dlp CLI, whisper-cpp, whisper-mcp. **Prompts before touching `ffmpeg`** because ffmpeg is usually shared with non-creative tooling — answer `N` to keep it.

---

## The maxxing series

This is one of three repos in the stack:

| Repo | What it does |
|------|-------------|
| [`cli-maxxing`](https://github.com/lorecraft-io/cli-maxxing) | Foundation — Claude Code, shell aliases, dev tools, productivity MCPs (Morgen, Motion, n8n, Notion, Playwright, SwiftKit). |
| **`creativity-maxxing`** | **This repo** — design skills, video prompt engines, transcription lab, Canva in terminal. |
| [`task-maxxing`](https://github.com/lorecraft-io/task-maxxing) | Three-way task sync — Obsidian ↔ Notion ↔ Morgen (requires [`2ndBrain-mogging`](https://github.com/lorecraft-io/2ndBrain-mogging)). |

Install `cli-maxxing` first (it drops `claude` onto your `PATH`). After that, `creativity-maxxing` and `task-maxxing` can be installed in either order.

---

## Security

See [`SECURITY.md`](./SECURITY.md) — credential surface, supply-chain notes, and how to report installer vulnerabilities.

TL;DR: no secret ever goes into this repo, no install step downloads an unsigned binary over HTTP.

---

## License

MIT — see [`LICENSE`](./LICENSE).

[⤴ back to top](#top)
