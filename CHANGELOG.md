# Changelog

All notable changes to `creativity-maxxing` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- README: social-links badge strip (X · LinkedIn · YouTube · Instagram, ruvnet-style for-the-badge) inserted into the centered header block beneath the project license badge.
- **Playwright MCP** added to the design module (`design/install.sh`) so headless web automation is available for design QA workflows.

### Changed
- Git history rewrite: `git filter-repo` collapsed all author/committer identities into a single `Nate Davidovich <nate@lorecraft.io>` identity across `main` and the v1.0.0 tag. All `Co-authored-by:` trailers stripped. Tag commit hash for v1.0.0 changed; this repo has no published npm artifact, so no downstream impact.

### Fixed
- Excalidraw MCP URL aligned with the official OSS README (no more pointing at the wrong upstream).
- Added `set -e` to `design/install.sh` so a partial install fails loud instead of silently leaving missing tools on disk.
- MCP detection greps anchored at `^<name>:` to stop matching substrings inside other MCP names (e.g. `obsidian` no longer false-matched on `obsidian-mcp`).

## [1.0.0] - 2026-04-13

### Added — Initial extraction from cli-maxxing

`creativity-maxxing` was carved out of the original `cli-maxxing` step-4 + step-5 modules to keep the design / video / audio / transcription stack on a separate cadence from the core terminal install. Per `project_cli_maxxing_split` and `project_cli_maxxing_split_exec`.

- **Design module** (`design/install.sh`) — Figma MCP, Excalidraw MCP, Gamma MCP, Magic MCP, Canva MCP, Code Connect setup.
- **Media module** (`media/install.sh`) — Higgsfield Seedance video skills (15 templates), yt-dlp MCP, whisper-mcp transcription stack.
- `CHEAT-SHEET.md` — every slash command, skill, and MCP call exposed by the install in one reference page.
- Cross-platform install/uninstall/update scripts.
- Test suite — 5 files, all green at v1.0.0.
