List the all lines to another buffer, which is able to squeeze
by any words you input.  At the same time, the original buffer's
cursor is jumping line to line according to moving up and down
the list.

Example config
----------------------------------------------------------------
;; helm from https://github.com/emacs-helm/helm
(require 'helm)

;; Locate the helm-swoop folder to your path
;; This line is unnecessary if you get this program from MELPA
(add-to-list 'load-path "~/.emacs.d/elisp/helm-swoop")

(require 'helm-swoop)

;; Change keybinds to whatever you like :)
(global-set-key (kbd "M-i") 'helm-swoop)
(global-set-key (kbd "M-I") 'helm-swoop-back-to-last-point)
(global-set-key (kbd "C-c M-i") 'helm-multi-swoop)
(global-set-key (kbd "C-x M-i") 'helm-multi-swoop-all)

;; When doing isearch, hand the word over to helm-swoop
(define-key isearch-mode-map (kbd "M-i") 'helm-swoop-from-isearch)
(define-key helm-swoop-map (kbd "M-i") 'helm-multi-swoop-all-from-helm-swoop)

;; Save buffer when helm-multi-swoop-edit complete
(setq helm-multi-swoop-edit-save t)

;; If this value is t, split window inside the current window
(setq helm-swoop-split-with-multiple-windows nil)

;; Split direction.  'split-window-vertically or 'split-window-horizontally
(setq helm-swoop-split-direction 'split-window-vertically)

;; If nil, you can slightly boost invoke speed in exchange for text color
(setq helm-swoop-speed-or-color nil)

;; Go to the opposite side of line from the end or beginning of line
(setq helm-swoop-move-to-line-cycle t)

;; Optional face for line numbers
;; Face name is `helm-swoop-line-number-face`
(setq helm-swoop-use-line-number-face t)

----------------------------------------------------------------

* `M-x helm-swoop` when region active
* `M-x helm-swoop` when the cursor is at any symbol
* `M-x helm-swoop` when the cursor is not at any symbol
* `M-3 M-x helm-swoop` or `C-u 5 M-x helm-swoop` multi separated line culling
* `M-x helm-multi-swoop` multi-occur like feature
* `M-x helm-multi-swoop-all` apply all buffers
* `C-u M-x helm-multi-swoop` apply last selected buffers from the second time
* `M-x helm-swoop-same-face-at-point` list lines have the same face at the cursor is on
* During isearch `M-i` to hand the word over to helm-swoop
* During helm-swoop `M-i` to hand the word over to helm-multi-swoop-all
* While doing `helm-swoop` press `C-c C-e` to edit mode, apply changes to original buffer by `C-x C-s`

Helm Swoop Edit
While doing helm-swoop, press keybind [C-c C-e] to move to edit buffer.
Edit the list and apply by [C-x C-s].  If you'd like to cancel, [C-c C-g]
