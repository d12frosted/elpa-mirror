;;; php-boris.el --- Run boris php REPL

;; Copyright (C) 2013 Tom Regner
;; Copyright (C) 2012-2013  Takeshi Arabiki

;;
;; Author: Tom Regner
;;
;; Based on nodejs-repl.el
;; (based on as in "stolen, repainted and sold for new" :-D )
;; by Author: Takeshi Arabiki
;; Maintainer: Tom Regner <tom@goochesa.de>
;;
;; Version: 0.0.1
;; Package-Version: 20130527.821
;; Package-Commit: 4bb7e4d34d9906ddce688205eb24cafe634c6d06
;;          See `php-boris-version'
;; Keywords: php, commint, repl, boris

;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This program is derived from comint-mode and provides the following features.
;;
;;  * file name completion in string
;;  * incremental history search
;;
;;
;; Put this file in your Emacs lisp path (e.g. ~/.emacs.d/site-lisp)
;; and add the following line to your .emacs:
;;
;;    (require 'php-boris)
;;
;; Type M-x php-boris to run boris php REPL.
;; See also `comint-mode' to check key bindings.
;;

(require 'cc-mode)
(require 'comint)
(require 'ansi-color)

(defgroup php-boris nil
  "Run boris REPL and communicate the process."
  :group 'processes)

(defconst php-boris-version "0.0.1"
  "php-boris mode Version.")

(defcustom php-boris-command "boris"
  "boris command used in `php-boris-mode'."
  :group 'php-boris
  :type 'string)

(defcustom php-boris-prompt "\\[\\d+\\] boris> "
  "boris prompt used in `php-boris-mode'."
  :group 'php-boris
  :type 'string)

(defvar php-boris-process-name "boris-repl"
  "process name of boris REPL.")

(defvar php-boris-temp-buffer-name "*php-boris-command-output*")

(defvar php-boris-mode-syntax-table
  (let ((st (make-syntax-table)))
    (c-populate-syntax-table st)
    (modify-syntax-entry ?$ "_" st)
    st))

(defvar php-boris-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "TAB") 'comint-dynamic-complete)
    (define-key map (kbd "C-c C-c") 'php-boris-quit-or-cancel)
    map))

;; process.stdout.columns should be set.
;; but process.stdout.columns in Emacs is infinity because Emacs returns 0 as winsize.ws_col.
;; The completion candidates won't be displayed if process.stdout.columns is infinity.
;; see also `handleGroup` function in readline.js
(defvar php-boris-code "")


(defvar php-boris-input-ignoredups t
  "If non-nil, don't add input matching the last on the input ring.

See also `comint-input-ignoredups'")

(defvar php-boris-process-echoes t
  "If non-nil, boris does not echo any input.

See also `comint-process-echoes'")

(defvar php-boris-extra-espace-sequence-re "\\(\x1b\\[[0-9]+[GJK]\\)")
(defvar php-boris-ansi-color-sequence-re "\\(\x1b\\[[0-9]+m\\)")
;;; if send string like "a; Ma\t", return a; Math\x1b[1G> a; Math\x1b[0K\x1b[10G
(defvar php-boris-prompt-re-format
  (concat
   "\x1b\\[1G"
   "\\("
   "\x1b\\[0J%s.*\x1b\\[[0-9]+G"  ; for Node.js 0.8
   "\\|"
   "%s.*\x1b\\[0K\x1b\\[[0-9]+G"  ; for Node.js 0.4 or 0.6
   "\\)"
   "$"))
(defvar php-boris-prompt-re
  (format php-boris-prompt-re-format php-boris-prompt php-boris-prompt))
;;; not support Unicode characters
(defvar php-boris-require-re
  (concat
   "\\(?:^\\|\\s-\\|[-+*/%&|><!;{}()[]\\|\\]\\)"  ; delimiter
   "require\\s-*(\\s-*"
   "\\("
   "\"[^\"\\]*\\(?:\\\\.[^\"\\]*\\)*"             ; double quote
   "\\|"
   "'[^'\\]*\\(?:\\\\.[^'\\]*\\)*"                ; single quote
   "\\)"
   "$"))

(defvar php-boris-cache-token "")
(defvar php-boris-cache-candidates ())


;;;--------------------------
;;; Private functions
;;;--------------------------
(defun php-boris--in-string-p (&optional pos)
  "Return non-nil if point is inside string"
  (nth 3 (syntax-ppss pos)))

(defun php-boris--extract-require-argument (string)
  (if (string-match php-boris-require-re string)
      (match-string 1 string)))

(defun php-boris--get-last-token (string)
  "Return the last token in the string."
  (if (string-match "\\([._$]\\|\\w\\)+$" string)
      (match-string 0 string)))

;;; TODO:
;;; * the case that a command is sent while another command is being prossesed
;;; * the case that incomplete commands are sent like "1 +\n"
;;; * support commands which output a string without CR-LF like process.stdout.write("a")
;;;   while being processed
(defun php-boris--send-string (string)
  "Send string to boris process and return the output."
  (with-temp-buffer
    (let* ((proc (get-process php-boris-process-name))
           (orig-marker (marker-position (process-mark proc)))
           (orig-filter (process-filter proc))
           (orig-buf (process-buffer proc)))
      (unwind-protect
          (progn
            (set-process-buffer proc (current-buffer))
            (set-process-filter proc 'php-boris--insert-and-update-status)
            (set-marker (process-mark proc) (point-min))
            (process-send-string proc string)
            (php-boris--wait-for-process proc string 0.01))
        (set-process-buffer proc orig-buf)
        (set-process-filter proc orig-filter)
        (set-marker (process-mark proc) orig-marker orig-buf))
      (buffer-string))))

(defun php-boris--wait-for-process (proc string interval)
  "Wait for boris process to output all results."
  (process-put proc 'last-line "")
  (process-put proc 'running-p t)
  ;; trim trailing whitespaces
  (setq string (replace-regexp-in-string "\\s-*$" "" string))
  ;; TODO: write unit test for the case that the process returns 'foo' when string is 'foo\t'
  (while (or (process-get proc 'running-p)
             (not
              (let ((last-line (process-get proc 'last-line)))
                (or (string-match-p php-boris-prompt-re last-line)
                    (string-match-p "^\x1b[[0-9]+D$" last-line)  ; for Node.js 0.8
                    (string= last-line string)))))
    (process-put proc 'running-p nil)
    (accept-process-output proc interval)))

(defun php-boris--insert-and-update-status (proc string)
  "Insert the output string and update the process status (properties)
when receive the output string"
  (process-put proc 'running-p t)
  (with-current-buffer (process-buffer proc)
    (insert string)
    (goto-char (point-max))
    (process-put proc 'last-line (buffer-substring (point-at-bol) (point)))))

(defun php-boris--get-candidates-from-process (token)
  "Get copmletion candidates sending TAB to boris process."
  (let ((ret (php-boris--send-string (concat token "\t")))
         candidates)
    (php-boris-clear-line)
    (when (not (equal ret token))
      (if (string-match-p "\n" ret)
          (progn
            ;; remove extra substrings
            (setq ret (replace-regexp-in-string "\r" "" ret))
            ;; remove LF
            (setq ret (replace-regexp-in-string "\n\\{2,\\}" "\n" ret))
            ;; trim trailing whitespaces
            (setq ret (replace-regexp-in-string "\\s-*$" "" ret))
            ;; don't split by whitespaces because the prompt may has whitespaces!!
            (setq candidates (split-string ret "\n"))
            ;; remove the first element (input) and the last element (prompt)
            (setq candidates (reverse (cdr (reverse (cdr candidates)))))
            ;; split by whitespaces
            ;; '("encodeURI     encodeURIComponent") -> '("encodeURI" "encodeURIComponent")
            (setq candidates (split-string (mapconcat 'identity candidates " ") "\\s-+")))
        (setq ret (replace-regexp-in-string php-boris-extra-espace-sequence-re "" ret))
        (setq candidates (list (php-boris--get-last-token ret)))))
    candidates))


;;;--------------------------
;;; Public functions
;;;--------------------------
(defun php-boris-quit-or-cancel ()
  "Send ^C to boris process."
  (interactive)
  (process-send-string (get-process "boris") "\x03"))

(defun php-boris-clear-line ()
  "Send ^U to boris process."
  (php-boris--send-string "\x15"))

(defun php-boris-execute (command &optional buf)
  "Execute a command and output the result to the temporary buffer."
  (let ((ret (php-boris--send-string (concat command "\n"))))
    (with-current-buffer (get-buffer-create php-boris-temp-buffer-name)
      (erase-buffer)
      (setq ret (replace-regexp-in-string php-boris-ansi-color-sequence-re "" ret))
      ;; delete inputs
      (setq ret (replace-regexp-in-string "\\(\\w\\|\\W\\)+\r\r\n" "" ret))
      (setq ret (replace-regexp-in-string "\r" "" ret))
      (insert ret)
      ;; delete last line (prompt)
      (goto-char (point-max))
      (delete-region (point-at-bol) (point)))))

(defun php-boris-complete-from-process ()
  "Dynamically complete tokens at the point."
  (when (comint-after-pmark-p)
    (let* ((input (buffer-substring (comint-line-beginning-position) (point)))
           require-arg
           token
           candidates
           ret)
      (if (php-boris--in-string-p)
          (progn
            (setq require-arg (php-boris--extract-require-argument input))
            (if (and require-arg
                     (or (= (length require-arg) 1)
                         (not (string-match-p "[./]" (substring require-arg 1 2)))))
                (setq token (concat "require(" require-arg))
              (setq ret (comint-dynamic-complete-as-filename))))
        (setq token (php-boris--get-last-token input)))
      (when token
        (setq candidates (php-boris-get-candidates token))
        ;; TODO: write unit test
        (setq token (replace-regexp-in-string "^require(['\"]" "" token))
        (setq ret (comint-dynamic-simple-complete token candidates)))
      (if (eq ret 'sole)
          (delete-char -1))
      ret)))

(defun php-boris-get-candidates (token)
  "Get completion candidates."
  (let (candidates)
    (if (and (not (equal php-boris-cache-token ""))
             (string-match-p (concat "^" php-boris-cache-token) token)
             (not (string-match-p (concat "^" php-boris-cache-token ".*?[.(/'\"]") token)))
        (setq candidates php-boris-cache-candidates)
      (if (equal token "require(")  ; a bug occurs when press TAB after "require(" in node 0.6
          (setq candidates nil)
        (setq candidates (php-boris--get-candidates-from-process token)))
      (setq php-boris-cache-token token)
      (setq php-boris-cache-candidates candidates))
    candidates))

;;; a function belong to comint-output-filter-functions must have one argument
(defun php-boris-filter-escape-sequnces (string)
  "Filter extra escape sequences from output."
  (let ((beg (or comint-last-output-start
                 (point-min-marker)))
        (end (process-mark (get-buffer-process (current-buffer)))))
    (save-excursion
      (goto-char beg)
      ;; remove ansi escape sequences used in readline.js
      (while (re-search-forward php-boris-extra-espace-sequence-re end t)
        (replace-match "")))))

;;; a function belong to comint-output-filter-functions must have one argument
(defun php-boris-clear-cache (string)
  "Clear caches when outputting the result."
  (setq php-boris-cache-token "")
  (setq php-boris-cache-candidates ()))


(define-derived-mode php-boris-mode comint-mode "boris REPL"
  "Major mode for boris php REPL"
  :syntax-table php-boris-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults) '(nil nil t))
  (add-hook 'comint-output-filter-functions 'php-boris-filter-escape-sequnces nil t)
  (add-hook 'comint-output-filter-functions 'php-boris-clear-cache nil t)
  (setq comint-input-ignoredups php-boris-input-ignoredups)
  (setq comint-process-echoes php-boris-process-echoes)
  ;; delq seems to change global variables if called this phase
  (set (make-local-variable 'comint-dynamic-complete-functions)
       (delete 'comint-dynamic-complete-filename comint-dynamic-complete-functions))
  (add-hook 'comint-dynamic-complete-functions 'php-boris-complete-from-process nil t)
  (ansi-color-for-comint-mode-on))

;;;###autoload
(defun php-boris ()
  "Run boris REPL."
  (interactive)
  (setq php-boris-prompt-re
        (format php-boris-prompt-re-format php-boris-prompt php-boris-prompt))
  (switch-to-buffer-other-window
   (apply 'make-comint php-boris-process-name php-boris-command nil
          `("-e" ,(format php-boris-code (window-width) php-boris-prompt))))
  (php-boris-mode))

(provide 'php-boris)
;;; php-boris.el ends here
