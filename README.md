# Corporate-man's Linux

> Turn any Mac into mine in one command. macOS, bent to behave like a tiling-WM Linux desktop.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BawanHoshyar/corporate-mans-linux/main/setup.sh)
```

Re-runnable. Re-running skips what's already installed and updates what's stale.

---

## What you get

| Layer            | Tool                                                                 |
| ---------------- | -------------------------------------------------------------------- |
| Tiling WM        | [AeroSpace](https://github.com/nikitabobko/AeroSpace)                |
| Status bar       | [Sketchybar](https://github.com/FelixKratz/SketchyBar) + [Borders](https://github.com/FelixKratz/JankyBorders) |
| Glue / hotkeys   | [Hammerspoon](https://www.hammerspoon.org)                           |
| Curator          | [Omachy](https://dough654.github.io/Omachy/) (Omakub-for-Mac)        |
| Terminal         | [Ghostty](https://ghostty.org) (Catppuccin Mocha, JetBrains Mono 13, hidden titlebar) |
| Shell            | zsh + [Starship](https://starship.rs) + [atuin](https://atuin.sh) + fzf + autosuggestions + syntax-highlighting |
| Editor           | [Neovim](https://neovim.io) with [LazyVim](https://www.lazyvim.org)  |
| File / git / docker TUIs | [yazi](https://yazi-rs.github.io), [lazygit](https://github.com/jesseduffield/lazygit), [lazydocker](https://github.com/jesseduffield/lazydocker) |
| Local agents     | [Ollama](https://ollama.com) + [OpenCode](https://opencode.ai) + [Hermes](https://github.com/NousResearch/hermes-agent) |
| Music            | [ytermusic](https://github.com/BawanHoshyar/ytermusic) — my fork    |
| Bonus            | atuin, fastfetch, ffmpeg, fzf, gh, go, rust, tmux, uv, yt-dlp        |

GUI casks: aerospace, claude-code, ghostty, hammerspoon, ollama-app, postman, plus the two Nerd Fonts.

---

## Opinionated choices, explained

### Why AeroSpace and not yabai?

yabai needs SIP partially disabled to do anything useful. AeroSpace doesn't — pure userland. Same i3-like model. The trade is worth it on a corporate Mac where MDM-managed SIP is non-negotiable.

### Why Sketchybar over the native menu bar?

The native bar can't render per-space, can't run scripts, can't show icons that animate to state. Sketchybar can. Borders adds the colored window outline macOS refuses to ship.

### Why Hammerspoon *and* AeroSpace?

AeroSpace = window management. Hammerspoon = everything else (caps-lock as hyper key, custom app launchers, audio toggles, focus modes, anything you'd script in Lua). They don't overlap.

### Why Omachy?

It's the macOS-side answer to omarchy/omakub — a curated, batteries-included set of tools that already cooperate. Skip the solo-curation tax of stitching aerospace + sketchybar + borders + hammerspoon yourself.

### Why function keys swapped to F-keys-first?

Every serious dev tool — Neovim, VS Code, tmux, IntelliJ — binds to F1–F12. macOS ships with media keys default and treats F-keys as the Fn-modified ones. We flip it so dev tools work without a modifier, and you press Fn for brightness/volume.

`defaults write -g com.apple.keyboard.fnState -bool true` — handled in `scripts/30-macos-defaults.sh`.

### Why Ghostty?

GPU-accelerated, zero-config-and-it-looks-good, Mitchell Hashimoto's discipline. iTerm2 has too many menus. Alacritty makes you write YAML for everything. Kitty's config language is its own dialect. Ghostty is the boring-on-purpose terminal.

### Why a custom ytermusic?

Upstream `ccgauche/ytermusic` had bugs and missing pieces I needed: config cleanup, search UX rewrite, playlist view rewrite, playback gauges, an audio visualizer. My fork lives at <https://github.com/BawanHoshyar/ytermusic>. The setup script installs it via `cargo install --git`.

### Why no VS Code extension restore?

I live in Neovim. The only GUI I sign into manually is Postman. If you want VS Code mirrored, fork this repo and add `cask "visual-studio-code"` to the Brewfile + dump your extensions via `code --list-extensions > vscode-extensions.txt`.

### Why no encrypted secrets?

This repo is public so other people can use it. Anyone forking should bring their own ssh keys, atuin sync key, GitHub auth, Claude login, Hermes config. The script prints a manual TODO list of every credential to set up.

---

## YouTube Music cookie (for ytermusic)

`ytermusic` reads your YouTube Music playlists via a session cookie. There's no OAuth path — you have to export it from a logged-in browser.

1. **Install a cookie-export extension**:
   - Chrome / Edge: [EditThisCookie](https://chromewebstore.google.com/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg) or [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
   - Firefox: [cookies.txt](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/)
2. **Log into <https://music.youtube.com>** in that browser.
3. **Export cookies** for the domain `.youtube.com` in **Netscape format** (the `cookies.txt` standard yt-dlp uses).
4. **Save the file** to the location ytermusic asks for on first launch — usually `~/.config/ytermusic/cookies.txt`. Run `ytermusic` once with no cookie and it will print the exact expected path.
5. **Restart ytermusic.** Playlists should load.

If you re-export, replace the same file — ytermusic re-reads it on launch.

> The cookie expires roughly every 2 years, or whenever you sign out of YouTube on that browser. If playlists stop loading, re-export.

---

## What's NOT in this repo

- `~/.ssh`, atuin login key, zsh history, browser sessions — bring your own.
- `~/.hermes/config.yaml` — has API keys + machine-specific paths. Sample at `~/.hermes/config.yaml.example` after `60-hermes.sh` runs.
- Corporate apps (FortiClient, Okta Verify, SentinelOne, Cloudflare WARP, etc.) — IT pushes these via MDM on a work Mac. Trying to brew-install them collides.
- Microsoft Office, Apple iWork — work license, not portable.
- VS Code extensions and Chrome bookmarks — use the native sync.

---

## After install

The final banner from `99-post-install.sh` lists every manual step. The big ones:

1. **Log out + log back in.** Fn-keys, `chsh`, and Accessibility permissions don't take effect mid-session.
2. **Grant Accessibility + Screen Recording** to AeroSpace, Hammerspoon, Sketchybar in System Settings.
3. **Sign in:** `atuin login`, `gh auth login`, ssh-keygen and paste to GitHub, `/login` in Claude Code, sign into Postman.
4. **Ghostty:** Settings → Make Default Terminal.
5. **Hermes:** copy `~/.hermes/config.yaml.example` → `~/.hermes/config.yaml`, fill in.
6. **ytermusic:** follow the YT cookie section above.

---

## Testing on a VM before nuking a real Mac

If you want to dry-run, [Tart](https://tart.run) can boot a macOS VM in seconds:

```bash
brew install cirruslabs/cli/tart
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest test-mac
tart run test-mac
# inside the VM:
bash <(curl -fsSL https://raw.githubusercontent.com/BawanHoshyar/corporate-mans-linux/main/setup.sh)
```

---

## Layout

```
.
├── README.md
├── setup.sh              # one entry point, sources scripts/ in order
├── Brewfile              # brew bundle manifest
├── scripts/
│   ├── 00-preflight.sh   # xcode CLT + brew
│   ├── 10-brew-bundle.sh # everything in Brewfile
│   ├── 20-dotfiles.sh    # symlink with timestamped backup of anything replaced
│   ├── 30-macos-defaults.sh
│   ├── 40-cargo-installs.sh   # ytermusic from BawanHoshyar fork
│   ├── 50-ollama-models.sh    # pulls 4 default models
│   ├── 60-hermes.sh           # clones NousResearch/hermes-agent
│   ├── 70-tmux-tpm.sh
│   ├── 80-services.sh
│   └── 99-post-install.sh
└── dotfiles/             # the actual configs, symlinked into $HOME
```

---

## License

The dotfiles and scripts in this repo are MIT-licensed. The third-party projects they install have their own licenses — see each project's repo.
