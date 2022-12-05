;;; mos-mode.el --- MOS toolkit usage -*- lexical-binding: t; -*-

;; URL: https://github.com/themkat/mos-mode
;; Package-Version: 20221204.1932
;; Package-Commit: e6e3df3e1ea0a94848d09aa72eb214e5dc3b77ef
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (lsp-mode "8.0.0") (dap-mode "0.7") (dash "2.19.1") (ht "2.3"))

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

;; Glue code and helpers to make the MOS toolkit (lsp-server, dap-adapter and more) work inside Emacs.
;; This is used to work with MOS 6502 assembly programming projects.
;; https://github.com/datatrash/mos
;; Provides a minor mode for assembly language programs that provide the functionality from MOS if in a MOS project.

;;; Code:

(require 'lsp-mode)
(require 'dap-mode)
(require 'dash)
(require 'ht)

(defcustom mos-executable-path (executable-find "mos")
  "Path to the mos executable."
  :group 'mos-mode
  :type 'string)

(defcustom mos-vice-executable-path (executable-find "x64sc")
  "Path to the VICE executable (either x64 or x64sc)."
  :group 'mos-mode
  :type 'string)

(defcustom mos-format-on-save t
  "Whether to format the buffer when saving or not"
  :group 'mos-mode
  :type 'boolean)

;; font lock to get proper syntax highlighting
(defconst mos-font-lock-keywords
  (list
   ;; comments
   (cons "/\\*.*\\*/" 'font-lock-comment-face)
   (cons "//.*$" 'font-lock-comment-face)
   ;; labels
   (cons "[a-zA-Z0-9_]+\\:" 'font-lock-function-name-face)
   ;; macro invocation
   (cons "[a-zA-Z0-9_]+(.*)" 'font-lock-function-name-face)
   ;; mnemonics/asm opcodes
   (cons "[ ]+\\(adc\\|and\\|asl\\|bcc\\|bcs\\|beq\\|bit\\|bmi\\|bne\\|bpl\\|brk\\|bvc\\|bvs\\|clc\\|cld\\|cli\\|clv\\|cmp\\|cpx\\|cpy\\|dec\\|dex\\|dey\\|eor\\|inc\\|inx\\|iny\\|jmp\\|jsr\\|lda\\|ldx\\|ldy\\|lsr\\|nop\\|ora\\|pha\\|php\\|pla\\|plp\\|rol\\|ror\\|rti\\|rts\\|sbc\\|sec\\|sed\\|sei\\|sta\\|stx\\|sty\\|tax\\|tay\\|tsx\\|txa\\|txs\\|tya\\)"
         'font-lock-keyword-face)
   ;; mos builtins
   (cons (regexp-opt '(".const" ".var" ".byte" ".word" ".dword" ".macro" ".define" ".segment" ".loop" ".align" ".if" "else" "as" ".import" "from" ".text" "ascii" "petscii" "petscreen" ".file" ".assert" ".trace" ".test")
                     t)
         'font-lock-builtin-face)
   ;; hexadecimals
   (cons "#?\\$[0-9A-Fa-f]+" 'font-lock-constant-face)
   ;; binary numbers
   (cons "#?\\%[0-1]+" 'font-lock-constant-face)
   ;; decimals
   (cons "#?[0-9]+" 'font-lock-constant-face))
  "Highlighting rules for MOS, mostly 6502 assembly syntax with some special built-ins on top.")

(defun mos--jump-to-prev-non-empty-line ()
  "Jumps to first non-empty line, or the beginning of the buffer. Used for indentation."
  (forward-line -1)
  (back-to-indentation)
  (when (and (not (bobp))
             (looking-at "^[[:blank:]]*$"))
    (mos--jump-to-prev-non-empty-line)))

(defconst mos--regex-label-pattern "[[:blank:]]*[a-zA-Z0-9_]+:"
  "Pattern to check if something is an assembly label.")

(defun mos-indent-line ()
  "Indent the current line."
  (beginning-of-line)
  (let (prev-indent
        inside-block
        is-prev-label
        (prev-line-label-length -1))
    ;; get the previous non empty lines indentation level
    (save-excursion
      (mos--jump-to-prev-non-empty-line)
      (setq prev-indent (current-indentation))
      (setq inside-block (looking-at ".*{"))
      (setq is-prev-label (looking-at mos--regex-label-pattern))
      (when is-prev-label
        (let* ((curr-line (thing-at-point 'line))
               (label-text (match-string (string-match mos--regex-label-pattern
                                                       curr-line)
                                         curr-line)))
          (setq prev-line-label-length (length (string-trim label-text))))))

    ;; actual indentation logic (probably super simple)
    ;; (first time I ever had to create an indent function)
    (cond ((bobp) (indent-line-to 20))
          (inside-block
           (indent-line-to (+ prev-indent 4)))
          ((looking-at "^.*}")
           (indent-line-to (- prev-indent 4)))
          ((looking-at mos--regex-label-pattern)
           ;; we are at the line of a label, so we need to get the labels length
           (let* ((curr-line (thing-at-point 'line))
                  (label-text (match-string (string-match mos--regex-label-pattern
                                                          curr-line)
                                            curr-line))
                  (label-length (length (string-trim label-text))))
             (indent-line-to (- prev-indent label-length 1))))
          (is-prev-label
           ;; Opposite of the "current line is label" calculation
           (indent-line-to (+ prev-indent prev-line-label-length 1)))
          (t
           (indent-line-to prev-indent)))))

;; Function to control whether we format on save
(defun mos-format-on-save-fun ()
  "Format on save given that the variable mos-format-on-save is true"
  (when mos-format-on-save
    (lsp-format-buffer)))

;; simple major mode based on assembly mode that can be activated
;;;###autoload
(define-derived-mode mos-mode
  fundamental-mode "MOS mode"
  "Major mode for use with the MOS toolkit for 6502 processors."
  (setq font-lock-defaults '(mos-font-lock-keywords nil t))
  (setq indent-line-function 'mos-indent-line)
  (add-hook 'after-save-hook 'mos-format-on-save-fun nil t))

(add-to-list 'lsp-language-id-configuration '(mos-mode . "mos"))
(add-to-list 'mos-mode-hook #'lsp)

(defun mos-build ()
  "Build the current project."
  (interactive)
  (let ((default-directory (locate-dominating-file default-directory "mos.toml")))
    (compile (string-join (list mos-executable-path " build")))))

(defun mos-run-all-tests ()
  "Run all the tests in project."
  (interactive)
  (let ((default-directory (locate-dominating-file default-directory "mos.toml")))
    (compile (string-join (list mos-executable-path " test")))))

(defun mos-run-program ()
  "Run the current program/source file."
  (interactive)
  ;; TODO: build. preLaunchTask is probably a vscode thing.
  (dap-debug (list :type "mos"
                   :request "launch"
                   :name "MOS Run program"
                   :vicePath mos-vice-executable-path
                   :noDebug t)))

(defun mos-debug-program ()
  "Debug the current program/source file."
  (interactive)
  ;; TODO: build. preLaunchTask is probably a vscode thing.
  (dap-debug (list :type "mos"
                   :request "launch"
                   :name "MOS Debug program"
                   :vicePath mos-vice-executable-path
                   :noDebug nil)))

(defun mos-debug-test (no-debug)
  "Debug helper function to avoid repetition.
NO-DEBUG denotes if it should be a regular session or a debug session."
  `(lambda (arguments)
     (-let [(&hash "arguments" [test-name]) arguments]
       (dap-debug (list :type "mos"
                        :request "launch"
                        :name (string-join (list "Test " test-name))
                        :testRunner (list :testCaseName test-name)
                        :noDebug ,no-debug)))))
;; TODO: maybe some sort of support if we don't have lenses active?


;; download if dependency not present
;; TODO: FIX! NOT WORKING AT THE MOMENT!
;; (defcustom mos-download-url
;;   (string-join (list "https://github.com/datatrash/mos/releases/download/0.7.5/mos-0.7.5-x86_64-"
;;                      (cond ((string-equal "darwin" system-type) "apple-darwin.tar.gz")
;;                      ((string-equal "gnu/linux" system-type) "unknown-linux-musl.tar.gz")
;;                      ((string-equal "windows-nt" system-type) "pc-windows-msvc.zip"))))
  
;;   "Download URL for the mos executable"
;;   :group 'mos-mode
;;   :type 'string)

;; (defvar mos-lsp-download-path (f-join lsp-server-install-dir "mos" "mos"))

;; (lsp-dependency
;;  'mos
;;  (list :system mos-lsp-download-path)
;;  (list :download
;;        :url mos-download-url
;;        ;; TODO: should there be a way to unpack tar.gz in lsp-mode? maybe make a pr for that instead fo hacky shit here...
;;        :decompress (if (string-equal "windows-nt" system-type) :zip :tgz)
;;        :store-path (f-join lsp-server-install-dir
;;                            "mos"
;;                            "mos")
;;        :binary-path mos-lsp-download-path
;;        :set-executable? t))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection (lambda () (list mos-executable-path "-v" "lsp")))
  :activation-fn (lsp-activate-on "mos")
  :major-modes '(mos-mode)
  :priority -1
  :server-id 'mos-ls
  :action-handlers (ht ("mos.runSingleTest" (mos-debug-test t))
                       ("mos.debugSingleTest" (mos-debug-test nil)))
  ;; :download-server-fn (lambda (_client callback error-callback _update?)
  ;;                       (lsp-package-ensure 'mos callback error-callback)
  ))

(defun mos-mode-populate-debug-args (conf)
  "Populate default settings for debug adapter.
CONF is the current configuration sent by `dap-mode` functions."
  (-> conf
      (dap--put-if-absent :type "mos")
      (dap--put-if-absent :request "launch")
      (dap--put-if-absent :workspace (lsp-workspace-root))
      (dap--put-if-absent :host "127.0.0.1")
      (dap--put-if-absent :debugServer 6503)))

(dap-register-debug-provider "mos" #'mos-mode-populate-debug-args)

(provide 'mos-mode)
;;; mos-mode.el ends here
