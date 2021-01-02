Provides syntax highlighting and a "go to lexicon"-function useful
for editing Helsinki Finite State Transducer descriptions.

Usage:
(add-to-list 'load-path "/path/to/hfst-mode-folder")
(autoload 'hfst-mode "~/path/to/hfst-mode/hfst.el")
; Change these lines if you name your files something other
; than .twol and .lexc:
(add-to-list 'auto-mode-alist '("\\.twol$" . hfst-mode))
(add-to-list 'auto-mode-alist '("\\.lexc$" . hfst-mode))

For information about Helsinki Finite State Transducer Tools
(HFST), see http://hfst.github.io/"
