## Description
Queries cliphist history in fzf with previews and some basic keybinds for clipboard management.  I opted to use IPC over the recommended lua implementation because I suck at lua but I am very open to other implementations of this script, theoretically this should run faster in lua using native hyprlua. I don't currently have any plans to maintain this etc, mainly posting this to just share my implementation thus I give full permission to anyone to modify or distribute this file for any reason.

Credits to [Jannis-baum](https://github.com/jannis-baum), in providing the following solution to `kitty icat --clear` not functioning as intended and providing the following: `printf "\x1b_Ga=d,d=A\x1b\\"` to clear all displayed iamges. Link to the post for reference:
[https://github.com/junegunn/fzf/issues/3228#issuecomment-1803402184](https://github.com/junegunn/fzf/issues/3228#issuecomment-1803402184)
Currently unsure if [Kovid](https://github.com/kovidgoyal/kitty) has merged an official fix, too lazy to check fwiw.

## Dependencies
**Explicit dependencies:**
```
cliphist
wl-clipboard
fzf
```

**Recommended dependencies:**
```
hyprland
kitty (OR Ghostty)
socat
```
Respectively:

Use in other WMs is possible but just be sure to swap out any hyprctl calls for other WMs, so this is recommended but not required for core function.
Relies on `kitty icat` for image display but should function fine in other terminals like foot (without image previews). It should be fairly simple to swap out the graphics protocol to swap terminals if preferred. IIRC Ghostty supports the kitty graphics protocl and provides  the same icat command so this should function with minimal/no edits.
Socket cat was utilized to listen to the hypr IPC event socket for any focus changes away from the clipboard window class and trigger a trapped exit. Technically not necessary and can be gutted.

## Minimal implementation example (Hyprlua):
```lua
local class = "cliphist_fzf"
local cmd = "kitty --class " .. class .. " -- ~/.config/hypr/scripts/cliphist_fzf.sh"

hl.bind("SUPER + V", function()
    local w = hl.get_active_window()

    if w and w.class == class then
        hl.dispatch(hl.dsp.window.close({ window = "class:^" .. class .. "$" }))
    else
        hl.dispatch(hl.dsp.exec_cmd(cmd))
    end
end)

hl.window_rule({
    name = "Cliphist",
    match = { class = "^cliphist_fzf$" },
    float = true,
    size = { "(monitor_w*0.47)", "(monitor_h*0.51)" },
    center = true
})
```
*Note, if using UWSM to modify the spawn command ie: `local cmd = "uwsm app -- kitty --class " .. class .. " -- ~/.config/hypr/scripts/cliphist_fzf.sh"`
