;;; gitlab-ci-mode-flycheck.el --- Flycheck support for ‘gitlab-ci-mode’ -*- lexical-binding: t; -*-
;;
;; Copyright 2018 Joe Wreschnig
;;
;; Author: Joe Wreschnig
;; Keywords: tools, vc, convenience
;; Package-Commit: eba81cfb7224fd1fa4e4da90d11729cc7ea12f72
;; Package-Requires: ((emacs "25") (flycheck "31") (gitlab-ci-mode "1"))
;; Package-Version: 20190323.1829
;; Package-X-Original-Version: 20180605.1
;; URL: https://gitlab.com/joewreschnig/gitlab-ci-mode-flycheck/
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; Flycheck integration for the linter included with ‘gitlab-ci-mode’.
;; For security reasons this checker is not enabled by default, as the
;; linter works by sending your GitLab CI configuration to a remote
;; server.  To enable it, call ‘gitlab-ci-mode-flycheck-enable’.


;;; Code:

(require 'flycheck)
(require 'gitlab-ci-mode)

(defun gitlab-ci-mode-flycheck--goto-path (path)
  "Go to the YAML key described by a “:”-separated PATH string.

If the full path could not be resolved, go to the last element
which could be found."
  (goto-char 0)
  (condition-case nil
      (let ((prefix "^"))
        (dolist (key (split-string path ":"))
          (re-search-forward
           (concat "\\(" prefix "\\)\\<\\(" key "\\)\\> *:"))
          (setq prefix (concat (match-string 1) " +"))
          (goto-char (match-end 2))))
    (search-failed nil)))

(defun gitlab-ci-mode-flycheck--line-for-message (message)
  "Try figure out the line number described by MESSAGE.

If the full key in the message could not be found, attribute the
error to the last element which could be found."
  (cond ((string-match
          "\\(?:jobs:\\)?\\([^ ]+\\) .* keys: \\([^ ]+\\)" message)
         (gitlab-ci-mode-flycheck--goto-path
          (concat (match-string 1 message) ":" (match-string 2 message))))
        ((string-match "\\(?:jobs:\\)?\\([^ ]+\\) config" message)
         (gitlab-ci-mode-flycheck--goto-path (match-string 1 message)))
        ((string-match "jobs:\\([^ ]+\\)" message)
         (gitlab-ci-mode-flycheck--goto-path (match-string 1 message)))
        (t (goto-char 0)))
  (line-number-at-pos))

(defun gitlab-ci-mode-flycheck--errors-filter (errors)
  "Fix up the line numbers of each error in ERRORS, if necessary."
  (dolist (err errors)
    (when (and (not (flycheck-error-line err)) (flycheck-error-message err))
      (flycheck-error-with-buffer err
        (save-restriction
          (save-mark-and-excursion
           (widen)
           (gitlab-ci-mode-flycheck--line-for-message
            (flycheck-error-message err))
           (setf (flycheck-error-line err) (line-number-at-pos)
                 (flycheck-error-column err) (current-column)))))))
  errors)

(flycheck-define-generic-checker 'gitlab-ci
  "Lint GitLab CI configuration files.

This checker will send your file to a remote service, as GitLab
offers no local linting tool. The service URL is configurable via
‘gitlab-ci-url’.

Because the GitLab CI linter does not give line numbers for most
errors, line-level attribution may be incorrect when using some
YAML features such as references, tags, or unusual indentation."
  :start
  (lambda (checker callback)
    (gitlab-ci-request-lint
     (lambda (status data)
       (if (eq status 'errored)
           (funcall callback status data)
         (funcall
          callback status
          (mapcar
           (lambda (message)
             (flycheck-error-new-at
              (when (string-match "\\<line \\([0-9]+\\)\\>" message)
                (string-to-number (match-string 1 message)))
              (when (string-match "\\<column \\([0-9]+\\)\\>" message)
                (string-to-number (match-string 1 message)))
              'error message :checker checker))
           (alist-get 'errors data)))))
     :silent))

  :error-filter #'gitlab-ci-mode-flycheck--errors-filter

  :modes '(gitlab-ci-mode))

;;;###autoload
(defun gitlab-ci-mode-flycheck-enable ()
  "Enable Flycheck support for ‘gitlab-ci-mode’.

Enabling this checker will upload your buffer to the site
specified in ‘gitlab-ci-url’.  If your buffer contains sensitive
data, this is not recommended.  (Storing sensitive data in your
CI configuration file is also not recommended.)

If your GitLab API requires a private token, set
‘gitlab-ci-api-token’."
  (add-to-list 'flycheck-checkers 'gitlab-ci))


(provide 'gitlab-ci-mode-flycheck)
;;; gitlab-ci-mode-flycheck.el ends here
