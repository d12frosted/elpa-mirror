Usage:

Dpaste a buffer

(require 'dpaste_de)

(dpaste-buffer)
The url is copied into your clipboard and kill ring

On a region
(require 'dpaste_de)
(dpaste-region)

Dpaste a buffer by specifying a name
(require 'dpaste_de)
(dpaste-buffer-with-name "*scratch*")

Special thanks to Martin Mahner (https://github.com/bartTC) for running dpaste.de

; Change Log:

0.2 - Fixes for the latest web.el
0.1 - Initial commit and push into melpa
