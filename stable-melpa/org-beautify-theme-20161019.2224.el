;;; org-beautify-theme.el --- A sub-theme to make org-mode more beautiful.
;; Copyright (C) 2014-2016 Jonathan Arkell

;; Author: Jonathan Arkell <jonnay@jonnay.net>
;; Version: 0.3.1
;; Package-Version: 20161019.2224
;; Package-Commit: 7b7a7cbd4f25f77e8bd81783f517b2b182220fd9
;; Created: 5 Oct 2012
;; Keywords: org theme

;; This file is not part of GNU Emacs.
;; Released under the GPL v3.0

;;; Commentary:
;; * Making Org-mode Beautiful
;; ** This theme is dedicated to my wife Shell
;;   Who—in her beauty, her love, and her love for beauty—has shown me
;;   that form can enhance function.
;; * Mission
;;   - Make org mode headlines easy to read.  In any theme.
;;   - Make it look more like a published book and/or desktop app, less
;;     like angry fruit salad.
;;   - Make it awesome to live in an org buffer.
;; * Usage
;;   Load this theme over top your existing theme, and you should be
;;   golden.  If you find any incompatibilities, let me know with what
;;   theme and I will try and fix it.
;; 
;;   When loading a whole new theme overtop, org-beautify-theme will
;;   still be active with the old theme.  Just unload org-beautify-theme
;;   and then reload it, and everything will be fine again.
;; 
;; * Changelog
;;    - v0.3.1 [2016-10-19]
;;      - Fix load path issues (Thanks PierreTechoueyres!)
;;      - reverse chronological changelog, because ah-doy!
;;    - v0.2 [2016-08-08]
;;      - Better repository Location
;;      - Fix so that you can load the theme properly.
;;    - v0.1.2 :: [2014-01-06]
;;      - Add Verdana font to fall back on
;;    - v0.1.1 :: [2014-01-06]
;;      - Fix checkboxes
;;    - v0.1 :: First Release
;;          - Make the colors suck a lot less, and the buffers look a lot nicer.
;; 

;;; Code:

(deftheme org-beautify "Sub-theme to beautify org mode")

(let* ((sans-font (cond ((x-list-fonts "Lucida Grande") '(:font "Lucida Grande"))
                        ((x-list-fonts "Verdana") '(:font "Verdana"))
                        ((x-family-fonts "Sans Serif") '(:family "Sans Serif"))
                        (nil (warn "Cannot find a Sans Serif Font.  Please report at: https://github.com/jonnay/org-beautify-theme/issues"))))
       (base-font-color (face-foreground 'default  nil 'default))
       (background-color (face-background 'default nil 'default))
       (headline `(:inherit default :foreground ,base-font-color))
       (primary-color (face-foreground 'mode-line nil))
       (secondary-color (face-background 'secondary-selection nil 'region))
       (padding `(:line-width 5 :color ,background-color))
       (org-highlights `(:foreground ,base-font-color :background ,secondary-color)))
  (custom-theme-set-faces 'org-beautify
                          `(org-agenda-structure ((t (:inherit default ,@sans-font :height 2.0 :underline nil))))
                          `(org-level-8 ((t ,headline)))
                          `(org-level-7 ((t ,headline)))
                          `(org-level-6 ((t ,headline)))
                          `(org-level-5 ((t ,headline)))
                          `(org-level-4 ((t ,headline)))
                          `(org-level-3 ((t (,@headline  :box ,padding))))
                          `(org-level-2 ((t (,@headline ,@sans-font :height 1.25 :box ,padding))))
                          `(org-level-1 ((t (,@headline ,@sans-font :height 1.5 :box ,padding ))))
                          `(org-document-title ((t (:inherit org-level-1 :height 2.0 :underline nil :box ,padding))))

                          `(org-block ((t (:foreground ,base-font-color :background ,background-color :box nil))))
                          `(org-block-begin-line ((t ,org-highlights)))
                          `(org-block-end-line ((t ,org-highlights)))

                          `(org-checkbox ((t (:foreground "#000000", :background "#93a1a1" :box (:line-width -3 :color "#93a1a1" :style "released-button")))))

                          `(org-headline-done ((t (:strike-through t))))
                          `(org-done ((t (:strike-through t))))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Local Variables:
;; no-byte-compile: t
;; End:

(provide-theme 'org-beautify)
;;; org-beautify-theme.el ends here
