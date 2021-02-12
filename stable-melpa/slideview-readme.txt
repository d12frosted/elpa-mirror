View sequential files with simple operation.

## Install:

    (require 'slideview)

Start slideview-mode automatically when open a image file.

    (add-hook 'image-mode-hook 'slideview-mode)

## Usage:

* Space
  Move forward slideview

* Backspace
  Move backward slideview

* `C-c C-i` / `C-c C-M-i` (Work only in `image-mode')
  Concat current image with next/previous image.
  To indicate the viewing file direction, please use
  `slideview-modify-setting' or `slideview-add-matched-file'

* Slideview settings for file.zip

    (slideview-modify-setting "/path/to/file.zip"
                              :margin 30 :direction 'right)
