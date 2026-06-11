-- Enable `hs -c "..."` and `open hammerspoon://reload` so config reloads
-- don't require quitting the menubar app.
require("hs.ipc")
hs.allowAppleScript(true)
hs.urlevent.bind("reload", function() hs.reload() end)

hs.hotkey.bind({"cmd"}, "t", function()
  hs.application.launchOrFocus("Ghostty")
end)

-- ── Cheatsheet (hold ⌘⌥/ to show, release to hide) ──────────────────────────
local cheatsheet = nil

local cheatsheetHtml = [[
<!DOCTYPE html>
<html><head><style>
  html, body { margin: 0; padding: 0; height: 100%; }
  body {
    font-family: -apple-system, "SF Pro Text", sans-serif;
    background: rgba(30, 30, 46, 0.96);
    color: #cdd6f4;
    padding: 22px 28px;
    box-sizing: border-box;
    border-radius: 18px;
    border: 1px solid rgba(205, 214, 244, 0.18);
  }
  h1 {
    font-size: 14px; margin: 0 0 14px 0; color: #cba6f7;
    text-align: center; letter-spacing: 1px; text-transform: uppercase;
  }
  .grid { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 0 24px; }
  h2 {
    font-size: 11px; text-transform: uppercase; letter-spacing: 1px;
    color: #89b4fa; margin: 12px 0 4px 0;
    border-bottom: 1px solid #45475a; padding-bottom: 3px;
  }
  .col > h2:first-child { margin-top: 0; }
  .row {
    display: flex; justify-content: space-between;
    font-size: 12px; padding: 2px 0; line-height: 1.4;
  }
  .keys {
    color: #f9e2af; font-family: ui-monospace, "SF Mono", monospace;
    font-size: 11px; white-space: nowrap;
  }
  .desc { color: #a6adc8; text-align: right; padding-left: 14px; }
  .signature {
    margin-top: 18px; padding-top: 10px;
    border-top: 1px solid rgba(205, 214, 244, 0.10);
    text-align: center; font-size: 10px; letter-spacing: 1.5px;
    text-transform: uppercase; color: #6c7086;
  }
</style></head><body>
<h1>Corporate Man's Linux</h1>
<div class="grid">
  <div class="col">
    <h2>Focus</h2>
    <div class="row"><span class="keys">⌥ h j k l</span><span class="desc">focus left/down/up/right</span></div>
    <h2>Move window</h2>
    <div class="row"><span class="keys">⌥ ⇧ h j k l</span><span class="desc">move window</span></div>
    <h2>Resize</h2>
    <div class="row"><span class="keys">⌥ −</span><span class="desc">shrink</span></div>
    <div class="row"><span class="keys">⌥ =</span><span class="desc">grow</span></div>
    <div class="row"><span class="keys">⌥ r</span><span class="desc">enter resize mode</span></div>
    <h2>Layout</h2>
    <div class="row"><span class="keys">⌥ /</span><span class="desc">tiles horiz ↔ vert</span></div>
    <div class="row"><span class="keys">⌥ ,</span><span class="desc">accordion horiz ↔ vert</span></div>
    <div class="row"><span class="keys">⌥ ⇧ space</span><span class="desc">floating ↔ tiling</span></div>
    <div class="row"><span class="keys">⌥ f</span><span class="desc">macOS fullscreen</span></div>
  </div>
  <div class="col">
    <h2>Workspaces</h2>
    <div class="row"><span class="keys">⌥ 1 … 9</span><span class="desc">switch workspace</span></div>
    <div class="row"><span class="keys">⌥ ⇧ 1 … 9</span><span class="desc">move window to workspace</span></div>
    <div class="row"><span class="keys">⌥ tab</span><span class="desc">last workspace</span></div>
    <div class="row"><span class="keys">⌥ ⇧ tab</span><span class="desc">workspace → next monitor</span></div>
    <h2>Windows</h2>
    <div class="row"><span class="keys">⌥ q</span><span class="desc">close window</span></div>
    <div class="row"><span class="keys">⌥ ↩</span><span class="desc">new Ghostty window</span></div>
    <h2>Service mode (⌥⇧;)</h2>
    <div class="row"><span class="keys">esc</span><span class="desc">reload config + exit</span></div>
    <div class="row"><span class="keys">r</span><span class="desc">flatten workspace</span></div>
    <div class="row"><span class="keys">f</span><span class="desc">toggle floating</span></div>
    <div class="row"><span class="keys">⌫</span><span class="desc">close all but current</span></div>
    <div class="row"><span class="keys">⌥ ⇧ h j k l</span><span class="desc">join with neighbor</span></div>
    <h2>Hammerspoon</h2>
    <div class="row"><span class="keys">⌘ t</span><span class="desc">launch Ghostty</span></div>
    <div class="row"><span class="keys">⌘ ⌥ /</span><span class="desc">hold to show this</span></div>
  </div>
  <div class="col">
    <h2>Shell</h2>
    <div class="row"><span class="keys">setup [name]</span><span class="desc">4-pane workspace: yazi · claude · ytermusic/nvim</span></div>
    <h2>tmux &middot; prefix ⌃b</h2>
    <div class="row"><span class="keys">⌃b ?</span><span class="desc">list all bindings</span></div>
    <div class="row"><span class="keys">⌃b d</span><span class="desc">detach session</span></div>
    <div class="row"><span class="keys">⌃b :</span><span class="desc">command prompt</span></div>
    <h2>Panes</h2>
    <div class="row"><span class="keys">⌃b v</span><span class="desc">split vertical (right)</span></div>
    <div class="row"><span class="keys">⌃b x</span><span class="desc">split horizontal (below)</span></div>
    <div class="row"><span class="keys">⌃b h j k l</span><span class="desc">focus pane</span></div>
    <div class="row"><span class="keys">⌃b H J K L</span><span class="desc">resize pane (repeatable)</span></div>
    <div class="row"><span class="keys">⌃b o</span><span class="desc">next pane</span></div>
    <div class="row"><span class="keys">⌃b z</span><span class="desc">zoom toggle</span></div>
    <div class="row"><span class="keys">⌃b q</span><span class="desc">show pane numbers</span></div>
    <div class="row"><span class="keys">⌃b r</span><span class="desc">reload tmux config</span></div>
    <h2>Windows</h2>
    <div class="row"><span class="keys">⌃b c</span><span class="desc">new window</span></div>
    <div class="row"><span class="keys">⌃b n p</span><span class="desc">next / prev window</span></div>
    <div class="row"><span class="keys">⌃b 0 … 9</span><span class="desc">switch by number</span></div>
    <div class="row"><span class="keys">⌃b ,</span><span class="desc">rename window</span></div>
    <div class="row"><span class="keys">⌃b &amp;</span><span class="desc">close window</span></div>
    <h2>Sessions &middot; Copy</h2>
    <div class="row"><span class="keys">⌃b s</span><span class="desc">list sessions</span></div>
    <div class="row"><span class="keys">⌃b $</span><span class="desc">rename session</span></div>
    <div class="row"><span class="keys">⌃b [</span><span class="desc">enter copy mode (q exit)</span></div>
  </div>
  <div class="col">
    <h2>LazyVim &middot; leader ␣</h2>
    <div class="row"><span class="keys">␣ ␣</span><span class="desc">find files (root)</span></div>
    <div class="row"><span class="keys">␣ /</span><span class="desc">live grep</span></div>
    <div class="row"><span class="keys">␣ ,</span><span class="desc">switch buffer</span></div>
    <div class="row"><span class="keys">␣ e</span><span class="desc">file explorer</span></div>
    <div class="row"><span class="keys">␣ qq</span><span class="desc">quit all</span></div>
    <h2>Buffers / Splits</h2>
    <div class="row"><span class="keys">⇧ h / ⇧ l</span><span class="desc">prev / next buffer</span></div>
    <div class="row"><span class="keys">␣ bd</span><span class="desc">delete buffer</span></div>
    <div class="row"><span class="keys">⌃ h j k l</span><span class="desc">move between splits</span></div>
    <div class="row"><span class="keys">␣ |  ␣ -</span><span class="desc">split right / below</span></div>
    <h2>LSP / Code</h2>
    <div class="row"><span class="keys">g d</span><span class="desc">go to definition</span></div>
    <div class="row"><span class="keys">g r</span><span class="desc">references</span></div>
    <div class="row"><span class="keys">K</span><span class="desc">hover docs</span></div>
    <div class="row"><span class="keys">␣ ca</span><span class="desc">code action</span></div>
    <div class="row"><span class="keys">␣ cr</span><span class="desc">rename symbol</span></div>
    <div class="row"><span class="keys">␣ cf</span><span class="desc">format</span></div>
    <div class="row"><span class="keys">] d  [ d</span><span class="desc">next / prev diagnostic</span></div>
    <h2>Git / Term / Lazy</h2>
    <div class="row"><span class="keys">␣ gg</span><span class="desc">lazygit</span></div>
    <div class="row"><span class="keys">] h  [ h</span><span class="desc">next / prev hunk</span></div>
    <div class="row"><span class="keys">⌃ /</span><span class="desc">toggle terminal</span></div>
    <div class="row"><span class="keys">␣ l</span><span class="desc">Lazy (plugins)</span></div>
    <div class="row"><span class="keys">␣ cm</span><span class="desc">Mason (LSP installer)</span></div>
  </div>
</div>
<div class="signature">Bawan A. Dawood</div>
</body></html>
]]

local function showCheatsheet()
  if cheatsheet then return end
  local screen = hs.screen.mainScreen():frame()
  local w, h = 1320, 640
  local rect = hs.geometry.rect(
    screen.x + (screen.w - w) / 2,
    screen.y + (screen.h - h) / 2,
    w, h
  )
  cheatsheet = hs.webview.new(rect)
    :html(cheatsheetHtml)
    :transparent(true)
    :allowTextEntry(false)
    :windowStyle({"borderless", "nonactivating"})
    :level(hs.drawing.windowLevels.overlay)
    :show()
end

local function hideCheatsheet()
  if cheatsheet then
    cheatsheet:delete()
    cheatsheet = nil
  end
end

hs.hotkey.bind({"cmd", "alt"}, "/", showCheatsheet, hideCheatsheet)
