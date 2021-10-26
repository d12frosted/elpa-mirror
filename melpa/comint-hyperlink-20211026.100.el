;;; comint-hyperlink.el --- Create hyperlinks in comint for SGR URL control sequences -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Matthew Bauer

;; Author: Matthew Bauer <mjbauer95@gmail.com>
;; Created: 15 Aug 2019
;; Keywords: comint, shell, processes, hypermedia, terminals
;; Package-Version: 20211026.100
;; Package-Commit: 905f2db1f95950899301b9f71faed9e9362cf5dc
;; Version: 0.1.6
;; Homepage: https://github.com/matthewbauer/comint-hyperlink
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;; This file is free software...

;;; Commentary:

;; A filter for comint.el to make URLs clickable from control
;; sequences. Coreutils outputs these when you run ‘ls --hyperlink’.

;; See
;; https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
;; for more information.

;;; Usage:

;;; Usage is pretty straightforward, just require this Elisp file and
;;; add comint-hyperlink-process-output to
;;; comint-input-filter-functions. For vanilla Emacs, this looks like
;;; adding the below snippet to your init.el file.

;; (require 'comint-hyperlink)
;; (add-to-list 'comint-output-filter-functions
;;              'comint-hyperlink-process-output)

;;; Alternatively if you use use-package, this looks like the following.

;; (use-package comint-hyperlink
;;   :commands (comint-hyperlink-process-output)
;;   :init (add-to-list 'comint-output-filter-functions
;;                   'comint-hyperlink-process-output))

;;; Code:

(require 'comint)
(require 'button)
(require 'url-util)
(require 'regexp-opt)

(defvar comint-hyperlink-control-seq-regexp
  "\e\\]8;;\\([^\a\e]*\\)[\a\e]\\(?:\\\\\\)?\\([^\e]*\\)\e]8;;[\a\e]\\(?:\\\\\\)?")

(defvar comint-hyperlink-file-regexp
  "^file://\\([^/]*\\)")

(defvar comint-hyperlink-url-protocols
  (regexp-opt '("http" "https" "ftp" "man" "mailto" "news")))

(defgroup comint-hyperlink nil
  "Comint hyperlink handling"
  :group 'comint)

(defcustom comint-hyperlink-action 'comint-hyperlink-find-file
  "Action to use in comint-hyperlink button."
  :group 'comint-hyperlink
  :type '(choice (function :tag "Browse url" 'comint-hyperlink-browse-url)
                 (function :tag "Find file" 'comint-hyperlink-find-file)
                 (function :tag "Browse url (don’t ask)" 'comint-hyperlink-browse-url-no-ask)
                 (function :tag "Custom function")))

(defcustom comint-hyperlink-for-comint-mode t
  "Determines what to do with comint output.
If nil, do nothing.
If the symbol `filter', then just filter all hyperlink control sequences.
If anything else (such as t), then translate hyperlink control sequences
into button.

In order for this to have any effect, `comint-hyperlink-process-output' must
be in `comint-output-filter-functions'."
  :type '(choice (const :tag "Do nothing" nil)
                 (const :tag "Filter" filter)
                 (const :tag "Translate" t))
  :group 'comint-hyperlink)

(defun comint-hyperlink-find-file (url)
  "Find file when clicking on a file:// URL.

Falls back to ‘browse-url’."
  (cond
   ((string-match-p "^file://" url)
    (find-file
     (replace-regexp-in-string comint-hyperlink-file-regexp "" url)))
   (t (comint-hyperlink-browse-url url))))

(defun comint-hyperlink-browse-url (url)
  "Use ‘browse-url’ to open the URL.

Asks for confirmation with ‘yes-or-no-p’"
  (when (yes-or-no-p (format "Open %s in a web browser? " url))
    (comint-hyperlink-browse-url-no-ask url)))

(defun comint-hyperlink-browse-url-no-ask (url)
  "Use ‘browse-url’ to open the URL."
  ;; Need to strip hostname from file urls
  (if (string-match-p comint-hyperlink-url-protocols url)
      (browse-url
       (replace-regexp-in-string comint-hyperlink-file-regexp "file://" url))
    (error "Protocol for %s not supported by browse-url" url)))

(define-button-type 'comint-hyperlink
  'follow-link t
  'face nil
  'action (lambda (x) (funcall comint-hyperlink-action
                               (button-get x 'comint-hyperlink-url))))

(defvar-local comint-hyperlink-escape-start nil)

;;;###autoload
(defun comint-hyperlink-process-output (&optional _)
  "Convert SGR control sequences of comint into clickable text properties.

This is a good function to put in
`comint-output-filter-functions'."
  (interactive)
  (when comint-hyperlink-for-comint-mode
    (let ((start-marker (or comint-hyperlink-escape-start
                            (if (and (markerp comint-last-output-start)
                                     (eq (marker-buffer comint-last-output-start)
                                         (current-buffer))
                                     (marker-position comint-last-output-start))
                                comint-last-output-start
                              (point-min-marker))))
          (end-marker (process-mark (get-buffer-process (current-buffer)))))

      (save-excursion
        (goto-char start-marker)
        (while (re-search-forward comint-hyperlink-control-seq-regexp end-marker t)
          (let ((url (match-string 1)) (text (match-string 2)))
            (cond
             ((eq comint-hyperlink-for-comint-mode 'filter)
              (remove-text-properties (match-beginning 0) (match-end 0) '(read-only t))
              (delete-region (match-beginning 0) (match-end 0))
              (insert text))
             ((eq comint-hyperlink-for-comint-mode t)
              (remove-text-properties (match-beginning 0) (match-end 0) '(read-only t))
              (delete-region (match-beginning 0) (match-end 0))
              (insert-button text
                             'type 'comint-hyperlink
                             'comint-hyperlink-url (url-unhex-string url)
                             'help-echo (format "Visit %s"
                                                (url-unhex-string url)))))))

        ;; Save ending escape sequence that isn’t closed
	(if (re-search-forward "\e\\]8" end-marker t)
	    (setq comint-hyperlink-escape-start (match-beginning 0))
	  (setq comint-hyperlink-escape-start nil))))))

(provide 'comint-hyperlink)
;;; comint-hyperlink.el ends here
