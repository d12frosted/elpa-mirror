;;; doneburn-theme.el --- A light theme based on Bozhidar Batsov's Zenburn

;; Copyright (C) 2018 Manuel Uberti

;; Author: Manuel Uberti <manuel.uberti@inventati.org>
;; Keywords: faces themes
;; Package-Version: 20220720.1218
;; Package-Commit: 824eae7ecf1cce08fa41f6762a27670815b7f786
;; URL: http://github.com/manuel-uberti/doneburn-emacs
;; Version: 1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a dark on light variant of Bozhidar Batsov's Zenburn theme.

;;; Credits:

;; Chris Done created the original theme. This is an updated version for modern
;; emacsen.

;;; Code:

(deftheme doneburn "The Doneburn color theme")

(defgroup doneburn-theme nil
  "Doneburn theme."
  :prefix "doneburn-theme-"
  :group 'doneburn-theme
  :link '(url-link :tag "GitHub" "http://github.com/manuel-uberti/doneburn-emacs")
  :tag "Doneburn theme")

;;;###autoload
(defcustom doneburn-override-colors-alist '()
  "Place to override default theme colors.

You can override a subset of the theme's default colors by
defining them in this alist."
  :group 'doneburn-theme
  :type '(alist
          :key-type (string :tag "Name")
          :value-type (string :tag " Hex")))

;;; Color Palette

(defvar doneburn-default-colors-alist
  '(("doneburn-fg+1"     . "#4d4d4d")
    ("doneburn-fg"       . "#444444")
    ("doneburn-fg-1"     . "#404040")
    ("doneburn-bg-2"     . "#e8e8e8")
    ("doneburn-bg-1"     . "#f9f9f9")
    ("doneburn-bg-05"    . "#eeeeee")
    ("doneburn-bg"       . "#fefefe")
    ("doneburn-bg+05"    . "#e7e7e7")
    ("doneburn-bg+1"     . "#e8e8e8")
    ("doneburn-bg+2"     . "#f2f2f2")
    ("doneburn-bg+3"     . "#ffffff")
    ("doneburn-red+2"    . "#a45ba0")
    ("doneburn-red+1"    . "#945190")
    ("doneburn-red"      . "#8f4e8b")
    ("doneburn-red-1"    . "#844880")
    ("doneburn-red-2"    . "#733f70")
    ("doneburn-red-3"    . "#633660")
    ("doneburn-red-4"    . "#522d50")
    ("doneburn-red-5"    . "#422440")
    ("doneburn-red-6"    . "#311b30")
    ("doneburn-orange"   . "#8f684e")
    ("doneburn-yellow"   . "#c3a043")
    ("doneburn-yellow-1" . "#c3a043")
    ("doneburn-yellow-2" . "#cfb56e")
    ("doneburn-green-5"  . "#11221c")
    ("doneburn-green-4"  . "#19332b")
    ("doneburn-green-3"  . "#224439")
    ("doneburn-green-2"  . "#2a5547")
    ("doneburn-green-1"  . "#326755")
    ("doneburn-green"    . "#397460")
    ("doneburn-green+1"  . "#3b7863")
    ("doneburn-green+2"  . "#438972")
    ("doneburn-green+3"  . "#4c9a80")
    ("doneburn-green+4"  . "#54ab8e")
    ("doneburn-cyan"     . "#20a6ab")
    ("doneburn-blue+3"   . "#4e8cca")
    ("doneburn-blue+2"   . "#3b80c4")
    ("doneburn-blue+1"   . "#3573b1")
    ("doneburn-blue"     . "#2e659c")
    ("doneburn-blue-1"   . "#295989")
    ("doneburn-blue-2"   . "#234d76")
    ("doneburn-blue-3"   . "#1d4062")
    ("doneburn-blue-4"   . "#17334f")
    ("doneburn-blue-5"   . "#12263b")
    ("doneburn-magenta"  . "#DC8CC3")
    ("doneburn-highlight-subtle-background" . "#f7f7f7"))
  "List of Doneburn colors.
Each element has the form (NAME . HEX).

`+N' suffixes indicate a color is lighter.
`-N' suffixes indicate a color is darker.")

(defmacro doneburn-with-color-variables (&rest body)
  "`let' bind all colors defined in `doneburn-colors-alist' around BODY.
Also bind `class' to ((class color) (min-colors 89))."
  (declare (indent 0))
  `(let ((class '((class color) (min-colors 89)))
         ,@(mapcar (lambda (cons)
                     (list (intern (car cons)) (cdr cons)))
                   (append doneburn-default-colors-alist
                           doneburn-override-colors-alist)))
     ,@body))

;;; Theme Faces
(doneburn-with-color-variables
  (custom-theme-set-faces
   'doneburn
;;;; Built-in
;;;;; basic coloring
   '(button ((t (:underline t))))
   `(link ((t (:foreground ,doneburn-yellow :underline t :weight bold))))
   `(link-visited ((t (:foreground ,doneburn-yellow-2 :underline t :weight normal))))
   `(default ((t (:foreground ,doneburn-fg :background ,doneburn-bg))))
   `(cursor ((t (:foreground ,doneburn-fg :background ,doneburn-fg+1))))
   `(escape-glyph ((t (:foreground ,doneburn-yellow :weight bold))))
   `(fringe ((t (:background ,doneburn-highlight-subtle-background))))
   `(header-line ((t (:foreground ,doneburn-yellow
                                  :background ,doneburn-bg-1
                                  :box (:line-width -1 :style released-button)))))
   `(highlight ((t (:background ,doneburn-bg-05))))
   `(success ((t (:foreground ,doneburn-green :weight bold))))
   `(warning ((t (:foreground ,doneburn-orange :weight bold))))
   `(tooltip ((t (:foreground ,doneburn-fg :background ,doneburn-bg+1))))
;;;;; compilation
   `(compilation-column-face ((t (:foreground ,doneburn-yellow))))
   `(compilation-enter-directory-face ((t (:foreground ,doneburn-green))))
   `(compilation-error-face ((t (:foreground ,doneburn-red-1 :weight bold :underline t))))
   `(compilation-face ((t (:foreground ,doneburn-fg))))
   `(compilation-info-face ((t (:foreground ,doneburn-blue))))
   `(compilation-info ((t (:foreground ,doneburn-green+4 :underline t))))
   `(compilation-leave-directory-face ((t (:foreground ,doneburn-green))))
   `(compilation-line-face ((t (:foreground ,doneburn-yellow))))
   `(compilation-line-number ((t (:foreground ,doneburn-yellow))))
   `(compilation-message-face ((t (:foreground ,doneburn-blue))))
   `(compilation-warning-face ((t (:foreground ,doneburn-orange :weight bold :underline t))))
   `(compilation-mode-line-exit ((t (:foreground ,doneburn-green+2 :weight bold))))
   `(compilation-mode-line-fail ((t (:foreground ,doneburn-red :weight bold))))
   `(compilation-mode-line-run ((t (:foreground ,doneburn-yellow :weight bold))))
;;;;; completions
   `(completions-annotations ((t (:foreground ,doneburn-fg-1))))
;;;;; eww
   '(eww-invalid-certificate ((t (:inherit error))))
   '(eww-valid-certificate   ((t (:inherit success))))
;;;;; grep
   `(grep-context-face ((t (:foreground ,doneburn-fg))))
   `(grep-error-face ((t (:foreground ,doneburn-red-1 :weight bold :underline t))))
   `(grep-hit-face ((t (:foreground ,doneburn-blue))))
   `(grep-match-face ((t (:foreground ,doneburn-orange :weight bold))))
   `(match ((t (:background ,doneburn-bg-1 :foreground ,doneburn-orange :weight bold))))
;;;;; hi-lock
   `(hi-blue    ((t (:background ,doneburn-cyan    :foreground ,doneburn-bg-1))))
   `(hi-green   ((t (:background ,doneburn-green+4 :foreground ,doneburn-bg-1))))
   `(hi-pink    ((t (:background ,doneburn-magenta :foreground ,doneburn-bg-1))))
   `(hi-yellow  ((t (:background ,doneburn-yellow  :foreground ,doneburn-bg-1))))
   `(hi-blue-b  ((t (:foreground ,doneburn-blue    :weight     bold))))
   `(hi-green-b ((t (:foreground ,doneburn-green+2 :weight     bold))))
   `(hi-red-b   ((t (:foreground ,doneburn-red     :weight     bold))))
;;;;; info
   `(Info-quoted ((t (:inherit font-lock-constant-face))))
;;;;; isearch
   `(isearch ((t (:foreground ,doneburn-yellow-2 :weight bold :background ,doneburn-bg+2))))
   `(isearch-fail ((t (:foreground ,doneburn-fg :background ,doneburn-red-4))))
   `(lazy-highlight ((t (:foreground ,doneburn-yellow-2 :weight bold :background ,doneburn-bg-05))))

   `(menu ((t (:foreground ,doneburn-fg :background ,doneburn-bg))))
   `(minibuffer-prompt ((t (:foreground ,doneburn-yellow))))
   `(mode-line
     ((,class (:foreground ,doneburn-green+1
                           :background ,doneburn-bg-1
                           :box (:line-width -1 :style released-button)))
      (t :inverse-video t)))
   `(mode-line-buffer-id ((t (:foreground ,doneburn-blue+1 :weight bold))))
   `(mode-line-inactive
     ((t (:foreground ,doneburn-green-2
                      :background ,doneburn-bg-05
                      :box (:line-width -1 :style released-button)))))
   `(region ((,class (:background ,doneburn-bg-1))
             (t :inverse-video t)))
   `(secondary-selection ((t (:background ,doneburn-bg+2))))
   `(trailing-whitespace ((t (:background ,doneburn-red))))
   `(vertical-border ((t (:foreground ,doneburn-fg))))
;;;;; font lock
   `(font-lock-builtin-face ((t (:foreground ,doneburn-fg :weight bold))))
   `(font-lock-comment-face ((t (:foreground ,doneburn-green))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,doneburn-green-2))))
   `(font-lock-constant-face ((t (:foreground ,doneburn-green+4))))
   `(font-lock-doc-face ((t (:foreground ,doneburn-green+2))))
   `(font-lock-function-name-face ((t (:foreground ,doneburn-blue))))
   `(font-lock-keyword-face ((t (:foreground ,doneburn-blue :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,doneburn-yellow :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,doneburn-blue+1))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,doneburn-yellow :weight bold))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,doneburn-green :weight bold))))
   `(font-lock-string-face ((t (:foreground ,doneburn-red))))
   `(font-lock-type-face ((t (:foreground ,doneburn-blue-1))))
   `(font-lock-variable-name-face ((t (:foreground ,doneburn-orange))))
   `(font-lock-warning-face ((t (:foreground ,doneburn-yellow-2 :weight bold))))

   `(c-annotation-face ((t (:inherit font-lock-constant-face))))
;;;;; line numbers (Emacs 26.1 and above)
   `(line-number ((t (:foreground ,doneburn-yellow-2 :background ,doneburn-bg-05))))
   `(line-number-current-line ((t (:inherit line-number :foreground ,doneburn-fg))))
;;;;; man
   '(Man-overstrike ((t (:inherit font-lock-keyword-face))))
   '(Man-underline  ((t (:inherit (font-lock-string-face underline)))))
;;;;; newsticker
   `(newsticker-date-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-default-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-enclosure-face ((t (:foreground ,doneburn-green+3))))
   `(newsticker-extra-face ((t (:foreground ,doneburn-bg+2 :height 0.8))))
   `(newsticker-feed-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-immortal-item-face ((t (:foreground ,doneburn-green))))
   `(newsticker-new-item-face ((t (:foreground ,doneburn-blue))))
   `(newsticker-obsolete-item-face ((t (:foreground ,doneburn-red))))
   `(newsticker-old-item-face ((t (:foreground ,doneburn-bg+3))))
   `(newsticker-statistics-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-treeview-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-treeview-immortal-face ((t (:foreground ,doneburn-green))))
   `(newsticker-treeview-listwindow-face ((t (:foreground ,doneburn-fg))))
   `(newsticker-treeview-new-face ((t (:foreground ,doneburn-blue :weight bold))))
   `(newsticker-treeview-obsolete-face ((t (:foreground ,doneburn-red))))
   `(newsticker-treeview-old-face ((t (:foreground ,doneburn-bg+3))))
   `(newsticker-treeview-selection-face ((t (:background ,doneburn-bg-1 :foreground ,doneburn-yellow))))
;;;;; woman
   '(woman-bold   ((t (:inherit font-lock-keyword-face))))
   '(woman-italic ((t (:inherit (font-lock-string-face italic)))))
;;;; Third-party
;;;;; ace-jump
   `(ace-jump-face-background
     ((t (:foreground ,doneburn-fg-1 :background ,doneburn-bg :inverse-video nil))))
   `(ace-jump-face-foreground
     ((t (:foreground ,doneburn-green+2 :background ,doneburn-bg :inverse-video nil))))
;;;;; ace-window
   `(aw-background-face
     ((t (:foreground ,doneburn-fg-1 :background ,doneburn-bg :inverse-video nil))))
   `(aw-leading-char-face ((t (:inherit aw-mode-line-face))))
;;;;; android mode
   `(android-mode-debug-face ((t (:foreground ,doneburn-green+1))))
   `(android-mode-error-face ((t (:foreground ,doneburn-orange :weight bold))))
   `(android-mode-info-face ((t (:foreground ,doneburn-fg))))
   `(android-mode-verbose-face ((t (:foreground ,doneburn-green))))
   `(android-mode-warning-face ((t (:foreground ,doneburn-yellow))))
;;;;; anzu
   `(anzu-mode-line ((t (:foreground ,doneburn-cyan :weight bold))))
   `(anzu-mode-line-no-match ((t (:foreground ,doneburn-red :weight bold))))
   `(anzu-match-1 ((t (:foreground ,doneburn-bg :background ,doneburn-green))))
   `(anzu-match-2 ((t (:foreground ,doneburn-bg :background ,doneburn-orange))))
   `(anzu-match-3 ((t (:foreground ,doneburn-bg :background ,doneburn-blue))))
   `(anzu-replace-to ((t (:inherit anzu-replace-highlight :foreground ,doneburn-yellow))))
;;;;; auctex
   `(font-latex-bold-face ((t (:inherit bold))))
   `(font-latex-warning-face ((t (:foreground nil :inherit font-lock-warning-face))))
   `(font-latex-sectioning-5-face ((t (:foreground ,doneburn-red :weight bold ))))
   `(font-latex-sedate-face ((t (:foreground ,doneburn-yellow))))
   `(font-latex-italic-face ((t (:foreground ,doneburn-cyan :slant italic))))
   `(font-latex-string-face ((t (:inherit ,font-lock-string-face))))
   `(font-latex-math-face ((t (:foreground ,doneburn-orange))))
   `(font-latex-script-char-face ((t (:foreground ,doneburn-orange))))
;;;;; avy
   `(avy-background-face
     ((t (:foreground ,doneburn-fg-1 :background ,doneburn-bg :inverse-video nil))))
   `(avy-lead-face-0
     ((t (:foreground ,doneburn-green+3 :background ,doneburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-1
     ((t (:foreground ,doneburn-yellow :background ,doneburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face-2
     ((t (:foreground ,doneburn-red+1 :background ,doneburn-bg :inverse-video nil :weight bold))))
   `(avy-lead-face
     ((t (:foreground ,doneburn-cyan :background ,doneburn-bg :inverse-video nil :weight bold))))
;;;;; company-mode
   `(company-tooltip ((t (:foreground ,doneburn-fg+1 :background ,doneburn-bg))))
   `(company-tooltip-annotation ((t (:foreground ,doneburn-orange :background ,doneburn-bg+1))))
   `(company-tooltip-annotation-selection ((t (:foreground ,doneburn-orange :background ,doneburn-bg-1))))
   `(company-tooltip-selection ((t (:foreground ,doneburn-fg :background ,doneburn-bg-1))))
   `(company-tooltip-mouse ((t (:background ,doneburn-bg-1))))
   `(company-tooltip-common ((t (:foreground ,doneburn-red+2))))
   `(company-tooltip-common-selection ((t (:foreground ,doneburn-red+2))))
   `(company-scrollbar-fg ((t (:background ,doneburn-bg-1))))
   `(company-scrollbar-bg ((t (:background ,doneburn-bg+2))))
   `(company-preview ((t (:background ,doneburn-red+2))))
   `(company-preview-common ((t (:foreground ,doneburn-red+2 :background ,doneburn-bg-1))))
;;;;; bm
   `(bm-face ((t (:background ,doneburn-yellow-1 :foreground ,doneburn-bg))))
   `(bm-fringe-face ((t (:background ,doneburn-yellow-1 :foreground ,doneburn-bg))))
   `(bm-fringe-persistent-face ((t (:background ,doneburn-green-2 :foreground ,doneburn-bg))))
   `(bm-persistent-face ((t (:background ,doneburn-green-2 :foreground ,doneburn-bg))))
;;;;; cider
   `(cider-result-overlay-face ((t (:background unspecified))))
   `(cider-enlightened-face ((t (:box (:color ,doneburn-orange :line-width -1)))))
   `(cider-enlightened-local-face ((t (:weight bold :foreground ,doneburn-green+1))))
   `(cider-deprecated-face ((t (:background ,doneburn-yellow-2))))
   `(cider-instrumented-face ((t (:box (:color ,doneburn-red :line-width -1)))))
   `(cider-traced-face ((t (:box (:color ,doneburn-cyan :line-width -1)))))
   `(cider-test-failure-face ((t (:background ,doneburn-red-4))))
   `(cider-test-error-face ((t (:background ,doneburn-magenta))))
   `(cider-test-success-face ((t (:background ,doneburn-green-2))))
   `(cider-fringe-good-face ((t (:foreground ,doneburn-green+4))))
;;;;; circe
   `(circe-highlight-nick-face ((t (:foreground ,doneburn-cyan))))
   `(circe-my-message-face ((t (:foreground ,doneburn-fg))))
   `(circe-fool-face ((t (:foreground ,doneburn-red+1))))
   `(circe-topic-diff-removed-face ((t (:foreground ,doneburn-red :weight bold))))
   `(circe-originator-face ((t (:foreground ,doneburn-fg))))
   `(circe-server-face ((t (:foreground ,doneburn-green))))
   `(circe-topic-diff-new-face ((t (:foreground ,doneburn-orange :weight bold))))
   `(circe-prompt-face ((t (:foreground ,doneburn-orange :background ,doneburn-bg :weight bold))))
;;;;; context-coloring
   `(context-coloring-level-0-face ((t :foreground ,doneburn-fg)))
   `(context-coloring-level-1-face ((t :foreground ,doneburn-cyan)))
   `(context-coloring-level-2-face ((t :foreground ,doneburn-green+4)))
   `(context-coloring-level-3-face ((t :foreground ,doneburn-yellow)))
   `(context-coloring-level-4-face ((t :foreground ,doneburn-orange)))
   `(context-coloring-level-5-face ((t :foreground ,doneburn-magenta)))
   `(context-coloring-level-6-face ((t :foreground ,doneburn-blue+1)))
   `(context-coloring-level-7-face ((t :foreground ,doneburn-green+2)))
   `(context-coloring-level-8-face ((t :foreground ,doneburn-yellow-2)))
   `(context-coloring-level-9-face ((t :foreground ,doneburn-red+1)))
;;;;; coq
   `(coq-solve-tactics-face ((t (:foreground nil :inherit font-lock-constant-face))))
;;;;; ctable
   `(ctbl:face-cell-select ((t (:background ,doneburn-blue :foreground ,doneburn-bg))))
   `(ctbl:face-continue-bar ((t (:background ,doneburn-bg-05 :foreground ,doneburn-bg))))
   `(ctbl:face-row-select ((t (:background ,doneburn-cyan :foreground ,doneburn-bg))))
;;;;; debbugs
   `(debbugs-gnu-done ((t (:foreground ,doneburn-fg-1))))
   `(debbugs-gnu-handled ((t (:foreground ,doneburn-green))))
   `(debbugs-gnu-new ((t (:foreground ,doneburn-red))))
   `(debbugs-gnu-pending ((t (:foreground ,doneburn-blue))))
   `(debbugs-gnu-stale ((t (:foreground ,doneburn-orange))))
   `(debbugs-gnu-tagged ((t (:foreground ,doneburn-red))))
;;;;; diff
   `(diff-added          ((t (:background ,doneburn-green-5 :foreground ,doneburn-green+2))))
   `(diff-changed        ((t (:background "#555511" :foreground ,doneburn-yellow-1))))
   `(diff-removed        ((t (:background ,doneburn-red-6 :foreground ,doneburn-red+1))))
   `(diff-refine-added   ((t (:background ,doneburn-green-4 :foreground ,doneburn-green+3))))
   `(diff-refine-changed ((t (:background "#888811" :foreground ,doneburn-yellow))))
   `(diff-refine-removed ((t (:background ,doneburn-red-5 :foreground ,doneburn-red+2))))
   `(diff-header ((,class (:background ,doneburn-bg+2))
                  (t (:background ,doneburn-fg :foreground ,doneburn-bg))))
   `(diff-file-header
     ((,class (:background ,doneburn-bg+2 :foreground ,doneburn-fg :weight bold))
      (t (:background ,doneburn-fg :foreground ,doneburn-bg :weight bold))))
;;;;; diff-hl
   `(diff-hl-change ((,class (:foreground ,doneburn-blue :background ,doneburn-blue-2))))
   `(diff-hl-delete ((,class (:foreground ,doneburn-red+1 :background ,doneburn-red-1))))
   `(diff-hl-insert ((,class (:foreground ,doneburn-green+1 :background ,doneburn-green-2))))
;;;;; dim-autoload
   `(dim-autoload-cookie-line ((t :foreground ,doneburn-bg+1)))
;;;;; dired-async
   `(dired-async-failures ((t (:foreground ,doneburn-red :weight bold))))
   `(dired-async-message ((t (:foreground ,doneburn-yellow :weight bold))))
   `(dired-async-mode-message ((t (:foreground ,doneburn-yellow))))
;;;;; diredfl
   `(diredfl-compressed-file-suffix ((t (:foreground ,doneburn-orange))))
   `(diredfl-date-time ((t (:foreground ,doneburn-magenta))))
   `(diredfl-deletion ((t (:foreground ,doneburn-yellow))))
   `(diredfl-deletion-file-name ((t (:foreground ,doneburn-red))))
   `(diredfl-dir-heading ((t (:foreground ,doneburn-blue :background ,doneburn-bg-1))))
   `(diredfl-dir-priv ((t (:foreground ,doneburn-cyan))))
   `(diredfl-exec-priv ((t (:foreground ,doneburn-red))))
   `(diredfl-executable-tag ((t (:foreground ,doneburn-green+1))))
   `(diredfl-file-name ((t (:foreground ,doneburn-blue))))
   `(diredfl-file-suffix ((t (:foreground ,doneburn-green))))
   `(diredfl-flag-mark ((t (:foreground ,doneburn-yellow))))
   `(diredfl-flag-mark-line ((t (:foreground ,doneburn-orange))))
   `(diredfl-ignored-file-name ((t (:foreground ,doneburn-red))))
   `(diredfl-link-priv ((t (:foreground ,doneburn-yellow))))
   `(diredfl-no-priv ((t (:foreground ,doneburn-fg))))
   `(diredfl-number ((t (:foreground ,doneburn-green+1))))
   `(diredfl-other-priv ((t (:foreground ,doneburn-yellow-1))))
   `(diredfl-rare-priv ((t (:foreground ,doneburn-red-1))))
   `(diredfl-read-priv ((t (:foreground ,doneburn-green-1))))
   `(diredfl-symlink ((t (:foreground ,doneburn-yellow))))
   `(diredfl-write-priv ((t (:foreground ,doneburn-magenta))))
;;;;; ediff
   `(ediff-current-diff-A ((t (:inherit diff-removed))))
   `(ediff-current-diff-Ancestor ((t (:inherit ediff-current-diff-A))))
   `(ediff-current-diff-B ((t (:inherit diff-added))))
   `(ediff-current-diff-C ((t (:foreground ,doneburn-blue+2 :background ,doneburn-blue-5))))
   `(ediff-even-diff-A ((t (:background ,doneburn-bg+1))))
   `(ediff-even-diff-Ancestor ((t (:background ,doneburn-bg+1))))
   `(ediff-even-diff-B ((t (:background ,doneburn-bg+1))))
   `(ediff-even-diff-C ((t (:background ,doneburn-bg+1))))
   `(ediff-fine-diff-A ((t (:inherit diff-refine-removed :weight bold))))
   `(ediff-fine-diff-Ancestor ((t (:inherit ediff-fine-diff-A))))
   `(ediff-fine-diff-B ((t (:inherit diff-refine-added :weight bold))))
   `(ediff-fine-diff-C ((t (:foreground ,doneburn-blue+3 :background ,doneburn-blue-4 :weight bold))))
   `(ediff-odd-diff-A ((t (:background ,doneburn-bg+2))))
   `(ediff-odd-diff-Ancestor ((t (:inherit ediff-odd-diff-A))))
   `(ediff-odd-diff-B ((t (:inherit ediff-odd-diff-A))))
   `(ediff-odd-diff-C ((t (:inherit ediff-odd-diff-A))))
;;;;; elfeed
   `(elfeed-log-error-level-face ((t (:foreground ,doneburn-red))))
   `(elfeed-log-info-level-face ((t (:foreground ,doneburn-blue))))
   `(elfeed-log-warn-level-face ((t (:foreground ,doneburn-yellow))))
   `(elfeed-search-date-face ((t (:foreground ,doneburn-yellow-1 :underline t
                                              :weight bold))))
   `(elfeed-search-tag-face ((t (:foreground ,doneburn-green))))
   `(elfeed-search-feed-face ((t (:foreground ,doneburn-cyan))))
;;;;; emacs-w3m
   `(w3m-anchor ((t (:foreground ,doneburn-yellow :underline t
                                 :weight bold))))
   `(w3m-arrived-anchor ((t (:foreground ,doneburn-yellow-2
                                         :underline t :weight normal))))
   `(w3m-form ((t (:foreground ,doneburn-red-1 :underline t))))
   `(w3m-header-line-location-title ((t (:foreground ,doneburn-yellow
                                                     :underline t :weight bold))))
   '(w3m-history-current-url ((t (:inherit match))))
   `(w3m-lnum ((t (:foreground ,doneburn-green+2 :background ,doneburn-bg))))
   `(w3m-lnum-match ((t (:background ,doneburn-bg-1
                                     :foreground ,doneburn-orange
                                     :weight bold))))
   `(w3m-lnum-minibuffer-prompt ((t (:foreground ,doneburn-yellow))))
;;;;; erc
   `(erc-action-face ((t (:inherit erc-default-face))))
   `(erc-bold-face ((t (:weight bold))))
   `(erc-current-nick-face ((t (:foreground ,doneburn-blue :weight bold))))
   `(erc-dangerous-host-face ((t (:inherit font-lock-warning-face))))
   `(erc-default-face ((t (:foreground ,doneburn-fg))))
   `(erc-direct-msg-face ((t (:inherit erc-default-face))))
   `(erc-error-face ((t (:inherit font-lock-warning-face))))
   `(erc-fool-face ((t (:inherit erc-default-face))))
   `(erc-highlight-face ((t (:inherit hover-highlight))))
   `(erc-input-face ((t (:foreground ,doneburn-yellow))))
   `(erc-keyword-face ((t (:foreground ,doneburn-blue :weight bold))))
   `(erc-nick-default-face ((t (:foreground ,doneburn-yellow :weight bold))))
   `(erc-my-nick-face ((t (:foreground ,doneburn-red :weight bold))))
   `(erc-nick-msg-face ((t (:inherit erc-default-face))))
   `(erc-notice-face ((t (:foreground ,doneburn-green))))
   `(erc-pal-face ((t (:foreground ,doneburn-orange :weight bold))))
   `(erc-prompt-face ((t (:foreground ,doneburn-orange :background ,doneburn-bg :weight bold))))
   `(erc-timestamp-face ((t (:foreground ,doneburn-green+4))))
   `(erc-underline-face ((t (:underline t))))
;;;;; eros
   `(eros-result-overlay-face ((t (:background unspecified))))
;;;;; ert
   `(ert-test-result-expected ((t (:foreground ,doneburn-green+4 :background ,doneburn-bg))))
   `(ert-test-result-unexpected ((t (:foreground ,doneburn-red :background ,doneburn-bg))))
;;;;; eshell
   `(eshell-prompt ((t (:foreground ,doneburn-yellow :weight bold))))
   `(eshell-ls-archive ((t (:foreground ,doneburn-red-1 :weight bold))))
   `(eshell-ls-backup ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-clutter ((t (:inherit font-lock-comment-face))))
   `(eshell-ls-directory ((t (:foreground ,doneburn-blue+1 :weight bold))))
   `(eshell-ls-executable ((t (:foreground ,doneburn-red+1 :weight bold))))
   `(eshell-ls-unreadable ((t (:foreground ,doneburn-fg))))
   `(eshell-ls-missing ((t (:inherit font-lock-warning-face))))
   `(eshell-ls-product ((t (:inherit font-lock-doc-face))))
   `(eshell-ls-special ((t (:foreground ,doneburn-yellow :weight bold))))
   `(eshell-ls-symlink ((t (:foreground ,doneburn-cyan :weight bold))))
;;;;; flx
   `(flx-highlight-face ((t (:foreground ,doneburn-green+2 :weight bold))))
;;;;; flycheck
   `(flycheck-error
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-red-1) :inherit unspecified))
      (t (:foreground ,doneburn-red-1 :weight bold :underline t))))
   `(flycheck-warning
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-yellow) :inherit unspecified))
      (t (:foreground ,doneburn-yellow :weight bold :underline t))))
   `(flycheck-info
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-cyan) :inherit unspecified))
      (t (:foreground ,doneburn-cyan :weight bold :underline t))))
   `(flycheck-fringe-error ((t (:foreground ,doneburn-red-1 :weight bold))))
   `(flycheck-fringe-warning ((t (:foreground ,doneburn-yellow :weight bold))))
   `(flycheck-fringe-info ((t (:foreground ,doneburn-cyan :weight bold))))
;;;;; flymake
   `(flymake-errline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-red)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,doneburn-red-1 :weight bold :underline t))))
   `(flymake-warnline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-orange)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,doneburn-orange :weight bold :underline t))))
   `(flymake-infoline
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-green)
                   :inherit unspecified :foreground unspecified :background unspecified))
      (t (:foreground ,doneburn-green-2 :weight bold :underline t))))
;;;;; flyspell
   `(flyspell-duplicate
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-orange) :inherit unspecified))
      (t (:foreground ,doneburn-orange :weight bold :underline t))))
   `(flyspell-incorrect
     ((((supports :underline (:style wave)))
       (:underline (:style wave :color ,doneburn-red) :inherit unspecified))
      (t (:foreground ,doneburn-red-1 :weight bold :underline t))))
;;;;; git-commit
   `(git-commit-comment-action  ((,class (:foreground ,doneburn-green+1 :weight bold))))
   `(git-commit-comment-branch  ((,class (:foreground ,doneburn-blue+1  :weight bold)))) ; obsolete
   `(git-commit-comment-branch-local  ((,class (:foreground ,doneburn-blue+1  :weight bold))))
   `(git-commit-comment-branch-remote ((,class (:foreground ,doneburn-green  :weight bold))))
   `(git-commit-comment-heading ((,class (:foreground ,doneburn-yellow  :weight bold))))
;;;;; git-gutter
   `(git-gutter:added ((t (:foreground ,doneburn-green :weight bold :inverse-video t))))
   `(git-gutter:deleted ((t (:foreground ,doneburn-red :weight bold :inverse-video t))))
   `(git-gutter:modified ((t (:foreground ,doneburn-magenta :weight bold :inverse-video t))))
   `(git-gutter:unchanged ((t (:foreground ,doneburn-fg :weight bold :inverse-video t))))
;;;;; git-gutter-fr
   `(git-gutter-fr:added ((t (:foreground ,doneburn-green  :weight bold))))
   `(git-gutter-fr:deleted ((t (:foreground ,doneburn-red :weight bold))))
   `(git-gutter-fr:modified ((t (:foreground ,doneburn-magenta :weight bold))))
;;;;; git-rebase
   `(git-rebase-hash ((t (:foreground, doneburn-orange))))
;;;;; gnus
   `(gnus-group-mail-1 ((t (:weight bold :inherit gnus-group-mail-1-empty))))
   `(gnus-group-mail-1-empty ((t (:inherit gnus-group-news-1-empty))))
   `(gnus-group-mail-2 ((t (:weight bold :inherit gnus-group-mail-2-empty))))
   `(gnus-group-mail-2-empty ((t (:inherit gnus-group-news-2-empty))))
   `(gnus-group-mail-3 ((t (:weight bold :inherit gnus-group-mail-3-empty))))
   `(gnus-group-mail-3-empty ((t (:inherit gnus-group-news-3-empty))))
   `(gnus-group-mail-4 ((t (:weight bold :inherit gnus-group-mail-4-empty))))
   `(gnus-group-mail-4-empty ((t (:inherit gnus-group-news-4-empty))))
   `(gnus-group-mail-5 ((t (:weight bold :inherit gnus-group-mail-5-empty))))
   `(gnus-group-mail-5-empty ((t (:inherit gnus-group-news-5-empty))))
   `(gnus-group-mail-6 ((t (:weight bold :inherit gnus-group-mail-6-empty))))
   `(gnus-group-mail-6-empty ((t (:inherit gnus-group-news-6-empty))))
   `(gnus-group-mail-low ((t (:weight bold :inherit gnus-group-mail-low-empty))))
   `(gnus-group-mail-low-empty ((t (:inherit gnus-group-news-low-empty))))
   `(gnus-group-news-1 ((t (:weight bold :inherit gnus-group-news-1-empty))))
   `(gnus-group-news-2 ((t (:weight bold :inherit gnus-group-news-2-empty))))
   `(gnus-group-news-3 ((t (:weight bold :inherit gnus-group-news-3-empty))))
   `(gnus-group-news-4 ((t (:weight bold :inherit gnus-group-news-4-empty))))
   `(gnus-group-news-5 ((t (:weight bold :inherit gnus-group-news-5-empty))))
   `(gnus-group-news-6 ((t (:weight bold :inherit gnus-group-news-6-empty))))
   `(gnus-group-news-low ((t (:weight bold :inherit gnus-group-news-low-empty))))
   `(gnus-header-content ((t (:inherit message-header-other))))
   `(gnus-header-from ((t (:inherit message-header-to))))
   `(gnus-header-name ((t (:inherit message-header-name))))
   `(gnus-header-newsgroups ((t (:inherit message-header-other))))
   `(gnus-header-subject ((t (:inherit message-header-subject))))
   `(gnus-server-opened ((t (:foreground ,doneburn-green+2 :weight bold))))
   `(gnus-server-denied ((t (:foreground ,doneburn-red+1 :weight bold))))
   `(gnus-server-closed ((t (:foreground ,doneburn-blue :slant italic))))
   `(gnus-server-offline ((t (:foreground ,doneburn-yellow :weight bold))))
   `(gnus-server-agent ((t (:foreground ,doneburn-blue :weight bold))))
   `(gnus-summary-cancelled ((t (:foreground ,doneburn-orange))))
   `(gnus-summary-high-ancient ((t (:foreground ,doneburn-blue))))
   `(gnus-summary-high-read ((t (:foreground ,doneburn-green :weight bold))))
   `(gnus-summary-high-ticked ((t (:foreground ,doneburn-orange :weight bold))))
   `(gnus-summary-high-unread ((t (:foreground ,doneburn-fg :weight bold))))
   `(gnus-summary-low-ancient ((t (:foreground ,doneburn-blue))))
   `(gnus-summary-low-read ((t (:foreground ,doneburn-green))))
   `(gnus-summary-low-ticked ((t (:foreground ,doneburn-orange :weight bold))))
   `(gnus-summary-low-unread ((t (:foreground ,doneburn-fg))))
   `(gnus-summary-normal-ancient ((t (:foreground ,doneburn-blue))))
   `(gnus-summary-normal-read ((t (:foreground ,doneburn-green))))
   `(gnus-summary-normal-ticked ((t (:foreground ,doneburn-orange :weight bold))))
   `(gnus-summary-normal-unread ((t (:foreground ,doneburn-fg))))
   `(gnus-summary-selected ((t (:foreground ,doneburn-yellow :weight bold))))
   `(gnus-cite-1 ((t (:foreground ,doneburn-blue))))
   `(gnus-cite-10 ((t (:foreground ,doneburn-yellow-1))))
   `(gnus-cite-11 ((t (:foreground ,doneburn-yellow))))
   `(gnus-cite-2 ((t (:foreground ,doneburn-blue-1))))
   `(gnus-cite-3 ((t (:foreground ,doneburn-blue-2))))
   `(gnus-cite-4 ((t (:foreground ,doneburn-green+2))))
   `(gnus-cite-5 ((t (:foreground ,doneburn-green+1))))
   `(gnus-cite-6 ((t (:foreground ,doneburn-green))))
   `(gnus-cite-7 ((t (:foreground ,doneburn-red))))
   `(gnus-cite-8 ((t (:foreground ,doneburn-red-1))))
   `(gnus-cite-9 ((t (:foreground ,doneburn-red-2))))
   `(gnus-group-news-1-empty ((t (:foreground ,doneburn-yellow))))
   `(gnus-group-news-2-empty ((t (:foreground ,doneburn-green+3))))
   `(gnus-group-news-3-empty ((t (:foreground ,doneburn-green+1))))
   `(gnus-group-news-4-empty ((t (:foreground ,doneburn-blue-2))))
   `(gnus-group-news-5-empty ((t (:foreground ,doneburn-blue-3))))
   `(gnus-group-news-6-empty ((t (:foreground ,doneburn-bg+2))))
   `(gnus-group-news-low-empty ((t (:foreground ,doneburn-bg+2))))
   `(gnus-signature ((t (:foreground ,doneburn-yellow))))
   `(gnus-x ((t (:background ,doneburn-fg :foreground ,doneburn-bg))))
   `(mm-uu-extract ((t (:background ,doneburn-bg-05 :foreground ,doneburn-green+1))))
;;;;; hl-line-mode
   `(hl-line-face ((,class (:background ,doneburn-bg-05))
                   (t :weight bold)))
   `(hl-line ((,class (:background ,doneburn-bg-05)) ; old emacsen
              (t :weight bold)))
;;;;; hl-sexp
   `(hl-sexp-face ((,class (:background ,doneburn-bg+1))
                   (t :weight bold)))
;;;;; hydra
   `(hydra-face-red ((t (:foreground ,doneburn-red-1 :background ,doneburn-bg))))
   `(hydra-face-amaranth ((t (:foreground ,doneburn-red-3 :background ,doneburn-bg))))
   `(hydra-face-blue ((t (:foreground ,doneburn-blue :background ,doneburn-bg))))
   `(hydra-face-pink ((t (:foreground ,doneburn-magenta :background ,doneburn-bg))))
   `(hydra-face-teal ((t (:foreground ,doneburn-cyan :background ,doneburn-bg))))
;;;;; info+
   `(info-command-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-orange))))
   `(info-constant-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-magenta))))
   `(info-double-quoted-name ((t (:inherit font-lock-comment-face))))
   `(info-file ((t (:background ,doneburn-bg-1 :foreground ,doneburn-yellow))))
   `(info-function-ref-item ((t (:background ,doneburn-bg-1 :inherit font-lock-function-name-face))))
   `(info-macro-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-yellow))))
   `(info-menu ((t (:foreground ,doneburn-yellow))))
   `(info-quoted-name ((t (:inherit font-lock-constant-face))))
   `(info-reference-item ((t (:background ,doneburn-bg-1))))
   `(info-single-quote ((t (:inherit font-lock-keyword-face))))
   `(info-special-form-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-yellow))))
   `(info-string ((t (:inherit font-lock-string-face))))
   `(info-syntax-class-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-blue+1))))
   `(info-user-option-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-red))))
   `(info-variable-ref-item ((t (:background ,doneburn-bg-1 :foreground ,doneburn-orange))))
;;;;; ivy
   `(ivy-confirm-face ((t (:foreground ,doneburn-green :background ,doneburn-bg))))
   `(ivy-current-match ((t (:foreground ,doneburn-yellow :weight bold :underline t))))
   `(ivy-cursor ((t (:foreground ,doneburn-bg :background ,doneburn-fg))))
   `(ivy-match-required-face ((t (:foreground ,doneburn-red :background ,doneburn-bg))))
   `(ivy-minibuffer-match-face-1 ((t (:background ,doneburn-bg+1))))
   `(ivy-minibuffer-match-face-2 ((t (:background ,doneburn-red+2))))
   `(ivy-minibuffer-match-face-3 ((t (:background ,doneburn-red))))
   `(ivy-minibuffer-match-face-4 ((t (:background ,doneburn-red+1))))
   `(ivy-remote ((t (:foreground ,doneburn-blue :background ,doneburn-bg))))
   `(ivy-subdir ((t (:foreground ,doneburn-yellow :background ,doneburn-bg))))
;;;;; ido-mode
   `(ido-first-match ((t (:foreground ,doneburn-yellow :weight bold))))
   `(ido-only-match ((t (:foreground ,doneburn-orange :weight bold))))
   `(ido-subdir ((t (:foreground ,doneburn-yellow))))
   `(ido-indicator ((t (:foreground ,doneburn-yellow :background ,doneburn-red-4))))
;;;;; iedit-mode
   `(iedit-occurrence ((t (:background ,doneburn-bg+2 :weight bold))))
;;;;; jabber-mode
   `(jabber-roster-user-away ((t (:foreground ,doneburn-green+2))))
   `(jabber-roster-user-online ((t (:foreground ,doneburn-blue-1))))
   `(jabber-roster-user-dnd ((t (:foreground ,doneburn-red+1))))
   `(jabber-roster-user-xa ((t (:foreground ,doneburn-magenta))))
   `(jabber-roster-user-chatty ((t (:foreground ,doneburn-orange))))
   `(jabber-roster-user-error ((t (:foreground ,doneburn-red+1))))
   `(jabber-rare-time-face ((t (:foreground ,doneburn-green+1))))
   `(jabber-chat-prompt-local ((t (:foreground ,doneburn-blue-1))))
   `(jabber-chat-prompt-foreign ((t (:foreground ,doneburn-red+1))))
   `(jabber-chat-prompt-system ((t (:foreground ,doneburn-green+3))))
   `(jabber-activity-face((t (:foreground ,doneburn-red+1))))
   `(jabber-activity-personal-face ((t (:foreground ,doneburn-blue+1))))
   `(jabber-title-small ((t (:height 1.1 :weight bold))))
   `(jabber-title-medium ((t (:height 1.2 :weight bold))))
   `(jabber-title-large ((t (:height 1.3 :weight bold))))
;;;;; js2-mode
   `(js2-warning ((t (:underline ,doneburn-orange))))
   `(js2-error ((t (:foreground ,doneburn-red :weight bold))))
   `(js2-jsdoc-tag ((t (:foreground ,doneburn-green-2))))
   `(js2-jsdoc-type ((t (:foreground ,doneburn-green+2))))
   `(js2-jsdoc-value ((t (:foreground ,doneburn-green+3))))
   `(js2-function-param ((t (:foreground, doneburn-orange))))
   `(js2-external-variable ((t (:foreground ,doneburn-orange))))
;;;;; additional js2 mode attributes for better syntax highlighting
   `(js2-instance-member ((t (:foreground ,doneburn-green-2))))
   `(js2-jsdoc-html-tag-delimiter ((t (:foreground ,doneburn-orange))))
   `(js2-jsdoc-html-tag-name ((t (:foreground ,doneburn-red-1))))
   `(js2-object-property ((t (:foreground ,doneburn-blue+1))))
   `(js2-magic-paren ((t (:foreground ,doneburn-blue-5))))
   `(js2-private-function-call ((t (:foreground ,doneburn-cyan))))
   `(js2-function-call ((t (:foreground ,doneburn-cyan))))
   `(js2-private-member ((t (:foreground ,doneburn-blue-1))))
   `(js2-keywords ((t (:foreground ,doneburn-magenta))))
;;;;; linum-mode
   `(linum ((t (:foreground ,doneburn-green+2 :background ,doneburn-bg))))
;;;;; lispy
   `(lispy-command-name-face ((t (:background ,doneburn-bg-05 :inherit font-lock-function-name-face))))
   `(lispy-cursor-face ((t (:foreground ,doneburn-bg :background ,doneburn-fg))))
   `(lispy-face-hint ((t (:inherit highlight :foreground ,doneburn-yellow))))
;;;;; ruler-mode
   `(ruler-mode-column-number ((t (:inherit 'ruler-mode-default :foreground ,doneburn-fg))))
   `(ruler-mode-fill-column ((t (:inherit 'ruler-mode-default :foreground ,doneburn-yellow))))
   `(ruler-mode-goal-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-comment-column ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-tab-stop ((t (:inherit 'ruler-mode-fill-column))))
   `(ruler-mode-current-column ((t (:foreground ,doneburn-yellow :box t))))
   `(ruler-mode-default ((t (:foreground ,doneburn-green+2 :background ,doneburn-bg))))
;;;;; macrostep
   `(macrostep-gensym-1
     ((t (:foreground ,doneburn-green+2 :background ,doneburn-bg-1))))
   `(macrostep-gensym-2
     ((t (:foreground ,doneburn-red+1 :background ,doneburn-bg-1))))
   `(macrostep-gensym-3
     ((t (:foreground ,doneburn-blue+1 :background ,doneburn-bg-1))))
   `(macrostep-gensym-4
     ((t (:foreground ,doneburn-magenta :background ,doneburn-bg-1))))
   `(macrostep-gensym-5
     ((t (:foreground ,doneburn-yellow :background ,doneburn-bg-1))))
   `(macrostep-expansion-highlight-face
     ((t (:inherit highlight))))
   `(macrostep-macro-face
     ((t (:underline t))))
;;;;; magit
;;;;;; headings and diffs
   `(magit-section-highlight           ((t (:background ,doneburn-bg+05))))
   `(magit-section-heading             ((t (:foreground ,doneburn-yellow :weight bold))))
   `(magit-section-heading-selection   ((t (:foreground ,doneburn-orange :weight bold))))

   `(magit-diff-added ((t (:inherit diff-added))))
   `(magit-diff-added-highlight ((t (:inherit diff-refine-added))))
   `(magit-diff-removed ((t (:inherit diff-removed))))
   `(magit-diff-removed-highlight ((t (:inherit diff-refine-removed))))

   `(magit-diff-file-heading           ((t (:weight bold))))
   `(magit-diff-file-heading-highlight ((t (:background ,doneburn-bg+05  :weight bold))))
   `(magit-diff-file-heading-selection ((t (:background ,doneburn-bg+05
                                                        :foreground ,doneburn-orange :weight bold))))
   `(magit-diff-hunk-heading           ((t (:background ,doneburn-bg+1))))
   `(magit-diff-hunk-heading-highlight ((t (:background ,doneburn-bg+2))))
   `(magit-diff-hunk-heading-selection ((t (:background ,doneburn-bg+2
                                                        :foreground ,doneburn-orange))))
   `(magit-diff-lines-heading          ((t (:background ,doneburn-orange
                                                        :foreground ,doneburn-bg+2))))
   `(magit-diff-context-highlight      ((t (:background ,doneburn-bg+05
                                                        :foreground "grey70"))))
   `(magit-diffstat-added   ((t (:foreground ,doneburn-green+4))))
   `(magit-diffstat-removed ((t (:foreground ,doneburn-red))))
;;;;;; popup
   `(magit-popup-heading             ((t (:foreground ,doneburn-yellow  :weight bold))))
   `(magit-popup-key                 ((t (:foreground ,doneburn-green-2 :weight bold))))
   `(magit-popup-argument            ((t (:foreground ,doneburn-green   :weight bold))))
   `(magit-popup-disabled-argument   ((t (:foreground ,doneburn-fg-1    :weight normal))))
   `(magit-popup-option-value        ((t (:foreground ,doneburn-blue-2  :weight bold))))
;;;;;; process
   `(magit-process-ok    ((t (:foreground ,doneburn-green  :weight bold))))
   `(magit-process-ng    ((t (:foreground ,doneburn-red    :weight bold))))
;;;;;; log
   `(magit-log-author    ((t (:foreground ,doneburn-orange))))
   `(magit-log-date      ((t (:foreground ,doneburn-fg-1))))
   `(magit-log-graph     ((t (:foreground ,doneburn-fg+1))))
;;;;;; sequence
   `(magit-sequence-pick ((t (:foreground ,doneburn-yellow-2))))
   `(magit-sequence-stop ((t (:foreground ,doneburn-green))))
   `(magit-sequence-part ((t (:foreground ,doneburn-yellow))))
   `(magit-sequence-head ((t (:foreground ,doneburn-blue))))
   `(magit-sequence-drop ((t (:foreground ,doneburn-red))))
   `(magit-sequence-done ((t (:foreground ,doneburn-fg-1))))
   `(magit-sequence-onto ((t (:foreground ,doneburn-fg-1))))
;;;;;; bisect
   `(magit-bisect-good ((t (:foreground ,doneburn-green))))
   `(magit-bisect-skip ((t (:foreground ,doneburn-yellow))))
   `(magit-bisect-bad  ((t (:foreground ,doneburn-red))))
;;;;;; blame
   `(magit-blame-heading ((t (:background ,doneburn-bg-1 :foreground ,doneburn-blue-2))))
   `(magit-blame-hash    ((t (:background ,doneburn-bg-1 :foreground ,doneburn-blue-2))))
   `(magit-blame-name    ((t (:background ,doneburn-bg-1 :foreground ,doneburn-orange))))
   `(magit-blame-date    ((t (:background ,doneburn-bg-1 :foreground ,doneburn-orange))))
   `(magit-blame-summary ((t (:background ,doneburn-bg-1 :foreground ,doneburn-blue-2
                                          :weight bold))))
;;;;;; references etc
   `(magit-dimmed         ((t (:foreground ,doneburn-fg+1))))
   `(magit-hash           ((t (:foreground ,doneburn-fg+1))))
   `(magit-tag            ((t (:foreground ,doneburn-orange :weight bold))))
   `(magit-branch-remote  ((t (:foreground ,doneburn-green  :weight bold))))
   `(magit-branch-local   ((t (:foreground ,doneburn-blue   :weight bold))))
   `(magit-branch-current ((t (:foreground ,doneburn-blue   :weight bold :box t))))
   `(magit-head           ((t (:foreground ,doneburn-blue   :weight bold))))
   `(magit-refname        ((t (:background ,doneburn-bg+2 :foreground ,doneburn-fg :weight bold))))
   `(magit-refname-stash  ((t (:background ,doneburn-bg+2 :foreground ,doneburn-fg :weight bold))))
   `(magit-refname-wip    ((t (:background ,doneburn-bg+2 :foreground ,doneburn-fg :weight bold))))
   `(magit-signature-good      ((t (:foreground ,doneburn-green))))
   `(magit-signature-bad       ((t (:foreground ,doneburn-red))))
   `(magit-signature-untrusted ((t (:foreground ,doneburn-yellow))))
   `(magit-signature-expired   ((t (:foreground ,doneburn-orange))))
   `(magit-signature-revoked   ((t (:foreground ,doneburn-magenta))))
   '(magit-signature-error     ((t (:inherit    magit-signature-bad))))
   `(magit-cherry-unmatched    ((t (:foreground ,doneburn-cyan))))
   `(magit-cherry-equivalent   ((t (:foreground ,doneburn-magenta))))
   `(magit-reflog-commit       ((t (:foreground ,doneburn-green))))
   `(magit-reflog-amend        ((t (:foreground ,doneburn-magenta))))
   `(magit-reflog-merge        ((t (:foreground ,doneburn-green))))
   `(magit-reflog-checkout     ((t (:foreground ,doneburn-blue))))
   `(magit-reflog-reset        ((t (:foreground ,doneburn-red))))
   `(magit-reflog-rebase       ((t (:foreground ,doneburn-magenta))))
   `(magit-reflog-cherry-pick  ((t (:foreground ,doneburn-green))))
   `(magit-reflog-remote       ((t (:foreground ,doneburn-cyan))))
   `(magit-reflog-other        ((t (:foreground ,doneburn-cyan))))
;;;;; message-mode
   `(message-cited-text ((t (:inherit font-lock-comment-face))))
   `(message-header-name ((t (:foreground ,doneburn-green+1))))
   `(message-header-other ((t (:foreground ,doneburn-green))))
   `(message-header-to ((t (:foreground ,doneburn-yellow :weight bold))))
   `(message-header-cc ((t (:foreground ,doneburn-yellow :weight bold))))
   `(message-header-newsgroups ((t (:foreground ,doneburn-yellow :weight bold))))
   `(message-header-subject ((t (:foreground ,doneburn-orange :weight bold))))
   `(message-header-xheader ((t (:foreground ,doneburn-green))))
   `(message-mml ((t (:foreground ,doneburn-yellow :weight bold))))
   `(message-separator ((t (:inherit font-lock-comment-face))))
;;;;; mic-paren
   `(paren-face-match ((t (:foreground ,doneburn-cyan :background ,doneburn-bg :weight bold))))
   `(paren-face-mismatch ((t (:foreground ,doneburn-bg :background ,doneburn-magenta :weight bold))))
   `(paren-face-no-match ((t (:foreground ,doneburn-bg :background ,doneburn-red :weight bold))))
;;;;; nav
   `(nav-face-heading ((t (:foreground ,doneburn-yellow))))
   `(nav-face-button-num ((t (:foreground ,doneburn-cyan))))
   `(nav-face-dir ((t (:foreground ,doneburn-green))))
   `(nav-face-hdir ((t (:foreground ,doneburn-red))))
   `(nav-face-file ((t (:foreground ,doneburn-fg))))
   `(nav-face-hfile ((t (:foreground ,doneburn-red-4))))
;;;;; mu4e
   `(mu4e-cited-1-face ((t (:foreground ,doneburn-blue    :slant italic))))
   `(mu4e-cited-2-face ((t (:foreground ,doneburn-green+2 :slant italic))))
   `(mu4e-cited-3-face ((t (:foreground ,doneburn-blue-2  :slant italic))))
   `(mu4e-cited-4-face ((t (:foreground ,doneburn-green   :slant italic))))
   `(mu4e-cited-5-face ((t (:foreground ,doneburn-blue-4  :slant italic))))
   `(mu4e-cited-6-face ((t (:foreground ,doneburn-green-2 :slant italic))))
   `(mu4e-cited-7-face ((t (:foreground ,doneburn-blue    :slant italic))))
   `(mu4e-replied-face ((t (:foreground ,doneburn-bg+3))))
   `(mu4e-trashed-face ((t (:foreground ,doneburn-bg+3 :strike-through t))))
;;;;; org-mode
   `(org-agenda-date-today
     ((t (:foreground ,doneburn-fg+1 :slant italic :weight bold))) t)
   `(org-agenda-structure
     ((t (:inherit font-lock-comment-face))))
   `(org-archived ((t (:foreground ,doneburn-fg :weight bold))))
   `(org-block ((t (:background ,doneburn-bg+2))))
   `(org-checkbox ((t (:background ,doneburn-bg+2 :foreground ,doneburn-fg+1
                                   :box (:line-width 1 :style released-button)))))
   `(org-date ((t (:foreground ,doneburn-blue :underline t))))
   `(org-deadline-announce ((t (:foreground ,doneburn-red-1))))
   `(org-done ((t (:weight bold :weight bold :foreground ,doneburn-green+3))))
   `(org-formula ((t (:foreground ,doneburn-yellow-2))))
   `(org-headline-done ((t (:foreground ,doneburn-green+3))))
   `(org-hide ((t (:foreground ,doneburn-bg-1))))
   `(org-level-1 ((t (:foreground ,doneburn-orange))))
   `(org-level-2 ((t (:foreground ,doneburn-green+4))))
   `(org-level-3 ((t (:foreground ,doneburn-blue-1))))
   `(org-level-4 ((t (:foreground ,doneburn-yellow-2))))
   `(org-level-5 ((t (:foreground ,doneburn-cyan))))
   `(org-level-6 ((t (:foreground ,doneburn-green+2))))
   `(org-level-7 ((t (:foreground ,doneburn-red-4))))
   `(org-level-8 ((t (:foreground ,doneburn-blue-4))))
   `(org-link ((t (:foreground ,doneburn-yellow-2 :underline t))))
   `(org-scheduled ((t (:foreground ,doneburn-green+4))))
   `(org-scheduled-previously ((t (:foreground ,doneburn-red))))
   `(org-scheduled-today ((t (:foreground ,doneburn-blue+1))))
   `(org-sexp-date ((t (:foreground ,doneburn-blue+1 :underline t))))
   `(org-special-keyword ((t (:inherit font-lock-comment-face))))
   `(org-table ((t (:foreground ,doneburn-green+2))))
   `(org-tag ((t (:weight bold :weight bold))))
   `(org-time-grid ((t (:foreground ,doneburn-orange))))
   `(org-todo ((t (:weight bold :foreground ,doneburn-red :weight bold))))
   `(org-upcoming-deadline ((t (:inherit font-lock-keyword-face))))
   `(org-warning ((t (:weight bold :foreground ,doneburn-red :weight bold :underline nil))))
   `(org-column ((t (:background ,doneburn-bg-1))))
   `(org-column-title ((t (:background ,doneburn-bg-1 :underline t :weight bold))))
   `(org-mode-line-clock ((t (:foreground ,doneburn-fg :background ,doneburn-bg-1))))
   `(org-mode-line-clock-overrun ((t (:foreground ,doneburn-bg :background ,doneburn-red-1))))
   `(org-ellipsis ((t (:foreground ,doneburn-yellow-1 :underline t))))
   `(org-footnote ((t (:foreground ,doneburn-cyan :underline t))))
   `(org-document-title ((t (:foreground ,doneburn-blue))))
   `(org-document-info ((t (:foreground ,doneburn-blue))))
   `(org-habit-ready-face ((t :background ,doneburn-green)))
   `(org-habit-alert-face ((t :background ,doneburn-yellow-1 :foreground ,doneburn-bg)))
   `(org-habit-clear-face ((t :background ,doneburn-blue-3)))
   `(org-habit-overdue-face ((t :background ,doneburn-red-3)))
   `(org-habit-clear-future-face ((t :background ,doneburn-blue-4)))
   `(org-habit-ready-future-face ((t :background ,doneburn-green-2)))
   `(org-habit-alert-future-face ((t :background ,doneburn-yellow-2 :foreground ,doneburn-bg)))
   `(org-habit-overdue-future-face ((t :background ,doneburn-red-4)))
;;;;; outline
   `(outline-1 ((t (:foreground ,doneburn-orange))))
   `(outline-2 ((t (:foreground ,doneburn-green+4))))
   `(outline-3 ((t (:foreground ,doneburn-blue-1))))
   `(outline-4 ((t (:foreground ,doneburn-yellow-2))))
   `(outline-5 ((t (:foreground ,doneburn-cyan))))
   `(outline-6 ((t (:foreground ,doneburn-green+2))))
   `(outline-7 ((t (:foreground ,doneburn-red-4))))
   `(outline-8 ((t (:foreground ,doneburn-blue-4))))
;;;;; rainbow-delimiters
   `(rainbow-delimiters-depth-1-face ((t (:foreground ,doneburn-fg))))
   `(rainbow-delimiters-depth-2-face ((t (:foreground ,doneburn-green+4))))
   `(rainbow-delimiters-depth-3-face ((t (:foreground ,doneburn-yellow-2))))
   `(rainbow-delimiters-depth-4-face ((t (:foreground ,doneburn-cyan))))
   `(rainbow-delimiters-depth-5-face ((t (:foreground ,doneburn-green+2))))
   `(rainbow-delimiters-depth-6-face ((t (:foreground ,doneburn-blue+1))))
   `(rainbow-delimiters-depth-7-face ((t (:foreground ,doneburn-yellow-1))))
   `(rainbow-delimiters-depth-8-face ((t (:foreground ,doneburn-green+1))))
   `(rainbow-delimiters-depth-9-face ((t (:foreground ,doneburn-blue-2))))
   `(rainbow-delimiters-depth-10-face ((t (:foreground ,doneburn-orange))))
   `(rainbow-delimiters-depth-11-face ((t (:foreground ,doneburn-green))))
   `(rainbow-delimiters-depth-12-face ((t (:foreground ,doneburn-blue-5))))
;;;;; rcirc
   `(rcirc-my-nick ((t (:foreground ,doneburn-blue))))
   `(rcirc-other-nick ((t (:foreground ,doneburn-orange))))
   `(rcirc-bright-nick ((t (:foreground ,doneburn-blue+1))))
   `(rcirc-dim-nick ((t (:foreground ,doneburn-blue-2))))
   `(rcirc-server ((t (:foreground ,doneburn-green))))
   `(rcirc-server-prefix ((t (:foreground ,doneburn-green+1))))
   `(rcirc-timestamp ((t (:foreground ,doneburn-green+2))))
   `(rcirc-nick-in-message ((t (:foreground ,doneburn-yellow))))
   `(rcirc-nick-in-message-full-line ((t (:weight bold))))
   `(rcirc-prompt ((t (:foreground ,doneburn-yellow :weight bold))))
   `(rcirc-track-nick ((t (:inverse-video t))))
   `(rcirc-track-keyword ((t (:weight bold))))
   `(rcirc-url ((t (:weight bold))))
   `(rcirc-keyword ((t (:foreground ,doneburn-yellow :weight bold))))
;;;;; re-builder
   `(reb-match-0 ((t (:foreground ,doneburn-bg :background ,doneburn-magenta))))
   `(reb-match-1 ((t (:foreground ,doneburn-bg :background ,doneburn-blue))))
   `(reb-match-2 ((t (:foreground ,doneburn-bg :background ,doneburn-orange))))
   `(reb-match-3 ((t (:foreground ,doneburn-bg :background ,doneburn-red))))
;;;;; regex-tool
   `(regex-tool-matched-face ((t (:background ,doneburn-blue-4 :weight bold))))
;;;;; rst-mode
   `(rst-level-1-face ((t (:foreground ,doneburn-orange))))
   `(rst-level-2-face ((t (:foreground ,doneburn-green+1))))
   `(rst-level-3-face ((t (:foreground ,doneburn-blue-1))))
   `(rst-level-4-face ((t (:foreground ,doneburn-yellow-2))))
   `(rst-level-5-face ((t (:foreground ,doneburn-cyan))))
   `(rst-level-6-face ((t (:foreground ,doneburn-green-2))))
;;;;; sh-mode
   `(sh-heredoc     ((t (:foreground ,doneburn-yellow :weight bold))))
   `(sh-quoted-exec ((t (:foreground ,doneburn-red))))
;;;;; show-paren
   `(show-paren-mismatch ((t (:foreground ,doneburn-red+1 :background ,doneburn-bg+3 :weight bold))))
   `(show-paren-match ((t (:background ,doneburn-bg+3 :weight bold))))
;;;;; smartparens
   `(sp-show-pair-mismatch-face ((t (:foreground ,doneburn-red+1 :background ,doneburn-bg+3 :weight bold))))
   `(sp-show-pair-match-face ((t (:background ,doneburn-bg+3 :weight bold))))
;;;;; term
   `(term-color-black ((t (:foreground ,doneburn-bg
                                       :background ,doneburn-bg-1))))
   `(term-color-red ((t (:foreground ,doneburn-red-2
                                     :background ,doneburn-red-4))))
   `(term-color-green ((t (:foreground ,doneburn-green
                                       :background ,doneburn-green+2))))
   `(term-color-yellow ((t (:foreground ,doneburn-orange
                                        :background ,doneburn-yellow))))
   `(term-color-blue ((t (:foreground ,doneburn-blue-1
                                      :background ,doneburn-blue-4))))
   `(term-color-magenta ((t (:foreground ,doneburn-magenta
                                         :background ,doneburn-red))))
   `(term-color-cyan ((t (:foreground ,doneburn-cyan
                                      :background ,doneburn-blue))))
   `(term-color-white ((t (:foreground ,doneburn-fg
                                       :background ,doneburn-fg-1))))
   '(term-default-fg-color ((t (:inherit term-color-white))))
   '(term-default-bg-color ((t (:inherit term-color-black))))
;;;;; undo-tree
   `(undo-tree-visualizer-active-branch-face ((t (:foreground ,doneburn-fg+1 :weight bold))))
   `(undo-tree-visualizer-current-face ((t (:foreground ,doneburn-red-1 :weight bold))))
   `(undo-tree-visualizer-default-face ((t (:foreground ,doneburn-fg))))
   `(undo-tree-visualizer-register-face ((t (:foreground ,doneburn-yellow))))
   `(undo-tree-visualizer-unmodified-face ((t (:foreground ,doneburn-cyan))))
;;;;; visual-regexp
   `(vr/group-0 ((t (:foreground ,doneburn-bg :background ,doneburn-green :weight bold))))
   `(vr/group-1 ((t (:foreground ,doneburn-bg :background ,doneburn-orange :weight bold))))
   `(vr/group-2 ((t (:foreground ,doneburn-bg :background ,doneburn-blue :weight bold))))
   `(vr/match-0 ((t (:inherit isearch))))
   `(vr/match-1 ((t (:foreground ,doneburn-yellow-2 :background ,doneburn-bg-1 :weight bold))))
   `(vr/match-separator-face ((t (:foreground ,doneburn-red :weight bold))))
;;;;; web-mode
   `(web-mode-builtin-face ((t (:inherit ,font-lock-builtin-face))))
   `(web-mode-comment-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-constant-face ((t (:inherit ,font-lock-constant-face))))
   `(web-mode-css-at-rule-face ((t (:foreground ,doneburn-orange ))))
   `(web-mode-css-prop-face ((t (:foreground ,doneburn-orange))))
   `(web-mode-css-pseudo-class-face ((t (:foreground ,doneburn-green+3 :weight bold))))
   `(web-mode-css-rule-face ((t (:foreground ,doneburn-blue))))
   `(web-mode-doctype-face ((t (:inherit ,font-lock-comment-face))))
   `(web-mode-folded-face ((t (:underline t))))
   `(web-mode-function-name-face ((t (:foreground ,doneburn-blue))))
   `(web-mode-html-attr-name-face ((t (:foreground ,doneburn-orange))))
   `(web-mode-html-attr-value-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-html-tag-face ((t (:foreground ,doneburn-cyan))))
   `(web-mode-keyword-face ((t (:inherit ,font-lock-keyword-face))))
   `(web-mode-preprocessor-face ((t (:inherit ,font-lock-preprocessor-face))))
   `(web-mode-string-face ((t (:inherit ,font-lock-string-face))))
   `(web-mode-type-face ((t (:inherit ,font-lock-type-face))))
   `(web-mode-variable-name-face ((t (:inherit ,font-lock-variable-name-face))))
   `(web-mode-server-background-face ((t (:background ,doneburn-bg))))
   `(web-mode-server-comment-face ((t (:inherit web-mode-comment-face))))
   `(web-mode-server-string-face ((t (:inherit web-mode-string-face))))
   `(web-mode-symbol-face ((t (:inherit font-lock-constant-face))))
   `(web-mode-warning-face ((t (:inherit font-lock-warning-face))))
   `(web-mode-whitespaces-face ((t (:background ,doneburn-red))))
;;;;; whitespace-mode
   `(whitespace-space ((t (:background ,doneburn-bg+1 :foreground ,doneburn-bg+1))))
   `(whitespace-hspace ((t (:background ,doneburn-bg+1 :foreground ,doneburn-bg+1))))
   `(whitespace-tab ((t (:background ,doneburn-red-1))))
   `(whitespace-newline ((t (:foreground ,doneburn-bg+1))))
   `(whitespace-trailing ((t (:background ,doneburn-red))))
   `(whitespace-line ((t (:background ,doneburn-bg :foreground ,doneburn-magenta))))
   `(whitespace-space-before-tab ((t (:background ,doneburn-orange :foreground ,doneburn-orange))))
   `(whitespace-indentation ((t (:background ,doneburn-yellow :foreground ,doneburn-red))))
   `(whitespace-empty ((t (:background ,doneburn-yellow))))
   `(whitespace-space-after-tab ((t (:background ,doneburn-yellow :foreground ,doneburn-red))))
;;;;; which-func-mode
   `(which-func ((t (:foreground ,doneburn-green+4))))
   ))

;;; Theme Variables
(doneburn-with-color-variables
 (custom-theme-set-variables
  'doneburn
;;;;; ansi-color
  `(ansi-color-names-vector [,doneburn-bg ,doneburn-red ,doneburn-green ,doneburn-yellow
                                          ,doneburn-blue ,doneburn-magenta ,doneburn-cyan ,doneburn-fg])
;;;;; company-quickhelp
  `(company-quickhelp-color-background ,doneburn-bg+1)
  `(company-quickhelp-color-foreground ,doneburn-fg)
;;;;; fill-column-indicator
  `(fci-rule-color ,doneburn-bg-05)
;;;;; nrepl-client
  `(nrepl-message-colors
    '(,doneburn-red ,doneburn-orange ,doneburn-yellow ,doneburn-green ,doneburn-green+4
                    ,doneburn-cyan ,doneburn-blue+1 ,doneburn-magenta))
;;;;; pdf-tools
  `(pdf-view-midnight-colors '(,doneburn-fg . ,doneburn-bg-05))
;;;;; vc-annotate
  `(vc-annotate-color-map
    '(( 20. . ,doneburn-red-1)
      ( 40. . ,doneburn-red)
      ( 60. . ,doneburn-orange)
      ( 80. . ,doneburn-yellow-2)
      (100. . ,doneburn-yellow-1)
      (120. . ,doneburn-yellow)
      (140. . ,doneburn-green-2)
      (160. . ,doneburn-green)
      (180. . ,doneburn-green+1)
      (200. . ,doneburn-green+2)
      (220. . ,doneburn-green+3)
      (240. . ,doneburn-green+4)
      (260. . ,doneburn-cyan)
      (280. . ,doneburn-blue-2)
      (300. . ,doneburn-blue-1)
      (320. . ,doneburn-blue)
      (340. . ,doneburn-blue+1)
      (360. . ,doneburn-magenta)))
  `(vc-annotate-very-old-color ,doneburn-magenta)
  `(vc-annotate-background ,doneburn-bg-1)
  ))

;;; Rainbow Support

(declare-function rainbow-mode 'rainbow-mode)
(declare-function rainbow-colorize-by-assoc 'rainbow-mode)

(defvar doneburn-add-font-lock-keywords nil
  "Whether to add font-lock keywords for doneburn color names.
In buffers visiting library `doneburn-theme.el' the doneburn
specific keywords are always added.  In all other Emacs-Lisp
buffers this variable controls whether this should be done.
This requires library `rainbow-mode'.")

(defvar doneburn-colors-font-lock-keywords nil)

;;; Footer

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'doneburn)

;; Local Variables:
;; no-byte-compile: t
;; indent-tabs-mode: nil
;; eval: (when (require 'rainbow-mode nil t) (rainbow-mode 1))
;; End:

;;; doneburn-theme.el ends here
