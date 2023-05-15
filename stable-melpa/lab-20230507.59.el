;;; lab.el --- An interface for GitLab -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Isa Mert Gurbuz

;; Author: Isa Mert Gurbuz <isamertgurbuz@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20230507.59
;; Package-Commit: 3e33e532aea48ffadde4e4e48efd26523d362a0d
;; Homepage: https://github.com/isamert/lab.el
;; License: GPL-3.0-or-later
;; Package-Requires: ((emacs "27.1") (memoize "1.1") (request "0.3.2") (s "1.10.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; lab.el is an Emacs package that provides a simple integration with
;; GitLab (managed or self-hosted).
;;
;; Provides you easier access to some GitLab functionality regarding to:
;; - Projects :: list, open, clone, list MRs...
;; - Merge Requests :: list, open, create, rebase, list pipelines...
;; - Pipelines :: list, open, retry, cancel, delete, watch status...
;; - Jobs :: list, open, retry, cancel, delete, show logs/traces...
;;
;; lab.el also provides you `lab--request' function which you can use
;; to do GitLab API calls easily.

;;; Code:

(require 's)
(require 'pp)
(require 'vc)
(require 'vc-git)
(require 'request)
(require 'memoize)
(require 'ansi-color)


;; Customization:

(defgroup lab nil
  "An interface for GitLab."
  :group 'tools
  :prefix "lab-")

(defcustom lab-token
  nil
  "GitLab API token."
  :type 'string
  :group 'lab)

(defcustom lab-host
  "https://gitlab.com"
  "GitLab host, like `https://gitlab.mycompany.com'."
  :type 'string
  :group 'lab)

(defcustom lab-group
  nil
  "The GitLab group you mostly work on.
Required only for functions containing `-group-' phrase."
  :type 'string
  :group 'lab)

(defcustom lab-after-merge-requests-create-functions
  '()
  "Functions to run after an MR is created."
  :type 'hook
  :group 'lab)

(defcustom lab-after-merge-request-mark-ready-functions
  '()
  "Functions to run after an MR is marked ready."
  :type 'hook
  :group 'lab)

(defcustom lab-browse-url-fn
  #'browse-url
  "Function to open external links."
  :type 'function
  :group 'lab)

(defcustom lab-projects-directory
  (expand-file-name "~")
  "Default place where local projects are stored."
  :type 'directory
  :group 'lab)

(defcustom lab-result-count
  20
  "Total result count for `lab-list-X' functions.
Can't be higher than `lab--max-per-page-result-count'."
  :type 'integer
  :group 'lab)

(defcustom lab-should-open-pipeline-on-manual-action?
  nil
  "Should pipeline web page automatically be opened if it requires a manual action?"
  :type 'boolean
  :group 'lab)

(defcustom lab-clone-method
  'ssh
  "Prefered for cloning repositories into your local."
  :type '(choice (const :tag "SSH" ssh)
                 (const :tag "HTTPS" https))
  :group 'lab)

(defcustom lab-action-handler
  'read-multiple-choice
  "Default action handler.
`lab' uses the given function for listing possible actions on a
selection."
  :type '(choice (const :tag "completing-read" completing-read)
                 (const :tag "read-multiple-choice" read-multiple-choice))
  :group 'lab)

(defcustom lab-main-branch-name
  "main"
  "Default main branch name used in your projects, like \"main\", \"master\" etc.
Mostly used for convenience-related stuff.."
  :type 'string
  :group 'lab)

(defcustom lab-default-merge-request-create-options
  (list
   ;; Premium feature:
   ;; :approvals_before_merge t
   ;; My broke-ass yaml parser does not support arrays right now, so:
   ;; :labels '()
   :squash "false"
   :allow_collaboration t
   :remove_source_branch t)
  "Default options used while creating a merge request."
  :group 'lab
  :type 'sexp)

(defcustom lab-pipeline-watcher-initial-delay
  30
  "Initial delay before starting to watch pipelines.
Pipelines do not start immediately after a push, it may take a
while for them to come online.  This delay is used in functions
`lab-watch-pipeline-for-*' so that you can use these functions as
hooks without worrying about lags.  Value is in seconds."
  :type 'number
  :group 'lab)


;;; Internal variables/constants:

(defvar lab--inspect-buffer-name "*lab inspect*"
  "Buffer name for showing pretty printed results.")

(defvar lab--action-selection-title "Action: "
  "The text displayed on action selection menus.")

(defvar lab--pipeline-watcher-debounce-time 30)

(defconst lab--max-per-page-result-count 100
  "This is the hard limit set by GitLab.")

(defconst lab--regex-yaml-metadata-border
  "\\(-\\{3\\}\\)$"
  "Regular expression for matching YAML metadata.")

(defconst lab--diff-buffer-name "*lab-diff*")


;;; Elisp helpers:

(defun lab-last-item (list)
  "Return the last item of LIST."
  (car (last list)))

;; Taken from transient.el
(defun lab--plist-to-alist (plist)
  (let (alist)
    (while plist
      (push (cons (let* ((symbol (pop plist))
                         (name (symbol-name symbol)))
                    (if (eq (aref name 0) ?:)
                        (intern (substring name 1))
                      symbol))
                  (pop plist))
            alist))
    (nreverse alist)))

(defun lab--inspect-obj (obj)
  "Inspect the given elisp OBJ."
  (get-buffer-create lab--inspect-buffer-name)
  (let ((print-length nil)
        (print-level nil))
    (pp-display-expression obj lab--inspect-buffer-name))
  (unless (get-buffer-window lab--inspect-buffer-name)
    (switch-to-buffer-other-window lab--inspect-buffer-name)))

(defun lab--plist-remove-keys-with-prefix (prefix lst)
  "Return a copy of LST without the key-value pairs whose keys start with PREFIX."
  (seq-each
   (lambda (it) (setq lst (map-delete lst it)))
   (seq-filter
    (lambda (it) (s-prefix? prefix (symbol-name it)))
    (map-keys lst)))
  lst)

(defun lab--length= (lst it)
  (= (length lst) it))


;;; Utilities:

;; The discussion made here[1] was quite helpful for implementing the following functionality.
;; [1]: https://github.com/oantolin/embark/issues/495

(cl-defun lab--completing-read-object (prompt objects &key (formatter #'identity) category predicate require-match initial-input hist def inherit-input-method (sort? t))
  "`completing-read' with formatter and sort control.
Applies FORMATTER to every object in OBJECTS and propertizes
candidates with the actual object so that they can be retrieved
later by embark actions.  Also adds category metadata to each
candidate, if given.  PROMPT passed to `completing-read' as is."
  (let* ((object-table
          (make-hash-table :test 'equal :size (length objects)))
         (object-strings
          (mapcar
           (lambda (object)
             (let ((formatted-object (funcall formatter object)))
               (puthash formatted-object object object-table)
               (propertize formatted-object 'lab--completing-read-object object)))
           objects))
         (selected
          (completing-read
           prompt
           (lambda (string predicate action)
             (if (eq action 'metadata)
                 `(metadata
                   ,(when category (cons 'category category))
                   ,@(unless sort?
                       '((display-sort-function . identity)
                         (cycle-sort-function . identity))))
               (complete-with-action
                action object-strings string predicate)))
           predicate require-match initial-input hist def inherit-input-method)))
    (gethash selected object-table selected)))

(cl-defun lab--user-input
    (&key
     (mode #'fundemental-mode)
     (init "")
     (buffer-name "*lab-input*")
     on-start
     on-accept
     on-reject
     parser)
  "Prompt the user for input in a new buffer with customizable options.
Keyword arguments:
- MODE - the major mode to use for the new buffer.
- INIT - initial text to display in the buffer.
- BUFFER-NAME - name of the new buffer to create.
- ON-START - no-arg function to run before the user input prompt is displayed.
- ON-ACCEPT - function to run when the user accepts the input.
- ON-REJECT - no-arg function to run when the user rejects the input
- PARSER - an function to parse user input before passing to on-accept function

The prompt provides instructions for the user to accept or reject
input.  When the user accepts the input, the on-accept function
is called with the input and parser result if given, and the
buffer is killed.  When the user rejects the input, the on-reject
function is called if given and the buffer is simply killed."
  (let* ((buffer (get-buffer-create buffer-name))
         (success-handler (lambda ()
                            (interactive)
                            (let ((parser-result (when parser
                                                   (with-current-buffer buffer
                                                     (funcall parser))))
                                  (result (substring-no-properties (buffer-string))))
                              (kill-buffer buffer)
                              (if parser
                                  (funcall on-accept result parser-result)
                                (funcall on-accept result)))))
         (reject-handler (lambda ()
                           (interactive)
                           (kill-buffer buffer)
                           (when on-reject
                             (funcall on-reject)))))
    (with-current-buffer buffer
      (funcall mode)
      (use-local-map (copy-keymap (current-local-map)))
      (local-set-key (kbd "C-c C-c") success-handler)
      (local-set-key (kbd "C-c C-k") reject-handler)
      (setq header-line-format "Hit `C-c C-c' to save `C-c C-k' to reject.")
      (insert init)
      (funcall on-start)
      (switch-to-buffer-other-window buffer))))

(defun lab--extract-object-from-target (type target)
  (cons type (or (get-text-property 0 'lab--completing-read-object target) target)))

(defvar embark-keymap-alist)
(defvar embark-transformer-alist)
(cl-defmacro lab--define-actions-for (category &key formatter keymap)
  (declare (indent 1))
  (let ((lab--generate-action-name
         (lambda (category name &optional public?)
           (intern (format "lab%s%s-%s" (if public? "-" "--") category (s-replace " " "-" (downcase name))))))
        (lab-keymap-full-name (intern (format "lab--embark-keymap-for-%s" category)))
        (lab-category-full-name (intern (format "lab-%s" category))))
    `(progn
       ;; Generate non-interactive action definitions for this
       ;; category (simple defuns). When user selects an action, one
       ;; of these functions are dispatched. These are non-interactive
       ;; because embark does not support passing objects to actions
       ;; if they are interactive.
       ,@(mapcar
          (lambda (keydef)
            (let ((action (seq-subseq keydef 2))
                  (name (nth 1 keydef)))
              (when (listp action)
                `(defun ,(funcall lab--generate-action-name category name) (it)
                   (let-alist it
                     ,@action)))))
          keymap)

       ;; Define embark keymap and add it to `embark-keymap-alist.'
       ;; This uses the functions generated above.
       (defvar ,lab-keymap-full-name
         (let ((map (make-sparse-keymap)))
           ,@(mapcar
              (lambda (keydef)
                `(define-key map ,(char-to-string (nth 0 keydef)) #',(funcall lab--generate-action-name category (nth 1 keydef))))
              keymap)
           map)
         ,(format "Actions for %s" lab-category-full-name))

       (with-eval-after-load 'embark
         (add-to-list 'embark-keymap-alist '(,lab-category-full-name . ,lab-keymap-full-name))

         ;; Also define a embark transformer for these actions. That's
         ;; because we want to pass full objects to the actions instead
         ;; of passing selected string. Objects are attached to the
         ;; text-properties by `lab--completing-read-object'
         ;; function. This extractor simply extracts it.
         (setf
          (alist-get ',lab-category-full-name embark-transformer-alist)
          #'lab--extract-object-from-target))

       ;; Generate the `...-act' function which let's user select one
       ;; of the inputs and act on them
       (cl-defun ,(funcall lab--generate-action-name category "act-on" t) (items &key (sort? t))
         (let* ((result (lab--completing-read-object
                         (format "%s: " (s-titleize (format "%s" ',category)))
                         items
                         :formatter ,formatter
                         :category ',lab-category-full-name
                         :sort? sort?))
                (action (pcase lab-action-handler
                          ('read-multiple-choice
                           (nth 1 (read-multiple-choice
                                   lab--action-selection-title
                                   ',(mapcar
                                      (lambda (keydef)
                                        (let ((name (downcase (nth 1 keydef))))
                                          (list (nth 0 keydef) name)))
                                      keymap))))
                          ('completing-read
                           (completing-read
                            lab--action-selection-title
                            ',(mapcar (lambda (keydef) (nth 1 keydef)) keymap)))))
                (action-fn (,lab--generate-action-name ',category action)))
           (funcall action-fn result))))))

(defvar project-current-inhibit-prompt)
(defvar project-current-directory-override)
(defmacro lab--within-current-project (&rest forms)
  "Let you run FORMS in current projects directory."
  `(let ((default-directory
          (or
           (when (boundp 'project-current-inhibit-prompt)
             project-current-inhibit-prompt)
           (when (boundp 'project-current-directory-override)
             project-current-directory-override)
           default-directory)))
     ,@forms))


;;; Git helpers:

;;;###autoload
(defun lab-git-current-branch ()
  "Return current branch's name."
  (s-trim (shell-command-to-string "git rev-parse --abbrev-ref HEAD")))

;;;###autoload
(defun lab-git-last-commit-sha ()
  "Return last commits SHA for current project."
  (s-trim (shell-command-to-string "git rev-parse HEAD")))

;;;###autoload
(defun lab-git-get-config (conf)
  "`git config --get CONF' wrapper."
  (thread-last
    (format "git config --get '%s'" conf)
    shell-command-to-string
    s-trim))

;;;###autoload
(defun lab-git-user-name ()
  "Return user name."
  (thread-last
    (lab-git-get-config "user.email")
    (s-split "@")
    car))

;;;###autoload
(defun lab-git-remote-homepage ()
  "Generate API base homepage from repository origin remote URL."
  (let ((remote-url (lab-git-get-config "remote.origin.url")))
    (cond
     ((s-contains? "@" remote-url)
      (thread-last
        remote-url
        (s-split "@")
        (nth 1)
        (s-replace-regexp ":[0-9]\*/\*" "/")
        (s-chop-suffix ".git")
        (s-prepend "https://")))
     (t (s-chop-suffix ".git" remote-url)))))


;;; Git helpers (interactive):

;;;###autoload
(defun lab-git-clone (url dir)
  "Clone URL to DIR."
  (interactive
   (list
    (read-string "URL: ")
    (read-directory-name "Directory to clone in: " "~/Workspace/")))
  (let* ((default-directory dir)
         (proc (start-process-shell-command "*lab-clone*" "*lab-clone*" (format "git clone '%s'" url))))
    (set-process-sentinel
     proc
     (lambda (p _e)
       (if (= 0 (process-exit-status p))
           (message "%s cloned." url)
         (message "Cloning %s is failed." url))))))

;;;###autoload
(defun lab-git-origin-switch-to-ssh ()
  "Switch remote origin address to SSH from HTTPS."
  (interactive)
  (if-let* ((https-origin (s-trim (shell-command-to-string "git config --get remote.origin.url")))
            (it (s-match "https://\\(.*\\)\\.\\(com\\|net\\|org\\)/\\(.*\\)" https-origin))
            (ssh-origin (format "git@%s.%s:%s" (nth 1 it) (nth 2 it) (nth 3 it))))
      (progn
        (shell-command-to-string (format "git remote set-url origin '%s'" ssh-origin))
        (message "Switched to SSH!"))
    (user-error "Already using SSH method or something is wrong with the current upstream address!")))


;;; Core:

(defun lab--project-path ()
  "Return hexified project path for current git project.
This is mostly used while doing an api call for the current
project."
  (thread-last
    (lab-git-remote-homepage)
    (s-chop-prefix lab-host)
    (s-chop-prefix "/")
    (s-chop-prefix "/")
    (s-chop-prefix "/")
    (s-trim)
    (url-hexify-string)))

(cl-defun lab--request
    (endpoint
     &rest params
     &key (%type "GET") (%headers '()) (%data nil) (%collect-all? nil) (%raw? nil)
     &allow-other-keys)
  "Do a GitLab request.

%TYPE, %HEADERS, %DATA, %COLLECT-ALL and %RAW are special
parameters, rest of the given PARAMS are added into ENDPOINT as
url parameters.

When %COLLECT-ALL is non-nil, do a paged request and collect all
results in a list and return them.

When %RAW is non-nil, return raw response from GitLab instead of
interpreting it as JSON and casting it into an alist.

If ENDPOINT requires a project path, you can use `#{project}'
special syntax to refer to the current project which is inherited
from the buffer this function is called from.

Examples:

  ;; Get *all* pipelines currently running on master.
  (lab--request
   \"projects/#{project}/pipelines\"
   :scope \"running\"
   :ref \"master\"
   :%collect-all t)"

  ;; Remove meta items from params list so that we can use `params' as
  ;; url parameters
  (setq params (lab--plist-remove-keys-with-prefix ":%" params))

  (let (json
        (all-items '())
        (lastid t)
        (json-object-type 'alist)
        (json-array-type #'list)
        (json-key-type 'symbol))
    (while lastid
      (request
        (thread-last (format "%s/api/v4/%s" lab-host endpoint)
                     (s-replace "#{group}" (url-hexify-string lab-group))
                     (s-replace "#{project}" (lab--project-path)))
        :type %type
        :headers `((Authorization . ,(format "Bearer %s" lab-token)) ,@%headers)
        :parser (if %raw? #'buffer-string #'json-read)
        :success (cl-function
                  (lambda (&key data &allow-other-keys)
                    (setq json data)
                    (when %collect-all?
                      (setq all-items `(,@all-items ,@json)))))
        :error (cl-function
                (lambda (&key data &allow-other-keys)
                  (error ">> lab--request failed with %s" data)))
        :sync t
        :data (lab--plist-to-alist %data)
        :params `(,@(when %collect-all?
                      `(("per_page" . ,lab--max-per-page-result-count)
                        ("order_by" . "id")
                        ("sort" . "asc")
                        ("pagination" . "keyset")))
                  ,@(when (and %collect-all? (not (eq lastid t)))
                      `(("id_after" . ,lastid)))
                  ,@(unless %collect-all?
                      `(("per_page" . ,lab-result-count)))
                  ,@(lab--plist-to-alist params)))
      (setq lastid
            (when (and %collect-all? (lab--length= json lab--max-per-page-result-count))
              (alist-get 'id (lab-last-item json)))))
    (if %collect-all? all-items json)))

(defun lab--open-web-url (url)
  (kill-new url)
  (funcall lab-browse-url-fn url))


;;; Projects:

(lab--define-actions-for project
  :formatter #'lab--format-project-title
  :keymap
  ((?o "Open"
       (lab--open-web-url .web_url))
   (?c "Clone"
       (lab-git-clone
        (alist-get (lab--clone-url-path-selector) it)
        (read-directory-name "Directory to clone in: " lab-projects-directory)))
   (?m "List merge requests"
       (lab-list-project-merge-requests .id))
   (?p "List pipelines"
       (lab-list-project-pipelines .id))
   (?i "Inspect"
       (lab--inspect-obj it))))

(defmemoize lab-get-all-group-projects (&optional group)
  "Get all groups belonging to given group."
  (lab--request
   (format "groups/%s/projects" (or group "#{group}"))
   :with_shared 'false
   :include_subgroups 'true
   :%collect-all? t))

;;;###autoload
(defun lab-list-all-group-projects (&optional group)
  "List all GROUP projects and act on them.
See `lab-group'.  BE CAREFUL, this function tries to fetch all
functions belonging to given group.  Result is memoized after
first call for `memoize-default-timeout'."
  (interactive)
  (lab-project-act-on (lab-get-all-group-projects group)))

(defmemoize lab-get-all-owned-projects ()
  "Get all projects owned by you."
  (lab--request
   "projects"
   :owned 'true
   :%collect-all? t))

;;;###autoload
(defun lab-list-all-owned-projects ()
  "Get all projects owned by you.
BE CAREFUL, this function tries to fetch all functions belonging
to given group.  Result is memoized after first call for
`memoize-default-timeout'."
  (interactive)
  (lab-project-act-on (lab-get-all-owned-projects)))

;;;###autoload
(defun lab-list-project-merge-requests (&optional project)
  "List all open MRs that belongs to PROJECT.
If it's omitted, currently open project is used."
  (interactive)
  (lab--within-current-project
   (lab-merge-request-act-on
    (lab--request
     (format "projects/%s/merge_requests" (or project "#{project}"))
     :scope 'all)
    :sort? nil)))

;;;###autoload
(defun lab-get-project-pipelines (&optional project)
  "Get pipelines for PROJECT.
If PROJECT is nil, current git project is used."
  (lab--request
   (format "projects/%s/pipelines" (or project "#{project}"))))

;;;###autoload
(defun lab-list-project-pipelines (&optional project)
  "List latest pipelines belonging to PROJECT.
If PROJECT is nil,current git project is used."
  (interactive)
  (lab--within-current-project
   (lab-pipeline-act-on
    (lab--sort-by-latest-updated
     (lab-get-project-pipelines project))
    :sort? nil)))


;;; Pipelines:

(lab--define-actions-for pipeline
  :formatter #'lab--format-pipeline
  :keymap
  ((?o "Open"
       (lab--open-web-url .web_url))
   (?r "Retry"
       (lab--request
        (format "projects/%s/pipelines/%s/retry" .project_id .id)
        :%type "POST"))
   (?c "Cancel"
       (lab--request
        (format "projects/%s/pipelines/%s/cancel" .project_id .id)
        :%type "POST"))
   (?d "Delete"
       (lab--request
        (format "projects/%s/pipelines/%s" .project_id .id)
        :%type "DELETE"))
   (?w "Watch"
       (lab-watch-pipeline .web_url))
   (?j "List jobs"
       (lab-list-pipeline-jobs .project_id .id))
   (?i "Inspect"
       (lab--inspect-obj it))
   (?I "Inspect detailed"
       (lab--inspect-obj
        (lab-get-pipeline .project_id .id)))))

;;;###autoload
(defun lab-get-pipeline (project-id pipeline-id)
  "Get detailed information for PIPELINE-ID in PROJECT-ID."
  (lab--request (format "projects/%s/pipelines/%s" project-id pipeline-id)))

;;;###autoload
(defun lab-get-pipeline-jobs (project-id pipeline-id)
  "Get latest jobs for PIPELINE-ID in PROJECT-ID."
  (lab--request
   (format "projects/%s/pipelines/%s/jobs" project-id pipeline-id)))

;;;###autoload
(defun lab-list-pipeline-jobs (project-id pipeline-id)
  "List latest jobs for PIPELINE-ID in PROJECT-ID."
  (lab-job-act-on
   (lab-get-pipeline-jobs project-id pipeline-id)
   :sort? nil))

;;;###autoload
(defun lab-watch-pipeline (url &optional rerun?)
  "Start watching pipeline URL status.
Send a notification if it's finished, failed or waiting for a
manual action.  RERUN? is used to indicate that this is a
recurring call, instead of a new watch request."
  (interactive "sPipeline URL: ")
  (let* ((data (s-match "https://.*\\.com/\\(.*\\)/-/pipelines/\\([0-9]+\\)" url))
         (project (nth 1 data))
         (project-hexified (url-hexify-string project))
         (pipeline (nth 2 data)))
    (when (or (not pipeline) (s-blank? pipeline))
      (user-error "Pipeline id is nil for %s" url))
    (unless rerun?
      (message ">> Started watching pipeline %s on %s!" pipeline project))
    (run-with-timer
     (if rerun? lab--pipeline-watcher-debounce-time 1)
     nil
     (lambda ()
       (let-alist (lab--request (format "projects/%s/pipelines/%s" project-hexified pipeline))
         (pcase .status
           ("success"
            (lab--alert (format "Pipeline FINISHED: %s/%s" project pipeline)))
           ("failed"
            (lab--alert (format "Pipeline FAILED: %s/%s" project pipeline)))
           ((or "canceled" "skipped" "scheduled")
            (lab--alert (format "Pipeline %s: %s/%s" (s-upcase .status) project pipeline)))
           ("manual"
            (lab--alert (format "Pipeline requires MANUAL action: %s/%s" project pipeline))
            (when lab-should-open-pipeline-on-manual-action?
              (browse-url .web_url)))
           (_
            (lab-watch-pipeline url t))))))))

;;;###autoload
(defun lab-watch-pipeline-for-last-commit ()
  "Start watching the pipeline created by your last commit."
  (interactive)
  (unless (s-prefix? lab-host (lab-git-remote-homepage))
    (user-error "Not a valid Gitlab repo"))
  (let ((project (lab--project-path))
        (sha (lab-git-last-commit-sha)))
    ;; Pipeline may take some time to appear
    (run-with-timer
     lab-pipeline-watcher-initial-delay nil
     (lambda ()
       (if-let* ((lab-result-count 3)
                 (pipeline (seq-find
                            (lambda (it) (equal sha (alist-get 'sha it)))
                            (lab-get-project-pipelines project))))
           (lab-watch-pipeline (alist-get 'web_url pipeline))
         (user-error "Seems like there are no pipelines created for your last commit"))))))

;;;###autoload
(defun lab-watch-merge-request-last-pipeline (mr)
  "Start watching the latest pipeline of given MR."
  ;; Pipeline may take some time to appear
  (run-with-timer
   lab-pipeline-watcher-initial-delay nil
   (lambda ()
     (let* ((lab-result-count 1)
            (pipeline (car (lab-get-merge-request-pipelines
                            (alist-get 'project_id mr)
                            (alist-get 'iid mr)))))
       (lab-watch-pipeline (alist-get 'web_url pipeline))))))


;;; lab-trace-mode:

;; TODO Add retry action for `lab-trace-mode-current-job' and start watching it
;; automatically

(defvar-local lab-trace-mode-current-job nil)

(defun lab-trace-mode-open-externally ()
  "Open current log in external browser."
  (interactive nil lab-trace-mode)
  (lab--open-web-url (alist-get 'web_url lab-trace-mode-current-job)))

(defvar-local lab-trace-mode-current-job nil
  "Currently inspected job object.")

(defvar lab-trace-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c &") #'lab-trace-mode-open-externally)
    map)
  "Keymap for `lab-trace-mode'.")

(define-derived-mode lab-trace-mode prog-mode "lab-trace-mode"
  "Major mode for showing trace of a job.")

(defun lab-show-job-logs (job)
  "Show logs for JOB in a seperate buffer."
  (let-alist job
    (with-current-buffer (get-buffer-create (format "*lab-trace:%s-%s*" .id .name))
      (lab-trace-mode)
      (setq-local lab-trace-mode-current-job job)
      (insert
       (ansi-color-apply
        (replace-regexp-in-string
         "\r" "\n"
         (lab--request
          (format "projects/%s/jobs/%s/trace"
                  (lab--projid-for-job job)
                  .id)
          :%raw? t))))
      (switch-to-buffer-other-window (current-buffer)))))


;;; Jobs:

(lab--define-actions-for job
  :formatter #'lab--format-job
  :keymap
  ((?o "Open"
       (lab--open-web-url .web_url))
   (?r "Retry"
       (lab--request
        (format "projects/%s/jobs/%s/retry" (lab--projid-for-job it) .id)
        :%type "POST"))
   (?c "Cancel"
       (lab--request
        (format "projects/%s/jobs/%s/cancel" (lab--projid-for-job it) .id)
        :%type "POST"))
   (?d "Delete"
       (lab--request
        (format "projects/%s/jobs/%s/erase" (lab--projid-for-job it) .id)
        :%type "POST"))
   (?t "Trace/logs"
       (lab-show-job-logs it))
   (?i "Inspect"
       (lab--inspect-obj it))
   (?I "Inspect detailed"
       (lab--inspect-obj
        (lab-get-job (lab--projid-for-job it) .id)))))

(defun lab-get-job (project-id job-id)
  "Get detailed information for JOB-ID in PROJECT-ID."
  (lab--request (format "projects/%s/jobs/%s" project-id job-id)))

(defun lab-act-on-last-failed-pipeline-job (&optional project-id)
  "List and act on last failed pipelines jobs for PROJECT.
If PROJECT-ID is omitted, currently open project is used."
  (interactive)
  (let* ((failed?
          (lambda (it)
            (equal (downcase (alist-get 'status it)) "failed")))
         (last-failed-pipeline (seq-find failed? (lab-get-project-pipelines (or project-id "#{project}")))))
    (if last-failed-pipeline
        (let-alist last-failed-pipeline
          (let ((jobs (seq-filter failed? (lab-get-pipeline-jobs .project_id .id))))
            (if (and jobs (> (length jobs) 0))
                (lab-job-act-on jobs :sort? nil)
              (user-error "A failed pipeline found but no failed job is found, see %s" .web_url))))
      (user-error "Not a single failed pipeline, congrats :)"))))


;;; Merge Requests:

(lab--define-actions-for merge-request
  :formatter #'lab--format-merge-request-title
  :keymap
  ((?o "Open"
       (lab--open-web-url .web_url))
   (?c "Copy url"
       (kill-new .web_url))
   (?m "Mark as ready"
       (let ((result
              (lab--request
               (format "projects/%s/merge_requests/%s" .project_id .iid)
               :%type "PUT"
               :%data (list :title (s-chop-prefixes '("WIP: " "Draft: ") .title)))))
         (seq-each
          (lambda (it) (funcall it result))
          lab-after-merge-request-mark-ready-functions)))
   (?r "Rebase"
       ;; TODO add a function that rebases merge request with given
       ;; URL and write this in terms of the new function
       (lab--request
        (format "projects/%s/merge_requests/%s/rebase" .project_id .iid)
        :%type "PUT"))
   (?p "Pipelines"
       (lab-pipeline-act-on
        (lab--sort-by-latest-updated
         (lab--request
          (format "projects/%s/merge_requests/%s/pipelines" .project_id .iid)
          :scope 'all
          :state 'opened))
        :sort? nil))
   (?w "Watch last pipeline"
       (lab-watch-merge-request-last-pipeline it))
   (?i "Inspect"
       (lab--inspect-obj it))))

(defun lab-get-merge-request-pipelines (project-id mr-id)
  "Get last pipelines for MR-ID in PROJECT-ID."
  (lab--request
   (format "projects/%s/merge_requests/%s/pipelines" project-id mr-id)))

(defun lab-list-branch-merge-requests ()
  "List all open MRs that the source branch is the current branch."
  (interactive)
  (lab-merge-request-act-on
   (lab--sort-by-latest-updated
    (lab--request
     "projects/#{project}/merge_requests"
     :scope 'all
     :state 'opened
     :source_branch (lab-git-current-branch)))
   :sort? nil))

(defun lab-list-my-merge-requests ()
  "List all of your currently open merge requests.
`Your' means either it's created by you or assigned to you."
  (interactive)
  (lab-merge-request-act-on
   (lab--sort-by-latest-updated
    `(,@(lab--request
         "merge_requests"
         :scope 'created_by_me
         :state 'opened)
      ,@(lab--request
         "merge_requests"
         :scope 'assigned_to_me
         :state 'opened)))
   :sort? nil))

(defun lab-list-group-merge-requests (&optional group)
  "List all open MRs that belongs to GROUP.
If GROUP is omitted, `lab-group' is used."
  (interactive)
  (lab-merge-request-act-on
   (lab--sort-by-latest-updated
    (lab--request
     (format "groups/%s/merge_requests" (or group "#{group}"))
     :scope 'all
     :state 'opened))
   :sort? nil))

(defun lab--remove-diff-buffer ()
  (when-let (buffer (get-buffer-window lab--diff-buffer-name))
    (quit-window t buffer)))

(declare-function markdown-mode "markdown-mode")
(defun lab-create-merge-request ()
  "Create an MR interactively for current git project."
  (interactive)
  (let* ((currbuf (current-buffer))
         (branches (vc-git-branches))
         (source-branch (completing-read
                         "Source branch: "
                         branches
                         nil nil (lab-git-current-branch)))
         (target-branch (completing-read
                         "Target branch: "
                         branches
                         nil nil (when (member lab-main-branch-name branches)
                                   lab-main-branch-name)))
         (title (read-string "MR Title: "
                             (s-trim (shell-command-to-string "git log -1 --pretty=%B")))))
    (lab--user-input
     :mode (if (require 'markdown-mode nil t) #'markdown-mode #'prog-mode)
     :init (thread-last
             (append
              lab-default-merge-request-create-options
              (list :source_branch source-branch
                    :target_branch target-branch
                    :title title))
             (map-apply
              (lambda (key val)
                (format "%s: %s" (substring (symbol-name key) 1) (lab--serialize-yaml-value val))))
             (nreverse)
             (s-join "\n")
             (s-prepend "---\n")
             (s-append "\n---\n\n"))
     :parser #'lab--parse-merge-request-buffer
     :on-start
     (lambda ()
       (vc-diff-internal t (vc-deduce-fileset t) target-branch source-branch t lab--diff-buffer-name))
     :on-reject #'lab--remove-diff-buffer
     :on-accept
     (lambda (_ data)
       (with-current-buffer currbuf
         (let ((result
                (lab--request
                 "projects/#{project}/merge_requests"
                 :%type "POST"
                 :%data data)))
           (lab--remove-diff-buffer)
           (seq-each
            (lambda (it) (funcall it result))
            lab-after-merge-requests-create-functions)
           (lab--open-web-url (alist-get 'web_url result))))))))

(defun lab--parse-merge-request-buffer ()
  (goto-char (point-min))
  (let* ((yaml (when (search-forward-regexp lab--regex-yaml-metadata-border nil t)
                 (buffer-substring-no-properties
                  (point)
                  (search-forward-regexp lab--regex-yaml-metadata-border nil t))))
         (yaml-data (when yaml
                      (thread-last
                        yaml
                        (s-split "\n")
                        (mapcar (lambda (it) (mapcar #'s-trim (s-split-up-to ": " it 1))))
                        (seq-filter (lambda (it) (and (lab--length= it 2)
                                                      (not (s-blank? (car it))))))
                        (mapcar (lambda (it) (list (intern (concat ":" (car it)))
                                                   (lab--deserialize-yaml-value (cadr it)))))
                        (apply #'seq-concatenate 'list)))))
    (map-insert yaml-data
                :description (s-trim (buffer-substring-no-properties (point) (point-max))))))


;;; Formatters & other helpers:

(defun lab--format-merge-request-title (mr)
  (format "[%-15s | %-6s => %-15s] %s"
          (propertize
           (thread-last
             (alist-get 'web_url mr)
             (s-chop-prefix lab-host)
             (s-split "/-/merge_requests/")
             (car)
             (s-split "/")
             (lab-last-item)
             (s-truncate 15))
           'face '(:weight thin))
          (propertize (alist-get 'state mr)
                      'face '(:weight thin :slant italic))
          (propertize (s-truncate 15 (alist-get 'name (alist-get 'author mr)))
                      'face 'italic)
          (propertize (alist-get 'title mr)
                      'face 'bold)))

(defun lab--format-project-title (project)
  (alist-get 'name_with_namespace project))

(defun lab--fontify-status (status)
  (propertize
   (upcase status) 'face
   `(:foreground ,(pcase (downcase status)
                    ("failed" "red")
                    ("success" "green")
                    ("manual" "orange")))))

(defun lab--format-pipeline (it)
  (let-alist it
    (format
     "%8s | %8s, %6s → %s (%s)%s"
     (lab--fontify-status .status)
     .id .source .ref
     (lab--time-ago (date-to-time .updated_at))
     (if .user (format " by %s" (alist-get 'username .user)) ""))))

(defun lab--format-job (it)
  (let-alist it
    (format
     "%8s | %8s, %15s on %s%s"
     (lab--fontify-status .status) .id (propertize .name 'face 'bold) .ref
     (if .user
         (format " by %s"  (propertize (alist-get 'username .user) 'face 'italic))
       ""))))

(defun lab--clone-url-path-selector ()
  (pcase lab-clone-method
    ('ssh 'ssh_url_to_repo)
    ('https 'https_url_to_repo)))

(defun lab--sort-by-latest-updated (lst)
  (seq-sort
   (lambda (o1 o2) (string> (alist-get 'updated_at o1) (alist-get 'updated_at o2)))
   lst))

(defun lab--serialize-yaml-value (val)
  (pcase val
    ((or 't "t" "true" "yes") "true")
    ((or "false" "no" :json-false 'nil) "false")
    (_ val)))

(defun lab--deserialize-yaml-value (val)
  (pcase val
    ((or 't "t" "true" "yes") t)
    ((or "false" "nil" "no" ":json-false") "false")
    (_ val)))

(defun lab--time-ago (past)
  (let* ((intervals '((31536000 . "year")
                      (2592000 . "month")
                      (86400 . "day")
                      (3600 . "hour")
                      (60 . "minute")
                      (1 . "second")
                      (0 . "now")))
         (secs (floor (-
                       (string-to-number (format-time-string "%s"))
                       (string-to-number (format-time-string "%s" past)))))
         (int (seq-find (lambda (it) (< (car it) secs)) intervals))
         (count (floor (/ secs (car int)))))
    (format
     "%s %s%s ago"
     count (cdr int) (if (> count 1) "s" ""))))

(defun lab--projid-for-job (job)
  (or (alist-get 'project_id job) (alist-get 'project_id (alist-get 'pipeline job))))

(declare-function alert "alert")
(defun lab--alert (msg)
  (message ">> lab.el :: %s" msg)
  (when (require 'alert nil t)
    (alert msg :title "lab.el")))

(provide 'lab)

;;; lab.el ends here
