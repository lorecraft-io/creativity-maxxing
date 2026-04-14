# Security Policy — creativity-maxxing

`creativity-maxxing` installs creative tooling on top of a working
`cli-maxxing` environment: design skills, component MCPs, video frameworks,
and media transcription utilities. It does **not** ship secrets itself, but
several of the tools it installs read credentials from your shell
environment or from a local config file. Treat those credentials like any
other production secret.

## Credential surface

The installer + the tools it installs touch the following credential types.

### 21st.dev Magic MCP
- `MAGIC_API_KEY` (or whatever env var the latest `@21st-dev/magic`
  release reads — check the upstream README before configuring).
- Grants access to the 21st.dev component generation API. A leaked key
  lets someone burn your component-generation quota and, depending on
  tier, exfiltrate prompt history.
- **Store in**: `~/.zshrc` / `~/.bashrc` via `export` behind a
  `[ -f ... ] && source ...` guard on a private dotfile. Never paste
  directly into a committed rc file or a shared shell profile.
- **Rotate**: immediately if the key appears in a commit, a screen
  recording, or a pasted terminal transcript.

### 21st.dev account credentials
- The Magic MCP is gated on a 21st.dev account. Protect email + password
  (or SSO) with 2FA. Usage is billable per their current pricing page.

### Whisper / OpenAI API keys (optional)
- If you configure `whisper-mcp` to call a remote inference endpoint
  rather than running `whisper-cpp` locally, you may wire in an
  `OPENAI_API_KEY` or equivalent.
- The default local path (`whisper-cpp`) runs entirely offline and does
  **not** need a key. Prefer local transcription when handling
  unreleased audio, interviews, or anything under NDA.

### YouTube Transcript MCP
- No credential by default. Uses public transcript endpoints.
- Be aware that scraping transcripts at scale can still violate YouTube's
  ToS even without a key.

### yt-dlp (CLI + MCP)
- No credential by default.
- Supports `--cookies` / `--username` / `--netrc` for logged-in downloads
  (private IG, paywalled videos). If you pass those flags, treat the
  cookie jar / netrc file exactly like a password — it is a live session.
- Never commit a cookies file, a netrc, or a download config that
  references them.

### Remotion
- Remotion itself needs no credential. Cloud rendering (Remotion Lambda,
  Remotion Cloud Run) does. If you enable a cloud renderer, follow their
  upstream IAM docs and scope the deploy role to a single bucket.

## Reporting a vulnerability

If you find a security issue in the installer scripts in this repo
(command injection in `install.sh` / `uninstall.sh`, a typo'd `rm -rf`,
an unvalidated download URL, etc.), open a private advisory on the
GitHub repository or email the maintainer listed on the org profile.
**Do not** file a public issue for credential-exfiltration class bugs.

## Install-script expectations

Both `install.sh` and `uninstall.sh` in this repo:

- use `set -euo pipefail` to fail fast
- require `claude` + `~/.claude/skills` to already exist (i.e. cli-maxxing
  ran successfully first)
- never auto-download a binary without HTTPS
- prompt before touching `ffmpeg` during uninstall because it is
  frequently system-shared with non-creative tooling

If you modify a step script, re-run `bash -n step-{4,5}/step-*-install.sh`
and `shellcheck` before merging.
