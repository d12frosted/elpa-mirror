;;; clojure-essential-ref-nov.el --- Cider-doc to "Clojure, The Essential Reference" (EPUB) -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Jordan Besly
;;
;; Version: 0.1.0
;; Package-Version: 20200719.608
;; Package-Commit: 13ac560c25f7355fba00d9ca8c9f4ca03e7fd189
;; URL: https://github.com/p3r7/clojure-essential-ref
;; Package-Requires: ((emacs "24")(dash "2.16.0")(nov "0.3.1")(clojure-essential-ref "0.1.0"))
;;
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Provides command `clojure-essential-ref-nov' to browse offline the
;; documentation for symbol in ebook version of book "Clojure, The
;; Essential Reference".
;;
;; Works similarly to `cider-clojuredocs-web'.
;;
;; This package is a child package of `clojure-essential-ref'.
;;
;; You can make command `clojure-essential-ref' browse to the EPUB version (instead of the online "liveBook") by putting this in your Emacs init:
;;
;; (setq clojure-essential-ref-default-browse-fn #'clojure-essential-ref-nov-browse)

;;; Code:



;; REQUIRES

(require 'dash)
(require 'nov)

(require 'clojure-essential-ref)



;; CONFIG

(defvar clojure-essential-ref-nov-epub-path "" "Path of local ebook.")



;; nov.el WRAPPERS

(defun clojure-essential-ref-nov--buffer ()
  "Get or create nov.el buffer for the book."
  (let* ((buff-name (file-name-nondirectory clojure-essential-ref-nov-epub-path))
         (matching-p (lambda (b)
                       (and (string= (buffer-name b) buff-name)
                            b)))
         (buff (-some matching-p (buffer-list))))
    (if buff
        buff
      (find-file-noselect clojure-essential-ref-nov-epub-path))))

(defun clojure-essential-ref-nov--get-index (section)
  "Get ebook url for SECTION from table of content."
  (with-current-buffer (clojure-essential-ref-nov--buffer)
    (nov-goto-toc)
    (goto-char (point-min))
    (search-forward section)
    (get-text-property (point) 'shr-url)))


(defun clojure-essential-ref-nov--browse-section (section)
  "Browse to SECTION of ebook."
  (let ((url (clojure-essential-ref-nov--get-index section))
        (buff (clojure-essential-ref-nov--buffer)))
    (switch-to-buffer-other-window buff)
    (apply 'nov-visit-relative-file (nov-url-filename-and-target url))))



;; COMMAND

(defun clojure-essential-ref-nov (&optional arg)
  "Open Clojure documentation for symbol in local ebook.

Offline ebook version of book \"Clojure, The Essential
Reference\" is used as a documentation source.

Prompts for the symbol to use, or uses the symbol at point, depending on
the value of `cider-prompt-for-symbol'.  With prefix arg ARG, does the
opposite of what that option dictates."
  (interactive "P")
  (let ((clojure-essential-ref-default-browse-fn #'clojure-essential-ref-nov-browse))
    (if (called-interactively-p 'any)
        (call-interactively #'clojure-essential-ref nil (vector arg))
      (funcall #'clojure-essential-ref arg))))



;; BROWSE

(defun clojure-essential-ref-nov-browse (symbol)
  "Open doc in Clojure Essential Ref for SYMBOL in local ebook."
  (unless clojure-essential-ref-nov-epub-path
    (error "Path of ebook (var `clojure-essential-ref-nov-epub-path') needs to be configured"))
  (unless (file-exists-p clojure-essential-ref-nov-epub-path)
    (error "Configured Path of ebook (\"%s\", var `clojure-essential-ref-nov-epub-path') does not exist" clojure-essential-ref-nov-epub-path))

  (let ((props (clojure-essential-ref--get-props symbol)))
    (unless props
      (error "Couldn't find reference to %s in book index" symbol))
    (clojure-essential-ref-nov--browse-section (plist-get props :section))))




(provide 'clojure-essential-ref-nov)

;;; clojure-essential-ref-nov.el ends here
