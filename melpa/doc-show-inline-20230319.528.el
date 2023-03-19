;;; doc-show-inline.el --- Show doc-strings found in external files -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2021  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-doc-show-inline
;; Package-Version: 20230319.528
;; Package-Commit: 261554a788e9cc6c0ba538a732667e514fab70c6
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; This package overlays doc-strings (typically from C/C++ headers).
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'doc-show-inline)
;;
;; Or with `use-package':
;;
;;   (use-package doc-show-inline)
;;
;; If you prefer to enable this per-mode, you may do so using
;; mode hooks instead of calling `doc-show-inline-mode'.
;; The following example enables this for C-mode:
;;
;;   (add-hook 'c-mode-hook
;;     (lambda ()
;;       (doc-show-inline-mode)))
;;

;;; Code:

;; Built-in packages.
(require 'xref)
(require 'imenu)


;; ---------------------------------------------------------------------------
;; Compatibility

(when (and (version< emacs-version "29.1") (not (and (fboundp 'pos-bol) (fboundp 'pos-eol))))
  (defun pos-bol (&optional n)
    "Return the position at the line beginning."
    (declare (side-effect-free t))
    (let ((inhibit-field-text-motion t))
      (line-beginning-position n)))
  (defun pos-eol (&optional n)
    "Return the position at the line end."
    (declare (side-effect-free t))
    (let ((inhibit-field-text-motion t))
      (line-end-position n))))


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup doc-show-inline nil
  "Overlay doc-strings from external files (using `xref' look-up)."
  :group 'convenience)

(defcustom doc-show-inline-idle-delay-init 1.0
  "Initial idle delay, `doc-show-inline-idle-delay' is used afterwards."
  :type 'float)

(defcustom doc-show-inline-idle-delay 0.75
  "Idle time to wait before highlighting.
Set to 0.0 to highlight immediately (as part of syntax highlighting)."
  :type 'float)

(defcustom doc-show-inline-exclude-regexp nil
  "Optionally skip comments that match this regular expression."
  :type '(choice (const nil) (regexp)))

(defcustom doc-show-inline-exclude-blank-lines 0
  "Optionally skip comments which have blank lines above the declaration.
Ignore comments that have at least this many blank lines after the doc-string.
Zero disables."
  :type 'integer)

(defcustom doc-show-inline-face-background-highlight -0.04
  "Use to tint the background color for overlay text (between -1.0 and 1.0).
Ignored when `doc-show-inline-face'
does not have a user defined background color."
  :type 'float)

(defface doc-show-inline-face (list (list t :extend t))
  "Background for overlays.
Note that the `background' is initialized using
`doc-show-inline-face-background-highlight' unless it's customized.")

;; TODO, document and make public.
(defvar doc-show-inline-mode-defaults
  (list
   (cons 'c-mode (list :filter 'doc-show-inline-filter-for-cc-mode))
   (cons 'cc-mode (list :filter 'doc-show-inline-filter-for-cc-mode))
   (cons 'objc-mode (list :filter 'doc-show-inline-filter-for-cc-mode)))
  "An association-list of default functions.")

(defcustom doc-show-inline-use-logging nil
  "Optionally log interactions.
Use for troubleshooting when lookups aren't or debugging.
Note that this should not be enabled general usage as it impacts performance."
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Custom Functions

(defvar doc-show-inline-fontify-hook nil
  "Run before extraction, functions take two arguments for the comment range.
Intended for any additional highlighting such as tags or spell checking text,
note that highlighting from overlays are also supported.")

(defvar doc-show-inline-buffer-hook nil
  "Run upon loading a new buffer.
This hook is called instead of the mode hooks such as:
`c-mode-hook' and `after-change-major-mode-hook'.")

(defvar-local doc-show-inline-locations 'doc-show-inline-locations-default
  "Scans the current buffer for locations that `xref' should look-up.
The result of each item must be a (symbol . position) cons cell,
where the symbol is a string used for the look-up and
the position is it's beginning in the buffer.

Note that this function may move the POINT without using `save-excursion'.")

(defvar-local doc-show-inline-extract-doc 'doc-show-inline-extract-doc-default
  "Function to extract the doc-string given the destination buffer.
The buffer and point will be the destination (the header file for example).
The function must return a (BEG . END) cons cell representing the range to
display or nil on failure.
Note that the beginning may contain white-space (before the comment begins)
in order to maintain alignment with the following lines.")

(defvar-local doc-show-inline-filter nil
  "Optionally skip some symbols when this function returns nil.
The function takes a string (the symbol being looked up).
When unset, the :filter property from `doc-show-inline-mode-defaults' is used.")


;; ---------------------------------------------------------------------------
;; Internal Variables

(defconst doc-show-inline--cc-modes '(c-mode c++-mode objc-mode))

;; Allow disabling the mode (when opening buffers for the purpose of introspection).
(defvar doc-show-inline--inhibit-mode nil)

;; Allow disabling for debugging.
(defconst doc-show-inline--use-lookup-cache t)
;; Always set when the mode is active:
;; - key: the symbol as a string (from `xref-backend-identifier-at-point' or from `imenu'),
;; - value: the syntax-highlighted string to display (from `doc-show-inline--doc-from-xref').
(defvar-local doc-show-inline--lookup-cache nil)

(defvar-local doc-show-inline--idle-timer nil)

;; List of interactive commands.
(defconst doc-show-inline--commands (list 'doc-show-inline-buffer 'doc-show-inline-mode))


;; ---------------------------------------------------------------------------
;; Idle Overlay (Package Development / Debugging Only)
;;
;; Not intended for general purpose use,
;; needed for checking there are no gaps in the regions being checked .

;; Only for showing areas marked for highlighting.
(defconst doc-show-inline--idle-overlays-debug nil)
;; When debug is enabled.
(defvar doc-show-inline--idle-overlays-debug-index 0)
(defvar doc-show-inline--idle-overlays-debug-colors
  (list "#005500" "#550000" "#000055" "#550055" "#005555"))


;; ---------------------------------------------------------------------------
;; Internal Functions / Macros

(defmacro doc-show-inline--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with WHERE advice on FN-ORIG temporarily enabled."
  (declare (indent 3))
  `(let ((fn-advice-var ,fn-advice))
     (unwind-protect
         (progn
           (advice-add ,fn-orig ,where fn-advice-var)
           ,@body)
       (advice-remove ,fn-orig fn-advice-var))))

(defun doc-show-inline--color-highlight (color factor)
  "Tint between COLOR by FACTOR in (-1..1).
Where positive brighten and negative numbers darken."
  (let ((value (color-values color))
        (factor-int (truncate (* 65535 factor))))
    (apply #'format
           (cons
            "#%02x%02x%02x"
            (mapcar
             (lambda (n)
               ;; Shift by -8 to map the value returned by `color values':
               ;; 0..65535 to 0..255 for `#RRGGBB` string formatting.
               (ash (min 65535 (max 0 (truncate (+ (nth n value) factor-int)))) -8))
             (number-sequence 0 2))))))

(defun doc-show-inline--buffer-substring-with-overlay-props (pos-beg pos-end)
  "Return text between POS-BEG and POS-END including overlay properties."
  ;; Extract text and possible overlays.
  (let ((text (buffer-substring pos-beg pos-end))
        (text-length (- pos-end pos-beg))
        (overlays (overlays-in pos-beg pos-end)))
    (while overlays
      (let ((ov (pop overlays)))
        (let ((face-prop (overlay-get ov 'face)))
          (when face-prop
            (add-face-text-property (max (- (overlay-start ov) pos-beg) 0)
                                    (min (- (overlay-end ov) pos-beg) text-length)
                                    face-prop
                                    t
                                    text)))))
    text))


;; ---------------------------------------------------------------------------
;; Logging
;;
;; Without detailed logging, it's difficult to know why a doc-string is not found,
;; this is quite verbose and intended for troubleshooting only.

(defun doc-show-inline--log-type-impl (prefix str)
  "Logging function (implementation), PREFIX and STR (with no newline)."
  (let ((buf (get-buffer-create "*doc-show-inline-log*")))
    (set-text-properties 0 (length str) nil str)
    ;; (printf "%s%s\n" prefix str)
    (with-current-buffer buf
      (insert prefix str "\n"))))

(defmacro doc-show-inline--log-fail (&rest args)
  "Log failure messages formatted with ARGS."
  `(when doc-show-inline-use-logging
     (doc-show-inline--log-type-impl "Fail: " (format ,@args))))

(defmacro doc-show-inline--log-info (&rest args)
  "Log info messages formatted with ARGS."
  `(when doc-show-inline-use-logging
     (doc-show-inline--log-type-impl "Info: " (format ,@args))))


;; ---------------------------------------------------------------------------
;; Mode Specific Logic
;;
;; Currently only C/C++ has custom support, other languages will work in principle
;; if their doc-strings are stored externally and support `xref'.

(defun doc-show-inline-filter-for-cc-mode (sym)
  "Return non-nil when this SYM should be checked for a doc-string.

The point will be located over the symbol (typically at it's beginning),
the point should not be moved by this function."
  (let ((prefix (buffer-substring-no-properties (pos-bol) (point))))
    (cond
     ;; Ignore defines, they never have external docs.
     ;; Removing will work, it just performs an unnecessary lookup.
     ((string-match-p "[ \t]*#[ \t]*define[ \t]+" prefix)
      nil)
     ;; Ignore static function doc-strings.
     ;; Removing will work, it just performs an unnecessary lookup.
     ((string-match-p "\\_<static\\_>" prefix)
      nil)
     ;; Forward declaring structs shouldn't show documentation, e.g:
     ;;    struct SomeStruct;
     ;; while this is in some sense a personal preference,
     ;; forward declarations are mostly used to prevent warnings when these
     ;; structs are used as parameters.
     ;; So it makes sense to ignore them.
     ((and (string-match-p "^\\_<struct\\_>" prefix)
           (equal ?\; (char-after (+ (point) (length sym)))))
      nil)
     ;; Including `typedef' rarely gains anything from in-lining doc-string
     ;; Similar to `struct':
     ;; - This is already the declaration so the doc-string is already available.
     ;; - This forward declares an opaque type.
     ((string-match-p "^\\_<typedef\\_>" prefix)
      nil)
     (t
      t))))

(defun doc-show-inline-extract-doc-default (sym)
  "Extract doc-string for SYM."

  ;; There may be blank lines between the comment beginning,
  ;; include these since it's useful to display the the space to know if the comment
  ;; was directly above the text or not.
  (let ((pos-end (max (point-min) (1- (pos-bol)))))
    ;; Move one character into the comment.
    (goto-char pos-end)
    (cond
     ((forward-comment -1)
      (let ((pos-beg (point))
            (pos-beg-of-line (pos-bol)))

        (cond
         ;; Ensure the comment is not a trailing comment of a previous line.
         ((not
           (eq
            pos-beg-of-line
            (save-excursion
              (skip-chars-backward " \t" pos-beg-of-line)
              (point))))
          (doc-show-inline--log-info
           "symbol \"%s\" in %S at point %d is previous lines trailing comment"
           sym
           (current-buffer)
           (point))
          ;; Skip this comment.
          nil)

         ;; Optionally exclude blank lines between the comment and the function definition.
         ((and
           ;; Checking blank lines?
           (not (zerop doc-show-inline-exclude-blank-lines))
           (let ((blank-lines 0))
             (save-excursion
               (goto-char pos-end)
               ;; It's important the point is at the beginning of the line
               ;; so `looking-at-p' works as expected.
               (goto-char (pos-bol))
               (while (and (looking-at-p "[[:blank:]]*$")
                           (< (setq blank-lines (1+ blank-lines))
                              doc-show-inline-exclude-blank-lines)
                           (zerop (forward-line -1)))))
             (eq blank-lines doc-show-inline-exclude-blank-lines)))

          (doc-show-inline--log-info
           "comment \"%s\" in %S at point %d was skipped because of at least %d blank lines"
           sym
           (current-buffer)
           pos-beg
           doc-show-inline-exclude-blank-lines)

          ;; Found at least `doc-show-inline-exclude-blank-lines' blank-lines, skipping.
          nil)

         ;; Optionally exclude a regexp.
         ((and doc-show-inline-exclude-regexp
               (save-match-data
                 (goto-char pos-beg)
                 (search-forward-regexp doc-show-inline-exclude-regexp pos-end t)))

          (doc-show-inline--log-info
           "comment \"%s\" in %S at point %d was skipped because of regex match with %S"
           sym
           (current-buffer)
           pos-beg
           doc-show-inline-exclude-regexp)

          ;; Skip this comment.
          nil)

         (t
          ;; Success.
          (cons pos-beg-of-line pos-end)))))
     (t
      (doc-show-inline--log-info
       "symbol \"%s\" in %S at point %d has no comment before it"
       sym
       (current-buffer)
       (point))
      ;; Failure.
      nil))))


;; ---------------------------------------------------------------------------
;; Internal Functions / Macros

(defun doc-show-inline--init-face-background-once ()
  "Ensure `doc-show-inline-face' has a background color."
  (when (eq 'unspecified (face-attribute 'doc-show-inline-face :background))
    ;; Tint the color.
    (let* ((default-color (face-attribute 'default :background))
           (default-tint
            (doc-show-inline--color-highlight
             default-color doc-show-inline-face-background-highlight)))
      ;; Ensure there is some change, otherwise tint in the opposite direction.
      (when (equal default-color default-tint)
        (setq default-tint
              (doc-show-inline--color-highlight
               default-color (- doc-show-inline-face-background-highlight))))
      (set-face-attribute 'doc-show-inline-face nil :background default-tint))))

(defun doc-show-inline--overlays-remove (&optional pos-beg pos-end)
  "Remove overlays between POS-BEG & POS-END."
  (cond
   ;; When logging remove overlays one at a time.
   (doc-show-inline-use-logging
    (let ((overlays-in-view (overlays-in (or pos-beg (point-min)) (or pos-end (point-max)))))
      (when overlays-in-view
        (while overlays-in-view
          (let ((ov (pop overlays-in-view)))
            (when (and (overlay-get ov 'doc-show-inline) (overlay-buffer ov))
              (doc-show-inline--log-info
               "removing overlay in %S at point %d" (current-buffer)
               ;; Start & end are the same.
               (overlay-start ov))
              (delete-overlay ov)))))))
   (t
    (remove-overlays pos-beg pos-end 'doc-show-inline t))))

(defun doc-show-inline--pos-in-overlays (pos overlays)
  "Return non-nil when POS is within OVERLAYS."
  (let ((result nil))
    (while overlays
      (let ((ov (pop overlays)))
        (when (and (>= pos (overlay-start ov)) (< pos (overlay-end ov)))
          (setq result t)
          ;; Break.
          (setq overlays nil))))
    result))

;; See https://emacs.stackexchange.com/questions/30673
;; (adapted from `which-function').
(defun doc-show-inline-locations-default (pos-beg pos-end)
  "Return `imenu' positions for the current buffer between POS-BEG and POS-END."
  ;; Ensure `imenu--index-alist' is populated.
  (unless imenu--index-alist
    (condition-case-unless-debug err
        ;; Note that in some cases a file will fail to parse,
        ;; typically when the file is intended for another platform (for example).
        (imenu--make-index-alist)
      (error
       (doc-show-inline--log-fail
        "IMENU couldn't access symbols (failed to parse?): %s"
        (error-message-string err)))))
  (let ((alist imenu--index-alist)
        (pair nil)
        (mark nil)
        (imstack nil)
        (result nil)

        ;; As the results differ between back-ends, some custom handling is needed.
        (xref-backend (xref-find-backend)))

    ;; Elements of alist are either ("name" . marker), or
    ;; ("submenu" ("name" . marker) ... ). The list can be
    ;; Arbitrarily nested.
    (while (or alist imstack)
      (cond
       (alist
        (setq pair (car-safe alist))
        (setq alist (cdr-safe alist))
        (cond
         ((atom pair)) ; Skip anything not a cons.

         ((imenu--subalist-p pair)
          (setq imstack (cons alist imstack))
          (setq alist (cdr pair)))

         ((number-or-marker-p (setq mark (cdr pair)))
          (let ((pos
                 (cond
                  ((markerp mark)
                   (marker-position mark))
                  (t ; Integer.
                   mark))))

            (unless (or (and pos-beg (<= pos pos-beg)) (and pos-end (>= pos pos-end)))
              (goto-char pos)
              (let ((sym nil))
                (cond
                 ((eq xref-backend 'eglot)
                  ;; EGLOT mode has some differences.
                  ;; - `xref-backend-identifier-at-point' isn't functional.
                  ;; - The point is at the beginning of the line.
                  ;; For this reason, it's necessary to search for `sym' & set the
                  ;; position to this.
                  (setq sym (car pair))
                  (unless (looking-at-p (regexp-quote sym))
                    ;; In most cases limiting by `pos-eol' is sufficient.
                    (save-match-data
                      (when (search-forward sym pos-end t)
                        (setq pos (- (point) (length sym)))))))
                 (t
                  ;; This works for `xref-lsp'.
                  (setq sym (xref-backend-identifier-at-point xref-backend))))

                (push (cons sym pos) result)))))))
       (t
        (setq alist (car imstack))
        (setq imstack (cdr imstack)))))

    result))

(defun doc-show-inline--xref-list-from-definitions (sym xref-backend)
  "Return a list of XREF items from the identifier SYM at the current point.

Argument XREF-BACKEND is used to avoid multiple calls to `xref-find-backend'."
  ;; (printf "SYM: %S\n" sym)
  (let ((xref-list nil))
    (doc-show-inline--with-advice #'xref--not-found-error :override (lambda (_kind _input) nil)
      (doc-show-inline--with-advice #'xref--show-defs :override
                                    (lambda (fetcher _display-action)
                                      (setq xref-list (funcall fetcher)))
        (let ((xref-prompt-for-identifier nil))
          ;; Needed to suppress `etags' from requesting a file.
          (doc-show-inline--with-advice #'read-file-name :override
                                        (lambda (&rest _args)
                                          (doc-show-inline--log-info
                                           "XREF lookup %S requested a file name for backend %S"
                                           (current-buffer)
                                           xref-backend)
                                          ;; File that doesn't exist.
                                          (user-error
                                           "Doc-show-inline: ignoring request for file read"))
            (with-demoted-errors "%S"
              (xref-find-definitions sym))))))
    xref-list))

(defun doc-show-inline--doc-from-xref (sym xref-list)
  "XREF-LIST is a list of `xref' items for SYM."
  ;; Build a list of comments from the `xref' list (which may find multiple sources).
  ;; In most cases only a single item is found.
  ;; Nevertheless, best combine all so a doc-string will be extracted from at least one.
  (let ((text-results nil)
        (current-buf (current-buffer)))

    ;; Don't enable additional features when loading files
    ;; only for the purpose of reading their comments.
    ;; `doc-show-inline-fontify-hook' can be used to enable features needed for comment extraction.
    (save-excursion
      (doc-show-inline--with-advice #'run-mode-hooks :override
                                    (lambda (_hooks)
                                      (with-demoted-errors "doc-show-inline-buffer-hook: %S"
                                        (run-hooks 'doc-show-inline-buffer-hook)))

        (dolist (item xref-list)

          (let* ((marker
                  ;; This sets '(point)' which is OK in this case.
                  (xref-location-marker (xref-item-location item)))
                 (buf (marker-buffer marker)))
            ;; Ignore matches in the same buffer.
            ;; While it's possible doc-strings could be at another location within this buffer,
            ;; in practice, this is almost never done.
            (unless (eq buf current-buf)

              (with-current-buffer buf
                (goto-char marker)
                (pcase-let ((`(,pos-beg . ,pos-end) (funcall doc-show-inline-extract-doc sym)))
                  (when (and pos-beg pos-end)
                    ;; Ensure the comment is properly syntax highlighted,
                    ;; note that we could assume this only uses the comment face
                    ;; however some configurations highlight tags such as TODO
                    ;; or even bad spelling, so font lock this text.
                    (with-demoted-errors "doc-show-inline/font-lock-ensure: %S"
                      (font-lock-ensure pos-beg pos-end))

                    (with-demoted-errors "doc-show-inline-fontify-hook: %S"
                      (run-hook-with-args 'doc-show-inline-fontify-hook pos-beg pos-end))

                    (let ((text
                           (doc-show-inline--buffer-substring-with-overlay-props pos-beg pos-end)))
                      (push text text-results))))))))))

    (cond
     (text-results ; Add a blank item so there is a trailing newline when joining.
      (let ((text (string-join (reverse (cons "" text-results)) "\n")))
        (add-face-text-property 0 (length text) 'doc-show-inline-face t text)
        text))
     (t
      nil))))

(defun doc-show-inline--show-text (pos text)
  "Add an overlay from TEXT at POS."
  (doc-show-inline--log-info
   "adding overlay in %S at point %d has %d length text"
   (current-buffer)
   pos
   (length (or text "")))

  (let ((ov (make-overlay pos pos)))
    ;; Handy for debugging pending regions to be checked.

    (overlay-put ov 'before-string text)
    (overlay-put ov 'doc-show-inline t)
    ov))

(defun doc-show-inline--idle-overlays (pos-beg pos-end)
  "Return a list of valid overlays between POS-BEG and POS-END."
  (let ((result nil))
    (let ((overlays-in-view (overlays-in pos-beg pos-end)))
      (when overlays-in-view
        (while overlays-in-view
          (let ((ov (pop overlays-in-view)))
            (when (and (overlay-get ov 'doc-show-inline-pending) (overlay-buffer ov))
              (push ov result))))))
    result))

(defun doc-show-inline--idle-overlays-remove (&optional pos-beg pos-end)
  "Remove `doc-show-inline-pending' overlays from current buffer.
If optional arguments POS-BEG and POS-END exist
remove overlays from range POS-BEG to POS-END.
Otherwise remove all overlays."
  (remove-overlays pos-beg pos-end 'doc-show-inline-pending t))

(defun doc-show-inline--idle-handle-pos (pos sym xref-backend)
  "Add text for the overlay at POS for SYM.
XREF-BACKEND is the back-end used to find this symbol."
  (cond
   ;; Check if the symbol should be considered for doc-strings,
   ;; some symbols might not make sense such as: '#define FOO' in C
   ;; which can't have been declared elsewhere.
   ((null (funcall doc-show-inline-filter sym))
    (doc-show-inline--log-info
     "symbol \"%s\" in %S at point %d has been ignored by filter %S"
     sym
     (current-buffer)
     pos
     doc-show-inline-filter))
   (t ; Symbol is valid and not filtered out.

    (let ((text t))
      (when doc-show-inline--use-lookup-cache
        (setq text (gethash sym doc-show-inline--lookup-cache t)))

      ;; When true, the value doesn't exist in cache.
      (cond
       ((eq text t)
        (setq text nil)
        (let ((xref-list (doc-show-inline--xref-list-from-definitions sym xref-backend)))
          (doc-show-inline--log-info
           "symbol \"%s\" in %S at point %d has %d reference(s)"
           sym
           (current-buffer)
           pos
           (length xref-list))
          ;; Loads a buffer.
          (when xref-list
            (setq text (doc-show-inline--doc-from-xref sym xref-list))))

        ;; Cache, even when nil (to avoid future lookups to establish it's nil).
        (when doc-show-inline--use-lookup-cache
          (puthash sym text doc-show-inline--lookup-cache))

        (doc-show-inline--log-info
         "symbol \"%s\" in %S at point %d has %d length text"
         sym
         (current-buffer)
         pos
         (length (or text ""))))
       ;; Otherwise cache is used, text is either nil or a string.
       (t
        (doc-show-inline--log-info
         "symbol \"%s\" in %S at point %d has %d length text (cached)"
         sym
         (current-buffer)
         pos
         (length (or text "")))))

      (when text
        (doc-show-inline--show-text (pos-bol) text))))))

(defun doc-show-inline--idle-handle-pending-ranges ()
  "Handle all queued ranges."
  ;; First remove any overlays.
  (when-let ((overlays-in-view (doc-show-inline--idle-overlays (point-min) (point-max))))
    (let ((overlays-beg (point-max))
          (overlays-end (point-min)))

      (dolist (ov overlays-in-view)
        (let ((ov-beg (overlay-start ov))
              (ov-end (overlay-end ov)))
          (doc-show-inline--overlays-remove ov-beg ov-end)

          ;; Calculate the range while removing overlays.
          (setq overlays-beg (min overlays-beg ov-beg))
          (setq overlays-end (max overlays-end ov-end))))

      (save-excursion
        ;; There is something to do, postpone accessing `points'.
        (let ((points (funcall doc-show-inline-locations (point-min) (point-max))))
          (doc-show-inline--log-info
           "found %d identifier(s) in %S"
           (length points)
           (current-buffer))
          (when points
            (let ((temporary-buffers (list))
                  (xref-backend (xref-find-backend))
                  ;; When loading buffers for introspection,
                  ;; there is no need to add `doc-show-inline' there
                  ;; (harmless but not necessary).
                  (doc-show-inline--inhibit-mode t))

              ;; Track buffers loaded.
              (doc-show-inline--with-advice #'create-file-buffer :around
                                            (lambda (fn-orig filename)
                                              (let ((buf (funcall fn-orig filename)))
                                                (when buf
                                                  (push buf temporary-buffers))
                                                buf))

                (while points
                  (pcase-let ((`(,sym . ,pos) (pop points)))
                    (cond
                     ((null (doc-show-inline--pos-in-overlays pos overlays-in-view))
                      (doc-show-inline--log-info
                       "symbol \"%s\" in %S at point %d is not in the overlay list"
                       sym
                       (current-buffer)
                       pos))
                     (t
                      (goto-char pos)
                      (doc-show-inline--idle-handle-pos pos sym xref-backend))))))

              ;; Close any buffers loaded only for the purpose of extracting text.
              (mapc 'kill-buffer temporary-buffers)))))

      ;; Do this last, in the unlikely event of an error or an interruption,
      ;; these overlays will be used again to ensure everything is updated.
      (doc-show-inline--idle-overlays-remove overlays-beg overlays-end))))

(defun doc-show-inline--idle-font-lock-region-pending (pos-beg pos-end)
  "Track the range to check for overlays, adding POS-BEG & POS-END to the queue."
  (let ((ov (make-overlay pos-beg pos-end)))
    (doc-show-inline--log-info "idle overlay [%d..%d] in %S" pos-beg pos-end (current-buffer))

    ;; Handy for debugging pending regions to be checked.
    ;; (overlay-put ov 'face '(:background "#000000" :extend t))

    (overlay-put ov 'doc-show-inline-pending t)

    (overlay-put ov 'evaporate 't)

    (doc-show-inline--timer-ensure t))

  ;; Debug only, disabled by default.
  (when doc-show-inline--idle-overlays-debug
    (setq doc-show-inline--idle-overlays-debug-index
          (1+ doc-show-inline--idle-overlays-debug-index))
    (when (>= doc-show-inline--idle-overlays-debug-index
              (length doc-show-inline--idle-overlays-debug-colors))
      (setq doc-show-inline--idle-overlays-debug-index 0))
    (let ((ov (make-overlay pos-beg pos-end)))
      (overlay-put ov 'doc-show-inline-idle-overlay-debug t)
      (overlay-put
       ov 'face
       (list
        :background
        (nth
         doc-show-inline--idle-overlays-debug-index doc-show-inline--idle-overlays-debug-colors)
        :extend t)))))

(defun doc-show-inline--timer-callback-or-disable (this-timer buf)
  "Callback run from the idle timer THIS-TIMER for BUF."
  ;; Ensure all other buffers are highlighted on request.
  (cond
   ((null (buffer-name buf))
    (doc-show-inline--log-info "idle timer ignored for invalid buffer %S" buf)
    ;; The buffer has been deleted, so cancel the timer directly.
    (cancel-timer this-timer))
   (t
    ;; Needed since the initial time might have been 0.0.
    ;; Ideally this wouldn't need to be set every time.
    (when doc-show-inline--idle-timer
      (timer-set-idle-time doc-show-inline--idle-timer doc-show-inline-idle-delay t))

    (with-current-buffer buf
      (cond
       ((null (get-buffer-window buf t))
        (doc-show-inline--log-info "idle timer ignored for buffer %S without a window" buf))
       ((null (bound-and-true-p doc-show-inline-mode))
        (doc-show-inline--log-info
         "idle timer ignored for buffer %S without `doc-show-inline-mode' set"
         buf))
       (t
        (doc-show-inline--log-info "idle timer for buffer %S callback running..." buf)
        ;; In the unlikely event of an error, run the timer again.
        (doc-show-inline--idle-handle-pending-ranges)))

      (doc-show-inline--timer-ensure nil)))))


(defun doc-show-inline--timer-ensure (state)
  "Ensure the timer is enabled when STATE is non-nil, otherwise disable."
  (cond
   (state
    (cond
     (doc-show-inline--idle-timer
      (doc-show-inline--log-info "idle timer ensure t, already enabled for %S" (current-buffer)))
     (t
      (doc-show-inline--log-info "idle timer ensure t, enabling for %S" (current-buffer))
      (setq doc-show-inline--idle-timer
            ;; One off, set repeat so the timer can be manually disabled,
            ;; ensuring it is only disabled on successful completion.
            ;; Pass a nil function here, set the function & arguments below.
            (run-with-idle-timer
             doc-show-inline-idle-delay t #'doc-show-inline--timer-callback-or-disable))

      (timer-set-function doc-show-inline--idle-timer #'doc-show-inline--timer-callback-or-disable
                          (list
                           ;; Pass the timer, to allow cancellation from the timer.
                           doc-show-inline--idle-timer
                           ;; Pass the buffer (check the buffer is still active).
                           (current-buffer))))))

   (t
    (when doc-show-inline--idle-timer
      (cancel-timer doc-show-inline--idle-timer))
    (kill-local-variable 'doc-show-inline--idle-timer))))

(defun doc-show-inline--timer-reset ()
  "Run this when the buffer was changed."
  ;; Ensure changing windows triggers the idle timer if this buffer uses the mode.
  (when (bound-and-true-p doc-show-inline-mode)
    (doc-show-inline--timer-ensure t)))

(defun doc-show-inline--timer-buffer-local-enable ()
  "Ensure buffer local state is enabled."
  ;; Needed in case focus changes before the idle timer runs.
  (doc-show-inline--timer-ensure t)
  (add-hook 'window-state-change-hook #'doc-show-inline--timer-reset nil t))

(defun doc-show-inline--timer-buffer-local-disable ()
  "Ensure buffer local state is disabled."
  (doc-show-inline--timer-ensure nil)
  (remove-hook 'window-state-change-hook #'doc-show-inline--timer-reset t))


;; ---------------------------------------------------------------------------
;; Gap-less Font Lock Overlay Hack
;;
;; Unfortunately C/C++ font locking performs tricks resulting in gaps in ranges
;; with `jit-lock-register' callbacks.
;; This is annoying but can be worked around using

(defun doc-show-inline--cc-gapless-hack-fn (old-fn beg end)
  "Advice for `c-context-expand-fl-region' (OLD-FN),extract the region (BEG END)."
  (let ((bounds (funcall old-fn beg end)))
    (when (bound-and-true-p doc-show-inline-mode)
      (doc-show-inline--idle-font-lock-region-pending (car bounds) (cdr bounds)))
    bounds))

(defun doc-show-inline--jit-or-gapless-hack-is-needed ()
  "Check if any buffers need this hack."
  (let ((result nil))
    (let ((buffers (buffer-list)))
      (while buffers
        (let ((buf (pop buffers)))
          (when (and (buffer-local-value 'doc-show-inline-mode buf)
                     (memq (buffer-local-value 'major-mode buf) doc-show-inline--cc-modes))
            ;; Break.
            (setq buffers nil)
            (setq result t)))))
    result))

(defun doc-show-inline--jit-or-gapless-hack-set (state)
  "Setup the callback for tracking ranges that need to be handled.
Use STATE to enable/disable."
  (cond
   ((memq major-mode doc-show-inline--cc-modes)
    (cond
     (state
      ;; Needed so existing regions that are highlighted will be
      ;; calculated again with the callback installed.
      (font-lock-flush)
      (advice-add 'c-context-expand-fl-region :around #'doc-show-inline--cc-gapless-hack-fn))
     (t
      ;; Only remove when no other buffers use this mode.
      (unless (doc-show-inline--jit-or-gapless-hack-is-needed)
        (advice-remove 'c-context-expand-fl-region #'doc-show-inline--cc-gapless-hack-fn)))))

   (t
    (cond
     (state
      (jit-lock-register #'doc-show-inline--idle-font-lock-region-pending))
     (t
      (jit-lock-unregister #'doc-show-inline--idle-font-lock-region-pending))))))


;; ---------------------------------------------------------------------------
;; Internal Mode Logic

(defun doc-show-inline--idle-enable ()
  "Enable the idle style of updating."

  (doc-show-inline--init-face-background-once)

  (doc-show-inline--jit-or-gapless-hack-set t)

  ;; Setup default callbacks based on mode.
  (let ((defaults (assoc-default major-mode doc-show-inline-mode-defaults 'eq nil)))
    ;; Set unless the user has set this already.
    (unless doc-show-inline-filter
      (setq doc-show-inline-filter (or (plist-get defaults :filter) 'identity))))

  (doc-show-inline--timer-buffer-local-enable))

(defun doc-show-inline--idle-disable ()
  "Disable the idle style of updating."

  (doc-show-inline--jit-or-gapless-hack-set nil)

  (doc-show-inline--overlays-remove)
  (doc-show-inline--idle-overlays-remove)
  (doc-show-inline--timer-buffer-local-disable)

  ;; Debug only, disabled by default.
  (when doc-show-inline--idle-overlays-debug
    (remove-overlays (point-min) (point-max) 'doc-show-inline-idle-overlay-debug t)))

;;;###autoload
(defun doc-show-inline-buffer ()
  "Calculate overlays for the whole buffer."
  (interactive)

  (unless (bound-and-true-p doc-show-inline-mode)
    (user-error "Error: doc-show-inline-mode is not active!"))

  (font-lock-ensure (point-min) (point-max))
  (doc-show-inline--idle-font-lock-region-pending (point-min) (point-max))
  (doc-show-inline--idle-handle-pending-ranges)
  ;; No need for the timer.
  (doc-show-inline--timer-ensure nil))


;; ---------------------------------------------------------------------------
;; Define Minor Mode
;;
;; Developer note, use global hooks since these run before buffers are loaded.
;; Each function checks if the local mode is active before operating.

(defun doc-show-inline--mode-enable (&optional is-interactive)
  "Turn on option `doc-show-inline-mode' for the current buffer.
When IS-INTERACTIVE is true, use `doc-show-inline-idle-delay-init'."

  (when doc-show-inline--use-lookup-cache
    (setq doc-show-inline--lookup-cache (make-hash-table :test 'equal)))

  (doc-show-inline--idle-enable)

  ;; Should always be true.
  (when doc-show-inline--idle-timer
    ;; When loading for the first time, postpone `timer-set-idle-time',
    ;; since `lsp-mode' may take some time to initialize.
    ;; Otherwise this can run immediately when started on an existing buffer.
    (timer-set-idle-time doc-show-inline--idle-timer
                         (cond
                          (is-interactive
                           0.0)
                          (t
                           doc-show-inline-idle-delay-init))
                         ;; Repeat.
                         t)))

(defun doc-show-inline--mode-disable ()
  "Turn off option `doc-show-inline-mode' for the current buffer."

  (when doc-show-inline--use-lookup-cache
    (kill-local-variable 'doc-show-inline--lookup-cache))

  (doc-show-inline--idle-disable))

;;;###autoload
(define-minor-mode doc-show-inline-mode
  "Toggle variable `doc-show-inline-mode' in the current buffer."
  :global nil

  (cond
   (doc-show-inline-mode
    (unless doc-show-inline--inhibit-mode
      (doc-show-inline--mode-enable (called-interactively-p 'interactive))))
   (t
    (doc-show-inline--mode-disable))))

;; Evil Mode (setup if in use).
;;
;; Don't let these commands repeat as they are for the UI, not editor.
;;
;; Notes:
;; - Package lint complains about using this command,
;;   however it's needed to avoid issues with `evil-mode'.
(declare-function evil-declare-not-repeat "ext:evil-common")
(with-eval-after-load 'evil
  (mapc #'evil-declare-not-repeat doc-show-inline--commands))

(provide 'doc-show-inline)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; doc-show-inline.el ends here
