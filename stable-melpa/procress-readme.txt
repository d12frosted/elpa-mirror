This package shows a progress indicator for a process in the modeline.
Typical usage:

(require 'procress)
(procress-load-default-svg-images)
(add-hook 'LaTeX-mode-hook #'procress-auctex-mode)

The function `procress-load-default-svg-images' can be called for SVG
images (an animations) to be used to indicate progress.

The mode `procress-auctex-mode' shows the progress for AUCTeX-created
processes.
