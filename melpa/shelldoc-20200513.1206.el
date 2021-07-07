;;; shelldoc.el --- shell command editing support with man page.

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: applications
;; Package-Version: 20200513.1206
;; Package-Commit: fa69f67b6229fad3f31d936955ca8d1982009b77
;; URL: http://github.com/mhayashi1120/Emacs-shelldoc
;; Version: 0.1.3
;; Package-Requires: ((cl-lib "0.3") (s "1.9.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; ## Install

;; Please install this package from MELPA. (https://melpa.org/)

;; Otherwise, put this file into load-path'ed directory.
;; And put the following expression into your ~/.emacs.
;; You may need some extra packages.

;;     (require 'shelldoc)

;; Now you can see man page when `read-shell-command` is invoked.
;; e.g. M-x shell-command
;; `C-v` / `M-v` to scroll the man page window.
;; `C-c C-s` / `C-c C-r` to search the page.

;; You can complete `-` (hyphen) option at point.
;; Try to type C-i after insert `-`.

;; ## Configuration

;; * To show original man page initially. (probably english)

;;     (setq shelldoc-keep-man-locale nil)

;; * You may install new man page after shelldoc:

;;     M-x shelldoc-clear-cache

;; * shelldoc is working as a minor mode if you desire.

;;  * eshell

;;     (add-hook 'eshell-mode-hook 'shelldoc-minor-mode-on)

;;  * sh-mode (editing shell script)

;;     (add-hook 'sh-mode-hook 'shelldoc-minor-mode-on)

;;  * M-x shell

;;     (add-hook 'shell-mode-hook 'shelldoc-minor-mode-on)

;; * To toggle shelldoc feature.

;;     M-x shelldoc

;;; TODO:
;; * multilingual man page
;; * support tramp (`call-process' -> `process-file' consider cache key)
;; * show what the man page is. in mode-line.

;;; Code:

(require 'cl-lib)
(require 'man)
(require 's)
(require 'advice)
(require 'shell)

(defgroup shelldoc ()
  "shell command editing support with man page."
  :group 'applications
  :prefix "shelldoc-")

(put 'shelldoc-quit 'error-conditions '(shelldoc-quit error))
(put 'shelldoc-quit 'error-message "shelldoc error")

;;;
;;; Basic utility
;;;

(defun shelldoc--count-regexp-matching (regexp)
  (goto-char (point-min))
  (let ((count 0))
    (while (re-search-forward regexp nil t)
      (setq count (1+ count)))
    count))

;;;
;;; Process
;;;

(defvar shelldoc--man-locale nil)

(defcustom shelldoc-keep-man-locale t
  "To keep man language on your environment.
If you need to read default, set to nil."
  :group 'shelldoc
  :type 'boolean)

(defun shelldoc--man-LANG ()
  (cond
   (shelldoc-keep-man-locale
    (getenv "LANG"))
   (t
    "C")))

(defmacro shelldoc--man-environ (&rest form)
  `(with-temp-buffer
     (let ((process-environment (copy-sequence process-environment)))
       (setenv "LANG" (shelldoc--man-LANG))
       ;; unset unnecessary env variables
       (setenv "MANROFFSEQ")
       (setenv "MANSECT")
       (setenv "PAGER")
       (setenv "LC_MESSAGES")
       (progn ,@form))))

(defvar shelldoc--man-section nil)

(defun shelldoc--call-man-to-string (args)
  (shelldoc--man-environ
   (when (= (apply
             'call-process
             manual-program
             nil t nil
             args) 0)
     (buffer-string))))

(defun shelldoc--read-manpage (name)
  (let ((args '()))
    (when shelldoc--man-locale
      (setq args
            (append args
                    (list "--locale" shelldoc--man-locale))))
    ;; restrict only two section
    ;; 1. Executable programs or shell commands
    ;; 8. System administration commands (usually only for root)
    (setq args (append
                (list "-S" (or shelldoc--man-section "1:8")))
                args))
    (setq args (append args (list name)))
    (shelldoc--call-man-to-string args)))

(defun shelldoc--manpage-exists-p (name)
  (let* ((args (list
                (list "-S" (or shelldoc--man-section "1:8")))
                "--where" name))
         (out (shelldoc--call-man-to-string args)))
    (and out (s-trim out))))

(defun shelldoc--convert-man-name (command)
  (let ((nondir (file-name-nondirectory command))
        (re (concat "\\(.+?\\)" (regexp-opt exec-suffixes) "\\'")))
    (if (string-match re nondir)
        (match-string 1 nondir)
      nondir)))

;;;
;;; Cache (process result)
;;;

;;TODO key: lang/name and tramp
(defvar shelldoc--man-cache
  (make-hash-table :test 'equal))

(defun shelldoc--get-cache-keyname (man-name)
  (format "%s/%s" (shelldoc--man-LANG) man-name))

(defun shelldoc--get-manpage (cmd)
  (let* ((name (shelldoc--convert-man-name cmd))
         (key (shelldoc--get-cache-keyname name)))
    (or (gethash key shelldoc--man-cache)
        (let* ((page (shelldoc--read-manpage name))
               (man (if page (list name page) 'unavailable)))
          (puthash key man shelldoc--man-cache)
          man))))

(defun shelldoc--filter-manpage-args (args)
  (remq nil
        (mapcar
         (lambda (c)
           (when (shelldoc--maybe-command-name-p c)
             (let ((name (shelldoc--convert-man-name c)))
               (cond
                ((not (memq (gethash name shelldoc--man-cache)
                            '(nil unavailable)))
                 c)
                ((not (shelldoc--manpage-exists-p name))
                 (puthash name 'unavailable shelldoc--man-cache)
                 nil)
                (t c)))))
         args)))

;;;
;;; Parsing
;;;

(defvar eshell-last-output-end)
(defun shelldoc--prompt-end ()
  (cond
   ((minibufferp)
    (minibuffer-prompt-end))
   ((derived-mode-p 'eshell-mode)
    eshell-last-output-end)
   ((and (derived-mode-p 'shell-mode)
         (get-buffer-process (current-buffer)))
    ;; guessed as prompt
    (let ((proc (get-buffer-process (current-buffer))))
      (process-mark proc)))
   ((derived-mode-p 'sh-mode)
    (point-at-bol))
   (t
    (signal 'shelldoc-quit (list "Not supported")))))

;; Using `read' to implement easily.
(defun shelldoc--parse-current-command-line (&optional split-here)
  (save-excursion
    (save-restriction
      (let ((start (shelldoc--prompt-end))
            ;; restrict to current line
            (end (point-at-eol)))
        (skip-chars-backward "\s\t\n" start)
        (when split-here
          (narrow-to-region start (point)))
        (let ((first (point))
              before after)
          (goto-char start)
          (ignore-errors
            ;; cursor is after command
            (while (< (point) first)
              (let ((segs (shelldoc--read-command-args)))
                (setq before (append before segs)))))
          (when split-here
            (widen))
          (ignore-errors
            (while (< (point) end)
              (let ((segs (shelldoc--read-command-args)))
                (setq after (append after segs)))))
          (list before after))))))

(defun shelldoc--read-command-args ()
  (skip-chars-forward ";\s\t\n")
  (let* ((exp (read (current-buffer)))
         (text (format "%s" exp)))
    (cond
     ;; general (e.g. --prefix=/usr/local)
     ((string-match "\\`\\(-.+?\\)=\\(.+\\)" text)
      (list (match-string 1 text) (match-string 2 text)))
     (t
      (list text)))))

(defun shelldoc--maybe-command-name-p (text)
  (and
   ;; Detect environment
   (not (string-match "=" text))
   ;; Detect general optional arg
   (not (string-match "\\`-" text))))

(defun shelldoc--option-parsing-strategy ()
  (with-current-buffer (shelldoc--popup-buffer)
    (save-excursion
      (let (
            ;; e.g. ImageMagick `convert' (single-hiphen)
            ;; "convert" "-adjoin"
            (single-hiphen (shelldoc--count-regexp-matching
                            "^[\s\t]+-[a-zA-Z0-9]\\{2,\\}"))
            ;; e.g. `ls' or common unix command (common-unix)
            ;; "ls" "-lha"
            (common-unix (shelldoc--count-regexp-matching
                          (eval-when-compile
                            (concat
                             "^[\s\t]+"
                             (regexp-opt
                              '(
                                "-[a-zA-Z0-9]\\b"
                                "--[a-zA-Z0-9]"
                                ))))))
            ;; e.g. `ps' (TODO: not implemented too complicated)
            )
        (if (> single-hiphen common-unix)
            'single-hiphen 'common-unix)))))

(defun shelldoc--split-compound-option (words)
  (cl-loop for w in words
           if (string-match "\\`-\\([a-zA-Z0-9]+\\)" w)
           append (mapcar (lambda (c) (format "-%c" c))
                          (string-to-list (match-string 1 w)))
           else
           append (list w)))

;;;
;;; Text manipulation
;;;

(defun shelldoc--create-wordify-regexp (keyword)
  (let* ((base-re (concat "\\(" (regexp-quote keyword) "\\)"))
         ;; do not use "\\b" sequence
         ;; keyword may be "--option" like string which start with
         ;; non word (FIXME: otherwise define new syntax?)
         (non-word "[][\s\t\n:,=|]")
         (regexp (concat non-word base-re non-word)))
    regexp))

;;;
;;; argument to man page name
;;;

(defcustom shelldoc-arguments-to-man-filters
  '(shelldoc--git-commands-filter)
  "Functions each accept one arg which indicate string list and
 return physical man page name.
See the `shelldoc--git-commands-filter' as sample."
  :group 'shelldoc
  :type 'hook)

(defun shelldoc--git-commands-filter (args)
  (and (equal (car args) "git")
       (stringp (cadr args))
       (format "git-%s" (cadr args))))

(defun shelldoc--guess-manpage-name (args)
  (or
   (run-hook-with-args-until-success
    'shelldoc-arguments-to-man-filters
    args)
   (let* ((filtered (shelldoc--filter-manpage-args args))
          (last (last filtered)))
     (car last))))

;;;
;;; UI
;;;

(defcustom shelldoc-idle-delay 0.3
  "Seconds to delay until popup man page."
  :group 'shelldoc
  :type 'number)

(defface shelldoc-short-help-face
  '((t :inherit match))
  "Face to highlight word in shelldoc."
  :group 'shelldoc)

(defface shelldoc-short-help-emphasis-face
  '((t :inherit match :bold t :underline t))
  "Face to highlight word in shelldoc."
  :group 'shelldoc)

(defvar shelldoc--current-man-name nil)
(make-variable-buffer-local 'shelldoc--current-man-name)

(defvar shelldoc--current-commands nil)
(make-variable-buffer-local 'shelldoc--current-commands)

(defvar shelldoc--mode-line-format
  (eval-when-compile
    (concat
     "\\[shelldoc-scroll-doc-window-up]:scroll-up"
     " "
     "\\[shelldoc-scroll-doc-window-down]:scroll-down"
     " "
     "\\[shelldoc-toggle-doc-window]:toggle-window"
     )))

;;
;; window/buffer manipulation
;;

(defvar shelldoc--saved-window-configuration nil)
(make-variable-buffer-local 'shelldoc--saved-window-configuration)

(defvar shelldoc--suppress-popup nil)

(defvar shelldoc--popup-buffer-p nil)
(make-variable-buffer-local 'shelldoc--popup-buffer-p)

(defun shelldoc--popup-buffer ()
  (let ((buf (get-buffer "*Shelldoc*")))
    (unless buf
      (setq buf (get-buffer-create "*Shelldoc*"))
      ;; in `current-buffer' to show command keys
      (let ((mode-line (substitute-command-keys
                        shelldoc--mode-line-format)))
        (with-current-buffer buf
          (kill-all-local-variables)
          (setq buffer-undo-list t)
          (setq mode-line-format
                `(,mode-line))
          (setq shelldoc--popup-buffer-p t))))
    buf))

(defun shelldoc--windows-bigger-order ()
  (mapcar
   'car
   (sort
    (mapcar
     (lambda (w)
       (cons w (* (window-height w) (window-width w))))
     (window-list))
    (lambda (w1 w2) (> (cdr w1) (cdr w2))))))

(defun shelldoc--delete-window ()
  (let* ((buf (shelldoc--popup-buffer))
         (win (get-buffer-window buf)))
    (when win
      (delete-window win))))

(defun shelldoc--prepare-window ()
  (let* ((buf (shelldoc--popup-buffer))
         (orig-win (selected-window))
         (all-wins (shelldoc--windows-bigger-order))
         (winlist (cl-remove-if-not
                   (lambda (w)
                     (eq (window-buffer w) buf)) all-wins)))
    ;; delete if multiple window is shown.
    ;; probablly no error but ignore error just in case.
    (ignore-errors
      (when (> (length winlist) 1)
        (dolist (w (cdr winlist))
          (delete-window w))))
    (or (car winlist)
        ;; split the biggest window property
        (let* ((win (car all-wins))
               (newwin
                (condition-case nil
                    (split-window win)
                  (error
                   (signal 'shelldoc-quit nil)))))
          (set-window-buffer newwin buf)
          (select-window orig-win t)
          newwin))))

(defun shelldoc--set-window-cursor (win words)
  (let* ((last (car (last words)))
         (regexps '()))
    (when last
      (when (string-match "\\`-" last)
        ;; general man page option start with spaces and hiphen
        (push (format "^[\s\t]+%s\\_>" (regexp-quote last)) regexps))
      (when (string-match "\\`--" last)
        ;; e.g. git add --force
        (push (format "^[\s\t]+-[^-][\s\t]*,[\s\t]*%s" (regexp-quote last))
              regexps))
      (when (string-match "\\`\\(-[^=]+\\)=" last)
        ;; e.g. print --action=
        (let ((last-arg (match-string 1 last)))
          (push (format "^[\s\t]+%s=" (regexp-quote last-arg)) regexps)))
      ;; default regexp if not matched to above
      (push (shelldoc--create-wordify-regexp last) regexps)
      (setq regexps (nreverse regexps))
      (with-current-buffer (shelldoc--popup-buffer)
        (goto-char (point-min))
        ;; goto first found (match strictly)
        (catch 'done
          (while regexps
            (when (let ((case-fold-search nil))
                    (re-search-forward (car regexps) nil t))
              ;; 5% margin
              (let ((margin (truncate (* (window-height win) 0.05))))
                (set-window-start win (point-at-bol (- margin)))
                nil)
              (throw 'done t))
            (setq regexps (cdr regexps)))
          ;; Keep window start
          )))))

;; FUNC must not change selected-window
(defun shelldoc--invoke-function (func)
  (let ((win (get-buffer-window (shelldoc--popup-buffer))))
    (when win
      (let ((prevwin (selected-window)))
        (unwind-protect
            (progn
              (select-window win)
              (funcall func))
          (select-window prevwin))))))

;;
;; drawing
;;

(defcustom shelldoc-fuzzy-match-requires 2
  "Number of characters to highlight with fuzzy search."
  :group 'shelldoc
  :type 'integer)

(defun shelldoc--prepare-man-page (page)
  (with-current-buffer (shelldoc--popup-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert page))))

(defun shelldoc--prepare-buffer (words)
  (with-current-buffer (shelldoc--popup-buffer)
    (remove-overlays)

    (dolist (word words)
      (when (>= (length word) shelldoc-fuzzy-match-requires)
        (let ((regexp (concat "\\(" (regexp-quote word) "\\)")))
          ;; fuzzy search
          (shelldoc--mark-regexp regexp 'shelldoc-short-help-face t))))
    (let* ((last (car (last words)))
           (regexp (shelldoc--create-wordify-regexp last)))
      ;; strict search
      (shelldoc--mark-regexp regexp 'shelldoc-short-help-emphasis-face nil))
    ;; To initialize, goto min
    (goto-char (point-min))))

(defun shelldoc--mark-regexp (regexp face case-fold)
  (let ((case-fold-search case-fold))
    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (let* ((start (match-beginning 1))
             (end (match-end 1))
             (ov (make-overlay start end)))
        (overlay-put ov 'face face)))))

(defun shelldoc--clear-showing ()
  (setq shelldoc--current-man-name nil)
  (setq shelldoc--current-commands nil))

;; to prepare man buffer to complete options.
(defun shelldoc--prepare-popup-buffer ()
  (cl-destructuring-bind (cmd-before cmd-after)
      (shelldoc--parse-current-command-line)
    (let ((cmd (shelldoc--guess-manpage-name cmd-before)))
      (when cmd
        (let ((man (shelldoc--get-manpage cmd)))
          (unless (or (null man) (eq 'unavailable man))
            (cl-destructuring-bind (name page) man
              (unless (equal name shelldoc--current-man-name)
                (shelldoc--prepare-man-page page)
                (setq shelldoc--current-man-name name))
              t)))))))

;; prepare man buffer and popup window.
(defun shelldoc--print-command-info ()
  (cl-destructuring-bind (cmd-before cmd-after)
      (shelldoc--parse-current-command-line)
    (let ((cmd (shelldoc--guess-manpage-name cmd-before))
          (clear (lambda ()
                   (shelldoc--delete-window)
                   (shelldoc--clear-showing))))
      (cond
       ((null cmd)
        (funcall clear))
       (t
        (let ((man (shelldoc--get-manpage cmd)))
          (cond
           ((or (null man) (eq 'unavailable man))
            (funcall clear))
           (t
            (cl-destructuring-bind (name page) man
              (unless (equal name shelldoc--current-man-name)
                (shelldoc--prepare-man-page page)
                (setq shelldoc--current-man-name name)))

            (let ((strategy (shelldoc--option-parsing-strategy))
                  words)
              (cond
               ((eq strategy 'common-unix)
                (cl-destructuring-bind (cmd-before2 cmd-after2)
                    ;; fallback command-line parsing after detect
                    ;; option parsing rule.
                    (shelldoc--parse-current-command-line t)
                  (setq cmd-before cmd-before2)
                  (setq cmd-after cmd-after2))
                (setq words (shelldoc--split-compound-option cmd-before)))
               (t
                (setq words cmd-before)))
              (let ((changed (not (equal shelldoc--current-commands words))))
                (when changed
                  (shelldoc--prepare-buffer words)
                  ;; using literal parsed value to compare equality
                  (setq shelldoc--current-commands cmd-before))
                (unless shelldoc--suppress-popup
                  ;; arrange window visibility.
                  ;; may be deleted multiple buffer window.
                  (let ((win (shelldoc--prepare-window)))
                    ;; set `window-start' when change command line virtually
                    (when changed
                      (shelldoc--set-window-cursor win words))))))))))))))

;;
;; Completion
;;

;;TODO improve regexp
;; OK: -a, --all
;; NG: --all, -a (however no example..)
(defconst shelldoc--man-option-re
  (eval-when-compile
    (mapconcat
     'identity
     '(
       ;; general option segment start
       "^\\(?:[\s\t]*\\(-[^\s\t\n,]+\\)\\)"
       ;; long option
       "\\(--[-_a-zA-Z0-9]+\\)"
       )
     "\\|")))

;; gather text by REGEXP first subexp of captured
(defun shelldoc--gather-regexp (regexp)
  (let ((buf (shelldoc--popup-buffer))
        (res '())
        (depth (regexp-opt-depth regexp)))
    (with-current-buffer buf
      (goto-char (point-min))
      (while (re-search-forward regexp nil t)
        (let ((text (cl-loop for i from 1 to depth
                             if (match-string-no-properties i)
                             return (match-string-no-properties i))))
          (unless (member text res)
            (setq res (cons text res)))))
      (nreverse res))))

;; Adopted `completion-at-point'
(defun shelldoc-option-completion ()
  (save-excursion
    (let ((end (point)))
      (skip-chars-backward "^\s\t\n")
      (when (looking-at "[\"']?\\(-\\)")
        (let ((start (match-beginning 1)))
          (when (shelldoc--prepare-popup-buffer)
            (let ((collection (shelldoc--gather-regexp
                               shelldoc--man-option-re)))
              (if collection
                  (list start end collection nil)
                nil))))))))

;; Adopted `pcomplete'
(defun shelldoc-option-pcomplete ()
  (let ((arg (pcomplete-actual-arg)))
    (when (string-match "\\`-" arg)
      (when (shelldoc--prepare-popup-buffer)
        (let ((collection (shelldoc--gather-regexp
                           shelldoc--man-option-re)))
          (throw 'pcomplete-completions
                 (all-completions arg collection)))))))

;;
;; Command
;;

(defun shelldoc-scroll-doc-window-up (&optional arg)
  (interactive "p")
  (let* ((buf (shelldoc--popup-buffer))
         (win (get-buffer-window buf))
         (minibuffer-scroll-window win)
         (base-lines (truncate (* (window-height win) 0.8)))
         (scroll-lines (* arg base-lines)))
    ;; ARG is lines of text
    (scroll-other-window scroll-lines)))

(defun shelldoc-scroll-doc-window-down (&optional arg)
  (interactive "p")
  (shelldoc-scroll-doc-window-up (- arg)))

;;TODO switch popup window position
(defun shelldoc-switch-popup-window ()
  "Not yet implemented"
  (interactive)
  (error "Not yet implemented"))

;;TODO
(defun shelldoc-toggle-locale ()
  "Not yet implemented
Toggle between default locale and todo"
  (interactive)
  (error "Not yet implemented")
  ;; (setq shelldoc--man-locale
  ;;       (unless shelldoc--man-locale
  ;;         (getenv "LANG")))
  )

(defun shelldoc-isearch-forward-document ()
  "Incremental search text in document buffer."
  (interactive)
  (shelldoc--invoke-function 'isearch-forward))

(defun shelldoc-isearch-backward-document ()
  "Incremental search text in document buffer."
  (interactive)
  (shelldoc--invoke-function 'isearch-backward))

(defun shelldoc-toggle-doc-window ()
  "Toggle shelldoc popup window is show/hide."
  (interactive)
  (setq shelldoc--suppress-popup
        (not shelldoc--suppress-popup))
  (when shelldoc--suppress-popup
    (shelldoc--delete-window))
  (unless (minibufferp)
    (message "Now shelldoc popup window is %s."
             (if shelldoc--suppress-popup
                 "deactivated" "activated"))))

(defvar shelldoc-minibuffer-map nil)
(unless shelldoc-minibuffer-map
  (let ((map (make-sparse-keymap)))

    (set-keymap-parent map minibuffer-local-shell-command-map)

    (define-key map  "\C-v" 'shelldoc-scroll-doc-window-up)
    (define-key map  "\ev" 'shelldoc-scroll-doc-window-down)

    (setq shelldoc-minibuffer-map map)))

(defvar shelldoc--original-minibuffer-map nil)

;; To suppress byte-compile warnings do not use `shelldoc' var name.
(defvar shelldoc:on nil)

(defun shelldoc (&optional arg)
  "Activate/Deactivate `shelldoc'."
  (interactive
   (list (and current-prefix-arg
              (prefix-numeric-value current-prefix-arg))))
  (cond
   ((or (and (numberp arg) (cl-minusp arg))
        (and (null arg) shelldoc:on))
    ;; all shelldoc window popup is disabled
    (shelldoc--cancel-timer)
    (ad-disable-advice
     'read-shell-command 'before
     'shelldoc-initialize-read-shell-command)
    (ad-update 'read-shell-command)
    ;; restore old map
    (setq minibuffer-local-shell-command-map
          shelldoc--original-minibuffer-map)
    ;; remove completion
    (setq shell-dynamic-complete-functions
          (remq 'shelldoc-option-completion
                shell-dynamic-complete-functions))
    (kill-buffer (shelldoc--popup-buffer))
    (setq shelldoc:on nil))
   (t
    (ad-enable-advice
     'read-shell-command 'before
     'shelldoc-initialize-read-shell-command)
    (ad-activate 'read-shell-command)
    ;; reset innner variable
    (setq-default shelldoc--suppress-popup nil)
    ;; save old map
    (setq shelldoc--original-minibuffer-map
          minibuffer-local-shell-command-map)
    ;; set new map
    (setq minibuffer-local-shell-command-map
          shelldoc-minibuffer-map)
    ;; for completion
    (add-to-list 'shell-dynamic-complete-functions
                 'shelldoc-option-completion)
    (shelldoc-clear-cache t)
    (setq shelldoc:on t)))
  (message "Now `shelldoc' is %s."
           (if shelldoc:on
               "activated"
             "deactivated")))

(defun shelldoc-clear-cache (&optional no-msg)
  "Clear cache to get newly installed file after shelldoc was activated."
  (interactive "P")
  (clrhash shelldoc--man-cache)
  (unless no-msg
    (message "shelldoc cache has been cleared.")))

(defvar shelldoc-minor-mode-map nil)

(unless shelldoc-minor-mode-map
  (let ((map (make-sparse-keymap)))

    (define-key map "\e." 'shelldoc-scroll-doc-window-up)
    (define-key map "\e," 'shelldoc-scroll-doc-window-down)
    (define-key map "\C-c\C-v" 'shelldoc-toggle-doc-window)
    ;; (define-key map "\ec" 'shelldoc-switch-popup-window)
    ;; (define-key map "\ec" 'shelldoc-toggle-locale)
    (define-key map "\C-c\C-s" 'shelldoc-isearch-forward-document)
    (define-key map "\C-c\C-r" 'shelldoc-isearch-backward-document)

    (setq shelldoc-minor-mode-map map)))

(define-minor-mode shelldoc-minor-mode
  ""
  nil nil shelldoc-minor-mode-map
  (cond
   (shelldoc-minor-mode
    (add-hook 'kill-buffer-hook 'shelldoc--cleanup-when-kill-buffer)
    ;; pcomplete (e.g. eshell)
    (add-hook 'pcomplete-try-first-hook
              'shelldoc-option-pcomplete nil t)
    ;; initialize internal vars
    (shelldoc--clear-showing)
    (setq shelldoc--saved-window-configuration
          (current-window-configuration))
    (shelldoc--maybe-start-timer))
   (t
    (remove-hook 'kill-buffer-hook 'shelldoc--cleanup-when-kill-buffer)
    (remove-hook 'pcomplete-try-first-hook
                 'shelldoc-option-pcomplete t)
    (shelldoc--maybe-cancel-timer)
    (when shelldoc--saved-window-configuration
      (set-window-configuration shelldoc--saved-window-configuration)
      (setq shelldoc--saved-window-configuration nil))
    (shelldoc--clear-showing)
    )))

(defun shelldoc-minor-mode-off ()
  (interactive)
  (shelldoc-minor-mode -1))

(defvar shelldoc--idle-timer nil)

(defun shelldoc--cleanup-when-kill-buffer ()
  ;; before killing buffer release some resource
  (shelldoc-minor-mode-off))

(defun shelldoc--cancel-timer ()
  (cancel-function-timers 'shelldoc-print-info)
  (setq shelldoc--idle-timer nil))

(defun shelldoc--maybe-cancel-timer ()
  (cl-loop for buf in (buffer-list)
           if (buffer-local-value 'shelldoc-minor-mode buf)
           return buf
           finally return
           (progn
             (shelldoc--cancel-timer)
             t)))

(defun shelldoc--maybe-start-timer ()
  (unless shelldoc--idle-timer
    (setq shelldoc--idle-timer
          (run-with-idle-timer shelldoc-idle-delay t 'shelldoc-print-info))))

;;;
;;; Load
;;;

;; 1. shelldoc--minibuffer-setup:
;;  minibuffer-setup-hook <- shelldoc--minibuffer-initialize

;; 2. shelldoc--minibuffer-initialize:
;;  minibuffer-setup-hook -> shelldoc--minibuffer-initialize
;;  minibuffer-exit-hook <- shelldoc--minibuffer-cleanup

;; Now shelldoc is working on timer:

;; 3. shelldoc--minibuffer-cleanup:
;;  minibuffer-exit-hook -> shelldoc--minibuffer-cleanup

;; Now shelldoc is deactivated.

(defvar shelldoc--minibuffer-depth nil)

(defun shelldoc-print-info ()
  (condition-case nil
      (cond
       (shelldoc-minor-mode
        (shelldoc--print-command-info))
       (shelldoc--popup-buffer-p)
       (t
        ;; cleanup if switching buffer has no shelldoc.
        (shelldoc--delete-window)))
    (shelldoc-quit
     ;; Do nothing. cannot show window but can prepare buffer.
     ;; (e.g. too small window to split window)
     )
    (error
     ;; do nothing
     )))

(defun shelldoc--minibuffer-initialize ()
  (when (= (minibuffer-depth) shelldoc--minibuffer-depth)
    ;; remove me
    (remove-hook 'minibuffer-setup-hook 'shelldoc--minibuffer-initialize)
    ;; add finalizer
    (add-hook 'minibuffer-exit-hook 'shelldoc--minibuffer-cleanup)
    (shelldoc-minor-mode-on)))

(defun shelldoc--minibuffer-cleanup ()
  ;; checking minibuffer-depth (e.g. helm conflict this)
  ;; lambda expression hard to `remove-hook' it
  (when (= (minibuffer-depth) shelldoc--minibuffer-depth)
    (shelldoc-minor-mode-off)
    ;; remove me
    (remove-hook 'minibuffer-exit-hook 'shelldoc--minibuffer-cleanup)))

;;;###autoload
(defun shelldoc-minor-mode-on ()
  (interactive)
  (shelldoc-minor-mode 1))

;;;###autoload
(defun shelldoc--minibuffer-setup ()
  (add-hook 'minibuffer-setup-hook 'shelldoc--minibuffer-initialize)
  (setq shelldoc--minibuffer-depth (1+ (minibuffer-depth))))

;; FIXME: switch to nadvice
;;;###autoload
(defadvice read-shell-command
    ;; default is `activate'
    (before shelldoc-initialize-read-shell-command () activate)
  (shelldoc--minibuffer-setup))

;; activate (after autoload / manually load)
(shelldoc 1)

;;;
;;; Unload
;;;

(defun shelldoc-unload-function ()
  (shelldoc -1)
  ;; explicitly return nil to continue `unload-feature'
  nil)

(provide 'shelldoc)

;;; shelldoc.el ends here
