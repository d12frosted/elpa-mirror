;;; stripes.el --- highlight alternating lines differently -*- lexical-binding: t -*-

;; Author: Michael Schierl <schierlm-public@gmx.de>
;;         Štěpán Němec <stepnem@smrk.net>
;; Maintainer: Štěpán Němec <stepnem@smrk.net>
;; Created: 02 October 2003
;; URL: http://git.smrk.net/stripes.el
;; Package-Version: 20230402.1228
;; Package-Commit: 4683c9020da14bb1c1f74b90d27a4d9fdc7a9147
;; Keywords: convenience faces
;; License: public domain
;; Version: 0.4b
;; Tested-with: GNU Emacs 29
;; Package-Requires: ((emacs "24.3"))

;;; Commentary:

;; Highlight every other `stripes-unit' lines with an alternative
;; background color.  Useful for buffers that display lists of any
;; kind, as a guide for your eyes to follow.

;; The sole entry point of this library is the command `stripes-mode',
;; which you can invoke manually or from a suitable hook.  Note that
;; in some cases the choice of the right hook might not be entirely
;; obvious, e.g. for `dired' you have to use `dired-after-readin-hook'
;; instead of `dired-mode-hook' unless you're using Emacs >= 28:
;; https://gitlab.com/stepnem/stripes-el/-/issues/1#note_309176403

;;; Related / history:

;; Before deciding to go the minimal way I also stumbled upon (and
;; discarded just by looking at) the following:

;;   https://github.com/sabof/stripe-buffer

;; ...and an apparently unfinished attempt at rewriting it:

;;   https://github.com/michael-heerdegen/stripe-buffer

;; Michael Schierl's last version (0.2) this is based off can still be
;; found in the git repository (first commit) or at the EmacsWiki:
;; https://www.emacswiki.org/emacs/stripes.el

;; Corrections and productive feedback appreciated, publicly
;; (<public@smrk.net>, inbox.smrk.net) or in private.

;;; Code:

(defgroup stripes () "Highlight alternating lines differently."
  :group 'convenience)

(defcustom stripes-unit 3 "Number of lines making up a single color unit."
  :type 'integer)

(defcustom stripes-overlay-priority nil
  "Priority of stripe overlays.
See Info node `(elisp) Overlay Properties' for allowed values and
their semantics."
  :type '(choice (const nil) integer)
  :package-version '(stripes . "0.4"))

(defface stripes `((((min-colors 88) (background dark))
                    (:background "#222222"
                                 ,@(unless (version< emacs-version "27")
                                     '(:extend t))))
                   (((min-colors 88) (background light))
                    (:background "#f4f4f4"
                                 ,@(unless (version< emacs-version "27")
                                     '(:extend t))))
                   (t (:italic t)))
  "Face for alternate lines.")

;;;###autoload
(define-minor-mode stripes-mode
  "Highlight alternating lines differently.

Highlight every other `stripes-unit' lines with an alternative
background color.  Useful for buffers that display lists of any
kind, as a guide for your eyes to follow these lines.

When called interactively with a positive prefix argument, set
`stripes-unit' locally (= in the current buffer) to its value, in
addition to enabling the mode." :lighter ""
  (unless (or executing-kbd-macro noninteractive)
    (if (not stripes-mode)
        (message "Stripes mode disabled")
      (when current-prefix-arg
        (let ((num (prefix-numeric-value current-prefix-arg)))
          (when (> num 0)
            (setq-local stripes-unit num))))
      (if (= stripes-unit 1)
          (message "Stripes mode enabled")
        (message "Stripes mode (%i lines) enabled"
                 stripes-unit))))
  (if stripes-mode
      (progn
        (stripes-create)
        (add-hook 'after-change-functions #'stripes-create nil t))
    (stripes-remove)
    (remove-hook 'after-change-functions #'stripes-create t)))

(defun stripes-remove ()
  "Remove all alternation colors."
  (remove-overlays nil nil 'face 'stripes))

(defun stripes-create (&rest _)
  "Color alternate lines in current buffer differently."
  (stripes-remove)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (forward-line stripes-unit)
      (unless (eobp)
        (let ((p (point)))
          (forward-line stripes-unit)
          (let ((ol (make-overlay p (point))))
            (overlay-put ol 'face 'stripes)
            (overlay-put ol 'priority stripes-overlay-priority)))))))

(provide 'stripes)
;;; stripes.el ends here
