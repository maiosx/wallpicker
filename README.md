# Wallpaper Picker

A fullscreen Omarchy overlay that grids out every image in your Pictures
folder so you can click one to set it as your wallpaper. Built from the
same overlay template as Soprano/Runway: `WlrLayer.Overlay`, exclusive
keyboard focus, `keepLoaded`, bar-widget toggle.

## Install

Local checkout (recommended while you tweak paths/columns):

```bash
plugin_dir="$HOME/.config/omarchy/plugins/wallpicker.grid"
mkdir -p "$(dirname "$plugin_dir")"
ln -s "$PWD" "$plugin_dir"
omarchy-shell shell rescanPlugins
omarchy plugin enable wallpicker.grid
```

Or, once it's in its own git repo:

```bash
omarchy plugin add https://github.com/<you>/wallpicker.git --enable --yes
```

Enable the **Wallpapers** bar widget from Setup → Bar if it doesn't show
up on the right side automatically.

## Use

- Click the grid glyph (▦) in the bar to open/close the overlay.
- Click any thumbnail to apply it immediately and close the overlay.
- Escape dismisses without changing anything.

IPC:

```bash
omarchy-shell shell toggle wallpicker.grid
omarchy-shell wallpicker toggle|open|close|status
```

## Configuration

Open `WallpaperPicker.qml` and edit the properties near the top:

- `picturesDir` — defaults to `$HOME/Pictures`. Point it at any folder.
- `recursive` — set to `true` to include subfolders.
- `columns` — number of grid columns (default 5).

## How wallpaper-setting works

On click this plugin runs Omarchy's own CLI:

```bash
omarchy theme bg set "<chosen image>"
```

via `Util.execDetached(...)` (the same helper Omarchy's own plugins use).
Earlier drafts of this plugin manually symlinked
`~/.config/omarchy/current/background` and relaunched `swaybg` by hand —
that fought the CLI over state it owns (it actually tracks the current
background under `~/.local/state/omarchy/current/`) and silently did
nothing on current Omarchy releases. Letting `omarchy theme bg set` do
it is what Omarchy's own community plugins (e.g. grid-wallpaper-picker)
do, and it's the version that actually works.

## Remove

```bash
omarchy plugin disable wallpicker.grid
omarchy plugin remove wallpicker.grid --yes
```

## Notes / things to double check on your machine

- Relies on `omarchy theme bg set <path>` being available on your
  Omarchy version. Run it once from a terminal with a real image path
  to confirm it works on your system before relying on the plugin.
- The Quickshell `Process`/`StdioCollector` API used for listing files
  matches the pattern Omarchy's own plugins use, but if your Quickshell
  version's IPC API differs slightly, check `qs.Io`/`Quickshell.Io`
  docs and adjust `listProc`.
