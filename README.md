# KEYBINDINGS

| KEY  | WHAT ITS DOING |
| ------------- | ------------- |
| K  | RESIZE |
| ARROWS+SHIFT  | MOVING ELEMENT FASTER  |
| ARROWS | MOVING ELEMENT |
| S | RESIZE |
| R | ROTATION |
| L | TOGGLE LAYERS PANEL |


Keybind `K` is for resizing using red points and `S` for resizing width and height at the same time while our element is selected

# LAYERS PANEL

Press `L`, or click the `LAYERS` button next to `OUTPUT` on the toolbar, to
open the layers panel in the top-right corner of the screen.

The panel lists every element on the canvas, top-most (front) layer first:

- Click a layer's name to select it - same as clicking it on the canvas.
- `V`/`H` toggles whether the layer is visible. Hidden layers are skipped
  both in the editor and in the generated OUTPUT code.
- `U`/`L` toggles whether the layer is locked. Locked layers can't be
  selected for dragging/resizing and ignore the rotate/resize-via-key (`R`/`S`)
  shortcuts, but can still be selected from the panel to unlock them again.
- `^` / `v` move a layer one step towards the front/back (rendering order).
- `X` deletes the layer.

Right-clicking an element on the canvas also exposes "Rename layer",
"Visible", "Locked", "Bring to front", "Send to back", "Move forward" and
"Move backward" in its context menu.

Newly added shapes are placed on top of the layer stack and selected
automatically.

# TODO

- [ ] Creating scrollable text lists (EXAMPLE1,EXAMPLE2, etc.) vertically.
- [ ] Snap to grid
- [x] Circles
- [x] Rectangles
- [x] Lines
- [x] Text
- [x] Rounded rectangles
- [x] Text
- [x] Context menu
- [ ] Editboxes
- [ ] Buttons
- [ ] Checkboxes
- [ ] Scrollbar
- [ ] Stylizing UI elements system
- [ ] Gridlist
- [ ] Slider
- [ ] Scrollable toolbar and centered
- [x] Layers menu
- [ ] Open project menu
- [ ] Save project
- [x] Move rendering order to top/down in context menu as opt
