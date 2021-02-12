
; Use migemo on ivy.
; How to Use?

    ;; Toggle migemo and fuzzy by command.
    (define-key ivy-minibuffer-map (kbd "M-f")
    (define-key ivy-minibuffer-map (kbd "M-m")

    ;; If you want to defaultly use migemo on swiper and counsel-find-file:
    (setq ivy-re-builders-alist '((t . ivy--regex-plus)
                                  (swiper . ivy-migemo--regex-plus)
                                  (counsel-find-file . ivy-migemo--regex-plus))
                                  ;(counsel-other-function . ivy-migemo--regex-plus)
                                  )
    ;; Or you prefer fuzzy match like ido:
    (setq ivy-re-builders-alist '((t . ivy--regex-plus)
                                  (swiper . ivy-migemo--regex-fuzzy)
                                  (counsel-find-file . ivy-migemo--regex-fuzzy))
                                  ;(counsel-other-function . ivy-migemo--regex-fuzzy)
                                  )

; Functions
;; ~ivy-migemo-toggle-fuzzy~
   Toggle fuzzy match or not on ivy.  Almost same as ~ivy-toggle-fuzzy~, except
   this function can also be used to toggle between ~ivy-migemo--regex-fuzzy~ and
   ~ivy-migemo--regex-plus~.
;; ~ivy-migemo-toggle-migemo~
   Toggle using migemo or not on ivy.
; License
  This package is licensed by GPLv3.
