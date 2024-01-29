
Haki is an elegant, high-contrast dark theme in modern sense.
Looks and distinguish-ability is maintained.

Theme was inspired on modus-vivendi and minad's packages.
You can use `haki-change-region' to interactively change
`haki-region' face.
You can set some fonts, as haki-theme inherit them in some sensible places
like elfeed, org-mode, eww (shr)

sample configuration
(use-package haki-theme
:custom-face
(haki-region ((t (:background "#2e8b57" :foreground "#ffffff"))))
(haki-highlight ((t (:background "#fafad2" :foreground "#000000"))))
:config
(setq
 ;; If you skip setting this, it will use 'default' font.
 haki-heading-font "Comic Mono"
 haki-sans-font "Iosevka Comfy Motion"
 haki-title-font "Impress BT"
 haki-link-font "VictorMono Nerd Font" ;; or Maple Mono looks good
 haki-code-font "Maple Mono") ;; inline code/verbatim (org,markdown..)

;; For meow/evil users (change border of mode-line according to modal states)
(add-hook 'post-command-hook #'haki-modal-mode-line)

(load-theme 'haki t))
