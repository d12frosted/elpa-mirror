;;; veri-kompass.el --- verilog codebase navigation facility -*- lexical-binding:t -*-

;; Copyright (C) 2018 Andrea Corallo

;; Maintainer: andrea_corallo@yahoo.it
;; Package: veri-kompass
;; Homepage: https://gitlab.com/koral/veri-kompass
;; Version: 0.2
;; Package-Version: 20200213.934
;; Package-Commit: 271903cdf92db05898ee7cffb65641f30fa08280
;; Package-Requires: ((emacs "25") (cl-lib "0.5") (org "8.2.0"))
;; Keywords: languages, extensions, verilog, hardware, rtl

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Provide verilog codebase navigation facility.
;; Including a hierarchy sidebar and functions to follow drivers and loads
;; within the design.

;;; Code:

(require 'custom)
(require 'cl-macs)
(require 'pcase)
(require 'sort)
(require 'cl-extra)
(require 'files)
(require 'format)
(require 'whitespace)
(require 'simple)
(require 'message)
(require 'thingatpt)
(require 'org)
(require 'easy-mmode)
(require 'derived)
(require 'hashtable-print-readable)

(defgroup veri-kompass nil
  "Customization options for veri-kompass."
  :prefix "veri-kompass"
  :group 'languages)

(defcustom veri-kompass-top ""
  "Default top module name."
  :type 'string
  :group 'veri-kompass)

(defcustom veri-kompass-extention-regexp ".+\\.s?v$"
  "Regexp matching project files."
  :type 'string
  :group 'veri-kompass)

(defcustom veri-kompass-skip-regexp "^.*CONFORMTO.*$"
  "Regexp matching files to be skip."
  :type 'string
  :group 'veri-kompass)

(defface veri-kompass-inst-marked-face
  '((t :foreground "red1"))
  "Face for marking instance selected."
  :group 'veri-kompass)

(defvar veri-kompass-module-list nil)

(defvar veri-kompass-module-hier nil)

(defvar veri-kompass-mod-str-hash nil
  "This hash contains module structure hashed per module name.")

(defconst veri-kompass-bar-name "*veri-kompass-bar*")

(defconst veri-kompass-ignore-keywords '("if" "task" "assert" "disable" "define" "posedge"
                                         "negedge" "int" "for" "logic" "wire" "reg"))

(defconst veri-kompass-sym-regex "[0-9a-z_]+")

(defconst veri-kompass-ops-regex "[\]\[ ()|&\+-/%{}=<>]")

(defconst veri-kompass-module-start-regexp "module[[:space:]\n]+\\([0-9a-z_]+\\)")

(defconst veri-kompass-module-end-regexp "^[[:space:]]*endmodule")

(defvar veri-kompass-hier nil
  "Holds the design hierarchy.")

(defvar veri-kompass-curr-select nil
  "Holds the position of the current instance selected (if any).")

(defvar veri-kompass-history nil
  "Holds the instance selection history.")

(cl-defstruct (veri-kompass-mod-inst (:copier nil))
  "Holds a module instantiations."
  inst-name mod-name file-name line)

(defmacro veri-kompass-within-current-module (&rest code)
  "Execute code CODE narrowing into the current module definition."
  `(let* ((point-orig (point))
          (start (re-search-backward veri-kompass-module-start-regexp nil t))
          (end (re-search-forward veri-kompass-module-end-regexp nil t)))
     (goto-char point-orig)
     (if (and start end)
         (save-restriction
           (narrow-to-region start end)
           ,@code)
       (error "Not in a module definition?"))))

(defmacro veri-kompass-make-thread (f)
  "Make thread if threading is available.
Argument F is the thread name."
  (if (fboundp 'make-thread)
      `(make-thread ,f)
    `(funcall ,f)))

(defmacro veri-kompass-thread-yield ()
  "Yield a thread if threading is available."
  (when (fboundp 'thread-yield)
    '(thread-yield)))

(defun veri-kompass-completing-read (msg candidates &optional buff-name)
  "Complete user input between CANDIDATES using helm if available.
MSG is a string to prompt with.
BUFF-NAME is the buffer name created in case helm is used."
  (if (fboundp 'helm)
      (progn
	(require 'helm-source)
	(helm :sources (helm-build-sync-source msg
			 :candidates candidates)
	      :buffer buff-name))
    (completing-read msg candidates)))

(defun veri-kompass-sym-classify-at-point ()
  "Classify if a symbol is l-val or r-val."
  (save-excursion
    (re-search-forward "[=;]" nil t)
    (pcase (aref (match-string-no-properties 0) 0)
      (?\= 'l-val)
      (?\; 'r-val))))

(defun veri-kompass-sym-at-point ()
  "Return an a-list containing (sym-name . 'r-val) or (sym-name . 'l-val)."
  (save-excursion
    (re-search-backward veri-kompass-ops-regex nil t)
    (re-search-forward veri-kompass-sym-regex nil t)
    (cons (match-string-no-properties 0) (veri-kompass-sym-classify-at-point))))

(defun veri-kompass-search-driver (sym &optional internal)
  "Given the symbol SYM search for it's driver.
INTERNAL if the search is limited to the current module."
  (save-excursion
    (let ((point-orig (point)))
      (goto-char (point-min))
      ;; First case is easy, in case is a module input.
      (if (re-search-forward (concat
                              "input +\\(wire +\\)?\\(logic +\\)?\\[*.*\] +\\("
                              sym
                              "\\)")
                             nil t)
          (if (and (equal (match-beginning 3) point-orig) (not internal))
              'go-up
            (list (cons (match-string 0) (match-beginning 3))))
        (if (re-search-forward (concat "input +\\(wire +\\)?\\(logic +\\)?\\("
                                       sym
                                       "\\)")
                               nil t)
            (if (and (equal (match-beginning 3) point-orig) (not internal))
                'go-up
              (list (cons (match-string 0) (match-beginning 3))))
          (goto-char (point-max))
          ;; Here we handle direct assignments.
          (let ((res ()))
            (while (re-search-backward
                    (concat
                     "\\(\\<"
                     sym
                     "\\>\\)[[:space:]]*\\(\\[.*\\] +\\)?\\(=\\|<=\\)[^=].*")
                    nil t)
              (push (cons (match-string 0)
                          (match-beginning 0))
                    res))
            (if res
                res
              ;; Otherwise is coming from e submodule. TODO: check input/output!
              (while (re-search-backward
                      (concat
                       "\\..+([[:space:]]*\\("
                       sym
                       "\\)\\(\\[.*\\][[:space:]]*\\)?)")
                      nil t)
                (push (cons (match-string 0)
                            (match-beginning 1))
                      res))
              res)))))))

(defun veri-kompass-search-driver-at-point ()
  "Goto the driver for symbol at point."
  (interactive)
  (veri-kompass-within-current-module
   (let ((res (veri-kompass-search-driver (car (veri-kompass-sym-at-point)))))
     (when res
       (if (eq res 'go-up)
           (veri-kompass-go-up-from-point)
         (if (equal (length res) 1)
             (goto-char (cdar res))
           (goto-char
	    (veri-kompass-completing-read "select driver line: "
					  res
					  "*veri-kompass-driver-select*"))))))))

(defun veri-kompass-module-name-at-point ()
  "Return the module containing the current point."
  (save-excursion
    (forward-word 2)
    (re-search-backward veri-kompass-module-start-regexp)
    (match-string-no-properties 1)))

(defun veri-kompass-search-load (sym)
  "Given the simbol SYM search for all its loads."
  (save-excursion
    (let ((loads ())
          (drivers (mapcar #'cdr (veri-kompass-search-driver sym 'internal))))
      (goto-char (point-max))
      (while (re-search-backward (concat "^.*\\(\\<" sym "\\>\\).*") nil t)
        (unless (member (match-beginning 1) drivers)
          (push (cons (match-string 0) (match-beginning 1))
                loads)))
      loads)))

(defun veri-kompass-search-load-at-point ()
  "Goto the loads for symbol at point."
  (interactive)
  (veri-kompass-within-current-module
   (let ((res (veri-kompass-search-load (car (veri-kompass-sym-at-point)))))
     (when res
       (if (equal (length res) 1)
           (goto-char (cdar res))
         (goto-char
	  (veri-kompass-completing-read "select load line: "
					res
					"*veri-kompass-load-select*")))))))

(defun veri-kompass-follow-from-point ()
  "Follow symbol at point.
If is an l-val search for loads, if r-val search for drivers."
  (interactive)
  (let ((sym (veri-kompass-sym-at-point)))
    (pcase (cdr sym)
      ('l-val (veri-kompass-search-load-at-point))
      ('r-val (veri-kompass-search-driver-at-point)))))


(defun veri-kompass-directory-files-recursively-with-symlink (dir regexp &optional include-directories)
  "This function is a variant of ‘directory-files-recursively’ from files.el.
Return list of all files under DIR that have file names matching REGEXP.
This function works recursively following symlinks.
Files are returned in \"depth first\" order, and files from each directory are
 sorted in alphabetical order.
Each file name appears in the returned list in its absolute form.
Optional argument INCLUDE-DIRECTORIES non-nil means also include in the
output directories whose names match REGEXP."
  (let ((result nil)
        (files nil)
        ;; When DIR is "/", remote file names like "/method:" could
        ;; also be offered.  We shall suppress them.
        (tramp-mode (and tramp-mode (file-remote-p (expand-file-name dir)))))
    (dolist (file (sort (file-name-all-completions "" dir)
                        'string<))
      (unless (member file '("./" "../"))
        (if (directory-name-p file)
            (let* ((leaf (substring file 0 (1- (length file))))
                   (full-file (expand-file-name leaf dir)))
              (setq result
                    (nconc result (directory-files-recursively
                                   full-file regexp include-directories)))
              (when (and include-directories
                         (string-match regexp leaf))
                (setq result (nconc result (list full-file)))))
          (when (string-match regexp file)
            (push (expand-file-name file dir) files)))))
    (nconc result (nreverse files))))

(defun veri-kompass-list-file-in-proj (dir)
  "Return a list of all project files present in DIR ver.excluding the one specified by ‘veri-kompass-skip-regexp’."
  (remove nil
          (mapcar (lambda (x)
                    (if (or (string-match "/\\." x)
                            (string-match veri-kompass-skip-regexp x))
                        nil
                      x))
                  (veri-kompass-directory-files-recursively-with-symlink
                   dir veri-kompass-extention-regexp))))

(defun veri-kompass-list-modules-in-file (file)
  "Return the list of all declared modules present in FILE."
  (with-temp-buffer
    (insert-file-contents-literally file)
    (let ((mod-list))
      (while (re-search-forward
              "^[[:space:]]*module[[:space:]\n]+\\([0-9a-z_]+\\)[[:space:]]*\n*[[:space:]]*\\((\\|#(\\|`\\|;\\)" nil t)
        (push (list
               (match-string-no-properties 1)
               file
               (point)
               (line-number-at-pos (point))
               (match-string-no-properties 0))
              mod-list))
      mod-list)))

(defun veri-kompass-list-modules-in-proj (files)
  "Return the list of all declared modules present in FILES."
  (remove nil
          (cl-mapcan 'veri-kompass-list-modules-in-file files)))

(defun veri-kompass-mod-to-file-name-pos (name)
  "Given the module name NAME return its position." ;; improve
  (cdr (assoc name veri-kompass-module-list)))

(defun veri-kompass-mark-comments ()
  "Scanning a buffer mark all comments with property 'comment."
  (interactive)
  (save-mark-and-excursion
    (goto-char (point-min))
    (while (re-search-forward "//.*" nil t) ;; TODO add other comment style
      (put-text-property (match-beginning 0) (point) 'comment t))))

(defsubst veri-kompass-mark-code-blocks ()
  "Mark all text within code blocks with property 'code."
  (interactive)
  (save-mark-and-excursion
    (veri-kompass-mark-comments)
    (goto-char (point-min))
    (while (search-forward "begin" nil t)
      (unless (get-char-property 0 'comment (match-string 0))
        (backward-word)
        (set-mark (point))
        (forward-word)
        (let ((nest 1))
          (while (> nest 0)
            (re-search-forward "\\(begin\\|end$\\|end \\)" nil t)
            (setq nest (if (and (equal (match-string 1) "begin")
                                (not (get-char-property
                                      0
                                      'comment
                                      (match-string 0))))
                           (1+ nest)
                         (1- nest)))))
        (put-text-property (mark) (point) 'code t)))))

(defsubst veri-kompass-forward-balanced ()
  "After an opening parenthesys find the matching closing one."
  (save-match-data
    (let ((x 1))
      (while (and (> x 0)
                  (re-search-forward "\\((\\|)\\)" nil t))
        (if (equal (match-string 0) "(")
            (setq x (1+ x))
          (setq x (1- x)))))))

(defsubst veri-kompass-delete-parameters ()
  "Remove all #( ... )."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "#(" nil t)
      (veri-kompass-forward-balanced)
      (delete-region (match-beginning 0) (point)))))

(defsubst veri-kompass-remove-macros ()
  "Remove all `SOMETHIING ."
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "`[a-z_0-9]+" nil t)
      (unless (equal (match-string 0) "`define")
        (delete-region (match-beginning 0) (match-end 0))))))

(defun veri-kompass-retrive-original-line (inst-name mod-name content)
  "Given instance name INST-NAME module name MOD-NAME and the original buffer instantiation content CONTENT return the module instantiation line."
  (save-match-data
    (with-temp-buffer
      (insert content)
      (goto-char (point-min))
      (or (re-search-forward
           (format
            "\\<%s\\>[ a-z-0-9_.#(),\n]*\\<%s\\>"
            inst-name
            mod-name) nil t)
          (search-forward inst-name))
      (line-number-at-pos (match-beginning 0)))))

(defun veri-kompass-build-hier-rec (mod-name)
  "Given MOD-NAME return a list rappresenting the design hierarchy.
This recursive function call itself walking all the verilog design."
  (veri-kompass-thread-yield)
  (if (gethash mod-name veri-kompass-mod-str-hash) ;; some memoization is gonna help
      (gethash mod-name veri-kompass-mod-str-hash)
    (puthash
     mod-name
     (let ((target (veri-kompass-mod-to-file-name-pos mod-name))
           (struct)
           (orig-buff))
       (if target
           (with-temp-buffer
             (insert-file-contents-literally (car target))
             (setq orig-buff (buffer-string))
             (goto-char (cadr target))
             (set-mark (point))
             (re-search-forward veri-kompass-module-end-regexp nil t)
             (narrow-to-region (mark) (point))
             (veri-kompass-thread-yield)
             (veri-kompass-delete-parameters)
             (veri-kompass-thread-yield)
             (veri-kompass-remove-macros)
             (veri-kompass-thread-yield)
             (veri-kompass-mark-code-blocks)
             (veri-kompass-thread-yield)
             (goto-char (point-min))
             (while (re-search-forward
                     "\\([0-9a-z_]+\\)[[:space:]]+\\([0-9a-z_]+\\)[[:space:]]*("  nil t)
               (when (save-match-data
                       (veri-kompass-thread-yield)
                       (veri-kompass-forward-balanced)
                       (looking-at "[[:space:]]*;"))
                 (unless (or (get-char-property 0 'code (match-string 0))
                             (get-char-property 0 'comment (match-string 0))
                             (char-equal (aref (match-string-no-properties 1) 0)
                                         ?\`)
                             (member (match-string-no-properties 1)
                                     veri-kompass-ignore-keywords)
                             (member (match-string-no-properties 2)
                                     veri-kompass-ignore-keywords))
                   (veri-kompass-thread-yield)
                   (push (make-veri-kompass-mod-inst
                          :mod-name (match-string-no-properties 1)
                          :inst-name (match-string-no-properties 2)
                          :file-name (car target)
                          :line (veri-kompass-retrive-original-line (match-string 1)
                                                                    (match-string 2)
                                                                    orig-buff)) struct)
                   (let ((sub-hier
                          (veri-kompass-build-hier-rec
                           (match-string-no-properties 1))))
                     (when sub-hier
                       (push sub-hier struct)))
                   )))
             (reverse struct))
         (message "Cannot find module %s" mod-name)
         nil))
     veri-kompass-mod-str-hash)))

(defun veri-kompass-build-hier (top)
  "Given a TOP module return the hierarcky.
This is the entry point function for parsing the design."
  (let ((target (veri-kompass-mod-to-file-name-pos top)))
    (if target
        (list (make-veri-kompass-mod-inst
               :inst-name top
               :mod-name top
               :file-name (car target)
               :line (caddr target))
              (veri-kompass-build-hier-rec top))
      (message "Cannot find top module %s" top))))

(defun veri-kompass-orgify-link (inst)
  "Given a module instance INST return an org link."
  (let ((coords (veri-kompass-mod-to-file-name-pos (veri-kompass-mod-inst-mod-name inst))))
    (if coords
        (format "[[%s::%s][%s]] [[%s::%s][%s]]"
                (veri-kompass-mod-inst-file-name inst)
                (veri-kompass-mod-inst-line inst)
                (veri-kompass-mod-inst-inst-name inst)
                (nth 0 coords)
                (with-temp-buffer
                  (insert (nth 3 coords))
                  (re-search-backward "module.*$" nil t)
                  (match-string 0))
                (veri-kompass-mod-inst-mod-name inst))
      (veri-kompass-mod-inst-inst-name inst))))

(defun veri-kompass-orgify-hier (hier nest)
  "Given an hierarcky HIER and a nesting level NEST produce an org rappresentation of the hierarcky."
  (mapconcat (lambda (h)
               (if (consp h)
                   (veri-kompass-orgify-hier h (1+ nest))
                 (format "%s %s" (let ((x ""))
                                   (dotimes (_ nest)
                                     (setq x (concat x "*")))
                                   x)
                         (veri-kompass-orgify-link h)))) hier "\n"))

(defun veri-kompass-compute-and-create-bar (top-name)
  "Given a top module TOP-NAME create and populate the hierarky bar."
  (setq veri-kompass-hier (veri-kompass-build-hier top-name))
  (message "Parsing done.")
  (switch-to-buffer-other-window veri-kompass-bar-name)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (veri-kompass-orgify-hier veri-kompass-hier 1)))
  (read-only-mode)
  (veri-kompass-mode)
  (highlight-regexp "->\\|<-" 'veri-kompass-inst-marked-face)
  (whitespace-turn-off))

(defun veri-kompass-open-at-point (&rest _)
  "Follow link into the hierarchy bar."
  (interactive)
  (org-open-at-point)
  (window-buffer))

(defun veri-kompass-curr-mark ()
  "Return a pair (module-name . instance-name) for the current mark."
  (if veri-kompass-curr-select
      (save-excursion
        (switch-to-buffer-other-window veri-kompass-bar-name)
        (goto-char (point-min))
        ;; enjoy
        (re-search-forward "-> \\[\\[.*\\]\\[\\(.*\\)\\]\\] \\[\\[.*\\]\\[\\(.*\\)\\]\\] <-")
        (cons (match-string-no-properties 2)
              (match-string-no-properties 1)))
    (message "Select an instance first.")
    nil))

(defun veri-kompass-unmark ()
  "Remove mark on current instance selected."
  (interactive)
  (with-current-buffer veri-kompass-bar-name
    (save-excursion
      (when veri-kompass-curr-select
        (let ((inhibit-read-only t))
          (goto-char (point-min))
          (re-search-forward " ->" nil t)
          (replace-match "")
          (re-search-forward " <-" nil t)
          (replace-match "")
          (setq veri-kompass-curr-select nil))))))

(defun veri-kompass-mark ()
  "Mark the instance at point."
  (interactive)
  (with-current-buffer veri-kompass-bar-name
    (veri-kompass-mark-and-jump)
    (switch-to-buffer-other-window veri-kompass-bar-name)))

(defun veri-kompass-mark-and-jump ()
  "Mark the instance at point and jump to its definition."
  (interactive)
  (with-current-buffer veri-kompass-bar-name
    (when veri-kompass-curr-select
      (veri-kompass-unmark))
    (let ((inhibit-read-only t))
      (re-search-backward "^")
      (re-search-forward "\\*+")
      (setq veri-kompass-curr-select (point))
      (unless (equal (car veri-kompass-history) (point)) ;; should count lines
        (push (point) veri-kompass-history))
      (insert " ->")
      (re-search-forward "$")
      (insert " <-")
      (backward-char 4)
      (veri-kompass-open-at-point))))

(defun veri-kompass-go-backward ()
  "Move backward into the instance selection history."
  (interactive)
  (if veri-kompass-history
      (progn
        (setq veri-kompass-history (cdr veri-kompass-history))
        (with-current-buffer veri-kompass-bar-name
          (veri-kompass-unmark)
          (when (car veri-kompass-history)
            (goto-char (car veri-kompass-history))
            (veri-kompass-mark))))
    (message "History is empty")))

(defun veri-kompass-go-up (&optional jump)
  "Move up into the hierarchy.
If JUMP is not nil follow link too."
  (interactive)
  (with-current-buffer veri-kompass-bar-name
    (if veri-kompass-curr-select
        (progn
          (goto-char veri-kompass-curr-select)
          (veri-kompass-unmark)
          (org-up-element)
          (if jump
              (veri-kompass-mark-and-jump)
            (veri-kompass-mark)))
      (message "Select an instance first."))))

(defun veri-kompass-go-up-from-point ()
  "Move up into the hierarchy starting from point into a verilog file."
  (interactive)
  (if veri-kompass-curr-select ;; sanity check missing
      (let* ((signal-name (word-at-point))
             (curr-mark (veri-kompass-curr-mark))
             (mark-mod (car curr-mark))
             (mark-inst (cdr curr-mark))
             (module-name (veri-kompass-module-name-at-point)))
        (if (not (equal module-name mark-mod))
            (print "Marked module is different from current one.")
          (set-buffer (veri-kompass-go-up 'jump))
          (search-forward mark-inst)
          (re-search-forward
           (concat "\\." signal-name "[[:space:]]*\\((\\|\n\\)"))))
    "Please mark current instance into hierarchy buffer."))

(defun veri-kompass-full-mark-position()
  "Return a list with the current instance position in the hierarchy."
  (save-excursion
    (let ((res)
          (p))
      (while
          (progn
            (re-search-backward "^")
            (setq p (point))
            (search-forward "][")
            (re-search-forward "\\(.*\\)]] ")
            (push
             (match-string-no-properties 1) res)
            (unless (equal p (point-min))
              (org-up-element)
              t)))
      res)))

;;;###autoload
(defun veri-kompass (dir &optional top-name)
  "Enable Veri-Kompass.
Veri-Kompass is a verilog codebase navigation facility.
The codebase to be parsed will be in directory DIR.
The decendent parsing will start from module TOP-NAME."
  (interactive "D")
  (setq veri-kompass-mod-str-hash (make-hash-table :test 'equal))
  (setq veri-kompass-module-list
        (veri-kompass-list-modules-in-proj
         (veri-kompass-list-file-in-proj dir)))
  (unless top-name
    (setq top-name
	  (veri-kompass-completing-read "specify top module: "
					(mapcar (lambda (x)
						  (car x))
						veri-kompass-module-list)
					"*veri-kompass-module-top-select*")))
  (message "Parsing design...")
  (veri-kompass-make-thread (lambda ()
                              (veri-kompass-compute-and-create-bar top-name))))

(define-minor-mode veri-kompass-minor-mode
  "Minor mode to be used into verilog files."
  :lighter " VK"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c d") 'veri-kompass-search-driver-at-point)
            (define-key map (kbd "C-c l") 'veri-kompass-search-load-at-point)
            map))

(defvar veri-kompass-mode-map nil "Keymap for `veri-kompass-mode'.")

(progn
  (setq veri-kompass-mode-map (make-sparse-keymap))
  (define-key veri-kompass-mode-map (kbd "o") 'veri-kompass-open-at-point)
  (define-key veri-kompass-mode-map (kbd "m") 'veri-kompass-mark)
  (define-key veri-kompass-mode-map (kbd "RET") 'veri-kompass-mark-and-jump)
  (define-key veri-kompass-mode-map (kbd "u") 'veri-kompass-go-up)
  (define-key veri-kompass-mode-map (kbd "q") 'veri-kompass-unmark)
  (define-key veri-kompass-mode-map (kbd "b") 'veri-kompass-go-backward)
  (define-key veri-kompass-mode-map (kbd "C-S-<right>")
    'enlarge-window-horizontally)
  (define-key veri-kompass-mode-map (kbd "C-S-<left>")
    'shrink-window-horizontally))

(define-derived-mode
  veri-kompass-mode
  org-mode
  "Veri-Kompass"
  "Generate and handle verilog project hierarchy.")

(provide 'veri-kompass)

;;; veri-kompass.el ends here
