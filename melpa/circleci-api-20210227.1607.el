;;; circleci-api.el --- Bindings for the CircleCI API -*- lexical-binding: t -*-

;; Author: Robin Schroer
;; Maintainer: Robin Schroer
;; Version: 0.1
;; Package-Version: 20210227.1607
;; Package-Commit: 2e39c5896819bb2063f9d7795c4299f419cf5542
;; Homepage: https://github.com/sulami/circleci-api
;; Package-Requires: ((emacs "27") (request "0.3.2"))


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; Bindings for the CircleCI API.

;;; Code:

(require 'cl-lib)
(require 'request)

;; Customisation:

(defgroup circleci-api nil
  "Bindings for the CircleCI API."
  :group 'comm
  :prefix "circleci-api-")

(defcustom circleci-api-token ""
  "The CircleCI API token."
  :type 'string
  :group 'circleci-api)

(defcustom circleci-api-host "https://circleci.com"
  "The CircleCI API host."
  :type 'string
  :group 'circleci-api)

;; Routes:

(defun circleci-api--route--api-root ()
  "Return the API root."
  (concat circleci-api-host "/api"))

(defun circleci-api--route--api-v2 ()
  "Return the APIv2 root."
  (concat (circleci-api--route--api-root) "/v2"))

(defun circleci-api--route--pipeline ()
  "Return the API route for pipelines."
  (concat (circleci-api--route--api-v2) "/pipeline"))

(defun circleci-api--route--workflow-by-id (workflow-id)
  "Return the API route for the workflows with WORKFLOW-ID."
  (concat (circleci-api--route--api-v2)
          "/workflow/"
          workflow-id))

(defun circleci-api--route--workflow-cancel (workflow-id)
  "Return the API route for cancelling the workflow with WORKFLOW-ID."
  (concat (circleci-api--route--workflow-by-id workflow-id)
          "/cancel"))

(defun circleci-api--route--workflow-rerun (workflow-id)
  "Return the API route for reruning the workflow with WORKFLOW-ID."
  (concat (circleci-api--route--workflow-by-id workflow-id)
          "/rerun"))

(defun circleci-api--route--workflow-jobs (workflow-id)
  "Return the API route for the jobs of the workflow with WORKFLOW-ID."
  (concat (circleci-api--route--workflow-by-id workflow-id)
          "/job"))

(defun circleci-api--route--job-approve (workflow-id job-id)
  "Return the API route for approving the job with JOB-ID.

Also needs WORKFLOW-ID from the parent workflow."
  (concat (circleci-api--route--workflow-by-id workflow-id)
          "/approve/"
          job-id))

(defun circleci-api--route--project (project-slug)
  "Return the API route for the project at PROJECT-SLUG."
  (concat (circleci-api--route--api-v2) "/project/" project-slug))

(defun circleci-api--route--project-pipelines (project-slug)
  "Return the API route for pipelines of the project at PROJECT-SLUG."
  (concat (circleci-api--route--project project-slug)
          "/pipeline"))

(defun circleci-api--route--my-project-pipelines (project-slug)
  "Return the API route for user's pipelines of the project at PROJECT-SLUG."
  (concat (circleci-api--route--project-pipelines project-slug)
          "/mine"))

(defun circleci-api--route--pipeline-by-id (pipeline-id)
  "Return the API route for the pipeline with PIPELINE-ID."
  (concat (circleci-api--route--pipeline) "/" pipeline-id))

(defun circleci-api--route--pipeline-config (pipeline-id)
  "Return the API route for the config of the pipeline with PIPELINE-ID."
  (concat (circleci-api--route--pipeline-by-id pipeline-id)
          "/config"))

(defun circleci-api--route--pipeline-workflows (pipeline-id)
  "Return the API route for the workflows of the pipeline with PIPELINE-ID."
  (concat (circleci-api--route--pipeline-by-id pipeline-id)
          "/workflow"))

;; Plumbing:

(cl-defun circleci-api--default-handler (&key symbol-status circleci-responses &allow-other-keys)
  "Default RESPONSE handler for CircleCI requests.

Currently just prints some info.

SYMBOL-STATUS is provided by request.

CIRCLECI-RESPONSES is filled with a list of responses if the request
was paginated."
  (message "CircleCI request done: %s" symbol-status)
  (when circleci-responses
    (message "Ran %s requests" (length circleci-responses))
    (message "Response: %s" circleci-responses)))

(cl-defun circleci-api-run-request (route &key
                                          (method "GET")
                                          (token circleci-api-token)
                                          (page-token nil)
                                          (params nil)
                                          (data nil)
                                          (handler #'circleci-api--default-handler)
                                          (sync nil))
  "Run the request at ROUTE with authN.

Returns data parsed from JSON.

METHOD is a string, defaulting to \"GET\".

TOKEN is the CircleCI API token, defaulting to the value of
`circleci-api-token'.

PAGE-TOKEN is the optional pagination token for list endpoints.

PARAMS is appended to the HTTP query parameters.

DATA is POST-data as a native object, which is then passed to
`json-encode'.

HANDLER is the handler function to run on success, defaulting to
`circleci-api--default-handler'.

If SYNC is non-nil, this request is run synchronously."
  (request
   route
   :params (cl-concatenate
            'list
            (when params params)
            (when page-token (list (cons "page-token" page-token))))
   :data (cond
          (data
           (json-encode data))
          ((equal "POST" method)
           "{}")
          (t nil))
   :type method
   :headers (list (cons "Circle-Token" token)
                  (cons "Content-Type" "application/json")
                  (cons "Accept" "application/json"))
   :parser 'json-read
   :complete handler
   :sync sync))

(cl-defun circleci-api--pagination-handler (&key
                                            data
                                            error-thrown
                                            symbol-status
                                            response
                                            circleci-route
                                            circleci-args
                                            circleci-handler
                                            circleci-pages
                                            circleci-responses
                                            &allow-other-keys)
  "Response handler function for pagination.

DATA, ERROR-THROWN, SYMBOL-STATUS, and RESPONSE are request-provided
fields.

CIRCLECI-ROUTE and CIRCLECI-ARGS are passed through the handler to be
used in subsequent calls to `circleci-api-run-request'.

CIRCLECI-HANDLER is as well, but only used once the end has been
reached, either by reaching the caller-define limit, or running out of
pages.

CIRCLECI-PAGES and CIRCLECI-RESPONSES are accumulation variables
passed through here to count and aggregate responses."
  (let ((page-token (alist-get 'next_page_token data)))
    (if (and (not (equal 1 circleci-pages))
             page-token)
        ;; But wait, there's more.
        (apply #'circleci-api-run-request
               circleci-route
               :page-token page-token
               :handler (lambda (&rest args)
                          (apply #'circleci-api--pagination-handler
                                 :circleci-route circleci-route
                                 :circleci-args circleci-args
                                 :circleci-handler circleci-handler
                                 :circleci-pages (- circleci-pages 1)
                                 :circleci-responses (cons response circleci-responses)
                                 args))
               :allow-other-keys t
               circleci-args)
      ;; Reached the end, apply original handler.
      ;; TODO merge previous responses?.
      (apply circleci-handler
             :data data
             :error-thrown error-thrown
             :status-symbol symbol-status
             :response response
             :circleci-responses (cons response circleci-responses)
             '()))))

(cl-defun circleci-api-run-paginated-request (route &rest args
                                                    &key
                                                    (handler #'circleci-api--default-handler)
                                                    (pages 1)
                                                    &allow-other-keys)
  "Run a request on ROUTE and keep paginating for PAGES pages.

Use 0 for for PAGES to keep paginating until the end, if you dare.

ARGS is passed to `circleci-api-run-request'.

HANDLER is the handler function to run on the final result. Signature
TBD."
  (apply #'circleci-api-run-request
         route
         :handler (lambda (&rest handler-args)
                    (apply #'circleci-api--pagination-handler
                           :circleci-route route
                           :circleci-args args
                           :circleci-pages pages
                           :circleci-handler handler
                           handler-args))
         :allow-other-keys t
         args))

;; External interface:

;;;###autoload
(defun circleci-api-org-slug (vcs owner)
  "Construct the org slug VCS/OWNER."
  (concat vcs "/" owner))

;;;###autoload
(defun circleci-api-project-slug (vcs owner repo)
  "Construct the project slug VCS/OWNER/REPO."
  (concat vcs "/" owner "/" repo))

;;;###autoload
(cl-defun circleci-api-get-pipelines (org-slug &rest args
                                               &key
                                               (mine nil)
                                               &allow-other-keys)
  "Get recent pipelines for the org with ORG-SLUG.

If MINE is non-nil, only returns pipelines for the authenticated user.

ARGS is passed to `circleci-api-run-request'.

Supply PAGES as a keyword argument to fetch several pages. See
`circleci-api-run-paginated-request' for more info."
  (interactive "sOrg Slug: ") ;; FIXME Get the mine parameter in.
  (apply
   #'circleci-api-run-paginated-request
   (circleci-api--route--pipeline)
   :params (cl-concatenate
            'list
            (list (cons "org-slug" org-slug))
            (when mine (list (cons "mine" mine))))
   args))

;;;###autoload
(cl-defun circleci-api-get-project (project-slug &rest args &allow-other-keys)
  "Get the project with PROJECT-SLUG.

ARGS is passed to `circleci-api-run-request'."
  (interactive "Project Slug: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--project project-slug)
   args))

;;;###autoload
(cl-defun circleci-api-get-pipeline (pipeline-id &rest args &allow-other-keys)
  "Get a pipeline by PIPELINE-ID.

ARGS is passed to `circleci-api-run-request'."
  (interactive "sPipeline ID: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--pipeline-by-id pipeline-id)
   args))

;;;###autoload
(cl-defun circleci-api-get-pipeline-config (pipeline-id &rest args &allow-other-keys)
  "Get the config for the pipeline with PIPELINE-ID.

ARGS is passed to `circleci-api-run-request'."
  (interactive "sPipeline ID: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--pipeline-config pipeline-id)
   args))

;;;###autoload
(cl-defun circleci-api-get-pipeline-workflows (pipeline-id &rest args &allow-other-keys)
  "Get the workflows for the pipeline with PIPELINE-ID.

ARGS is passed to `circleci-api-run-paginated-request'.

Supply PAGES as a keyword argument to fetch several pages. See
`circleci-api-run-paginated-request' for more info."
  (interactive "sPipeline ID: ")
  (apply
   #'circleci-api-run-paginated-request
   (circleci-api--route--pipeline-workflows pipeline-id)
   args))

;;;###autoload
(cl-defun circleci-api-get-project-pipelines (project-slug &rest args &allow-other-keys)
  "Get the pipelines for the project with PROJECT-SLUG.

ARGS is passed to `circleci-api-run-paginated-request'.

Supply PAGES as a keyword argument to fetch several pages. See
`circleci-api-run-paginated-request' for more info."
  (interactive "sProject Slug: ")
  (apply
   #'circleci-api-run-paginated-request
   (circleci-api--route--project-pipelines project-slug)
   args))

;;;###autoload
(cl-defun circleci-api-get-my-project-pipelines (project-slug &rest args &allow-other-keys)
  "Get your pipelines for the project with PROJECT-SLUG.

ARGS is passed to `circleci-api-run-paginated-request'.

Supply PAGES as a keyword argument to fetch several pages. See
`circleci-api-run-paginated-request' for more info."
  (interactive "sProject Slug: ")
  (apply
   #'circleci-api-run-paginated-request
   (circleci-api--route--my-project-pipelines project-slug)
   args))

;;;###autoload
(cl-defun circleci-api-get-workflow (workflow-id &rest args &allow-other-keys)
  "Get the workflow with WORKFLOW-ID.

ARGS is passed to `circleci-api-run-request'."
  (interactive "sWorkflow ID: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--workflow-by-id workflow-id)
   args))

;;;###autoload
(cl-defun circleci-api-get-workflow-jobs (workflow-id &rest args &allow-other-keys)
  "Get the jobs for the workflow with WORKFLOW-ID.

ARGS is passed to `circleci-api-run-paginated-request'.

Supply PAGES as a keyword argument to fetch several pages. See
`circleci-api-run-paginated-request' for more info."
  (interactive "sWorkflow ID: ")
  (apply
   #'circleci-api-run-paginated-request
   (circleci-api--route--workflow-jobs workflow-id)
   args))

(defun some-string (s)
  "Return S if S is not blank, else `nil'."
  (unless (string-blank-p s)
    s))

;;;###autoload
(cl-defun circleci-api-trigger-pipeline (project-slug &rest args
                                                      &key
                                                      (branch nil)
                                                      (tag nil)
                                                      (pipeline-parameters nil)
                                                      &allow-other-keys)
  "Trigger a pipeine for the project with PROJECT-SLUG.

Specifying either BRANCH or TAG (but not both) is required.

PIPELINE-PARMATERS are a native alist, which is passed in as pipeline
parameters.

ARGS is passed to `circleci-api-run-request'."
  (interactive
   (list (read-string "Project Slug: ")
         (read-string "Branch: ")
         (read-string "Tag: ")
         (read-minibuffer "Pipeline Parameters: " nil)))
  (let* ((interactive? (called-interactively-p 'any))
         (branch (if interactive? (some-string (first args)) branch))
         (tag (if interactive? (some-string (second args)) tag))
         (pipeline-parameters (if interactive?
                                  (third args)
                                pipeline-parameters))
         (args (if interactive? (nthcdr 3 args) args))))
  (unless (or branch tag)
    (error "Need to specify either branch or tag"))
  (when (and branch tag)
    (error "Cannot specify branch and tag"))
  (apply
   #'circleci-api-run-request
   (circleci-api--route--project-pipelines project-slug)
   :method "POST"
   :data (cl-concatenate
          'list
          (list (cons "parameters" pipeline-parameters))
          (when branch (list (cons "branch" branch)))
          (when tag (list (cons "tag" tag))))
   :allow-other-keys t
   args))

;;;###autoload
(cl-defun circleci-api-cancel-workflow (workflow-id &rest args &allow-other-keys)
  "Cancel the workflow with WORKFLOW-ID.

ARGS is passed to `circleci-api-run-request'."
  (interactive "sWorkflow ID: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--workflow-cancel workflow-id)
   :method "POST"
   args))

;;;###autoload
(cl-defun circleci-api-rerun-workflow (workflow-id &rest args
                                                   &key
                                                   (from-failed nil)
                                                   &allow-other-keys)
  "Rerun the workflow with WORKFLOW-ID.

If FROM-FAILED is non-nil rerun from the failed job, otherwise rerun
everything.

ARGS is passed to `circleci-api-run-request'."
  (interactive
   (list (read-string "Workflow ID: ")
         (yes-or-no-p "From failed? ")))
  (let* ((interactive? (called-interactively-p 'any))
         (from-failed (if interactive? (first args) from-failed))
         (args (if interactive? (rest args) args)))
    (apply
     #'circleci-api-run-request
     (circleci-api--route--workflow-rerun workflow-id)
     :method "POST"
     :data (when from-failed '((from-failed t)))
     :allow-other-keys t
     args)))

;;;###autoload
(cl-defun circleci-api-approve-job (workflow-id job-id &rest args &allow-other-keys)
  "Approve the job with JOB-ID in the workflow with WORKFLOW-ID.

ARGS is passed to `circleci-api-run-request'."
  (interactive "sWorkflow ID: \nsJob ID: ")
  (apply
   #'circleci-api-run-request
   (circleci-api--route--job-approve workflow-id job-id)
   :method "POST"
   :allow-other-keys t
   args))

(provide 'circleci-api)

;;; circleci-api.el ends here
