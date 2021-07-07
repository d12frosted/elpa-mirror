;;; ac-dcd.el --- Auto Completion source for dcd for GNU Emacs

;; Author:  <atila.neves@gmail.com>
;; Version: 0.6
;; Package-Commit: 56d9817159acdebdbb3d5499c7e9379d29af0cd4
;; Package-Version: 20210428.1556
;; Package-X-Original-Version: 20170323.1301
;; Package-Requires: ((auto-complete "1.3.1") (flycheck-dmd-dub "0.7"))
;; Keywords: languages
;; URL: http://github.com/atilaneves/ac-dcd

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

;; Auto Completion source for DCD.  This code was modified from ac-dscanner.el
;; which originally came from auto-complete-clang-async.el.  Originally from
;; the DCD git repository https://github.com/Hackerpilot/DCD/blob/master/editors/emacs/ac-dcd.el.

;; Usage:

;; (require 'ac-dcd)
;; (add-to-list 'ac-modes 'd-mode)
;; (add-hook 'd-mode-hook #'ac-dcd-setup)

;;; Code:

(require 'auto-complete)
(require 'rx)
(require 'yasnippet nil t)
(require 'json)
(require 'flycheck-dmd-dub)


(defcustom ac-dcd-executable
  "dcd-client"
  "Location of dcd-client executable."
  :group 'auto-complete
  :type 'file)

(defcustom ac-dcd-flags nil
  "Extra flags to pass to the dcd-server.
This variable will typically contain include paths,
e.g., (\"-I~/MyProject\", \"-I.\").
You can't put port number flag here.  Set `ac-dcd-server-port' instead."
  :group 'auto-complete
  :type '(repeat (string :tag "Argument" "")))

(defconst ac-dcd-completion-pattern
  (rx bol (submatch (1+ nonl)) "\t" (submatch (any "cisuvmkfgePMaAltT")) eol)
  "Regex to parse dcd output.
\\1 is candidate itself, \\2 is kind of candidate.")

(defconst ac-dcd-error-buffer-name "*dcd-error*")
(defconst ac-dcd-output-buffer-name "*dcd-output*")
(defconst ac-dcd-document-buffer-name "*dcd-document*")
(defconst ac-dcd-search-symbol-buffer-name "*dcd-search-symbol*")
(defcustom ac-dcd-server-executable
  "dcd-server"
  "Location of dcd-server executable."
  :group 'auto-complete
  :type 'file)

(defcustom ac-dcd-server-port 9166
  "Port number of dcd-server.  default is 9166."
  :group 'auto-complete)

(defvar ac-dcd-delay-after-kill-process 200
  "Duration after killing server process in milli second.
If `ac-dcd-init-server' doesn't work correctly, please set bigger number for this variable.")

(defvar ac-dcd-version nil
  "Version of dcd server.  This variable is automatically set when ac-dcd-get-version is called.")

(defcustom ac-dcd-ignore-template-argument nil
  "If non-nil, ignore template argument of calltip candidate."
  :group 'auto-complete)

;;server handle functions

(defun ac-dcd-stop-server ()
  "Stop dcd-server manually.  Ordinary, you don't have to call it.
If you want to restart server, use `ac-dcd-init-server' instead."
  (interactive)
  (interrupt-process "dcd-server"))

(defsubst ac-dcd-start-server ()
  "Start dcd-server."
  (let ((buf (get-buffer-create " *dcd-server*")))
    (with-current-buffer buf (apply 'start-process "dcd-server" (current-buffer)
                                            ac-dcd-server-executable
                                            "-p"
                                            (format "%s" ac-dcd-server-port)
                                            ac-dcd-flags
                                            ))))

(defun ac-dcd-maybe-start-server ()
  "Start dcd-server.  When the server process is already running, do nothing."
  (unless (or (get-process "dcd-server") (not (zerop (string-to-number (shell-command-to-string "pidof dcd-server")))))
    (ac-dcd-start-server)))

(defun ac-dcd-init-server ()
  "Start dcd-server.  When the server process is already running, restart it."
  (interactive)
  (when (get-process "dcd-server")
    (ac-dcd-stop-server)
    (sleep-for 0 ac-dcd-delay-after-kill-process))
  (ac-dcd-start-server)
  (setq ac-dcd-version nil))

(defun ac-dcd-get-version ()
  "Get dcd version.  If ac-dcd-version is set, use it as a cache."
  (if ac-dcd-version
          ac-dcd-version
        (progn
          (ac-dcd-call-process '("--version"))
          (let* ((buf (get-buffer ac-dcd-output-buffer-name))
                         (str (with-current-buffer buf (buffer-string)))
                         verstr)
                (string-match (rx "v" (submatch (* nonl)) (or "-" "\n")) str)
                (setq verstr (match-string 1 str))
                (setq ac-dcd-version (string-to-number verstr))
                ))))

;; output parser functions

(defun ac-dcd-parse-output (prefix buf)
  "Parse dcd output with prefix PREFIX on buffer BUF."
  (with-current-buffer buf
        (goto-char (point-min))
        (let ((pattern ac-dcd-completion-pattern)
                  lines match detailed-info
                  (prev-match ""))
          (while (re-search-forward pattern nil t)
                (setq match (match-string-no-properties 1))

                (unless (string= "Pattern" match)
                  (setq detailed-info (match-string-no-properties 2))
                  (if (string= match prev-match)
                          (progn
                                (when detailed-info
                                  (setq match (propertize match
                                        'ac-dcd-help
                                        (concat
                                         (get-text-property 0 'ac-dcd-help (car lines))
                                         "\n"
                                         detailed-info)))
                                  (setf (car lines) match)))
                        (setq prev-match match)
                        (when detailed-info
                          (setq match (propertize match 'ac-dcd-help detailed-info)))
                        (push match lines))))
          lines)))

(defvar ac-dcd-error-message-regexp
  (rx (and (submatch (* nonl))  ": " (submatch (* nonl)) ": " (submatch (* nonl) eol)))
  "If it matches first line of dcd-output, it would be error message.")

(defun ac-dcd-handle-error (res args)
  "Notify error with result RES and arguments ARGS."
  (let* ((errbuf (get-buffer-create ac-dcd-error-buffer-name))
         (outbuf (get-buffer ac-dcd-output-buffer-name))
         (cmd (concat ac-dcd-executable " " (mapconcat 'identity (cons "--tcp" args) " ")))
         (errstr
          (with-current-buffer outbuf
            (goto-char (point-min))
            (re-search-forward ac-dcd-error-message-regexp)
            (concat
             (match-string 2) " : " (match-string 3)))
          ))
    (with-current-buffer errbuf
      (erase-buffer)
      (insert (current-time-string)
              "\n\"" cmd "\" failed."
              (format "\nError type is: %s\n" errstr)
              )
      (goto-char (point-min)))
    (display-buffer errbuf)))

;; utility functions to call process
(defun ac-dcd-call-process (args)
  "Call dcd-client with ARGS."
  (let ((buf (get-buffer-create ac-dcd-output-buffer-name))
        res)
    (with-current-buffer buf (erase-buffer))
    (setq res (if (null ac-dcd-executable)
                  (progn
                    (message "ac-dcd error: could not find dcd-client executable")
                    0)
                (apply 'call-process-region (point-min) (point-max)
                       ac-dcd-executable nil buf nil (cons "--tcp" args))))
    (with-current-buffer buf
      (unless (eq 0 res)
        (ac-dcd-handle-error res args))
      )))

(defsubst ac-dcd-cursor-position ()
  "Get cursor position to pass to dcd-client.
TODO: multi byte character support"
  (position-bytes (point)))

(defsubst ac-dcd-build-complete-args (pos)
  "Build argument list to pass to dcd-client for position POS."
  (list
   "-c"
   (format "%s" pos)
   "-p"
   (format "%s" ac-dcd-server-port)
   ))


(defsubst ac-in-string/comment ()
  "Return non-nil if point is in a literal (a comment or string)."
  (nth 8 (syntax-ppss)))

(defsubst ac-dcd-adjust-cursor-on-completion (point)
  "If it was not member completion, goto the head of query before call process.
`POINT' is the point to complete in D src."

  (let* ((end point)
         (begin (progn
                  (while (not (string-match (rx (or blank "." "\n")) (char-to-string (char-before (point)))))
                    (backward-char))
                  (point)))
         (query (buffer-substring begin end)))
    ))

;; Interface functions to communicate with auto-complete.el.
(defun ac-dcd-get-candidates ()
  "Get ordinary auto-complete candidates."
  (unless (ac-in-string/comment)
    (save-restriction
      (widen)
      (let ((prefix ac-prefix))
        (save-excursion
          (ac-dcd-adjust-cursor-on-completion (point))
          (ac-dcd-call-process
           (ac-dcd-build-complete-args (ac-dcd-cursor-position))))
        (ac-dcd-parse-output prefix (get-buffer-create ac-dcd-output-buffer-name))))))

(defun ac-dcd-prefix ()
  "Return the autocomplete prefix."
  (or (ac-prefix-symbol)
      (let ((c (char-before)))
                (point))))

(defun ac-dcd-document (item)
  "Return popup document of `ITEM'."
  (if (stringp item)
      (let (s)
        (setq s (get-text-property 0 'ac-dcd-help item))
        (cond
                 ((equal s "c") "class name")
                 ((equal s "i") "interface name")
                 ((equal s "s") "struct name")
                 ((equal s "u") "union name")
                 ((equal s "v") "variable name")
                 ((equal s "m") "member variable name")
                 ((equal s "k") "keyword, built-in version, scope statement")
                 ((equal s "f") "function or method")
                 ((equal s "g") "enum name")
                 ((equal s "e") "enum member")
                 ((equal s "P") "package name")
                 ((equal s "M") "module name")
                 ((equal s "a") "array")
                 ((equal s "A") "associative array")
                 ((equal s "l") "alias name")
                 ((equal s "t") "template name")
                 ((equal s "T") "mixin template name")
         (t (format "candidate kind undetected: %s" s))
         ))))



(defun ac-dcd-action ()
  "Try function calltip expansion."
  (when (featurep 'yasnippet)

    (let ((lastcompl (cdr ac-last-completion)))
      (cond
       ((string-match "f" (get-text-property 0 'ac-dcd-help lastcompl)) ; when it was a function
        (progn
          (ac-complete-dcd-calltips)))
       ((string-match "s" (get-text-property 0 'ac-dcd-help lastcompl)) ; when it was a struct
        (progn
          (ac-complete-dcd-calltips-for-struct-constructor)))
       (t nil)
       ))))

(ac-define-source dcd
  '((candidates . ac-dcd-get-candidates)
    (prefix . ac-dcd-prefix)
    (requires . 0)
    (document . ac-dcd-document)
    (action . ac-dcd-action)
    (cache)
    (symbol . "D")
    ))

;; function calltip expansion with yasnippet

(defun ac-dcd-get-calltip-candidates ()
  "Do calltip completion of the D symbol at point.
The cursor must be at the end of a D symbol.
When the symbol is not a function, returns nothing"
  (let ((buf (get-buffer-create ac-dcd-output-buffer-name)))
    (ac-dcd-call-process-for-calltips)
    (with-current-buffer buf (ac-dcd-parse-calltips))
    ))

(defun ac-dcd-call-process-for-calltips ()
  "Call process to get calltips of the function at point."
  (insert "( ;")
  (backward-char 2)

  (ac-dcd-call-process
   (ac-dcd-build-complete-args (ac-dcd-cursor-position)))

  (forward-char 2)
  (delete-char -3)
  )


(defconst ac-dcd-normal-calltip-pattern
  (rx bol (submatch (* nonl)) (submatch "(" (* nonl) ")") eol)
  "Regexp to parse calltip completion.
\\1 is function return type (if exists) and name, and \\2 is args.")
(defconst ac-dcd-template-pattern (rx (submatch (* nonl)) (submatch "(" (*? nonl) ")") (submatch "(" (* nonl)")"))
  "Regexp to parse template calltips.
\\1 is function return type (if exists) and name, \\2 is template args, and \\3 is args.")
(defconst ac-dcd-calltip-pattern
  (rx  (or (and bol (* nonl) "(" (* nonl) ")" eol)
           (and bol (* nonl) "(" (*? nonl) ")" "(" (* nonl)")" eol))))
(defcustom ac-dcd-ignore-template-argument t
  "If non-nil, ignore template argument on calltip expansion."
  :group 'auto-complete)

(defsubst ac-dcd-cleanup-function-candidate (s)
  "Remove return type of the head of the function.
`S' is candidate string."
  (let (res)
    (with-temp-buffer
      (insert s)

      ;;goto beggining of function name
      (progn
        (end-of-line)
        (backward-sexp)
        (re-search-backward (rx (or bol " "))))

      (setq res (buffer-substring
                 (point)
                 (progn
                   (end-of-line)
                   (point))))
      (when (equal " " (substring res 0 1))
        (setq res (substring res 1)))
      res
      )))
(defsubst ac-dcd-cleanup-template-candidate (s)
  "Remove return type of the head of the function.
`S' is candidate string."
  (let (res)
    (with-temp-buffer
      (insert s)

      ;;goto beggining of function name
      (progn
        (end-of-line)
        (backward-sexp)
        (backward-sexp)
        (re-search-backward (rx (or bol " "))))

      (setq res (buffer-substring
                 (point)
                 (progn
                   (end-of-line)
                   (point))))
      (when (equal " " (substring res 0 1))
        (setq res (substring res 1)))
      res
      )))

(defsubst ac-dcd-candidate-is-tempalte-p (s)
  "If candidate string `S' is template, return t."
  (with-temp-buffer
    (insert s)
    (backward-sexp)
    (equal ")" (char-to-string (char-before)))))

(defun ac-dcd-parse-calltips ()
  "Parse dcd output for calltip completion.
It returns a list of calltip candidates."
  (goto-char (point-min))
  (let ((pattern ac-dcd-calltip-pattern)
        lines
        match
        )
    (while (re-search-forward pattern nil t)
      (setq match (match-string 0))
      (if (ac-dcd-candidate-is-tempalte-p match)
          (progn
            (string-match ac-dcd-template-pattern match)
            (add-to-list 'lines (ac-dcd-cleanup-function-candidate (format "%s%s" (match-string 1 match) (match-string 3 match)))) ;candidate without template argument
            (unless ac-dcd-ignore-template-argument
              (string-match ac-dcd-template-pattern match)
              (add-to-list 'lines (ac-dcd-cleanup-template-candidate (format "%s!%s%s" (match-string 1 match) (match-string 2 match) (match-string 3 match))))))
        (progn
          (string-match ac-dcd-normal-calltip-pattern match)
          (add-to-list 'lines (ac-dcd-cleanup-function-candidate (format "%s%s" (match-string 1 match) (match-string 2 match)))))
        ))
    lines
    ))

(defsubst ac-dcd-format-calltips (str)
  "Format calltips `STR' in parenthesis to yasnippet style."
  (let (yasstr)

    ;;remove parenthesis
    (setq str (substring str 1 (- (length str) 1)))

    (setq yasstr
          (mapconcat
           (lambda (s) "format each args to yasnippet style" (concat "${" s "}"))
           (split-string str ", ")
           ", "))
    (setq yasstr (concat "(" yasstr ")"))
    ))

(defun ac-dcd-calltip-action ()
  "Format the calltip to yasnippet style.
This function should be called at *dcd-output* buf."
  (let* ((end (point))
         (arg-beg (save-excursion
                (backward-sexp)
                (point)))
         (template-beg
          (if (ac-dcd-candidate-is-tempalte-p (cdr ac-last-completion))
              (save-excursion
                (backward-sexp 2)
                (point))
            nil))
         (args (buffer-substring arg-beg end))
         res)
    (delete-region arg-beg end)
    (setq res (ac-dcd-format-calltips args))

    (when template-beg
      (let ((template-args (buffer-substring template-beg arg-beg)))
        (delete-region template-beg arg-beg)
        (setq res (format "%s%s" (ac-dcd-format-calltips template-args) res))))
    (yas-expand-snippet res)))

(defun ac-dcd-calltip-prefix ()
  (car ac-last-completion))

(defvar dcd-calltips
  '((candidates . ac-dcd-get-calltip-candidates)
    (prefix . ac-dcd-calltip-prefix)
    (action . ac-dcd-calltip-action)
    (cache)
    ))

(defun ac-complete-dcd-calltips ()
  (auto-complete '(dcd-calltips)))

;; struct constructor calltip expansion

(defsubst ac-dcd-replace-this-to-struct-name (struct-name)
  "Replace \"this\" with STRUCT-NAME.
dcd-client outputs candidates that begin with \"this\" when completing struct constructor calltips."
  (goto-char (point-min))
  (while (search-forward "this" nil t)
        (replace-match struct-name)))

(defun ac-dcd-calltip-candidate-for-struct-constructor ()
  "Almost the same as `ac-dcd-calltip-candidate', but call `ac-dcd-replace-this-to-struct-name' before parsing."
  (let ((buf (get-buffer-create ac-dcd-output-buffer-name)))
    (ac-dcd-call-process-for-calltips)
    (with-current-buffer buf
      (ac-dcd-replace-this-to-struct-name (cdr ac-last-completion))
      (ac-dcd-parse-calltips))
    ))

(defvar dcd-calltips-for-struct-constructor
  '((candidates . ac-dcd-calltip-candidate-for-struct-constructor)
    (prefix . ac-dcd-calltip-prefix)
    (action . ac-dcd-calltip-action)
    (cache)
    ))

(defun ac-complete-dcd-calltips-for-struct-constructor ()
  (auto-complete '(dcd-calltips-for-struct-constructor)))


;;show document

(defun ac-dcd-reformat-document ()
  "Currently, it just decodes \n and \\n."
  (with-current-buffer (get-buffer ac-dcd-document-buffer-name)

    ;;doit twice to catch '\n\n'
    (goto-char (point-min))
    (while (re-search-forward (rx (and (not (any "\\")) (submatch "\\n"))) nil t)
      (replace-match "\n" nil nil nil 1))

    (goto-char (point-min))
    (while (re-search-forward (rx (and (not (any "\\")) (submatch "\\n"))) nil t)
      (replace-match "\n" nil nil nil 1))

    ;; replace '\\n' in D src to '\n'
    (while (re-search-forward (rx "\\\\n") nil t)
      (replace-match "\\\\n"))
        (goto-char (point-min))
    ))

(defun ac-dcd-get-ddoc ()
  "Get document with `dcd-client --doc'."
  (save-buffer)
  (let ((args
         (append
          (ac-dcd-build-complete-args (ac-dcd-cursor-position))
          '("-d")
          (list (buffer-file-name))))
        (buf (get-buffer-create ac-dcd-document-buffer-name)))

    (with-current-buffer buf
      (erase-buffer)

      (apply 'call-process-region (point-min) (point-max)
             ac-dcd-executable nil buf nil (cons "--tcp" args))
      (when (or
             (string= (buffer-string) "")
             (string= (buffer-string) "\n\n\n")             ;when symbol has no doc
             )
        (error "No document for the symbol at point!"))
      (buffer-string)
      )))

(defun ac-dcd-show-ddoc-with-buffer ()
  "Display Ddoc at point using `display-buffer'."
  (interactive)
  (ac-dcd-get-ddoc)
  (ac-dcd-reformat-document)
  (display-buffer (get-buffer-create ac-dcd-document-buffer-name)))


;; goto definition
;; thanks to jedi.el by Takafumi Arakaki

(defcustom ac-dcd-goto-definition-marker-ring-length 16
  "Length of marker ring to store `ac-dcd-goto-definition' call positions."
  :group 'auto-complete)

(defvar ac-dcd-goto-definition-marker-ring
  (make-ring ac-dcd-goto-definition-marker-ring-length)
  "Ring that stores ac-dcd-goto-symbol-declaration.")

(defsubst ac-dcd-goto-def-push-marker ()
  "Push marker at point to goto-def ring."
  (ring-insert ac-dcd-goto-definition-marker-ring (point-marker)))

(defun ac-dcd-goto-def-pop-marker ()
  "Goto the point where `ac-dcd-goto-definition' was last called."
  (interactive)
  (if (ring-empty-p ac-dcd-goto-definition-marker-ring)
      (error "Marker ring is empty. Can't pop.")
    (let ((marker (ring-remove ac-dcd-goto-definition-marker-ring 0)))
      (switch-to-buffer (or (marker-buffer marker)
                            (error "Buffer has been deleted")))
      (goto-char (marker-position marker))
      ;; Cleanup the marker so as to avoid them piling up.
      (set-marker marker nil nil))))

(defun ac-dcd-goto-definition ()
  "Goto declaration of symbol at point."
  (interactive)
  (save-buffer)
  (ac-dcd-call-process-for-symbol-declaration)
  (let* ((data (ac-dcd-parse-output-for-get-symbol-declaration))
         (file (car data))
         (offset (cdr data)))
    (if (equal data '(nil . nil))
        (message "Not found")
      (progn
        (ac-dcd-goto-def-push-marker)
        (unless (string=  file "stdin") ; the declaration is in the current file
          (find-file file))
        (goto-char (byte-to-position (1+ (string-to-number offset))))))))


;; utilities for goto-definition

(defun ac-dcd-call-process-for-symbol-declaration ()
  "Get location of symbol declaration with `dcd-client --symbolLocation'."
  (let ((args
         (append
          (ac-dcd-build-complete-args (ac-dcd-cursor-position))
          '("-l")
          (list (buffer-file-name))))
        (buf (get-buffer-create ac-dcd-output-buffer-name)))
    (with-current-buffer
        buf (erase-buffer)
                (ac-dcd-call-process args)
                )
    (let ((output (with-current-buffer buf (buffer-string))))
      output)))

(defun ac-dcd-parse-output-for-get-symbol-declaration ()
  "Parse output of `ac-dcd-get-symbol-declaration'.
output is just like following.\n
`(cons \"PATH_TO_IMPORT/import/std/stdio.d\" \"63946\")'"
  (let ((buf (get-buffer-create ac-dcd-output-buffer-name)))
    (with-current-buffer buf
      (goto-char (point-min))
      (if (not (string= "Not found\n" (buffer-string)))
          (progn (re-search-forward (rx (submatch (* nonl)) "\t" (submatch (* nonl)) "\n"))
                 (cons (match-string 1) (match-string 2)))
        (cons nil nil)))
    ))

(defun ac-dcd-parent-directory (dir)
  "Return parent directory of DIR."
  (when dir
    (file-name-directory (directory-file-name (expand-file-name dir)))))

(defun ac-dcd-search-file-up (name &optional path)
  "Search for file NAME in parent directories recursively."
  (let* ((tags-file-name (concat path name))
         (parent (ac-dcd-parent-directory path))
         (path (or path default-directory))
         )
    (cond
     ((file-exists-p tags-file-name) tags-file-name)
     ((string= parent path) nil)
     (t (ac-dcd-search-file-up name parent)))))

(defun ac-dcd-find-imports-dub ()
  "Extract import flags from \"dub describe\" output."
  (let* ((basedir (fldd--get-project-dir)))
        (if basedir
                (mapcar (lambda (x) (concat "-I" x)) (fldd--get-dub-package-dirs))
          nil)))

(defun ac-dcd-find-imports-std ()
  "Extract import flags from dmd.conf file."
  (require 'cl)
  (let ((dmd-conf-filename
         (find-if 'file-exists-p
                  (list
                   ;; TODO: the first directory to look into should be dmd's current
                   ;; working dir
                   (concat (getenv "HOME") "/dmd.conf")
                   (concat (ac-dcd-parent-directory (executable-find "dmd")) "dmd.conf")
                   "/usr/local/etc/dmd.conf"
                   "/etc/dmd.conf"))))

    ;; TODO: this extracting procedure is pretty rough, it just searches for
    ;; the first occurrence of the DFLAGS
    (save-window-excursion
      (with-temp-buffer
        (insert-file-contents dmd-conf-filename)
        (goto-char (point-min))
        (search-forward "\nDFLAGS")
        (skip-chars-forward " =")
        (let ((flags-list (split-string (buffer-substring-no-properties
                                         (point) (line-end-position)))))
          (remove-if-not '(lambda (s)
                            (string-prefix-p "-I" s))
                         flags-list))))))

(defun ac-dcd--find-all-project-imports ()
  "Find all project imports, including std packages and dub dependencies."
  (append (ac-dcd-find-imports-std) (ac-dcd-find-imports-dub)))

(defun ac-dcd--add-imports (&optional imports)
  "Send import flags of the current DUB project to dcd-server.

The root of the project is determined by the \"closest\" dub.json
or package.json file. If IMPORTS is passed, it is used instead."
  (let ((paths (if imports (mapcar (lambda (x) (concat "-I" x)) imports) (ac-dcd--find-all-project-imports))))
    (ac-dcd-call-process paths)))

(defun ac-dcd-add-imports ()
  "Send import flags of the current DUB project to dcd-server.

The root of the project is determined by the \"closest\" dub.json
or package.json file."
  (interactive)
  (ac-dcd--add-imports))

(defun ac-dcd-add-import (path)
  "Add PATH to the list of DCD imports."
  (interactive "DPath to add to DCD imports: ")
  (ac-dcd--add-imports (list path))
  )

;;;###autoload
(defun ac-dcd-setup ()
  (auto-complete-mode t)
  ;; dir locals might be used by flycheck-dmd-dub to find import paths
  (hack-dir-local-variables-non-file-buffer)
  (when (featurep 'yasnippet) (yas-minor-mode-on))
  (ac-dcd-maybe-start-server)
  (ac-dcd-add-imports)
  (add-to-list 'ac-sources 'ac-source-dcd)
  (define-key d-mode-map (kbd "C-c ?") 'ac-dcd-show-ddoc-with-buffer)
  (define-key d-mode-map (kbd "C-c .") 'ac-dcd-goto-definition)
  (define-key d-mode-map (kbd "C-c ,") 'ac-dcd-goto-def-pop-marker)
  (define-key d-mode-map (kbd "C-c s") 'ac-dcd-search-symbol)

  (when (featurep 'popwin)
    (add-to-list 'popwin:special-display-config
                 `(,ac-dcd-error-buffer-name :noselect t))
    (add-to-list 'popwin:special-display-config
                 `(,ac-dcd-document-buffer-name :position right :width 80))
    (add-to-list 'popwin:special-display-config
                 `(,ac-dcd-search-symbol-buffer-name :position bottom :width 5))))

(defun ac-dcd-visit-file-in-line ()
  (interactive)
  (let* ((line (thing-at-point 'line))
         (parts (split-string line))
         (filename (car parts))
         (position (car (last parts))))
    (find-file filename)
    (goto-char (string-to-number position))
    (local-set-key (kbd "C-c <left>")
                   '(lambda ()
                      (interactive)
                      (switch-to-buffer (get-buffer-create
                                         ac-dcd-search-symbol-buffer-name))))))

(defun ac-dcd-search-symbol ()
  (interactive)
  (let ((thing (thing-at-point 'word)))
    (let ((buf (get-buffer-create ac-dcd-search-symbol-buffer-name)))
      (with-current-buffer buf
        (erase-buffer)
        (if thing
            (apply 'call-process-region (point-min) (point-max)
                   ac-dcd-executable nil buf nil (list "--tcp" "--search" thing))
          (let ((symbol (read-from-minibuffer "Enter symbol: ")))
            (apply 'call-process-region (point-min) (point-max)
                   ac-dcd-executable nil buf nil (list "--tcp" "--search" symbol))))
        (display-buffer buf)
        (end-of-buffer)
        (delete-char -1)
        (beginning-of-buffer)
        (if (= (count-lines (point-min) (point-max)) 1)
            (call-interactively 'ac-dcd-visit-file-in-line)
          (progn
            (local-set-key "q" 'delete-window)
            (local-set-key (kbd "RET") 'ac-dcd-visit-file-in-line)))))))

(provide 'ac-dcd)
;;; ac-dcd.el ends here
