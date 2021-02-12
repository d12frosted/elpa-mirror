
Capture is an Emacs mode to make screencasts on Linux easier.
(Well, maybe for some of you who use Emacs)

Configuration
------------------------

(require 'capture)

(setq capture-video-dest-dir "~/screencasts/SORT/")
(global-set-key (kbd "<s-f12>") 'capture-run-mode)

(defun my-capture-presets ()
  "Make my presets for capturing."
  (interactive)
  (capture-presets-clear)
  (capture-add-preset 524 333 854 480 15 "webm" "854px (webcam mic)"
                      (list "Webcam C270 Analog Mono")
                      (concat capture-background-path my-854-wallpaper)))
(my-capture-presets)

See more at https://github.com/pashinin/capture.el
