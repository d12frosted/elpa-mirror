;;; banner-comment.el --- For producing banner comments. -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2018 James Ferguson
;;
;; Author: James Ferguson <james@faff.org>
;; URL: https://github.com/WJCFerguson/banner-comment
;; Package-Version: 20190606.1809
;; Package-Commit: 35d3315683d3f97605207691b77e9f447af18fe2
;; Package-Requires: ((emacs "24.4"))
;; Version: 2.8.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:

;; Quick start:
;;
;; Bind the following commands:
;; banner-comment
;;
;; Code to format a line into a banner comment
;;
;;  ;; ================================ like so ================================
;;
;; or in a language with comment-end, like C:
;;
;;  /* =============================== like so ============================== */
;;
;;; Code:

(defgroup banner-comment nil
  "Turning comments into banners."
  :group 'convenience)

(defcustom banner-comment-char ?=
  "Character to be used for comment banners."
  :type 'character)

(defcustom banner-comment-char-match "[[:space:];#/*~=-]*"
  "Regexp to match old comment-banner prefix/suffix text to be destroyed."
  :type 'regexp)

(defcustom banner-comment-width nil
  "Default final column for banner comment if not specified by prefix arg.

If nil, use (or `comment-fill-column' `fill-column')."
  :type '(choice (const :tag "(or comment-fill-column fill-column)" nil)
                 integer))

(defcustom banner-comment-start nil
  "String to override `comment-start' for the banner, if non-nil."
  :type '(choice (const :tag "use `comment-start'" nil)
                 string))

(defcustom banner-comment-end nil
  "String to override `comment-end' for the banner, if non-nil."
  :type '(choice (const :tag "use `comment-end'" nil)
                 string))

(require 'subr-x) ;; for string-trim

;;;###autoload
(defun banner-comment (&optional end-column)
  "Turn line at point into a banner comment.

Called on an existing banner comment, will reformat it.

Final column will be (or END-COLUMN comment-fill-column fill-column)."
  (interactive "P")
  (save-excursion
    (save-restriction
      (beginning-of-line)
      (forward-to-indentation 0)
      (let ((banner-width (- (or end-column
                                 banner-comment-width
                                 comment-fill-column
                                 fill-column)
                             (current-column)))
            (comment-start (or banner-comment-start comment-start))
            (comment-end (or banner-comment-end comment-end)))
        (narrow-to-region (point) (line-end-position))
        ;; re search to extract existing into: pre(97), text(98), post(99)
        (if (re-search-forward
             (format
              "\\(?97:^\\(%s\\|\\)%s\\)\\(?98:.*?\\)\\(?99:%s\\(%s\\|%s\\|\\)\\)$"
              (or comment-start-skip (regexp-quote (string-trim comment-start)))
              banner-comment-char-match
              banner-comment-char-match
              (regexp-quote (string-trim comment-start))
              (or comment-end-skip (regexp-quote (string-trim comment-start)))))
            (let ((remaining-width (- banner-width
                                      (length comment-start)
                                      (if (string-empty-p (match-string 98))
                                          (length (match-string 98))
                                        (+ 2 (length (match-string 98))))
                                      (length comment-end))))
              (if (< remaining-width 0)
                  (error "Text too wide for banner comment"))
              (replace-match ;; replace everything before
               (concat
                comment-start
                (make-string (+ (/ remaining-width 2) (% remaining-width 2))
                             banner-comment-char)
                (if (not (string-empty-p (match-string 98))) " "))
               nil nil nil 97)
              (replace-match ;; replace everything after
               (concat
                (if (not (string-empty-p (match-string 98))) " ")
                (make-string (/ remaining-width 2) banner-comment-char)
                comment-end)
               nil nil nil 99)))))))


(provide 'banner-comment)
;;; banner-comment.el ends here
