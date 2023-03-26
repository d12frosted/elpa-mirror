;;; kele.el --- Spritzy Kubernetes cluster management -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023 Jonathan Jin

;; Author: Jonathan Jin <me@jonathanj.in>

;; Version: 0.4.1
;; Package-Version: 20230326.33
;; Package-Commit: 15e841fb7bbc08545534e466ce831d6e80fd8901
;; Homepage: https://github.com/jinnovation/kele.el
;; Keywords: kubernetes tools
;; SPDX-License-Identifier: Apache-2.0
;; Package-Requires: ((emacs "28.1") (async "1.9.7") (dash "2.19.1") (f "0.20.0") (ht "2.3") (plz "0.4") (s "1.13.0") (yaml "0.5.1"))

;;; Commentary:

;; kele.el enables nimble, lightweight management of Kubernetes clusters.
;;
;; For more details, see: https://jonathanj.in/kele.el.

;;; Code:

(require 'async)
(require 'dash)
(require 'eieio)
(require 'f)
(require 'filenotify)
(require 'ht)
(require 'json)
(require 'plz)
(require 's)
(require 'subr-x)
(require 'transient)
(require 'url-parse)
(require 'yaml)

(declare-function yaml-mode "yaml-mode")

(defgroup kele nil
  "Integration constructs for Kubernetes."
  :group 'external
  :prefix "kele-"
  :link '(url-link "https://github.com/jinnovation/kele.el"))

(defcustom kele-kubeconfig-path
  (expand-file-name (or (getenv "KUBECONFIG") "~/.kube/config"))
  "Path to the kubeconfig file."
  :type 'directory
  :group 'kele)

(defcustom kele-cache-dir
  (f-expand "~/.kube/cache/")
  "Path to the kubectl cache."
  :group 'kele
  :type 'directory)

(defcustom kele-kubectl-executable "kubectl"
  "The kubectl executable to use."
  :type 'string
  :group 'kele)

(defcustom kele-proxy-ttl 180
  "The default time-to-live for ephemeral kubectl proxy processes."
  :type 'integer
  :group 'kele)

(defcustom kele-get-show-instructions t
  "Whether to show usage instructions inside the `kele-get' buffer."
  :group 'kele
  :type 'boolean)

(defcustom kele-resource-default-refresh-interval 60
  "The time-to-live for cached resources.

If a resource is not listed in `kele-resource-refresh-overrides',
its cached values are wiped afther this many seconds."
  :type 'integer
  :group 'kele)

(defcustom kele-resource-refresh-overrides '((namespace . 600))
  "Resource-specific cache time-to-live overrides.

If a resource is listed here, the corresponding value will be
used for cache time-to-live for that resource.  Otherwise,
`kele-resource-default-refresh-interval' is used.

Keys are the singular form of the resource name, e.g. \"pod\" for
pods."
  :type '(alist :key-type symbol :value-type 'integer)
  :group 'kele)

(defcustom kele-discovery-refresh-interval
  600
  "Default interval for polling clusters' discovery cache."
  :type 'integer
  :group 'kele)

;; TODO (#80): Display in the `kele-get-mode' header what fields were filtered out
(defcustom kele-filtered-fields '((metadata managedFields)
                                  (metadata annotations kubectl.kubernetes.io/last-applied-configuration))
  "Top-level resource fields to never display, e.g. in `kele-get'."
  :type '(repeat (repeat symbol)))

(define-error 'kele-cache-lookup-error
  "Kele failed to find the requested resource in the cache.")
(define-error 'kele-request-error "Kele failed in querying the Kubernetes API")
(define-error 'kele-ambiguous-groupversion-error
  "Found multiple group-versions associated with the given resource")

(defface kele-disabled-face
  '((t (:inherit 'font-lock-comment-face)))
  "Face used for disabled or not-applicable values."
  :group 'kele)

(defmacro kele--with-progress (msg &rest body)
  "Execute BODY with a progress reporter using MSG.

Returns the last evaluated value of BODY."
  (declare (indent defun))
  `(let ((prog (make-progress-reporter ,msg))
         (res (progn ,@body)))
     (progress-reporter-done prog)
     res))

(cl-defun kele--retry (fn &key (count 5) (wait 1) (timeout 100))
  "Retry FN COUNT times, waiting WAIT seconds between each.

Returns unconditionally after TIMEOUT seconds.

Returns the retval of FN."
  (let ((retval))
    (with-timeout (timeout)
      (let ((count-remaining count))
        (while (and (> count-remaining 0) (not (setq retval (funcall fn))))
          (setq count-remaining (- count-remaining 1))
          (sleep-for wait))))
    retval))

(defun kele--kill-process-quietly (proc &optional _signal)
  "Kill process PROC silently and the associated buffer, suppressing all errors."
  (when proc
    (set-process-sentinel proc nil)
    (set-process-query-on-exit-flag proc nil)
    (let ((kill-buffer-query-functions nil)
          (buf (process-buffer proc)))
      (ignore-errors (kill-process proc))
      (ignore-errors (delete-process proc))
      (ignore-errors (kill-buffer buf)))))

(defconst kele--random-port-range '(1000 9000))

(defun kele--random-port ()
  "Return a random integer within `kele--random-port-range'."
  (+ (car kele--random-port-range) (random (cadr kele--random-port-range))))

(cl-defun kele--proxy-process (context &key port (wait t) (read-only t))
  "Create a new kubectl proxy process for CONTEXT.

The proxy will be opened at PORT (localhost:PORT).  If PORT is
  nil, a random port will be chosen.  It is the caller's
  responsibility to ensure that the port is not occupied.

If READ-ONLY is set, the proxy will only accept read-only
requests.

If WAIT is non-nil, `kele--proxy-process' will wait for the proxy
  to be ready before returning.  This wait is a best effort; the
  proxy's /livez and /readyz endpoints are not guaranteed to
  return 200s by end of wait."
  (let* ((chosen-port (or port (kele--random-port)))
         (s-port (number-to-string chosen-port))
         (proc-name (format "kele: proxy (%s, %s)" context s-port))
         (cmd (list kele-kubectl-executable
                    "--context"
                    context
                    "proxy"
                    "--port"
                    s-port
                    "--reject-methods"
                    (if read-only "\'POST,PUT,PATCH\'" "^$")))
         (proc (make-process
                :name proc-name
                :command cmd
                :buffer (generate-new-buffer (format " *%s*" proc-name))
                :noquery t
                :sentinel
                (lambda (proc _status)
                  (when (zerop (process-exit-status proc))
                    (message "Successfully terminated process: %s" proc-name)
                    (kele--kill-process-quietly proc)))))
         (ready-addr (format "http://localhost:%s/readyz" s-port))
         (live-addr (format "http://localhost:%s/livez" s-port)))
    (when wait
      ;; Give the proxy process some time to spin up, so that curl doesn't
      ;; return error code 7 which to request.el is a "peculiar error"
      (sleep-for 2)
      (kele--retry (lambda ()
                     ;; /readyz and /livez can sometimes return nil, maybe when
                     ;; the proxy is just starting up. Add retries for these.
                     (when-let* ((resp-ready (plz 'get ready-addr :as 'response))
                                 (resp-live (plz 'get live-addr :as 'response))
                                 (status-ready (plz-response-status resp-ready))
                                 (status-live (plz-response-status resp-live)))
                       (and (= 200 status-ready) (= 200 status-live))))
                   :wait 2
                   :count 10))
    proc))

(cl-defun kele-kubectl-do (&rest args)
  "Execute kubectl with ARGS."
  (let ((cmd (append (list kele-kubectl-executable)
                     `("--kubeconfig" ,kele-kubeconfig-path)
                     args)))
    (make-process
     :name (format "kele: %s" (s-join " " cmd))
     :command cmd
     :noquery t)))

(cl-defgeneric kele--cache-update (&optional _)
  "Update in response to activity in the underlying filesystem.

Ideally this should be an asynchronous process.  This function
should be suitable for use as part of a file-watcher.")

(cl-defgeneric kele--cache-start (&key bootstrap)
  "Start watching the file system.

If BOOTSTRAP is non-nil, the implementation should also perform a
bootstrapping update, e.g. `kele--cache-update'.")

(cl-defgeneric kele--cache-stop ()
  "Stop watching the file system.")

(defclass kele--discovery-cache ()
  ((contents
    :documentation
    "Alist mapping contexts to the discovered APIs.

Key is the host name and the value is a list of all the
   APIGroupLists and APIResourceLists found in said cache.")
   (timer
    :documentation "The timer process for polling the filesystem."))
  "Track the Kubernetes discovery cache.

A class for loading a Kubernetes discovery cache and keeping it
in sync with the filesystem.")

(defclass kele--kubeconfig-cache ()
  ((contents
    :documentation "The loaded kubeconfig contents.")
   (filewatch-id
    :documentation "The ID of the file watcher.")
   (update-in-progress
    :documentation "Flag denoting whether an update is in progress."
    :initform nil))
  "Track the kubeconfig cache.

A class for loading kubeconfig contents and keeping them in sync
with the filesystem.")

(cl-defmethod kele--wait ((cache kele--kubeconfig-cache)
                          &key
                          (count 10)
                          (wait 1)
                          (timeout 100)
                          (msg "Waiting for kubeconfig update to finish..."))
  "Wait for CACHE to finish updating.

COUNT, WAIT, and TIMEOUT are as defined in `kele--retry'.

MSG is the progress reporting message to display."
  (when (oref cache update-in-progress)
    (kele--with-progress msg
      (kele--retry (lambda () (not (oref cache update-in-progress)))
                   :count count :wait wait :timeout timeout))))

(defun kele--get-host-for-context (&optional context)
  "Get host for CONTEXT."
  (let* ((server (let-alist (kele--context-cluster (or context (kele-current-context-name)))
                   .cluster.server))
         (host (url-host (url-generic-parse-url server)))
         (port (url-portspec (url-generic-parse-url server))))
    (s-concat host (if port (format ":%s" port) ""))))

(cl-defmethod kele--get-resource-lists-for-context ((cache kele--discovery-cache)
                                                    &optional context)
  "Get all resource lists for CONTEXT from CACHE."
  (alist-get
   (s-replace ":" "_" (kele--get-host-for-context (or context (kele-current-context-name))))
   (oref cache contents)
   nil nil #'equal))

(cl-defmethod kele--get-groupversions-for-type ((cache kele--discovery-cache)
                                                type
                                                &key context)
  "Look up the groupversions for a given resource TYPE in CACHE.

TYPE is expected to be the plural name of the resource.

If CONTEXT is nil, use the current context."
  (->> (kele--get-resource-lists-for-context cache (or context (kele-current-context-name)))
       (-filter (lambda (api-resource-list)
                  (->> (alist-get 'resources api-resource-list)
                       (-any (lambda (resource)
                               (equal (alist-get 'name resource) type))))))
       (-map (-partial #'alist-get 'groupVersion))
       (-sort (lambda (a _) (equal a "v1")))))

(cl-defmethod kele--resource-namespaced-p ((cache kele--discovery-cache)
                                           group-version
                                           type
                                           &key context)
  "Look up the namespaced-ness of GROUP-VERSION TYPE in CACHE.

If CONTEXT is not provided, the current context is used."
  (if-let ((namespaced-p
            (->> (kele--get-resource-lists-for-context cache (or context (kele-current-context-name)))
                 (-first (lambda (resource-list) (equal (alist-get 'groupVersion resource-list) group-version)))
                 (alist-get 'resources)
                 (-first (lambda (resource) (equal (alist-get 'name resource) type)))
                 (alist-get 'namespaced))))
      (not (eq :false namespaced-p))
    (signal 'kele-cache-lookup-error `(,context ,group-version ,type))))

(cl-defmethod kele--cache-update ((cache kele--discovery-cache) &optional _)
  "Update CACHE with the values from `kele-cache-dir'.

This is done asynchronously.  To wait on the results, pass the
retval into `async-wait'."
  (let* ((progress-reporter (make-progress-reporter "Pulling discovery cache..."))
         (func-complete (lambda (res)
                          (oset cache contents res)
                          (progress-reporter-done progress-reporter))))
    (async-start `(lambda ()
                    (add-to-list 'load-path (file-name-directory ,(locate-library "dash")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "f")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "s")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "yaml")))
                    (require 'f)
                    (require 'json)
                    (require 'yaml)
                    ,(async-inject-variables "kele-cache-dir")
                    (->> (f-entries (f-join kele-cache-dir "discovery"))
                         (-map (lambda (dir)
                                 (let* ((api-list-files (f-files dir
                                                                 (lambda (file)
                                                                   (equal (f-ext file) "json"))
                                                                 t))
                                        (api-lists (-map (lambda (file)
                                                           (json-parse-string (f-read file)
                                                                              :object-type 'alist
                                                                              :array-type 'list))
                                                         api-list-files))
                                        (key (f-relative dir (f-join kele-cache-dir "discovery"))))
                                   `(,key . ,api-lists))))))
                 func-complete)))

(cl-defmethod kele--resource-has-verb-p ((cache kele--discovery-cache)
                                         group-version kind verb &key context)
  (-contains-p (->> (kele--get-resource-lists-for-context
                     cache
                     (or context (kele-current-context-name)))
                    (-first (lambda (resource-list)
                              (equal (alist-get 'groupVersion resource-list)
                                     group-version)))
                    (alist-get 'resources)
                    (-first (lambda (resource)
                              (equal (alist-get 'name resource)
                                     kind)))
                    (alist-get 'verbs))
               (if (stringp verb) verb (symbol-name verb))))

(cl-defmethod kele--cache-start ((cache kele--discovery-cache) &key bootstrap)
  "Start file-watch for CACHE.

If BOOTSTRAP is non-nil, perform an initial read."
  (oset cache timer
        (run-with-timer
         (if bootstrap 0 kele-discovery-refresh-interval)
         kele-discovery-refresh-interval
         (-partial #'kele--cache-update cache))))

(cl-defmethod kele--cache-stop ((cache kele--discovery-cache))
  "Stop polling for CACHE."
  (cancel-timer (oref cache timer)))

(defvar kele--enabled nil
  "Flag indicating whether Kele has already been enabled or not.

This is separate from `kele-mode' to ensure that activating
`kele-mode' is idempotent.")
(defvar kele--global-kubeconfig-cache (kele--kubeconfig-cache))
(defvar kele--global-discovery-cache (kele--discovery-cache))

(cl-defmethod kele--cache-stop ((cache kele--kubeconfig-cache))
  "Stop watching `kele-kubeconfig-path' for contents to write to CACHE."
  (file-notify-rm-watch (oref cache filewatch-id)))

(cl-defmethod kele--cache-update ((cache kele--kubeconfig-cache) &optional _)
  "Update CACHE with the values from `kele-kubeconfig-path'.

This is done asynchronously.  To wait on the results, pass the
retval into `async-wait'."
  (let* ((progress-reporter (make-progress-reporter "Pulling kubeconfig contents..."))
         (func-complete (lambda (config)
                          (oset cache contents config)
                          (oset cache update-in-progress nil)
                          (progress-reporter-done progress-reporter))))
    (oset cache update-in-progress t)
    (async-start `(lambda ()
                    ;; TODO: How to just do all of these in one fell swoop?
                    (add-to-list 'load-path (file-name-directory ,(locate-library "yaml")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "f")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "s")))
                    (add-to-list 'load-path (file-name-directory ,(locate-library "dash")))
                    (require 'yaml)
                    (require 'f)
                    ,(async-inject-variables "kele-kubeconfig-path")
                    (yaml-parse-string (f-read kele-kubeconfig-path)
                                       :object-type 'alist
                                       :sequence-type 'list))
                 func-complete)))

(cl-defmethod kele--cache-start ((cache kele--kubeconfig-cache) &key bootstrap)
  "Start watching `kele-kubeconfig-path' for CACHE.

If BOOTSTRAP is non-nil, will perform an initial load of the
contents."
  (oset cache
        filewatch-id
        (file-notify-add-watch
         kele-kubeconfig-path
         '(change)
         (-partial #'kele--cache-update cache)))
  (when bootstrap
    (kele--cache-update cache)))

(cl-defstruct (kele--proxy-record
               (:constructor kele--proxy-record-create)
               (:copier nil))
  "Record of a proxy server process.

PROCESS is the process itself.

PORT is the port the process is running on.

TIMER, if non-nil, is the cleanup timer."
  process
  port
  timer)

(cl-defmethod kele--url ((proxy kele--proxy-record))
  (format "http://localhost:%s" (kele--proxy-record-port proxy)))

(cl-defmethod ready-p ((proxy kele--proxy-record))
  "Return non-nil if the PROXY is ready for requests.

Returns nil on any curl error."
  (let ((ready-addr (format "%s/readyz" (kele--url proxy)))
        (live-addr (format "%s/livez" (kele--url proxy))))
    (when-let* ((resp-ready (plz 'get ready-addr :as 'response :else 'ignore))
                (resp-live (plz 'get live-addr :as 'response :else 'ignore))
                (status-ready (plz-response-status resp-ready))
                (status-live (plz-response-status resp-live)))
      (and (= 200 status-ready) (= 200 status-live)))))

(defclass kele--proxy-manager ()
  ((records
    :documentation
    "Alist of context names to `kele--proxy-record' objects."
    :initarg :records
    :type list
    :initform nil))
  "Manage proxy server processes.")

(cl-defmethod proxy-start ((manager kele--proxy-manager)
                           context
                           &key port (ephemeral t))
  "Start a proxy process within MANAGER for CONTEXT at PORT.

If EPHEMERAL is non-nil, the proxy process will be cleaned up
after a certain amount of time.

If PORT is nil, a random port will be chosen.

Returns the proxy process.

If CONTEXT already has a proxy process active, this function returns the
existing process *regardless of the value of PORT*."
  (-if-let ((&alist context record) (oref manager records))
      record
    (kele--with-progress (format "Starting proxy server process for `%s'..."
                                 context)
      (let* ((selected-port (or port (kele--random-port)))
             (record (kele--proxy-record-create
                      :process (kele--proxy-process context :port selected-port :wait nil)
                      :timer (when ephemeral
                               (run-with-timer kele-proxy-ttl nil (-partial #'proxy-stop
                                                                            manager
                                                                            context)))
                      :port selected-port)))
        (oset manager records (cons `(,context . ,record) (oref manager records)))
        record))))

(cl-defmethod proxy-get ((manager kele--proxy-manager)
                         context
                         &key (wait t))
  "Retrieve the proxy process from MANAGER for CONTEXT.

If WAIT is non-nil, polls the liveliness and health endpoints for
  the proxy server until they respond successfully.

This function assumes that the proxy process has already been started.  It will
  not start a proxy server if one has not already been started."
  (-when-let ((&alist context record) (oref manager records))
    (when wait
      (kele--retry (-partial #'ready-p record) :wait 2 :count 10))
    record))

(cl-defmethod proxy-stop ((manager kele--proxy-manager)
                          context)
  "Stop the proxy process in MANAGER for CONTEXT.

If no process active for CONTEXT, this function is a no-op and
returns nil."
  (-when-let ((&alist context record) (oref manager records))
    (kele--kill-process-quietly (kele--proxy-record-process record))
    (when (kele--proxy-record-timer record)
      (cancel-timer (kele--proxy-record-timer record)))
    (oset manager records (assoc-delete-all context (oref manager records))))
  (message (format "[kele] Stopped proxy for context `%s'" context)))

(cl-defmethod proxy-active-p ((manager kele--proxy-manager)
                              context)
  "Return non-nil if a proxy serve is active for CONTEXT in MANAGER."
  (when-let (res (assoc context (oref manager records)))
    (cdr res)))

(defvar kele--global-proxy-manager (kele--proxy-manager))

(cl-defun kele--get-resource-types-for-context (context-name &key verb)
  "Retrieve the names of all resource types for CONTEXT-NAME.

If VERB provided, returned resource types will be restricted to
those that support the given verb."
  (->> (kele--get-resource-lists-for-context kele--global-discovery-cache
                                             (or context-name (kele-current-context-name)))
       (-filter (lambda (resource-list) (equal (alist-get 'kind resource-list) "APIResourceList")))
       (-map (lambda (list) (alist-get 'resources list)))
       (-flatten-n 1)
       (-filter (lambda (resource)
                  (if verb
                      (-contains-p (alist-get 'verbs resource)
                                   (if (stringp verb) verb (symbol-name verb)))
                    t)))
       (-map (lambda (resource) (alist-get 'name resource)))
       (-uniq)))

(cl-defun kele-current-context-name (&key (wait t))
  "Get the current context name.

The value is kept up-to-date with any changes to the underlying
configuration, e.g. via `kubectl config'.

If WAIT is non-nil, does not wait for any current update process
to complete.  Returned value may not be up to date."
  (when wait
    (kele--wait kele--global-kubeconfig-cache))
  (alist-get 'current-context (oref kele--global-kubeconfig-cache contents)))

(defun kele--default-namespace-for-context (context)
  "Get the defualt namespace for CONTEXT."
  (-if-let* (((&alist 'context (&alist 'namespace namespace))
              (-first (lambda (elem)
                        (string= (alist-get 'name elem) context))
                      (alist-get 'contexts (oref kele--global-kubeconfig-cache contents)))))
      namespace))

(cl-defun kele-current-namespace (&key (wait t))
  "Get the current context's default namespace.

The value is kept up-to-date with any changes to the underlying
configuration, e.g. via `kubectl config'.

If WAIT is non-nil, does not wait for any current update process
to complete.  Returned value may not be up to date."
  (kele--default-namespace-for-context (kele-current-context-name :wait wait)))

(defun kele-status-simple ()
  "Return a simple status string suitable for modeline display."
  (let* ((ctx (kele-current-context-name :wait nil))
         (ns (kele-current-namespace :wait nil))
         (status (if (not (or ctx ns))
                     "--"
                   (concat ctx (if ns (concat "(" ns ")") "")))))
    (concat "k8s:" status)))

(defconst kele--awesome-tray-module '("kele" . (kele-status-simple nil)))

(defun kele-context-names ()
  "Get the names of all known contexts."
  (-map
   (lambda (elem) (alist-get 'name elem))
   (alist-get 'contexts (oref kele--global-kubeconfig-cache contents))))

(defun kele--context-cluster (context-name)
  "Get the cluster metadata for the context named CONTEXT-NAME."
  (-first (lambda (elem) (string= (alist-get 'name elem)
                                  (kele--context-cluster-name context-name)))
          (alist-get 'clusters (oref kele--global-kubeconfig-cache contents))))

(defun kele--context-cluster-name (context-name)
  "Get the name of the cluster of the context named CONTEXT-NAME."
  (if-let ((context (-first (lambda (elem) (string= (alist-get 'name elem) context-name))
                            (alist-get 'contexts (oref kele--global-kubeconfig-cache contents)))))
      (alist-get 'cluster (alist-get 'context context))
    (error "Could not find context of name %s" context-name)))

(defun kele--context-annotate (context-name)
  "Return annotation text for the context named CONTEXT-NAME."
  (let* ((context (-first (lambda (elem)
                            (string= (alist-get 'name elem) context-name))
                          (alist-get 'contexts (oref kele--global-kubeconfig-cache contents))))
         (cluster-name (or (alist-get 'cluster (alist-get 'context context)) ""))
         (cluster (-first (lambda (elem)
                            (string= (alist-get 'name elem) cluster-name))
                          (-concat (alist-get 'clusters (oref kele--global-kubeconfig-cache contents)) '())))
         (server (or (alist-get 'server (alist-get 'cluster cluster)) ""))
         (proxy-status (if (proxy-active-p kele--global-proxy-manager context-name)
                           (propertize "Proxy ON" 'face 'warning)
                         (propertize "Proxy OFF" 'face 'shadow))))
    (format " %s%s, %s, %s%s"
            (propertize "(" 'face 'completions-annotations)
            (propertize cluster-name 'face 'completions-annotations)
            (propertize server 'face 'completions-annotations)
            proxy-status
            (propertize ")" 'face 'completions-annotations))))

(cl-defun kele--resources-complete (str pred action &key cands category)
  "Complete input for selection of resources.

STR, PRED, and ACTION are as defined in completion functions.

CANDS is the collection of completion candidates.

CATEGORY is the category the candidates should be categorized
as."
  (if (eq action 'metadata)
      `(metadata (category . ,(or category 'kele-resource)))
    (complete-with-action action cands str pred)))

(defun kele-namespace-switch-for-context (context namespace)
  "Switch to NAMESPACE for CONTEXT."
  (interactive (let ((context (completing-read "Context: " #'kele--contexts-complete)))
                 (list context
                       (completing-read (format "Namespace (%s): " context)
                                        (-cut kele--resources-complete <> <> <>
                                              :cands (kele--get-namespaces
                                                      context)
                                              :category 'kele-namespace)))))
  (kele-kubectl-do "config" "set-context" context "--namespace" namespace))

(transient-define-suffix kele-namespace-switch-for-current-context (namespace)
  "Switch to NAMESPACE for the current context."
  :key "n"
  :description
  (lambda ()
    (format "Change default namespace of %s to..."
            (propertize (oref transient--prefix scope)
                        'face 'warning)))
  (interactive
   (let ((ctx (if (and transient--prefix
                      (slot-boundp transient--prefix 'scope))
                 (oref transient--prefix scope)
               (kele-current-context-name))))
     (list
      (completing-read
       (format "Namespace (%s): " ctx)
       (-cut kele--resources-complete <> <> <>
             :cands (kele--get-namespaces ctx)
             :category 'kele-namespace)))))
  (kele-namespace-switch-for-context
   (if (and transient--prefix
            (slot-boundp transient--prefix 'scope))
       (oref transient--prefix scope)
     (kele-current-context-name))
   namespace))

;; TODO
(defun kele--namespace-annotate (_namespace-name)
  "Return annotation text for the namespace named NAMESPACE-NAME."
  "")

(defun kele--contexts-complete (str pred action)
  "Complete input for selection of contexts.

STR, PRED, and ACTION are as defined in completion functions."
  (if (eq action 'metadata)
      '(metadata (annotation-function . kele--context-annotate)
                 (category . kele-context))
    (complete-with-action action (kele-context-names) str pred)))

(defun kele--contexts-read (prompt initial-input history)
  "Reader function for contexts.

PROMPT, INITIAL-INPUT, and HISTORY are all as defined in Info
node `(elisp)Programmed Completion'."
  (completing-read prompt #'kele--contexts-complete nil t initial-input history))

(transient-define-suffix kele-context-switch (context)
  "Switch to a new CONTEXT."
  :key "s"
  :description
  (lambda ()
    (format "Switch from %s to..."
            (propertize (if (and transient--prefix
                                 (slot-boundp transient--prefix 'scope))
                            (oref transient--prefix scope)
                          (kele-current-context-name))
                        'face
                        'warning)))
  (interactive (list (completing-read "Context: " #'kele--contexts-complete)))
  (kele--with-progress (format "Switching to use context `%s'..." context)
    (kele-kubectl-do "config" "use-context" context)))

(transient-define-suffix kele-context-rename (old-name new-name)
  "Rename context named OLD-NAME to NEW-NAME."
  :key "r"
  :description "Rename a context"
  (interactive (list (completing-read "Context to rename: "
                                      #'kele--contexts-complete
                                      nil t nil nil (kele-current-context-name))
                     (read-from-minibuffer "Rename to: ")))
  ;; TODO: This needs to update `kele--global-proxy-manager' as well.
  (kele-kubectl-do "config" "rename-context" old-name new-name))

(transient-define-suffix kele-context-delete (context)
  :key "d"
  :description "Delete a context"
  (interactive (list (completing-read "Context: " #'kele--contexts-complete)))
  (kele--with-progress (format "Deleting context `%s'..." context)
    (kele-kubectl-do "config" "delete-context" context)))

(cl-defun kele-proxy-stop (context)
  "Clean up the proxy for CONTEXT."
  (interactive (list (completing-read "Stop proxy for context: " #'kele--contexts-complete)))
  (proxy-stop kele--global-proxy-manager context))

(cl-defun kele-proxy-start (context &key port (ephemeral t))
  "Start a proxy process for CONTEXT at PORT.

If EPHEMERAL is non-nil, the proxy process will be cleaned up
after a certain amount of time.

If PORT is nil, a random port will be chosen.

Returns an alist with keys `proc', `timer', and `port'.

If CONTEXT already has a proxy process active, this function returns the
existing process *regardless of the value of PORT*."
  (interactive (list (completing-read "Start proxy for context: " #'kele--contexts-complete)
                     :port nil
                     :ephemeral t))
  (proxy-start kele--global-proxy-manager context :port port :ephemeral ephemeral))

(defun kele-proxy-toggle (context)
  "Start or stop proxy server process for CONTEXT."
  (interactive (list (completing-read
                      "Start/stop proxy for context: "
                      #'kele--contexts-complete)))
  (funcall
   (if (proxy-active-p kele--global-proxy-manager context)
       #'kele-proxy-stop
     #'kele-proxy-start)
   context))

(defvar kele--context-resources nil
  "An alist mapping contexts to their cached resources.

Values are: (RESOURCE-NAME . (list RESOURCE)).")

(defvar kele--context-namespaces nil
  "An alist mapping contexts to their constituent namespaces.

If value is nil, the namespaces need to be fetched directly.")

(defun kele--clear-namespaces-for-context (context)
  "Clear the stored namespaces for CONTEXT."
  (setq kele--context-namespaces
        (assoc-delete-all (intern context) kele--context-namespaces)))

(defun kele--get-namespaces (context)
  "Get namespaces for CONTEXT.

If not cached, will fetch and cache the namespaces."
  (if-let ((namespaces (alist-get (intern context) kele--context-namespaces)))
      namespaces
    (apply #'kele--cache-namespaces context
           (kele--fetch-resource-names nil "v1" "namespaces" :context context))))

(defun kele--get-cache-ttl-for-resource (resource)
  "Get the cache TTL for RESOURCE."
  (or (alist-get resource kele-resource-refresh-overrides)
      kele-resource-default-refresh-interval))

(defun kele--cache-namespaces (context &rest namespace-names)
  "Cache NAMESPACE-NAMES as the associated namespaces for CONTEXT.

The cache has a TTL as defined by
`kele-resource-refresh-overrides' and
`kele-resource-default-refresh-interval'.

Returns the passed-in list of namespaces."
  (add-to-list 'kele--context-namespaces `(,(intern context) . ,namespace-names))
  (run-with-timer
   (kele--get-cache-ttl-for-resource 'namespace)
   nil
   #'kele--clear-namespaces-for-context
   context)
  namespace-names)

(cl-defstruct (kele--resource-container
               (:constructor kele--resource-container-create)
               (:copier nil))
  "Container associating a Kubernetes RESOURCE with its CONTEXT and NAMESPACE.

RESOURCE is expected to be an alist representing the Kubernetes
object.

RETRIEVAL-TIME denotes the time at which RESOURCE was retrieved.
"
  resource
  context
  namespace
  kind
  retrieval-time)

(cl-defun kele--get-resource (kind name &key group version context namespace)
  "Get resource KIND by NAME.

KIND should be the plural form of the kind's name, e.g. \"pods\"
instead of \"pod.\"

If GROUP and VERSION are nil, the function will look up the
possible group-versions for the resource KIND. If there is more
than one group-version associated with the resource KIND, the
function will signal an error.

If GROUP is nil, look up KIND in the core API group.

If CONTEXT is nil, use the current context.

If NAMESPACE is nil and the resource KIND is namespaced, use the
default namespace of the given CONTEXT.

If NAMESPACE is provided for a non-namespaced resource KIND,
throws an error."
  (let* ((context (or context (kele-current-context-name)))
         (time (current-time-string))
         (group-versions
          (cond
           ((and group version) (list (format "%s/%s" group version)))
           ((and version (not group)) (list version))
           (t (kele--get-groupversions-for-type kele--global-discovery-cache
                                                kind
                                                :context context)))))

    (when (> (length group-versions) 1)
      (signal 'kele-ambiguous-groupversion-error group-versions))
    (when (and namespace (not (kele--resource-namespaced-p
                               kele--global-discovery-cache
                               (car group-versions)
                               kind
                               :context context)))
      (user-error "Namespace `%s' specified for un-namespaced resource `%s'; remove namespace and try again" namespace kind))

    (-let* ((gv (car group-versions))
            (namespace (and (kele--resource-namespaced-p
                             kele--global-discovery-cache
                             gv
                             kind
                             :context context)
                            (or namespace (kele--default-namespace-for-context context))))
            (url-gv (if (s-contains-p "/" gv)
                        (format "apis/%s" gv)
                      (format "api/%s" gv)))
            (url-res (format "%s/%s" kind name))
            (url-all (concat url-gv "/"
                             (if namespace (format "namespaces/%s/" namespace) "")
                             url-res))
            (port (kele--proxy-record-port (proxy-start kele--global-proxy-manager context)))
            (url (format "http://localhost:%s/%s" port url-all)))
      (condition-case err
          (kele--resource-container-create
           :resource (kele--retry (lambda () (plz 'get url :as #'json-read)))
           :context context
           :kind kind
           :namespace namespace
           :retrieval-time time)
        (error (signal 'kele-request-error (error-message-string err)))))))

(cl-defstruct (kele--resource-buffer-context
               (:constructor kele--resource-buffer-context-create)
               (:copier nil)
               (:include kele--resource-container))
  "Contextual metadata for a `kele-get-mode' buffer."
  filtered-paths)

(defvar kele--current-resource-buffer-context)

(defun kele--quit-and-kill (&optional window)
  "Quit WINDOW and kill its buffer."
  (interactive)
  (quit-window t window))

(defvar kele--get-mode-command-descriptions
  '((quit-window . "quit window")
    (kele--quit-and-kill . "quit window, killing buffer")
    (kele-refetch . "re-fetch the resource")))

(define-minor-mode kele-get-mode
  "Enable some Kele features in resource-viewing buffers.

Kele resource buffers are created when you run `kele-get'.  They
show the requested Kubernetes object manifest.

\\{kele-get-mode-map}"
  :group 'kele
  :interactive nil
  :lighter "Kele Get"
  :keymap `((,(kbd "q") . quit-window)
            (,(kbd "Q") . kele--quit-and-kill)
            (,(kbd "g") . kele-refetch))
  (read-only-mode 1))

(cl-defstruct (kele--list-entry-id
               (:constructor kele--list-entry-id-create)
               (:copier nil))
  "ID value for entries in `kele-list-mode'."
  context
  namespace
  group-version
  kind
  name)

(defvar kele-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'kele-list-get)
    map))

(define-derived-mode kele-list-mode tabulated-list-mode "Kele: List"
  "Major mode for listing multiple resources of a single kind."
  :group 'kele
  :interactive nil
  (setq-local tabulated-list-format
              (vector (list "Name" 50 t)
                      (list "Namespace" 20 t)
                      (list "Group" 10 t)
                      (list "Version" 5 t)))
  (tabulated-list-init-header)
  (read-only-mode 1))

(defun kele-refetch ()
  "Refetches the currently displayed resource."
  (interactive nil kele-get-mode)

  (-let* ((ctx kele--current-resource-buffer-context)
          ((&alist 'kind kind
                   'apiVersion api-version
                   'metadata (&alist 'name name
                                     'namespace namespace))
           (kele--resource-buffer-context-resource ctx))
          (context (kele--resource-buffer-context-context ctx)))
    (kele--with-progress (format "Re-fetching resource `%s/%s' (namespace: %s, context: %s)..."
                                 kind
                                 name
                                 namespace
                                 context)
      (kele--render-object
       (kele--get-resource (kele--resource-buffer-context-kind ctx)
                           name
                           :group (car (kele--groupversion-split api-version))
                           :version (cadr (kele--groupversion-split api-version))
                           :namespace namespace
                           :context context)
       (current-buffer)))))

(defun kele--get-insert-header ()
  "Insert header into a `kele-get-mode' buffer."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (when (boundp 'kele--current-resource-buffer-context)
        (insert (propertize (format "# Context: %s\n"
                                    (kele--resource-buffer-context-context
                                     kele--current-resource-buffer-context))
                            'font-lock-face 'font-lock-comment-face))
        (insert (propertize (format "# Retrieval time: %s\n"
                                    (kele--resource-buffer-context-retrieval-time
                                     kele--current-resource-buffer-context))
                            'font-lock-face 'font-lock-comment-face)))
      (when kele-get-show-instructions
        (insert "#\n")
        (insert "# Keybindings:\n")
        (pcase-dolist (`(,cmd . ,desc) kele--get-mode-command-descriptions)
          (insert (format (propertize "# %s %s\n"
                                      'font-lock-face 'font-lock-comment-face)
                          (s-pad-right
                           10
                           " "
                           (substitute-command-keys (format "\\[%s]" cmd)))
                          desc)))))))

(add-hook 'kele-get-mode-hook #'kele--get-insert-header t)

(defun kele--groupversion-string (group version)
  "Concatenate GROUP and VERSION into single group-version string."
  (if group (concat group "/" version) version))

(defun kele--groupversion-split (group-version)
  "Split a single GROUP-VERSION string.

Returns a list where the car is the group and the cadr is the version.

Nil value for group denotes the core API."
  (let ((split (s-split "/" group-version)))
    (if (length= split 1) (list nil (car split)) split)))

(cl-defun kele--list-resources (group version kind &key namespace context)
  "Return the List of the resources of type specified by GROUP, VERSION, and KIND.

Return value is an alist mirroring the Kubernetes List type of
the type in question.

If NAMESPACE is provided, return only resources belonging to that
namespace.  If NAMESPACE is provided for non-namespaced KIND,
throws an error.

If CONTEXT is not provided, use the current context."
  (when (and namespace
             (not (kele--resource-namespaced-p
                   kele--global-discovery-cache
                   (kele--groupversion-string group version)
                   kind)))
    (signal 'user-error '()))

  (let* ((ctx (or context (kele-current-context-name)))
         (port (kele--proxy-record-port
                (proxy-start kele--global-proxy-manager ctx)))
         (url (format "http://localhost:%s/%s/%s"
                      port
                      (if group
                          (format "apis/%s/%s" group version)
                        (format "api/%s" version))
                      kind)))
    ;; Block on proxy readiness
    (proxy-get kele--global-proxy-manager ctx :wait t)
    (if-let* ((data (kele--retry (lambda () (plz 'get url :as #'json-read))))
              (filtered-items (->> (append  (alist-get 'items data) '())
                                   (-filter (lambda (item)
                                              (if (not namespace) t
                                                (let-alist item
                                                  (equal .metadata.namespace namespace))))))))
        (progn
          (setf (cdr (assoc 'items data)) filtered-items)
          data)
      (signal 'error (format "Failed to fetch %s/%s/%s" group version kind)))))

(cl-defun kele--fetch-resource-names (group version kind &key namespace context)
  "Fetch names of resources belonging to GROUP, VERSION, and KIND.

If NAMESPACE is provided, return only resources belonging to that namespace.  If
NAMESPACE is provided for non-namespaced KIND, throws an error.

If CONTEXT is not provided, use the current context."
  (let* ((resource-list (kele--list-resources
                        group version kind
                        :namespace namespace
                        :context context))
         (items (append (alist-get 'items resource-list) '())))
    (-map (lambda (item) (let-alist item .metadata.name)) items)))

(cl-defun kele--render-object (object &optional buffer)
  "Render OBJECT in a buffer as YAML.

Filters out fields according to `kele-filtered-fields'.

If BUFFER is provided, renders into it.  Otherwise, a new buffer
will be created.

OBJECT is either an alist representing a Kubernetes object, or a
`kele--resource-container'.  If the latter, buffer will have
context and namespace in its name."
  (cl-assert (and object (if (kele--resource-container-p object)
                             (kele--resource-container-resource object)
                           t)))
  (let* ((buf-name (concat " *kele: "
                           (if (kele--resource-container-p object)
                               (concat
                                (kele--resource-container-context object)
                                (and (kele--resource-container-namespace object)
                                     (format "(%s)"
                                             (kele--resource-container-namespace
                                              object)))
                                ": "))
                           (let-alist (if (kele--resource-container-p object)
                                          (kele--resource-container-resource object)
                                        object)
                             (format "%s/%s" .kind .metadata.name))
                           "*"))
         (buf (or buffer (get-buffer-create buf-name)))
         (obj (if (kele--resource-container-p object)
                  (kele--resource-container-resource object)
                object))
         (filtered-obj (-reduce-from (lambda (o keys)
                                       (apply #'kele--prune o keys))
                                     obj
                                     kele-filtered-fields)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (yaml-encode filtered-obj))
        (whitespace-cleanup)
        (goto-char (point-min)))

      (if (featurep 'yaml-mode) (yaml-mode)
        (message "[kele] For syntax highlighting, install `yaml-mode'."))

      (when (kele--resource-container-p object)
        (setq-local kele--current-resource-buffer-context
                    (kele--resource-buffer-context-create
                     :context (kele--resource-container-context object)
                     :kind (kele--resource-container-kind object)
                     :retrieval-time (kele--resource-container-retrieval-time object)
                     :resource (kele--resource-container-resource object)
                     :namespace (kele--resource-container-namespace object)))
        (put 'kele--current-resource-buffer-context 'permanent-local t))

      (kele-get-mode 1))
    (select-window (display-buffer buf))))

(defun kele--prune (alist &rest keys)
  "Delete the sub-tree of ALIST corresponding to KEYS."
  (let ((prev)
        (curr alist))
    (dolist (key keys)
      (setq prev curr)
      (setq curr (if-let ((list-p (listp curr))
                          (res (assq key curr)))
                     (cdr res)
                   nil)))
    (when curr
      (assq-delete-all (car (last keys)) prev))
    alist))

(defvar kele--context-keymap nil
  "Keymap for actions on Kubernetes contexts.

Only populated if Embark is installed.")

(defvar kele--namespace-keymap nil
  "Keymap for actions on Kubernetes namespaces.

Only populated if Embark is installed.")

(defconst kele--embark-keymap-entries '((kele-context . kele--context-keymap)
                                        (kele-namespace . kele--namespace-keymap)))

(transient-define-suffix kele-find-kubeconfig ()
  "Open the configured kubeconfig file in a buffer."
  :key "c"
  :description
  (lambda ()
    (format "Open %s" (propertize kele-kubeconfig-path 'face 'transient-value)))
  (interactive)
  (if (file-exists-p kele-kubeconfig-path)
      (find-file kele-kubeconfig-path)
    (message "[kele] %s does not exist; try initializing kubectl first." kele-kubeconfig-path)))

(defun kele--setup-embark-maybe ()
  "Optionally set up Embark integration."
  (when (featurep 'embark)
    (with-suppressed-warnings ((free-vars embark-keymap-alist embark-general-map))
      (setq kele--context-keymap (let ((map (make-sparse-keymap)))
                                   (define-key map "s" #'kele-context-switch)
                                   (define-key map "r" #'kele-context-rename)
                                   (define-key map "p" #'kele-proxy-toggle)
                                   (define-key map "n" #'kele-namespace-switch-for-context)
                                   (make-composed-keymap map embark-general-map)))
      (setq kele--namespace-keymap (let ((map (make-sparse-keymap)))
                                     (define-key map "s" #'kele-namespace-switch-for-current-context)
                                     (make-composed-keymap map embark-general-map)))
      (dolist (entry kele--embark-keymap-entries)
        (add-to-list 'embark-keymap-alist entry)))))

(defun kele--teardown-embark-maybe ()
  "Optionally tear down Embark integration."
  (when (featurep 'embark)
    (with-suppressed-warnings ((free-vars embark-keymap-alist))
      (dolist (entry kele--embark-keymap-entries)
        (delete entry embark-keymap-alist)))))

(defun kele--enable ()
  "Enables Kele functionality.

This is idempotent."
  (unless kele--enabled
    (setq kele--enabled t)
    ;; FIXME: Update the watcher when `kele-kubeconfig-path' changes.
    (kele--cache-start kele--global-kubeconfig-cache :bootstrap t)
    ;; FIXME: Update the watcher when `kele-cache-dir' changes.
    (kele--cache-start kele--global-discovery-cache :bootstrap t)

    (kele--setup-embark-maybe)
    (if (featurep 'awesome-tray)
        (with-suppressed-warnings ((free-vars awesome-tray-module-alist))
          (add-to-list 'awesome-tray-module-alist kele--awesome-tray-module)))))

(defun kele--disable ()
  "Disable Kele functionality.

This is idempotent."
  (unless (not kele--enabled)
    (setq kele--enabled nil)
    (kele--cache-stop kele--global-kubeconfig-cache)
    (kele--cache-stop kele--global-discovery-cache)
    (kele--teardown-embark-maybe)
    (if (featurep 'awesome-tray)
        (with-suppressed-warnings ((free-vars awesome-tray-module-alist))
          (delete kele--awesome-tray-module awesome-tray-module-alist)))))

(defvar kele-mode-map (make-sparse-keymap)
  "Keymap for Kele mode.")

(defvar kele-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") #'kele-config)
    (define-key map (kbd "r") #'kele-resource)
    (define-key map (kbd "p") #'kele-proxy)
    (define-key map (kbd "?") #'kele-dispatch)
    map)
  "Keymap for Kele commands.")

;;;###autoload
(define-minor-mode kele-mode
  "Minor mode to enable listening on Kubernetes configs."
  :global t
  :keymap kele-mode-map
  :group 'kele
  :lighter nil
  (if (not kele-mode)
      (kele--disable)
    (kele--enable)))

(defun kele--namespace-read-from-prefix (prompt initial-input history)
  "Read a namespace value using PROMPT, INITIAL-INPUT, and HISTORY.

Assumes that the current Transient prefix's :scope is an alist w/ `context' key."
  ;; FIXME: Make this resilient to the prefix's scope not having a context
  ;; value.  If not present (or the scope is not an alist or the scope is not
  ;; defined), default to current context.
  (if-let ((context (alist-get 'context (oref transient--prefix scope))))
      (completing-read
       prompt
       (-cut kele--resources-complete <> <> <>
             :cands (kele--get-namespaces context)
             :category 'kele-namespace)
       nil t initial-input history)
    (error "Unexpected nil context in `%s'" (oref transient--prefix command))))

(defclass kele--transient-scope-mutator (transient-option)
  ((fn
    :initarg :fn
    :initform (lambda (_scope _val) nil)
    :type function
    :documentation
    "The logic for updating the prefix's scope on each new value
assignment.

Defaults to a no-op."))
  "A Transient suffix that also modifies the associated prefix's
scope.")

(cl-defmethod transient-infix-set ((obj kele--transient-scope-mutator) new-value)
  "Set the infix NEW-VALUE while modifying the current prefix's scope.

On each invocation, calls OBJ's `fn' field with the prefix's
scope and NEW-VALUE."
  (cl-call-next-method obj new-value)
  (when (slot-boundp obj 'fn)
    (funcall (oref obj fn) (oref transient--prefix scope) new-value)))

(defclass kele--transient-infix-resetter (transient-option)
  ((resettees
    :initarg :resettees
    :initform nil
    :type list
    :documentation
    "List of arguments on the same prefix to reset when this one changes."))
  "A Transient infix that can also \"reset\" any of its peer infixes.")

(cl-defmethod transient-infix-set ((obj kele--transient-infix-resetter) val)
  "Set the infix VAL for OBJ.

Also resets any specified peer arguments on the same prefix that
  match any element of `:resettees' on OBJ."
  (cl-call-next-method obj val)
  (dolist (arg (oref obj resettees))
    (when-let ((obj (cl-find-if (lambda (obj)
                                  (and (slot-boundp obj 'argument)
                                       (equal (oref obj argument) arg)))
                                transient--suffixes)))
      (transient-init-value obj))))

(defclass kele--transient-infix (kele--transient-infix-resetter
                                 kele--transient-scope-mutator)
  ())

(defclass kele--transient-switches (transient-infix)
  ;; NB(@jinnovation): At some point we might need to expand this class to
  ;; include the "no value is a value" case, but that's not today. :D
  ((options
   :initarg :options
   :initform (lambda () nil)
   :type function
   :documentation
   "Function that returns the options for this infix to cycle through.

The car will be the default value.")))

(cl-defmethod transient-infix-read ((obj kele--transient-switches))
  "Read the new selected value for OBJ.

This does not prompt for user input.  Instead, it cycles through
  the CHOICES on invocation by the user."
  (let ((choices (oref obj choices))
        (value (oref obj value)))
    (or (cadr (member value choices))
        (car choices))))

(cl-defmethod transient-init-value ((obj kele--transient-switches))
  "Initialize the selected value for OBJ.

This is the car of the OPTIONS function's retval."
  (oset obj choices (funcall (oref obj options)))
  (oset obj value (car (oref obj choices))))

(cl-defmethod transient-format-value ((obj kele--transient-switches))
  "Formats the selection options for OBJ.

This draws heavy inspiration from `transient-switches', with the
following differences:

1. The ARGUMENT slot is not a part of the formatted value;

2. We do not allow non-selection as an option."
  (with-slots (value choices) obj
    (mapconcat
     (lambda (choice)
       (propertize choice 'face
                   (if (equal choice value)
                       'transient-value
                     'transient-inactive-value)))
     choices
     (propertize "|" 'face 'transient-inactive-value))))

;; FIXME: This is kind of contrived; could we find a way not to need to set
;; --argument here when we literally don't use it other than as a glorified
;; index?
(cl-defmethod transient-infix-value ((obj kele--transient-switches))
  "Return the value of OBJ.

This concatenates the `argument' slot with the `value' slot so
  that the value can be retrieved via `transient-arg-value'."
  (concat (oref obj argument) (oref obj value)))

(cl-defmethod transient-prompt ((_ kele--transient-switches))
  "Return a nil prompt.

`kele--transient-switches' does not prompt for user input."
  nil)

(transient-define-infix kele--namespace-infix ()
  "Select a namespace to work with.

Defaults to the default namespace for the currently active
context as set in `kele-kubeconfig-path'."
  :prompt "Namespace: "
  :description "namespace"
  :key "=n"
  :argument "--namespace="
  :class 'transient-option
  :reader 'kele--namespace-read-from-prefix
  :always-read t
  :if
  (lambda ()
    (-let (((&alist 'group-versions gvs 'kind kind)
            (oref transient--prefix scope)))
      (kele--resource-namespaced-p kele--global-discovery-cache (car gvs) kind)))
  :init-value (lambda (obj)
                (oset obj value
                      (kele--default-namespace-for-context
                       (alist-get 'context (oref transient--prefix scope))))))

(transient-define-infix kele--context-infix ()
  "Select a Kubernetes context to execute a given command in.

Defaults to the currently active context as set in
`kele-kubeconfig-path'."
  :class 'kele--transient-infix
  :fn (lambda (scope value)
        (proxy-start kele--global-proxy-manager value)
        (setf (cdr (assoc 'context scope)) value))
  :resettees '("--namespace=")
  :prompt "Context: "
  :description "context"
  :key "=c"
  :argument "--context="
  :always-read t
  :reader 'kele--contexts-read
  :init-value (lambda (obj)
                (oset obj value (kele-current-context-name))))

(transient-define-infix kele--groupversions-infix ()
  :class 'kele--transient-switches
  :key "v"
  :description "group-version"
  :argument "--groupversion="
  :options (lambda ()
             (alist-get 'group-versions (oref transient--prefix scope))))

(cl-defun kele--get-context-arg ()
  "Get the value to use for Kubernetes context.

First checks the current Transient command's arguments if set.
Otherwise, returns the current context name from kubeconfig."
  (if-let* ((cmd transient-current-command)
            (args (transient-args cmd))
            (value (transient-arg-value "--context=" args)))
      value
    (kele-current-context-name)))

(cl-defun kele--get-namespace-arg (&key use-default group-version kind (prompt "Namespace: "))
  "Get the value to use for Kubernetes namespace.

In order of priority, this function attempts the following:

- If we are currently in a Transient command; if so, pull the
  `--namespace=`' argument from it;

- If USE-DEFAULT is non-nil, use the default namespace for the context argument
  (from `kele--get-context-arg');

- If the resource type specified by GROUP-VERSION and KIND is not
  namespaced, return nil;

- Otherwise, ask the user to select a namespace using PROMPT."
  (let ((transient-arg-maybe (->> transient-current-command
                                  (transient-args)
                                  (transient-arg-value "--namespace="))))
    (cond
     (transient-arg-maybe transient-arg-maybe)
     ((or (not (and group-version kind)) use-default)
      (kele--default-namespace-for-context (kele--get-context-arg)))
     ((not (kele--resource-namespaced-p
            kele--global-discovery-cache
            group-version
            kind))
      nil)
     (t (completing-read prompt
                         (kele--get-namespaces (kele--get-context-arg)))))))

(cl-defun kele--get-groupversion-arg (&optional kind)
  "Get the group-version to use for a command.

First checks the current Transient command's arguments if set.
Otherwise, prompts user to select from the group-versions
available for the argument KIND.  If there is only one, no user
prompting and the function simply returns the single option."
  (if-let* ((cmd transient-current-command)
            (args (transient-args cmd))
            (value (transient-arg-value "--groupversion=" args)))
      value
    (let ((gvs (kele--get-groupversions-for-type
                kele--global-discovery-cache
                kind
                :context (kele--get-context-arg))))
      (if (= (length gvs) 1)
          (car gvs)
        (completing-read (format "Desired group-version of `%s': "
                                 kind)
                         gvs)))))

(transient-define-suffix kele-list (group-version kind context namespace)
  "List all resources of a given GROUP-VERSION and KIND.

If CONTEXT is provided, use it.  Otherwise, use the current context as reported
by `kele-current-context-name'.

If NAMESPACE is provided, use it.  Otherwise, use the default
namespace for the context.  If NAMESPACE is provided and the KIND
is not namespaced, returns an error."
  :key "l"
  :description
  (lambda ()
    (format "List all %s"
            (propertize
             (alist-get 'kind (oref transient--prefix scope))
             'face
             'warning)))
  (interactive
   (let* ((kind (kele--get-kind-arg))
          (group-version (kele--get-groupversion-arg kind)))
     (list group-version
           kind
           (kele--get-context-arg)
           (when (kele--resource-namespaced-p kele--global-discovery-cache
                                              group-version
                                              kind)
             (kele--get-namespace-arg)))))

  (-let* (((group version) (kele--groupversion-split group-version))
          (fn-entries (lambda ()
                        (let* ((resource-list (kele--list-resources
                                               group version kind
                                               :context context
                                               :namespace namespace))
                               (api-version (alist-get 'apiVersion resource-list)))
                          (->> resource-list
                               (alist-get 'items)
                               (-map (lambda (resource)
                                       (-let* (((&alist 'metadata (&alist 'name name 'namespace namespace)) resource)
                                               ((group version) (kele--groupversion-split api-version))
                                               (id (kele--list-entry-id-create
                                                    :context context
                                                    :namespace namespace
                                                    :group-version api-version
                                                    :kind kind
                                                    :name name)))
                                         (list
                                          id
                                          (vector
                                           `(,name action kele-list-get
                                                   kele-resource-id ,id)
                                           (or namespace
                                               (propertize "N/A" 'face 'kele-disabled-face))
                                           (or group
                                               (propertize "N/A" 'face 'kele-disabled-face))
                                           version))))))))))
    (let ((buf (get-buffer-create (format " *kele: %s/%s [%s(%s)]*"
                                          group-version
                                          kind
                                          context
                                          namespace))))
      (with-current-buffer buf
        (kele-list-mode)
        (setq-local tabulated-list-entries fn-entries)
        (tabulated-list-print))
      (select-window (display-buffer buf)))))

(cl-defun kele-list-get (&optional button)
  "Call `kele-get' on entry at point.

If BUTTON is provided, pull the resource information from the
  button properties.  Otherwise, get it from the list entry."
  (interactive nil kele-list-mode)
  (-let* ((id (if button (button-get button 'kele-resource-id) (tabulated-list-get-id))))
    (kele-get (kele--list-entry-id-context id)
              (kele--list-entry-id-namespace id)
              (kele--list-entry-id-group-version id)
              (kele--list-entry-id-kind id)
              (kele--list-entry-id-name id))))

(cl-defun kele--get-kind-arg ()
  "Get the kind to work with.

First checks if the kind is set in the current Transient prefix,
if it's set.  Otherwise, prompts user for input."
  (or (and transient-current-prefix
           (alist-get 'kind (oref transient-current-prefix scope)))
      (completing-read (format
                        "Choose a kind to work with (context: `%s'): "
                        (kele--get-context-arg))
                       (kele--get-resource-types-for-context
                        (kele--get-context-arg)))))

(transient-define-suffix kele-get (context namespace group-version kind name)
  "Get resource KIND by NAME and display it in a buffer.

GROUP-VERSION, NAMESPACE, KIND, and CONTEXT are all used to identify the
resource type to query for.

KIND should be the plural form of the kind's name, e.g. \"pods\"
instead of \"pod.\""
  :key "g"
  :description
  (lambda ()
    (--> (oref transient--prefix scope)
         (alist-get 'kind it)
         (propertize it 'face 'warning)
         (format "Get a single %s" it)))
  (interactive
   (-let* ((kind (kele--get-kind-arg))
           (gv (kele--get-groupversion-arg kind))
           ((group version) (kele--groupversion-split gv))
           (ns (kele--get-namespace-arg
                :group-version gv
                :kind kind
                :use-default nil))
           (cands (kele--fetch-resource-names group version kind
                                              :namespace ns
                                              :context (kele--get-context-arg)))
           (name (completing-read "Name: " (-cut kele--resources-complete <> <>
                                                 <> :cands cands))))
     (list (kele--get-context-arg) ns gv kind name)))
  (-let (((group version) (kele--groupversion-split group-version)))
    (kele--render-object (kele--get-resource kind name
                                             :group group
                                             :version version
                                             :namespace namespace
                                             :context context))))

(transient-define-prefix kele-resource (group-versions kind)
  "Work with Kubernetes resources."
  ["Arguments"
   (kele--context-infix)
   (kele--groupversions-infix)
   (kele--namespace-infix)]

  ["Actions"
   (kele-get)
   (kele-list)]

  (interactive (let* ((context (kele-current-context-name))
                      (kind (completing-read
                             (format "Choose a kind to work with (context: `%s'): " context)
                             (kele--get-resource-types-for-context
                              context)))
                      (gvs (kele--get-groupversions-for-type
                            kele--global-discovery-cache
                            kind
                            :context context)))
                 (list gvs kind)))
  (proxy-start kele--global-proxy-manager (kele-current-context-name))
  ;; TODO: Can we make proxy-start non-ephemeral and simply terminate the proxy
  ;; server when the transient exits?
  (transient-setup 'kele-resource nil nil :scope `((group-versions . ,group-versions)
                                                   (kind . ,kind)
                                                   (context . ,(kele-current-context-name)))))

(transient-define-prefix kele-dispatch ()
  "Work with Kubernetes clusters and configs."
  ["Work with..."
   ("c" "Configurations" kele-config)
   ("r" "Resources" kele-resource)
   ("p" "Proxy servers" kele-proxy)])

(transient-define-suffix kele--toggle-proxy-current-context (context)
  :key "p"
  :description
  (lambda ()
    (format "%s proxy server for %s"
            (if (proxy-active-p
                 kele--global-proxy-manager
                 (oref transient--prefix scope))
                "Disable"
              "Enable")
            (propertize (oref transient--prefix scope) 'face
                        'warning)))
  (interactive (list (oref transient-current-prefix scope)))
  (kele-proxy-toggle context))

(transient-define-prefix kele-config ()
  "Work with Kubernetes configurations.

The `scope' is the current context name."
  [[:description
    (lambda ()
      (format "Context: %s"
              (propertize (oref transient--prefix scope) 'face 'warning)))
    (kele-context-switch)
    (kele-namespace-switch-for-current-context)
    (kele--toggle-proxy-current-context)]
   ["Actions"
   (kele-context-rename)
   (kele-context-delete)]
   ["Files"
    (kele-find-kubeconfig)]]
  (interactive)
  (transient-setup 'kele-config nil nil :scope (kele-current-context-name)))

(transient-define-prefix kele-proxy ()
  "Work with kubectl proxy servers."
  ["Proxy servers"
   (kele--toggle-proxy-current-context)
   ("P" kele-proxy-toggle :description "Start/stop proxy server for...")]
  (interactive)
  (transient-setup 'kele-proxy nil nil :scope (kele-current-context-name)))

(provide 'kele)

;;; kele.el ends here
