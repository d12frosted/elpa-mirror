

* Slideview settings for file.zip

(slideview-modify-setting "/path/to/file.zip"
    :margin 30 :direction 'right)

* Space
  Move forward slideview

* Backspace
  Move backward slideview

* C-c C-i, C-c C-p (Work only in `image-mode')
  Concat current image with next/previous image.
  To indicate the viewing file direction, please use
  `slideview-modify-setting' or `slideview-add-matched-file'
