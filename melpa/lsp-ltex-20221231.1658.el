;;; lsp-ltex.el --- LSP Clients for LTEX  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2023  Shen, Jen-Chieh
;; Created date 2021-04-03 00:35:56

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-languagetool/lsp-ltex
;; Package-Version: 20221231.1658
;; Package-Commit: d1a599c8ec3748c2b81899d5831b6e7158255479
;; Version: 0.2.1
;; Package-Requires: ((emacs "27.1") (lsp-mode "6.1"))
;; Keywords: convenience lsp languagetool checker

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; LSP server implementation for LTEX
;;

;;; Code:

(require 'custom)
(require 'subr-x)

(require 'lsp-mode)
(require 'github-tags nil t)

(defgroup lsp-ltex nil
  "Settings for the LTEX Language Server.

https://github.com/valentjn/ltex-ls"
  :prefix "lsp-ltex-"
  :group 'lsp-mode
  :link '(url-link :tag "Github" "https://github.com/emacs-languagetool/lsp-ltex"))

(defconst lsp-ltex-repo-path "valentjn/ltex-ls"
  "Path points to the repository url.")

(defcustom lsp-ltex-active-modes
  '(text-mode latex-mode org-mode markdown-mode)
  "List of major mode that work with LTEX Language Server."
  :type 'list
  :group 'lsp-ltex)

(defvar lsp-ltex--filename nil "File base name.")
(defvar lsp-ltex--extension-name nil "File name of the extension file from language server.")
(defvar lsp-ltex--server-download-url nil "Automatic download url for lsp-ltex.")

(defcustom lsp-ltex-server-store-path
  (expand-file-name "ltex-ls" lsp-server-install-dir)
  "The path to the file in which LTEX Language Server will be stored."
  :type 'file
  :group 'lsp-ltex)

(defcustom lsp-ltex-user-rules-path
  (let ((path (expand-file-name "lsp-ltex" user-emacs-directory)))
    (unless (and (file-exists-p path) (file-directory-p path))
      (mkdir path t))
    path)
  "The path to the directory where `lsp-ltex' will store user rules."
  :type 'directory
  :group 'lsp-ltex)

(defcustom lsp-ltex-enabled nil
  "Controls whether the extension is enabled."
  :type '(choice (const :tag "None" nil)
                 list)
  :group 'lsp-ltex)

(defcustom lsp-ltex-language "en-US"
  "The language LanguageTool should check against."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-dictionary '()
  "Lists of additional words that should not be counted as spelling errors."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-disabled-rules '()
  "Lists of rules that should be disabled (if enabled by default by
LanguageTool)."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-enabled-rules '()
  "Lists of rules that should be enabled (if disabled by default by
LanguageTool)."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-hidden-false-positives '()
  "Lists of false-positive diagnostics to hide."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-bibtex-fields '()
  "List of BibTEX fields whose values are to be checked in BibTEX files."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-latex-commands '()
  "List of LATEX commands to be handled by the LATEX parser, listed together
with empty arguments."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-latex-environments '()
  "List of names of LATEX environments to be handled by the LATEX parser."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-markdown-nodes '()
  "List of Markdown node types to be handled by the Markdown parser."
  :type 'list
  :group 'lsp-ltex)

(defcustom lsp-ltex-additional-rules-enable-picky-rules nil
  "Enable LanguageTool rules that are marked as picky and that are disabled
by default, e.g., rules about passive voice, sentence length, etc."
  :type 'boolean
  :group 'lsp-ltex)

(defcustom lsp-ltex-mother-tongue ""
  "Optional mother tongue of the user (e.g., \"de-DE\")."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-additional-rules-language-model ""
  "Optional path to a directory with rules of a language model with
n-gram occurrence counts."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-additional-rules-neural-network-model ""
  "Optional path to a directory with rules of a pretrained neural network model."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-additional-rules-word-2-vec-model ""
  "Optional path to a directory with rules of a word2vec language model."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-languagetool-http-server-uri ""
  "If set to a non-empty string, LTEX will not use the bundled,
built-in version of LanguageTool.  Instead, LTEX will connect to an
external LanguageTool HTTP server."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-languagetool-org-username ""
  "Username/email as used to log in at languagetool.org for Premium API access.
Only relevant if `lsp-ltex-languagetool-http-server-uri' is set."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-languagetool-org-api-key ""
  "API key for Premium API access.
Only relevant if `lsp-ltex-languagetool-http-server-uri' is set."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-ls-path ""
  "If set to an empty string, LTEX automatically downloads ltex-ls from GitHub.
It stores it in the folder of the extension, and uses it for the checking
process.  You can point this setting to an ltex-ls release you downloaded by
yourself."
  :type 'directory
  :group 'lsp-ltex)

(defcustom lsp-ltex-log-level "fine"
  "Logging level (verbosity) of the ltex-ls server log."
  :type '(choice (const "severe")
                 (const "warning")
                 (const "info")
                 (const "config")
                 (const "fine")
                 (const "finer")
                 (const "finest"))
  :group 'lsp-ltex)

(defcustom lsp-ltex-java-path ""
  "If set to an empty string and LTEX could not find Java on your computer,
LTEX automatically downloads a Java distribution (AdoptOpenJDK), stores it
in the folder of the extension, and uses it to run ltex-ls.  You can point
this setting to an existing Java installation on your computer to use that
installation instead."
  :type 'string
  :group 'lsp-ltex)

(defcustom lsp-ltex-java-initial-heap-size 64
  "Initial size of the Java heap memory in megabytes.
Corresponds to Java's -Xmx option, this must be a positive integer"
  :type 'integer
  :group 'lsp-ltex)

(defcustom lsp-ltex-java-maximum-heap-size 512
  "Maximum size of the Java heap memory in megabytes.
Corresponds to Java's -Xmx option, this must be a positive integer"
  :type 'integer
  :group 'lsp-ltex)

(defcustom lsp-ltex-sentence-cache-size 2000
  "Size of the LanguageTool `ResultCache` in sentences.
This must be a positive integer."
  :type 'integer
  :group 'lsp-ltex)

(defcustom lsp-ltex-completion-enabled nil ;; TODO: Add proper implementation
  "If this this is enabled, auto-completion list for the current word is sent.
The editor need to send a completion request."
  :type 'boolean
  :group 'lsp-ltex)

(defcustom lsp-ltex-diagnostic-severity "information"
  "Severity of the diagnostics corresponding to the grammar and spelling errors."
  :type '(choice (const "error")
                 (const "warning")
                 (const "information")
                 (const "hint"))
  :group 'lsp-ltex)

(defcustom lsp-ltex-check-frequency "edit"
  "Controls when documents should be checked."
  :type '(choice (const "edit")
                 (const "save")
                 (const "manual"))
  :group 'lsp-ltex)

(defcustom lsp-ltex-clear-diagnostics-when-closing-file t
  "If non-nil, diagnostics of a file are cleared when the file is closed."
  :type 'boolean
  :group 'lsp-ltex)

(defcustom lsp-ltex-status-bar-item nil ;; TODO: Add proper implementation
  "If non-nil, the status of LTEX is shown permanently in the status bar."
  :type 'boolean
  :group 'lsp-ltex)

(defcustom lsp-ltex-trace-server "off"
  "Debug setting to log the communication between language client and server."
  :type '(choice (const "off")
                 (const "messages")
                 (const "verbose"))
  :group 'lsp-ltex)

;;
;; (@* "Externals" )
;;

(declare-function github-tags "ext:github-tags.el")

;;
;; (@* "Util" )
;;

(defmacro lsp-ltex--mute-apply (&rest body)
  "Execute BODY without message."
  (declare (indent 0) (debug t))
  `(let (message-log-max)
     (with-temp-message (or (current-message) nil)
       (let ((inhibit-message t)) ,@body))))

(defun lsp-ltex--s-replace (old new s)
  "Replace OLD with NEW in S."
  (replace-regexp-in-string (regexp-quote old) new s t t))

(defun lsp-ltex--execute (cmd &rest args)
  "Return non-nil if CMD executed succesfully with ARGS."
  (save-window-excursion
    (lsp-ltex--mute-apply
      (= 0 (shell-command (concat cmd " "
                                  (mapconcat #'shell-quote-argument
                                             (cl-remove-if #'null args)
                                             " ")))))))

(defun lsp-ltex--plist-keys (plist)
  "Return the keys of PLIST."
  (let (keys)
    (while plist
      (push (car plist) keys)
      (setq plist (cddr plist)))
    keys))

(defun lsp-ltex--lsp-keys (table)
  "Similar to `lsp-get' and `lsp-put', it return the keys in TABLE."
  (if lsp-use-plists
      (lsp-ltex--plist-keys table)
    (hash-table-keys table)))

(defun lsp-ltex--serialize-symbol (sym dir)
  "Serialize SYM to DIR.
Return the written file name, or nil if SYM is not bound."
  (when (boundp sym)
    (let ((out-file (expand-file-name
                     (lsp-ltex--s-replace "lsp-ltex--" ""
                                          (symbol-name sym))
                     dir)))
      (lsp-message "[INFO] Saving `%s' to file \"%s\"" (symbol-name sym) out-file)
      (with-temp-buffer
        (prin1 (eval sym) (current-buffer))
        (lsp-ltex--mute-apply (write-file out-file)))
      out-file)))

(defun lsp-ltex--deserialize-symbol (sym dir &optional mutate)
  "Deserialize SYM from DIR, if MUTATE is non-nil, assign the object to SYM.
Return the deserialized object, or nil if the SYM.el file dont exist."
  (let ((in-file (expand-file-name
                  (lsp-ltex--s-replace "lsp-ltex--" ""
                                       (symbol-name sym))
                  dir))
        res)
    (when (file-exists-p in-file)
      (lsp-message "[INFO] Loading `%s' from file \"%s\"" (symbol-name sym) in-file)
      (with-temp-buffer
        (insert-file-contents in-file)
        (goto-char (point-min))
        (ignore-errors (setq res (read (current-buffer)))))
      (when mutate (set sym res)))
    res))

(defun lsp-ltex--add-rule (lang rule rules-plist)
  "Add RULE of language LANG to the plist named RULES-PLIST (symbol)."
  (when (null (eval rules-plist))
    (set rules-plist (list lang [])))
  (plist-put (eval rules-plist) lang
             (vconcat (list rule) (plist-get (eval rules-plist) lang)))
  (when-let (out-file (lsp-ltex--serialize-symbol rules-plist lsp-ltex-user-rules-path))
    (lsp-message "[INFO] Rule for language %s saved to file \"%s\"" (symbol-name lang) out-file)))

(defun lsp-ltex-combine-plists (&rest plists)
  "Create a single property list from all plists in PLISTS.
Modified from `org-combine-plists'. This supposes the values to be vectors,
and concatenate them."
  (let ((res (copy-sequence (pop plists)))
        prop val plist)
    (while plists
      (setq plist (pop plists))
      (while plist
        (setq prop (pop plist) val (pop plist))
        (setq res (plist-put res prop (vconcat val (plist-get res prop))))))
    res))

;;
;; (@* "Installation and Upgrade" )
;;

(defun lsp-ltex--downloaded-extension-path ()
  "Return full path of the downloaded extension (compressed file).

This is use to unzip the language server files."
  (expand-file-name lsp-ltex--extension-name lsp-ltex-server-store-path))

(defun lsp-ltex--extension-root ()
  "Return the root of the extension path.

This is use to active language server and check if language server's existence."
  (expand-file-name "latest" lsp-ltex-server-store-path))

(defun lsp-ltex--store-locally-p ()
  "Return non-nil if language server is installed locally."
  (and (string-prefix-p lsp-server-install-dir lsp-ltex-server-store-path)
       (file-directory-p lsp-ltex-server-store-path)))

(defun lsp-ltex--current-version ()
  "Return the current version of LTEX."
  (if (lsp-ltex--store-locally-p)
      (when-let* ((gz-files (directory-files-recursively lsp-ltex-server-store-path "\\.gz"))
                  (tar (car gz-files))
                  (fn (file-name-nondirectory (lsp-ltex--s-replace ".tar.gz" "" tar))))
        (lsp-ltex--s-replace "ltex-ls-" "" fn))
    (ignore-errors (gethash "ltex-ls" (json-parse-string (shell-command-to-string "ltex-ls -V"))))))

(defun lsp-ltex--latest-version ()
  "Return the latest version from remote repository."
  (when (featurep 'github-tags)
    (when-let ((response (ignore-errors (github-tags lsp-ltex-repo-path))))
      (let ((names (plist-get (cdr response) :names))
            (index 0) version ver)
        ;; Loop through tag name and fine the stable version
        (while (and (not version) (< index (length names)))
          (setq ver (nth index names)
                index (1+ index))
          (when (string-match-p "^[0-9.]+$" ver)  ; stable version are only with numbers and dot
            (setq version ver)))
        version))))

(defun lsp-ltex--lsp-dependency ()
  "Register LSP dependency once."
  (lsp-dependency
   'ltex-ls
   '(:system "ltex-ls")
   `(:download :url ,lsp-ltex--server-download-url
               :store-path ,(lsp-ltex--downloaded-extension-path))))

(defcustom lsp-ltex-version (or (lsp-ltex--current-version)
                                (lsp-ltex--latest-version)
                                "14.0.0")  ; fall back to preset version
  "Version of LTEX language server."
  :type 'string
  :set (lambda (symbol value)
         (set-default symbol value)
         (setq lsp-ltex--filename (format "ltex-ls-%s" value)
               lsp-ltex--extension-name (format "%s.tar.gz" lsp-ltex--filename)
               lsp-ltex--server-download-url
               (format "https://github.com/%s/releases/download/%s/%s"
                       lsp-ltex-repo-path value lsp-ltex--extension-name))
         (lsp-ltex--lsp-dependency))
  :group 'lsp-ltex)

(defun lsp-ltex-upgrade-ls ()
  "Upgrade LTEX to latest stable version.

If current server not found, install it then."
  (interactive)
  (let ((latest (lsp-ltex--latest-version))
        (current (lsp-ltex--current-version)))
    (if (and current (version<= latest current))
        (message "[INFO] Current LTEX server is up to date: %s" current)
      (when current
        ;; First delete all binary files
        (delete-directory lsp-ltex-server-store-path t))
      (custom-set-variables `(lsp-ltex-version ,latest))
      (lsp-install-server t 'ltex-ls)  ; this is async
      (message "[INFO] %s LTEX server version: %s"
               (if current "Upgrading" "Installing") lsp-ltex-version))))

(defun lsp-ltex-install-ls ()
  "Install LTEX language server."
  (let* ((tar (lsp-ltex--downloaded-extension-path))
         (dest (file-name-directory tar))
         (output (expand-file-name lsp-ltex--filename dest))
         (latest (expand-file-name "latest" (file-name-directory output)))
         (is-windows (eq system-type 'windows-nt)))
    (if (lsp-ltex--execute "tar" "-xvzf" tar "-C" dest)
        (unless (lsp-ltex--execute (if is-windows "move" "mv")
                                   (unless is-windows "-f")
                                   output latest)
          (error "[ERROR] Failed to rename version `%s` to latest" lsp-ltex-version))
      (error "[ERROR] Failed to unzip tar, %s" tar))))

;;
;; (@* "Activation" )
;;

(defvar lsp-ltex--stored-dictionary
  (lsp-ltex--deserialize-symbol 'lsp-ltex--stored-dictionary
                                lsp-ltex-user-rules-path)
  "The dictionary created from interactively added words.")

(defvar lsp-ltex--stored-disabled-rules
  (lsp-ltex--deserialize-symbol 'lsp-ltex--stored-disabled-rules
                                lsp-ltex-user-rules-path)
  "The rules created from interactively added words.")

(defvar lsp-ltex--stored-hidden-false-positives
  (lsp-ltex--deserialize-symbol 'lsp-ltex--stored-hidden-false-positives
                                lsp-ltex-user-rules-path)
  "The rules created from interactively added words.")

(defvar lsp-ltex--combined-dictionary
  (lsp-ltex-combine-plists lsp-ltex-dictionary lsp-ltex--stored-dictionary)
  "The combined `lsp-ltex-dictionary' and interactively added words.")

(defvar lsp-ltex--combined-disabled-rules
  (lsp-ltex-combine-plists lsp-ltex-disabled-rules lsp-ltex--stored-disabled-rules)
  "The combined `lsp-ltex-disabled-rules' and interactively added rules.")

(defvar lsp-ltex--combined-hidden-false-positives
  (lsp-ltex-combine-plists lsp-ltex-hidden-false-positives
                           lsp-ltex--stored-hidden-false-positives)
  "The combined `lsp-ltex-hidden-false-positives' and interactively added rules.")

(defun lsp-ltex--server-entry ()
  "Return the server entry file.

This file is use to activate the language server."
  (if (lsp-ltex--store-locally-p)
      (concat (file-name-as-directory (lsp-ltex--extension-root))
              (file-name-as-directory "bin")
              (if (eq system-type 'windows-nt)
                  "ltex-ls.bat"
                "ltex-ls"))
    (executable-find "ltex-ls")))

(defun lsp-ltex--server-command ()
  "Startup command for LTEX language server."
  (list (lsp-ltex--server-entry)))

(lsp-register-custom-settings
 '(("ltex.enabled" lsp-ltex-enabled)
   ("ltex.language" lsp-ltex-language)
   ("ltex.dictionary" lsp-ltex--combined-dictionary)
   ("ltex.disabledRules" lsp-ltex--combined-disabled-rules)
   ("ltex.enabledRules" lsp-ltex-enabled-rules)
   ("ltex.hiddenFalsePositives" lsp-ltex--combined-hidden-false-positives)
   ("ltex.bibtex.fields" lsp-ltex-bibtex-fields)
   ("ltex.latex.commands" lsp-ltex-latex-commands)
   ("ltex.latex.environments" lsp-ltex-latex-environments)
   ("ltex.markdown.nodes" lsp-ltex-markdown-nodes)
   ("ltex.additionalRules.enablePickyRules" lsp-ltex-additional-rules-enable-picky-rules t)
   ("ltex.additionalRules.motherTongue" lsp-ltex-mother-tongue)
   ("ltex.additionalRules.languageModel" lsp-ltex-additional-rules-language-model)
   ("ltex.additionalRules.neuralNetworkModel" lsp-ltex-additional-rules-neural-network-model)
   ("ltex.additionalRules.word2VecModel" lsp-ltex-additional-rules-word-2-vec-model)
   ("ltex.languageToolHttpServerUri" lsp-ltex-languagetool-http-server-uri)
   ("ltex.languageToolOrg.username" lsp-ltex-languagetool-org-username)
   ("ltex.languageToolOrg.apiKey" lsp-ltex-languagetool-org-api-key)
   ("ltex.ltex-ls.path" lsp-ltex-ls-path)
   ("ltex.ltex-ls.logLevel" lsp-ltex-log-level)
   ("ltex.java.path" lsp-ltex-java-path)
   ("ltex.java.initialHeapSize" lsp-ltex-java-initial-heap-size)
   ("ltex.java.maximumHeapSize" lsp-ltex-java-maximum-heap-size)
   ("ltex.sentenceCacheSize" lsp-ltex-sentence-cache-size)
   ("ltex.completionEnabled" lsp-ltex-completion-enabled t)
   ("ltex.diagnosticSeverity" lsp-ltex-diagnostic-severity)
   ("ltex.checkFrequency" lsp-ltex-check-frequency)
   ("ltex.clearDiagnosticsWhenClosingFile" lsp-ltex-clear-diagnostics-when-closing-file t)
   ("ltex.statusBarItem" lsp-ltex-status-bar-item t)
   ("ltex.trace.server" lsp-ltex-trace-server)))

(lsp-ltex--lsp-dependency)

(defun lsp-ltex--action-add-to-rules (action-ht key rules-plist &optional store)
  "Execute action ACTION-HT by getting KEY and storing it in the RULES-PLIST.
When STORE is non-nil, this will also store the new plist in the directory
`lsp-ltex-user-rules-path'."
  (let ((args-ht (lsp-get (if (vectorp action-ht) (elt action-ht 0) action-ht) key)))
    (dolist (lang (lsp-ltex--lsp-keys args-ht))
      (let ((lang-key (if (stringp lang) (intern (concat ":" lang)) lang)))
        (mapc (lambda (rule)
                (lsp-ltex--add-rule lang-key rule rules-plist)
                (when store
                  (lsp-ltex--serialize-symbol rules-plist lsp-ltex-user-rules-path)))
              (lsp-get args-ht lang-key))))))

(lsp-defun lsp-ltex--code-action-add-to-dictionary ((&Command :arguments?))
  "Handle action for \"_ltex.addToDictionary\"."
  ;; Add rule internally to the `lsp-ltex--stored-dictionary' plist and
  ;; store it in the directory `lsp-ltex-user-rules-path'
  (lsp-ltex--action-add-to-rules
   arguments? :words 'lsp-ltex--stored-dictionary t)
  ;; Combine user configured words `lsp-ltex-dictionary' and the internal
  ;; interactively generated `lsp-ltex--stored-dictionary', and store them in
  ;; the internal `lsp-ltex--combined-dictionary', which is sent to ltex-ls
  (setq lsp-ltex--combined-dictionary
        (lsp-ltex-combine-plists lsp-ltex-dictionary lsp-ltex--stored-dictionary))
  (lsp-message "[INFO] Word added to dictionary."))

(lsp-defun lsp-ltex--code-action-hide-false-positives ((&Command :arguments?))
  "Handle action for \"_ltex.hideFalsePositives\"."
  (lsp-ltex--action-add-to-rules arguments? :falsePositives
                                 'lsp-ltex--stored-hidden-false-positives t)
  (setq lsp-ltex--combined-hidden-false-positives
        (lsp-ltex-combine-plists lsp-ltex-hidden-false-positives
                                 lsp-ltex--stored-hidden-false-positives))
  (lsp-message "[INFO] Rule added to false positives."))

(lsp-defun lsp-ltex--code-action-disable-rules ((&Command :arguments?))
  "Handle action for \"_ltex.disableRules\"."
  (lsp-ltex--action-add-to-rules arguments? :ruleIds
                                 'lsp-ltex--stored-disabled-rules t)
  (setq lsp-ltex--combined-disabled-rules
        (lsp-ltex-combine-plists lsp-ltex-disabled-rules
                                 lsp-ltex--stored-disabled-rules))
  (lsp-message "[INFO] Rule disabled."))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   #'lsp-ltex--server-command
                   (lambda () (let ((entry (lsp-ltex--server-entry)))
                                (and (file-exists-p entry)
                                     (not (file-directory-p entry))
                                     (file-executable-p entry)))))
  :major-modes lsp-ltex-active-modes
  :action-handlers
  (lsp-ht
   ("_ltex.addToDictionary" #'lsp-ltex--code-action-add-to-dictionary)
   ("_ltex.disableRules" #'lsp-ltex--code-action-disable-rules)
   ("_ltex.hideFalsePositives" #'lsp-ltex--code-action-hide-false-positives))
  :priority -2
  :add-on? t
  :server-id 'ltex-ls
  :download-server-fn
  (lambda (_client _callback error-callback _update?)
    (lsp-package-ensure 'ltex-ls #'lsp-ltex-install-ls error-callback))))

(provide 'lsp-ltex)
;;; lsp-ltex.el ends here
