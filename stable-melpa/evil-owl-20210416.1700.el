;;; evil-owl.el --- Preview evil registers and marks before using them -*- lexical-binding: t -*-

;; Copyright (C) 2019 Daniel Phan

;; Author: Daniel Phan <daniel.phan36@gmail.com>
;; Version: 0.0.1
;; Package-Version: 20210416.1700
;; Package-Commit: a41a6d28e26052b25f3d21da37ccf1d8fde1e6aa
;; Package-Requires: ((emacs "25.1") (evil "1.2.13"))
;; Homepage: https://github.com/mamapanda/evil-owl
;; Keywords: emulations, evil, visual

;; This file is NOT part of GNU Emacs.

;;; License:
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

;;; Commentary:
;;
;; evil-owl provides a preview popup for evil's mark and register
;; commands.  To enable the popup, turn on `evil-owl-mode'.

;;; Code:

;; * Setup
(require 'cl-lib)
(require 'evil)
(require 'format-spec)
(eval-when-compile
  (require 'subr-x))

(declare-function posframe-workable-p "ext:posframe.el")
(declare-function posframe-show "ext:posframe.el")
(declare-function posframe-funcall "ext:posframe.el")
(declare-function posframe-delete "ext:posframe.el")

(defgroup evil-owl nil
  "Register and mark preview popups."
  :prefix "evil-owl-"
  :group 'evil)

;; * User Options
;; ** Variables
(defcustom evil-owl-register-groups
  `(("Named"     . ,(cl-loop for c from ?a to ?z collect c))
    ("Numbered"  . ,(cl-loop for c from ?0 to ?9 collect c))
    ("Special"   . (?\" ?* ?+ ?-))
    ("Read-only" . (?% ?# ?/ ?: ?= ?.)))
  "An alist of register group names to registers.
Groups and registers will be displayed in the same order they appear
in this variable."
  :type '(alist :key string :value (repeat character)))

(defcustom evil-owl-mark-groups
  `(("Named Local"  . ,(cl-loop for c from ?a to ?z collect c))
    ("Named Global" . ,(cl-loop for c from ?A to ?Z collect c))
    ("Numbered"     . ,(cl-loop for c from ?0 to ?9 collect c))
    ;; With the last jump marks, `evil-get-marker' won't necessarily
    ;; preserve the current buffer. Gotta file a PR I guess.
    ;;
    ;; Also, interesting comment about the last change mark:
    ;; https://github.com/Andrew-William-Smith/evil-fringe-mark/blob/a1689fddb7ee79aaa720a77aada1208b8afd5c20/evil-fringe-mark.el#L284
    ;;
    ;; As a result, these 3 marks are left out by default.
    ("Special"      . (?\[ ?\] ?< ?> ?^ ?\( ?\) ?{ ?})))
  "An alist of mark group names to marks.
Groups and marks will be displayed in the same order they appear in
this variable."
  :type '(alist :key string :value (repeat character)))

(defcustom evil-owl-header-format "%s"
  "Format for group headers.
An empty string means to not show a header."
  :type 'string)

(defcustom evil-owl-register-format " %r: %s"
  "Format for register entries.
Possible format specifiers are:
- %r: the register
- %s: the register's contents"
  :type 'string)

(defcustom evil-owl-local-mark-format " %m: [l: %-5l, c: %-5c]"
  "Format for local mark entries.
Possible format specifiers are:
- %m: the mark
- %l: the mark's line number
- %c: the mark's column number
- %b: the mark's buffer
- %s: text of the mark's line"
  :type 'string)

(defcustom evil-owl-global-mark-format " %m: [l: %-5l, c: %-5c] %b"
  "Format for global mark entries.
Possible format specifiers are:
- %m: the mark
- %l: the mark's line number
- %c: the mark's column number
- %b: the mark's buffer
- %s: text of the mark's line"
  :type 'string)

(defcustom evil-owl-separator "\n"
  "The separator string to place between sections."
  :type 'string)

(defcustom evil-owl-display-method 'window
  "The method to use to display the preview.
The value may be either 'window or 'posframe."
  :type '(choice (const window) (const posframe)))

(defcustom evil-owl-extra-posframe-args nil
  "Extra arguments to pass to `posframe-show'."
  :type 'list)

(defcustom evil-owl-idle-delay 1
  "The idle delay, in seconds, before the popup appears."
  :type 'float)

(define-obsolete-variable-alias 'evil-owl-register-char-limit 'evil-owl-max-string-length "0.0.1")

(defcustom evil-owl-max-string-length nil
  "Maximum number of characters to consider in a string register or context line."
  :type 'integer)

(defcustom evil-owl-lighter " evil-owl"
  "Lighter for evil-owl."
  :type 'string)

;; ** Faces
(defface evil-owl-group-name '((t (:inherit font-lock-function-name-face)))
  "The face for group names.")

(defface evil-owl-entry-name '((t (:inherit font-lock-type-face)))
  "The face for marks and registers.")

;; * Display Strings
;; ** Common
(defun evil-owl--header-string (name-of-group)
  "Return the header string for a group, where NAME-OF-GROUP is the group name."
  (if (string-empty-p evil-owl-header-format)
      ""
    (concat
     (format evil-owl-header-format
             (propertize name-of-group 'face 'evil-owl-group-name))
     "\n")))

(defun evil-owl--display-string (groups entry-string-fn)
  "Return the display string to put in the preview buffer.
GROUPS is an alist of group names to group members.
ENTRY-STRING-FN is a function that takes one parameter, the entry to
show, and outputs an entry string (newline included)."
  (mapconcat
   (lambda (group)
     (let ((header (evil-owl--header-string (car group)))
           (body (mapconcat entry-string-fn (cdr group) "")))
       (concat header body)))
   groups
   evil-owl-separator))

;; ** Registers
(defun evil-owl--get-register (reg)
  "Get the contents of REG as a string.
The result is nil if REG is empty."
  (when-let ((contents (cond
                        ((= ?= reg)
                         (and (boundp 'evil-last-=-register-input)
                              evil-last-=-register-input))
                        (t (evil-get-register reg t)))))
    (cond
     ((stringp contents)
      (when (and evil-owl-max-string-length
                 (> (length contents) evil-owl-max-string-length))
        (setq contents (substring contents 0 evil-owl-max-string-length)))
      (replace-regexp-in-string "\n" "^J" contents))
     ((vectorp contents)
      (key-description contents)))))

(defun evil-owl--register-entry-string (reg)
  "Compute the entry string for REG."
  (let* ((contents (evil-owl--get-register reg))
         (spec (format-spec-make ?r (propertize (char-to-string reg)
                                                'face 'evil-owl-entry-name)
                                 ?s contents)))
    (if (cl-plusp (length contents))
        (concat (format-spec evil-owl-register-format spec) "\n")
      "")))

(defun evil-owl--register-display-string ()
  "Compute the preview display string for registers."
  (evil-owl--display-string evil-owl-register-groups
                            #'evil-owl--register-entry-string))

;; ** Marks
(defun evil-owl--global-marker-p (mark)
  "Return whether MARK is a global mark."
  (or (<= ?A mark ?Z)
      (and evil-jumps-cross-buffers (memq mark '(?` ?')))))

(defun evil-owl--get-mark (mark)
  "Get the position stored in MARK.
The result is a list (line-number column-number buffer context-line),
or nil if MARK points nowhere."
  (when-let ((pos (condition-case nil
                      (evil-get-marker mark)
                    ;; Some marks error if their use conditions
                    ;; haven't been met (e.g. '> assumes that there's
                    ;; a previous/current visual selection)
                    (error nil)))
             (buffer (cond ((numberp pos) (current-buffer))
                           ((markerp pos) (marker-buffer pos)))))
    (with-current-buffer buffer
      (save-excursion
        (goto-char pos)
        (let* ((line (line-number-at-pos pos))
               (column (current-column))
               (context-beg (line-beginning-position))
               (context-end (if evil-owl-max-string-length
                                (min (+ context-beg
                                        evil-owl-max-string-length)
                                     (line-end-position))
                              (line-end-position)))
               (context (buffer-substring context-beg context-end)))
          (list line column buffer context))))))

(defun evil-owl--mark-entry-string (mark)
  "Compute the entry string for MARK."
  (if-let ((pos-info (evil-owl--get-mark mark)))
      (cl-destructuring-bind (line column buffer contents) pos-info
        (let ((format (if (evil-owl--global-marker-p mark)
                          evil-owl-global-mark-format
                        evil-owl-local-mark-format))
              (spec (format-spec-make ?m (propertize (char-to-string mark)
                                                     'face 'evil-owl-entry-name)
                                      ?l line
                                      ?c column
                                      ?s contents
                                      ?b buffer)))
          (concat (format-spec format spec) "\n")))
    ""))

(defun evil-owl--mark-display-string ()
  "Compute the preview display string for markers."
  (evil-owl--display-string evil-owl-mark-groups
                            #'evil-owl--mark-entry-string))

;; * Preview
;; ** Show / Hide
(defconst evil-owl--buffer "*evil-owl*"
  "The buffer name for the popup.")

(defvar evil-owl--timer nil
  "The timer for the popup.")

(defvar evil-owl--saved-window-config nil
  "The window configuration before triggering evil-owl.
This is used to restore the window configuration when
`evil-owl-display-method' is 'window.")

(defun evil-owl--show-window (string)
  "Show STRING in a preview window."
  (setq evil-owl--saved-window-config (current-window-configuration))
  (let* ((buffer (get-buffer-create evil-owl--buffer))
         (window (display-buffer buffer t)))
    (with-selected-window window
      (setq cursor-in-non-selected-windows nil)
      (setq-local truncate-lines t)
      (erase-buffer)
      (insert string)
      (goto-char (point-min)))))

(defun evil-owl--hide-window ()
  "Hide the preview window."
  (when evil-owl--saved-window-config
    (set-window-configuration evil-owl--saved-window-config)
    (setq evil-owl--saved-window-config nil))
  (when-let ((buffer (get-buffer evil-owl--buffer)))
    (kill-buffer buffer)))

(defun evil-owl--show-posframe (string)
  "Show STRING in a preview posframe."
  (require 'posframe)
  ;; `posframe-show' errors when we're in the minibuffer.
  ;; I've also observed this with other packages.
  (when (and (posframe-workable-p) (not (minibufferp)))
    (apply #'posframe-show
           evil-owl--buffer
           :string string
           :position (point)
           evil-owl-extra-posframe-args)
    (posframe-funcall evil-owl--buffer
                      (lambda () (setq-local truncate-lines t)))))

(defun evil-owl--hide-posframe ()
  "Hide the preview posframe."
  (require 'posframe)
  (posframe-delete evil-owl--buffer))

(defun evil-owl--show-popup (string)
  "Show STRING in a preview popup.
The popup type is determined by `evil-owl-display-method'."
  (cl-case evil-owl-display-method
    (window (evil-owl--show-window string))
    (posframe (evil-owl--show-posframe string))))

(defun evil-owl--idle-show-popup (string)
  "Show STRING in a popup after `evil-owl-idle-delay' seconds."
  (setq evil-owl--timer
        (run-at-time evil-owl-idle-delay nil #'evil-owl--show-popup string)))

(defun evil-owl--hide-popup ()
  "Hide the preview popup."
  (when evil-owl--timer
    (cancel-timer evil-owl--timer)
    (setq evil-owl--timer nil))
  (cl-case evil-owl-display-method
    (window (evil-owl--hide-window))
    (posframe (evil-owl--hide-posframe))))

;; ** Keybindings
(defvar evil-owl-popup-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "<escape>") #'keyboard-quit)
    (define-key map (kbd "C-g") #'keyboard-quit)
    (define-key map (kbd "C-b") #'evil-owl-scroll-popup-up)
    (define-key map (kbd "C-f") #'evil-owl-scroll-popup-down)
    map)
  "Keymap applied when the popup is active.")

(defun evil-owl--funcall (fn &rest args)
  "Call FN with ARGS in the preview buffer."
  (cl-case evil-owl-display-method
    (window
     (when-let ((window (get-buffer-window evil-owl--buffer)))
       (with-selected-window window
         (apply fn args))))
    (posframe
     (posframe-funcall evil-owl--buffer fn args))))

(defun evil-owl-scroll-popup-up ()
  "Scroll the popup up one page."
  (interactive)
  (condition-case nil
      (evil-owl--funcall #'scroll-down)
    (beginning-of-buffer nil)))

(defun evil-owl-scroll-popup-down ()
  "Scroll the popup down one page."
  (interactive)
  (condition-case nil
      (evil-owl--funcall #'scroll-up)
    (end-of-buffer nil)))

(defmacro evil-owl--with-popup-map (&rest body)
  "Execute BODY with `evil-owl-popup-map' as the sole keymap."
  (declare (indent 0))
  (let ((current-global-map (cl-gensym "current-global-map")))
    `(let ((overriding-terminal-local-map nil)
           (overriding-local-map evil-owl-popup-map)
           (,current-global-map (current-global-map)))
       (unwind-protect
           (progn
             (use-global-map
              (let ((map (make-sparse-keymap)))
                (define-key map [menu-bar]
                  (lookup-key global-map [menu-bar]))
                (define-key map [tool-bar]
                  (lookup-key global-map [tool-bar]))
                (define-key map [tab-bar]
                  (lookup-key global-map [tab-bar]))
                map))
             ,@body)
         (use-global-map ,current-global-map)))))

(defun evil-owl--read-register-or-mark (&rest _)
  "Read a register or mark character.
This function allows executing commands in `evil-owl-popup-map', and
the keys of such commands will not be read."
  (evil-owl--with-popup-map
    (catch 'char
      (while t
        (let* ((keys (read-key-sequence nil nil t))
               (cmd (key-binding keys)))
          (cond
           (cmd
            (call-interactively cmd))
           ((and (stringp keys) (= (length keys) 1))
            (throw 'char (aref keys 0)))
           (t
            ;; Keys represented with vectors (e.g. <delete> and <F3>)
            ;; aren't valid registers or marks, since valid ones use
            ;; ascii characters.
            (user-error "%s is undefined" (key-description keys)))))))))

;; * Minor Mode
(defun evil-owl--eval-interactive-spec (fn display-fn)
  "Evaluate FN's interactive spec with a preview popup.
The popup will show DISPLAY-FN's output."
  (unwind-protect
      (progn
        (evil-owl--idle-show-popup (funcall display-fn))
        (cl-letf (((symbol-function 'evil-read-key) #'evil-owl--read-register-or-mark)
                  ((symbol-function 'read-char) #'evil-owl--read-register-or-mark))
          (advice-eval-interactive-spec (cl-second (interactive-form fn)))))
    (evil-owl--hide-popup)))

(cl-defmacro evil-owl--define-wrapper (name &key wrap display)
  "Define NAME as a wrapper around WRAP.
DISPLAY is a function that outputs a string to show in the preview
popup."
  (declare (indent defun))
  (let ((args (cl-gensym "args")))
    `(evil-define-command ,name (&rest ,args)
       ,(format "Wrapper function for `%s' that shows a preview popup." wrap)
       ,@(evil-get-command-properties wrap)
       (interactive (evil-owl--eval-interactive-spec #',wrap #',display))
       (setq this-command #',wrap)
       (apply #'funcall-interactively #',wrap ,args))))

(evil-owl--define-wrapper evil-owl-use-register
  :wrap evil-use-register
  :display evil-owl--register-display-string)

(evil-owl--define-wrapper evil-owl-execute-macro
  :wrap evil-execute-macro
  :display evil-owl--register-display-string)

(evil-owl--define-wrapper evil-owl-record-macro
  :wrap evil-record-macro
  :display evil-owl--register-display-string)

(evil-owl--define-wrapper evil-owl-paste-from-register
  :wrap evil-paste-from-register
  :display evil-owl--register-display-string)

(evil-owl--define-wrapper evil-owl-set-marker
  :wrap evil-set-marker
  :display evil-owl--mark-display-string)

(evil-owl--define-wrapper evil-owl-goto-mark
  :wrap evil-goto-mark
  :display evil-owl--mark-display-string)

(evil-owl--define-wrapper evil-owl-goto-mark-line
  :wrap evil-goto-mark-line
  :display evil-owl--mark-display-string)

;;;###autoload
(define-minor-mode evil-owl-mode
  "A minor mode to preview marks and registers before using them."
  :global t
  :lighter evil-owl-lighter
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map [remap evil-record-macro] #'evil-owl-record-macro)
            (define-key map [remap evil-execute-macro] #'evil-owl-execute-macro)
            (define-key map [remap evil-use-register] #'evil-owl-use-register)
            (define-key map [remap evil-paste-from-register] #'evil-owl-paste-from-register)
            (define-key map [remap evil-set-marker] #'evil-owl-set-marker)
            (define-key map [remap evil-goto-mark] #'evil-owl-goto-mark)
            (define-key map [remap evil-goto-mark-line] #'evil-owl-goto-mark-line)
            map))

(provide 'evil-owl)
;;; evil-owl.el ends here
