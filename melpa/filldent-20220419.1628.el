;;; filldent.el --- Fill or indent                  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Case Duckworth

;; Author: Case Duckworth <acdw@acdw.net>
;; URL: https://github.com/duckwork/filldent.el
;; Package-Version: 20220419.1628
;; Package-Commit: b55fd3aae9f389b76fe695b300984188f24f9366
;; Version: 1.0.1
;; Package-Requires: ((emacs "24.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; From a conversation in #emacs, where someone was confused about M-q vs.
;; C-M-\.  I realized that we rarely want to indent prose, or fill programming,
;; so let's do a dwim-style thing.  That's filldent.

;; Apparently `paredit' already has a binding like this, set to M-q.  Very
;; interesting.

;;; Code:

;;; Variables

(defgroup filldent nil
  "Fill or indent buffer text depending on mode."
  :prefix "filldent-"
  :group 'convenience)

(defcustom filldent-fill-modes '(tex-mode text-mode)
  "Modes in which `filldent-dwim' and friends will fill.
Recommended: text-ish modes."
  :type '(repeat function))

(defcustom filldent-indent-modes '(prog-mode)
  "Modes in which `filldent-dwim' and friends will indent.
Recommended: prog-ish modes."
  :type '(repeat function))

(defcustom filldent-default 'fill
  "What to do if confused.
If a mode doesn't derive from any of the modes in
`filldent-fill-modes' or `filldent-indent-modes', this defines
the default thing to do.

Possible values are `fill' and `indent'."
  :type '(choice (const :tag "Fill" 'fill)
                 (const :tag "Indent" 'indent)))

(defcustom filldent-fill-comments-and-strings t
  "Whether to fill comments and strings in `indent' modes.
This option only takes effect when calling `filldent-paragraph',
because a region might span multiple syntactic elements.

When t, if the point is on a comment or string in an `indent'
mode, instead of indenting the current defun, fill the current
paragraph.  When nil, indent the current defun.

This defaults to t to fulfill the principle of least-surprise, at
least for the author."
  :type '(choice (const :tag "Fill comments and strings" t)
                 (const :tag "Indent the containing function" nil)))

;;; Functions

(defun filldent--type (&optional buffer)
  "Determine what type of buffer we're in.
BUFFER can be the name of a buffer, a buffer object, but defaults
to the current buffer.  This function returns the symbol `fill'
or `indent'."
  (with-current-buffer (or buffer (current-buffer))
    (cond
     ((apply #'derived-mode-p filldent-fill-modes)
      'fill)
     ((apply #'derived-mode-p filldent-indent-modes)
      'indent)
     (t filldent-default))))

;;;###autoload
(defun filldent-region (beg end &optional arg)
  "Filldent region from BEG to END.
Optional prefix ARG determines whether to justify the text (when
filling) or the number of spaces to indent the text (when
indenting)."
  (interactive "*r\nP")
  (pcase (filldent--type)
    ('indent (indent-region beg end arg))
    ('fill (fill-region beg end arg))))

;;;###autoload
(defun filldent-paragraph (&optional arg)
  "Filldent defun or paragraph at point.
Optional prefix ARG determines whether to justify the text (when
filling) or the number of spaces to indent the text (when
indenting)."
  (interactive "*P")
  (pcase (filldent--type)
    ('indent (if (and filldent-fill-comments-and-strings
                      (or (nth 3 (syntax-ppss))
                          (nth 4 (syntax-ppss))))
                 (fill-paragraph arg)
               (save-excursion
                 (mark-defun)
                 (indent-region (region-beginning) (region-end) arg))))
    ('fill (fill-paragraph arg))))

;;;###autoload
(defun filldent-dwim (&optional arg)
  "Filldent defun or paragraph at point, or region, if it's active.
Optional prefix ARG determines whether to justify the text (when
filling) or the number of spaces to indent the text (when
indenting)."
  (interactive "*P")
  (if (region-active-p)
      (filldent-region (region-beginning) (region-end) arg)
    (filldent-paragraph arg)))

;;;###autoload
(defun filldent-fill-then-indent-dwim (&optional arg)
  "Fill and indent region if active, or current defun/paragraph.
Optional ARG causes the paragraph to \"unfill.\""
  ;; I include this function as an alternative to the "smarter" `filldent-dwim',
  ;; which I used for a bit before making `filldent-paragraph' smarter.
  ;;
  ;; Possible TODO: make calling this twice in a row restore the buffer how it
  ;; was.
  (interactive "*P")
  (let ((fill-column (if arg most-positive-fixnum fill-column)))
    (if (region-active-p)
        (progn
          (fill-region (region-beginning) (region-end))
          (indent-region (region-beginning) (region-end)))
      (progn
        (fill-paragraph)
        (save-excursion
          (mark-defun)
          (indent-region (region-beginning) (region-end)))))))

;;; Unfill commands
;; basically filldent-modified versions of Steve Purcell's `unfill' library

;;;###autoload
(defun filldent-unfill-paragraph ()
  "Replace newline chars in current paragraph by single spaces.
This command does the inverse of `filldent-paragraph'."
  (interactive)
  (let ((fill-column most-positive-fixnum))
    (call-interactively #'filldent-paragraph)))

;;;###autoload
(defun filldent-unfill-region (start end)
  "Replace newline chars in region from START to END by single spaces.
This command does the inverse of `filldent-region'."
  (interactive "r")
  (let ((fill-column most-positive-fixnum))
    (filldent-region start end)))

;;;###autoload
(defun filldent-unfill-toggle (&optional arg)
  "Toggle filldent/unfill of current paragraph, or active
region. Optional prefix ARG is passed on to `filldent-dwim'."
  (interactive "*P")
  (let (deactivate-mark
        (fill-column
         (if (eq last-command this-command)
             (progn (setq this-command nil)
                    most-positive-fixnum)
           fill-column)))
    (call-interactively #'filldent-dwim)))

(provide 'filldent)
;;; filldent.el ends here
