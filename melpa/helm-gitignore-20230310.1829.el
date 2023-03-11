;;; helm-gitignore.el --- Generate .gitignore files with gitignore.io.
;;
;; Author: Juan Placencia
;; Version: 0.2.0
;; Package-Version: 20230310.1829
;; Package-Commit: 85c34065e6fceac8fa7287e6ec79ea3d1182d654
;; Keywords: helm gitignore gitignore.io
;; Homepage: https://github.com/jupl/helm-gitignore
;; Package-Requires: ((git-modes "1.4.0") (helm "1.7.0") (request "0.1.0") (cl-lib "0.5"))

;;; Commentary:
;;
;; This package provides a configured helm to generate .gitignore files using
;; https://www.gitignore.io/.
;;

;;; Code:

(require 'gitignore-mode)
(require 'helm)
(require 'json)
(require 'request)
(require 'cl-lib)

(defvar helm-gitignore--api-url
  "https://www.gitignore.io/api/%s"
  "Url used to generate .gitignore file.")

(defvar helm-gitignore--list-url
  "https://www.gitignore.io/dropdown/templates.json?term=%s"
  "Url used to get list of templates in raw and human-friendly text.")

(defvar helm-gitignore--cache nil
  "Cache that contains results of querying of candidates from gitignore.io.")

(defvar helm-gitignore--source
  (helm-build-sync-source "gitignore.io"
    :candidates 'helm-gitignore--candidates
    :action 'helm-gitignore--action
    :volatile t
    :requires-pattern 1))

(defun helm-gitignore--candidates ()
  "Query for gitignore templates."
  (let ((delay 0.1))
    (unless helm-gitignore--cache
      (run-at-time delay nil 'helm-gitignore--query-candidates helm-pattern))
    (and (sit-for delay)
         (prog1 helm-gitignore--cache
           (and helm-gitignore--cache
                (setq helm-gitignore--cache nil))))))

(defun helm-gitignore--query-candidates (pattern)
  "Query for gitignore templates using given PATTERN."
  (request
   (format helm-gitignore--list-url pattern)
   :parser 'json-read
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (setq helm-gitignore--cache
                     (mapcar 'helm-gitignore--format-result data))
               (and helm-alive-p (helm-update))))
   :error (cl-function
           (lambda (&key error-thrown &allow-other-keys&rest _)
             (message error-thrown)))))

(defun helm-gitignore--action (candidate)
  "Generate .gitignore given at least a CANDIDATE and present to screen."
  (let ((candidates (helm-marked-candidates)))
    (unless candidates (setq candidates (list candidate)))
    (request
     (helm-gitignore--generate-url candidates)
     :parser 'buffer-string
     :success (cl-function
               (lambda (&key data &allow-other-keys)
                 (when data
                   (with-current-buffer (get-buffer-create "*gitignore*")
                     (gitignore-mode)
                     (erase-buffer)
                     (insert data)
                     (goto-char (point-min))
                     (pop-to-buffer (current-buffer))))))
     :error (cl-function
             (lambda (&key error-thrown &allow-other-keys&rest _)
               (message error-thrown))))))

(defun helm-gitignore--format-result (result)
  "Pluck data from RESULT to create a Helm candidate."
  (cons (assoc-default 'text result) (assoc-default 'id result)))

(defun helm-gitignore--generate-url (list)
  "Create url from LIST to generate .gitignore using gitignore.io."
  (format helm-gitignore--api-url (mapconcat 'identity list ",")))

;;;###autoload
(defun helm-gitignore ()
  "Helm to generate .gitignore using gitignore.io."
  (interactive)
  (helm :sources 'helm-gitignore--source
        :buffer "*helm-gitignore*"))

(provide 'helm-gitignore)

;;; helm-gitignore.el ends here
