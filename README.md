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

Omarchy doesn't ship a public "set this exact file as wallpaper" command
(only `omarchy-theme-bg-next`, which cycles the *current theme's*
backgrounds). So on click this plugin does what Omarchy itself does
internally:

```bash
ln -sf "<chosen image>" "$HOME/.config/omarchy/current/background"
pkill -x swaybg
swaybg -i "<chosen image>" -m fill &
```

This mirrors the actual background symlink + swaybg relaunch, so the
wallpaper survives independent of any theme's own background set. If a
future Omarchy release exposes a stable "set wallpaper to path" command,
swap it in inside `setWallpaper()` in place of the bash one-liner.

## Remove

```bash
omarchy plugin disable wallpicker.grid
omarchy plugin remove wallpicker.grid --yes
```

## Notes / things to double check on your machine

- This assumes Wayland + swaybg, which is what stock Omarchy uses for
  backgrounds. If you've switched to `swww` or `hyprpaper`, change the
  commands in `setWallpaper()` accordingly.
- The Quickshell `Process`/`StdioCollector` API used for listing files
  matches the pattern Omarchy's own plugins (e.g. Soprano) use, but if
  your Quickshell version's IPC API differs slightly, check
  `qs.Io`/`Quickshell.Io` docs and adjust `listProc`/`applyProc`.
