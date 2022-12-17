;;; tern-context-coloring.el --- Use Tern for context coloring  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Jackson Ray Hamilton

;; Author: Jackson Ray Hamilton <jackson@jacksonrayhamilton.com>
;; Version: 0.0.0
;; Package-Version: 20170102.2253
;; Package-Commit: 3a8e979d6cc83aabcb3dda3f5f31a6422532efba
;; Keywords: convenience faces tools
;; Package-Requires: ((emacs "24.3") (context-coloring "8.1.0") (tern "0.0.1"))
;; URL: https://github.com/jacksonrayhamilton/tern-context-coloring

;;; Commentary:

;; Use Tern as a backend for context coloring.

;; Add the following code to enable Tern support for context coloring:

;; (eval-after-load 'context-coloring
;;   '(tern-context-coloring-setup))

;;; Code:

(require 'context-coloring)
(require 'tern)

(defun tern-context-coloring-delay (fn)
  "Run FN in the next turn of the event loop."
  (run-with-idle-timer 0 nil fn))

(defun tern-context-coloring-apply-tokens (tokens)
  "Iterate through TOKENS representing start, end and level."
  (let ((index 0) (length (length tokens)))
    (while (< index length)
      (context-coloring-colorize-region
       (aref tokens index)
       (aref tokens (+ index 1))
       (aref tokens (+ index 2)))
      (setq index (+ index 3)))))

(defun tern-context-coloring-do-colorize (data)
  "Use DATA to colorize the buffer."
  (context-coloring-before-colorize)
  (with-silent-modifications
    (tern-context-coloring-apply-tokens data)
    (context-coloring-colorize-comments-and-strings))
  (context-coloring-after-colorize))

(defun tern-context-coloring-colorize ()
  "Query tern for contextual colors and colorize the buffer."
  (interactive)
  ;; Clear the stack to run `post-command-hook' so Tern won't erroneously
  ;; consider the query stale immediately after enabling a mode.
  (tern-context-coloring-delay
   (lambda ()
     (tern-run-query
      #'tern-context-coloring-do-colorize
      "context-coloring"
      (point)
      :full-file))))

(defun tern-context-coloring-predicate ()
  "Determine if Tern should be used for context coloring."
  tern-mode)

;;;###autoload
(defun tern-context-coloring-setup ()
  "Add Tern support to `context-coloring-mode'."
  (interactive)
  (puthash
   'tern
   (list :predicate #'tern-context-coloring-predicate
         :colorizer #'tern-context-coloring-colorize
         :setup #'context-coloring-setup-idle-change-detection
         :teardown #'context-coloring-teardown-idle-change-detection
         :async-p t)
   context-coloring-dispatch-hash-table))

(provide 'tern-context-coloring)

;;; tern-context-coloring.el ends here
