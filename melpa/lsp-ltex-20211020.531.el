;;; lsp-ltex.el --- LSP Clients for LTEX  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-04-03 00:35:56

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: LSP Clients for LTEX.
;; Keyword: lsp languagetool checker
;; Version: 0.2.1
;; Package-Version: 20211020.531
;; Package-Commit: e546ad686ac3d92752ae2841b3da5b4b92ef06c8
;; Package-Requires: ((emacs "26.1") (lsp-mode "6.1") (f "0.20.0") (s "1.12.0"))
;; URL: https://github.com/emacs-languagetool/lsp-ltex

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
(require 'f)
(require 's)

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
  (f-join lsp-server-install-dir "ltex-ls")
  "The path to the file in which LTEX Language Server will be stored."
  :type 'file
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

(defcustom lsp-ltex-java-force-try-system-wide nil
  "If non-nil, always try to use a system-wide Java installation before
trying to use an automatically downloaded Java distribution."
  :type 'boolean
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

(defcustom lsp-ltex-trace-server "off"
  "Debug setting to log the communication between language client and server."
  :type '(choice (const "off")
                 (const "messages")
                 (const "verbose"))
  :group 'lsp-ltex)

;;
;; (@* "Externals" )
;;

(defvar github-tags-names)

(declare-function github-tags "ext:github-tags.el")

;;
;; (@* "Util" )
;;

(defun lsp-ltex--execute (cmd &rest args)
  "Return non-nil if CMD executed succesfully with ARGS."
  (save-window-excursion
    (let ((inhibit-message t) (message-log-max nil))
      (= 0 (shell-command (concat cmd " "
                                  (mapconcat #'shell-quote-argument args " ")))))))
;;
;; (@* "Installation and Upgrade" )
;;

(defun lsp-ltex--downloaded-extension-path ()
  "Return full path of the downloaded extension (compressed file).

This is use to unzip the language server files."
  (f-join lsp-ltex-server-store-path lsp-ltex--extension-name))

(defun lsp-ltex--extension-root ()
  "Return the root of the extension path.

This is use to active language server and check if language server's existence."
  (f-join lsp-ltex-server-store-path "latest"))

(defun lsp-ltex--current-version ()
  "Return the current version of LTEX."
  (when-let* ((gz-files (ignore-errors
                          (f--files lsp-ltex-server-store-path (equal (f-ext it) "gz"))))
              (tar (nth 0 gz-files))
              (fn (f-filename (s-replace ".tar.gz" "" tar))))
    (s-replace "ltex-ls-" "" fn)))

(defun lsp-ltex--latest-version ()
  "Return the latest version from remote repository."
  (when (featurep 'github-tags)
    (github-tags lsp-ltex-repo-path)
    (let ((index 0) version ver)
      ;; Loop through tag name and fine the stable version
      (while (and (not version) (< index (length github-tags-names)))
        (setq ver (nth index github-tags-names)
              index (1+ index))
        (when (string-match-p "^[0-9.]+$" ver)  ; stable version are only with numbers and dot
          (setq version ver)))
      version)))

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
  "Upgrade LTEXT to latest stable version.

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

;;
;; (@* "Activation" )
;;

(defun lsp-ltex--server-entry ()
  "Return the server entry file.

This file is use to activate the language server."
  (f-join (lsp-ltex--extension-root) "bin" (if (eq system-type 'windows-nt)
                                               "ltex-ls.bat"
                                             "ltex-ls")))

(defun lsp-ltex--server-command ()
  "Startup command for LTEX language server."
  (list (lsp-ltex--server-entry)))

(lsp-register-custom-settings
 '(("ltex.enabled" lsp-ltex-enabled)
   ("ltex.language" lsp-ltex-language)
   ("ltex.dictionary" lsp-ltex-dictionary)
   ("ltex.disabledRules" lsp-ltex-disabled-rules)
   ("ltex.enabledRules" lsp-ltex-enabled-rules)
   ("ltex.hiddenFalsePositives" lsp-ltex-hidden-false-positives)
   ("ltex.bibtex.fields" lsp-ltex-bibtex-fields)
   ("ltex.latex.commands" lsp-ltex-latex-commands)
   ("ltex.latex.environments" lsp-ltex-latex-environments)
   ("ltex.markdown-nodes" lsp-ltex-markdown-nodes)
   ("ltex.additionalRules.enablePickyRules" lsp-ltex-additional-rules-enable-picky-rules)
   ("ltex.additionalRules.motherTongue" lsp-ltex-mother-tongue)
   ("ltex.additionalRules.languageModel" lsp-ltex-additional-rules-language-model)
   ("ltex.additionalRules.neuralNetworkModel" lsp-ltex-additional-rules-neural-network-model)
   ("ltex.additionalRules.word2VecModel" lsp-ltex-additional-rules-word-2-vec-model)
   ("ltex.ltex-ls.languageToolHttpServerUri" lsp-ltex-languagetool-http-server-uri)
   ("ltex.ltex-ls.logLevel" lsp-ltex-log-level)
   ("ltex.java.path" lsp-ltex-java-path)
   ("ltex.java.forceTrySystemWide" lsp-ltex-java-force-try-system-wide)
   ("ltex.java.initialHeapSize" lsp-ltex-java-initial-heap-size)
   ("ltex.java.maximumHeapSize" lsp-ltex-java-maximum-heap-size)
   ("ltex.sentenceCacheSize" lsp-ltex-sentence-cache-size)
   ("ltex.diagnosticSeverity" lsp-ltex-diagnostic-severity)
   ("ltex.checkFrequency" lsp-ltex-check-frequency)
   ("ltex.clearDiagnosticsWhenClosingFile" lsp-ltex-clear-diagnostics-when-closing-file)
   ("ltex.trace.server" lsp-ltex-trace-server)))

(lsp-ltex--lsp-dependency)

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   #'lsp-ltex--server-command
                   (lambda () (f-exists? (lsp-ltex--extension-root))))
  :activation-fn (lambda (&rest _) (apply #'derived-mode-p lsp-ltex-active-modes))
  :priority -2
  :add-on? t
  :server-id 'ltex-ls
  :download-server-fn
  (lambda (_client _callback error-callback _update?)
    (lsp-package-ensure
     'ltex-ls
     (lambda ()
       (let* ((tar (lsp-ltex--downloaded-extension-path))
              (dest (f-dirname tar))
              (output (f-join dest lsp-ltex--filename))
              (latest (f-join (f-dirname output) "latest")))
         (if (lsp-ltex--execute "tar" "-xvzf" tar "-C" dest)
             (unless (lsp-ltex--execute (if (eq system-type 'windows-nt) "move" "mv")
                                        output latest)
               (error "Failed to rename version `%s` to latest" lsp-ltex-version))
           (error "Error during the unzip process: tar"))))
     error-callback))))

(provide 'lsp-ltex)
;;; lsp-ltex.el ends here
