;;; company-pollen.el --- company-mode completion backend for pollen

;; Copyright (C) 2016 Junsong Li
;; Author: Junsong Li <ljs.darkfish AT GMAIL>
;; Maintainer: Junsong Li
;; Created: 22 June 2016
;; Keywords: languages, pollen, pollenpub, company
;; Package-Version: 20160812.1510
;; Package-Commit: 09a9dc48c468dcd385982b9629f325e70d569faf
;; License: LGPL
;; Version: 0.2
;; Package-Requires: ((company "0.9.0") (pollen-mode "1.0"))
;; Distribution: This file is not part of Emacs
;; URL: https://github.com/lijunsong/pollen-mode

;;; Commentary:
;; company pollen provides pollen tag completion for pollen-mode.

;; TODO:
;; - Generate annotation.

;;; Code:

(require 'company)
(require 'cl-lib)

(defun pollen-fetch-id-code (sample-file)
  "Code to generate ids given pollen SAMPLE-FILE."
  (concat
   (format "(require \"%s\")" sample-file)
   (format "(define pollen-file \"%s\")" sample-file)
   "(define-values (l1 l2) (module->exports pollen-file))"
   "(define (get-module-path mod-idx)
  (define-values (path sub) (module-path-index-split mod-idx))
  path)"
   "(define (id-info id)
  (let ((name (first id))
        (idx (and (not (empty? (second id)))
                  (first (second id)))))
    (cons (symbol->string name)
          (if (module-path-index? idx)
              (get-module-path idx)
              pollen-file))))"
   "(printf \"~S\" (append (map id-info (rest (first l1)))
                           (map id-info (rest (first l2)))))"))

(defun pollen-fetch-id (pollen-file-path)
  "Helper function to async fetch ids from racket file POLLEN-FILE-PATH.

This function updates pollen-id-cache-initialized and
pollen-id-cache, and then delete `POLLEN-FILE-PATH`"
  ;; Because the code that fetches ID is running async, it is possible
  ;; this function is called multiple times during its long
  ;; running. As soon as it runs, we set pollen-id-cache-initialized
  ;; to true to prevent its second run.
  (unless pollen-id-cache-initialized
    (setq pollen-id-cache-initialized t)
    (let* ((process-buf-name "*pollenid*")
           (cmd-dir (file-name-directory pollen-file-path))
           (pollen-file-name (file-name-nondirectory pollen-file-path))
           (default-directory (file-name-as-directory cmd-dir)))
      ;; clean *pollenid* buffer if exists
      (when (get-buffer process-buf-name)
        (kill-buffer process-buf-name))
      ;; start process and sentinel
      (let ((process
             (start-process "pollenid" process-buf-name "racket" "-e"
                            (pollen-fetch-id-code pollen-file-name)))
            (process-sentinel
             `(lambda (proc event)
                (let ((content (save-current-buffer
                                 (set-buffer ,process-buf-name)
                                 (buffer-string))))
                  (cond ((string-match-p "finished" event)
                         (setq pollen-id-cache (read content))
                         (message "Company pollen initialized."))
                        (t     ;(string-match-p "\\(exited\\|dump\\)" event)
                         (setq pollen-id-cache nil)
                         (message "Errors in tag list init:\n%s" content)))
                  (when (eq (process-status proc) 'exit)
                    (when (get-buffer ,process-buf-name)
                      (kill-buffer ,process-buf-name))
                    (delete-file ,pollen-file-path))))))
        (set-process-sentinel process process-sentinel)))))

(defun pollen-initialize-id-cache ()
  "Asynchronously update pollen-id-cache."
  (when (and (eq major-mode 'pollen-mode)
             buffer-file-name
             (null pollen-id-cache-initialized))
    (message "Initializing company pollen backend ...")
    (let* ((current-path (file-name-directory (buffer-file-name)))
           (tmp-path (concat current-path "pollen-mode-get-ids.rkt")))
      (with-temp-file tmp-path
        (insert "#lang pollen"))
      (pollen-fetch-id tmp-path))))

(defvar-local pollen-id-cache nil
  "Cache for pollen identifiers.

ID is a list of pairs (identifier . FROM-MODULE)")

(defvar-local pollen-id-cache-initialized nil
  "Non-nil if `pollen-id-cache' has been initialized.")

(defun pollen-tag-completions ()
  "Return the cached ids."
  (when pollen-id-cache-initialized
    pollen-id-cache))

(defun pollen-find-tag-fuzzy-match (prefix candidate)
  "Fuzzy match PREFIX with CANDIDATE."
  ;; TODO: improve accuracy.
  (cl-subsetp (string-to-list prefix)
              (string-to-list candidate)))

(defun pollen-find-tag-info (prefix)
  "Given a PREFIX, return tag info."
  (cl-remove-if-not
   (lambda (info)
     (pollen-find-tag-fuzzy-match prefix (car info)))
   (pollen-tag-completions)))

(defun company-grab-pollen-tag ()
  "Return tag name if point is on a pollen tag, nil otherwise.

Note: this function uses one function from `pollen-mode'."
  (let ((tag (pollen-tag-at-point t)))
    (when tag
      (substring tag 1))))

(defun company-pollen-backend (command &optional arg &rest ignored)
  "The main function for backend.

If pollen identifiers not available, let other backends take over."
  (interactive (list 'interactive))
  (pollen-initialize-id-cache)
  (cl-case command
    (interactive (company-begin-backend 'company-pollen-backend))
    (prefix (and (eq major-mode 'pollen-mode)
                 (and pollen-id-cache-initialized pollen-id-cache)
                 (company-grab-pollen-tag)))
    (candidates
     (mapcar 'car (pollen-find-tag-info arg)))))

(add-to-list 'company-backends 'company-pollen-backend)

(provide 'company-pollen)

;;; company-pollen.el ends here
