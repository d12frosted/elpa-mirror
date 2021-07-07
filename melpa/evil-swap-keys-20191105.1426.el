;;; evil-swap-keys.el --- Intelligently swap keys on text input with evil -*- lexical-binding: t; -*-

;; Author: Wouter Bolsterlee <wouter@bolsterl.ee>
;; Version: 1.0.0
;; Package-Version: 20191105.1426
;; Package-Commit: b5ef105499f998b5667da40da30c073229a213ea
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience data languages tools
;; URL: https://github.com/wbolster/evil-swap-keys
;;
;; This file is not part of GNU Emacs.

;;; License:

;; 3-clause "new bsd"; see readme for details.

;;; Commentary:

;; Minor mode to intelligently swap keys when entering text.
;; See the README for more details.

;;; Code:

(defgroup evil-swap-keys nil
  "Intelligently swap keys when entering text"
  :prefix "evil-swap-keys-"
  :group 'evil)

(defcustom evil-swap-keys-number-row-keys
  '(("1" . "!")
    ("2" . "@")
    ("3" . "#")
    ("4" . "$")
    ("5" . "%")
    ("6" . "^")
    ("7" . "&")
    ("8" . "*")
    ("9" . "(")
    ("0" . ")"))
  "The numbers and symbols on the keyboard's number row.

This should match the actual keyboard layout."
  :group 'evil-swap-keys
  :type '(alist
          :key-type string
          :value-type string))

(defcustom evil-swap-keys-text-input-states
  '(emacs
    insert
    replace)
  "Evil states in which key presses will be treated as text input."
  :group 'evil-swap-keys
  :type '(repeat symbol))

(defcustom evil-swap-keys-text-input-commands
  '(evil-find-char
    evil-find-char-backward
    evil-find-char-to
    evil-find-char-to-backward
    evil-replace

    ;; third-party packages
    evil-snipe-f
    evil-snipe-F
    evil-snipe-s
    evil-snipe-S
    evil-snipe-t
    evil-snipe-T
    evil-snipe-x
    evil-snipe-X
    evil-surround-region
    evil-Surround-region)
  "Commands that read keys which should be treated as text input."
  :group 'evil-swap-keys
  :type '(repeat function))

(defcustom evil-swap-keys-elisp-input-commands
  '(customize-face
    customize-variable
    customize-variable-other-window
    describe-face
    describe-function
    describe-symbol
    describe-variable
    eval-expression
    execute-extended-command

    ;; third-party packages
    counsel-M-x
    counsel-descbinds
    counsel-describe-face
    counsel-describe-function
    counsel-describe-variable
    counsel-set-variable)
  "Commands that read elisp identifiers.  A remapped hyphen (minus) will be ignored here."
  :group 'evil-swap-keys
  :type '(repeat function))

(defcustom evil-swap-keys-file-input-commands
  '(find-file
    find-file-at-point
    find-file-literally
    find-file-literally-at-point
    find-file-other-frame
    find-file-other-window
    find-file-read-only
    find-file-read-only-other-frame
    find-file-read-only-other-window

    ;; third-party packages
    counsel-find-file
    counsel-find-file-extern
    projectile-find-dir
    projectile-find-dir-other-window
    projectile-find-file
    projectile-find-file-in-directory
    projectile-find-file-in-known-projects
    projectile-find-file-other-window)
  "Commands that read file names.  A remapped slash will be ignored here."
  :group 'evil-swap-keys
  :type '(repeat function))

(defvar evil-swap-keys--elisp-input-active nil
  "Flag indicating whether command name input is active.")

(defvar evil-swap-keys--file-input-active nil
  "Flag indicating whether file name input is active.")

(defvar evil-swap-keys--mappings nil
  "Active mappings for this buffer.")
(make-variable-buffer-local 'evil-swap-keys--mappings)

(defvar evil-state)
(defvar evil-this-type)

(defun evil-swap-keys--text-input-p (buffer)
  "Determine whether the current input for BUFFER should treated as text input."
  ;; NOTE: The evil-this-type check is a hack that seems to work well
  ;; for motions in operator mode. This variable is non-nil while
  ;; reading motions themselves, but not while entering a (optional)
  ;; count prefix for those motions. This makes things like d2t@
  ;; (delete until the second @ sign) work without using the shift key
  ;; at all: the first 2 is a count and will not be translated, and
  ;; the second 2 will be translated into a @ since the 't' motion
  ;; reads text input.
  (if (and (boundp 'evil-mode)
           (buffer-local-value 'evil-local-mode buffer))
      (or
       (and (eq evil-state 'operator) evil-this-type)
       isearch-mode
       (minibufferp)
       (memq evil-state evil-swap-keys-text-input-states)
       (memq this-command evil-swap-keys-text-input-commands))
    ;; when evil is not loaded (or inactive), treat everything as text input
    t))

(defun evil-swap-keys--pre-command-hook ()
  "Pre-command hook to set some internal flags."
  (unless (minibufferp)
    (cond
     ((eq this-command 'self-insert-command))
     ((memq this-command evil-swap-keys-file-input-commands)
      (setq evil-swap-keys--file-input-active t))
     ((memq this-command evil-swap-keys-elisp-input-commands)
      (setq evil-swap-keys--elisp-input-active t))
     (t
      (setq
       evil-swap-keys--elisp-input-active nil
       evil-swap-keys--file-input-active nil)))))

(defun evil-swap-keys--elisp-input-around-advice (fn &rest args)
  "Helper to call FN with ARGS, and set a 'reading elisp' flag."
  (let ((evil-swap-keys--elisp-input-active t))
    (apply fn args)))

(defun evil-swap-keys--file-input-around-advice (fn &rest args)
  "Helper to call FN with ARGS, and set a 'reading file name' flag."
  (let ((evil-swap-keys--file-input-active t))
    (apply fn args)))

(defun evil-swap-keys--maybe-translate (&optional _prompt)
  "Maybe translate the current input.

The PROMPT argument is ignored; it's only there for compatibility with
the 'key-translation-map callback signature."
  ;; This callback uses the local configuration to decide whether the
  ;; key should be translated, and if so, determine the replacement.
  ;; A nil return value implies no key translation takes place.
  (let* ((key (string last-input-event))
         (buffer (if (minibufferp)
                     (window-buffer (minibuffer-selected-window))
                   (current-buffer)))
         (mappings (buffer-local-value 'evil-swap-keys--mappings buffer))
         (should-translate
          (and (buffer-local-value 'evil-swap-keys-mode buffer)
               (evil-swap-keys--text-input-p buffer)))
         (replacement (cdr (assoc key mappings))))
    (when (and evil-swap-keys--file-input-active (member "/" (list key replacement)))
      (setq should-translate nil))  ;; special case for file names
    (when (and evil-swap-keys--elisp-input-active (member "-" (list key replacement)))
      (setq should-translate nil))  ;; special case for elisp names
    (when should-translate replacement)))

(defun evil-swap-keys--add-bindings ()
  "Add bindings to the global 'key-translation-map'."
  ;; Note: key-translation-map is global. Enabling key swapping in a
  ;; buffer only adds bindings to this global map. Other buffers (with
  ;; possibly different configurations) may have added these bindings
  ;; already, which is not a problem because define-key is idempotent.
  (dolist (mapping evil-swap-keys--mappings)
    (define-key key-translation-map
      (car mapping)
      #'evil-swap-keys--maybe-translate)))

(defun evil-swap-keys--remove-bindings ()
  "Remove bindings from the global 'key-translation-map'."
  (dolist (key (where-is-internal #'evil-swap-keys--maybe-translate
                                  key-translation-map))
    (define-key key-translation-map key nil)))

(defun evil-swap-keys--add-advice ()
  "Add advice around various functions that require instrumenting."
  (dolist (fn evil-swap-keys-elisp-input-commands)
    (advice-add fn :around 'evil-swap-keys--elisp-input-around-advice))
  (dolist (fn evil-swap-keys-file-input-commands)
    (advice-add fn :around 'evil-swap-keys--file-input-around-advice)))

(defun evil-swap-keys--remove-advice ()
  "Remove previously added advices."
  (dolist (fn evil-swap-keys-file-input-commands)
    (advice-remove fn 'evil-swap-keys--file-input-around-advice)))

;;;###autoload
(define-minor-mode evil-swap-keys-mode
  "Minor mode to intelligently swap keyboard keys during text input."
  :group 'evil-swap-keys
  :lighter " !1"
  (when evil-swap-keys-mode
    (evil-swap-keys--add-bindings)
    (evil-swap-keys--add-advice)
    (add-hook 'pre-command-hook 'evil-swap-keys--pre-command-hook)))

;;;###autoload
(define-globalized-minor-mode global-evil-swap-keys-mode
  evil-swap-keys-mode
  (lambda () (evil-swap-keys-mode t))
  "Global minor mode to intelligently swap keyboard keys during text input.")

;;;###autoload
(defun evil-swap-keys-add-mapping (from to)
  "Add a one-way mapping from key FROM to key TO."
  (add-to-list 'evil-swap-keys--mappings (cons from to))
  (evil-swap-keys-mode t))

;;;###autoload
(defun evil-swap-keys-add-pair (FROM TO)
  "Add a two-way mapping to swap keys FROM and TO."
  (evil-swap-keys-add-mapping FROM TO)
  (evil-swap-keys-add-mapping TO FROM))

;;;###autoload
(defun evil-swap-keys-swap-number-row ()
  "Swap the keys on the number row."
  (interactive)
  (dolist (pair evil-swap-keys-number-row-keys)
    (evil-swap-keys-add-pair (car pair) (cdr pair))))

;;;###autoload
(defun evil-swap-keys-swap-underscore-dash ()
  "Swap the underscore and the dash."
  (interactive)
  (evil-swap-keys-add-pair "_" "-"))

;;;###autoload
(defun evil-swap-keys-swap-colon-semicolon ()
  "Swap the colon and semicolon."
  (interactive)
  (evil-swap-keys-add-pair ":" ";"))

;;;###autoload
(defun evil-swap-keys-swap-tilde-backtick ()
  "Swap the backtick and tilde."
  (interactive)
  (evil-swap-keys-add-pair "~" "`"))

;;;###autoload
(defun evil-swap-keys-swap-double-single-quotes ()
  "Swap the double and single quotes."
  (interactive)
  (evil-swap-keys-add-pair "\"" "'"))

;;;###autoload
(defun evil-swap-keys-swap-square-curly-brackets ()
  "Swap the square and curly brackets."
  (interactive)
  (evil-swap-keys-add-pair "[" "{")
  (evil-swap-keys-add-pair "]" "}"))

;;;###autoload
(defun evil-swap-keys-swap-pipe-backslash ()
  "Swap the pipe and backslash."
  (interactive)
  (evil-swap-keys-add-pair "|" "\\"))

;;;###autoload
(defun evil-swap-keys-swap-question-mark-slash ()
  "Swap the question mark and slash."
  (interactive)
  (evil-swap-keys-add-pair "/" "?"))

(provide 'evil-swap-keys)
;;; evil-swap-keys.el ends here
