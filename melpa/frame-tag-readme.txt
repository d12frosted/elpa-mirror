; Usage

frame-tag mode allows you to switch between frames quickly. Frames are orderd by their positions
The top left frame is assigned the number 1. The second frame is assigned 2 and so on.
To switch to the frames, press M-1 to switch to frame 1.
It assigns a maximum of 9 frames to switch from.

; Installation

(add-to-list 'load-path "/path/to/frame-tag")
(require 'frame-tag)
(frame-tag-mode 1)
