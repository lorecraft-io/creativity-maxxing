# creativity-maxxing

The **creative half** of cli-maxxing. Everything you need to turn Claude
Code into a design studio and a video lab: taste-enforcing UI skills, a
component generator, Remotion for programmatic video, and a full
transcription pipeline for audio and social-media clips.

If cli-maxxing is the terminal, creativity-maxxing is the canvas.

> **Prereq: cli-maxxing** — install [`cli-maxxing`](https://github.com/lorecraft-io/cli-maxxing) first.
>
> **Requires `cli-maxxing`
> installed first.** This repo assumes `claude` is on your `PATH` and
> `~/.claude/skills/` already exists. Run the cli-maxxing installer
> before this one.

---

## Install

One-liner:

```bash
curl -fsSL https://github.com/lorecraft-io/creativity-maxxing/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/lorecraft-io/creativity-maxxing.git
cd creativity-maxxing
bash install.sh
```

The installer runs `step-4` then `step-5` in order, refuses to start if
`claude` or `~/.claude/skills/` is missing, and is idempotent — re-run it
any time without duplicating installs.

---

## What gets installed

| Tool | Kind | What it does |
|------|------|--------------|
| UI/UX Pro Max | Claude skill | Design intelligence: 67 styles, 96 palettes, 57 font pairings, 13 stacks |
| Taste Skill pack (7 variants) | Claude skill | Anti-slop design enforcement — see deep-dive below |
| 21st.dev Magic MCP | MCP server | Component generator: inspiration, build, refine, logo search |
| Remotion best-practices | Claude skill | React-based programmatic video |
| YouTube Transcript MCP | MCP server | Free transcript extraction from public YT videos |
| yt-dlp MCP | MCP server | Download audio/video from IG, TikTok, YT, and 1000+ sites |
| yt-dlp CLI | Homebrew | Underlying binary for yt-dlp MCP |
| whisper-cpp | Homebrew | Local Whisper inference — no API key, runs offline |
| whisper-mcp | MCP server | Claude-side interface to whisper-cpp |
| ffmpeg | Homebrew | Video/audio processing glue (shared — prompted before uninstall) |

All install targets are **idempotent**: each check-and-skip if the
target already exists.

---

## Taste Skill deep-dive (the marquee feature)

The Taste Skill pack (Leonxlnx/taste-skill) is the reason this repo
exists as its own install. It ships **7 opinionated variants** that each
enforce a different visual register, plus **3 global knobs** that steer
how strict each variant behaves. One `skills add` command expands the
pack into 7 separate skill directories under `~/.claude/skills/`.

### The 7 variants

1. **taste** — the default. A general-purpose anti-generic filter that
   blocks the usual LLM UI defaults (centered hero + three-column card
   grid + Lucide icon trio + "Get Started" button).
2. **redesign** — applied to *existing* projects. Audits current CSS,
   flags generic AI patterns, and retrofits premium patterns without
   breaking layout or functionality.
3. **soft** — rounded, approachable, pastel-adjacent. Good for wellness,
   consumer, lifestyle, content-creator-facing UIs.
4. **output** — takes a spec and produces a finished, unabridged build.
   Pairs with the full-output-enforcement protocol; bans placeholder
   patterns and stub components.
5. **minimalist** — warm monochrome palette, typographic contrast, flat
   bento grids, muted pastels. No gradients, no heavy shadows.
6. **brutalist** — industrial / raw mechanical. Fuses Swiss typographic
   print with military terminal aesthetics. Rigid grids, extreme type
   scale contrast, analog degradation effects.
7. **stitch** — Google-Stitch-aligned. Generates `DESIGN.md` files that
   enforce premium anti-generic UI: strict typography, calibrated color,
   asymmetric layouts, perpetual micro-motion, hardware-accelerated
   performance.

Each variant is a full skill directory, so `claude` auto-loads them on
session start and you can call them by name.

### The 3 knobs

Every variant exposes the same three global knobs. Tuning them changes
how aggressively the skill rewrites your work.

1. **Strictness** — how hard the skill blocks "default LLM" patterns.
   Low = suggest. High = refuse to emit the pattern at all.
2. **Surface area** — how much of the file the skill is allowed to
   touch. Narrow = only the component you pointed at. Wide = the whole
   page, including siblings and imports.
3. **Reference weight** — how strongly the skill pulls from its own
   reference library (color palettes, font pairings, layout templates)
   vs. letting the underlying model improvise. Zero = pure model. Max =
   near-template output.

The pack's README documents the exact knob values each variant defaults
to. Override them per-session by setting the variant's config file or
passing flags through the skill invocation.

### Typical combos

- **Premium SaaS landing page** → `taste` + `high-end-visual-design`
- **Existing project cleanup** → `redesign`
- **Editorial blog** → `minimalist`
- **Dashboard / data tool** → `brutalist`
- **Spec-driven build from a Figma export** → `output` + `stitch`

---

## The rest of the install at a glance

### Design skills
- **UI/UX Pro Max** — the encyclopedia. When Taste Skill tells Claude
  what *not* to do, UI/UX Pro Max tells it what is *available*: 13
  stacks, 67 styles, 96 palettes, 57 font pairings, 25 chart types.

### Component generation
- **21st.dev Magic MCP** — component generator driven by natural
  language. Inspiration mode ("show me X"), build mode ("make this a
  working React component"), refine mode ("same component, dark mode,
  accessible"). Requires a 21st.dev account + API key — see
  [`SECURITY.md`](./SECURITY.md).

### Video + audio
- **Remotion** — compose videos in React. The skill ships the Remotion
  team's best-practices doc so Claude writes idiomatic compositions
  instead of re-inventing timing logic.
- **YouTube Transcript MCP** — pull transcripts from any public YT
  video. No credential needed.
- **yt-dlp MCP + CLI** — pull audio, video, metadata, and comments
  from IG, TikTok, YT, X, and ~1000 other sites. Used alongside
  whisper-cpp to transcribe Instagram Reels locally.
- **whisper-cpp + whisper-mcp** — local Whisper inference. No network,
  no API key, no audio ever leaves the machine.
- **ffmpeg** — the glue. Required by Remotion for rendering, by yt-dlp
  for postprocessing, and by whisper-cpp for audio conversion.

---

## Uninstall

```bash
curl -fsSL https://github.com/lorecraft-io/creativity-maxxing/uninstall.sh | bash
```

Or, from a clone:

```bash
bash uninstall.sh
```

The uninstaller removes, in reverse order: UI/UX Pro Max, all 7 Taste
Skill variants, 21st.dev Magic MCP, Remotion skills, YouTube Transcript
MCP, yt-dlp MCP, yt-dlp CLI, whisper-cpp, whisper-mcp. It **prompts
before touching `ffmpeg`** because ffmpeg is frequently shared with
non-creative tooling — answer `N` to keep it.

---

## Companion repos

- [`cli-maxxing`](https://github.com/lorecraft-io/cli-maxxing) — the
  terminal half. Required before this installer will run. See its
  "Companion Repos" section for the full constellation.

---

## Security

See [`SECURITY.md`](./SECURITY.md) for the full credential surface —
Magic MCP API key, 21st.dev account, optional Whisper/OpenAI keys,
yt-dlp cookie jars, and the reporting process for installer-script
vulnerabilities.

TL;DR: no secret ever goes in this repo, and no install function ever
downloads an unsigned binary over HTTP.

---

## License

MIT. See [`LICENSE`](./LICENSE).
