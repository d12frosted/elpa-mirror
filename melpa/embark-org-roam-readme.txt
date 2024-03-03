This package provides an embark export buffer for org roam nodes.

;; Usage

Use `embark-select' to select all org roam nodes of interest,
then use `embark-export', which will open a special org mode
buffer containing links to the selected nodes.

;; Tips

+ You can customize whether the exported buffer is read-only using
  the `embark-org-roam-readonly' variable.

;; Credits

This package would not have been possible without the following
magnificent packages: org-roam [1] and embark [2].  Also a big
thanks to alphapapa for their Emacs package development
handbook [3]!

 [1] https://github.com/org-roam/org-roam
 [2] https://github.com/oantolin/embark
 [3] https://github.com/alphapapa/emacs-package-dev-handbook

; Installation:

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Install these required packages:

+ embark
+ org-roam

Then put this file in your load-path, and put this in your init
file:

(require 'embark-org-roam)

;;; Straight

Put this in your init file:

(use-package embark-org-roam
   :ensure t
   :straight (embark-org-roam
              :type git
              :host github
              :repo "bramadams/embark-org-roam")
   :after (org-roam embark)
   :demand t)

;;; Elpaca

Put this in your init file:

(use-package embark-org-roam
   :ensure t
   :elpaca (embark-org-roam
              :type git
              :host github
              :repo "bramadams/embark-org-roam")
   :after (org-roam embark)
   :demand t)
