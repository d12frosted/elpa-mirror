;;; Commentary:

;; drag-stuff is a minor mode for dragging stuff around in Emacs. You
;; can drag lines, words and region.

;; To use drag-stuff, make sure that this file is in Emacs load-path
;; (add-to-list 'load-path "/path/to/directory/or/file")
;;
;; Then require drag-stuff
;; (require 'drag-stuff)

;; To start drag-stuff
;; (drag-stuff-mode t) or M-x drag-stuff-mode
;;
;; drag-stuff is buffer local, so hook it up
;; (add-hook 'ruby-mode-hook 'drag-stuff-mode)
;;
;; Or use the global mode to activate it in all buffers.
;; (drag-stuff-global-mode t)

;; Drag Stuff stores a list (`drag-stuff-except-modes') of modes in
;; which `drag-stuff-mode' should not be activated in (note, only if
;; you use the global mode) because of conflicting use.
;;
;; You can add new except modes:
;;   (add-to-list 'drag-stuff-except-modes 'conflicting-mode)

;; Default modifier key is the meta-key. This can be changed and is
;; controlled by the variable `drag-stuff-modifier'.
;;
;; Control key as modifier:
;;   (setq drag-stuff-modifier 'control)
;;
;; Meta and Shift keys as modifier:
;;   (setq drag-stuff-modifier '(meta shift))

