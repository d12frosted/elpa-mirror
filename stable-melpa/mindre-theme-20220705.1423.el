;;; mindre-theme.el --- Minimal, light theme -*- lexical-binding: t -*-

;; Author: Erik Bäckman <contact@ebackman.net>
;; Version: 0.1
;; Package-Version: 20220705.1423
;; Package-Commit: d08d6235cc122fafa144aae06a4332c730bc3ba4
;; Package-Requires: ((emacs "26.1"))
;; Keywords: faces
;; Homepage: https://github.com/erikbackman/mindre-theme

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
;; ---------------------------------------------------------------------

;;; Commentary:

;; Mindre (which is the Swedish word for “less”) tries to strike a good balance
;; between usability and minimalism by almost being a monochrome theme but with
;; a splash of color.
;;
;; Three colors are used to make certain language constructs stand out
;; enough for your eyes to notice them without being distracting.
;; The colors (in order of importance) are:
;; 1. mindre-salient
;;    Preferably used for language constructs that acts as the beginning
;;    or end of a clause, such as if/then/else, when, where etc.
;; 2. mindre-salient-alt (types)
;; 3. mindre-verbatim (strings)

;;; Code:

(deftheme mindre
  "Mindre theme.")

(defgroup mindre nil
  "Mindre theme properties."
  :group 'faces)

(defcustom mindre-background "#F5F5F5"
  "Default background color."
  :type 'color :group 'mindre)

(defcustom mindre-background-2 "#f2f3f5"
  "Alternative background used for UI elements."
  :type 'color :group 'mindre)

(defcustom mindre-background-3 "#e3e5e8"
  "Alternative background used for UI elements."
  :type 'color :group 'mindre)

(defcustom mindre-foreground "#2e3338"
  "Default foreground color."
  :type 'color :group 'mindre)

(defcustom mindre-salient "#5c3e99"
  "Salient color is used for information that are important.
Commonly used for keywords."
  :type 'color :group 'mindre)

(defcustom mindre-salient-alt "#16524F"
  "Alt Salient color is used for information that are important.
Commonly used for types"
  :type 'color :group 'mindre)

(defcustom mindre-verbatim "#54433a"
  "Color used for things like strings."
  :type 'color :group 'mindre)

(defcustom mindre-highlight "#CFD8DC"
  "Highlight color is used to highlight part of the screen."
  :type 'color :group 'mindre)

(defcustom mindre-subtle "#ECEFF1"
  "Subtle color is used to suggest a physical area on the screen."
  :type 'color :group 'mindre)

(defcustom mindre-faded "#B0BEC5"
  "Faded face is for information that are less important."
  :type 'color :group 'mindre)

(defcustom mindre-strong "#171A1C"
  "Strong color is used for information of a structural nature."
  :type 'color :group 'mindre)

(defcustom mindre-ok "#537469"
  "Default green color."
  :type 'color :group 'mindre)

(defcustom mindre-warning "#d47500"
  "Default orange color."
  :type 'color :group 'mindre)

(defcustom mindre-error "#BF616A"
  "Default red color."
  :type 'color :group 'mindre)

(defcustom mindre-critical "#BF616A"
  "Critical face for information that requires immediate action."
  :type 'color :group 'mindre)

(defface mindre-critical nil
  "Critical face for information that requires immediate action."
  :group nil)

(defface mindre-critical-i nil
  "Critical face inversed."
  :group nil)

(defface mindre-strong nil
  "Strong face for information of a structural nature."
  :group nil)

(defface mindre-bold
  '((t (:bold t :foreground "#000")))
  "Bold face."
  :group nil)

(defface mindre-strong-i nil
  "Strong face inversed." :group nil)

(defface mindre-salient nil
  "Salient face for important information."
  :group nil)

(defface mindre-salient-alt nil
  "Alternative salient face."
  :group nil)

(defface mindre-salient-i nil
  "Strong face inversed."
  :group nil)

(defface mindre-faded nil
  "Faded face for less important information."
  :group nil)

(defface mindre-faded-i nil
  "Faded face inversed." :group nil)

(defface mindre-subtle nil
  "Subtle face is used to suggest a physical area on the screen."
  :group nil)

(defface mindre-subtle-i nil
  "Subtle face inversed." :group nil)

(defface mindre-default nil
  "Default face." :group nil)

(defface mindre-default-i nil
  "Default face inversed." :group nil)

(defface mindre-highlight nil
  "Default highlight face."
  :group nil)

(defface mindre-warning nil
  "Warning face."
  :group nil)

(defface mindre-note nil
  "Note face."
  :group nil)

(defface mindre-block nil
  "Default block face."
  :group nil)

(defface mindre-button
  `((t (:box (:style released-button) :background ,mindre-background-3)))
  "Default button face."
  :group nil)

(defface mindre-button-hover
  `((t (:inherit mindre-button :background ,mindre-background-2)))
  "Hover button face."
  :group nil)

(defface mindre-button-pressed
  `((t (:box (:style nil) :background ,mindre-background-3)))
  "Pressed button face."
  :group nil)

(defface mindre-verbatim nil
  "Face used for things like strings."
  :group nil)

(defface mindre-paren-face
  '((t (:foreground "grey70")))
  "Face used to dim parentheses."
  :group nil)

(defun mindre--font-lock-add-paren ()
  "Make Lisp parentheses faded."
  (font-lock-add-keywords nil '(("(\\|)" . 'mindre-paren-face))))

(defvar mindre-after-load-hook nil
  "Hook run after theme has loaded.")

(defcustom mindre-use-more-bold nil
  "Use more bold constructs."
  :type 'boolean :group 'mindre)

(defcustom mindre-use-faded-lisp-parens t
  "Use faded parenthesis in Lisp modes."
  :type 'boolean :group 'mindre)

(defface mindre-heading-1 nil
  "Face for headings."
  :group nil)

(defun mindre ()
  "Load mindre theme."
  (interactive)

  (when mindre-use-faded-lisp-parens
    (add-hook 'lisp-data-mode-hook #'mindre--font-lock-add-paren)
    (add-hook 'scheme-mode-hook #'mindre--font-lock-add-paren))

  (load-theme 'mindre t)
  (run-hooks 'mindre-after-load-hook))

(make-obsolete 'mindre 'load-theme "0.1")

;; --- Faces ---------------------------------------------------------
(let ((mindre-heading-1-height (if mindre-use-more-bold
				   1.0
				 1.1)))

  (custom-theme-set-faces
   'mindre

   ;; --- Base ---------------------------------------------------------
   `(cursor ((t (:foreground ,mindre-background :background ,mindre-foreground))))

   `(default ((t (:background ,mindre-background :foreground ,mindre-foreground))))

   `(highlight ((t (:background ,mindre-highlight))))

   `(mindre-subtle ((t (:background ,mindre-subtle))))

   `(mindre-subtle-i ((t (:foreground ,mindre-subtle))))

   `(mindre-faded ((t (:foreground ,mindre-faded))))

   `(mindre-faded-i ((t (:foreground ,mindre-background :background ,mindre-faded))))

   `(mindre-default ((t (:foreground ,mindre-foreground))))

   `(mindre-default-i ((t (:foreground ,mindre-background :background ,mindre-foreground))))

   `(mindre-salient ((t (:foreground ,mindre-salient))))
   `(mindre-salient-alt ((t (:foreground ,mindre-salient-alt))))

   `(mindre-salient-i ((t (:foreground ,mindre-background :background ,mindre-salient))))
   `(mindre-strong ((t ,(when mindre-use-more-bold '(:weight semibold)))))
   `(mindre-strong-i ((t (:foreground ,mindre-background :background ,mindre-strong :weight bold))))

   `(mindre-critical ((t (:foreground ,mindre-background :background ,mindre-critical))))

   `(mindre-warning ((t (:foreground ,mindre-warning))))
   `(mindre-note ((t (:foreground ,mindre-ok))))
   `(mindre-critical-i ((t (:foreground ,mindre-critical))))
   `(mindre-verbatim ((t (:foreground ,mindre-verbatim))))

   `(mindre-heading-1 ((t (:inherit mindre-strong :height ,mindre-heading-1-height))))
   `(mindre-block ((t (:background ,mindre-background-2 :foreground ,mindre-foreground :extend t))))

   ;; --- Header & mode line -------------------------------------------
   `(mode-line ((t (:foreground ,mindre-foreground
		    :background ,mindre-background-2
		    :box (:color ,mindre-faded :line-width 1)))))

   `(mode-line-inactive ((t (:foreground "#535c65"
			     :background ,mindre-background-3
			     :box (:line-width 1 :color ,mindre-faded)))))

   `(mode-line-buffer-id ((t (:weight regular :background nil))))
   `(mode-line-emphasis ((t (:weight regular :background nil))))


   `(header-line ((t (:foreground ,mindre-foreground
		      :background ,mindre-background-2
		      :inherit nil
		      :height 0.9
		      :box nil))))

   ;; --- Structural ---------------------------------------------------
   '(bold ((t (:inherit mindre-strong :weight semibold))))
   '(italic ((t (:slant italic))))
   '(italic ((t (:inherit mindre-faded))))
   '(bold-italic ((t (:inherit mindre-strong))))
   '(region ((t (:inherit highlight))))
   '(fringe ((t (:inherit mindre-faded))))
   '(hl-line ((t (:inherit mindre-subtle))))
   '(link ((t (:inherit mindre-salient :underline t))))

   ;; --- Semantic -----------------------------------------------------
   '(shadow ((t (:inherit mindre-faded))))
   '(success ((t (:inherit mindre-salient))))
   '(warning ((t (:inherit mindre-warning))))
   '(error ((t (:inherit mindre-critical))))
   '(match ((t (:inherit ,mindre-bold))))
   `(preview-face ((t (:inherit mindre-subtle))))

   ;; --- General ------------------------------------------------------
   '(buffer-menu-buffer ((t (:inherit mindre-strong))))
   '(minibuffer-prompt ((t (:inherit mindre-strong))))
   `(isearch ((t (:inherit (mindre-strong highlight)))))
   '(isearch-fail ((t (:inherit mindre-faded))))
   '(show-paren-match ((t (:weight bold :foreground "#AB47BC"))))
   '(show-paren-mismatch ((t (:inherit mindre-critical))))
   '(lazy-highlight ((t (:inherit mindre-subtle))))
   '(trailing-whitespace ((t (:inherit mindre-subtle))))
   '(secondary-selection ((t (:inherit mindre-subtle))))
   '(completions-annotations ((t (:inherit mindre-faded))))
   '(completions-common-part ((t (:inherit mindre-bold))))
   '(completions-first-difference ((t (:inherit nil))))
   '(tooltip ((t (:inherit mindre-subtle))))
   '(read-multiple-choice-face ((t (:inherit mindre-strong))))
   '(nobreak-hyphen ((t (:inherit mindre-strong))))
   '(nobreak-space ((t (:inherit mindre-strong))))
   '(help-argument-name ((t (:inherit mindre-verbatim))))
   '(help-key-binding ((t :inherit mindre-verbatim)))
   '(tabulated-list-fake-header ((t (:inherit mindre-strong))))
   '(tool-bar ((t (:inherit mindre-faded-i))))

   ;; --- Pulse --------------------------------------------------------
   `(pulse-highlight-face ((t (:inherit highlight))))
   `(pulse-highlight-start-face ((t (:inherit highlight))))

   ;; --- TTY faces ----------------------------------------------------
   '(tty-menu-disabled-face ((t (:inherit mindre-faded-i))))
   '(tty-menu-enabled-face ((t (:inherit mindre-default-i))))
   '(tty-menu-selected-face ((t (:inherit mindre-salient-i))))

   ;; --- whitespace-mode ----------------------------------------------------
   `(whitespace-space ((t (:inherit mindre-default))))
   `(whitespace-empty ((t (:inherit mindre-default :foreground ,mindre-warning))))
   `(whitespace-newline ((t (:inherit mindre-faded))))

   ;; --- Eshell ----------------------------------------------------
   '(eshell-prompt ((t (:inherit mindre-default))))

   ;; --- ERC ----------------------------------------------------
   '(erc-prompt-face ((t (:inhert mindre-default))))
   '(erc-timestamp-face ((t (:inhert mindre-faded))))
   '(erc-notice-face ((t (:inherit mindre-salient))))
   '(erc-current-nick-face ((t (:inherit mindre-strong))))
   '(erc-error-face ((t (:inherit mindre-critical-i))))

   ;; --- Dictionary ----------------------------------------------------
   `(dictionary-word-definition-face ((t (:inherit (mindre-default fixed-pitch)))))
   `(dictionary-reference-face ((t (:inherit (mindre-salient fixed-pitch)))))
   ;; --- Windows divider ----------------------------------------------
   `(window-divider ((t (:foreground ,mindre-background))))
   '(window-divider-first-pixel ((t (:inherit window-divider))))
   '(window-divider-last-pixel ((t (:inherit window-divider))))
   `(vertical-border ((t (:foreground ,mindre-faded))))

   ;; --- Tab bar ------------------------------------------------------
   '(tab-bar ((t (:inherit default))))
   '(tab-bar-tab ((t (:inherit default))))
   '(tab-bar-tab-inactive ((t (:inherit mindre-faded))))
   '(tab-line ((t (:inherit default))))

   ;; --- Line numbers -------------------------------------------------
   '(line-number ((t (:inherit mindre-faded))))
   '(line-number-current-line ((t (:inherit default))))
   `(line-number-major-tick ((t (:inherit mindre-faded))))
   '(line-number-minor-tick ((t (:inherit mindre-faded))))

   ;; --- Font lock ----------------------------------------------------
   '(font-lock-comment-face ((t (:inherit mindre-faded))))
   '(font-lock-doc-face ((t (:inherit mindre-faded))))
   `(font-lock-string-face ((t (:foreground ,mindre-verbatim))))
   '(font-lock-constant-face ((t (:inherit mindre-strong))))
   `(font-lock-warning-face ((t (:inherit mindre-warning))))
   '(font-lock-function-name-face ((t (:inherit mindre-strong))))
   `(font-lock-variable-name-face ((t (:inherit mindre-default))))
   '(font-lock-builtin-face ((t (:inherit mindre-salient))))
   '(font-lock-type-face ((t (:inherit (mindre-salient-alt)))))
   '(font-lock-keyword-face ((t (:inherit mindre-salient))))

   ;; --- Popper -------------------------------------------------------
   `(popper-echo-area-buried ((t (:inherit mindre-default))))
   `(popper-echo-dispatch-hint ((t (:inherit mindre-subtle))))

   ;; --- Custom edit --------------------------------------------------
   '(widget-field ((t (:inherit mindre-subtle))))
   '(widget-button ((t (:inherit mindre-strong))))
   '(widget-single-line-field ((t (:inherit mindre-subtle))))
   '(custom-group-subtitle ((t (:inherit mindre-strong))))
   '(custom-group-tag ((t (:inherit mindre-strong))))
   '(custom-group-tag-1 ((t (:inherit mindre-strong))))
   '(custom-comment ((t (:inherit mindre-faded))))
   '(custom-comment-tag ((t (:inherit mindre-faded))))
   '(custom-changed ((t (:inherit mindre-salient))))
   '(custom-modified ((t (:inherit mindre-salient))))
   '(custom-face-tag ((t (:inherit mindre-strong))))
   '(custom-variable-tag ((t (:inherit mindre-strong))))
   '(custom-invalid ((t (:inherit mindre-strong))))
   '(custom-visibility ((t (:inherit mindre-salient))))
   '(custom-state ((t (:inherit mindre-salient))))
   '(custom-link ((t (:inherit mindre-salient))))
   '(custom-variable-obsolete ((t (:inherit mindre-faded))))

   ;; --- Company  ----------------------------------------------
   '(company-tooltip ((t (:inherit mindre-subtle))))
   '(company-tooltip-mouse ((t (:inherit mindre-faded-i))))
   '(company-tooltip-selection ((t (:inherit highlight))))
   '(company-scrollbar-fg ((t (:inherit mindre-default-i))))
   '(company-scrollbar-bg ((t (:inherit mindre-faded-i))))
   '(company-tooltip-common ((t (:inherit mindre-strong))))
   '(company-tooltip-common-selection ((t (:inherit mindre-popout))))
   '(company-tooltip-annotation ((t (:inherit mindre-faded))))
   '(company-tooltip-annotation-selection ((t (:inherit mindre-faded))))
   '(company-tooltip-scrollbar-thumb ((t (:inherit mindre-default-i))))
   '(company-tooltip-scrollbar-track ((t (:inherit mindre-faded-i))))
   '(company-tooltip-annotation-selection ((t (:inherit mindre-subtle))))

   ;; --- Corfu  --------------------------------------------------------
   `(corfu-current ((t (:inherit highlight))))

   ;; --- Vertico  --------------------------------------------------------
   `(vertico-current ((t (:inherit highlight))))

   ;; --- Buttons ------------------------------------------------------
   `(custom-button ((t (:inherit mindre-button))))

   `(custom-button-mouse ((t (:inherit mindre-button-hover))))

   `(custom-button-pressed ((t (:inherit mindre-button-pressed))))

   ;; --- Packages -----------------------------------------------------
   '(package-description ((t (:inherit mindre-default))))
   '(package-help-section-name ((t (:inherit mindre-default))))
   '(package-name ((t (:inherit mindre-salient))))
   '(package-status-avail-obso ((t (:inherit mindre-faded))))
   '(package-status-available ((t (:inherit mindre-default))))
   '(package-status-built-in ((t (:inherit mindre-salient))))
   '(package-status-dependency ((t (:inherit mindre-salient))))
   '(package-status-disabled ((t (:inherit mindre-faded))))
   '(package-status-external ((t (:inherit mindre-default))))
   '(package-status-held ((t (:inherit mindre-default))))
   '(package-status-incompat ((t (:inherit mindre-faded))))
   '(package-status-installed ((t (:inherit mindre-salient))))
   '(package-status-new ((t (:inherit mindre-default))))
   '(package-status-unsigned ((t (:inherit mindre-default))))

   ;; --- Info ---------------------------------------------------------
   '(info-node ((t (:inherit mindre-strong))))
   '(info-menu-header ((t (:inherit mindre-strong))))
   '(info-header-node ((t (:inherit mindre-default))))
   '(info-index-match ((t (:inherit mindre-salient))))
   '(info-menu-star ((t (:inherit mindre-default))))
   '(Info-quoted ((t (:inherit mindre-salient))))
   '(info-title-1 ((t (:inherit mindre-strong))))
   '(info-title-2 ((t (:inherit mindre-strong))))
   '(info-title-3 ((t (:inherit mindre-strong))))
   '(info-title-4 ((t (:inherit mindre-strong))))

   ;; --- Helpful ------------------------------------------------------
   '(helpful-heading ((t (:inherit mindre-strong))))

   ;; --- EPA ----------------------------------------------------------
   '(epa-field-body ((t (:inherit mindre-default))))
   '(epa-field-name ((t (:inherit mindre-strong))))
   '(epa-mark ((t (:inherit mindre-salient))))
   '(epa-string ((t (:inherit mindre-strong))))
   '(epa-validity-disabled ((t (:inherit mindre-faded))))
   '(epa-validity-high ((t (:inherit mindre-strong))))
   '(epa-validity-medium ((t (:inherit mindre-default))))
   '(epa-validity-low ((t (:inherit mindre-faded))))

   ;; --- Dired --------------------------------------------------------
   '(dired-directory ((t (:inherit (mindre-strong bold)))))
   `(dired-symlink ((t (:slant italic))))
   '(dired-marked ((t (:inherit mindre-salient))))
   `(dired-broken-symlink ((t (:slant italic :strike-through "#BF616A"))))

   ;; --- Eglot --------------------------------------------------------
   `(eglot-mode-line ((t (:foreground ,mindre-foreground))))
   `(eglot-mode-line-none-face ((t (:foreground ,mindre-foreground))))
   '(eglot-highlight-symbol-face ((t (:inherit underline))))

   ;; --- Eww ----------------------------------------------------
   `(eww-form-submit ((t (:box (:style released-button) :background ,mindre-background-3))))

   ;; --- Keycast ------------------------------------------------------
   `(keycast-key ((t :inherit nil :bold t)))
   `(keycast-command ((t :inherit mindre-default)))

   ;; --- Popup --------------------------------------------------------
   '(popup-face ((t (:inherit highlight))))
   '(popup-isearch-match ((t (:inherit mindre-strong))))
   '(popup-menu-face ((t (:inherit mindre-subtle))))
   '(popup-menu-mouse-face ((t (:inherit mindre-faded-i))))
   '(popup-menu-selection-face ((t (:inherit mindre-salient-i))))
   '(popup-menu-summary-face ((t (:inherit mindre-faded))))
   '(popup-scroll-bar-background-face ((t (:inherit mindre-subtle))))
   '(popup-scroll-bar-foreground-face ((t (:inherit mindre-subtle))))
   '(popup-summary-face ((t (:inherit mindre-faded))))
   '(popup-tip-face ((t (:inherit mindre-strong-i))))

   ;; --- Diff ---------------------------------------------------------
   '(diff-header ((t (:inherit mindre-faded))))
   '(diff-file-header ((t (:inherit mindre-strong))))
   '(diff-context ((t (:inherit mindre-default))))
   '(diff-removed ((t (:inherit mindre-faded))))
   '(diff-changed ((t (:inherit mindre-strong))))
   '(diff-added ((t (:inherit mindre-salient))))
   '(diff-refine-added ((t (:inherit (mindre-salient mindre-strong)))))
   '(diff-refine-changed ((t (:inherit mindre-strong))))
   '(diff-refine-removed ((t (:inherit mindre-faded :strike-through t))))

   ;; --- Message ------------------------------------------------------
   '(message-cited-text-1 ((t (:inherit mindre-faded))))
   '(message-cited-text-2 ((t (:inherit mindre-faded))))
   '(message-cited-text-3 ((t (:inherit mindre-faded))))
   '(message-cited-text-4 ((t (:inherit mindre-faded))))
   '(message-cited-text ((t (:inherit mindre-faded))))
   '(message-header-cc ((t (:inherit mindre-default))))
   '(message-header-name ((t (:inherit mindre-strong))))
   '(message-header-newsgroups ((t (:inherit mindre-default))))
   '(message-header-other ((t (:inherit mindre-default))))
   '(message-header-subject ((t (:inherit mindre-salient))))
   '(message-header-to ((t (:inherit mindre-salient))))
   '(message-header-xheader ((t (:inherit mindre-default))))
   '(message-mml ((t (:inherit mindre-strong))))
   '(message-separator ((t (:inherit mindre-faded))))

   ;; --- Outline ------------------------------------------------------
   '(outline-1 ((t (:inherit mindre-strong))))
   '(outline-2 ((t (:inherit mindre-strong))))
   '(outline-3 ((t (:inherit mindre-strong))))
   '(outline-4 ((t (:inherit mindre-strong))))
   '(outline-5 ((t (:inherit mindre-strong))))
   '(outline-6 ((t (:inherit mindre-strong))))
   '(outline-7 ((t (:inherit mindre-strong))))
   '(outline-8 ((t (:inherit mindre-strong))))

   ;; --- Orderless ------------------------------------------------------
   '(orderless-match-face-0 ((t (:inherit mindre-bold))))
   '(orderless-match-face-1 ((t (:inherit mindre-bold))))
   '(orderless-match-face-2 ((t (:inherit mindre-bold))))
   '(orderless-match-face-3 ((t (:inherit mindre-bold))))

   ;; --- Flyspell ----------------------------------------------------
   '(flyspell-duplicate ((t (:inherit mindre-warning))))
   `(flyspell-incorrect ((t (:inherit mindre-strong :underline (:style wave :color ,mindre-error)))))

   ;; --- Flymake ----------------------------------------------------
   `(flymake-error ((t (:underline (:style wave :color ,mindre-error)))))
   `(flymake-warning ((t (:underline (:style wave :color ,mindre-warning)))))
   `(flymake-note ((t (:underline (:style wave :color ,mindre-ok)))))
   `(compilation-error ((t (:foreground ,mindre-error))))
   `(compilation-warning ((t (:foreground ,mindre-warning))))
   `(compilation-mode-line-run ((t (:inherit mindre-foreground))))

   ;; --- Flycheck ----------------------------------------------------
   `(flycheck-error ((t (:underline (:style wave :color ,mindre-error)))))
   `(flycheck-warning ((t (:underline (:style wave :color ,mindre-warning)))))
   `(flycheck-info ((t (:underline (:style wave :color ,mindre-ok)))))

   ;; --- Org agenda ---------------------------------------------------
   '(org-agenda-calendar-event ((t (:inherit mindre-default))))
   '(org-agenda-calendar-sexp ((t (:inherit mindre-salient))))
   '(org-agenda-clocking ((t (:inherit mindre-faded))))
   '(org-agenda-column-dateline ((t (:inherit mindre-faded))))
   '(org-agenda-current-time ((t (:inherit mindre-strong))))
   '(org-agenda-date ((t (:inherit mindre-salient))))
   '(org-agenda-date-today ((t (:inherit (mindre-salient mindre-strong)))))
   '(org-agenda-date-weekend ((t (:inherit mindre-faded))))
   '(org-agenda-diary ((t (:inherit mindre-faded))))
   '(org-agenda-dimmed-todo-face ((t (:inherit mindre-faded))))
   '(org-agenda-done ((t (:inherit mindre-faded))))
   '(org-agenda-filter-category ((t (:inherit mindre-faded))))
   '(org-agenda-filter-effort ((t (:inherit mindre-faded))))
   '(org-agenda-filter-regexp ((t (:inherit mindre-faded))))
   '(org-agenda-filter-tags ((t (:inherit mindre-faded))))
   '(org-agenda-property-face ((t (:inherit mindre-faded))))
   '(org-agenda-restriction-lock ((t (:inherit mindre-faded))))
   '(org-agenda-structure ((t (:inherit mindre-strong))))

   ;; --- Org ----------------------------------------------------------
   '(org-archived ((t (:inherit mindre-faded))))
   '(org-block ((t (:inherit (mindre-block fixed-pitch)))))

   `(org-block-begin-line ((t (:inherit (mindre-faded fixed-pitch)
					:foreground "#585c60"
					:overline ,mindre-faded
					:background ,mindre-subtle
					:height 0.9
					:extend t))))
   `(org-block-end-line ((t (:inherit (mindre-faded fixed-pitch)
				      :background ,mindre-subtle
				      :height 0.9
				      :extend t))))

   '(org-checkbox ((t (:inherit (mindre-default fixed-pitch)))))
   '(org-checkbox-statistics-done ((t (:inherit (mindre-faded fixed-pitch)))))
   '(org-checkbox-statistics-todo ((t (:inherit (mindre-default fixed-pitch)))))
   '(org-clock-overlay ((t (:inherit mindre-faded))))
   '(org-code ((t (:inherit (fixed-pitch mindre-block)))))
   '(org-column ((t (:inherit mindre-faded))))
   '(org-column-title ((t (:inherit mindre-faded))))
   '(org-date ((t (:inherit mindre-faded))))
   '(org-date-selected ((t (:inherit mindre-faded))))
   '(org-default ((t (:inherit mindre-faded))))
   '(org-document-info ((t (:inherit mindre-faded))))
   '(org-document-info-keyword ((t (:inherit (mindre-faded fixed-pitch)))))
   '(org-document-title ((t (:inherit mindre-strong :height 1.8 :weight semibold))))
   '(org-done ((t (:foreground "#585c60"))))
   '(org-drawer ((t (:inherit (mindre-faded fixed-pitch)))))
   '(org-ellipsis ((t (:inherit mindre-faded))))
   '(org-footnote ((t (:inherit mindre-faded))))
   '(org-formula ((t (:inherit mindre-faded))))
   '(org-headline-done ((t (:foreground "#585c60"))))
   '(org-headline-todo ((t (:inherit mindre-default))))
   '(org-hide ((t (:inherit mindre-subtle-i))))
   '(org-indent ((t (:inherit mindre-subtle-i))))
   `(org-latex-and-related ((t (:inherit (mindre-default) :background ,mindre-background))))
   `(org-level-1 ((t (:inherit mindre-heading-1))))
   `(org-level-2 ((t (:inherit mindre-heading-1))))
   `(org-level-3 ((t (:inherit mindre-heading-1))))
   `(org-level-4 ((t (:inherit mindre-heading-1))))
   `(org-level-5 ((t (:inherit mindre-heading-1))))
   `(org-level-6 ((t (:inherit mindre-strong))))
   `(org-level-7 ((t (:inherit mindre-strong))))
   `(org-level-8 ((t (:inherit mindre-strong))))
   `(org-link ((t (:inherit link))))
   '(org-list-dt ((t (:inherit mindre-faded))))
   '(org-macro ((t (:inherit mindre-faded))))
   '(org-meta-line ((t (:inherit (mindre-faded fixed-pitch) :height 0.9))))
   '(org-mode-line-clock ((t (:inherit mindre-faded))))
   '(org-mode-line-clock-overrun ((t (:inherit mindre-faded))))
   '(org-priority ((t (:inherit mindre-faded))))
   '(org-property-value ((t (:inherit (mindre-faded fixed-pitch)))))
   '(org-quote ((t (:inherit mindre-default))))
   '(org-scheduled ((t (:inherit mindre-faded))))
   '(org-scheduled-previously ((t (:inherit mindre-faded))))
   '(org-scheduled-today ((t (:inherit mindre-faded))))
   '(org-sexp-date ((t (:inherit mindre-faded))))
   '(org-special-keyword ((t (:inherit (mindre-faded fixed-pitch)))))
   '(org-table ((t (:inherit (mindre-default fixed-pitch)))))
   '(org-tag ((t (:inherit mindre-strong))))
   '(org-tag-group ((t (:inherit mindre-faded))))
   '(org-target ((t (:inherit mindre-faded))))
   '(org-time-grid ((t (:inherit mindre-faded))))
   '(org-todo ((t (:inherit (mindre-salient mindre-strong)))))
   '(org-upcoming-deadline ((t (:inherit mindre-default))))
   '(org-verbatim ((t (:inherit (mindre-verbatim fixed-pitch)))))
   '(org-verse ((t (:inherit mindre-faded))))
   '(org-warning ((t (:inherit mindre-strong))))

   ;; --- Org modern ---------------------------------------------------
   `(org-modern-date-active ((t (:inherit org-modern-done :background ,mindre-background-3))))
   `(org-modern-statistics ((t (:inherit org-modern-done :background ,mindre-background-3))))
   `(org-modern-priority ((t (:inherit org-modern-done :background ,mindre-background-3))))
   `(org-modern-label ((t (:box (:color ,mindre-background :line-width (0 . -1))))))

   ;; --- Mu4e ---------------------------------------------------------
   '(mu4e-attach-number-face ((t (:inherit mindre-strong))))
   '(mu4e-cited-1-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-2-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-3-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-4-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-5-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-6-face ((t (:inherit mindre-faded))))
   '(mu4e-cited-7-face ((t (:inherit mindre-faded))))
   '(mu4e-compose-header-face ((t (:inherit mindre-faded))))
   '(mu4e-compose-separator-face ((t (:inherit mindre-faded))))
   '(mu4e-contact-face ((t (:inherit mindre-salient))))
   '(mu4e-context-face ((t (:inherit mindre-faded))))
   '(mu4e-draft-face ((t (:inherit mindre-faded))))
   '(mu4e-flagged-face ((t (:inherit mindre-strong))))
   '(mu4e-footer-face ((t (:inherit mindre-faded))))
   '(mu4e-forwarded-face ((t (:inherit mindre-default))))
   '(mu4e-header-face ((t (:inherit mindre-default))))
   '(mu4e-header-highlight-face ((t (:inherit highlight))))
   '(mu4e-header-key-face ((t (:inherit mindre-strong))))
   '(mu4e-header-marks-face ((t (:inherit mindre-faded))))
   '(mu4e-header-title-face ((t (:inherit mindre-strong))))
   '(mu4e-header-value-face ((t (:inherit mindre-default))))
   '(mu4e-highlight-face ((t (:inherit mindre-strong))))
   '(mu4e-link-face ((t (:inherit mindre-salient))))
   '(mu4e-modeline-face ((t (:inherit mindre-faded))))
   '(mu4e-moved-face ((t (:inherit mindre-faded))))
   '(mu4e-ok-face ((t (:inherit mindre-faded))))
   '(mu4e-region-code ((t (:inherit mindre-faded))))
   '(mu4e-replied-face ((t (:inherit mindre-default))))
   '(mu4e-special-header-value-face ((t (:inherit mindre-default))))
   '(mu4e-system-face ((t (:inherit mindre-faded))))
   '(mu4e-title-face ((t (:inherit mindre-strong))))
   '(mu4e-trashed-face ((t (:inherit mindre-faded))))
   '(mu4e-unread-face ((t (:inherit mindre-strong))))
   '(mu4e-url-number-face ((t (:inherit mindre-faded))))
   '(mu4e-view-body-face ((t (:inherit mindre-default))))
   '(mu4e-warning-face ((t (:inherit mindre-strong))))

   ;; --- Notmuch -------------------------------------------------------
   `(notmuch-crypto-decryption ((t (:inherit mindre-strong))))
   `(notmuch-crypto-part-header ((t (:inherit mindre-strong))))
   `(notmuch-crypto-signature-bad ((t (:inherit mindre-error))))
   `(notmuch-crypto-signature-good ((t (:inherit mindre-ok))))
   `(notmuch-crypto-signature-good-key ((t (:inherit mindre-ok))))
   `(notmuch-crypto-signature-unknown ((t (:inherit mindre-warning))))
   `(notmuch-search-count ((t (:inherit mindre-faded))))
   `(notmuch-search-unread-face ((t (:weight semibold))))
   `(notmuch-search-date ((t (:inherit mindre-default))))
   `(notmuch-search-matching-authors ((t (:inherit mindre-salient))))
   `(notmuch-search-non-matching-authors ((t (:inherit mindre-faded))))
   `(notmuch-search-subject ((t (:inherit mindre-default))))
   `(notmuch-tag-added ((t (:inherit mindre-verbatim :underline t))))
   `(notmuch-tag-deleted ((t (:inherit mindre-verbatim :strike-through t))))
   `(notmuch-tag-face ((t (:inherit mindre-verbatim))))
   `(notmuch-tag-flagged ((t (:inherit mindre-strong))))
   `(notmuch-tag-unread ((t (:inherit mindre-strong))))
   `(notmuch-tree-match-author-face ((t (:inherit mindre-salient))))
   `(notmuch-tree-match-subject-face ((t (:inherit mindre-default))))
   `(notmuch-tree-match-date-face ((t (:inherit mindre-default))))
   `(notmuch-tree-match-tag-face ((t (:inherit mindre-verbatim))))
   `(notmuch-tree-no-match-face ((t (:inherit mindre-faded))))
   `(notmuch-tree-no-match-date-face ((t (:inherit mindre-default))))

   ;; --- Elfeed -------------------------------------------------------
   '(elfeed-log-date-face ((t (:inherit mindre-faded))))
   '(elfeed-log-info-level-face ((t (:inherit mindre-default))))
   '(elfeed-log-debug-level-face ((t (:inherit mindre-default))))
   '(elfeed-log-warn-level-face ((t (:inherit mindre-strong))))
   '(elfeed-log-error-level-face ((t (:inherit mindre-strong))))
   '(elfeed-search-tag-face ((t (:inherit mindre-verbatim))))
   '(elfeed-search-date-face ((t (:inherit mindre-default))))
   '(elfeed-search-feed-face ((t (:inherit mindre-salient))))
   '(elfeed-search-filter-face ((t (:inherit mindre-faded))))
   '(elfeed-search-last-update-face ((t (:inherit mindre-salient))))
   '(elfeed-search-title-face ((t (:inherit mindre-default))))
   '(elfeed-search-unread-count-face ((t (:inherit mindre-strong))))
   '(elfeed-search-unread-title-face ((t (:inherit mindre-strong))))

   ;; --- Ivy --------------------------------------------------------
   `(ivy-minibuffer-match-face-1 ((t (:inherit mindre-strong))))
   `(ivy-minibuffer-match-face-2 ((t (:inherit mindre-strong))))
   `(ivy-minibuffer-match-face-3 ((t (:inherit mindre-strong))))
   `(ivy-minibuffer-match-face-4 ((t (:inherit mindre-strong))))

   ;; --- Rainbow delimeters ------------------------------------------
   '(rainbow-delimiters-depth-1-face ((t (:foreground "#b9bbbc"))))
   '(rainbow-delimiters-depth-2-face ((t (:foreground "#a2a4a6"))))
   '(rainbow-delimiters-depth-3-face ((t (:foreground "#8b8e90"))))
   '(rainbow-delimiters-depth-4-face ((t (:foreground "#737779"))))
   '(rainbow-delimiters-depth-5-face ((t (:foreground "#5c6063"))))
   '(rainbow-delimiters-depth-6-face ((t (:foreground "#45494d"))))
   '(rainbow-delimiters-depth-7-face ((t (:foreground "#2d3336"))))
   '(rainbow-delimiters-depth-8-face ((t (:inherit mindre-strong))))
   '(rainbow-delimiters-depth-9-face ((t (:inherit mindre-strong))))
   '(rainbow-delimiters-depth-10-face ((t (:inherit mindre-strong))))
   '(rainbow-delimiters-depth-11-face ((t (:inherit mindre-strong))))
   '(rainbow-delimiters-depth-12-face ((t (:inherit mindre-strong))))

   ;; --- Deft --------------------------------------------------------
   '(deft-filter-string-error-face ((t (:inherit mindre-strong))))
   '(deft-filter-string-face ((t (:inherit mindre-default))))
   '(deft-header-face ((t (:inherit mindre-salient))))
   '(deft-separator-face ((t (:inherit mindre-faded))))
   '(deft-summary-face ((t (:inherit mindre-faded))))
   '(deft-time-face ((t (:inherit mindre-salient))))
   '(deft-title-face ((t (:inherit mindre-strong))))

   ;; --- Restructured text -------------------------------------------
   '(rst-adornment ((t (:inherit mindre-faded))))
   '(rst-block ((t (:inherit mindre-default))))
   '(rst-comment ((t (:inherit mindre-faded))))
   '(rst-definition ((t (:inherit mindre-salient))))
   '(rst-directive ((t (:inherit mindre-salient))))
   '(rst-emphasis1 ((t (:inherit mindre-faded))))
   '(rst-emphasis2 ((t (:inherit mindre-strong))))
   '(rst-external ((t (:inherit mindre-salient))))
   '(rst-level-1 ((t (:inherit mindre-strong))))
   '(rst-level-2 ((t (:inherit mindre-strong))))
   '(rst-level-3 ((t (:inherit mindre-strong))))
   '(rst-level-4 ((t (:inherit mindre-strong))))
   '(rst-level-5 ((t (:inherit mindre-strong))))
   '(rst-level-6 ((t (:inherit mindre-strong))))
   '(rst-literal ((t (:inherit mindre-salient))))
   '(rst-reference ((t (:inherit mindre-salient))))
   '(rst-transition ((t (:inherit mindre-default))))

   ;; --- Markdown ----------------------------------------------------
   '(markdown-blockquote-face ((t (:inherit mindre-default))))
   '(markdown-bold-face ((t (:inherit mindre-strong))))
   `(markdown-code-face ((t (:inherit mindre-block))))
   '(markdown-comment-face ((t (:inherit mindre-faded))))
   '(markdown-footnote-marker-face ((t (:inherit mindre-default))))
   '(markdown-footnote-text-face ((t (:inherit mindre-default))))
   '(markdown-gfm-checkbox-face ((t (:inherit mindre-default))))
   '(markdown-header-delimiter-face ((t (:inherit mindre-faded))))
   '(markdown-header-face ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-1 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-2 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-3 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-4 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-5 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-face-6 ((t (:inherit (mindre-strong mindre-heading-1)))))
   '(markdown-header-rule-face ((t (:inherit mindre-default))))
   '(markdown-highlight-face ((t (:inherit mindre-default))))
   '(markdown-hr-face ((t (:inherit mindre-default))))
   '(markdown-html-attr-name-face ((t (:inherit mindre-default))))
   '(markdown-html-attr-value-face ((t (:inherit mindre-default))))
   '(markdown-html-entity-face ((t (:inherit mindre-default))))
   '(markdown-html-tag-delimiter-face ((t (:inherit mindre-default))))
   '(markdown-html-tag-name-face ((t (:inherit mindre-default))))
   '(markdown-inline-code-face ((t (:inherit mindre-strong))))
   '(markdown-italic-face ((t (:inherit mindre-faded))))
   '(markdown-language-info-face ((t (:inherit mindre-default))))
   '(markdown-language-keyword-face ((t (:inherit mindre-faded))))
   '(markdown-line-break-face ((t (:inherit mindre-default))))
   '(markdown-link-face ((t (:inherit mindre-salient))))
   '(markdown-link-title-face ((t (:inherit mindre-default))))
   '(markdown-list-face ((t (:inherit mindre-default))))
   '(markdown-markup-face ((t (:inherit mindre-faded))))
   '(markdown-math-face ((t (:inherit mindre-default))))
   '(markdown-metadata-key-face ((t (:inherit mindre-faded))))
   '(markdown-metadata-value-face ((t (:inherit mindre-faded))))
   '(markdown-missing-link-face ((t (:inherit mindre-default))))
   '(markdown-plain-url-face ((t (:inherit mindre-default))))
   `(markdown-pre-face ((t (:background ,mindre-subtle :extend t :inherit fixed-pitch))))
   '(markdown-reference-face ((t (:inherit mindre-salient))))
   '(markdown-strike-through-face ((t (:inherit mindre-faded))))
   '(markdown-table-face ((t (:inherit mindre-default))))
   '(markdown-url-face ((t (:inherit mindre-salient))))

   ;; --- Terminal ----------------------------------------------------
   '(term-bold ((t (:inherit mindre-strong))))
   '(term-color-black ((t (:inherit default))))
   '(term-color-blue ((t (:inherit default))))
   '(term-color-cyan ((t (:inherit default))))
   '(term-color-green ((t (:inherit mindre-note))))
   '(term-color-magenta ((t (:foreground "#5e429f" :background "#5e429f "))))
   '(term-color-red ((t (:foreground "#C74B50" :background "#C74B50 "))))
   '(term-color-yellow ((t (:foreground "#d47500" :background "#F8B400"))))

   ;; --- Haskell ----------------------------------------------------
   `(haskell-constructor-face ((t (:foreground ,mindre-salient-alt))))
   `(haskell-pragma-face ((t (:foreground ,mindre-highlight))))
   `(haskell-operator-face ((t (:inherit mindre-default))))

   ;; --- Nix ----------------------------------------------------
   `(nix-attribute-face ((t (:foreground ,mindre-foreground :bold nil))))

   ;; --- Sh ----------------------------------------------------
   `(sh-quoted-exec ((t (:foreground ,mindre-salient-alt))))

   ;; --- LaTeX ----------------------------------------------------
   `(font-latex-math-face ((t (:inherit (mindre-default fixed-pitch)))))
   `(font-latex-bold-face ((t (:inherit (bold)))))
   `(font-latex-warning-face ((t (:inherit (mindre-note fixed-pitch)))))
   `(font-latex-script-char-face ((t (:inherit mindre-default))))
   `(font-latex-sectioning-2-face ((t (:inherit bold :height 1.4))))

   ;; --- Geiser ----------------------------------------------------
   `(geiser-font-lock-autodoc-current-arg ((t :inherit mindre-verbatim)))
   `(geiser-font-lock-autodoc-identifier ((t :inherit mindre-salient)))))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
	       (file-name-as-directory (file-name-directory load-file-name))))

;;;###autoload
(when mindre-use-faded-lisp-parens
  (add-hook 'lisp-data-mode-hook #'mindre--font-lock-add-paren)
  (add-hook 'scheme-mode-hook #'mindre--font-lock-add-paren))

;;;###autoload
(run-hooks 'mindre-after-load-hook)

(provide-theme 'mindre)

;;; mindre-theme.el ends here
