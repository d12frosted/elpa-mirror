;;; dart-server.el --- Minor mode for editing Dart files -*- lexical-binding: t; -*-

;; Author: Natalie Weizenbaum
;;      Brady Trainor <mail@bradyt.com>
;; Maintainer: Brady Trainor <mail@bradyt.com>
;; URL: https://github.com/bradyt/dart-server
;; Package-Version: 20210501.1445
;; Package-Commit: 75562baf9a89b7e314bc2f795f6ecdc5d1f2cc8c
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.5") (cl-lib "0.5") (dash "2.10.0") (flycheck "0.23") (s "1.10"))
;; Keywords: languages

;; Copyright (C) 2011 Google Inc.
;;
;; This program is free software: you can redistribute it and/or modify
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; This file contains several functions and variables adapted from the
;; code in https://github.com/dominikh/go-mode.el

;; Definitions adapted from go-mode.el are
;;
;; gofmt-command gofmt-args gofmt-show-errors gofmt go--apply-rcs-patch
;; gofmt--kill-error-buffer gofmt--process-errors gofmt-before-save
;; go--goto-line go--delete-whole-line

;; go-mode.el uses this license:
;;
;; Copyright (c) 2014 The go-mode Authors. All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;    * Redistributions of source code must retain the above copyright
;; notice, this list of conditions and the following disclaimer.
;;    * Redistributions in binary form must reproduce the above
;; copyright notice, this list of conditions and the following disclaimer
;; in the documentation and/or other materials provided with the
;; distribution.
;;    * Neither the name of the copyright holder nor the names of its
;; contributors may be used to endorse or promote products derived from
;; this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; Minor mode for editing Dart files.

;; Provides dart server features, such as formatting, analysis,
;; flycheck, etc.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'dash)
(ignore-errors
 (require 'flycheck))
(require 'help-mode)
(require 'json)
(require 'rx)
(require 's)
(require 'subr-x)

;;; Utility functions and macros

(defun dart-server-log (msg)
  "Logs MSG to the dart log."
  (let* ((log-buffer (get-buffer-create "*dart-server-debug*"))
         (iso-format-string "%Y-%m-%dT%T%z")
         (timestamp-and-log-string
          (format-time-string iso-format-string (current-time))))
    (with-current-buffer log-buffer
      (goto-char (point-max))
      (insert "\n\n\n")
      (insert (concat timestamp-and-log-string
                      "\n"
                      msg))
      (insert "\n"))))

(defun dart-server-beginning-of-statement ()
  "Moves to the beginning of a Dart statement.

Unlike `c-beginning-of-statement', this handles maps correctly
and will move to the top level of a bracketed statement."
  (while
      (progn
        (back-to-indentation)
        (while (eq (char-after) ?})
          (forward-char)
          (forward-sexp -1)
          (back-to-indentation))
        (unless (dart-server--beginning-of-statement-p)) (forward-line -1))))

(defun dart-server--beginning-of-statement-p ()
  "Returns whether the point is at the beginning of a statement.

Statements are assumed to begin on their own lines. This returns
true for positions before the start of the statement, but on its line."
  (and
   (save-excursion
     (skip-syntax-forward " ")
     (not (or (bolp) (eq (char-after) ?}))))
   (save-excursion
     (skip-syntax-backward " ")
     (when (bolp)
       (cl-loop do (forward-char -1)
             while (looking-at "^ *$"))
       (skip-syntax-backward " ")
       (cl-case (char-before)
         ((?} ?\;) t))))))

(defun dart-server--delete-whole-line (&optional arg)
  "Delete the current line without putting it in the `kill-ring'.
Derived from function `kill-whole-line'.  ARG is defined as for that
function."
  (setq arg (or arg 1))
  (if (and (> arg 0)
           (eobp)
           (save-excursion (forward-visible-line 0) (eobp)))
      (signal 'end-of-buffer nil))
  (if (and (< arg 0)
           (bobp)
           (save-excursion (end-of-visible-line) (bobp)))
      (signal 'beginning-of-buffer nil))
  (cond ((zerop arg)
         (delete-region (progn (forward-visible-line 0) (point))
                        (progn (end-of-visible-line) (point))))
        ((< arg 0)
         (delete-region (progn (end-of-visible-line) (point))
                        (progn (forward-visible-line (1+ arg))
                               (unless (bobp)
                                 (backward-char))
                               (point))))
        (t
         (delete-region (progn (forward-visible-line 0) (point))
                        (progn (forward-visible-line arg) (point))))))

(defconst dart-server--identifier-re
  "[a-zA-Z_$][a-zA-Z0-9_$]*"
  "A regular expression that matches keywords.")

(defun dart-server--forward-identifier ()
  "Moves the point forward through a Dart identifier."
  (when (looking-at dart-server--identifier-re)
    (goto-char (match-end 0))))

(defun dart-server--kill-buffer-and-window (buffer)
  "Kills BUFFER, and its window if it has one.

This is different than `kill-buffer' because, if the buffer has a
window, it respects the `quit-restore' window parameter. See
`quit-window' for details."
  (-if-let (window (get-buffer-window buffer))
      (quit-window t window)
    (kill-buffer buffer)))

(defun dart-server--get (alist &rest keys)
  "Recursively calls `cdr' and `assoc' on ALIST with KEYS.
Returns the value rather than the full alist cell."
  (--reduce-from (cdr (assoc it acc)) alist keys))

(defmacro dart-server--json-let (json fields &rest body)
  "Assigns variables named FIELDS to the corresponding fields in JSON.
FIELDS may be either identifiers or (ELISP-IDENTIFIER JSON-IDENTIFIER) pairs."
  (declare (indent 2))
  (let ((json-value (make-symbol "json")))
    `(let ((,json-value ,json))
       (let ,(--map (if (symbolp it)
                        `(,it (dart-server--get ,json-value ',it))
                      (-let [(variable key) it]
                        `(,variable (dart-server--get ,json-value ',key))))
                    fields)
         ,@body))))

(defun dart-server--property-string (text prop value)
  "Returns a copy of TEXT with PROP set to VALUE.

Converts TEXT to a string if it's not already."
  (let ((copy (substring (format "%s" text) 0)))
    (put-text-property 0 (length copy) prop value copy)
    copy))

(defun dart-server--face-string (text face)
  "Returns a copy of TEXT with its font face set to FACE.

Converts TEXT to a string if it's not already."
  (dart-server--property-string text 'face face))

(defmacro dart-server--fontify-excursion (face &rest body)
  "Applies FACE to the region moved over by BODY."
  (declare (indent 1))
  (-let [start (make-symbol "start")]
    `(-let [,start (point)]
       ,@body
       (put-text-property ,start (point) 'face ,face))))

(defun dart-server--flash-highlight (offset length)
  "Briefly highlights the text defined by OFFSET and LENGTH.
OFFSET and LENGTH are expected to come from the analysis server,
rather than Elisp."
  (-let [overlay (make-overlay (+ 1 offset) (+ 1 offset length))]
    (overlay-put overlay 'face 'highlight)
    (run-at-time "1 sec" nil (lambda () (delete-overlay overlay)))))

(defun dart-server--read-file (filename)
  "Returns the contents of FILENAME."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(defmacro dart-server--with-temp-file (name-variable &rest body)
  "Creates a temporary file for the duration of BODY.
Assigns the filename to NAME-VARIABLE. Doesn't change the current buffer.
Returns the value of the last form in BODY."
  (declare (indent 1))
  `(-let [,name-variable (make-temp-file "dart-server.")]
     (unwind-protect
         (progn ,@body)
       (delete-file ,name-variable))))

(defun dart-server--run-process (executable &rest args)
  "Runs EXECUTABLE with ARGS synchronously.
Returns (STDOUT STDERR EXIT-CODE)."
  (dart-server--with-temp-file stderr-file
    (with-temp-buffer
      (-let [exit-code
             (apply #'call-process
                    executable nil (list t stderr-file) nil args)]
        (list
         (buffer-string)
         (dart-server--read-file stderr-file)
         exit-code)))))

(defun dart-server--try-process (executable &rest args)
  "Like `dart-server--run-process', but only returns stdout.
Any stderr is logged using dart-server-log. Returns nil if the exit code is non-0."
  (-let [result (apply #'dart-server--run-process executable args)]
    (unless (string-empty-p (nth 1 result))
      (dart-server-log (format "Error running %S:\n%s" (cons executable args) (nth 1 result))))
    (if (eq (nth 2 result) 0) (nth 0 result))))

(defvar dart-server--do-it-again-callback nil
  "A callback to call when `dart-server-do-it-again' is invoked.

Only set in `dart-server-popup-mode'.")
(make-variable-buffer-local 'dart-server--do-it-again-callback)


;;; General configuration

(defcustom dart-server-sdk-path
  ;; Use Platform.resolvedExecutable so that this logic works through symlinks
  ;; and wrapper scripts.
  (-when-let (dart (or (executable-find "dart")
                       (let ((flutter (executable-find "flutter")))
                         (when flutter
                           (expand-file-name "cache/dart-sdk/bin/dart"
                                             (file-name-directory flutter))))))
    (dart-server--with-temp-file input
      (with-temp-file input (insert "
        import 'dart:io';

        void main() {
          print(Platform.resolvedExecutable);
        }
        "))
      (-when-let (result (dart-server--try-process dart input))
        (file-name-directory
         (directory-file-name
          (file-name-directory (string-trim result)))))))
  "The absolute path to the root of the Dart SDK."
  :group 'dart-server
  :type 'directory
  :package-version '(dart-server . "0.1.0"))

(defun dart-server-executable-path ()
  "The absolute path to the 'dart' executable.

Returns nil if `dart-server-sdk-path' is nil."
  (when dart-server-sdk-path
    (concat dart-server-sdk-path
            (file-name-as-directory "bin")
            (if (memq system-type '(ms-dos windows-nt))
                "dart.exe"
              "dart"))))


;;; Configuration

(defvar dart-server-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c ?") 'dart-server-show-hover)
    ;; (define-key map (kbd "C-c C-g") 'dart-server-goto)
    (define-key map (kbd "C-c C-f") 'dart-server-find-refs)
    (define-key map (kbd "C-c C-e") 'dart-server-find-member-decls)
    (define-key map (kbd "C-c C-r") 'dart-server-find-member-refs)
    (define-key map (kbd "C-c C-t") 'dart-server-find-top-level-decls)
    (define-key map (kbd "C-c C-o") 'dart-server-format)
    (define-key map (kbd "M-/") 'dart-server-expand)
    (define-key map (kbd "M-?") 'dart-server-expand-parameters)
    map)
  "Keymap used in dart-server buffers.")


;;; Dart analysis server

(cl-defstruct
    (dart-server--analysis-server
     (:constructor dart-server--make-analysis-server))
  "Struct containing data for an instance of a Dart analysis server.

The slots are:
- `process': the process of the running server.
- `buffer': the buffer where responses from the server are written."
  process buffer)

(defgroup dart-server nil
  "Major mode for editing Dart code."
  :group 'languages)

(defvar dart-server-debug nil
  "If non-nil, enables writing debug messages for dart-server.")

(defcustom dart-server-enable-analysis-server nil
  "If non-nil, enables support for Dart analysis server.

The Dart analysis server adds support for error checking, code completion,
navigation, and more."
  :group 'dart-server
  :type 'boolean
  :package-version '(dart-server . "0.1.0"))

(defvar dart-server--analysis-server nil
  "The instance of the Dart analysis server we are communicating with.")

(defun dart-server--analysis-server-snapshot-path ()
  "The absolute path to the snapshot file that runs the Dart analysis server."
  (when dart-server-sdk-path
    (concat dart-server-sdk-path
            (file-name-as-directory "bin")
            (file-name-as-directory "snapshots")
            "analysis_server.dart.snapshot")))

(defvar dart-server-analysis-roots nil
  "The list of analysis roots that are known to the analysis server.

All Dart files underneath the analysis roots are analyzed by the analysis
server.")

(defvar dart-server--analysis-server-next-id 0
  "The ID to use for the next request to the Dart analysis server.")

(defvar dart-server--analysis-server-callbacks nil
  "An alist of ID to callback to be called when the analysis server responds.

Each request to the analysis server has an associated ID.  When the analysis
server sends a response to a request, it tags the response with the ID of the
request.  We look up the callback for the request in this alist and run it with
the JSON decoded server response.")

(defvar dart-server--analysis-server-subscriptions nil
  "An alist of event names to lists of callbacks to be called for those events.

These callbacks take the event object and an opaque subcription
object which can be passed to `dart-server--analysis-server-unsubscribe'.")

(defun dart-server-info (msg)
  "Logs MSG to the dart log if `dart-server-debug' is non-nil."
  (when dart-server-debug (dart-server-log msg)))

(defun dart-server--normalize-path (path)
  (if (equal system-type 'windows-nt)
      (replace-regexp-in-string (rx "/") (rx "\\") path)
    path))

(defun dart-server--start-analysis-server-for-current-buffer ()
  "Initialize Dart analysis server for current buffer.

This starts Dart analysis server and adds either the pub root
directory or the current file directory to the analysis roots."
  (unless dart-server--analysis-server (dart-server-start-analysis-server))
  ;; TODO(hterkelsen): Add this file to the priority files.
  (dart-server-add-analysis-root-for-file)
  (add-hook 'first-change-hook #'dart-server-add-analysis-overlay t t)
  (add-hook 'after-change-functions #'dart-server-change-analysis-overlay t t)
  (add-hook 'after-save-hook #'dart-server-remove-analysis-overlay t t)
  (when (boundp 'flycheck-checkers)
    (add-to-list 'flycheck-checkers 'dart-server-analysis-server)))

(defun dart-server-start-analysis-server ()
  "Start the Dart analysis server.

Initializes analysis server support for all `dart-server' buffers."
  (when dart-server--analysis-server
    (-let [process (dart-server--analysis-server-process dart-server--analysis-server)]
      (when (process-live-p process) (kill-process process)))
    (kill-buffer (dart-server--analysis-server-buffer dart-server--analysis-server)))

  (let* ((process-connection-type nil)
         (dart-server-process
          (start-process "dart-server-analysis-server"
                         "*dart-server-analysis-server*"
                         (dart-server-executable-path)
                         (dart-server--analysis-server-snapshot-path))))
    (set-process-query-on-exit-flag dart-server-process nil)
    (setq dart-server--analysis-server
          (dart-server--analysis-server-create dart-server-process)))

  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (bound-and-true-p dart-server)
        (dart-server--start-analysis-server-for-current-buffer)
        (when (buffer-modified-p buffer) (dart-server-add-analysis-overlay))))))

(defun dart-server--analysis-server-create (process)
  "Create a Dart analysis server from PROCESS."
  (-let [instance (dart-server--make-analysis-server
                   :process process
                   :buffer (generate-new-buffer (process-name process)))]
    (buffer-disable-undo (dart-server--analysis-server-buffer instance))
    (set-process-filter
     process
     (lambda (_ string)
       (dart-server--analysis-server-process-filter instance string)))
    instance))

(defun dart-server-add-analysis-overlay ()
  "Report to the Dart analysis server that it should overlay this buffer.

The Dart analysis server allows clients to 'overlay' file contents with
a client-supplied string.  This is needed because we want Emacs to report
errors for the current contents of the buffer, not whatever is saved to disk."
  ;; buffer-file-name can be nil within revert-buffer, but in that case the
  ;; buffer is just being reverted to its format on disk anyway.
  (when buffer-file-name
    (dart-server--analysis-server-send
     "analysis.updateContent"
     `((files
        . ((,(dart-server--normalize-path buffer-file-name)
            . ((type . "add")
               (content
                . ,(save-restriction (widen) (buffer-string)))))))))))

(defun dart-server-change-analysis-overlay
    (change-begin change-end change-before-length)
  "Report to analysis server that it should change the overlay for this buffer.

The region that changed ranges from CHANGE-BEGIN to CHANGE-END, and the
length of the text before the change is CHANGE-BEFORE-LENGTH. See also
`dart-server-add-analysis-overlay'."
  (dart-server--analysis-server-send
   "analysis.updateContent"
   `((files
      . ((,(dart-server--normalize-path buffer-file-name)
          . ((type . "change")
             (edits
              . (((offset . ,(- change-begin 1))
                  (length . ,change-before-length)
                  (replacement
                   . ,(buffer-substring change-begin change-end))))))))))))

(defun dart-server-remove-analysis-overlay ()
  "Remove the overlay for the current buffer since it has been saved.

See also `dart-server-add-analysis-overlay'."
  (dart-server--analysis-server-send
   "analysis.updateContent"
   `((files . ((,(dart-server--normalize-path buffer-file-name) . ((type . "remove"))))))))

(defun dart-server-add-analysis-root-for-file (&optional file)
  "Add the given FILE's root to the analysis server's analysis roots.

A file's root is the pub root if it is in a pub package, or the file's directory
otherwise.  If no FILE is given, then this will default to the variable
`buffer-file-name'."
  (let* ((file-to-add (or file buffer-file-name))
         (pub-root (locate-dominating-file file-to-add "pubspec.yaml"))
         (current-dir (file-name-directory file-to-add)))
    (if pub-root
        (dart-server-add-to-analysis-roots (directory-file-name (expand-file-name pub-root)))
      (dart-server-add-to-analysis-roots (directory-file-name (expand-file-name current-dir))))))

(defun dart-server-add-to-analysis-roots (dir)
  "Add DIR to the analysis server's analysis roots.

The analysis roots are directories that contain Dart files. The analysis server
analyzes all Dart files under the analysis roots and provides information about
them when requested."
  (add-to-list 'dart-server-analysis-roots (dart-server--normalize-path dir))
  (dart-server--send-analysis-roots))

(defun dart-server--send-analysis-roots ()
  "Send the current list of analysis roots to the analysis server."
  (dart-server--analysis-server-send
   "analysis.setAnalysisRoots"
   `(("included" . ,dart-server-analysis-roots)
     ("excluded" . nil))))

(defun dart-server--analysis-server-send (method &optional params callback)
  "Send the METHOD request to the server with optional PARAMS.

PARAMS should be JSON-encodable.  If you provide a CALLBACK, it will be called
with the JSON decoded response.  Otherwise, the output will just be checked."
  (-let [req-without-id (dart-server--analysis-server-make-request method params)]
    (dart-server--analysis-server-enqueue req-without-id callback)))

(defun dart-server--analysis-server-make-request (method &optional params)
  "Construct a request for the analysis server.

The constructed request will call METHOD with optional PARAMS."
  `((method . ,method) (params . ,params)))

(defun dart-server--analysis-server-on-error-callback (response)
  "If RESPONSE has an error, report it."
  (-when-let (resp-err (assoc-default 'error response))
    (error "Analysis server error: %s" (assoc-default 'message resp-err))))

(defun dart-server--analysis-server-enqueue (req-without-id callback)
  "Send REQ-WITHOUT-ID to the analysis server, call CALLBACK with the result."
  (setq dart-server--analysis-server-next-id (1+ dart-server--analysis-server-next-id))
  (-let [request
         (json-encode (cons (cons 'id (format "%s" dart-server--analysis-server-next-id))
                            req-without-id))]

    ;; Enqueue the request so that we can be sure all requests are processed in
    ;; order.
    (push (cons dart-server--analysis-server-next-id
                (or callback #'dart-server--analysis-server-on-error-callback))
          dart-server--analysis-server-callbacks)

    (cond
     ((not dart-server--analysis-server)
      (message "Starting Dart analysis server.")
      (dart-server-start-analysis-server))
     ((not (process-live-p (dart-server--analysis-server-process dart-server--analysis-server)))
      (message "Dart analysis server crashed, restarting.")
      (dart-server-start-analysis-server)))

    (dart-server-info (concat "Sent: " request))
    (process-send-string (dart-server--analysis-server-process dart-server--analysis-server)
                         (concat request "\n"))))

(cl-defun dart-server--analysis-server-process-filter (das string)
  "Handle the event or method response from the dart analysis server.

The server DAS has STRING added to the buffer associated with it.
Method responses are paired according to their pending request and
the callback for that request is given the json decoded response."
  (-let [buf (dart-server--analysis-server-buffer das)]
    ;; The buffer may have been killed if the server was restarted
    (unless (buffer-live-p buf)
      (cl-return-from dart-server--analysis-server-process-filter))

    ;; We use a buffer here because emacs might call the filter before the
    ;; entire line has been written out. In this case we store the
    ;; unterminated line in a buffer to be read when the rest of the line is
    ;; output.
    (with-current-buffer buf
      (goto-char (point-max))
      (insert string)
      (-let [buf-lines (s-lines (buffer-string))]
        (delete-region (point-min) (point-max))
        (insert (-last-item buf-lines))

        (-let [messages
               (--filter (and it (not (string-empty-p it)))
                         (-butlast buf-lines))]
          (dolist (message messages)
            (dart-server-info (concat "Received: " message))
            (dart-server--analysis-server-handle-msg
             (-let [json-array-type 'list]
               (json-read-from-string message)))))))))

(defun dart-server--analysis-server-handle-msg (msg)
  "Handle the parsed MSG from the analysis server."
  (-if-let* ((raw-id (dart-server--get msg 'id))
             (id (string-to-number raw-id)))
      ;; This is a response to a request, so we should invoke a callback in
      ;; dart-server--analysis-server-callbacks.
      (-if-let (resp-closure (dart-server--get dart-server--analysis-server-callbacks id))
          (progn
            (setq dart-server--analysis-server-callbacks
                  (assq-delete-all id dart-server--analysis-server-callbacks))
            (funcall resp-closure msg))
        (-if-let (err (dart-server--get msg 'error))
            (dart-server--analysis-server-on-error-callback msg)
          (dart-server-info (format "No callback was associated with id %s" raw-id))))

    ;; This is a notification, so we should invoke callbacks in
    ;; dart-server--analysis-server-subscriptions.
    (-when-let* ((event (dart-server--get msg 'event))
                 (params (dart-server--get msg 'params))
                 (callbacks (dart-server--get dart-server--analysis-server-subscriptions event)))
      (dolist (callback callbacks)
        (-let [subscription (cons event callback)]
          (funcall callback params subscription))))))

(defun dart-server--analysis-server-subscribe (event callback)
  "Registers CALLBACK to be called for each EVENT of the given type.

CALLBACK should take two parameters: the event object and an
opaque subscription object that can be passed to
`dart-server--analysis-server-unsubscribe'. Returns the same opaque
subscription object."
  (-if-let (cell (assoc event dart-server--analysis-server-subscriptions))
      (nconc cell (list callback))
    (push (cons event (list callback)) dart-server--analysis-server-subscriptions))
  (cons event callback))

(defun dart-server--analysis-server-unsubscribe (subscription)
  "Unregisters the analysis server SUBSCRIPTION.

SUBSCRIPTION is an opaque object provided by
`dart-server--analysis-server-subscribe'."
  (-let [(event . callback) subscription]
    (delq callback (assoc event dart-server--analysis-server-subscriptions))))

;;;; Flycheck Error Reporting

(defun dart-server--flycheck-start (_ callback)
  "Run the CHECKER and report the errors to the CALLBACK."
  (dart-server-info (format "Checking syntax for %s" (current-buffer)))
  (dart-server--analysis-server-send
   "analysis.getErrors"
   `((file . ,(dart-server--normalize-path (buffer-file-name))))
   (-let [buffer (current-buffer)]
     (lambda (response)
       (dart-server--report-errors response buffer callback)))))

(when (fboundp 'flycheck-define-generic-checker)
 (flycheck-define-generic-checker
  'dart-server-analysis-server
  "Checks Dart source code for errors using Dart analysis server."
  :start 'dart-server--flycheck-start
  :modes '(dart-server)))

(defun dart-server--report-errors (response buffer callback)
  "Report the errors returned from the analysis server.

The errors contained in RESPONSE from Dart analysis server run on BUFFER are
reported to CALLBACK."
  (dart-server-info (format "Reporting to flycheck: %s" response))
  (-let [fly-errors (--map (dart-server--to-flycheck-err it buffer)
                           (dart-server--get response 'result 'errors))]
    (dart-server-info (format "Parsed errors: %s" fly-errors))
    (funcall callback 'finished fly-errors)))

(defun dart-server--to-flycheck-err (err buffer)
  "Create a flycheck error from a dart ERR in BUFFER."
  (when (fboundp 'flycheck-error-new)
    (flycheck-error-new
     :buffer buffer
     :checker 'dart-server-analysis-server
     :filename (dart-server--get err 'location 'file)
     :line (dart-server--get err 'location 'startLine)
     :column (dart-server--get err 'location 'startColumn)
     :message (dart-server--get err 'message)
     :level (dart-server--severity-to-level (dart-server--get err 'severity)))))

(defun dart-server--severity-to-level (severity)
  "Convert SEVERITY to a flycheck level."
  (cond
   ((string= severity "INFO") 'info)
   ((string= severity "WARNING") 'warning)
   ((string= severity "ERROR") 'error)))

;;;; Hover

(defun dart-server-show-hover (&optional show-in-buffer)
  "Displays hover information for the current point.

With a prefix argument, opens a new buffer rather than using the
minibuffer."
  (interactive "P")
  (-when-let (filename (dart-server--normalize-path (buffer-file-name)))
    (let ((show-in-buffer show-in-buffer)
          (buffer (current-buffer))
          (pos (point)))
      (dart-server--analysis-server-send
       "analysis.getHover"
       `(("file" . ,filename) ("offset" . ,pos))
       (lambda (response)
         (-when-let (hover (car (dart-server--get response 'result 'hovers)))
           (dart-server--json-let hover
               (offset
                length
                dartdoc
                (element-description elementDescription)
                (element-kind elementKind)
                (is-deprecated isDeprecated)
                parameter)
             (setq is-deprecated (not (eq is-deprecated :json-false)))

             ;; Briefly highlight the region that's being shown.
             (with-current-buffer buffer
               (dart-server--flash-highlight offset length))

             (with-temp-buffer
               (when is-deprecated
                 (insert (dart-server--face-string "DEPRECATED" 'font-lock-warning-face) ?\n))

               (when element-description
                 (insert (dart-server--highlight-description element-description)
                         (dart-server--face-string (concat " (" element-kind ")") 'italic))
                 (when (or dartdoc parameter) (insert ?\n)))
               (when parameter
                 (insert
                  (dart-server--highlight-description parameter)
                  (dart-server--face-string " (parameter type)" 'italic))
                 (when dartdoc) (insert ?\n))
               (when dartdoc
                 (when (or element-description parameter) (insert ?\n))
                 (insert (dart-server--highlight-dartdoc dartdoc (not show-in-buffer))))

               (let ((text (buffer-string)))
                 (if show-in-buffer
                     (with-current-buffer-window
                      "*Dart Analysis*" nil nil
                      (insert text)
                      (dart-server-popup-mode)

                      (setq dart-server--do-it-again-callback
                            (lambda ()
                              (save-excursion
                                (with-current-buffer buffer
                                  (goto-char pos)
                                  (dart-server-show-hover t))))))
                   (message "%s" text)))))))))))

(defconst dart-server--highlight-keyword-re
  (regexp-opt
   '("get" "set" "as" "abstract" "class" "extends" "implements" "enum" "typedef"
     "const" "covariant" "deferred" "factory" "final" "import" "library" "new"
     "operator" "part" "static" "async" "sync" "var")
   'words)
  "A regular expression that matches keywords.")

(defun dart-server--highlight-description (description)
  "Returns a highlighted copy of DESCRIPTION."
  (with-temp-buffer
    (insert description)
    (goto-char (point-min))

    (while (not (eq (point) (point-max)))
      (cond
       ;; A keyword.
       ((looking-at dart-server--highlight-keyword-re)
        (dart-server--fontify-excursion 'font-lock-keyword-face
          (goto-char (match-end 0))))

       ;; An identifier could be a function name or a type name.
       ((looking-at dart-server--identifier-re)
        (goto-char (match-end 0))
        (put-text-property
         (match-beginning 0) (point) 'face
         (if (dart-server--at-end-of-function-name-p) 'font-lock-function-name-face
           'font-lock-type-face))

        (cl-case (char-after)
          ;; Foo.bar()
          (?.
           (forward-char)
           (dart-server--fontify-excursion 'font-lock-function-name-face
             (dart-server--forward-identifier)))

          ;; Foo bar
          (?\s
           (forward-char)
           (dart-server--fontify-excursion 'font-lock-variable-name-face
             (dart-server--forward-identifier)))))

       ;; Anything else is punctuation that we ignore.
       (t (forward-char))))

    (buffer-string)))

(defun dart-server--at-end-of-function-name-p ()
  "Returns whether the point is at the end of a function name."
  (cl-case (char-after)
    (?\( t)
    (?<
     (and (looking-at (concat "\\(" dart-server--identifier-re "\\|[<>]\\)*"))
          (eq (char-after (match-end 0)) ?\()))))

(defun dart-server--highlight-dartdoc (dartdoc truncate)
  "Returns a higlighted copy of DARTDOC."
  (with-temp-buffer
    (insert dartdoc)

    ;; Cut off long dartdocs so that the full signature is always visible.
    (when truncate
      (forward-line 11)
      (delete-region (- (point) 1) (point-max)))

    (goto-char (point-min))

    (while (re-search-forward "\\[.*?\\]" nil t)
      (put-text-property (match-beginning 0) (match-end 0)
                         'face 'font-lock-reference-face))

    (buffer-string)))

;;;; Navigation

(defun dart-server-goto ()
  (interactive)
  (-when-let (filename (dart-server--normalize-path (buffer-file-name)))
    (dart-server--analysis-server-send
     "analysis.getNavigation"
     `(("file" . ,filename) ("offset" . ,(point)) ("length" . 0))
     (lambda (response)
       (-when-let (result (dart-server--get response 'result))
         (dart-server--json-let result (files targets regions)
           (-when-let (region (car regions))
             (let* ((target-index (car (dart-server--get region 'targets)))
                    (target (elt targets target-index))

                    (file-index (dart-server--get target 'fileIndex))
                    (offset (dart-server--get target 'offset))
                    (length (dart-server--get target 'length))

                    (file (elt files file-index)))
               (find-file file)
               (goto-char (+ 1 offset))
               (dart-server--flash-highlight offset length)))))))))

;;;; Search

(defun dart-server-find-refs (pos &optional include-potential)
  (interactive "dP")
  (-when-let (filename (dart-server--normalize-path (buffer-file-name)))
    (dart-server--analysis-server-send
     "search.findElementReferences"
     `(("file" . ,filename)
       ("offset" . ,pos)
       ("includePotential" . ,(or include-potential json-false)))
     (let ((buffer (current-buffer))
           (include-potential include-potential))
       (lambda (response)
         (-when-let (result (dart-server--get response 'result))
           (let ((name (dart-server--get result 'element 'name))
                 (location (dart-server--get result 'element 'location)))
             (dart-server--display-search-results
              (dart-server--get result 'id)
              (lambda ()
                (setq dart-server--do-it-again-callback
                      (lambda ()
                        (with-current-buffer buffer
                          (dart-server-find-refs pos include-potential))))

                (insert "References to ")
                (insert-button
                 name
                 'action (lambda (_) (dart-server--goto-location location)))
                (insert ":\n\n"))))))))))

(defun dart-server-find-member-decls (name)
  "Find member declarations named NAME."
  (interactive "sMember name: ")
  (dart-server--find-by-name
   "search.findMemberDeclarations" "name" name "Members named "))

(defun dart-server-find-member-refs (name)
  "Find member references named NAME."
  (interactive "sMember name: ")
  (dart-server--find-by-name
   "search.findMemberReferences" "name" name "References to "))

(defun dart-server-find-top-level-decls (name)
  "Find top-level declarations named NAME."
  (interactive "sDeclaration name: ")
  (dart-server--find-by-name
   "search.findTopLevelDeclarations" "pattern" name "Declarations matching "))

(defun dart-server--find-by-name (method argument name header)
  "A helper function for running an analysis server search for NAME.

Calls the given analysis server METHOD passing NAME to the given
ARGUMENT. Displays a header beginning with HEADER in the results."
  (dart-server--analysis-server-send
   method
   (list (cons argument name))
   (lambda (response)
     (-when-let (id (dart-server--get response 'result 'id))
       (dart-server--display-search-results
        id
        (lambda ()
          (setq dart-server--do-it-again-callback
                (lambda ()
                  (dart-server--find-by-name method argument name header)))
          (insert header name ":\n\n")))))))

(defun dart-server--display-search-results (search-id callback)
  "Displays search results with the given SEARCH-ID.

CALLBACK is called with no arguments in the search result buffer
to add a header and otherwise prepare it for displaying results."
  (let (buffer
        beginning-of-results
        (total-results 0))
    (with-current-buffer-window
     "*Dart Search*" nil nil
     (dart-server-popup-mode)
     (setq buffer (current-buffer))
     (funcall callback)
     (setq beginning-of-results (point))

     (dart-server--analysis-server-subscribe
      "search.results"
      (lambda (event subscription)
        (with-current-buffer buffer
          (dart-server--json-let event (id results (is-last isLast))
            (when (equal id search-id)
              (-let [buffer-read-only nil]
                (save-excursion
                  (goto-char (point-max))
                  (dolist (result results)
                    (let ((location (dart-server--get result 'location))
                          (path (dart-server--get result 'path))
                          (start (point)))
                      (dart-server--fontify-excursion '(compilation-info underline)
                        (when (cl-some
                               (lambda (element)
                                 (equal (dart-server--get element 'kind) "CONSTRUCTOR"))
                               path)
                          (insert "new "))

                        (insert
                         (->> path
                              (--remove (member (dart-server--get it 'kind)
                                                '("COMPILATION_UNIT" "FILE" "LIBRARY" "PARAMETER")))
                              (--map (dart-server--get it 'name))
                              (-remove 'string-empty-p)
                              nreverse
                              (s-join ".")))

                        (make-text-button
                         start (point)
                         'action (lambda (_) (dart-server--goto-location location))))

                      (dart-server--json-let location (file (line startLine) (column startColumn))
                        (insert " " file ":"
                                (dart-server--face-string line 'compilation-line-number) ":"
                                (dart-server--face-string column 'compilation-column-number) ?\n)))))

                (setq total-results (+ total-results (length results)))

                (when (eq is-last t)
                  (dart-server--analysis-server-unsubscribe subscription)
                  (save-excursion
                    (goto-char (point-max))
                    (insert "\nFound " (dart-server--face-string total-results 'bold) " results."))))))))))

    (select-window (get-buffer-window buffer))
    (goto-char beginning-of-results)))

(defun dart-server--goto-location (location)
  "Sends the user to the analysis server LOCATION."
  (dart-server--json-let location (file offset length)
    (find-file file)
    (goto-char (+ 1 offset))
    (dart-server--flash-highlight offset length)))

;;;; Auto-complete

(defcustom dart-server-expand-fallback (key-binding (kbd "M-/"))
  "The fallback command to use for `dart-server-expand'.

This is used when the analysis server isn't available. It
defaults to the command globally bound to M-/."
  :group 'dart-server
  :type 'function
  :package-version '(dart-server . "0.1.0"))

(defvar dart-server--last-expand-results nil
  "The results of the last call to `dart-server-expand'.")

(defvar dart-server--last-expand-beginning nil
  "The marker for the beginning of the text inserted by the last call to `dart-server-expand'.")

(defvar dart-server--last-expand-end nil
  "The marker for the end of the text inserted by the last call to `dart-server-expand'.")

(defvar dart-server--last-expand-index nil
  "The index into `dart-server--last-expand-results' for the last call to `dart-server-expand'.")

(defvar dart-server--last-expand-parameters-index nil
  "The index into for the last parameter suggestion from `dart-server-expand-parameters'.

This is an index into the paramaterNames and parameterTypes list
in the suggestion identified by `dart-server--last-expand-index', and
into `dart-server--last-expand-parameters-ranges'.")

(defvar dart-server--last-expand-parameters-ranges nil
  "The list of parameter ranges for the last call to `dart-server-expand-parameters'.

This is a list of pairs of markers. Each pair identifies the
beginning and end of a parameter in the parameter list generated
by `dart-server-expand-parameters'`.

Note that the end markers are placed one character after the
actual ending of the parameter. This ensures that if the marker
stayas in place when the parameter is overwritten.")

(defvar dart-server--last-expand-subscription nil
  "The last analysis server subscription from a call to `dart-server-expand'.")

(cl-defun dart-server-expand ()
  "Expand previous word using Dart's autocompletion."
  (interactive "*")
  (unless dart-server-enable-analysis-server
    (call-interactively dart-server-expand-fallback t)
    (cl-return-from dart-server-expand))

  (when (and (memq last-command '(dart-server-expand dart-server-expand-parameters))
             dart-server--last-expand-results)
    (cl-incf dart-server--last-expand-index)
    (when (>= dart-server--last-expand-index (length dart-server--last-expand-results))
      (setq dart-server--last-expand-index 0))
    (dart-server--use-expand-suggestion
     dart-server--last-expand-beginning
     dart-server--last-expand-end
     (elt dart-server--last-expand-results dart-server--last-expand-index))
    (cl-return-from dart-server-expand))

  (when dart-server--last-expand-subscription
    (dart-server--analysis-server-unsubscribe dart-server--last-expand-subscription))
  (setq dart-server--last-expand-results nil)
  (setq dart-server--last-expand-beginning nil)
  (setq dart-server--last-expand-end nil)
  (setq dart-server--last-expand-index nil)
  (setq dart-server--last-expand-subscription nil)

  (-when-let (filename (dart-server--normalize-path (buffer-file-name)))
    (dart-server--analysis-server-send
     "completion.getSuggestions"
     `(("file" . ,filename)
       ("offset" . ,(- (point) 1)))
     (let ((buffer (current-buffer))
           (first t))
       (lambda (response)
         (-when-let (completion-id (dart-server--get response 'result 'id))
           (dart-server--analysis-server-subscribe
            "completion.results"
            (setq dart-server--last-expand-subscription
                  (lambda (event subscription)
                    (dart-server--json-let event
                        (id results
                            (offset replacementOffset)
                            (length replacementLength)
                            (is-last isLast))
                      (when is-last (dart-server--analysis-server-unsubscribe subscription))

                      (when (equal id completion-id)
                        (with-current-buffer buffer
                          (dart-server--handle-completion-event results offset length first))
                        (setq first nil))))))))))))

(defun dart-server--handle-completion-event (results offset length first)
  "Handles a completion results event.

If FIRST is non-nil, this is the first completion event for this completion."
  ;; Get rid of any suggestions that don't match existing characters. The
  ;; analysis server provides extra suggestions to support search-as-you-type,
  ;; but we don't do that.
  (when (> length 0)
    (-let [text (buffer-substring (+ offset 1) (+ offset length 1))]
      (setq results
            (--remove (string-prefix-p text (dart-server--get it 'completion) t)
                      results))))

  (when (> (length results) 0)
    ;; Fill the first result so the first call does something. Just save later
    ;; results for future calls.
    (when first
      (setq dart-server--last-expand-index 0)
      (setq dart-server--last-expand-beginning (copy-marker (+ offset 1)))
      (dart-server--use-expand-suggestion (+ offset 1) (+ offset length 1) (car results)))

    (setq first nil)
    (setq dart-server--last-expand-results results)))

(defun dart-server--use-expand-suggestion (beginning end suggestion)
  "Inserts SUGGESTION between BEGINNING and END."
  (dart-server--json-let suggestion
      (completion element
       (selection-offset selectionOffset)
       (is-deprecated isDeprecated)
       (doc-summary docSummary))
    (goto-char beginning)
    (delete-region beginning end)
    (save-excursion
      (insert completion)
      (setq dart-server--last-expand-end (point-marker)))
    (forward-char selection-offset)

    (with-temp-buffer
      (when (eq is-deprecated t)
        (insert (dart-server--face-string "DEPRECATED" 'font-lock-warning-face) ?\n))

      (insert (dart-server--highlight-description (dart-server--description-of-element element)))
      (when doc-summary
        (insert ?\n ?\n (dart-server--highlight-dartdoc doc-summary nil)))

      (message "%s" (buffer-string)))))

(defun dart-server--description-of-element (element)
  "Returns a textual description of an analysis server ELEMENT."
  (dart-server--json-let element
      (kind name parameters
       (return-type returnType)
       (type-parameters typeParameters))
    (with-temp-buffer
      (if (equal kind "CONSTRUCTOR")
          (progn
            (insert "new " return-type)
            (unless (string-empty-p name)
              (insert "." name))
            (insert parameters)
            (insert " → " return-type))

        (cl-case kind
          ("GETTER" (insert "get "))
          ("SETTER" (insert "set ")))
        (insert name)
        (when type-parameters (insert type-parameters))
        (when parameters (insert parameters))
        (when return-type (insert " → " return-type)))
      (buffer-string))))

(cl-defun dart-server-expand-parameters ()
  "Adds parameters to the currently-selected `dart-server-expand' completion.

This will select the first parameter, if one exists."
  (interactive "*")
  (cond
   ((and (eq last-command 'dart-server-expand)
         dart-server--last-expand-results)

    ;; If this is called directly after `dart-server-expand', create the parameter list
    ;; and highlight the first entry.
    (setq dart-server--last-expand-parameters-index 0)
    (dart-server--json-let (elt dart-server--last-expand-results dart-server--last-expand-index)
        ((parameter-names parameterNames)
         (argument-string defaultArgumentListString)
         (argument-ranges defaultArgumentListTextRanges))
      (unless parameter-names (cl-return-from dart-server-expand-parameters))

      (unless argument-string
        (insert ?\()
        (save-excursion
          (insert ?\))
          (setq dart-server--last-expand-end (point-marker)))
        (cl-return-from dart-server-expand-parameters))

      (save-excursion
        (insert ?\( argument-string ?\))
        (setq dart-server--last-expand-end (point-marker)))

      (setq dart-server--last-expand-parameters-ranges
            (cl-loop for i below (length argument-ranges) by 2
                  collect (let* ((beginning (+ (point) 1 (elt argument-ranges i)))
                                 (end (+ beginning (elt argument-ranges (+ i 1)) 1)))
                            (list (copy-marker beginning) (copy-marker end)))))

      (dart-server--expand-select-parameter)))

   ((and (< dart-server--last-expand-beginning (point) dart-server--last-expand-end)
         dart-server--last-expand-parameters-index)

    ;; If this is called when the point is within the text generated by the
    ;; last `dart-server-expand-parameters' call, move to the next parameter in the
    ;; list.
    (cl-incf dart-server--last-expand-parameters-index)
    (when (>= dart-server--last-expand-parameters-index (length dart-server--last-expand-parameters-ranges))
      (setq dart-server--last-expand-parameters-index 0))

    (dart-server--expand-select-parameter))))

(defun dart-server--expand-select-parameter ()
  "Selects the parameter indicated by expansion variables."
  (-let [(beginning end) (elt dart-server--last-expand-parameters-ranges
                              dart-server--last-expand-parameters-index)]
    (dart-server--delsel-range beginning (- end 1)))

  (dart-server--json-let (elt dart-server--last-expand-results dart-server--last-expand-index)
      ((parameter-names parameterNames)
       (parameter-types parameterTypes))
    (message "%s" (dart-server--highlight-description
                   (concat (elt parameter-types dart-server--last-expand-parameters-index) " "
                           (elt parameter-names dart-server--last-expand-parameters-index))))))

(defun dart-server--delsel-range (beginning end)
  "Highlights the range between BEGINNING and END and enables `delete-selection-mode' temporarily."
  (setq transient-mark-mode nil)
  (goto-char beginning)
  (push-mark nil t)
  (goto-char end)

  ;; Run this in a timer because `activate-mark' doesn't seem to work
  ;; directly, and because we don't want to disable `delete-selection-mode'
  ;; when `post-command-hook' is invoked after the calling command finishes.
  (run-at-time
   "0 sec" nil
   (lambda ()
     (activate-mark)

     ;; Overwrite the current selection, but don't globally enable
     ;; delete-selection-mode.
     (unless delete-selection-mode
       (delete-selection-mode 1)
       (add-hook 'post-command-hook #'dart-server--disable-delsel t t)))))

(defun dart-server--disable-delsel ()
  "Disables `delete-selection-mode' and deactivates the mark.

Also removes this function from `post-command-hook'."
  (deactivate-mark)
  (delete-selection-mode 0)
  (remove-hook 'post-command-hook 'dart-server--disable-delsel t))


;;; Popup Mode

(define-derived-mode dart-server-popup-mode fundamental-mode "DartPopup"
  "Major mode for popups."
  :mode 'dart-server-popup
  (use-local-map dart-server-popup-mode-map))

(put 'dart-server-popup-mode 'mode-class 'special)

(defvar dart-server-popup-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map help-mode-map)
    (define-key map (kbd "g") 'dart-server-do-it-again)
    ;; Unbind help-specific keys.
    (define-key map (kbd "RET") nil)
    (define-key map (kbd "l") nil)
    (define-key map (kbd "r") nil)
    (define-key map (kbd "<XF86Back>") nil)
    (define-key map (kbd "<XF86Forward>") nil)
    (define-key map (kbd "<mouse-2>") nil)
    (define-key map (kbd "C-c C-b") nil)
    (define-key map (kbd "C-c C-c") nil)
    (define-key map (kbd "C-c C-f") nil)
    map)
  "Keymap used in Dart popup buffers.")

(defun dart-server-do-it-again ()
  "Re-runs the logic that generated the current buffer."
  (interactive)
  (when dart-server--do-it-again-callback
    (funcall dart-server--do-it-again-callback)))


;;; Formatting

(defcustom dart-server-formatter-command-override nil
  "The command for running the Dart formatter.

Don't read this variable; call `dart-server-formatter-command' instead."
  :type 'string
  :group 'dart-server
  :package-version '(dart-server . "0.1.0"))

(defcustom dart-server-formatter-line-length 80
  "The line length to use when running the Dart formatter."
  :type 'integer
  :group 'dart-server
  :package-version '(dart-server . "0.1.0"))

(defcustom dart-server-format-on-save nil
  "Whether to run the Dart formatter before saving."
  :type 'boolean
  :group 'dart-server
  :package-version '(dart-server . "0.1.0"))

(defcustom dart-server-formatter-show-errors 'buffer
  "Where to display Dart formatter error output.
It can either be displayed in its own buffer, in the echo area, or not at all.

Please note that Emacs outputs to the echo area when writing
files and will overwrite the formatter's echo output if used from
inside a `before-save-hook'."
  :type '(choice
          (const :tag "Own buffer" buffer)
          (const :tag "Echo area" echo)
          (const :tag "None" nil))
  :group 'dart-server)

(defun dart-server-formatter-command ()
  "The command for running the Dart formatter.

This can be customized by setting `dart-server-formatter-command-override'."
  (or dart-server-formatter-command-override
      (when dart-server-sdk-path
        (concat dart-server-sdk-path
                (file-name-as-directory "bin")
                "dartfmt"))))

(defvar dart-server--formatter-compilation-regexp
  '("^line \\([0-9]+\\), column \\([0-9]+\\) of \\([^ \n]+\\):" 3 1 2)
  "Regular expresion to match errors in the formatter's output.
See `compilation-error-regexp-alist' for help on their format.")

(add-to-list 'compilation-error-regexp-alist-alist
             (cons 'dart-server-formatter dart-server--formatter-compilation-regexp))
(add-to-list 'compilation-error-regexp-alist 'dart-server-formatter)

(cl-defun dart-server-format ()
  "Format the current buffer using the Dart formatter.

By default, this uses the formatter in `dart-server-sdk-path'. However,
this can be overridden by customizing
`dart-server-formatter-command-override'."
  (interactive)
  (let* ((file (make-temp-file "format" nil ".dart"))
         (patch-buffer (get-buffer-create "*Dart formatter patch*"))
         (error-buffer (when dart-server-formatter-show-errors
                         (get-buffer-create "*Dart formatter errors*")))
         (coding-system-for-read 'utf-8)
         (coding-system-for-write 'utf-8)
         (args `("--line-length" ,(number-to-string dart-server-formatter-line-length)
                 "--overwrite" ,file)))
    (unwind-protect
        (save-restriction
          (widen)

          (when error-buffer
            (with-current-buffer error-buffer
              (setq buffer-read-only nil)
              (erase-buffer)))

          (write-region nil nil file nil 'no-message)
          (dart-server-info (format "%s %s" (dart-server-formatter-command) args))

          (unless (zerop (apply #'call-process (dart-server-formatter-command) nil error-buffer nil args))
            (message "Formatting failed")
            (when error-buffer
              (dart-server--formatter-show-errors error-buffer file (buffer-file-name)))
            (cl-return-from dart-server-format))

          ;; Apply the format as a diff so that only portions of the buffer that
          ;; actually change are marked as modified.
          (if (zerop (call-process-region (point-min) (point-max)
                                          "diff" nil patch-buffer nil "--rcs" "-" file))
              (message "Buffer is already formatted")
            (dart-server--apply-rcs-patch patch-buffer)
            (message "Formatted buffer"))
          (when error-buffer (dart-server--kill-buffer-and-window error-buffer)))
      (kill-buffer patch-buffer)
      (delete-file file))))

(defun dart-server--do-format-on-save ()
  "Format the buffer if `dart-server-format-on-save' is non-nil."
  (when dart-server-format-on-save
    (dart-server-format)))

(defun dart-server--apply-rcs-patch (patch-buffer)
  "Apply an RCS diff from PATCH-BUFFER to the current buffer."
  (let ((target-buffer (current-buffer))
        ;; The relative offset between line numbers in the buffer and in patch.
        ;;
        ;; Line numbers in the patch are based on the source file, so we have to
        ;; keep an offset when making changes to the buffer.
        ;;
        ;; Appending lines decrements the offset (possibly making it negative),
        ;; deleting lines increments it. This order simplifies the forward-line
        ;; invocations.
        (line-offset 0))
    (save-excursion
      (with-current-buffer patch-buffer
        (goto-char (point-min))
        (while (not (eobp))
          (unless (looking-at "^\\([ad]\\)\\([0-9]+\\) \\([0-9]+\\)")
            (error "Invalid RCS patch or internal error in dart-server--apply-rcs-patch"))

          (forward-line)
          (let ((action (match-string 1))
                (from (string-to-number (match-string 2)))
                (len  (string-to-number (match-string 3))))
            (cond
             ((equal action "a")
              (-let [start (point)]
                (forward-line len)
                (-let [text (buffer-substring start (point))]
                  (with-current-buffer target-buffer
                    (cl-decf line-offset len)
                    (goto-char (point-min))
                    (forward-line (- from len line-offset))
                    (insert text)))))

             ((equal action "d")
              (with-current-buffer target-buffer
                (goto-char (point-min))
                (forward-line (- from line-offset 1))
                (cl-incf line-offset len)
                (dart-server--delete-whole-line len)))

             (t
              (error "Invalid RCS patch or internal error in dart-server--apply-rcs-patch")))))))))

(defun dart-server--formatter-show-errors (error-buffer temp-file real-file)
  "Display formatter errors in `error-buffer'.
This replaces references to TEMP-FILE with REAL-FILE."
  (with-current-buffer error-buffer
    (-let [echo (eq dart-server-formatter-show-errors 'echo)]
      (goto-char (point-min))
      (-let [regexp (concat "\\(" (regexp-quote temp-file) "\\):")]
        (while (search-forward-regexp regexp nil t)
          (replace-match (file-name-nondirectory real-file) t t nil 1)))

      (if echo
          (progn
            (message "%s" (buffer-string))
            (dart-server--kill-buffer-and-window error-buffer))
        (compilation-mode)
        (temp-buffer-window-show error-buffer)
        (select-window (get-buffer-window error-buffer))))))


;;; Initialization

;;;###autoload
(define-minor-mode dart-server nil nil nil nil
  (if dart-server
      (add-hook 'before-save-hook #'dart-server--do-format-on-save nil t)
    (remove-hook 'before-save-hook #'dart-server--do-format-on-save t)))

(provide 'dart-server)

;;; dart-server.el ends here
