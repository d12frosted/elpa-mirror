;;; atl-markup.el ---  Automatically truncate lines for markup languages  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-07-22 17:11:15

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Automatically truncate lines for markup languages.
;; Keyword: automatic truncate visual lines
;; Version: 0.1.5
;; Package-Version: 20210731.609
;; Package-Commit: 69780e11cfccbd05516b7c2724e02242e3d188d7
;; Package-Requires: ((emacs "24.3"))
;; URL: https://github.com/jcs-elpa/atl-markup

;; This file is NOT part of GNU Emacs.

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
;;
;; Automatically truncate lines for markup languages.
;;

;;; Code:

(defgroup atl-markup nil
  "Automatically truncate lines for markup languages."
  :prefix "atl-markup-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/atl-markup"))

(defcustom atl-markup-ignore-regex "[ \t\r\n]"
  "Regular expression string that will ignore auto truncate lines' action."
  :type 'string
  :group 'atl-markup)

(defcustom atl-markup-delay 0.1
  "Time delay to active auto truncate lines for markup languages."
  :type 'float
  :group 'atl-markup)

(defvar atl-markup--timer nil
  "Timer to active auto truncate lines.")

;;; Util

(defun atl-markup--comment-block-p ()
  "Return non-nil if current cursor is on comment."
  (nth 4 (syntax-ppss)))

(defun atl-markup--mute-apply (fnc &rest args)
  "Execute FNC with ARGS without message."
  (let ((message-log-max nil))
    (with-temp-message (or (current-message) nil)
      (let ((inhibit-message t))
        (apply fnc args)))))

(defun atl-markup--inside-tag-p ()
  "Check if current point inside the tag."
  (let ((backward-less (save-excursion (search-backward "<" nil t)))
        (backward-greater (save-excursion (search-backward ">" nil t)))
        (forward-less (save-excursion (search-forward "<" nil t)))
        (forward-greater (save-excursion (search-forward ">" nil t))))
    (unless backward-less (setq backward-less -1))
    (unless backward-greater (setq backward-greater -1))
    (unless forward-less (setq forward-less -1))
    (unless forward-greater (setq forward-greater -1))
    (and (not (= -1 backward-less))
         (not (= -1 forward-greater))
         (< backward-greater backward-less)
         (or (< forward-greater forward-less)
             (= -1 forward-less)))))

;;; Core

(defun atl-markup--web-truncate-lines-by-face ()
  "Enable/Disable the truncate lines mode depends on the face cursor currently on."
  (when (and (not (bobp)) (not (eobp))
             (not (save-excursion
                    (backward-char 1)
                    (looking-at-p atl-markup-ignore-regex)))
             (not (atl-markup--comment-block-p))
             (not (eolp)))
    (atl-markup--mute-apply
     (lambda ()
       (if (atl-markup--inside-tag-p)
           (toggle-truncate-lines 1) (toggle-truncate-lines -1))))))

(defun atl-markup--post-command-hook ()
  "Post command hook to do auto truncate lines in current buffer."
  (when (timerp atl-markup--timer)
    (cancel-timer atl-markup--timer)
    (setq atl-markup--timer nil))
  (run-with-idle-timer atl-markup-delay nil 'atl-markup--web-truncate-lines-by-face))

(defun atl-markup--enable ()
  "Enable 'atl-markup-mode'."
  (add-hook 'post-command-hook 'atl-markup--post-command-hook nil t))

(defun atl-markup--disable ()
  "Disable 'atl-markup-mode'."
  (remove-hook 'post-command-hook 'atl-markup--post-command-hook t))

;;;###autoload
(define-minor-mode atl-markup-mode
  "Minor mode 'atl-markup-mode'."
  :lighter " ATL-MrkUp"
  :group atl-markup
  (if atl-markup-mode (atl-markup--enable) (atl-markup--disable)))

(provide 'atl-markup)
;;; atl-markup.el ends here
