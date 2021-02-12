Install `scad-mode' and load this script:

  (require 'scad-preview)

then call `scad-preview-mode' in a `scad-mode' buffer.

You can rotate the preview image with following keybinds:

- <right>   scad-preview-rotz+
- <left>    scad-preview-rotz-
- <up>      scad-preview-dist-
- <down>    scad-preview-dist+
- C-<left>  scad-preview-roty+
- C-<right> scad-preview-roty-
- C-<up>    scad-preview-rotx+
- C-<down>  scad-preview-rotx-
- M-<left>  scad-preview-trnsx+
- M-<right> scad-preview-trnsx-
- M-<up>    scad-preview-trnsz-
- M-<down>  scad-preview-trnsz+
- r         scad-preview-reset-camera-parameters

You can also use "hjkl" or "npbf" instead of arrow keys.
