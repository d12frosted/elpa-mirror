;;; traad.el --- emacs interface to the traad refactoring server. -*- lexical-binding: t -*-
;;
;; Copyright (c) 2012-2017 Austin Bingham
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version: 3.1.1
;; Package-Version: 20180507.1511
;; Package-Commit: 1f05cb4e5e96a90d2fb2bbc93093084327c40cf2
;; URL: https://github.com/abingham/traad
;; Package-Requires: ((dash "2.13.0") (deferred "0.3.2") (popup "0.5.0") (request "0.2.0") (request-deferred "0.2.0") (virtualenvwrapper "20151123"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Description:
;;
;; traad is a JSON+HTTP server built around the rope refactoring library. This
;; file provides an API for talking to that server - and thus to rope - from
;; emacs lisp. Or, put another way, it's another way to use rope from emacs.
;;
;; For more details, see the project page at
;; https://github.com/abingham/traad.
;;
;; Installation:
;;
;; Copy traad.el to some location in your emacs load path. Then add
;; "(require 'traad)" to your emacs initialization (.emacs,
;; init.el, or something).
;;
;; Example config:
;;
;;   (require 'traad)
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'cl)
(require 'dash)
(require 'deferred)
(require 'json)
(require 'popup)
(require 'request)
(require 'request-deferred)
(require 'virtualenvwrapper)

(defcustom traad-save-unsaved-buffers 'ask
  "What to do when there are unsaved buffers before a refactoring.

Options are:

`ask'
      Ask the user if buffers should be saved.

`always'
     Always save modified buffers without asking.

`never'
     Never save unmodified buffers."
  :type '(choice (const :tag "Ask the user" ask)
                 (const :tag "Always save changes" always)
                 (const :tag "Never save changes" never))
  :risky t)

(defgroup traad nil
  "A Python refactoring tool."
  :group 'tools
  :group 'programming)

(defconst traad-host "127.0.0.1"
  "The host on which the traad server is running.")

(defcustom traad-server-program nil
  "The name of the traad server program.

If this is nil (default) then the server found in the
`traad-environment-name' virtual environment is used."
  :type '(repeat string)
  :group 'traad)

(defcustom traad-server-args (list "-V" "2")
  "Parameters passed to the traad server before the directory name."
  :type '(repeat string)
  :group 'traad)

(defcustom traad-debug nil
  "Whether debug info should be generated."
  :type '(boolean)
  :group 'traad)

(defconst traad-required-protocol-version 3
  "The required protocol version.")

(defcustom traad-environment-name "traad"
  "The name of the Python environment containing the traad server to use.

When `traad-install-server' runs, it uses this variable to
determine where to install the server.

When `traad-server-program' is nil, this variable is used to
determine where the traad server program is installed.

This name is used by `virtualenvwrapper.el' to locate the
virtual environment into which the desired version of traad is
installed.  If you have multiple traads in different virtual
environment (e.g. one for Python 2 and one for Python 3) then you
may need to dynamically alter this variable to select the one you
want to use."
  :group 'traad)

(defun traad--server-command ()
  "Get the command to launch the server."
  (or traad-server-program
      (venv-with-virtualenv
       traad-environment-name
       (let ((script (funcall 'executable-find "traad")))
         (if script
             (list script)
           (error "No traad executable found"))))))

;; represents a single server instance. We may be running many for different
;; projects.
(cl-defstruct traad--server
  (host "" :read-only t)
  (proc nil :read-only t))

(defun traad--open (directory)
  "Open a traad server in `directory'.

Returns `traad--server' struct.
"
  (let ((proc-buff (get-buffer-create (format "*traad-server: %s*" directory))))
    (with-current-buffer proc-buff
      (erase-buffer)
      (let* ((program (traad--server-command))
             (program (if (listp program) program (list program)))
             (args (append traad-server-args
                           (list "-p" "0")
                           (list directory)))
             (program+args (append program args))
             (default-directory "~/")
             (proc (apply #'start-process "traad-server" proc-buff program+args))
             (cont 1)
             (server nil))
        (while cont
          (set-process-query-on-exit-flag proc nil)
          (accept-process-output proc 0 100 t)
          (cond
           ((string-match "^Listening on http://.*:\\\([0-9]+\\\)/$" (buffer-string))
            (let ((server-host (concat traad-host ":" (match-string 1 (buffer-string)))))
              (setq server (make-traad--server :host server-host :proc proc)
                    cont nil)))
           (t
            (incf cont)
            (when (< 30 cont) ; timeout after 3 seconds
              (error "Server timeout.")))))
        server))))

(defun traad--check-protocol-version (path)
  (deferred:$

    (traad--deferred-request path "/protocol_version")

    (deferred:nextc it
      (lambda (req)
        (let ((protocol-version (assoc-default
                                 'protocol-version
                                 (request-response-data req))))
          (if (eq protocol-version traad-required-protocol-version)
              (message "Supported protocol version detected: %s" protocol-version)
            (error "Server protocol version is %s, but we require version %s"
                   protocol-version
                   traad-required-protocol-version)))))))

                                        ; TODO
;; (defun traad-add-cross-project (directory)
;;   "Add a cross-project to the traad instance."
;;   (interactive
;;    (list
;;     (read-directory-name "Directory:")))
;;   (traad-call 'add_cross_project directory))

                                        ; TODO
;; (defun traad-remove-cross-project (directory)
;;   "Remove a cross-project from the traad instance."
;;   (interactive
;;    (list
;;     (completing-read
;;      "Directory: "
;;      (traad-call 'cross_project_directories))))
;;   (traad-call 'remove_cross_project directory))

                                        ; TODO
;; (defun traad-get-cross-project-directories ()
;;   "Get a list of root directories for cross projects."
;;   (interactive)
;;   (traad-call 'cross_project_directories))

(defun traad--unredo (location idx)
  "Common implementation for undo and redo."
  (when (traad--all-changes-saved)
    (lexical-let ((data (list (cons "index" idx))))

      (deferred:$

        (traad--deferred-request
         (buffer-file-name)
         location
         :data data
         :type "POST")

        (deferred:nextc it
          (lambda (rsp)
            (let* ((response (request-response-data rsp))
                   (changesets (assoc-default 'changes response)))
              (-map
               (lambda (changeset)
                 (dolist (path (traad--change-set-to-paths changeset))
                   (let* ((root (traad--find-project-root path))
                          (full-path (expand-file-name (traad--join-path root path)))
                          (buff (get-file-buffer full-path)))
                     (if buff
                         (with-current-buffer buff
                           (revert-buffer :ignore-auto :no-confirm))))))
               changesets)))))))
  )

;;;###autoload
(defun traad-undo (idx)
  "Undo the IDXth change from the history. \
IDX is the position of an entry in the undo list (see: \
traad-history). This change and all that depend on it will be \
undone. \
Python-like negative indexing works here, so you can \
undo the most recent change by passing `-1' (the default value)."
  (interactive
   (list
    (read-number "Index: " -1)))
  (traad--unredo "/history/undo" idx))


;;;###autoload
(defun traad-redo (idx)
  "Redo the IDXth change from the history. \
IDX is the position of an entry in the redo list (see: \
traad-history). This change and all that depend on it will be \
redone. \
Python-like negative indexing works here, so you can \
redo the most recent undo by passing `-1' (the default value)."
  (interactive
   (list
    (read-number "Index: " -1)))
  (traad--unredo "/history/redo" idx))

(defun traad--update-history-buffer ()
  "Update the contents of the history buffer, creating it if \
necessary. Return the history buffer."
  (deferred:$

    (deferred:parallel
      (traad--deferred-request
       (buffer-file-name)
       "/history/view_undo")
      (traad--deferred-request
       (buffer-file-name)
       "/history/view_redo"))

    (deferred:nextc it
      (lambda (inputs)
        (let* ((undo (assoc-default 'history (request-response-data (elt inputs 0))))
               (redo (assoc-default 'history (request-response-data (elt inputs 1))))
               (buff (get-buffer-create "*traad-history*")))
          (set-buffer buff)
          (erase-buffer)
          (insert "== UNDO HISTORY ==\n")
          (if undo (insert (pp-to-string (traad--enumerate undo))))
          (insert "\n")
          (insert "== REDO HISTORY ==\n")
          (if redo (insert (pp-to-string (traad--enumerate redo))))
          buff)))))

;;;###autoload
(defun traad-display-history ()
  "Display undo and redo history."
  (interactive)
  (deferred:$
    (traad--update-history-buffer)
    (deferred:nextc it
      (lambda (buffer)
        (switch-to-buffer buffer)))))

(defun traad--history-info-core (location)
  "Display information on a single undo/redo operation."

  (deferred:$

    (traad--deferred-request
     (buffer-file-name)
     location)

    (deferred:nextc it
      (lambda (rsp)
        (let ((buff (get-buffer-create "*traad-change*"))
              (info (assoc-default 'info (request-response-data rsp))))
          (switch-to-buffer buff)
          (diff-mode)
          (erase-buffer)
          (insert "Description: " (cdr (assoc 'description info)) "\n"
                  "Time: " (number-to-string (cdr (assoc 'time info))) "\n"
                  "Change:\n"
                  (cdr (assoc 'full_change info))))))))

;;;###autoload
(defun traad-undo-info (i)
  "Get info on the I'th undo history."
  (interactive
   (list
    (read-number "Undo index: " -1)))
  (traad--history-info-core
   (concat "/history/undo_info/" (number-to-string i))))

;;;###autoload
(defun traad-redo-info (i)
  "Get info on the I'th redo history."
  (interactive
   (list
    (read-number "Redo index: " -1)))
  (traad--history-info-core
   (concat "/history/redo_info/" (number-to-string i))))

;;;###autoload
(defun traad-auto-import ()
  (interactive)

  (when (traad--all-changes-saved)

    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/auto_import/get_imports"
       :type "POST"
       :data (list (cons "path" (buffer-file-name))
                   (cons "offset" (traad--adjust-point (point)))))

      (deferred:nextc it
        (lambda (rsp)
          (let* ((buff (get-buffer-create "*traad-get-imports*"))
                 (data (request-response-data rsp))
                 (imports (assoc-default 'imports data))
                 (location (assoc-default 'location data))
                 (menu-entries
                  (sort
                   (mapcar
                    (lambda (import)
                      (format "from %s import %s"
                              (elt import 1)
                              (elt import 0)))
                    imports)
                   'string-lessp)))
            (if menu-entries
                (let ((selection (popup-menu*
                                  menu-entries
                                  :margin-left 1
                                  :margin-right 1
                                  )))
                  (save-excursion
                    (goto-line location)
                    (insert selection)
                    (insert "\n")))
              (message "No auto-import candidates (perhaps index is being built)"))))))))

;;;###autoload
(defun traad-rename (new-name)
  "Rename the object at the current location."
  (interactive
   (list
    (read-string "New name: ")))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/rename"
   :data (list (cons "name" new-name)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-rename-module (new-name)
  "Rename the current module."
  (interactive
   (list
    (read-string "New name: ")))
  (deferred:$
    (traad--fetch-perform
     (buffer-file-name)
     "/refactor/rename"
     :data (list (cons "name" new-name)
                 (cons "path" (buffer-file-name))))

    (deferred:nextc it
      (lambda (_)
        (let* ((dir-name (file-name-directory (buffer-file-name)))
               (new-name (expand-file-name (concat dir-name "/" new-name ".py"))))
          (kill-buffer (current-buffer))
          (switch-to-buffer (find-file new-name)))))))

;;;###autoload
(defun traad-move ()
  "Call the correct form of `move` based on the type of thing at the point."
  (interactive)
  (pcase (traad-thing-at (point))
    ('module (call-interactively 'traad-move-module))
    ('function (call-interactively 'traad-move-global))
    (_ (call-interactively 'traad-move-moodule))))


;;;###autoload
(defun traad-move-global (dest)
  "Move the object at the current location to dest."
  (interactive
   (list
    (read-file-name "Destination file: " nil nil "confirm")))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/move_global"
   :data (list (cons "dest" dest)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-move-module (dest)
  "Move the object at the current location to dest."
  (interactive
   (list
    (read-directory-name "Destination directory: " nil nil "confirm")))
  (deferred:$
    (traad--fetch-perform
     (buffer-file-name)
     "/refactor/move_module"
     :data (list (cons "dest" dest)
                 (cons "path" (buffer-file-name))))

    ;; Close current buffer, opening new one on moved file.
    (deferred:nextc it
      (lambda (_)
        (let* ((base_name (file-name-nondirectory (buffer-file-name)))
               (new_name (expand-file-name (concat dest "/" base_name))))
          (kill-buffer (current-buffer))
          (switch-to-buffer (find-file new_name)))))))

;;;###autoload
(defun traad-normalize-arguments ()
  "Normalize the arguments for the method at point."
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/normalize_arguments"
   :data (list (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-remove-argument (index)
  "Remove the INDEXth argument from the signature at point."
  (interactive
   (list
    (read-number "Index: ")))
                                        ; TODO: Surely there's a
                                        ; better way to construct
                                        ; these lists...
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/remove_argument"
   :data (list (cons "arg_index" index)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-add-argument (index name default value)
  "Add a new argument at `index' in the signature at point."
  (interactive
   (list
    (read-number "Index: ")
    (read-string "Name: ")
    (read-string "Default: ")
    (read-string "Value: ")))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/add_argument"
   :data (list (cons "arg_index" index)
               (cons "name" name)
               (cons "default" default)
               (cons "value" value)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-inline ()
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/inline"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-introduce-parameter (parameter)
  (interactive
   (list
    (read-string "Parameter: ")))

  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/introduce_parameter"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point)))
          (cons "parameter" parameter))))

;;;###autoload
(defun traad-encapsulate-field ()
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/encapsulate_field"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-local-to-field ()
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/local_to_field"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-use-function ()
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/use_function"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

(defun traad--extract-core (location name begin end)
  ;; TODO: refactor this common pattern of getting changes, applying them, and refreshing buffers.
  (traad--fetch-perform-refresh
   (buffer-file-name)
   location
   :data (list (cons "path" (buffer-file-name))
               (cons "start-offset" (traad--adjust-point begin))
               (cons "end-offset" (traad--adjust-point end))
               (cons "name" name))))

;;;###autoload
(defun traad-extract-method (name begin end)
  "Extract the currently selected region to a new method."
  (interactive "sMethod name: \nr")
  (traad--extract-core "/refactor/extract_method" name begin end))

;;;###autoload
(defun traad-extract-variable (name begin end)
  "Extract the currently selected region to a new variable."
  (interactive "sVariable name: \nr")
  (traad--extract-core "/refactor/extract_variable" name begin end))

;;;###autoload
(defun traad-organize-imports (filename)
  "Organize the import statements in `filename'."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/organize"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-expand-star-imports (filename)
  "Expand * import statements in `filename'."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/expand_stars"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-froms-to-imports (filename)
  "Convert 'from' imports to normal imports in `filename''."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/froms_to_imports"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-relatives-to-absolutes (filename)
  "Convert relative imports to absolute in `filename'."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/relatives_to_absolutes"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-handle-long-imports (filename)
  "Clean up long import statements in `filename'."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/handle_long_imports"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-imports-super-smackdown (filename)
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (mapcar (lambda (f) (funcall f filename))
          (list
           'traad-expand-star-imports
           'traad-relatives-to-absolutes
           'traad-froms-to-imports
           'traad-handle-long-imports
           'traad-organize-imports)))

;; (defun traad-find-occurrences (pos)
;;   "Get all occurences the use of the symbol at POS in the
;; current buffer.

;;   Returns a deferred request. The 'data' key in the JSON hold the
;;   location data in the form:

;;  [[path, [region-start, region-stop], offset, unsure, lineno], . . .]
;;   "
;;   (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
;;              (cons "path" (buffer-file-name)))))
;;     (traad--deferred-request
;;      "/findit/occurrences"
;;      :data data
;;      :type "POST")))

;; (defun traad-find-implementations (pos)
;;   "Get the implementations of the symbol at POS in the current buffer.

;;   Returns a deferred request. The 'data' key in the JSON hold the
;;   location data in the form:

;;  [[path, [region-start, region-stop], offset, unsure, lineno], . . .]
;;   "
;;   (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
;;              (cons "path" (buffer-file-name)))))
;;     (traad--deferred-request
;;      "/findit/implementations"
;;      :data data
;;      :type "POST")))

;; (defun traad-find-definition (pos)
;;   "Get location of a function definition.

;;   Returns a deferred request. The 'data' key in the JSON hold the location in
;;   the form:

;;  [path, [region-start, region-stop], offset, unsure, lineno]
;;   "
;;   (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
;;              (cons "path" (buffer-file-name)))))
;;     (traad--deferred-request
;;      "/findit/definition"
;;      :data data
;;      :type "POST")))

;; (defun traad-display-findit (pos func buff-name)
;;   "Common display routine for occurrences and implementations.

;;   Call FUNC with POS and fill up the buffer BUFF-NAME with the results."
;;   (lexical-let ((buff-name buff-name))
;;     (deferred:$
;;                                         ; Fetch in parallel...
;;       (deferred:parallel

;;                                         ; ...the occurrence data...
;;         (deferred:$
;;           (apply func (list pos))
;;           (deferred:nextc it
;;             'request-response-data)
;;           (deferred:nextc it
;;             (lambda (x) (assoc-default 'data x))))

;;                                         ; ...and the project root.
;;         (deferred:$
;;           (traad-get-root)
;;           (deferred:nextc it
;;             'request-response-data)
;;           (deferred:nextc it
;;             (lambda (x) (assoc-default 'root x)))))

;;       (deferred:nextc it
;;         (lambda (input)
;;           (let ((locs (elt input 0)) ; the location vector
;;                 (root (elt input 1)) ; the project root
;;                 (buff (get-buffer-create buff-name))
;;                 (inhibit-read-only 't))
;;             (pop-to-buffer buff)
;;             (erase-buffer)

;;                                         ; For each location, add a
;;                                         ; line to the buffer.  TODO:
;;                                         ; Is there a "dovector" we can
;;                                         ; use? This is a bit fugly.
;;             (mapcar
;;              (lambda (loc)
;;                (lexical-let* ((path (elt loc 0))
;;                               (abspath (concat root "/" path))
;;                               (lineno (elt loc 4))
;;                               (code (nth (- lineno 1) (traad--read-lines abspath))))
;;                  (insert-button
;;                   (format "%s:%s: %s\n"
;;                           path
;;                           lineno
;;                           code)
;;                   'action (lambda (x)
;;                             (goto-line
;;                              lineno
;;                              (find-file-other-window abspath))))))
;;              locs)))))))


;; ;;;###autoload
;; (defun traad-display-occurrences (pos)
;;   "Display all occurences the use of the symbol at POS in the
;; current buffer."
;;   (interactive "d")
;;   (traad-display-findit pos 'traad-find-occurrences "*traad-occurrences*"))

;; ;;;###autoload
;; (defun traad-display-implementations (pos)
;;   "Display all occurences the use of the symbol as POS in the
;; current buffer."
;;   (interactive "d")
;;   (traad-display-findit pos 'traad-find-implementations "*traad-implementations*"))

;; ;;;###autoload
;; (defun traad-goto-definition (pos)
;;   "Go to the definition of the function as POS."
;;   (interactive "d")
;;   (deferred:$
;;     (deferred:parallel
;;       (deferred:$
;;  (traad-find-definition pos)
;;  (deferred:nextc it
;;    'request-response-data)
;;  (deferred:nextc it
;;    (lambda (x) (assoc-default 'data x))))
;;       (deferred:$
;;  (traad-get-root)
;;  (deferred:nextc it
;;    'request-response-data)
;;  (deferred:nextc it
;;    (lambda (x) (assoc-default 'root x)))))

;;     (deferred:nextc it
;;       (lambda (input)
;;  (let ((loc (elt input 0)))
;;    (if (not loc)
;;        (message "No definition found.")
;;      (letrec ((path (elt loc 0))
;;           (root (elt input 1))
;;           (abspath (if (file-name-absolute-p path) path (concat root "/" path)))
;;           (lineno (elt loc 4)))
;;        (goto-line
;;         lineno
;;         (find-file-other-window abspath)))))))))

;; ;;;###autoload
;; (defun traad-findit (type)
;;   "Run a findit function at the current point."
;;   (interactive
;;    (list
;;     (completing-read
;;      "Type: "
;;      (list "occurrences" "implementations" "definition"))))
;;   (cond
;;    ((equal type "occurrences")
;;     (traad-display-occurrences (point)))
;;    ((equal type "implementations")
;;     (traad-display-implementations (point)))
;;    ((equal type "definition")
;;     (traad-goto-definition (point)))))

;;;###autoload
(defun traad-thing-at (pos)
  "Get the type of the Python thing at `pos'."
  (interactive "d")
  (let* ((data (list (cons "offset" (traad--adjust-point pos))
                     (cons "path" (buffer-file-name))))
         (request-backend 'url-retrieve)
         (url (traad--construct-url (buffer-file-name) "/thing_at"))
         (result (request-response-data
                  (request
                   url
                   :headers '(("Content-Type" . "application/json"))
                   :data (json-encode data)
                   :sync t
                   :parser 'json-read
                   :data (json-encode data)
                   :type "POST"))))
    (alist-get 'thing result)))

;;;###autoload
(defun traad-code-assist (pos)
  "Get possible completions at POS in current buffer.

This returns an alist like ((completions . [[name documentation scope type]]) (result . \"success\"))"
  (interactive "d")
  (let ((data (list (cons "offset" (traad--adjust-point pos))
                    (cons "path" (buffer-file-name))))
        (request-backend 'url-retrieve)
        (url (traad--construct-url (buffer-file-name) "/code_assist/completions")))
    (request-response-data
     (request
      url
      :headers '(("Content-Type" . "application/json"))
      :data (json-encode data)
      :sync t
      :parser 'json-read
      :data (json-encode data)
      :type "POST"))))

(defun traad--display-in-buffer (msg buffer)
  "Display `msg' in `buffer', clearing the buffer first."
  (let ((cbuff (current-buffer))
        (buff (get-buffer-create buffer))
        (inhibit-read-only 't))
    (pop-to-buffer buff)
    (erase-buffer)
    (insert msg)
    (pop-to-buffer cbuff)))

(defun traad-get-calltip (pos)
  "Get the calltip for an object.

  Returns a deferred which produces the calltip string.
  "
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/code_assist/calltip"
       :data data
       :type "POST")
      (deferred:nextc it
        (lambda (req)
          (assoc-default
           'calltip
           (request-response-data req)))))))

;;;###autoload
(defun traad-display-calltip (pos)
  "Display calltip for an object."
  (interactive "d")
  (deferred:$
    (traad-get-calltip pos)
    (deferred:nextc it
      (lambda (calltip)
        (if calltip
            (traad--display-in-buffer
             calltip
             "*traad-calltip*")
          (message "No calltip available."))))))

;;;###autoload
(defun traad-popup-calltip (pos)
  (interactive "d")
  (lexical-let ((pos pos))
    (deferred:$
      (traad-get-calltip pos)
      (deferred:nextc it
        (lambda (calltip)
          (if calltip
              (popup-tip
               calltip
               :point pos)))))))

(defun traad--get-doc (pos)
  "Get docstring for an object.

  Returns a deferred which produces the doc string. If there is
  not docstring, the deferred produces nil.
  "
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$

      (traad--deferred-request
       (buffer-file-name)
       "/code_assist/doc"
       :data data
       :type "POST")

      (deferred:nextc it
        (lambda (req)
          (assoc-default
           'doc
           (request-response-data req)))))))

;;;###autoload
(defun traad-display-doc (pos)
  "Display docstring for an object."
  (interactive "d")
  (deferred:$
    (traad--get-doc pos)
    (deferred:nextc it
      (lambda (doc)
        (if doc
            (traad--display-in-buffer
             doc
             "*traad-doc*")
          (message "No docstring available."))))))

;;;###autoload
(defun traad-popup-doc (pos)
  (interactive "d")
  (lexical-let ((pos pos))
    (deferred:$
      (traad--get-doc pos)
      (deferred:nextc it
        (lambda (doc)
          (if doc
              (popup-tip
               doc
               :point pos)))))))

(defvar traad--server-map (make-hash-table :test 'equal)
  "Mapping of project roots to `traad--server' structs.")

;;;###autoload
(defun traad-kill-all ()
  "Kill all traad servers and associatd buffers."
  (interactive)
  (maphash
   (lambda (root server)
     (let* ((proc (traad--server-proc server))
            (buff (process-buffer proc)))
       (kill-buffer buff)))
   traad--server-map)
  (clrhash traad--server-map))

(defun traad--get-server (project-root)
  "Get the server entry for `project-root'."
  (gethash project-root traad--server-map))

(defun traad--add-server (project-root server)
  "Add a server entry for `prbject-root'."
  (puthash project-root server traad--server-map))

(defun traad--remove-server (project-root)
  "Remove the server entry for `project-root'."
  (remhash project-root traad--server-map))

(defun traad--ensure-server (project-root)
  "Get the host of the server for `project-root'.

This starts a new server if necessary."
  (let* ((project-root (f-full project-root))
         (server (traad--get-server project-root)))
    (cond
     ;; Is there no server entry for this project?
     ((null server)
      (pcase (traad--open project-root)
        (`nil (error "Unable to start new server"))
        (server
         (traad--add-server project-root server)
         (traad--check-protocol-version project-root)
         (traad--server-host server))))

     ;; Is the process for the entry dead?
     ((not (process-live-p (traad--server-proc server)))
      (traad--remove-server project-root)
      (traad--ensure-server project-root))

     ;; We found a live server!
     (t (traad--server-host server)))))

(defun traad--find-project-root (for-path)
  "Find the root directory for the project containg `for-path'.

Returns `nil' if there is not such project.
"
  (locate-dominating-file for-path ".ropeproject"))

(defun traad--get-host (for-path)
  "Get the host of the server responsible for `for-path'.

This will start a new server if necessary.
"
  (let ((project-root
         (or
          (traad--find-project-root for-path)
          (read-directory-name "Project root? "))))
    (traad--ensure-server project-root)))

(defun traad--construct-url (for-path location)
  "Construct a URL to a specific location on the traad server.

  In short: http://server_host:server_port<location>
  "
  (let ((host (traad--get-host for-path)))
    (concat "http://" host location)))

(defun traad--save-all ()
  "Save all modified buffers without confirmation and return non-`nil'."
  (save-some-buffers 'no-confirm)
  'saved)

(defun traad--all-changes-saved ()
  "Determine if all unsaved changes are changed.

This checks `traad-save-unsaved-buffers' to know how to behave
when there are modified buffers. This returns non-`nil' only if
there were no modified buffers or if any modified buffers were
saved in the process of this function.
"
  (let ((save-all (lambda () (save-some-buffers 'no-confirm) t)))
    (or
     (not (-any
           (lambda (buff)
             (and (buffer-file-name buff)
                  (buffer-modified-p buff)))
           (buffer-list)))
     (case traad-save-unsaved-buffers
       ('never nil)
       ('always
        (funcall save-all))
       ('ask
        (and (yes-or-no-p "Save modified buffers? ")
             (funcall save-all)))))))

(defun* traad--fetch-perform (for-path location &key (data '()))
  "Perform common refactoring path: fetch changes from
`location' (passing `data' as a payload) and perform them."
  ;; TODO: check for non-success and lack of 'changes key
  (when (traad--all-changes-saved)
    (let ((response nil) (pth for-path))
      (deferred:$

        ;; Get the changes
        (traad--deferred-request
         pth
         location
         :type "POST"
         :data data)

        ;; Perform the changes
        (deferred:nextc it
          (lambda (rsp)
            (let ((response (request-response-data rsp)))
              (traad--deferred-request
               pth
               "/refactor/perform"
               :type "POST"
               :data response))))))))

(defun* traad--fetch-perform-refresh (for-path location &key (data '()))
  "Perform common refactoring path: fetch changes from
`location' (passing `data' as a payload), perform them, and
refresh affected buffers."
  (when (traad--all-changes-saved)
    (let ((response nil) (pth for-path))
      (deferred:$

        ;; Get the changes
        (traad--deferred-request
         pth
         location
         :type "POST"
         :data data)

        ;; Perform the changes
        (deferred:nextc it
          (lambda (rsp)
            (setq response (request-response-data rsp))
            (traad--deferred-request
             pth
             "/refactor/perform"
             :type "POST"
             :data response)))

        ;; Refresh buffers in the response
        (deferred:nextc it
          (lambda (rsp)
            (let ((changeset (assoc-default 'changes response)))
              (dolist (path (traad--change-set-to-paths changeset))
                (let* ((root (traad--find-project-root path))
                       (full-path (expand-file-name (traad--join-path root path)))
                       (buff (get-file-buffer full-path)))
                  (if buff
                      (with-current-buffer buff
                        (revert-buffer :ignore-auto :no-confirm))))))))))))

(defun* traad--deferred-request (for-path location &key (type "GET") (data '()))
  (let ((request-backend 'url-retrieve))
    (request-deferred
     (traad--construct-url for-path location)
     :type type
     :parser 'json-read
     :headers '(("Content-Type" . "application/json;charset=utf-8"))
     :data (encode-coding-string (json-encode data) 'utf-8))))

(defun traad--range (upto)
  (defun range_ (x)
    (if (> x 0)
        (cons x (range_ (- x 1)))
      (list 0)))
  (nreverse (range_ upto)))

(defun traad--enumerate (l)
  (map 'list 'cons (traad--range (length l)) l))

(defun traad--adjust-point (p)
  "Rope uses 0-based indexing, but Emacs points are 1-based."
  (- p 1))

(defun traad--read-lines (path)
  "Return a list of lines of a file at PATH."
  (with-temp-buffer
    (insert-file-contents path)
    (split-string (buffer-string) "\n" nil)))

                                        ; TODO: invalidation support?

(defconst traad--install-server-command
  "pip install --upgrade traad")

;;;###autoload
(defun traad-install-server ()
  "Install traad.

This installs the server into the `traad-environment-name'
virtual environment, creating the virtualenv if necessary.

By default, then, it installs traad into
`PYTHON-ENVIRONMENT_DIRECTORY/traad`."
  (interactive)
  (ignore-errors
    (venv-mkvirtualenv traad-environment-name))
  (venv-with-virtualenv-shell-command
   traad-environment-name
   traad--install-server-command))

;; Utilities
(defun traad--change-set-to-paths (changeset)
  "Get all paths of affected files from a changeset.

A changeset looks like this:
      ['ChangeSet',
        ['Renaming <using_project> to <foo_log>',
          [['ChangeContents',
              ['tests/test_json_api.py',
               '<contents>',
               null]],
           . . .
          ],
          null]]
"
  (let* ((refactoring (elt changeset 1))
         (change-contents (elt refactoring 1)))
    (-map
     (lambda (content)
       (let ((file-change (elt content 1)))
         (elt file-change 0)))
     change-contents)))

(defun traad--join-path (a b)
  (concat (file-name-as-directory a) b))

(provide 'traad)

;;; traad.el ends here
