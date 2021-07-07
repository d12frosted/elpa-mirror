;;; lusty-explorer.el --- Dynamic filesystem explorer and buffer switcher -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2008-2020 Stephen Bach
;;
;; Version: 3.2
;; Package-Version: 20200602.228
;; Package-Commit: a746514ccd8df71fc920ba8ad0aa8dca58702631
;; Keywords: convenience, files, matching, tools
;; URL: https://github.com/sjbach/lusty-emacs
;; Package-Requires: ((emacs "25.1"))
;;
;; Permission is hereby granted to use and distribute this code, with or
;; without modifications, provided that this copyright notice is copied with
;; it. Like anything else that's free, lusty-explorer.el is provided *as is*
;; and comes with no warranty of any kind, either expressed or implied. In no
;; event will the copyright holder be liable for any damages resulting from
;; the use of this software.

;;; Commentary:
;;  -----------
;;
;; To install, copy this file somewhere in your load-path and add this line to
;; your .emacs:
;;
;;    (require 'lusty-explorer)
;;
;; To launch the explorer, run or bind the following commands:
;;
;;    M-x lusty-file-explorer
;;    M-x lusty-buffer-explorer
;;
;; And then use as you would `find-file' or `switch-to-buffer'. A split window
;; shows the *Lusty-Matches* buffer, which updates dynamically as you type
;; using a fuzzy matching algorithm.  One match is highlighted; you can move
;; the highlight using C-n / C-p (next, previous) and C-f / C-b (next column,
;; previous column).  Pressing TAB or RET will select the highlighted match
;; (with slightly different semantics).
;;
;; To create a new buffer with the given name, press C-x e.  To open dired at
;; the current viewed directory, press C-x d.
;;
;;; Customization:
;;  --------------
;;
;; To modify the keybindings, use something like:
;;
;;   (add-hook 'lusty-setup-hook 'my-lusty-hook)
;;   (defun my-lusty-hook ()
;;     (define-key lusty-mode-map "\C-j" 'lusty-highlight-next))
;;
;; Respects these variables:
;;   completion-ignored-extensions
;;
;; Development:    <https://github.com/sjbach/lusty-emacs>
;; Further info:   <https://www.emacswiki.org/cgi-bin/wiki/LustyExplorer>
;;                 (Probably out-of-date)
;;

;;; Contributors:
;;
;; Tassilo Horn
;; Jan Rehders
;; Hugo Schmitt
;; Volkan Yazici
;; René Kyllingstad
;; Alex Schroeder
;; Sasha Kovar
;; John Wiegley
;; Johan Walles
;; p3r7
;; Nick Alcock
;; Jonas Bernoulli
;;

;;; Code:

;; TODO:
;; - highlight opened buffers in filesystem explorer
;; - FIX: deal with permission-denied
;; - C-e/C-a -> last/first column?
;; - config var: C-x d opens highlighted dir instead of current dir


(require 'cl-lib)  ; many functions and macros
(require 'dired)  ; faces only
(eval-when-compile (require 'subr-x))  ; string trimming

(cl-declaim (optimize (speed 3) (safety 0)))

(defgroup lusty-explorer nil
  "Quickly open new files or switch among open buffers."
  :group 'extensions
  :group 'convenience
  :version "23")

(defcustom lusty-setup-hook nil
  "Hook run after the lusty keymap has been setup.
Additional keys can be defined in `lusty-mode-map'."
  :type 'hook
  :group 'lusty-explorer)

(defcustom lusty-idle-seconds-per-refresh 0.05
  "Seconds to wait for additional input before updating matches window.
Can be floating point; 0.05 = 50 milliseconds.  Set to 0 to disable.
Note: only affects `lusty-file-explorer'; `lusty-buffer-explorer' is
always immediate."
  :type 'number
  :group 'lusty-explorer)

(defcustom lusty-buffer-MRU-contribution 0.1
  "How much influence buffer recency-of-use should have on ordering of
buffer names in the matches window; 0.10 = 10%."
  :type 'float
  :group 'lusty-explorer)

(defcustom lusty-case-fold t
  "Ignore case when matching if non-nil."
  :type 'boolean
  :group 'lusty-explorer)

(defface lusty-match-face
  '((t :inherit highlight))
  "The face used for the current match."
  :group 'lusty-explorer)

(defface lusty-directory-face
  '((t :inherit dired-directory))
  "The face used for directory completions."
  :group 'lusty-explorer)

(defface lusty-slash-face
  '((t :weight bold :foreground "red"))
  "The face used for the slash after directories."
  :group 'lusty-explorer)

(defface lusty-file-face
  nil ;; Use default face...
  "The face used for normal files."
  :group 'lusty-explorer)

(defface lusty-no-matches
  '((t :inherit isearch-fail :weight bold))
  "Face used for styling the \"NO MATCHES\" line."
  :group 'lusty-explorer)

(defface lusty-truncated
  '((t :inherit shadow :weight bold))
  "Face used for styling the \"TRUNCATED\" token."
  :group 'lusty-explorer)

(defvar lusty-buffer-name " *Lusty-Matches*")
(defvar lusty-prompt ">> ")
(defvar lusty-column-separator "    ")
(defvar lusty-no-matches-string
  "-- NO MATCHES --")
(defvar lusty-truncated-string
  "TRUNCATED")

(defvar lusty-mode-map nil
  "Minibuffer keymap for `lusty-file-explorer' and `lusty-buffer-explorer'.")

(defvar lusty-global-map
  (let ((map (make-sparse-keymap)))
    (dolist (b '((switch-to-buffer . lusty-buffer-explorer)
                 (find-file . lusty-file-explorer)))
      (define-key map (vector 'remap (car b)) (cdr b)))
    map))

(defvar lusty--active-mode nil)
(defvar lusty--wrapping-ido-p nil)
(defvar lusty--initial-window-config nil)
(defvar lusty--previous-minibuffer-contents nil)
(defvar lusty--current-idle-timer nil)

(defvar lusty--ignored-extensions-regex
  ;; Recalculated at execution time.
  (concat "\\(?:" (regexp-opt completion-ignored-extensions) "\\)$"))

(defvar lusty--highlighted-coords (cons 0 0))  ; (x . y)

;; Set later by `lusty--compute-layout-matrix'.
(defvar lusty--matches-matrix (make-vector 0 nil))
(defvar lusty--matrix-column-widths '())
(defvar lusty--matrix-truncated-p nil)

(when lusty--wrapping-ido-p
  (require 'ido))
(defvar ido-text) ; silence compiler warning

(defsubst lusty--matrix-empty-p ()
  (zerop (length lusty--matches-matrix)))
(defsubst lusty--matrix-coord-valid-p (x y)
  (not (or (cl-minusp x)
           (cl-minusp y)
           (>= x (length lusty--matches-matrix))
           (>= y (length (aref lusty--matches-matrix 0)))
           (null (aref (aref lusty--matches-matrix x) y)))))

(defun lusty--compute-column-width (start-index end-index lengths-v lengths-h)
  ;; Dynamic programming algorithm. Split the index range into smaller and
  ;; smaller chunks in recursive calls to this function, then calculate and
  ;; memoize the widths from the bottom up. The memoized widths are likely to
  ;; be used again in subsequent calls to this function.
  ;;
  ;; Note: this gets called a lot and would best be speedy.
  (if (= start-index end-index)
      ;; This situation describes a column consisting of a single element.
      (aref lengths-v start-index)
    (let* ((range-key (cons start-index end-index))
           (memoized-width (gethash range-key lengths-h)))
      (or memoized-width
          (let* ((split-point
                  (+ start-index
                     ;; Same thing as: (/ (- end-index start-index) 2)
                     (ash (- end-index start-index) -1)))
                 (width-first-half
                  (lusty--compute-column-width
                   start-index split-point
                   lengths-v lengths-h))
                 (width-second-half
                  (lusty--compute-column-width
                   (1+ split-point) end-index
                   lengths-v lengths-h)))
            (puthash range-key
                     (max width-first-half width-second-half)
                     lengths-h))))))

(defun lusty--propertize-path (path)
  "Propertize the given PATH like so: <dir></> or <file>.
Uses the faces `lusty-directory-face', `lusty-slash-face', and
`lusty-file-face'."
  (let ((last (1- (length path))))
    ;; Note: shouldn't get an empty path, so for performance
    ;; I'm not going to check for that case.
    (if (eq (aref path last) ?/) ; <-- FIXME nonportable?
        (progn
          ;; Directory
          (put-text-property 0 last 'face 'lusty-directory-face path)
          (put-text-property last (1+ last) 'face 'lusty-slash-face path))
      (put-text-property 0 (1+ last) 'face 'lusty-file-face path)))
  path)

;;;###autoload
(defun lusty-file-explorer ()
  "Launch the file/directory mode of LustyExplorer."
  (interactive)
  (let ((completing-read-function #'completing-read-default)
        (lusty--active-mode :file-explorer))
    (lusty--define-mode-map)
    (let* ((lusty--ignored-extensions-regex
            (concat "\\(?:" (regexp-opt completion-ignored-extensions) "\\)$"))
           (minibuffer-local-filename-completion-map lusty-mode-map)
           (file
            ;; `read-file-name' is odd in that if the result is equal to the
            ;; dir argument, it gets converted to the default-filename
            ;; argument. Set default-filename explicitly to "" so if
            ;; `lusty-launch-dired' is called in the directory we start at, the
            ;; result is that directory rather than the name of the current
            ;; buffer.
            (lusty--run 'read-file-name default-directory "")))
      (when file
        (switch-to-buffer
         (find-file-noselect
          (expand-file-name file)))))))

;;;###autoload
(defun lusty-buffer-explorer ()
  "Launch the buffer mode of LustyExplorer."
  (interactive)
  (let ((completing-read-function #'completing-read-default)
        (lusty--active-mode :buffer-explorer))
    (lusty--define-mode-map)
    (let* ((minibuffer-local-completion-map lusty-mode-map)
           (buffer (lusty--run 'read-buffer)))
      (when buffer
        (switch-to-buffer buffer)))))

;;;###autoload
(define-minor-mode lusty-explorer-mode
  "Toggle Lusty Explorer mode.
With a prefix argument ARG, enable Lusty Explorer mode if ARG is
positive, and disable it otherwise.  If called from Lisp, enable
the mode if ARG is omitted or nil.

Lusty Explorer mode is a global minor mode that enables switching
between buffers and finding files using substrings, fuzzy matching,
and recency information."
  nil nil lusty-global-map :global t)

;;;###autoload
(defun lusty-highlight-next ()
  "Highlight the next match in *Lusty-Matches*."
  (interactive)
  (when (and lusty--active-mode
             (not (lusty--matrix-empty-p)))
    (cl-destructuring-bind (x . y) lusty--highlighted-coords
      ;; Unhighlight previous highlight.
      (let ((prev-highlight
             (aref (aref lusty--matches-matrix x) y)))
        (lusty--propertize-path prev-highlight))
      ;; Determine the coords of the next highlight.
      (cl-incf y)
      (unless (lusty--matrix-coord-valid-p x y)
        (cl-incf x)
        (setq y 0)
        (unless (lusty--matrix-coord-valid-p x y)
          (setq x 0)))
      ;; Refresh with new highlight.
      (setq lusty--highlighted-coords (cons x y))
      (lusty-refresh-matches-buffer :use-previous-matrix))))

;;;###autoload
(defun lusty-highlight-previous ()
  "Highlight the previous match in *Lusty-Matches*."
  (interactive)
  (when (and lusty--active-mode
             (not (lusty--matrix-empty-p)))
    (cl-destructuring-bind (x . y) lusty--highlighted-coords
      ;; Unhighlight previous highlight.
      (let ((prev-highlight
             (aref (aref lusty--matches-matrix x) y)))
        (lusty--propertize-path prev-highlight))
      ;; Determine the coords of the next highlight.
      (cl-decf y)
      (unless (lusty--matrix-coord-valid-p x y)
        (let ((n-cols (length lusty--matches-matrix))
              (n-rows (length (aref lusty--matches-matrix 0))))
          (cl-decf x)
          (setq y (1- n-rows))
          (unless (lusty--matrix-coord-valid-p x y)
            (setq x (1- n-cols))
            (while (not (lusty--matrix-coord-valid-p x y))
              (cl-decf y)))))
      ;; Refresh with new highlight.
      (setq lusty--highlighted-coords (cons x y))
      (lusty-refresh-matches-buffer :use-previous-matrix))))

;;;###autoload
(defun lusty-highlight-next-column ()
  "Highlight the next column in *Lusty-Matches*."
  (interactive)
  (when (and lusty--active-mode
             (not (lusty--matrix-empty-p)))
    (cl-destructuring-bind (x . y) lusty--highlighted-coords
      ;; Unhighlight previous highlight.
      (let ((prev-highlight
             (aref (aref lusty--matches-matrix x) y)))
        (lusty--propertize-path prev-highlight))
      ;; Determine the coords of the next highlight.
      (cl-incf x)
      (unless (lusty--matrix-coord-valid-p x y)
        (setq x 0)
        (cl-incf y)
        (unless (lusty--matrix-coord-valid-p x y)
          (setq y 0)))
      ;; Refresh with new highlight.
      (setq lusty--highlighted-coords (cons x y))
      (lusty-refresh-matches-buffer :use-previous-matrix))))

;;;###autoload
(defun lusty-highlight-previous-column ()
  "Highlight the previous column in *Lusty-Matches*."
  (interactive)
  (when (and lusty--active-mode
             (not (lusty--matrix-empty-p)))
    (cl-destructuring-bind (x . y) lusty--highlighted-coords
      ;; Unhighlight previous highlight.
      (let ((prev-highlight
             (aref (aref lusty--matches-matrix x) y)))
        (lusty--propertize-path prev-highlight))
      ;; Determine the coords of the next highlight.
      (let ((n-cols (length lusty--matches-matrix))
            (n-rows (length (aref lusty--matches-matrix 0))))
        (if (and (zerop x)
                 (zerop y))
            (progn
              (setq x (1- n-cols)
                    y (1- n-rows))
              (while (not (lusty--matrix-coord-valid-p x y))
                (cl-decf y)))
          (cl-decf x)
          (unless (lusty--matrix-coord-valid-p x y)
            (setq x (1- n-cols))
            (cl-decf y)
            (unless (lusty--matrix-coord-valid-p x y)
              (while (not (lusty--matrix-coord-valid-p x y))
                (cl-decf x))))))
      ;; Refresh with new highlight.
      (setq lusty--highlighted-coords (cons x y))
      (lusty-refresh-matches-buffer :use-previous-matrix))))

;;;###autoload
(defun lusty-open-this ()
  "Open the given file/directory/buffer, creating it if not already present."
  (interactive)
  (when lusty--active-mode
    (if (lusty--matrix-empty-p)
        ;; No matches - open a new buffer/file with the current name.
        (lusty-select-current-name)
      (cl-ecase lusty--active-mode
        (:file-explorer
         (let* ((path (minibuffer-contents-no-properties))
                (last-char (aref path (1- (length path)))))
           (if (and (file-directory-p path)
                   (not (eq last-char ?/))) ; <-- FIXME nonportable?
               ;; Current path is a directory, sans-slash.  Open in dired.
               (lusty-select-current-name)
             ;; Just activate the current match as normal.
             (lusty-select-match))))
        (:buffer-explorer (lusty-select-match))))))

;;;###autoload
(defun lusty-select-match ()
  "Activate the highlighted match in *Lusty-Matches* - recurse if dir, open if file/buffer."
  (interactive)
  (cl-destructuring-bind (x . y) lusty--highlighted-coords
    (when (and lusty--active-mode
               (not (lusty--matrix-empty-p)))
      (cl-assert (lusty--matrix-coord-valid-p x y))
      (let ((selected-match
             (aref (aref lusty--matches-matrix x) y)))
        (cl-ecase lusty--active-mode
          (:file-explorer (lusty--file-explorer-select selected-match))
          (:buffer-explorer (lusty--buffer-explorer-select selected-match)))))))

;;;###autoload
(defun lusty-yank (arg)
  "A `yank' variant that adds some intuitive behavior in the case where
`default-directory' is at the root (\"/\") of a remote TRAMP connection and the
pasted path is absolute (i.e. has a leading \"/\"). The pasted path is
assumed to be on the remote filesystem rather than the local (that being the
default behavior, generally less useful)."
  (interactive "P")
  ;; (Possibly superstition, but other `yank' overrides do it.)
  (setq this-command 'yank)
  (unless arg
    (setq arg 0))
  (let ((text (string-trim (current-kill arg))))
    (cond
     ((and (region-active-p)
           delete-selection-mode)
      (delete-region (region-beginning) (region-end))
      (insert-for-yank text))
     ((and (eq (char-before) ?/)
           (eq (char-before (1- (point))) ?:)
           (string-prefix-p "/" text))
      (insert-for-yank (replace-regexp-in-string "^/" ""
                                                 text)))
     (t
      (push-mark (point))
      (insert-for-yank text)))))

;;;###autoload
(defun lusty-select-current-name ()
  "Open the given file/buffer or create a new buffer with the current name."
  (interactive)
  (when lusty--active-mode
    (exit-minibuffer)))

;;;###autoload
(defun lusty-launch-dired ()
  "Launch dired at the current directory."
  (interactive)
  (when (eq lusty--active-mode :file-explorer)
    (let* ((path (minibuffer-contents-no-properties))
           (dir (lusty-normalize-dir (file-name-directory path))))
      (lusty-set-minibuffer-text dir)
      (exit-minibuffer))))

(defun lusty-sort-by-fuzzy-score (strings abbrev)
  ;; TODO: case-sensitive when abbrev contains capital letter
  (let* ((strings+scores
          (cl-loop for str in strings
                   for score = (lusty-LM-score str abbrev)
                   unless (zerop score)
                   collect (cons str score)))
         (sorted
          (cl-sort strings+scores '> :key 'cdr)))
    (mapcar 'car sorted)))

(defun lusty-normalize-dir (dir)
  "Clean up the given directory path."
  (if (and dir (cl-plusp (length dir)))
      (setq dir (abbreviate-file-name
                 (expand-file-name
                  (substitute-in-file-name dir))))
    (setq dir "."))
  (and (file-directory-p dir)
       dir))

(defun lusty-complete-env-variable (path)
  "Look for an environment variable in PATH and try to complete it as
much as possible."
  (when (string-match "\$\\([[:word:]_]+\\)" path)
    (let* ((partial-var (match-string 1 path))
           (vars (mapcar (lambda (x)
                           (string-match "^[^=]+" x)
                           (match-string 0 x))
                         (cl-remove-if-not
                          (lambda (x)
                            (string-match (concat "^" partial-var) x))
                          process-environment)))
           (longest-completion (try-completion partial-var vars)))
      (cond ((eq t longest-completion) nil)
            ((null longest-completion) nil)
            ((> (length longest-completion) (length partial-var))
             (replace-regexp-in-string (concat "\$" partial-var)
                                       (concat "\$" longest-completion)
                                       path t t))))))

(defun lusty-filter-buffers (buffers)
  "Return BUFFERS converted to strings with hidden buffers removed."
  (cl-macrolet ((ephemeral-p (name)
                  `(eq (string-to-char ,name) ?\ )))
    (cl-loop for buffer in buffers
             for name = (buffer-name buffer)
             unless (ephemeral-p name)
             collect (copy-sequence name))))

;; Written kind-of silly for performance.
(defun lusty-filter-files (file-portion files)
  "Return FILES with './' removed and hidden files if FILE-PORTION
does not begin with '.'."
  (cl-macrolet ((leading-dot-p (str)
                  `(eq (string-to-char ,str) ?.))
                (pwd-p (str)
                  `(string= ,str "./"))
                (ignored-p (name)
                  `(string-match lusty--ignored-extensions-regex ,name)))
    (let ((filtered-files '()))
      (if (leading-dot-p file-portion)
          (dolist (file files)
            (unless (or (pwd-p file)
                        (ignored-p file))
              (push file filtered-files)))
        (dolist (file files)
          (unless (or (leading-dot-p file)
                      (ignored-p file))
            (push file filtered-files))))
      (nreverse filtered-files))))

(defun lusty-set-minibuffer-text (&rest args)
  "Sets ARGS into the minibuffer after the prompt."
  (cl-assert (minibufferp))
  (delete-region (minibuffer-prompt-end) (point-max))
  (apply #'insert args))

(defun lusty--file-explorer-select (match)
  (let* ((path (minibuffer-contents-no-properties))
         (var-completed-path (lusty-complete-env-variable path)))
    (if var-completed-path
        ;; We've completed a variable name (at least partially) -- set it and
        ;; leave, since it's confusing to do two kinds of completion at once.
        (lusty-set-minibuffer-text var-completed-path)
      (let* ((dir (file-name-directory path))
             (normalized-dir (lusty-normalize-dir dir)))
        ;; Clean up the path when selecting, in case we recurse.
        (remove-text-properties 0 (length match) '(face) match)
        (lusty-set-minibuffer-text normalized-dir match)
        (if (file-directory-p (concat normalized-dir match))
            (progn
              (setq lusty--highlighted-coords (cons 0 0))
              (lusty-refresh-matches-buffer))
          (minibuffer-complete-and-exit))))))

(defun lusty--buffer-explorer-select (match)
  (lusty-set-minibuffer-text match)
  (minibuffer-complete-and-exit))

;; Called after each command while lusty is running. We only care about
;; commands that modify the minibuffer content, e.g. `self-insert-command'.
(defun lusty--post-command-function ()
  (if (null lusty--active-mode)
      ;; Anomalous; lusty is not running but this function is somehow still
      ;; attached to `post-command-hook'.
      (lusty--clean-up)
    (when (and (minibufferp)
               (or (null lusty--previous-minibuffer-contents)
                   (not (string= lusty--previous-minibuffer-contents
                                 (minibuffer-contents-no-properties)))))
      (let ((startup-p (null lusty--initial-window-config)))
        (when startup-p
          (lusty--setup-matches-window
           (lusty--get-or-create-matches-buffer lusty-buffer-name)))
        (setq lusty--previous-minibuffer-contents
              (minibuffer-contents-no-properties))
        (setq lusty--highlighted-coords
              (cons 0 0))
        ;; Refresh matches.
        (if (or startup-p
                (null lusty-idle-seconds-per-refresh)
                (zerop lusty-idle-seconds-per-refresh)
                (eq lusty--active-mode :buffer-explorer))
            ;; No idle timer on first update, and never for buffer explorer.
            (lusty-refresh-matches-buffer)
          (when lusty--current-idle-timer
            (cancel-timer lusty--current-idle-timer))
          (setq lusty--current-idle-timer
                (run-with-idle-timer lusty-idle-seconds-per-refresh nil
                                     #'lusty-refresh-matches-buffer)))))))

(defun lusty--max-window-body-height (&optional window)
  "Return the expected maximum allowable height of a window body
on the current frame."
  (cl-assert (or (null window)
                 (window-live-p window)))
  (let* ((test-window
          (or window
              (when-let ((buffer (get-buffer lusty-buffer-name)))
                (get-buffer-window buffer))
              ;; Fall back to a different window.
              (if (minibufferp)
                  (next-window (selected-window) 'skip-mini)
                (selected-window)))))
    (cl-assert test-window)
    (let* ((max-delta
            (window-max-delta test-window
                              nil  ; not horizontal
                              test-window)))  ; ignore restrictions
      (+ (window-height test-window)
         max-delta))))
(defalias 'lusty-max-window-height 'lusty--max-window-body-height
  "Deprecated name.")

(defun lusty--min-matches-window-height ()
  ;; A height of 1 works but looks too cramped.
  (max 2 window-safe-min-height))

(defun lusty--exploitable-window-body-width (&optional window)
  (unless window
    (setq window
          (or (get-buffer-window (get-buffer lusty-buffer-name))
              (selected-window))))
  (let* ((body-width (window-body-width window))
         (window-fringe-absent-p
          (and (equal (window-fringes) '(0 0 nil nil))
               ;; (Probabably these are redundant checks.)
               (eq (frame-fringe-width) 0)
               ;; There are also `left-fringe-width`, `right-fringe-width`, but
               ;; I'm not sure about them.
               )))
    ;; Emacs manual for window-body-width: "Note that the returned value
    ;; includes the column reserved for the continuation glyph." So if we're
    ;; configured such that a continuation glyph would show, we need to
    ;; subtract one column for the "true" body width.
    ;;
    ;; Elsewhere in the manual: "[When] fringes are not available, Emacs uses
    ;; the leftmost and rightmost character cells to indicate continuation and
    ;; truncation with special ASCII characters ... .";
    ;;
    ;; So if we have no fringe, we can expect to lose that one column. There
    ;; doesn't appear to be a way to reclaim it. We can possibly change the
    ;; continuation character with `set-display-table-slot`, but not elide the
    ;; character altogether.
    (if window-fringe-absent-p
        (1- body-width)
      body-width)))

(defun lusty--setup-matches-window (buffer)
  (cl-assert (buffer-live-p buffer))
  (let* ((window
          (let ((ignore-window-parameters t))
            (split-window (frame-root-window)
                          (- (lusty--min-matches-window-height))
                          'below))))
    (set-window-buffer window buffer))
  ;; Window configuration may be restored intermittently.
  (setq lusty--initial-window-config (current-window-configuration)))

(defun lusty--quit-if-active ()
  (interactive)
  (if lusty--active-mode
      ;; This will lead to an unwind which calls `lusty--clean-up'.
      (if (fboundp 'minibuffer-keyboard-quit)
          (minibuffer-keyboard-quit)
        ;; Package `delsel' is not always loaded.
        (abort-recursive-edit))
    ;; Fallback; lusty is not running. This is anomalous. Either lusty crashed
    ;; and this window is left over, or the user has purposely selected the
    ;; hidden buffer in another window. Just quit the buffer and keep the
    ;; window.
    (quit-window)))

(defvar lusty--matches-buffer-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    ;; Realistically, user isn't intending to run `revert-buffer'.
    (define-key map "g" nil)
    ;; Have "q" and C-g" perform exit and clean-up.
    (define-key map [remap quit-window] #'lusty--quit-if-active)
    (define-key map [remap keyboard-quit] #'lusty--quit-if-active) map))

(define-derived-mode lusty--matches-buffer-mode special-mode "Lusty-Matches"
  "Major mode used in the \"*Lusty-Matches*\" buffer.
Not relevant to the user, generally."
  :group 'lusty-explorer)

(defun lusty--get-or-create-matches-buffer (buffer-name)
  (pcase-let ((`(,matches-buffer ,newly-created-p)
               (pcase (get-buffer buffer-name)
                 ((and (pred buffer-live-p) buf)
                  (cl-values buf nil))
                 (_
                  (cl-values (get-buffer-create buffer-name) t)))))
    (when newly-created-p
      (with-current-buffer matches-buffer
        (lusty--matches-buffer-mode)
        (when visual-line-mode
          (visual-line-mode -1))
        (unless truncate-lines
          ;; More gracefully handle any unconsidered corner cases in the
          ;; layout algorithm. If an inserted line of completions happens to
          ;; be longer than the window's text body -- which shouldn't happen
          ;; -- don't wrap the line, just show a truncation indicator in the
          ;; fringe (or, if there's no fringe, in the final text column).
          ;;
          ;; (Don't emit noisy line about truncation to *Messages*.)
          (let ((message-log-max nil))
            (toggle-truncate-lines 1)
            (message "")))
        ;; No mode-line -- acquire an extra display row.
        (when mode-line-format
          (setq-local mode-line-format nil))
        ;; Minor look-and-feel tweaks. We disable these display settings in
        ;; the completions buffer in case the user has enabled them globally.
        (setq-local indicate-buffer-boundaries nil)
        (setq-local show-trailing-whitespace nil)
        (setq-local indicate-empty-lines nil)
        (setq-local word-wrap nil)
        (setq-local line-prefix nil)
        ;; In graphical Emacs don't display an inactive cursor in the matches
        ;; window. But if the window happens to be selected by the user, do
        ;; show a cursor. (Terminal Emacs never displays the cursor of an
        ;; inactive window.)
        (setq-local cursor-in-non-selected-windows nil)
        (buffer-disable-undo)))
    matches-buffer))

(defun lusty-refresh-matches-buffer (&optional use-previous-matrix-p)
  "Refresh *Lusty-Matches*."
  (cl-assert (minibufferp))
  (let* ((minibuffer-text (if lusty--wrapping-ido-p
                              ido-text
                            (minibuffer-contents-no-properties))))
    (unless use-previous-matrix-p
      ;; Refresh the matches and layout matrix
      (let ((matches
             (cl-ecase lusty--active-mode
               (:file-explorer
                (lusty-file-explorer-matches minibuffer-text))
               (:buffer-explorer
                (lusty-buffer-explorer-matches minibuffer-text)))))
        (lusty--compute-layout-matrix matches)))
    ;; Create/update the matches window.
    (let ((matches-buffer
           (lusty--get-or-create-matches-buffer lusty-buffer-name)))
      (with-current-buffer matches-buffer
        (let ((buffer-read-only nil))
          (with-silent-modifications
            (atomic-change-group
              (erase-buffer)
              (lusty--display-matches)))
          (goto-char (point-min))
          (set-buffer-modified-p nil)))
      (when (one-window-p 'nomini)
        ;; Our matches window has somehow become the only window in the frame.
        ;; Restore the original window configuration before resizing the window
        ;; so that the minibuffer won't grow to an unusual size. (Aside: this
        ;; may have only been an issue in older versions of Emacs, now
        ;; unsupported.)
        (set-window-configuration lusty--initial-window-config))
      (let* ((window
              (display-buffer matches-buffer))
             (max-height
              (lusty--max-window-body-height window))
             (max-delta
              (- max-height
                 (window-height window)))
             (delta
              (min max-delta
                   (- (max (lusty--min-matches-window-height)
                           (with-current-buffer matches-buffer
                             (count-lines (point-min) (point-max))))
                      (window-height window)))))
        (set-window-hscroll window 0)  ; probably not necessary
        (unless (zerop delta)
          (window-resize window
                         delta
                         nil  ; horizontal
                         window))))))  ; ignore

(defun lusty-buffer-list ()
  "Return a list of buffers ordered with those currently visible at the end."
  (let ((visible-buffers '()))
    (walk-windows
     (lambda (window)
       ;; Add visible buffers
       (let ((b (window-buffer window)))
         (unless (memq b visible-buffers)
           (push b visible-buffers))))
     nil 'visible)
    (let ((non-visible-buffers
           (cl-loop for b in (buffer-list (selected-frame))
                    unless (memq b visible-buffers)
                    collect b)))
      (nconc non-visible-buffers visible-buffers))))

(defun lusty-buffer-explorer-matches (match-text)
  (let ((buffers (lusty-filter-buffers (lusty-buffer-list))))
    (if (string= match-text "")
        ;; Sort by MRU.
        buffers
      ;; Sort by fuzzy score and MRU order.
      (let* ((score-table
              (cl-loop with MRU-factor-step = (/ lusty-buffer-MRU-contribution
                                                 (length buffers))
                       for b in buffers
                       for step from 0.0 by MRU-factor-step
                       for score = (lusty-LM-score b match-text)
                       for MRU-factor = (- 1.0 step)
                       unless (zerop score)
                       collect (cons b (* score MRU-factor))))
             (sorted
              (cl-sort score-table '> :key 'cdr)))
        (mapcar 'car sorted)))))

;; FIXME: return an array instead of a list?
(defun lusty-file-explorer-matches (path)
  (let* ((dir (lusty-normalize-dir (file-name-directory path)))
         (file-portion (file-name-nondirectory path))
         (files
          (and dir
               ; NOTE: directory-files is quicker but
               ;       doesn't append slash for directories.
               ;(directory-files dir nil nil t)
               (file-name-all-completions "" dir)))
         (filtered (lusty-filter-files file-portion files)))
    (if (or (string= file-portion "")
            (string= file-portion "."))
        (sort filtered #'string<)
      (lusty-sort-by-fuzzy-score filtered file-portion))))

;; Principal goal: fit as many items as possible into as few buffer/window rows
;; as possible. This leads to maximizing the number of columns (approximately).
(defun lusty--compute-layout-matrix (items)
  (let* ((max-visible-rows
          ;; -1 is for a potential TRUNCATION indicator line.
          (1- (lusty--max-window-body-height)))
         (max-width
          ;; Prior to calling this function we called
          ;; `lusty--setup-matches-window', which expanded the window for the
          ;; matches buffer horizontally as much as it could. Therefore the
          ;; current width of that window is the maximum width.
          (lusty--exploitable-window-body-width))
         ;; Upper bound of the count of displayable items.
         (upper-bound most-positive-fixnum)  ; (set below)
         (n-items (length items))
         (lengths-v (make-vector n-items 0))
         (separator-length (length lusty-column-separator)))
    (let ((length-of-longest-name 0)) ; used to determine upper-bound
      ;; Initialize lengths-v
      (cl-loop for i from 0
               for item in items
               for len = (length item)
               do
            (aset lengths-v i len)
            (setq length-of-longest-name
                  (max length-of-longest-name len)))
      ;; Calculate an upper-bound.
      (let ((width (+ length-of-longest-name
                      separator-length))
            (columns 1)
            (shortest-first (sort (append lengths-v nil) '<)))
        (cl-dolist (item-len shortest-first)
          (cl-incf width item-len)
          (when (> width max-width)
            (cl-return))
          (cl-incf columns)
          (cl-incf width separator-length))
        (setq upper-bound (* columns max-visible-rows))))
    ;; Determine optimal row count.
    (cl-multiple-value-bind (optimal-n-rows truncated-p)
        (cond ((cl-endp items)
               (cl-values 0 nil))
              ((< upper-bound n-items)
               (cl-values max-visible-rows t))
              ((<= (cl-reduce (lambda (a b) (+ a separator-length b))
                              lengths-v)
                   max-width)
               ;; All fits in a single row.
               (cl-values 1 nil))
              (t
               (lusty--compute-optimal-row-count lengths-v)))
      (let ((n-columns 0)
            (column-widths '()))
        ;; Calculate n-columns and column-widths
        (cl-loop with total-width = 0
                 for start = 0 then end
                 for end = optimal-n-rows then
                 (min (length lengths-v)
                      (+ end optimal-n-rows))
                 while (< start end)
                 for col-width = (cl-reduce 'max lengths-v
                                            :start start
                                            :end end)
                 do
              (cl-incf total-width col-width)
              (when (> total-width max-width)
                (cl-return))
              (cl-incf n-columns)
              (push col-width column-widths)
              (cl-incf total-width separator-length))
        (setq column-widths (nreverse column-widths))
        (when (and (zerop n-columns)
                   (cl-plusp n-items))
          ;; Turns out there's not enough window space to do anything clever,
          ;; so just stack 'em up (and truncate).
          (setq n-columns 1)
          (setq column-widths
                (list
                 (cl-reduce #'max lengths-v
                            :start 0
                            :end (min n-items max-visible-rows)))))
        (let ((matrix
               ;; Create an empty matrix using the calculated dimensions.
               (let ((col-vec (make-vector n-columns nil)))
                 (dotimes (i n-columns)
                   (aset col-vec i
                         (make-vector optimal-n-rows nil)))
                 col-vec)))
          ;; Fill the matrix with propertized match strings.
          (unless (zerop n-columns)
            (let ((x 0)
                  (y 0)
                  (col-vec (aref matrix 0)))
              (cl-dolist (item items)
                (aset col-vec y (lusty--propertize-path item))
                (cl-incf y)
                (when (>= y optimal-n-rows)
                  (cl-incf x)
                  (if (>= x n-columns)
                      (cl-return)
                    (setq col-vec (aref matrix x)))
                  (setq y 0)))))
          (setq lusty--matches-matrix matrix
                lusty--matrix-column-widths column-widths
                lusty--matrix-truncated-p truncated-p)))))
  ;; No return value.
  (cl-values))

;; Returns number of rows and whether this row count will truncate the matches.
(cl-defun lusty--compute-optimal-row-count (lengths-v)
  ;;
  ;; Binary search; find the lowest number of rows at which we
  ;; can fit all the strings.
  ;;
  (let* ((separator-length (length lusty-column-separator))
         (n-items (length lengths-v))
         (max-visible-rows
          ;; -1 is for a potential TRUNCATION indicator line.
          (1- (lusty--max-window-body-height)))
         (available-width (lusty--exploitable-window-body-width))
         ;; Holds memoized widths of candidate columns (ranges of items).
         (lengths-h
          ;; Hashes by cons, e.g. (0 . 2), representing the width
          ;; of the column bounded by the range of [0..2].
          (make-hash-table :test 'equal
                           ;; Not scientific; will certainly grow larger for a
                           ;; nontrivial count of items (and so probably should
                           ;; be set higher here).
                           :size n-items))
         ;; We've already failed for a single row, so start at two.
         (lower 1)
         (upper (min (1+ max-visible-rows)
                     n-items)))
    (while (/= (1+ lower) upper)
      (let* ((n-rows (/ (+ lower upper) 2)) ; Mid-point
             (col-start-index 0)
             (col-end-index (1- n-rows))
             (total-width 0))
        (cl-block 'column-widths
          (while (< col-end-index n-items)
            (cl-incf total-width
                     (lusty--compute-column-width
                      col-start-index col-end-index
                      lengths-v lengths-h))
            (when (> total-width available-width)
              ;; Early exit; this row count is unworkable.
              (setq total-width most-positive-fixnum)
              (cl-return-from 'column-widths))
            (cl-incf total-width separator-length)
            (cl-incf col-start-index n-rows)
            (cl-incf col-end-index n-rows)
            (when (and (>= col-end-index n-items)
                       (< col-start-index n-items))
              ;; Remainder; last iteration will not be a full column.
              (setq col-end-index (1- n-items)))))
        ;; The final column doesn't need a separator.
        (cl-decf total-width separator-length)
        (if (<= total-width available-width)
            ;; This row count fits.
            (setq upper n-rows)
          ;; This row count doesn't fit.
          (setq lower n-rows))))
    (if (> upper max-visible-rows)
        ;; No row count can accomodate all entries; have to truncate.
        (cl-values max-visible-rows t)
      (cl-values upper nil))))

(cl-defun lusty--display-matches ()
  (when (lusty--matrix-empty-p)
    (lusty--print-no-matches (lusty--exploitable-window-body-width))
    (cl-return-from lusty--display-matches))
  (let* ((n-columns (length lusty--matches-matrix))
         (n-rows (length (aref lusty--matches-matrix 0))))
    ;; Highlight the selected match.
    (cl-destructuring-bind (h-x . h-y) lusty--highlighted-coords
      (setf (aref (aref lusty--matches-matrix h-x) h-y)
            (propertize (aref (aref lusty--matches-matrix h-x) h-y)
                        'face 'lusty-match-face)))
    ;; Print the match matrix.
    (dotimes (y n-rows)
      (cl-loop for column-width in lusty--matrix-column-widths
               for x from 0 upto n-columns
               do
            (let ((match (aref (aref lusty--matches-matrix x) y)))
              (when match
                (insert match)
                (when (< x (1- n-columns))
                  (let* ((spacer
                          (make-string (- column-width (length match))
                                       ?\ )))
                    (insert spacer lusty-column-separator))))))
      (insert "\n")))
  (when lusty--matrix-truncated-p
    (lusty--print-truncated (lusty--exploitable-window-body-width))))

(defun lusty--print-no-matches (row-width)
  "Insert a \"NO MATCHES\" line at point."
  (cl-assert (and (integerp row-width) (cl-plusp row-width)))
  (let ((start-pos (point)))
    (insert lusty-no-matches-string)
    (let* ((fill-column row-width))
      (center-line)
      ;; This should be in terms of columns, not buffer positions, but
      ;; every character involved has a width of 1 column so it's okay.
      (insert (make-string (- row-width (- (point) start-pos ))
                           ?\  )))
  (set-text-properties start-pos (point)
                       '(face lusty-no-matches))))

(defun lusty--print-truncated (row-width)
  "Insert a \"TRUNCATED\" line at point."
  (cl-assert (and (integerp row-width) (cl-plusp row-width)))
  (insert (propertize lusty-truncated-string 'face 'lusty-truncated))
  (let ((fill-column row-width))
    (center-line)))

(defun lusty-delete-backward (count)
  "Delete previous COUNT characters. If no count provided and if
cursor appears to be at the beginning of a directory, go up one
level."
  (interactive "P")
  (if count
      (call-interactively 'delete-backward-char)
    (if (eq (char-before) ?/)
        (progn
          (delete-char -1)
          (while (and (not (eq (char-before) ?/))
                      (not (get-text-property (1- (point)) 'read-only)))
            (delete-char -1)))
      (unless (get-text-property (1- (point)) 'read-only)
        (call-interactively 'delete-backward-char)))))

(defun lusty--define-mode-map ()
  ;; Re-generated every run so that it can inherit new functions.
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map (kbd "RET") #'lusty-open-this)
    (define-key map (kbd "TAB") #'lusty-select-match)
    (define-key map [remap next-line] #'lusty-highlight-next)  ; C-n
    (define-key map [remap previous-line] #'lusty-highlight-previous)  ; C-p
    (define-key map (kbd "C-s") #'lusty-highlight-next)
    (define-key map (kbd "C-r") #'lusty-highlight-previous)
    (define-key map (kbd "C-f") #'lusty-highlight-next-column)
    (define-key map (kbd "C-b") #'lusty-highlight-previous-column)
    (define-key map (kbd "<left>") #'lusty-highlight-previous-column)
    (define-key map (kbd "<right>") #'lusty-highlight-next-column)
    (define-key map (kbd "<up>") #'lusty-highlight-previous)
    (define-key map (kbd "<down>") #'lusty-highlight-next)
    (define-key map (kbd "C-x d") #'lusty-launch-dired)
    (define-key map (kbd "C-x e") #'lusty-select-current-name)
    ;; Special overrides.
    (define-key map [remap yank] #'lusty-yank)
    (define-key map [remap delete-backward-char] #'lusty-delete-backward)
    ;; Bindings for Evil.
    (define-key map [remap evil-next-line] #'lusty-highlight-next)  ; j
    (define-key map [remap evil-previous-line] #'lusty-highlight-previous)  ; k
    (define-key map [remap evil-scroll-page-down]  ; C-f
      #'lusty-highlight-next-column)
    (define-key map [remap evil-scroll-page-up]  ; C-b
      #'lusty-highlight-previous-column)
    (define-key map [remap evil-scroll-down]  ; C-d
      #'lusty-highlight-next-column)
    (define-key map [remap evil-scroll-up]  ; C-u (sometimes)
      #'lusty-highlight-previous-column)
    (setq lusty-mode-map map))
  (run-hooks 'lusty-setup-hook))

(defun lusty--run (read-fn &rest args)
  (let ((lusty--highlighted-coords (cons 0 0))
        (lusty--matches-matrix (make-vector 0 nil))
        (lusty--matrix-column-widths '())
        (lusty--matrix-truncated-p nil))
    ;; A post-command hook function may seem excessive, but it's the best way
    ;; I've found to update the matches list for every edit to the minibuffer.
    (add-hook 'post-command-hook #'lusty--post-command-function t)
    (unwind-protect
        (save-window-excursion
          (apply read-fn lusty-prompt args))
      (lusty--clean-up))))

(defun lusty--clean-up ()
  (remove-hook 'post-command-hook #'lusty--post-command-function)
  (setq lusty--previous-minibuffer-contents nil
        lusty--initial-window-config nil
        lusty--current-idle-timer nil)
  (when-let ((matches-buffer (get-buffer lusty-buffer-name)))
    (when (buffer-live-p matches-buffer)
      (kill-buffer matches-buffer))))



;;; LiquidMetal

;; Port of Ryan McGeary's LiquidMetal fuzzy matching algorithm found at:
;;   https://github.com/rmm5t/liquidmetal

(defmacro lusty--LM-score-no-match () 0.0)
(defmacro lusty--LM-score-match () 1.0)
(defmacro lusty--LM-score-trailing () 0.8)
(defmacro lusty--LM-score-trailing-but-started () 0.90)
(defmacro lusty--LM-score-buffer () 0.85)

(cl-defun lusty-LM-score (str abbrev)
  (let ((str-len (length str))
        (abbrev-len (length abbrev)))
    (cond ;((string= abbrev "")  ; Disabled; can't happen in practice
          ; (lusty--LM-score-trailing))
          ((> abbrev-len str-len)
           (lusty--LM-score-no-match))
          (t
           ;; Content of LM--build-score-array...
           ;; Inline for interpreted performance.
           (let* ((scores (make-vector str-len (lusty--LM-score-no-match)))
                  (str-test (if lusty-case-fold (downcase str) str))
                  (abbrev-test (if lusty-case-fold (downcase abbrev) abbrev))
                  (last-index 0)
                  (started-p nil))
             (dotimes (i abbrev-len)
               (let ((pos (cl-position (aref abbrev-test i) str-test
                                       :start last-index
                                       :end str-len)))
                 (when (null pos)
                   (cl-return-from lusty-LM-score (lusty--LM-score-no-match)))
                 (when (zerop pos)
                   (setq started-p t))
                 (cond ((and (cl-plusp pos)
                             (memq (aref str (1- pos))
                                   '(?. ?_ ?- ?\ )))
                        ;; New word.
                        (aset scores (1- pos) (lusty--LM-score-match))
                        (cl-fill scores (lusty--LM-score-buffer)
                                 :start last-index
                                 :end (1- pos)))
                       ((and (>= (aref str pos) ?A)
                             (<= (aref str pos) ?Z))
                        ;; Upper case.
                        (cl-fill scores (lusty--LM-score-buffer)
                                 :start last-index
                                 :end pos))
                       (t
                        (cl-fill scores (lusty--LM-score-no-match)
                                 :start last-index
                                 :end pos)))
                 (aset scores pos (lusty--LM-score-match))
                 (setq last-index (1+ pos))))
             (let ((trailing-score
                    (if started-p
                        (lusty--LM-score-trailing-but-started)
                      (lusty--LM-score-trailing))))
               (cl-fill scores trailing-score :start last-index))
             (/ (cl-loop for score across scores sum score)
                str-len ))))))
(defalias 'LM-score 'lusty-LM-score)  ;; deprecated

(provide 'lusty-explorer)

;;; lusty-explorer.el ends here.
