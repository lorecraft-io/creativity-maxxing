<a id="top"></a>

# creativity-maxxing — Cheat Sheet

Every slash command, skill invocation, and MCP call you'll actually use after installing this repo. Organized by what you're trying to get done.

[← back to README](./README.md)

---

## Design

### Taste skills (block generic LLM UI)

Taste skills are auto-loaded when Claude Code starts. Invoke by name:

```
/design-taste-frontend       # default premium frontend rules (3 knobs)
/redesign-existing-projects  # audit + retrofit an existing project
/high-end-visual-design      # premium soft UI, spring animations
/full-output-enforcement     # spec → finished build, no stubs
/minimalist-ui               # editorial / Linear-Notion / typographic
/industrial-brutalist-ui     # raw mechanical / dashboards / terminal feel
/stitch-design-taste         # Google-Stitch-aligned DESIGN.md generator
/gpt-taste                   # GPT-leaning variant
```

Tune the knobs per-session by telling Claude:

```
"Use design-taste-frontend with DESIGN_VARIANCE=8, MOTION_INTENSITY=4, VISUAL_DENSITY=3"
```

### UI/UX Pro Max

Natural-language. The skill is always loaded — just reference it:

```
"Using UI/UX Pro Max, pick a palette for a fintech SaaS — cool, trust-first."
"Show me a font pairing that works for editorial long-form."
"Which of your 13 stacks is best for a real-time dashboard?"
```

### 21st.dev Magic MCP

Natural-language component generation:

```
"Magic, inspire me with a pricing card that breaks the usual three-tier pattern."
"Magic, build me a search bar with command-palette behavior."
"Magic, refine this in dark mode and make it keyboard-accessible."
"Magic, find me a logo for 'Harbor' — nautical, minimal."
```

### Canva MCP

Conversational design inside the terminal. OAuth once, then just ask:

```
"List my Canva designs."
"Create a 3-variant banner for creativity-maxxing — green-dominant, bold slab font."
"Export design <id> as PNG at 1920×1080."
"Search my brand kits for Lorecraft colors."
"Generate a presentation outline about transcription pipelines."
"Import this screenshot as a new Canva design: <url>"
```

### Figma MCP

Paste any Figma URL and read files, inspect frames, export tokens, convert to code. OAuth once.

```
"Read this Figma file: https://www.figma.com/design/XXXX/..."
"Get the design context for node <node-id> in file <file-key>."
"Export the design tokens from this Figma file."
"Convert this Figma frame to React + Tailwind."
"Search the design system for 'button' components."
```

### Excalidraw MCP

Generate and save Excalidraw diagrams conversationally. OAuth once.

```
"Draw the architecture of a three-tier web app as an Excalidraw diagram."
"Export this diagram to .excalidraw format."
"Add a new node to my saved diagram checkpoint."
```

### Gamma MCP

Generate presentations, docs, and landing pages from a prompt.

> **Opt-in.** The default install skips Gamma because it fails to connect without an API key. To enable: re-run the installer with `--with-gamma` and grab a key from [gamma.app/api](https://gamma.app/api).
>
> ```bash
> bash install.sh --with-gamma
> ```

```
"Generate a presentation about the creativity-maxxing install stack."
"Create a one-page doc summarizing our transcription pipeline."
"List my Gamma folders."
"What themes are available in Gamma?"
```

### Playwright MCP

Microsoft's browser automation MCP. Let Claude log into and operate any web app that has no API — Higgsfield, niche SaaS tools, anything you'd normally click through. No credentials needed. First run downloads Chromium automatically.

```
"Log into Higgsfield and generate a video for me."
"Open this URL, fill in the form, and tell me what the response says."
"Take a screenshot of the dashboard after logging in."
```

---

## Video prompts (Higgsfield / Seedance 2.0)

15 skills, one per style. Each one turns Claude into a prompt engineer for Seedance 2.0 — paste the output into [higgsfield.ai/create/video](https://higgsfield.ai/create/video?model=seedance_2_0).

```
/01-cinematic          # film-style cinematic
/02-3d-cgi             # 3D CGI / rendered
/03-cartoon            # cartoon / animation
/04-comic-to-video     # comics / manga / webtoons
/05-fight-scenes       # action / fight choreography
/06-motion-design-ad   # motion design for software / tech ads
/07-ecommerce-ad       # product ads
/08-anime-action       # anime style
/09-product-360        # 360° turntables
/10-music-video        # beat-synced / music video
/11-social-hook        # viral TikTok / Reels / Shorts hooks
/12-brand-story        # brand storytelling / narrative
/13-fashion-lookbook   # fashion lookbooks / model showcase
/14-food-beverage      # food + beverage
/15-real-estate        # real estate / architecture / interior
```

Typical flow:

```
/11-social-hook
"Make me a 10s Reels hook for a coffee-shop grand opening — hand lifting
a latte, thick cream pour, green + cream palette, bass drop at 2s."
```

Claude hands back a 15-line, paste-ready Seedance prompt with hook framing, timeline, camera moves, lighting, sound design, and platform optimization.

---

## Programmatic video (Remotion)

The skill is always loaded — talk to Claude naturally:

```
"Start a new Remotion project called launch-reel."
"Add a composition for a 30s vertical social spot at 1080×1920, 30fps."
"Render the 'hero' composition to MP4 at 60fps."
```

Remotion best-practices come along automatically — Claude writes idiomatic timing / interpolation / spring code instead of reinventing it.

---

## Transcription

### YouTube

```
"Pull the transcript for https://youtube.com/watch?v=XXXX"
"Transcribe this video, then summarize the 5 strongest arguments."
```

Zero credentials needed — works on any public video.

### Instagram / TikTok / anything yt-dlp supports

```
"Transcribe this IG Reel: https://www.instagram.com/reel/XXXX"
"Download the audio from this TikTok and transcribe it locally."
"Grab every post from @someone in the last 30 days as a single transcript bundle."
```

Under the hood: `yt-dlp` grabs the audio → `ffmpeg` converts it → `whisper-cpp` transcribes locally. No uploads, no paywall, no mangled timestamps.

### Bulk / file-based

```
"Transcribe every .mp4 in ~/Downloads/interviews and output as .txt siblings."
"Run Whisper on this audio file with the small.en model."
```

---

## Workflow combos

Common multi-tool patterns:

```
# Clip → transcript → script → video
"Transcribe https://instagram.com/reel/XXXX, then rewrite the hook in
 my voice, then hand it to /11-social-hook as a Seedance prompt."

# Brand design pipeline
"Using /minimalist-ui, design me a three-card pricing section. Then
 hand the color palette to Canva and make me a matching LinkedIn banner."

# Research → video
"Pull the transcript from this YouTube video, extract the 3 strongest
 quotes, then use /10-music-video to turn them into a 45s Seedance prompt."
```

---

## Keyboard / CLI shortcuts

Not specific to this repo, but used constantly with these tools (from `cli-maxxing`):

```
cskip       # launch Claude Code with all permissions skipped (daily driver)
cc          # launch Claude Code (normal mode)
ccr         # Claude Code, resume last session
ccc         # Claude Code in continuous mode
cbrain      # open the 2ndBrain vault context (requires 2ndBrain-mogging)
```

---

## Installed paths (reference)

| Thing | Where |
|---|---|
| Design skills | `~/.claude/skills/ui-ux-pro-max/`, `~/.claude/skills/design-taste-frontend/`, …7 more taste variants |
| Video prompt skills | `~/.claude/skills/01-cinematic/` … `~/.claude/skills/15-real-estate/` |
| Remotion skill | `~/.claude/skills/remotion-best-practices/` |
| MCP registry | `claude mcp list` |
| Install marker | `~/.claude/.creativity-maxxing-installed` |
| yt-dlp CLI | `$(which yt-dlp)` (typically `/opt/homebrew/bin/yt-dlp`) |
| whisper-cpp | `$(which whisper-cli)` or `/opt/homebrew/bin/whisper-cli` |
| FFmpeg | `$(which ffmpeg)` |

[⤴ back to top](#top)
