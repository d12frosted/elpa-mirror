;;; comment-tags.el --- Highlight and navigate comment tags like TODO, FIXME, etc -*- lexical-binding: t -*-

;; Copyright © 2017 Vincent Dumas <vincekd@gmail.com>

;; Author: Vincent Dumas <vincekd@gmail.com>
;; URL: https://github.com/vincekd/comment-tags
;; Package-Version: 20170807.15
;; Package-Commit: 293a30026d7750f6657d6c2e6d6428abf1d7db5a
;; Keywords: convenience, comments, tags
;; Version: 0.1
;; Package-Requires: ((emacs "24.5") (pkg-info "0.4"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;

;;; TODO:
;; + find tags in current buffer with keyword search
;; + find tags in all buffers with keyword search
;; + allow differrent fonts for different `comment-tags/keywords'
;; + allow input of buffer name in `comment-tags/list-tags-buffer'

;;; Code:


(require 'cl-lib)


;;; customize
(defgroup comment-tags nil
  "Highlight and navigate comment tags."
  :group 'tools
  :link '(url-link :tag "Github" "https//github.com/vincekd/comment-tags"))

(defcustom comment-tags/keywords
  '("TODO"
    "FIXME"
    "BUG"
    "HACK"
    "XXX"
    "KLUDGE")
  "Keywords to highlight and track."
  :group 'comment-tags
  :type '(repeat string))

(defcustom comment-tags/require-colon t
  "Require colon after tags."
  :group 'comment-tags
  :type 'boolean)

(defcustom comment-tags/comment-start-only nil
  "Only highlight and track tags that are the beginning of a comment."
  :group 'comment-tags
  :type 'boolean)

(defcustom comment-tags/foreground-color "Red"
  "Font foreground color."
  :group 'comment-tags
  :type 'string)

(defcustom comment-tags/background-color nil
  "Font background color."
  :group 'comment-tags
  :type 'string)

(defcustom comment-tags/keymap-prefix (kbd "C-c c")
  "Prefix for keymap."
  :group 'comment-tags
  :type 'string)

(defconst comment-tags/temp-buffer-name "*comment-tags*"
  "Name for temp buffers to list tags.")

(defface comment-tags/face
  `((t :foreground ,comment-tags/foreground-color
       :background ,comment-tags/background-color
       :weight bold
       :underline nil))
  "Font face for highlighted tags."
  :group 'comment-tags)


;;; funcs
(defun comment-tags--join (list joiner)
  "Helper function to join LIST of string with JOINER."
  (mapconcat 'identity list joiner))

(defun comment-tags--make-regexp ()
  "Create regexp from `comment-tags/keywords'."
  (concat "\\<\\(\\(?:" (comment-tags--join comment-tags/keywords "\\|") "\\):"
          (if (not comment-tags/require-colon)
              "?"
            "") "\\)"))

(defun comment-tags--syntax-propertize-function (start end)
  "Find tags in buffer between START and END.
Mark with `comment-tags/highlight' prop."
  (let ((case-fold-search nil)
        (inhibit-modification-hooks t))
    (goto-char start)
    ;;(setq-local comment-tags/buffer-tags '())
    (remove-text-properties start end '(comment-tags/highlight))
    (funcall
     (syntax-propertize-rules
      ((comment-tags--make-regexp)
       (0 (ignore (comment-tags--find-tags)))))
     start end)))

(defun comment-tags--find-tags ()
  "Highlight tags in var `comment-tags/keywords'."
  (save-excursion
    (let* ((end-p (point))
           (start-p (match-beginning 0))
           (in-comment (and (nth 4 (syntax-ppss start-p)) (nth 4 (syntax-ppss end-p))))
           (comment-start (nth 8 (syntax-ppss start-p))))
      (when (and in-comment
                 (or (not comment-tags/comment-start-only)
                     (save-match-data
                       (string-match
                        (rx bol (0+ (not alphanumeric)) eol)
                        (buffer-substring-no-properties comment-start start-p)))))
        (put-text-property start-p end-p 'comment-tags/highlight (match-data))))))

(defun comment-tags--highlight-tags (limit)
  "Find areas marked with `comment-tags/highlight' and apply proper face within LIMIT."
  (let* ((pos (point))
         (chg (next-single-property-change pos 'comment-tags/highlight nil limit))
         (reg (comment-tags--make-regexp)))
    (when (and chg (> chg pos))
      (goto-char chg)
      (let ((value (get-text-property chg 'comment-tags/highlight)))
        (if value
            (progn
              (set-match-data value)
              t)
          (comment-tags--highlight-tags limit))))))

(defun comment-tags--find-matched-tags (start)
  "Utility function to find list of text marked with `comment-tags/highlight' from START on."
  (save-excursion
    (goto-char start)
    (let ((chg (next-single-property-change start 'comment-tags/highlight nil nil))
          (out (list)))
      (when (and chg (> chg start))
        (goto-char chg)
        (let ((val (get-text-property chg 'comment-tags/highlight)))
          (when val
            (push (list
                   (count-lines 1 chg)
                   (buffer-substring (line-beginning-position) (line-end-position)))
                  out))
          (setq out (append out (comment-tags--find-matched-tags chg)))))
      out)))


(defun comment-tags--buffer-tags (buffer)
  "Find all comment tags in BUFFER."
  (with-current-buffer buffer
    (save-excursion
      (beginning-of-buffer)
      (comment-tags--find-matched-tags (point)))))


(defun comment-tags--format-tag-string (tag)
  "Format a TAG for insertion into the temp buffer."
  (format "%d:\t%s\n" (car tag) (nth 1 tag)))


(defun comment-tags--format-buffer-string (buf-name)
  "Format a buffer BUF-NAME for separation in temp buffer."
  (format "** COMMENT TAGS in '%s' **\n\n" buf-name))


(defun comment-tags--open-buffer-at-line (buf line)
  "Opens BUF at LINE."
  (pop-to-buffer buf)
  (goto-line line))


;;;###autoload
(defun comment-tags/list-tags-buffer ()
  "List all tags in the current buffer."
  (interactive)
  (let ((oldbuf (current-buffer))
        (oldbuf-name (buffer-name)))
    (with-temp-buffer-window
     comment-tags/temp-buffer-name nil nil
     (pop-to-buffer comment-tags/temp-buffer-name)
     (insert (comment-tags--format-buffer-string oldbuf-name))
     (dolist (element (comment-tags--buffer-tags oldbuf))
       (insert-text-button
        (comment-tags--format-tag-string element)
        'action (lambda (a)
                  (comment-tags--open-buffer-at-line oldbuf (car element))))))))


;; TODO: search comments after tags?
;;;###autoload
(defun comment-tags/find-tags-buffer (&optional args)
  ;; TODO: finish this
  "List tags with ARGS in the current buffer."
  (interactive)
  (message "comment-tags/find-tags-buffer"))


;;;###autoload
(defun comment-tags/list-tags-buffers ()
  "List tags for all open buffers."
  (interactive)
  (with-temp-buffer-window
   comment-tags/temp-buffer-name nil nil
   (pop-to-buffer comment-tags/temp-buffer-name)
   ;; list all buffers with comment-tags-mode enabled
   (dolist (buf (cl-remove-if-not
                 (lambda (b)
                   (with-current-buffer b
                     (and (boundp 'comment-tags-mode) comment-tags-mode)))
                 (buffer-list)))
     (let ((buf-name (with-current-buffer buf (buffer-name)))
           (tags (comment-tags--buffer-tags buf)))
       (when tags
         (insert (comment-tags--format-buffer-string buf-name))
         (dolist (element tags)
           (insert-text-button
            (comment-tags--format-tag-string element)
            'action (lambda (a)
                      (comment-tags--open-buffer-at-line buf (car element)))))
         (insert "\n"))))))


;; enable/disable functions
(defun comment-tags--enable ()
  "Enable 'comment-tags-mode'."
  (set (make-local-variable 'syntax-propertize-function)
       #'comment-tags--syntax-propertize-function)
  (font-lock-add-keywords nil comment-tags/font-lock-keywords))

(defun comment-tags--disable ()
  "Disable 'comment-tags-mode'."
  (set (make-local-variable 'syntax-propertize-function) nil)
  (font-lock-remove-keywords nil comment-tags/font-lock-keywords))


;;; vars
(defvar comment-tags/font-lock-keywords
  `((comment-tags--highlight-tags 1 'comment-tags/face t))
  "List of font-lock keywords to add to `default-keywords'.")

(defvar comment-tags/command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "b") #'comment-tags/list-tags-buffer)
    (define-key map (kbd "a") #'comment-tags/list-tags-buffers)
    (define-key map (kbd "s") #'comment-tags/find-tags-buffer)
    map)
  "Command map.")
(fset 'comment-tags/command-map comment-tags/command-map)

(defvar comment-tags/mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map comment-tags/keymap-prefix 'comment-tags/command-map)
    map)
  "Keymap for Comment-Tags mode.")


;;;###autoload
(define-minor-mode comment-tags-mode
  "Highlight and navigate comment tags."
  :lighter "Comment Tags"
  :group 'comment-tags
  :require 'comment-tags
  :global nil
  :keymap comment-tags/mode-map
  (if comment-tags-mode
      (comment-tags--enable)
    (comment-tags--disable))
  (font-lock-mode 1))

(provide 'comment-tags)

;;; comment-tags.el ends here
