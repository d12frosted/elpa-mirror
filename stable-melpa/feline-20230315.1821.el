;;; feline.el --- A modeline with very little  -*- lexical-binding: t; -*-

;; Author: chee <emacs@chee.party>
;; Homepage: https://opensource.chee.party/chee/feline-mode
;; Version: 1.1
;; Package-Version: 20230315.1821
;; Package-Commit: 3f9247f48058285d3e03957680e011ecf58d6feb
;; Package-Requires: ((emacs "28.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; feline is a fast, low-frills modeline replacement for Emacs.

;; feline saves space by displaying only a few things:
;;   • evil state
;;     (state name and customizable colour)
;;   • file-edited state
;;     (a * if edited)
;;   • the major mode
;;     (or a customizable shorthand/symbol alias)
;;   • buffer ID
;;     (e.g. filename)
;;   • the current project.el project name
;;     (if active)
;;   • line and column number
;;     (like L18C40)
;;   • `mode-line-misc-info'
;;     (a place that modes put useful info sometimes)

;; Each segment has its own customizable face.  You'll notice that list does not
;; mention minor modes.  feline doesn't show minor modes.  The information it
;; chooses to show is very useful, and being limited like this lets it be very
;; fast and nimble.

;;; Code:

(defgroup feline nil
  "The feline modeline."
  :group 'mode-line
  :link '(url-link
           :tag "Homepage" "https://opensource.chee.party/chee/feline-mode"))

(defgroup feline-faces nil
  "Feline faces."
  :group 'feline
  :group 'faces
  :link '(url-link
           :tag "Homepage" "https://opensource.chee.party/chee/feline-mode"))

(defface feline-buffer-id-face
  '((t ()))
  "The buffer's name in the feline."
  :group 'feline-faces)

(defface feline-major-mode-face
  '((t (:weight bold)))
  "The major mode's name in the feline."
  :group 'feline-faces)

(defface feline-position-prefix-face
  '((t (:inherit font-lock-comment-face)))
  "The prefix for line and column positions in the feline."
  :group 'feline-faces)

(defface feline-project-name-face
  '((t (:weight bold)))
  "The name of the current project in the feline."
  :group 'feline-faces)

(defface feline-evil-state-face
  '((t (:weight bold)))
  "A face for evil states in the feline.
Every feline evil state indicator state inherits from this."
  :group 'feline-faces)

(defface feline-evil-normal-face
  '((t (:inherit feline-evil-state-face
			:background "black"
			:foreground "white")))
  "The evil normal state feline indicator."
  :group 'feline-faces)

(defface feline-evil-emacs-face
  '((t (:inherit feline-evil-state-face
			:background "#3366ff"
			:foreground "white")))
  "The evil Emacs state feline indicator."
  :group 'feline-faces)

(defface feline-evil-insert-face
  '((t (:inherit feline-evil-state-face
			:background "#3399ff"
			:foreground "white")))
  "The evil insert state feline indicator."
  :group 'feline-faces)

(defface feline-evil-replace-face
  '((t (:inherit feline-evil-state-face
			:background "#33ff99"
			:foreground "black")))
  "The evil replace state feline indicator."
  :group 'feline-faces)

(defface feline-evil-operator-face
  '((t (:inherit feline-evil-state-face
			:background "pink"
			:foreground "black")))
  "The evil operator state feline indicator."
  :group 'feline-faces)

(defface feline-evil-motion-face
  '((t (:inherit feline-evil-state-face
			:background "purple"
			:foreground "white")))
  "The evil motion state feline indicator."
  :group 'feline-faces)

(defface feline-evil-visual-face
  '((t (:inherit (region feline-evil-state-face))))
  "The evil visual state feline indicator."
  :group 'feline-faces)

(defface feline-position-face
  '((t (:inherit font-lock-constant-face)))
  "The value for the line and column positions."
  :group 'feline-faces)

(defcustom feline-line-prefix
  "l"
  "The prefix for line number."
  :type 'string
  :group 'feline)

(defcustom feline-column-prefix
  "c"
  "The prefix for column number."
  :type 'string
  :group 'feline)

(defcustom feline-mode-symbols
  '()
  "The replacement for a mode's name.
The key is the full mode name including -mode, i.e. \"emacs-lisp-mode\".
If there is no match, the fallback is the mode name without the -mode suffix."
  :type '(plist :key-type symbol :value-type string)
  :group 'feline)

(defun feline-get-mode-symbol (mode)
  "Get an symbol representation for MODE from the list `feline-mode-symbol'."
  (propertize
	 (or
		(plist-get
		  feline-mode-symbols mode)
		(format "%s" mode))
	 'face 'feline-major-mode-face))

(defun feline-mode-name (mode)
  "Get a feline representation of MODE."
  (replace-regexp-in-string "-mode$" "" (feline-get-mode-symbol mode)))

(defun feline-major-mode nil
  "Get a feline representation of the major mode."
  (feline-mode-name major-mode))

(defun feline-buffer-id (buffer-id)
  "Get a feline representation of BUFFER-ID."
  (propertize
	 (replace-regexp-in-string
		"\\*Org Src \\([^[]*\\)\\[ \\(.*\\) +]"
		" \\1→src(\\2)"
		buffer-id)
	 'face 'feline-buffer-id-face))

(defun feline-evil nil
  "Get a feline representation of the evil mode."
  (when-let ((state (bound-and-true-p evil-state)))
	  (propertize (symbol-name state) 'face
      (intern (format "feline-evil-%s-face" state)))))

(defun feline-positions nil
  "Present the line and column in the feline."
  (concat (propertize
		      feline-line-prefix
		      'face 'feline-position-prefix-face)
	 (propertize
		"%l"
		'face 'feline-position-face)
	 (propertize
		feline-column-prefix
		'face 'feline-position-prefix-face)
	 (propertize
		"%c"
		'face 'feline-position-face)))

(defvar feline--project-name-cache '())

(defun feline--project-name nil
  "Get the current project, if we're in one."
  (condition-case nil
    (when (fboundp 'project-name)
      (project-name (project-current)))
    (error nil)))

(defun feline-project-name nil
  "Get a feline representation of the current project name."
  (let* ((filename (buffer-file-name))
			 (cached (plist-get feline--project-name-cache filename)))
	 (format
		"(%s)"
		(propertize
		  ;; tramp makes this _really slow_ so we're gonna just exit sideways
		  (if (and (fboundp 'tramp-tramp-file-p) (tramp-tramp-file-p filename))
			 "TRAMP"
	       (if cached cached
			   (or (feline--project-name) "")))
		  'mouse-face 'mode-line-highlight
		  'local-map (let ((🐈‍⬛ (make-sparse-keymap)))
			            (define-key 🐈‍⬛ [mode-line mouse-1] 'project-switch-project)
			            🐈‍⬛)
		  'face 'feline-project-name-face))))

(defvar feline-original-modeline mode-line-format)

(defvar feline-mode nil "\"t\" if feline is active.")

(defun feline-spray nil
  "Stop feline, returning the previous modeline."
  (setq feline-mode nil)
  (setq-default mode-line-format feline-original-modeline))

(defun feline-purr nil
  "Start feline."
  (setq feline-mode t)
  (setq-default
	 mode-line-format
	 '(""
		 (:eval (feline-evil))
		 " "
		 (:eval (propertize (if (buffer-modified-p) "*" "") 'face 'feline-buffer-id-face))
		 (:eval (feline-major-mode))
		 " "
		 (:eval (feline-buffer-id (format-mode-line "%b")))
		 " "
		 (:eval (feline-project-name))
		 " "
		 (:eval (feline-positions))
		 " "
		 mode-line-misc-info)))

;;;###autoload
(define-minor-mode feline-mode
  "Toggle _f_e_l_i_n_e_."
  :group 'feline
  :global t
  :lighter nil
  (if feline-mode
	 (feline-purr)
	 (feline-spray)))

(provide 'feline)

;;; feline.el ends here
