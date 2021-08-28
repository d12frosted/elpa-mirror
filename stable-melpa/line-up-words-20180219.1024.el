;;; line-up-words.el --- Align words in an intelligent way

;; Copyright 2018 Jane Street Group, LLC <opensource@janestreet.com>
;; URL: https://github.com/janestreet/line-up-words
;; Package-Version: 20180219.1024
;; Package-Commit: 7f51793fa6c037a90a90e47b433cc8a773a3b552
;; Version: 1.0

;;; Commentary:

;; This package provides the ``line-up-words'' function that tries to
;; align words in the region in an intelligent way.  It is similar to
;; the ``align-regexp'' function but is a bit more clever in the way
;; it align words.
;;
;; Additionally, it was developed with the OCaml programming language
;; in mind and behaves well in OCaml source files.  More precisely it
;; ignores OCaml comments and tries to leave quoted strings
;; unmodified.
;;
;; The reformatting algorithm is implemented as a separate executable,
;; so you will need to install it before you can use
;; ``line-up-words''.

;; Installation:
;; You need to install the OCaml program ``line-up-words''.  The
;; easiest way to do so is to install the opam package manager:
;;
;;   https://opam.ocaml.org/doc/Install.html
;;
;; and then run "opam install line-up-words".

;;; Code:

(defgroup line-up-words nil
  "Try to align words in the region in an intelligent way."
  :tag "Aligning words with line-up-words."
  :version "1.0"
  :group 'align)

(defcustom line-up-words-command "line-up-words"
  "The command to execute for ‘line-up-words’."
  :type 'string
  :group 'line-up-words)

;;;###autoload
(defun line-up-words ()
  "Try to align words in the region in an intelligent way."
  (interactive)
  (shell-command-on-region
   (region-beginning) (region-end) line-up-words-command t t
   shell-command-default-error-buffer t)
  (indent-region (region-beginning) (region-end)))

(provide 'line-up-words)

;;; line-up-words.el ends here
