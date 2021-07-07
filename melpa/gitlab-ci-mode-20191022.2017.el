;;; gitlab-ci-mode.el --- Mode for editing GitLab CI files  -*- lexical-binding: t; -*-
;;
;; Copyright 2018 Joe Wreschnig
;;
;; Author: Joe Wreschnig
;; Keywords: tools, vc
;; Package-Commit: c861dc5fa17d380d5c3aca99dc3bbec5eee623bc
;; Package-Requires: ((emacs "25.1") (yaml-mode "0.0.12"))
;; Package-Version: 20191022.2017
;; Package-X-Original-Version: 20191022.12.4
;; URL: https://gitlab.com/joewreschnig/gitlab-ci-mode/
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
;; ‘gitlab-ci-mode’ is a major mode for editing GitLab CI files.  It
;; provides syntax highlighting and completion for keywords and special
;; variables.  An interface to GitLab’s CI file linter is also provided
;; via ‘gitlab-ci-lint’.
;;
;; For more information about GitLab CI, see URL
;; ‘https://docs.gitlab.com/ce/ci/README.html’.  For details about the
;; file format, see URL
;; ‘https://docs.gitlab.com/ce/ci/yaml/README.html’.


;;; Code:

(require 'json)
(require 'subr-x)
(require 'url)
(require 'yaml-mode)

(defconst gitlab-ci-configuration-variables
  '("CI_DEBUG_TRACE"
    "ARTIFACT_DOWNLOAD_ATTEMPTS"
    "GET_SOURCES_ATTEMPTS"
    "GIT_CHECKOUT"
    "GIT_CLEAN_FLAGS"
    "GIT_CLONE_PATH"
    "GIT_DEPTH"
    "GIT_STRATEGY"
    "GIT_SUBMODULE_STRATEGY"
    "RESTORE_CACHE_ATTEMPTS")
  "Environment variables used to control GitLab CI’s behavior.

These can be used as environment variables, but more often are
set in a ‘variables’ block and act more like keywords.")

(defconst gitlab-ci-keywords
  (append
   '("action"
     "after_script"
     "allow_failure"
     "artifacts"
     "before_script"
     "branch"
     "cache"
     "changes"
     "coverage"
     "dependencies"
     "environment"
     "except"
     "exists"
     "expire_in"
     "extends"
     "file"
     "if"
     "image"
     "include"
     "interruptible"
     "key"
     "kubernetes"
     "local"
     "max"
     "name"
     "needs"
     "on_stop"
     "only"
     "pages"
     "parallel"
     "paths"
     "policy"
     "project"
     "ref"
     "refs"
     "remote"
     "reports"
     "retry"
     "rules"
     "script"
     "services"
     "stage"
     "stages"
     "start_in"
     "tags"
     "template"
     "timeout"
     "trigger"
     "untracked"
     "url"
     "variables"
     "when")
   gitlab-ci-configuration-variables)
  "YAML keys with special meaning used in GitLab CI files.")

(defconst gitlab-ci-special-values
  '(".post"
    ".pre"
    "always"
    "api"
    "api_failure"
    "branches"
    "clone"
    "delayed"
    "external"
    "fetch"
    "manual"
    "merge_requests"
    "missing_dependency_failure"
    "none"
    "normal"
    "on_failure"
    "on_success"
    "pipelines"
    "pushes"
    "recursive"
    "runner_system_failure"
    "runner_unsupported"
    "schedules"
    "script_failure"
    "stuck_or_timeout_failure"
    "tags"
    "triggers"
    "unknown_failure"
    "web")
  "YAML values with special meaning used in GitLab CI files.")

(defconst gitlab-ci-variables
  (append
   '("CI"
     "CI_BUILDS_DIR"
     "CI_COMMIT_BEFORE_SHA"
     "CI_COMMIT_DESCRIPTION"
     "CI_CONCURRENT_ID"
     "CI_CONCURRENT_PROJECT_ID"
     "CI_COMMIT_MESSAGE"
     "CI_COMMIT_REF_NAME"
     "CI_COMMIT_REF_SLUG"
     "CI_COMMIT_SHA"
     "CI_COMMIT_SHORT_SHA"
     "CI_COMMIT_TAG"
     "CI_COMMIT_TITLE"
     "CI_CONFIG_PATH"
     "CI_DEPLOY_PASSWORD"
     "CI_DEPLOY_USER"
     "CI_DISPOSABLE_ENVIRONMENT"
     "CI_ENVIRONMENT_NAME"
     "CI_ENVIRONMENT_SLUG"
     "CI_ENVIRONMENT_URL"
     "CI_JOB_ID"
     "CI_JOB_MANUAL"
     "CI_JOB_NAME"
     "CI_JOB_STAGE"
     "CI_API_V4_URL"
     "CI_JOB_TOKEN"
     "CI_JOB_URL"
     "CI_MERGE_REQUEST_ASSIGNEES"
     "CI_MERGE_REQUEST_ID"
     "CI_MERGE_REQUEST_IID"
     "CI_MERGE_REQUEST_LABELS"
     "CI_MERGE_REQUEST_MILESTONE"
     "CI_MERGE_REQUEST_PROJECT_ID"
     "CI_MERGE_REQUEST_PROJECT_PATH"
     "CI_MERGE_REQUEST_PROJECT_URL"
     "CI_MERGE_REQUEST_REF_PATH"
     "CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
     "CI_MERGE_REQUEST_SOURCE_BRANCH_SHA"
     "CI_MERGE_REQUEST_SOURCE_PROJECT_ID"
     "CI_MERGE_REQUEST_SOURCE_PROJECT_PATH"
     "CI_MERGE_REQUEST_SOURCE_PROJECT_URL"
     "CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
     "CI_MERGE_REQUEST_TARGET_BRANCH_SHA"
     "CI_MERGE_REQUEST_TITLE"
     "CI_NODE_INDEX"
     "CI_NODE_TOTAL"
     "CI_PAGES_DOMAIN"
     "CI_PAGES_URL"
     "CI_PIPELINE_ID"
     "CI_PIPELINE_IID"
     "CI_PIPELINE_SOURCE"
     "CI_PIPELINE_TRIGGERED"
     "CI_PIPELINE_URL"
     "CI_PROJECT_DIR"
     "CI_PROJECT_ID"
     "CI_PROJECT_NAME"
     "CI_PROJECT_NAMESPACE"
     "CI_PROJECT_PATH"
     "CI_PROJECT_PATH_SLUG"
     "CI_PROJECT_URL"
     "CI_PROJECT_VISIBILITY"
     "CI_REGISTRY"
     "CI_REGISTRY_IMAGE"
     "CI_REGISTRY_PASSWORD"
     "CI_REGISTRY_USER"
     "CI_REPOSITORY_URL"
     "CI_RUNNER_DESCRIPTION"
     "CI_RUNNER_EXECUTABLE_ARCH"
     "CI_RUNNER_ID"
     "CI_RUNNER_REVISION"
     "CI_RUNNER_TAGS"
     "CI_RUNNER_VERSION"
     "CI_SERVER"
     "CI_SERVER_NAME"
     "CI_SERVER_REVISION"
     "CI_SERVER_VERSION"
     "CI_SERVER_VERSION_MAJOR"
     "CI_SERVER_VERSION_MINOR"
     "CI_SERVER_VERSION_PATCH"
     "CI_SHARED_ENVIRONMENT"
     "GITLAB_CI"
     "GITLAB_USER_EMAIL"
     "GITLAB_USER_ID"
     "GITLAB_USER_LOGIN"
     "GITLAB_USER_NAME")
   gitlab-ci-configuration-variables)
  "Environment variables defined by GitLab CI.

See URL ‘https://docs.gitlab.com/ce/ci/variables/’ for more
information about these variables.")

;; TODO: Also handle the special K8S_SECRET_* variables from Auto DevOps
;; pipelines.

(defconst gitlab-ci-deprecated-variables
  '("CI_BUILD_BEFORE_SHA"
    "CI_BUILD_ID"
    "CI_BUILD_MANUAL"
    "CI_BUILD_NAME"
    "CI_BUILD_REF"
    "CI_BUILD_REF_NAME"
    "CI_BUILD_REF_SLUG"
    "CI_BUILD_REPO"
    "CI_BUILD_STAGE"
    "CI_BUILD_TAG"
    "CI_BUILD_TOKEN"
    "CI_BUILD_TRIGGERED")
  "Deprecated environment variables defined by GitLab CI.

See URL ‘https://docs.gitlab.com/ce/ci/variables/#9-0-renaming’
for more information about these variables.")

;; TODO: Parse file to extract stages for highlighting?

(defgroup gitlab-ci nil
  "Support for editing GitLab CI configuration files.

For more information about GitLab CI, see URL
‘https://docs.gitlab.com/ce/ci/README.html’."
  :tag "GitLab CI"
  :group 'convenience)

(defface gitlab-ci-builtin-variable
  '((t (:inherit font-lock-builtin-face)))
  "Face for built-in GitLab CI variables (e.g. “$CI_COMMIT_TAG”)."
  :tag "GitLab CI Built-in Variable"
  :group 'gitlab-ci)

(defface gitlab-ci-custom-variable
  '((t (:inherit font-lock-variable-name-face)))
  "Face for custom GitLab CI variables."
  :tag "GitLab CI Custom Variable"
  :group 'gitlab-ci)

(defface gitlab-ci-special-value
  '((t (:inherit font-lock-constant-face)))
  "Face for special GitLab CI values (e.g. “branches”)."
  :tag "GitLab CI Special value"
  :group 'gitlab-ci)

(defun gitlab-ci--post-completion (_string status)
  "Handle special syntax after keywords/variables.

If STATUS is ‘finished’ then a “}” may be added to the end of a
variable use (if it began with “${”), and a “:” may be added to
the end of a keyword used as a key."
  (when (eq status 'finished)
    (cond
     ((and (looking-back "\\${[A-Za-z0-9_]+" (line-beginning-position))
           (not (eql (char-after) ?})))
      (insert "}"))
     ((and (looking-back "^ *[a-z_]+" (line-beginning-position))
           (not (eql (char-after) ?:)))
      (insert ":")))))

(defun gitlab-ci--try-completion (prefix match candidates)
  "Attempt to offer completions at the point.

When looking backwards at PREFIX followed MATCH, return the
bounds of that MATCH (which may move past the point) and the
CANDIDATES list."
  (save-mark-and-excursion
   (when (looking-back (concat prefix match) (line-beginning-position))
     (goto-char (match-beginning 0))
     (re-search-forward match)
     (list (match-beginning 0) (match-end 0) candidates))))

(defun gitlab-ci--completion-candidates ()
  "Return candidates for completion at the point."
  (or (gitlab-ci--try-completion "^ *" "[a-z_]+" gitlab-ci-keywords)
      (gitlab-ci--try-completion "\\${?" "[A-Z_]+" gitlab-ci-variables)
      (gitlab-ci--try-completion "[-:] *" "[a-z_]+" gitlab-ci-special-values)))

(defun gitlab-ci-complete-at-point ()
  "‘completion-at-point-functions’ function for GitLab CI files."
  (let ((completion (gitlab-ci--completion-candidates)))
    (when completion
      (append completion
              '(:exclusive no
                :exit-function gitlab-ci--post-completion)))))

;;;###autoload
(define-derived-mode gitlab-ci-mode yaml-mode "GitLab CI"
  "Major mode for editing GitLab CI (‘.gitlab-ci.yml’) files.

GitLab CI uses a YAML-based file format to configure the jobs it
will run in order to build, test, and deploy software.  For more
information about the GitLab CI file format, see URL
‘https://docs.gitlab.com/ce/ci/yaml/README.html’.  For general
information about GitLab CI, see URL
‘https://docs.gitlab.com/ce/ci/README.html’ and URL
‘https://about.gitlab.com/features/gitlab-ci-cd/’.

This mode is capable of linting files but does not do so
automatically out of security concerns. Use ‘gitlab-ci-lint’ to
lint interactively on-demand, or ‘gitlab-ci-request-lint’ to
integrate the linting process with other software.

Although this derives from ‘yaml-mode’, it does not truly parse
YAML.  Only idiomatic GitLab CI syntax will be handled correctly.
In particular, it does not expect to encounter tags."
  :group 'gitlab-ci
  (font-lock-add-keywords
   nil
   `((,(format "^ *\\(%s\\) *:" (regexp-opt gitlab-ci-keywords))
      (1 'font-lock-keyword-face))
     (,(format "\\<\\${?\\(%s\\)\\>"
               (regexp-opt gitlab-ci-deprecated-variables))
      (1 'warning))
     (,(format "\\<\\${?\\(%s\\)\\>[^A-Za-z0-9_]"
               (regexp-opt gitlab-ci-variables))
      (1 'gitlab-ci-builtin-variable))
     ("\\<\\${?\\([A-Za-z0-9_]+\\)\\>"
      (1 'gitlab-ci-custom-variable))
     (,(format "[-:].+\\<\\(%s\\)\\>"
               (regexp-opt gitlab-ci-special-values))
      (1 'gitlab-ci-special-value))))

  (setq-local completion-at-point-functions
              '(gitlab-ci-complete-at-point)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gitlab-ci.yml\\'" . gitlab-ci-mode))


;; Linting support

(defcustom gitlab-ci-url "https://gitlab.com"
  "GitLab URL to use for linting GitLab CI API files."
  :risky t ;; The risk of a local URL is not that someone steals your
           ;; buffer contents (they already had it, since they gave you
           ;; the file with the URL), but that someone steals your
           ;; default API token, which is probably for a public site.
  :tag "GitLab CI URL"
  :type 'string)

(defcustom gitlab-ci-api-token nil
  "Private token to use for the GitLab API when linting CI files."
  :risky t ;; There is no reason to let a file set this, since a) no
           ;; file should know your URL (see above), and b) CI files
           ;; shouldn’t contain secrets anyway.
  :tag "GitLab CI API Token"
  :type 'string)

(defun gitlab-ci--lint-to-buffer (status data)
  "Show linting errors in a temporary buffer.

STATUS and DATA are passed from ‘gitlab-ci-request-lint’, which see."
  (if (eq status 'errored)
      (error data)
    (let ((errors (alist-get 'errors data)))
      (if errors
          (with-output-to-temp-buffer "*GitLab CI Lint*"
            (dolist (error errors)
              (princ error) (princ "\n")))
        (message "No errors found")))))

(defvar url-http-end-of-headers)        ; defined in ‘url/url-http.el’
(defun gitlab-ci--lint-results (status callback buffer)
  "Translate lint API result into data and pass it on.

STATUS is passed from ‘url-retrieve’, and CALLBACK and BUFFER are
passed from ‘gitlab-ci-request-lint’, which see."
  (when (buffer-live-p buffer) ; Don’t bother if the source is dead.
    (condition-case err
        (let ((err (plist-get status :error)))
          (when err
            (signal (car err) (cdr err)))
          (goto-char url-http-end-of-headers)
          (let* ((json-array-type 'list)
                 (data (buffer-substring-no-properties (point) (point-max)))
                 (result (json-read-from-string
                          (decode-coding-string data 'utf-8))))
            (with-current-buffer buffer
              (funcall callback 'finished result))))
      (error (funcall callback 'errored (error-message-string err))))))

(defun gitlab-ci-request-lint (callback &optional silent)
  "Run the current buffer against the GitLab CI linter.

This function uploads the contents of the current buffer to
‘gitlab-ci-url’, authorizing the request with
‘gitlab-ci-api-token’ (if set).

When the request is complete, CALLBACK receives two arguments.
If the first is ‘finished’, then the second is the decoded JSON
response from the API.  If it is ‘errored’, then the second is an
error message.  SILENT is as to ‘url-retrieve’."
  (let* ((url-request-method "POST")
         (url-request-data
          (let ((h (make-hash-table)))
            (puthash "content" (substring-no-properties (buffer-string)) h)
            (encode-coding-string (json-encode h) 'utf-8)))
         (url-request-extra-headers
          '(("Content-Type" . "application/json")))
         (url (concat gitlab-ci-url "/api/v4/ci/lint")))

    (when gitlab-ci-api-token
      (add-to-list 'url-request-extra-headers
                   `("Private-Token" . ,gitlab-ci-api-token)))

    ;; TODO: Handle HTTP 429 responses and delay internally. (However,
    ;; GitLab’s API limit is fairly high relative to human typing speed,
    ;; so the idle timers within e.g. Flycheck may be enough for now.)
    (url-retrieve url #'gitlab-ci--lint-results
                  (list callback (current-buffer))
                  silent)))

(defun gitlab-ci-lint ()
  "Lint the current buffer using the GitLab API.

Running this command will upload your buffer to the site
specified in ‘gitlab-ci-url’.  If your buffer contains sensitive
data, this is not recommended.  (Storing sensitive data in your
CI configuration file is also not recommended.)

If your GitLab API requires a private token, set
‘gitlab-ci-api-token’."
  (interactive)
  (gitlab-ci-request-lint #'gitlab-ci--lint-to-buffer))


(provide 'gitlab-ci-mode)
;;; gitlab-ci-mode.el ends here
