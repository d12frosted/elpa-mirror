;;; battle-haxe.el --- A Haxe development system, with code completion and more -*- lexical-binding: t -*-

;; Copyright (C) 2019-2019  Alon Tzarafi

;; Author: Alon Tzarafi  <alontzarafi@gmail.com>
;; URL: https://github.com/AlonTzarafi/battle-haxe
;; Package-Version: 20210219.354
;; Package-Commit: 2f32c81dcecfc68fd410cb9d2aca303d6e3028c7
;; Version: 1.0
;; Package-Requires: ((emacs "25") (company "0.9.9") (helm "3.0") (async "1.9.3") (cl-lib "0.5") (dash "2.18.0") (s "1.10.0") (f "0.19.0"))
;; Keywords: programming, languages, completion

;; battle-haxe is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; battle-haxe is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with battle-haxe.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package offers a development system for the Haxe programming language.
;; Haxe code completion is activated using the `company-mode' package.
;; Code navigation options like "go to definition" and "find all references" are available.
;; There is support for `eldoc' to show the type of current variable, the arguments of current function.
;; All of those features are triggered in `battle-haxe-mode' which also spawns a Haxe server to perform them.
;; The tools rely on the Haxe "compiler services" feature ( https://haxe.org/manual/cr-completion-overview.html ).
;; The main quirk is that the system has to force automatic saving of the Haxe code file buffer as you edit it.
;; If this is a problem for you, don't use the package.
;; See the project home page for more information.

;;; Code:

;; For completion
(require 'company)
;; For find references
(require 'helm)
;; For non-blocking operations
(require 'async)
;; For helper functions
;; -- (built in)
(require 'cl-lib)
(require 'subr-x)
(require 'xml)
;; -- (downloaded)
(require 'dash)
(require 's)
(require 'f)

;; Optional dependency for function call snippets
(declare-function yas-expand-snippet "ext:yasnippet.el")


(defvar battle-haxe-yasnippet-completion-expansion nil
  "When non-nil, battle-haxe will expand completions using yasnippet when available.")

(defvar battle-haxe-immediate-completion t
  "When non-nil, battle-haxe can immediately trigger code-completion on its own.
Otherwise, completion only ever starts as configured in `company-mode' settings.
Example cases for immediate completions (the '|' symbol is the current point):
new |
import |
myObject.|
var x:|")

(defvar battle-haxe-disallow-other-backends-in-strings-and-comments nil
  "Allow other `company-mode' backends in strings and comments.")

(defvar battle-haxe-cwd nil
  "Current working directory: Current project folder to pass to Haxe compiler.")

(defvar battle-haxe-cached-hxml-args ""
  "Holds the Haxe compiler parameters, extracted from the '.hxml' file.
They are sent to the compiler to call compiler services for this project.")

(defvar battle-haxe-compiler-port 6000
  "The port that the Haxe server and client communicate with.")

(defvar battle-haxe-server-process nil
  "References a currently running Haxe server process if any.")

(defvar-local battle-haxe-cached-completion-context nil
  "Buffer-local saved result of (battle-haxe-get-line-and-hash-other-lines).
Used to determine if a new call to Haxe compiler services is needed.")

(defvar-local battle-haxe-cached-completion-response nil
  "Buffer-local saved copy of last completion server response.")

(defvar-local battle-haxe-current-completions-node-processor #'battle-haxe-type-completion-general-node-processor
  "Buffer-local current node-processor function.")

(defconst battle-haxe-symbol-chars "[[:alnum:]?_]"
  "Characters allowed in Haxe symbol names.")

(defconst battle-haxe-non-symbol-chars "[^[:alnum:]?_]"
  "Characters disallowed in Haxe symbol names.")

(defvar battle-haxe-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap used for symbol `battle-haxe-mode'.")

;;;###autoload
(define-minor-mode battle-haxe-mode
  "Haxe completion, and other coding tools, using Haxe's compiler services."
  :lighter " haxe"
  :global nil
  :keymap battle-haxe-mode-map
  ;;Init the minor mode
  (progn
    ;;Set up the Haxe compiler services for `company' in the buffer.
    ;; This starts a global server. If you want to force restart, or start in another project, run ‘battle-haxe-start-server’.
    (unless (battle-haxe-is-server-running)
      (battle-haxe-start-server))
    
    ;; Setup eldoc for Haxe
    (set (make-local-variable 'eldoc-documentation-function)
         #'battle-haxe-eldoc-function)))

;;;###autoload
(defun battle-haxe-company-backend (command &optional arg &rest ignored)
  "'company-mode' completion back-end using Haxe compiler services. Backend is called using COMMAND, ARG, and the rest is IGNORED."
  (interactive '(interactive))
  
  (cl-case command
    (interactive (company-begin-backend #'battle-haxe-company-backend))
    
    (prefix
     (if (and (bound-and-true-p battle-haxe-mode)
              (not (company-in-string-or-comment)))
         (let ((prefix (battle-haxe-get-company-prefix)))
           (or (when (looking-back
                      (concat
                       ;; Only when these conditions are found, immediate compilation can trigger.
                       "\\(?:"battle-haxe-non-symbol-chars"\\(using \\|import \\|new \\)""\\|[.:<]\\)")
                      (- (point) (line-beginning-position)))
                 (when battle-haxe-immediate-completion
                   (cons prefix t)))
               prefix))
       battle-haxe-disallow-other-backends-in-strings-and-comments))
    
    (candidates (battle-haxe-candidates arg))
    
    (no-cache t)
    
    (sorted t)
    
    (annotation (battle-haxe-annotation arg))
    
    (meta (battle-haxe-get-prop arg 'meta))
    
    (require-match 'never)
    
    (doc-buffer (battle-haxe-docstring arg))
    
    (match (battle-haxe-get-prop arg 'match))
    
    (post-completion
     ;; Clean up the old inserted text
     (backward-char (length arg))
     (delete-char (- (- (point) (line-beginning-position))
                     (length (alist-get 'line-str battle-haxe-cached-completion-context))))
     (forward-char (length arg))
     ;; After "new MyClass()" completion also auto-import it
     (battle-haxe-ensure-object-at-point-is-imported (battle-haxe-get-prop arg 'ensure-import))
     ;; Finalize inserted text
     (battle-haxe-perform-result-expansion arg))))

(defun battle-haxe-get-company-prefix ()
  "Get the prefix for a company completion.
The variable `battle-haxe-current-completions-node-processor' is
set according to the determined type of the prefix."
  (let ((prefix-text))
    (setq battle-haxe-current-completions-node-processor
          (cond
           ;; inserting a member?
           ((setq prefix-text (battle-haxe-get-prefix-member))
            #'battle-haxe-member-completion-xml-node-processor)
           ;; inserting a type?
           ((setq prefix-text (battle-haxe-get-prefix-type))
            #'battle-haxe-type-completion-xml-node-processor)
           ;; inserting something more general?
           ((setq prefix-text (battle-haxe-get-prefix-any-symbol))
            #'battle-haxe-type-completion-general-node-processor)))
    (or prefix-text
        ;; This disallows other company backends to run on the code:
        t)))

(defun battle-haxe-candidates (prefix)
  "The main company candidates function.
Decides when to use last cached candidates data.
And when to request from server again.
Sends PREFIX to the function `battle-haxe-compute-candidates'"
  (when buffer-file-name
    (let* ((line-num (alist-get 'line-num battle-haxe-cached-completion-context))
           (line-str (alist-get 'line-str battle-haxe-cached-completion-context))
           (rest-hash (alist-get 'rest-hash battle-haxe-cached-completion-context))
           (time-taken (alist-get 'time-taken battle-haxe-cached-completion-context))
           (use-cached (and
                        ;; has valid time in the last 30 seconds
                        time-taken
                        (> 30 (- (float-time) time-taken))
                        ;; same line num
                        (= line-num (line-number-at-pos))
                        (let ((current (battle-haxe-get-line-and-hash-other-lines)))
                          (and
                           ;; same hash
                           (string= rest-hash (alist-get 'rest-hash current))
                           ;; ensure the saved line is in scope
                           (>= (- (point) (line-beginning-position)) (length line-str))
                           
                           ;;---OLD:
                           ;; ;; same initial part of line
                           ;; (eq 0 (cl-search line-str (alist-get 'line-str current)))
                           
                           ;;---NEW:
                           ;; same exact line
                           (string=  line-str (alist-get 'line-str current)))))))
      (if use-cached
          ;; Approve a previous cached data
          (unless (alist-get 'approved battle-haxe-cached-completion-context)
            (add-to-list 'battle-haxe-cached-completion-context '(approved . t)))
        ;; Sets the context for next time.
        ;; Note that later on the 'line-str will be updated and cropped to the beginning of the inserted member.
        (setq battle-haxe-cached-completion-context (battle-haxe-get-line-and-hash-other-lines))))
    
    (battle-haxe-compute-candidates prefix)))

(defun battle-haxe-compute-candidates (prefix)
  "Return the company candidates for use by the command `company-complete'.
Reads completion type from PREFIX and tries to complete based on it.
Send nil if nothing to complete."
  (when (stringp prefix)
    (let* ((inserted-member-begin (- (point) (length prefix)))
           (haxe-point (battle-haxe-get-haxe-point inserted-member-begin)))
      
      ;; Final test of approval - same completion point
      (when (alist-get 'approved battle-haxe-cached-completion-context)
        (let ((completion-point-char (- inserted-member-begin (line-beginning-position)))
              (line-str-length (length (alist-get 'line-str battle-haxe-cached-completion-context))))
          (unless (= completion-point-char line-str-length)
            ;; Unapprove
            (setq battle-haxe-cached-completion-context nil))))
      
      ;; Update the cache if any, to match only until completion point
      (when battle-haxe-cached-completion-context
        (add-to-list 'battle-haxe-cached-completion-context
                     (cons 'line-str
                           (buffer-substring-no-properties
                            (line-beginning-position) inserted-member-begin))))
      
      ;; Let Haxe compiler read this file before proceeding to call the server
      (unless (alist-get 'approved battle-haxe-cached-completion-context)
        (battle-haxe-save-buffer-silently))
      
      (battle-haxe-company-candidates
       haxe-point
       ""
       prefix))))

(defun battle-haxe-company-candidates (haxe-point haxe-compiler-service inserted-text)
  "Return a company completion with the given parameters.
HAXE-POINT is the haxe-point.
HAXE-COMPILER-SERVICE is haxe compiler services mode (example: '@type').
It can also be an empty string and haxe will still provide contextual
completions in the provided point.
INSERTED-TEXT is sent to the parser to help match some candidates.
If a cache is valid, return it right away, else return async candidates."
  (let ((process-result
         (lambda (xml-str)
           ;; When it will get server results:
           (-remove #'string-empty-p
                    (battle-haxe-parse-completions-from-xml xml-str inserted-text))))
        (use-cached (alist-get 'approved battle-haxe-cached-completion-context)))
    (if use-cached
        (funcall process-result battle-haxe-cached-completion-response)
      (cons :async (lambda (callback)
                     (battle-haxe-get-completions
                      haxe-point
                      haxe-compiler-service
                      (lambda (xml-str)
                        (let ((candidates (funcall process-result xml-str)))
                          (funcall callback candidates)))))))))

(defun battle-haxe-get-completions (haxe-point haxe-compiler-service callback)
  "Call a compiler services completion command and pass result to CALLBACK.
The command is called in HAXE-POINT using the mode in HAXE-COMPILER-SERVICE."
  (let* ((command-to-call (battle-haxe-make-command-string haxe-point haxe-compiler-service))
         (command-result (shell-command-to-string
                          command-to-call)))
    ;; When done:
    (setq battle-haxe-cached-completion-response command-result)
    (funcall callback command-result)))

(defun battle-haxe-get-haxe-point (&optional target-point filename)
  "Return a haxe-point to be passed to Haxe's --display option.
A so called haxe-point looks like this: path-to-file/Haxe-file.hx@bytepos
The result is based either on FILENAME and TARGET-POINT,
or, if they are nil, on the current buffer file and point."
  (let ((target-point (or target-point (point))))
    (concat
     (or filename buffer-file-name)
     "@"
     (number-to-string
      (battle-haxe-get-byte-pos (or target-point (point)))))))

(defun battle-haxe-get-byte-pos (target-point)
  "Take the TARGET-POINT in the current buffer and return the byte position.
Haxe compiler services damands only byte position so some quirks must be handled."
  (let ((was-multibyte enable-multibyte-characters)
        (bytepos 0))
    (set-buffer-multibyte nil)
    (setq bytepos
          (-
           (bufferpos-to-filepos target-point 'exact)
           (if (battle-haxe-file-has-BOM)
               2
             0)))
    (set-buffer-multibyte was-multibyte)
    bytepos))

(defun battle-haxe-file-has-BOM ()
  "Detect if current file has a byte order mark (BOM) at the beginning."
  (let ((filename buffer-file-name))
    (when filename
      (with-temp-buffer
        (insert-file-contents-literally filename)
        (let ((bom (decode-coding-string (buffer-substring-no-properties 1 4) 'utf-8)))
          (string= bom (string ?\uFEFF)))))))

(defun battle-haxe-ensure-object-at-point-is-imported (full-class-name)
  "Maybe add an import statement in the current buffer to the FULL-CLASS-NAME.
Only adds the import if the class/type is not already available to the file.
When calling, the point must be on a class reference to that class.
The Haxe compiler services is then called to indentify the class."
  
  (when full-class-name
    (battle-haxe-save-buffer-silently)
    
    (let* ((is-imported
            (save-excursion
              (goto-char (point-min))
              (re-search-forward (concat "^[ \t]*import[ \t]+" full-class-name "[ \t]*;") nil t)))
           (needs-to-be-imported
            (and
             ;; not imported directly:
             (not is-imported)
             ;; and also not found by compiler services:
             (battle-haxe-is-invalid-pos-string (car (battle-haxe-position-query (battle-haxe-get-haxe-point)))))))
      (when needs-to-be-imported
        (save-excursion
          (goto-char 0)
          (while (re-search-forward "package[ \t[:alnum:]];" nil t))
          (while (re-search-forward "import[ \t]+.+[ \t]*;" nil t))
          (beginning-of-line)
          (unless (equal (point-at-bol) (point-at-eol))
            (forward-line))
          (open-line 1)
          (insert (concat "import " full-class-name ";"))
          (message (concat "Class added to import list: " full-class-name)))))))

(defun battle-haxe-get-line-and-hash-other-lines ()
  "Return an alist with 3 elements used to detect any change in buffer:
'line-num: The number of current line.
'line-str: The string of current line - up until the cursor.
'rest-hash: A Hash computed from every line except the current one.
'time-taken: The time at which this data was collected."
  (list
   (cons 'line-num
         (line-number-at-pos))
   (cons 'line-str
         (buffer-substring-no-properties
          (line-beginning-position) (point)))
   (cons 'rest-hash
         (concat (sha1 (buffer-substring-no-properties
                        1 (line-beginning-position)))
                 (sha1 (buffer-substring-no-properties
                        (line-end-position) (point-max)))))
   (cons 'time-taken
         (float-time))))

(defun battle-haxe-resolve-hxml-candidates ()
  "Resolves a list of .hxml file candidates and directories to be used.
for starting a server based on the current buffer file's directory"
  (let ((dir (file-name-directory (or buffer-file-name "")))
        (candidates nil))
    (while (and
            dir
            (not (f-root-p dir))
            (not (file-remote-p dir)))
      (setq candidates
            (append
             candidates
             (f-files dir (lambda (filename)
                            (string-match-p "\\.hxml$" filename)))))
      (setq dir (f-parent dir)))
    
    (setq candidates (reverse candidates))
    
    ;; Future idea: use projectile project root as a primary candidate (only if have projectile loaded)
    
    candidates))

(defun battle-haxe-read-lines (file-path)
  "Return a list of the lines of a file at FILE-PATH."
  (with-temp-buffer
    (insert-file-contents file-path)
    (split-string (buffer-string) "\n" t)))

(defun battle-haxe-additional-compiler-flags ()
  "Return the cached hxml args plus an argument specifying the current working directory."
  (append
   (list
    "--cwd" battle-haxe-cwd)
   (-map
    (lambda (str) (concat "\"" str "\""))
    battle-haxe-cached-hxml-args)))

(defun battle-haxe-make-command-string (haxe-point compiler-services-mode)
  "Construct a shell command for calling compiler services on the Haxe server.
The HAXE-POINT specifies the position of the operation.
the COMPILER-SERVICES-MODE is appended to the haxe-point in the --display argument."
  (s-join
   " "
   (append
    (list
     "haxe"
     "--connect"
     (number-to-string battle-haxe-compiler-port))
    (battle-haxe-additional-compiler-flags)
    (list
     "--display"
     (concat
      haxe-point "@" compiler-services-mode)))))

(defun battle-haxe-get-xml-root (xml-string)
  "Get a root XML object from the provided XML-STRING.
If XML-STRING is not a valid XML it will fail to parse and will return nil.
Haxe returns a non-XML only when there's too severe errors,
too many for the compiler services to function."
  (when (stringp xml-string)
    (with-temp-buffer
      (progn
        (insert xml-string)
        (ignore-errors
          (xml-parse-region (point-min) (point-max)))))))

(defun battle-haxe-parse-completions-from-xml (xml-str inserted-text)
  "Parse the XML-STR string returned from the Haxe server.
Send all nodes to the current node processor to add meta-data.
Also send INSERTED-TEXT to the node processor to help match candidtes.
Sort the candidates according to those matches.
The result is the full list of processed completion candidates."
  (let* ((xml-root (battle-haxe-get-xml-root xml-str))
         (is-error-response (not xml-root))
         (completion-xml-nodes (xml-get-children (car xml-root) 'i))
         (calc-completion-xml-node
          (lambda (xml-node)
            (funcall battle-haxe-current-completions-node-processor xml-node inserted-text)))
         (completions-processed
          (mapcar calc-completion-xml-node completion-xml-nodes))
         (completions-filtered
          (-filter #'stringp completions-processed))
         (completions-sorted (sort
                              completions-filtered
                              (lambda (a b)
                                ;; Mostly sort by match length,
                                ;; but give priority to matches that match at an earlier point
                                (>
                                 (- (battle-haxe-get-prop a 'matchlen 0)
                                    (* 0.001 (battle-haxe-get-prop a 'matchbegin 0)))
                                 (- (battle-haxe-get-prop b 'matchlen 0)
                                    (* 0.001 (battle-haxe-get-prop b 'matchbegin 0)))))))
         (completions completions-sorted))
    (if is-error-response
        (progn
          (run-at-time
           "100 millisecond"
           nil
           (lambda ()
             (message "Haxe completion failed. Haxe returned:\n%s" xml-str)))
          ;; Notify user but don't error:
          nil)
      completions)))

(defun battle-haxe-member-completion-xml-node-processor (completion-xml-node inserted-text)
  "The node processor for performing member completion.
Take COMPLETION-XML-NODE,
an individual result of compiler services member completion.
Parse it and return a string of the candidate name,
plus some meta-data as text properties.
The completion candidate is matched to INSERTED-TEXT."
  (let* ((competion-attrs (xml-node-attributes completion-xml-node))
         (kind (cdr (assoc 'k competion-attrs)))
         (type (or (car (cdr (cdr (nth 0 (xml-get-children completion-xml-node 't)))))
                   ""))

         (parts (battle-haxe-detect-signature-parts type))
         
         (name (battle-haxe-set-string-face
                'apropos-function-button
                (concat
                 (cdr (assoc 'n competion-attrs))
                 (alist-get 'args parts))))
         
         ;; (error-check (unless (stringp name)
         ;;                (error "Error. Couldn't parse completion node's name")))
         
         (docstring (car (cdr (cdr (nth 0 (xml-get-children completion-xml-node 'd))))))
         (output
          name))
    (battle-haxe-completion-node-common-props output kind type docstring inserted-text)
    output))

(defun battle-haxe-type-completion-xml-node-processor (completion-xml-node inserted-text)
  "The node processor for performing type completion.
Take COMPLETION-XML-NODE,
an individual result of compiler services member completion.
Parse it and return a string of the candidate name,
plus some meta-data as text properties.
The completion candidate is matched to INSERTED-TEXT."
  (let* ((competion-attrs (xml-node-attributes completion-xml-node))
         (name (car (xml-node-children
                     completion-xml-node)))
         (type (cdr (assoc 'p competion-attrs)))
         (ensure-import type)             ;Used later for auto-import
         (output name))
    (battle-haxe-set-prop output 'ensure-import ensure-import)
    (battle-haxe-completion-node-common-props output "" type "" inserted-text)
    output))

(defun battle-haxe-type-completion-general-node-processor (completion-xml-node inserted-text)
  "The node processor for performing general completion.
Take COMPLETION-XML-NODE,
an individual result of compiler services member completion.
Parse it and return a string of the candidate name,
plus some meta-data as text properties.
The completion candidate is matched to INSERTED-TEXT."
  (when-let*
      ((competion-attrs (xml-node-attributes completion-xml-node))
       (name (car (xml-node-children
                   completion-xml-node)))
       (kind (cdr (assoc 'k competion-attrs)))
       
       ;; Save type-completions only for explicit type-completion processor.
       ;; Here only allow local/member/literal completions:
       (is-valid (or (string= kind "local")
                     (string= kind "member")
                     (string= kind "static")
                     (string= kind "literal")))
       ;; Haxe literals are for example "true" "false"
       
       (type (or (cdr (assoc 't competion-attrs))
                 ;; Make having a type attribute optional (for the special case of literals)
                 ""))
       (output name))
    (battle-haxe-completion-node-common-props output kind type "" inserted-text)
    output))

(defun battle-haxe-completion-node-common-props (candidate kind type docstring inserted-text)
  "Perform common tasks for all completion node types.
Adds text properties to CANDIDATE.
KIND, TYPE, DOCSTRING are simply added.
INSERTED-TEXT is first used to match with the candidate."
  (let* ((name candidate)
         (match (battle-haxe-calc-match inserted-text name))
         (matchbegin (car (cl-first match)))
         (matchlen
          (if match
              (- (cdr (cl-first match)) (car (cl-first match)))
            0)))
    (battle-haxe-set-prop candidate 'kind kind)
    (battle-haxe-set-prop candidate 'type type)
    (battle-haxe-set-prop candidate 'docstring docstring)
    (battle-haxe-set-prop candidate 'match match)
    (battle-haxe-set-prop candidate 'matchlen matchlen)
    (battle-haxe-set-prop candidate 'matchbegin matchbegin)))

(defun battle-haxe-set-prop (text property value)
  "Put a text-property PROPERTY with value VALUE in string TEXT."
  (when (and text (not (string-empty-p text)))
    (put-text-property 0 1 property value text)))

(defun battle-haxe-get-prop (text property &optional default-value)
  "Get a text-property PROPERTY in string TEXT.
Optionally provide a DEFAULT-VALUE if not found."
  (or (get-text-property 0 property text)
      default-value))

(defun battle-haxe-annotation (name)
  "Annotate a completion-candidate NAME accodring to the attached meta-data."
  (let* ((type (get-text-property 0 'type name))
         (parts (battle-haxe-detect-signature-parts type))
         (return-type (alist-get 'return-val parts))
         (is-function (alist-get 'is-function parts)))
    (if is-function
        (concat
         " : "
         return-type)
      (concat ": " type))))

(defun battle-haxe-set-string-face (face string)
  "Helper to color STRING according to FACE."
  (put-text-property 0 (length string) 'face face string)
  string)

(defun battle-haxe-docstring (name)
  "Fetch documentation string from completion candidate NAME's metadata."
  (let ((doc-buffer
         (company-doc-buffer
          (concat
           (replace-regexp-in-string
            ;;remove tabs and spaces at beginning of lines
            "\n[\t ]+"
            "\n"
            (replace-regexp-in-string
             ;; remove empty lines and whitespace before text
             "\\`[ \t\n]*"
             ""
             (battle-haxe-get-prop name 'docstring "No documentation provided\n")))
           
           ;; ;; Give extra character to buffer because popup window crops up my text :-/
           ;; ;; Take note: the following string isn't empty,
           ;; "⁣"                            ; <-- there is a unicode "INVISIBLE SEPARATOR" here
           ))))
    ;; (with-current-buffer doc-buffer
    ;;   (visual-line-mode))
    doc-buffer))

(defun battle-haxe-get-prefix-member ()
  "Return a typed member name in a Haxe buffer, or nil if not typing a member."
  (let ((inserted-member
         (save-excursion
           (when (re-search-backward
                  (concat "\\(?:[.]\\|override \\)\\("battle-haxe-symbol-chars"*\\)\\=")
                  (line-beginning-position)
                  t)
             (match-string 1)))))
    inserted-member))

(defun battle-haxe-get-prefix-type ()
  "Return inserted type in syntax that expect types.

Specifically detects lines like this:
case Node(_):
And in those cases their colon is ignored and doesn't count as a type prefix.
However, in lines like this:
function fun():
The colon is accepted as a prefix to a Haxe type (and completion can trigger)."
  (let* ((beg-of-line (line-beginning-position))
         (is-switch-case-colon
          (save-excursion
            (when (re-search-backward
                   ;; Find situations like "case 1:" to ignore them
                   "^[[:blank:]]*\\(?:default\\|case\\)\\( .*\\)?:\\="
                   beg-of-line
                   t)
              (match-string 1))))
         (inserted-member
          (unless is-switch-case-colon
            (save-excursion
              (when (re-search-backward
                     "\\(?::\\|[<]\\|[^[:alnum:]]\\(?:new \\|import \\|using \\|\)\\)\\)\\([[:alnum:]\\|_]*\\)\\="
                     beg-of-line
                     t)
                (match-string 1))))))
    inserted-member))

(defun battle-haxe-get-prefix-any-symbol ()
  "Return a currently typed Haxe symbol, or nil if not detected to be typing any."
  (let ((inserted-symbol
         (save-excursion
           (when (re-search-backward
                  (concat battle-haxe-non-symbol-chars"\\("battle-haxe-symbol-chars"*\\)\\=")
                  (line-beginning-position)
                  t)
             (match-string 1)))))
    inserted-symbol))

(defun battle-haxe-try-find-enclosing-function-call ()
  "Try to find the 'current' function call.
That is, the function/constructor you're currently writing arguments to.
If found, return a buffer position that sits in the function/constructor's name.
If no function call found, return current point."
  (or (let* ((pos-at-function
              (save-excursion
                (or
                 (re-search-backward
                  (concat "\\(\\)new \\("battle-haxe-symbol-chars"*\\)[[:space:]]*\([^(]*\\=")
                  (line-beginning-position)
                  t)
                 (when (re-search-backward
                        (concat "\\("battle-haxe-symbol-chars"\\)[[:space:]]*[(][^(]*\\=")
                        ;;TODO: Allow detection of multi-line function calls. Maybe use `backward-up-list' until hit a "("
                        (line-beginning-position)
                        t)
                   (match-beginning 1))))))
        pos-at-function)
      (point)))

(defun battle-haxe-calc-match (inserted-text name)
  "Calculate the part of the INSERTED-TEXT that matchs NAME. Used for company candidates."
  (when name
    (let* ((str-match (string-match inserted-text name 0))
           (mbeg (if str-match
                     (match-beginning 0)
                   0))
           (mend (if str-match
                     (match-end 0)
                   0)))
      (list (cons mbeg mend)))))

(defun battle-haxe-save-buffer-silently ()
  "Save the buffer immediately before battle-haxe operations.
This forces you to save your documents unfortunately even if you don't want to,
but so far it's the only way I managed to get it to work.
Haxe asks for file paths and will not accept --display requests in temporary files."
  (let ((message-log-max nil))
    (save-buffer)))

(defun battle-haxe-eldoc-function ()
  "Asynchronously launch eldoc with a type hint string.
Contextually determines the current function or other symbol,
and displays the type information data for it.
If nothing found to fetch type information to, do nothing."
  
  (when buffer-file-name
    (battle-haxe-save-buffer-silently)
    
    ;; TODO: Use saved cached data when possible
    
    (battle-haxe-find-function-details
     (lambda (function-xml-details)
       (when function-xml-details
         (let* ((name (alist-get 'name function-xml-details))
                (root (alist-get 'xml-root function-xml-details))
                (is-function? (alist-get 'is-function? function-xml-details))
                (node-name (xml-node-name (xml-node-children (xml-node-name root))))
                (signature (battle-haxe-first-real-line-of node-name))
                (signature-parts (battle-haxe-detect-signature-parts signature))
                (args (alist-get 'args signature-parts))
                (return-val (alist-get 'return-val signature-parts)))
           (when name
             (eldoc-message
              (if is-function?
                  (concat name args " : " return-val)
                (concat name " : " signature))))))))))

(defun battle-haxe-first-real-line-of (str)
  "Get the first non-empty line in STR."
  (cl-first (-remove #'string-empty-p (split-string str "\n"))))

(defun battle-haxe-get-pos-string-parts (pos-string)
  "Split the returned POS-STRING to an alist with it's components.
the pos-string is returned from Haxe compiler services --display requests,
such as @position."
  (cl-mapcar #'cons '(file line char)
             (battle-haxe-string-regex-results
              "[[:space:]]*\\(.*\\):\\([[:digit:]]*\\): characters \\([[:digit:]]*\\)-[[:digit:]]*"
              3
              pos-string)))

(defun battle-haxe-detect-signature-parts (signature-string)
  "Break down SIGNATURE-STRING into args, and return value.
If not a function signature, the output 'args will be empty,
and the 'return-val will be the full signature."
  (if signature-string
      (let ((len (length signature-string)))
        (with-temp-buffer
          (insert signature-string)
          (goto-char 0)
          (if (or
               (and
                (< 0 (length signature-string))
                (string= "(" (substring signature-string 0 1)))
               (and (<= 5 len)
                    (string= "Void " (substring signature-string 0 5))))
              (progn
                (goto-char (scan-sexps (point) 1))
                (let* ((args (substring (buffer-string) 0 (- (point) 1)))
                       (return-val (cl-first
                                    (battle-haxe-string-regex-results
                                     "-> \\(.*\\)"
                                     1
                                     (substring (buffer-string)
                                                (min (point) len)
                                                len))))
                       (fixed-args (if (string= args "Void") "()" args)))
                  (list
                   (cons 'is-function t)
                   (cons 'args fixed-args)
                   (cons 'return-val return-val))))
            (list
             (cons 'is-function nil)
             (cons 'args "")
             (cons 'return-val signature-string)))))
    (list
     (cons 'is-function nil)
     (cons 'args "")
     (cons 'return-val "(NOT FOUND)"))))

(defun battle-haxe-is-invalid-pos-string (pos-string)
  "Check if this POS-STRING is actually a returned error message from the server."
  (or (not pos-string) (cl-search "unknown" pos-string)))

(defun battle-haxe-find-function-details (callback)
  "Calculate a cons result of (name . xml) about the current function.
That is, the Haxe function you're currently typing or typing arguments to.
The result will be returned to CALLBACK."
  (let ((function-info (battle-haxe-try-find-enclosing-function-call)))
    ;; If on a function
    (when function-info
      (let* ((function-pos function-info)
             (shell-cmd (battle-haxe-make-command-string
                         (battle-haxe-get-haxe-point function-pos) "position")))
        (async-start
         `(lambda ()
            (shell-command-to-string ,shell-cmd))
         (lambda (haxe-@position-output)
           (let ((pos-string (xml-node-name
                              (xml-node-children
                               (nth 0
                                    (xml-get-children
                                     (xml-node-name (battle-haxe-get-xml-root
                                                     haxe-@position-output))
                                     'pos))))))
             (if (battle-haxe-is-invalid-pos-string pos-string)
                 (progn
                   ;; (message
                   ;;  (format
                   ;;   "Couldn't find function position. Haxe returned this:\n%s"
                   ;;   haxe-@position-output))
                   nil)
               (when-let* ((parts (battle-haxe-get-pos-string-parts pos-string))
                           (filename (alist-get 'file parts))
                           (line-str (alist-get 'line parts))
                           (char-str (alist-get 'char parts))
                           (line (string-to-number line-str))
                           (char (string-to-number char-str)))
                 (let* ((try-function-name (battle-haxe-get-regex-at-coordinates "\\([^( \t\n]*\\)" filename line char))
                        (try-var-name (battle-haxe-get-regex-at-coordinates "\\([^: \t\n]*\\)" filename line char))
                        (is-function? (< (length try-function-name) (length try-var-name)))
                        (result-name)
                        (result-xml-root)
                        (haxe-point (battle-haxe-get-haxe-point-from-coordinates filename line char))
                        (shell-cmd2 (battle-haxe-make-command-string haxe-point "type")))
                   
                   (async-start
                    `(lambda ()
                       (shell-command-to-string ,shell-cmd2))
                    (lambda (haxe-@type-output)
                      
                      (setq result-name (if is-function?
                                            try-function-name
                                          try-var-name))
                      (setq result-xml-root (battle-haxe-get-xml-root haxe-@type-output))
                      
                      ;; pass the final value:
                      (funcall callback
                               (list
                                (cons 'name result-name)
                                (cons 'xml-root result-xml-root)
                                (cons 'is-function? is-function?)))))))))))
        ;; Found something, and fetching data asynchronously.
        ;; Return nil for now so eldoc doesn't launch yet.
        nil))))

(defun battle-haxe-get-regex-at-coordinates (regex filename line char)
  "Travel to the file FILENAME in a temporary buffer and extract some text.
The function goes to LINE and CHAR coordinates and tries to match REGEX."
  (let ((temp-buffer-name "*Haxe-temp*"))
    (progn
      (unless (get-buffer temp-buffer-name)
        (generate-new-buffer temp-buffer-name))
      (with-current-buffer
          temp-buffer-name
        (delete-region (point-min) (point-max))
        (insert-file-contents filename)
        (goto-char 0)
        (forward-line (cl-decf line))
        (forward-char (cl-decf char))
        (let ((result
               (save-excursion
                 (re-search-forward regex nil t)
                 (match-string 1))))
          (kill-buffer temp-buffer-name)
          result)))))

(defun battle-haxe-get-haxe-point-from-coordinates (filename line char)
  "Transforms FILENAME:LINE:CHAR coordinates.
The result is a haxe-point that can be sent to Haxe compiler services."
  (with-temp-buffer
    (insert-file-contents filename)
    
    (goto-char 0)
    (forward-line (cl-decf line))
    (forward-char (cl-decf char))
    (save-excursion
      (re-search-forward "\\([^( \t\n]*\\)" nil t))
    (concat filename (battle-haxe-get-haxe-point (point)))))

(defun battle-haxe-string-regex-results (regex num-results str)
  "Perform REGEX matching on the string STR.
Match a number of capture groups specified by NUM-RESULTS.
All of the matched results are returned as a list."
  (with-temp-buffer
    (insert str)
    (goto-char 0)
    (re-search-forward regex nil t)
    (cl-map 'listp
            (lambda (n) (match-string n))
            (number-sequence 1 num-results))))

(defun battle-haxe-is-server-running ()
  "Return non-nil if Haxe server is running."
  (and
   battle-haxe-server-process
   (eq  'run (process-status battle-haxe-server-process))))

(defun battle-haxe-start-server ()
  "Forcibly start the Haxe server in the current project.
If the server exists then kill it and start a new one.
Can be called interactively in another project to start a server there instead."
  (interactive)
  
  (when (battle-haxe-is-server-running)
    (kill-process battle-haxe-server-process)
    (setq battle-haxe-server-process nil))
  
  (when-let ((hxml-path
              (cl-first
               (battle-haxe-resolve-hxml-candidates))))
    ;;TODO: Make project-specific vars not global and allow launching several compilation servers, one per project?
    (setq battle-haxe-cached-hxml-args
          (battle-haxe-read-lines hxml-path))
    (setq battle-haxe-cwd
          (file-name-directory hxml-path)))
  
  ;; A delay between closing the server and starting a new one prevents problems.
  (run-at-time
   "1 sec"
   nil
   (lambda ()
     ;; (with-current-buffer (get-buffer-create "*Haxe server*")
     (setq battle-haxe-server-process
           (let ((shell-cmd
                  (s-join
                   " "
                   (list
                    ;; "start haxe -v --wait " (number-to-string battle-haxe-compiler-port)
                    "haxe -v --wait " (number-to-string battle-haxe-compiler-port)
                    " "
                    (s-join
                     " "
                     (battle-haxe-additional-compiler-flags))))))
             
             (async-start
              `(lambda ()
                 (shell-command-to-string
                  ,shell-cmd))))))))

(defun battle-haxe-goto-definition ()
  "Find definition of Haxe symbol at point and visit it."
  (interactive)
  
  (battle-haxe-save-buffer-silently)
  
  (-let* ((response (battle-haxe-position-query (battle-haxe-get-haxe-point)))
          ((pos-string . shell-result) response))
    (if (battle-haxe-is-invalid-pos-string pos-string)
        (message (format "Could not find definition. Haxe returned this:\n%s" shell-result))
      (battle-haxe-jump-to-pos-string (battle-haxe-get-pos-string-parts pos-string)))))

(defun battle-haxe-position-query (haxe-point)
  "Ask server the original position of object at point HAXE-POINT.
The return is a cons pair of (pos-string . shell-result)"
  (let* ((query (battle-haxe-make-command-string haxe-point "position"))
         (shell-result (shell-command-to-string query))
         (pos-string (nth 2 (car
                             (xml-get-children
                              (car (battle-haxe-get-xml-root shell-result))
                              'pos)))))
    (cons pos-string shell-result)))

(defun battle-haxe-jump-to-pos-string (pos-string-parts)
  "Visit coordinates (file, line, char) returned by Haxe compiler services.
POS-STRING-PARTS hold the coordinates.
The function uses 'push-mark' to enable going back to the previous position."
  (let* ((parts pos-string-parts)
         (filename (alist-get 'file parts))
         (line (string-to-number (alist-get 'line parts)))
         (char (string-to-number (alist-get 'char parts))))
    (when filename
      (push-mark)
      (find-file filename)
      (goto-char 0)
      (forward-line (cl-decf line))
      (forward-char (cl-decf char)))))

(defun battle-haxe-helm-find-references ()
  "Ask Haxe for all references to symbol at point and prompt to visit one.
Choosing between the results is done with helm."
  (interactive)
  
  (battle-haxe-save-buffer-silently)
  
  (let* ((command-to-call1      ;get the declaration
          (battle-haxe-make-command-string (battle-haxe-get-haxe-point) "position"))
         (command-to-call2      ;get all usage found
          (battle-haxe-make-command-string (battle-haxe-get-haxe-point) "usage"))
         (source-list
          (xml-get-children
           (car (battle-haxe-get-xml-root (shell-command-to-string command-to-call1)))
           'pos))
         (is-valid source-list)
         (usages-list
          (when is-valid
            (xml-get-children
             (car (battle-haxe-get-xml-root (shell-command-to-string command-to-call2)))
             'pos)))
         (candidates
          (when is-valid
            (-map
             (lambda (node)
               (let* ((pos-string (nth 2 node))
                      (parts (battle-haxe-get-pos-string-parts pos-string))
                      (file (alist-get 'file parts))
                      (formatted
                       (format
                        "%s:%s:%s"
                        (propertize file
                                    'face 'helm-grep-file)
                        (propertize (alist-get 'line parts)
                                    'face 'helm-grep-lineno)
                        (propertize (battle-haxe-get-line-contents parts)
                                    'face 'helm-grep-match)))
                      (candidate
                       (cons formatted parts)))
                 candidate))
             (append
              source-list
              usages-list)))))
    (if candidates
        (helm :sources   `((name . "Sections")
                           (candidates . ,candidates)
                           (volatile)
                           (action . (("Goto `RET'" . battle-haxe-jump-to-pos-string))))
              :buffer "*helm-haxe-find-references*")
      (message "No references found in code."))))

(defun battle-haxe-get-line-contents (parts)
  "Take PARTS (coordinates to a file position) and return the line's string there."
  (let* ((filename (alist-get 'file parts))
         (line (string-to-number (alist-get 'line parts)))
         (char 1))
    (or (battle-haxe-get-regex-at-coordinates
         "\\(?:[[:blank:]]\\)*\\(.*\\)$"
         filename line char)
        "")))

(defun battle-haxe-perform-result-expansion (candidate)
  "Called after CANDIDATE is inserted.
Either insert interactively using yasnippet,
Or insert regularly, but without any function arg list."
  (delete-region (- (point) (length candidate)) (point))
  (let* ((split (battle-haxe-split-candidate candidate))
         (use-yasnippet (and
                         battle-haxe-yasnippet-completion-expansion
                         (bound-and-true-p yas-minor-mode)
                         ;; Only for functions
                         (alist-get 'is-function split))))
    (if use-yasnippet
        (yas-expand-snippet (battle-haxe-make-yasnippet-template split))
      (insert (alist-get 'name split)))))

(defun battle-haxe-split-candidate (candidate)
  "Split CANDIDATE to a name, and a list of arguments (if any)."
  (let* ((name (cl-first (battle-haxe-string-regex-results (concat "\\("battle-haxe-symbol-chars"*\\).*") 1 candidate)))
         (is-function (cl-search "(" candidate))
         (args-str-raw
          (and is-function
               (battle-haxe-string-regex-results (concat ""battle-haxe-symbol-chars"*\(\\(.*\\)\)") 1 candidate)))
         (args-str (or (cl-first args-str-raw) ""))
         (args nil))
    ;; Arguments
    (when is-function
      (let ((arg-strings (split-string args-str ", " ",")))
        (setq args
              (-map (lambda (arg)
                      (substring arg 0
                                 (string-match battle-haxe-non-symbol-chars arg)))
                    arg-strings))))
    
    (list
     (cons 'is-function is-function)
     (cons 'name name)
     (cons 'args args))))

(defun battle-haxe-make-yasnippet-template (candidate-split)
  "Convert CANDIDATE-SPLIT to a yasnippet template."
  (let ((name (alist-get 'name candidate-split))
        (args (alist-get 'args candidate-split)))
    ;; Process arguments
    (setq args
          (let ((last (-last-item args)))
            (--map (if (string= it last)
                       (format "${%s}" it)
                     (format "${%s}, " it))
                   args)))
    ;; Process template
    (apply
     #'concat
     (append
      (list name "(")
      args
      (list ")")))))

(add-to-list 'company-backends #'battle-haxe-company-backend)

(provide 'battle-haxe)
;;; battle-haxe.el ends here
