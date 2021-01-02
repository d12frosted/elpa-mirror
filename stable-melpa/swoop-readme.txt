Feature:
* Search words through a whole buffer or across buffers
* Highlight target line and matched words
* Stick to the nearest line even after update the list
* Utilize PCRE (Perl Compatible Regular Expressions) like search
* Utilize migemo (Japanese words search command)
* Edit matched lines synchronously
* Cache buffer information to start quickly
* Shrink text size in buffers to view more
* and more

Example config
----------------------------------------------------------------
;; Require
;; async.el   https://github.com/jwiegley/emacs-async
;; pcre2el.el https://github.com/joddie/pcre2el
;; ht.el      https://github.com/Wilfred/ht.el
(require 'swoop)
(global-set-key (kbd "C-o")   'swoop)
(global-set-key (kbd "C-M-o") 'swoop-multi)
(global-set-key (kbd "M-o")   'swoop-pcre-regexp)
(global-set-key (kbd "C-S-o") 'swoop-back-to-last-position)
(global-set-key (kbd "H-6")   'swoop-migemo)

;; Transition
;; isearch     > press [C-o] > swoop
;; evil-search > press [C-o] > swoop
;; swoop       > press [C-o] > swoop-multi
(define-key isearch-mode-map (kbd "C-o") 'swoop-from-isearch)
(define-key evil-motion-state-map (kbd "C-o") 'swoop-from-evil-search)
(define-key swoop-map (kbd "C-o") 'swoop-multi-from-swoop)

;; Resume
;; C-u M-x swoop : Use last used query

;; Swoop Edit Mode
;; During swoop, press [C-c C-e]
;; You can edit synchronously
