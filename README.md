# Corporate-man's Linux

> Turn any Mac into mine in one command. macOS, bent to behave like a tiling-WM Linux desktop.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BawanHoshyar/corporate-mans-linux/main/setup.sh)
```

Re-runnable. Re-running skips what's already installed and updates what's stale.

### Undo

One command to reverse everything and put the Mac back the way it was:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BawanHoshyar/corporate-mans-linux/main/uninstall.sh)
```

Walks the setup in reverse: stops services, uninstalls every formula/cask/tap in the Brewfile, removes ytermusic, deletes the four Ollama models, blows away `~/.hermes` and the tmux plugins, deletes every `defaults write` key, then restores the most recent `~/.dotfiles-backup-*` into place. Confirms before each destructive step (use `--yes` to skip prompts, `--dry-run` to preview).

Kept by default — pass `--nuke` to remove these too:

- **Homebrew itself** (may have pre-existed)
- **gh / atuin auth** and `~/.local/share/atuin`

Never auto-removed (do it yourself if you want a truly clean Mac):

- **Xcode Command Line Tools** — too disruptive to yank; lots of other dev tools need them
- **`~/.ssh`** — your keys
- **Accessibility / Screen Recording grants** — revoke under System Settings → Privacy & Security

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

## The `setup` command — one-shot workspace

`setup [name]` (defaults to `x`) drops you into a tmux session with the four tools I always want open, laid out in a single window:

```
+--------+-----------+-----------+
|        |           | ytermusic |
|  yazi  |  claude   +-----------+
|        |           |   nvim    |
+--------+-----------+-----------+
```

- **left (~22%)** — `yazi` (file manager)
- **middle (~47%)** — `claude` (Claude Code)
- **right (~31%), top** — `ytermusic` (music)
- **right (~31%), bottom** — `nvim`

If a session with that name already exists it reattaches (or `switch-client`s if you're already inside tmux) instead of recreating panes — so `setup` is safe to run repeatedly, and `setup work`, `setup repo-a`, etc. give you parallel workspaces you can flip between.

Defined as a `setup()` shell function in `dotfiles/zshrc`. Press `⌘⌥/` in Hammerspoon to see this and every other shortcut on one screen.

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

The last script, `99-post-install.sh`, is **interactive** — it walks you through every step the OS won't let us automate, runs what it can, and pauses where it must. Steps:

1. **Login shell:** `chsh -s` to brew's zsh (asks for your password).
2. **SSH key:** prompts for an email, generates ed25519, adds to keychain.
3. **gh auth login:** opens browser, you paste the one-time code.
4. **Uploads the pubkey** to GitHub via `gh ssh-key add` — no manual paste.
5. **Atuin:** offers register / login / skip.
6. **Permissions:** opens the System Settings panels for Accessibility and Screen Recording — you click the toggles for AeroSpace, Hammerspoon, Sketchybar and press ENTER.
7. **Claude Code:** opens the app so you can run `/login`.
8. **Ghostty:** opens it so you can pick "Make Default Terminal".
9. **Hermes config:** copies the example into place, optionally opens in `$EDITOR`.
10. **ytermusic cookie:** points you at the README section below; confirms the file exists.
11. **Extra Ollama models:** prompts for any model name beyond the four defaults.

After that, **log out + log back in** (or reboot) so Fn-keys, `chsh`, and Accessibility grants settle.

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
