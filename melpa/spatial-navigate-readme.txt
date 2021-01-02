Support jumping horizontally & vertically
across blocks of white-space or non-white-space.

; Usage


;; This shows how using Alt-Arrow Keys can be used to set directional navigation.
(global-set-key (kbd "<M-up>") 'spatial-navigate-backward-vertical-bar)
(global-set-key (kbd "<M-down>") 'spatial-navigate-forward-vertical-bar)
(global-set-key (kbd "<M-left>") 'spatial-navigate-backward-horizontal-bar)
(global-set-key (kbd "<M-right>") 'spatial-navigate-forward-horizontal-bar)

;; If you use evil-mode, the 'box' navigation functions make sense in normal mode,
;; the 'bar' functions make most sense in insert mode.

(define-key evil-normal-state-map (kbd "M-k") 'spatial-navigate-backward-vertical-box)
(define-key evil-normal-state-map (kbd "M-j") 'spatial-navigate-forward-vertical-box)
(define-key evil-normal-state-map (kbd "M-h") 'spatial-navigate-backward-horizontal-box)
(define-key evil-normal-state-map (kbd "M-l") 'spatial-navigate-forward-horizontal-box)
(define-key evil-insert-state-map (kbd "M-k") 'spatial-navigate-backward-vertical-bar)
(define-key evil-insert-state-map (kbd "M-j") 'spatial-navigate-forward-vertical-bar)
(define-key evil-insert-state-map (kbd "M-h") 'spatial-navigate-backward-horizontal-bar)
(define-key evil-insert-state-map (kbd "M-l") 'spatial-navigate-forward-horizontal-bar)
