;;; spell-fu.el --- Fast & light spelling highlighter -*- lexical-binding: t -*-

;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-spell-fu
;; Package-Version: 20211008.106
;; Package-Commit: f38bebefea9d23c2bd4293ecf7100211c1410cd4
;; Keywords: convenience
;; Version: 0.3
;; Package-Requires: ((emacs "26.2"))

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

;; This package checks the spelling of on-screen text.
;;

;;; Usage

;;
;; Write the following code to your .emacs file:
;;
;;   (require 'spell-fu)
;;   (global-spell-fu-mode-mode)
;;
;; Or with `use-package':
;;
;;   (use-package spell-fu)
;;   (global-spell-fu-mode-mode)
;;
;; If you prefer to enable this per-mode, you may do so using
;; mode hooks instead of calling `global-spell-fu-mode-mode'.
;; The following example enables this for org-mode:
;;
;;   (add-hook 'org-mode-hook
;;     (lambda ()
;;       (setq spell-fu-faces-exclude '(org-meta-line))
;;       (spell-fu-mode)))
;;

;;; Code:


;; ---------------------------------------------------------------------------
;; Require Dependencies

;; For `face-list-p'.
(require 'faces)
;; For variables we read `ispell-personal-dictionary' local dictionary, etc.
(require 'ispell)


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup spell-fu nil
  "Fast, configurable spell checking of visible text, updated on a timer."
  :group 'ispell)

(defcustom spell-fu-directory (locate-user-emacs-file "spell-fu" ".emacs-spell-fu")
  "The directory to store undo data."
  :type 'string)

(defcustom spell-fu-idle-delay 0.25
  "Idle time to wait before highlighting.
Set to 0.0 to highlight immediately (as part of syntax highlighting)."
  :type 'float)

(defcustom spell-fu-ignore-modes nil
  "List of major-modes to exclude when `spell-fu' has been enabled globally."
  :type '(repeat symbol))

(defvar-local global-spell-fu-ignore-buffer nil
  "When non-nil, the global mode will not be enabled for this buffer.
This variable can also be a predicate function, in which case
it'll be called with one parameter (the buffer in question), and
it should return non-nil to make Global `spell-fu' Mode not
check this buffer.")

(defface spell-fu-incorrect-face
  '
  ((((supports :underline (:style wave))) :underline (:style wave :color "red"))
    (t :underline t :inherit error))
  "Face for incorrect spelling.")

;; See '-' as a word boundary \b, so 'full-screen' is detected as two words.
(defvar-local spell-fu-syntax-table
  (let ((table (copy-syntax-table (standard-syntax-table))))
    (modify-syntax-entry ?- "-" table)
    table)
  "The syntax table to use when scanning words.")

;; This regex handles:
;;
;; - ``Quotation'' <= don't match multiple trailing apostrophes.
;;     ^^^^^^^^^
;;
;; - we're <= Connect letters with a single apostrophe.
;;   ^^^^^
;;
;; - don't''join <= don't connect multiple apostrophes.
;;   ^^^^^  ^^^^
;;
(defvar-local spell-fu-word-regexp "\\b\\([[:alpha:]][[:alpha:]]*\\('[[:alpha:]]*\\)?\\)\\b"
  "Regex used to scan for words to check (used by `spell-fu-check-range').")

(defvar-local spell-fu-faces-include nil
  "List of faces to check or nil to include all (used by `spell-fu-check-range').")

(defvar-local spell-fu-faces-exclude nil
  "List of faces to check or nil to exclude none (used by `spell-fu-check-range').")

(defvar-local spell-fu-check-range 'spell-fu-check-range-default
  "Function that takes a beginning & end points to check for the current buffer.

Users may want to write their own functions to have more control
over which words are being checked.

Notes:

- The ranges passed in a guaranteed to be on line boundaries.
- Calling `spell-fu-check-word' on each word.

- You may explicitly mark a range as incorrect using
  `spell-fu-mark-incorrect' which takes the range to mark as arguments.")


;; ---------------------------------------------------------------------------
;; Internal Variables

;; Use to ensure the cache is not from a previous release.
;; Only ever increase.
(defconst spell-fu--cache-version "0.1")

;; List of language, dictionary mappings.
(defvar spell-fu--cache-table-alist nil)

;; Buffer local dictionary.
;; Note that this is typically the same dictionary shared across all buffers.
(defvar-local spell-fu--cache-table nil)


;; ---------------------------------------------------------------------------
;; Dictionary Utility Functions

(defun spell-fu--dictionary ()
  "Access the current dictionary."
  (or ispell-local-dictionary ispell-dictionary "default"))

(defun spell-fu--cache-file (dict)
  "Return the location of the cache file with dictionary DICT."
  (expand-file-name (format "words_%s.el.data" dict) spell-fu-directory))

(defun spell-fu--words-file (dict)
  "Return the location of the word-list with dictionary DICT."
  (expand-file-name (format "words_%s.txt" dict) spell-fu-directory))

(defun spell-fu--aspell-find-data-file (dict)
  "For Aspell dictionary DICT, return an associated data file path or nil."
  ;; Based on `ispell-aspell-find-dictionary'.

  ;; Make sure `ispell-aspell-dict-dir' is defined.
  (unless ispell-aspell-dict-dir
    (setq ispell-aspell-dict-dir (ispell-get-aspell-config-value "dict-dir")))

  ;; Make sure `ispell-aspell-data-dir' is defined.
  (unless ispell-aspell-data-dir
    (setq ispell-aspell-data-dir (ispell-get-aspell-config-value "data-dir")))

  ;; Try finding associated data-file. aspell will look for master .dat
  ;; file in `dict-dir' and `data-dir'. Associated .dat files must be
  ;; in the same directory as master file.
  (catch 'datafile
    (save-match-data
      (dolist (tmp-path (list ispell-aspell-dict-dir ispell-aspell-data-dir))
        ;; Try `xx.dat' first, strip out variant, country code, etc,
        ;; then try `xx_YY.dat' (without stripping country code),
        ;; then try `xx-alt.dat', for `de-alt' etc.
        (dolist (dict-re (list "^[[:alpha:]]+" "^[[:alpha:]_]+" "^[[:alpha:]]+-\\(alt\\|old\\)"))
          (let ((dict-match (and (string-match dict-re dict) (match-string 0 dict))))
            (when dict-match
              (let ((fullpath (concat (file-name-as-directory tmp-path) dict-match ".dat")))
                (when (file-readable-p fullpath)
                  (throw 'datafile fullpath))))))))))

(defun spell-fu--aspell-lang-from-dict (dict)
  "Return the language of a DICT or nil if identification fails.

Supports aspell alias dictionaries, e.g. 'german' or 'deutsch',
for 'de_DE' using Ispell's lookup routines.
The language is identified by looking for the data file
associated with the dictionary."
  (unless ispell-aspell-dictionary-alist
    (ispell-find-aspell-dictionaries))
  (let ((dict-name (cadr (nth 5 (assoc dict ispell-aspell-dictionary-alist)))))
    (when dict-name
      (let ((data-file (spell-fu--aspell-find-data-file dict-name)))
        (when data-file
          (file-name-base data-file))))))


;; ---------------------------------------------------------------------------
;; Generic Utility Functions
;;
;; Helpers, not directly related to checking spelling.
;;

(defmacro spell-fu--with-advice (fn-orig where fn-advice &rest body)
  "Execute BODY with WHERE advice on FN-ORIG temporarily enabled."
  `
  (let ((fn-advice-var ,fn-advice))
    (unwind-protect
      (progn
        (advice-add ,fn-orig ,where fn-advice-var)
        ,@body)
      (advice-remove ,fn-orig fn-advice-var))))

(defmacro spell-fu--with-message-prefix (prefix &rest body)
  "Add text before the message output.
Argument PREFIX is the text to add at the start of the message.
Optional argument BODY runs with the message prefix."
  (declare (indent 1))
  `
  (spell-fu--with-advice 'message
    :around
    (lambda (fn-orig arg &rest args)
      (apply fn-orig (append (list (concat "%s" arg)) (list ,prefix) args)))
    ,@body))

(defmacro spell-fu--with-add-hook-depth-override (depth-override &rest body)
  "Support overriding the depth of a hook added by an indirect call.
Argument DEPTH-OVERRIDE the depth value to call `add-hook' with.
Optional argument BODY runs with the depth override."
  (declare (indent 1))
  `
  (spell-fu--with-advice 'add-hook
    :around
    (lambda (fn-orig hook function &optional _depth local)
      (funcall fn-orig hook function ,depth-override local))
    ,@body))

(defmacro spell-fu--setq-expand-range-to-line-boundaries (point-start point-end)
  "Set POINT-START the the line beginning, POINT-END to the line end."
  (declare (indent 1))
  ;; Ignore field boundaries.
  (let ((inhibit-field-text-motion t))
    `
    (save-excursion
      ;; Extend the ranges to line start/end.
      (goto-char ,point-end)
      (setq ,point-end (line-end-position))
      (goto-char ,point-start)
      (setq ,point-start (line-beginning-position)))))

(defun spell-fu--buffer-as-line-list (buffer lines)
  "Add lines from BUFFER to LINES, returning the updated LINES."
  (with-current-buffer buffer
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (push (buffer-substring-no-properties (line-beginning-position) (line-end-position)) lines)
        (forward-line 1))))
  lines)

(defun spell-fu--removed-changed-overlay (overlay after _beg _end &optional _len)
  "Hook for removing OVERLAY which is being edited.
Argument AFTER, ignore when true."
  (unless after
    (delete-overlay overlay)))

(defun spell-fu--faces-at-point (pos)
  "Add the named faces that the `read-face-name' or `face' property use.
Argument POS return faces at this point."
  (let
    ( ;; List of faces to return.
      (faces nil)
      (faceprop (or (get-char-property pos 'read-face-name) (get-char-property pos 'face))))
    (cond
      ((facep faceprop)
        (push faceprop faces))
      ((face-list-p faceprop)
        (dolist (face faceprop)
          (when (facep face)
            (push face faces)))))
    faces))

(defun spell-fu--next-faces-prop-change (pos limit)
  "Return the next face change from POS restricted by LIMIT."
  (next-single-property-change
    pos
    'read-face-name
    nil
    (next-single-property-change pos 'face nil limit)))

(defun spell-fu--file-is-older-list (file-test file-list)
  "Return t when FILE-TEST is older than any files in FILE-LIST."
  (catch 'result
    (let ((file-test-time (file-attribute-modification-time (file-attributes file-test))))
      (dolist (file-new file-list)
        (when
          (time-less-p
            file-test-time
            (file-attribute-modification-time (file-attributes file-new)))
          (throw 'result t)))
      nil)))

(defun spell-fu--file-is-older (file-test &rest file-list)
  "Return t when FILE-TEST is older than any files in FILE-LIST."
  (spell-fu--file-is-older-list file-test file-list))


;; ---------------------------------------------------------------------------
;; Word List Generation

(defun spell-fu--word-list-ensure (words-file dict)
  "Ensure the word list is generated with dictionary DICT.
Argument WORDS-FILE the file to write the word list into."
  (let*
    (
      (personal-words-file ispell-personal-dictionary)
      (has-words-file (file-exists-p words-file))
      (has-dict-personal (and personal-words-file (file-exists-p personal-words-file)))
      (is-dict-outdated
        (and
          has-words-file
          has-dict-personal
          (spell-fu--file-is-older words-file personal-words-file))))

    (when (or (not has-words-file) is-dict-outdated)

      (spell-fu--with-message-prefix "Spell-fu generating words: "
        (message "%S" (file-name-nondirectory words-file))

        ;; Build a word list, sorted case insensitive.
        (let ((word-list nil))

          ;; Optional: insert personal dictionary, stripping header and inserting a newline.
          (with-temp-buffer
            (when has-dict-personal
              (insert-file-contents personal-words-file)
              (goto-char (point-min))
              (when (looking-at "personal_ws-")
                (delete-region (line-beginning-position) (1+ (line-end-position))))
              (goto-char (point-max))
              (unless (eq ?\n (char-after))
                (insert "\n")))

            (setq word-list (spell-fu--buffer-as-line-list (current-buffer) word-list)))

          ;; Insert dictionary from aspell.
          (with-temp-buffer
            (let
              ( ;; Use the pre-configured aspell binary, or call aspell directly.
                (aspell-bin
                  (or (and ispell-really-aspell ispell-program-name) (executable-find "aspell"))))

              (cond
                ((string-equal dict "default")
                  (call-process aspell-bin nil t nil "dump" "master"))
                (t
                  (call-process aspell-bin nil t nil "-d" dict "dump" "master")))

              ;; Check whether the dictionary has affixes, expand if necessary.
              (when (re-search-backward "^[[:alpha:]]*/[[:alnum:]]*$" nil t)
                (let ((lang (spell-fu--aspell-lang-from-dict dict)))
                  (unless
                    (zerop
                      (shell-command-on-region
                        (point-min) (point-max)
                        (cond
                          (lang
                            (format "%s -l %s expand" aspell-bin lang))
                          (t
                            (format "%s expand" aspell-bin)))
                        t t
                        ;; Output any errors into the message buffer instead of the word-list.
                        "*spell-fu word generation errors*"))
                    (message
                      (format
                        "spell-fu: affix extension for dictionary '%s' failed (with language: %S)."
                        dict
                        lang)))
                  (goto-char (point-min))
                  (while (search-forward " " nil t)
                    (replace-match "\n")))))

            (setq word-list (spell-fu--buffer-as-line-list (current-buffer) word-list)))

          ;; Case insensitive sort is important if this is used for `ispell-complete-word-dict'.
          ;; Which is a handy double-use for this file.
          (let ((word-list-ncase nil))
            (dolist (word word-list)
              (push (cons (downcase word) word) word-list-ncase))

            ;; Sort by the lowercase word.
            (setq word-list-ncase
              (sort word-list-ncase (lambda (a b) (string-lessp (car a) (car b)))))

            ;; Write to 'words-file'.
            (with-temp-buffer
              (dolist (line-cons word-list-ncase)
                (insert (cdr line-cons) "\n"))
              (write-region nil nil words-file nil 0))))))))


;; ---------------------------------------------------------------------------
;; Word List Cache

(defun spell-fu--cache-from-word-list-impl (words-file cache-file)
  "Create CACHE-FILE from WORDS-FILE.

The resulting cache is returned as a minor optimization for first-time loading,
where we need to create this data in order to write it,
save some time by not spending time reading it back."
  (message "%S" (file-name-nondirectory cache-file))
  (let
    ( ;; The header, an associative list of items.
      (cache-header (list (cons "version" spell-fu--cache-version)))
      (word-table nil))

    (with-temp-buffer
      (insert-file-contents-literally words-file)
      (setq word-table (make-hash-table :test #'equal :size (count-lines (point-min) (point-max))))
      (while (not (eobp))
        (let ((l (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
          ;; Value of 't' is just for simplicity, it's no used except for check the item exists.
          (puthash (encode-coding-string (downcase l) 'utf-8) t word-table)
          (forward-line 1))))

    ;; Write write it to a file.
    (with-temp-buffer
      (prin1 cache-header (current-buffer))
      (prin1 word-table (current-buffer))
      (write-region nil nil cache-file nil 0))

    ;; Return the resulting word table.
    word-table))

(defun spell-fu--cache-from-word-list (words-file cache-file)
  "Create CACHE-FILE from WORDS-FILE."
  (spell-fu--with-message-prefix "Spell-fu generating cache: "
    (condition-case err
      (spell-fu--cache-from-word-list-impl words-file cache-file)
      (error
        ;; Should be rare: if the file is corrupt or cannot be read for any reason.
        (progn
          (message "failed, %s" (error-message-string err))
          nil)))))

(defun spell-fu--cache-words-load-impl (cache-file)
  "Return the Lisp content from reading CACHE-FILE.

On failure of any kind, return nil,
the caller will need to regenerate the cache."
  (with-temp-buffer
    (insert-file-contents-literally cache-file)
    (goto-char (point-min))

    ;; Check header.
    (let ((cache-header (read (current-buffer))))
      (unless (listp cache-header)
        (error "Expected cache-header to be list, not %S" (type-of cache-header)))

      (let ((version (assoc-default "version" cache-header)))
        (unless (string-equal version spell-fu--cache-version)
          (error "Require cache version %S, not %S" spell-fu--cache-version version))))

    ;; Read the contents.
    (let ((word-table (read (current-buffer))))
      (unless (hash-table-p word-table)
        (error "Expected cache to contain a hash-table, not %S" (type-of word-table)))
      word-table)))

(defun spell-fu--cache-words-load (cache-file)
  "Return the Lisp content from reading CACHE-FILE."
  (spell-fu--with-message-prefix "Spell-fu reading cache: "
    (condition-case err
      (spell-fu--cache-words-load-impl cache-file)
      (error
        ;; Should be rare: if the file is corrupt or cannot be read for any reason.
        (progn
          (message "failed, %s" (error-message-string err))
          nil)))))


;; ---------------------------------------------------------------------------
;; Word List Initialization
;;
;; Top level function, called when enabling the mode.

(defun spell-fu--ensure-dict (dict)
  "Setup the dictionary, initializing new files as necessary with dictionary DICT."

  ;; First use the dictionary if it's in memory.
  ;; Once Emacs is running, this is used for all new buffers.
  (setq spell-fu--cache-table (assoc-default dict spell-fu--cache-table-alist))

  ;; Not loaded yet, initialize it.
  (unless spell-fu--cache-table

    ;; Ensure our path exists.
    (unless (file-directory-p spell-fu-directory)
      (make-directory spell-fu-directory))

    (let
      ( ;; Get the paths of both files, ensure the cache file is newer,
        ;; otherwise regenerate it.
        (words-file (spell-fu--words-file dict))
        (cache-file (spell-fu--cache-file dict)))

      (spell-fu--word-list-ensure words-file dict)

      ;; Load cache or create it, creating it returns the cache
      ;; to avoid some slow-down on first load.
      (setq spell-fu--cache-table
        (or
          (and
            (file-exists-p cache-file)
            (not (spell-fu--file-is-older cache-file words-file))
            (spell-fu--cache-words-load cache-file))
          (spell-fu--cache-from-word-list words-file cache-file)))

      ;; Add to to `spell-fu--cache-table-alist' for reuse on next load.
      (push (cons dict spell-fu--cache-table) spell-fu--cache-table-alist))))


;; ---------------------------------------------------------------------------
;; Shared Functions

(defun spell-fu--remove-overlays (&optional point-start point-end)
  "Remove symbol `spell-fu-mode' overlays from current buffer.
If optional arguments POINT-START and POINT-END exist
remove overlays from range POINT-START to POINT-END.
Otherwise remove all overlays."
  (remove-overlays point-start point-end 'spell-fu-mode t))

(defun spell-fu-mark-incorrect (point-start point-end)
  "Mark the text from POINT-START to POINT-END with incorrect spelling overlay."
  (let ((item-ov (make-overlay point-start point-end)))
    (overlay-put item-ov 'spell-fu-mode t)
    (overlay-put item-ov 'face 'spell-fu-incorrect-face)
    (overlay-put item-ov 'modification-hooks 'spell-fu--removed-changed-overlay)
    (overlay-put item-ov 'insert-in-front-hooks 'spell-fu--removed-changed-overlay)
    (overlay-put item-ov 'insert-behind-hooks 'spell-fu--removed-changed-overlay)
    (overlay-put item-ov 'evaporate t)
    item-ov))

(defun spell-fu-check-word (point-start point-end word)
  "Run the spell checker on a word.

Marking the spelling as incorrect using `spell-fu-incorrect-face' on failure.
Argument POINT-START the beginning position of WORD.
Argument POINT-END the end position of WORD."
  (unless (gethash (encode-coding-string (downcase word) 'utf-8) spell-fu--cache-table nil)
    ;; Ignore all uppercase words.
    (unless (equal word (upcase word))
      (spell-fu-mark-incorrect point-start point-end))))


;; ---------------------------------------------------------------------------
;; Range Checking Commands
;;
;; These functions are value values for the `spell-fu-check-range' buffer local variable.
;;
;; Note that the callers of these function extends the range to line delimiters,
;; to ensure there no chance of the points being in the middle of a word.
;;

(defun spell-fu--check-faces-at-point (pos)
  "Check if position POS has faces that match include/exclude."
  (let
    (
      (result (null spell-fu-faces-include))
      (faces-at-pos (spell-fu--faces-at-point pos)))
    (while faces-at-pos
      (let ((face (pop faces-at-pos)))
        (when (memq face spell-fu-faces-exclude)
          (setq faces-at-pos nil)
          (setq result nil))
        (when (and (null result) (memq face spell-fu-faces-include))
          (setq result t))))
    result))

(defun spell-fu--check-range-with-faces (point-start point-end)
  "Check spelling for POINT-START & POINT-END.

This only checks the text matching face rules."
  (spell-fu--remove-overlays point-start point-end)
  (with-syntax-table spell-fu-syntax-table
    (save-match-data ;; For regex search.
      (save-excursion ;; For moving the point.
        (save-restriction ;; For narrowing.
          ;; Avoid duplicate calls that check if `point-start' passes the face test.
          (let ((ok-start (spell-fu--check-faces-at-point point-start)))
            ;; It's possible the face changes part way through the word.
            ;; In practice this is likely caused by escape characters, e.g.
            ;; "test\nthe text" where "\n" may have separate highlighting.
            (while (< point-start point-end)
              (let*
                ( ;; Assign to `ok-start' next iteration to avoid duplicate checks.
                  (point-end-iter (spell-fu--next-faces-prop-change point-start point-end))
                  (ok-end-iter
                    (and
                      (< point-end-iter point-end)
                      (spell-fu--check-faces-at-point point-end-iter))))

                ;; No need to check faces of each word
                ;; as face-changes are being stepped over.
                (when ok-start

                  ;; Extend `point-end-iter' out for as long as the face isn't being ignored,
                  ;; needed when `whitespace-mode' sets a margin,
                  ;; splitting words in this case isn't desirable, see: #16.
                  ;;
                  ;; This may also have some advantage
                  ;; in reducing the number of narrowing calls.
                  ;;
                  ;; NOTE: this could be made into an option.
                  ;; Currently there doesn't seem much need for this at the moment.
                  (while ok-end-iter
                    (setq point-end-iter
                      (spell-fu--next-faces-prop-change point-end-iter point-end))
                    (setq ok-end-iter
                      (and
                        (< point-end-iter point-end)
                        (spell-fu--check-faces-at-point point-end-iter))))

                  ;; Use narrowing so the regex correctly handles boundaries
                  ;; that happen to fall on face changes.
                  (narrow-to-region point-start point-end-iter)
                  (goto-char point-start)
                  (while (re-search-forward spell-fu-word-regexp point-end-iter t)
                    (let
                      (
                        (word-start (match-beginning 0))
                        (word-end (match-end 0)))
                      (spell-fu-check-word
                        word-start
                        word-end
                        (buffer-substring-no-properties word-start word-end))))
                  (widen))

                (setq point-start point-end-iter)
                (setq ok-start ok-end-iter)))))))))

(defun spell-fu--check-range-without-faces (point-start point-end)
  "Check spelling for POINT-START & POINT-END, checking all text."
  (spell-fu--remove-overlays point-start point-end)
  (with-syntax-table spell-fu-syntax-table
    (save-match-data
      (save-excursion
        (goto-char point-start)
        (while (re-search-forward spell-fu-word-regexp point-end t)
          (let
            (
              (word-start (match-beginning 0))
              (word-end (match-end 0)))
            (spell-fu-check-word word-start word-end (match-string-no-properties 0))))))))

(defun spell-fu-check-range-default (point-start point-end)
  "Check spelling POINT-START & POINT-END, checking comments and strings."
  (cond
    ((or spell-fu-faces-include spell-fu-faces-exclude)
      (spell-fu--check-range-with-faces point-start point-end))
    (t
      (spell-fu--check-range-without-faces point-start point-end))))


;; ---------------------------------------------------------------------------
;; Immediate Style (spell-fu-idle-delay zero or lower)

(defun spell-fu--font-lock-fontify-region (point-start point-end)
  "Update spelling for POINT-START & POINT-END to the queue, checking all text."
  (spell-fu--setq-expand-range-to-line-boundaries
    ;; Warning these values are set in place.
    point-start point-end)
  (funcall spell-fu-check-range point-start point-end))

(defun spell-fu--immediate-enable ()
  "Enable immediate spell checking."

  ;; It's important this is added with a depth of 100,
  ;; because we want the font faces (comments, string etc) to be set so
  ;; the spell checker can read these values which may include/exclude words.
  (spell-fu--with-add-hook-depth-override 100
    (jit-lock-register #'spell-fu--font-lock-fontify-region)))

(defun spell-fu--immediate-disable ()
  "Disable immediate spell checking."
  (jit-lock-unregister #'spell-fu--font-lock-fontify-region)
  (spell-fu--remove-overlays))


;; ---------------------------------------------------------------------------
;; Timer Style (spell-fu-idle-delay over zero)

(defun spell-fu--idle-remove-overlays (&optional point-start point-end)
  "Remove `spell-fu-pending' overlays from current buffer.
If optional arguments POINT-START and POINT-END exist
remove overlays from range POINT-START to POINT-END.
Otherwise remove all overlays."
  (remove-overlays point-start point-end 'spell-fu-pending t))

(defun spell-fu--idle-handle-pending-ranges-impl (visible-start visible-end)
  "VISIBLE-START and VISIBLE-END typically from `window-start' and `window-end'.

Although you can pass in specific ranges as needed,
when checking the entire buffer for example."
  (let ((overlays-in-view (overlays-in visible-start visible-end)))
    (while overlays-in-view
      (let ((item-ov (pop overlays-in-view)))
        (when
          (and
            (overlay-get item-ov 'spell-fu-pending)
            ;; It's possible these become invalid while looping over items.
            (overlay-buffer item-ov))

          (let
            ( ;; Window clamped range.
              (point-start (max visible-start (overlay-start item-ov)))
              (point-end (min visible-end (overlay-end item-ov))))

            ;; Expand so we don't spell check half a word.
            (spell-fu--setq-expand-range-to-line-boundaries
              ;; Warning these values are set in place.
              point-start point-end)

            (when
              (condition-case err
                ;; Needed so the idle timer won't quit mid-spelling.
                (let ((inhibit-quit nil))
                  (funcall spell-fu-check-range point-start point-end)
                  t)
                (error
                  (progn
                    ;; Keep since this should be very rare.
                    (message "Early exit 'spell-fu-mode': %s" (error-message-string err))
                    ;; Break out of the loop.
                    (setq overlays-in-view nil)
                    nil)))

              ;; Don't delete the overlay since it may extend outside the window bounds,
              ;; always delete the range instead.
              ;;
              ;; While we could remove everything in the window range,
              ;; avoid this because it's possible `spell-fu-check-range' is interrupted.
              ;; Allowing interrupting is important, so users may set this to a slower function
              ;; which doesn't lock up Emacs as this is run from an idle timer.
              (spell-fu--idle-remove-overlays point-start point-end))))))))

(defun spell-fu--idle-handle-pending-ranges ()
  "Spell check the on-screen overlay ranges."
  (spell-fu--idle-handle-pending-ranges-impl (window-start) (window-end)))

(defun spell-fu--idle-font-lock-region-pending (point-start point-end)
  "Track the range to spell check, adding POINT-START & POINT-END to the queue."
  (let ((item-ov (make-overlay point-start point-end)))
    ;; Handy for debugging pending regions to be checked.
    ;; (overlay-put item-ov 'face '(:background "#000000" :extend t))
    (overlay-put item-ov 'spell-fu-pending t)
    (overlay-put item-ov 'evaporate 't)))

;; ---------------------------------------------------------------------------
;; Internal Timer Management
;;
;; This works as follows:
;;
;; - The timer is kept active as long as the local mode is enabled.
;; - Entering a buffer runs the buffer local `window-state-change-hook'
;;   immediately which checks if the mode is enabled,
;;   set up the global timer if it is.
;; - Switching any other buffer wont run this hook,
;;   rely on the idle timer it's self running, which detects the active mode,
;;   canceling it's self if the mode isn't active.
;;
;; This is a reliable way of using a global,
;; repeating idle timer that is effectively buffer local.
;;

;; Global idle timer (repeating), keep active while the buffer-local mode is enabled.
(defvar spell-fu--global-timer nil)
;; When t, the timer will update buffers in all other visible windows.
(defvar spell-fu--dirty-flush-all nil)
;; When true, the buffer should be updated when inactive.
(defvar-local spell-fu--dirty nil)

(defun spell-fu--time-callback-or-disable ()
  "Callback that run the repeat timer."

  ;; Ensure all other buffers are highlighted on request.
  (let ((is-mode-active (bound-and-true-p spell-fu-mode)))
    ;; When this buffer is not in the mode, flush all other buffers.
    (cond
      (is-mode-active
        ;; Don't update in the window loop to ensure we always
        ;; update the current buffer in the current context.
        (setq spell-fu--dirty nil))
      (t
        ;; If the timer ran when in another buffer,
        ;; a previous buffer may need a final refresh, ensure this happens.
        (setq spell-fu--dirty-flush-all t)))

    (when spell-fu--dirty-flush-all
      ;; Run the mode callback for all other buffers in the queue.
      (dolist (frame (frame-list))
        (dolist (win (window-list frame -1))
          (let ((buf (window-buffer win)))
            (when
              (and
                (buffer-local-value 'spell-fu-mode buf)
                (buffer-local-value 'spell-fu--dirty buf))
              (with-selected-frame frame
                (with-selected-window win
                  (with-current-buffer buf
                    (setq spell-fu--dirty nil)
                    (spell-fu--idle-handle-pending-ranges)))))))))
    ;; Always keep the current buffer dirty
    ;; so navigating away from this buffer will refresh it.
    (when is-mode-active
      (setq spell-fu--dirty t))

    (cond
      (is-mode-active
        (spell-fu--idle-handle-pending-ranges))
      (t ;; Cancel the timer until the current buffer uses this mode again.
        (spell-fu--time-ensure nil)))))

(defun spell-fu--time-ensure (state)
  "Ensure the timer is enabled when STATE is non-nil, otherwise disable."
  (cond
    (state
      (unless spell-fu--global-timer
        (setq spell-fu--global-timer
          (run-with-idle-timer spell-fu-idle-delay :repeat 'spell-fu--time-callback-or-disable))))
    (t
      (when spell-fu--global-timer
        (cancel-timer spell-fu--global-timer)
        (setq spell-fu--global-timer nil)))))

(defun spell-fu--time-reset ()
  "Run this when the buffer was changed."
  ;; Ensure changing windows doesn't leave other buffers with stale highlight.
  (cond
    ((bound-and-true-p spell-fu-mode)
      (setq spell-fu--dirty-flush-all t)
      (setq spell-fu--dirty t)
      (spell-fu--time-ensure t))
    (t
      (spell-fu--time-ensure nil))))

(defun spell-fu--time-buffer-local-enable ()
  "Ensure buffer local state is enabled."
  ;; Needed in case focus changes before the idle timer runs.
  (setq spell-fu--dirty-flush-all t)
  (setq spell-fu--dirty t)
  (spell-fu--time-ensure t)
  (add-hook 'window-state-change-hook #'spell-fu--time-reset nil t))

(defun spell-fu--time-buffer-local-disable ()
  "Ensure buffer local state is disabled."
  (kill-local-variable 'spell-fu--dirty)
  (spell-fu--time-ensure nil)
  (remove-hook 'window-state-change-hook #'spell-fu--time-reset t))

(defun spell-fu--idle-enable ()
  "Enable the idle style of updating."
  ;; Unlike with immediate style, idle / deferred checking isn't as likely to
  ;; run before fonts have been checked.
  ;; Nevertheless, this avoids the possibility of spell checking
  ;; running before font-faces have been set.
  (spell-fu--with-add-hook-depth-override 100
    (jit-lock-register #'spell-fu--idle-font-lock-region-pending))
  (spell-fu--time-buffer-local-enable))

(defun spell-fu--idle-disable ()
  "Disable the idle style of updating."
  (jit-lock-unregister #'spell-fu--idle-font-lock-region-pending)
  (spell-fu--remove-overlays)
  (spell-fu--idle-remove-overlays)
  (spell-fu--time-buffer-local-disable))

;; ---------------------------------------------------------------------------
;; Public Functions

(defun spell-fu-region (&optional point-start point-end verbose)
  "Spell check the region between POINT-START and POINT-END.

The VERBOSE argument reports the findings."
  ;; Expand range to line bounds, when set.
  (when (or point-start point-end)
    (unless point-start
      (setq point-start (point-min)))
    (unless point-end
      (setq point-end (point-max)))
    (spell-fu--setq-expand-range-to-line-boundaries
      ;; Warning these values are set in place.
      point-start point-end))

  (setq point-start (or point-start (point-min)))
  (setq point-end (or point-end (point-max)))

  (jit-lock-fontify-now point-start point-end)

  ;; Ensure idle timer is handled immediately.
  (cond
    ((<= spell-fu-idle-delay 0.0)
      nil)
    (t
      (spell-fu--idle-handle-pending-ranges-impl point-start point-end)))

  (when verbose
    (let ((count 0))
      (dolist (item-ov (overlays-in point-start point-end))
        (when (overlay-get item-ov 'spell-fu-mode)
          (setq count (1+ count))))
      (message "Spell-fu: %d misspelled word(s) found!" count))))


(defun spell-fu-buffer ()
  "Spell check the whole buffer."
  (interactive)
  (spell-fu-region nil nil t))

(defun spell-fu--goto-next-or-previous-error (dir)
  "Jump to the next or previous error using DIR.

Return t when found, otherwise nil."
  (let
    ( ;; Track the closest point in a given line.
      (point-found-delta most-positive-fixnum)
      (point-init (point))
      (point-prev nil)
      (point-found nil))
    (save-excursion
      (while (and (null point-found) (not (equal (point) point-prev)))
        (let
          (
            (point-start (line-beginning-position))
            (point-end (line-end-position)))

          (jit-lock-fontify-now point-start point-end)

          ;; Ensure idle timer is handled immediately.
          (cond
            ((<= spell-fu-idle-delay 0.0)
              nil)
            (t
              (spell-fu--idle-handle-pending-ranges-impl point-start point-end)))

          (dolist (item-ov (overlays-in point-start point-end))
            (when (overlay-get item-ov 'spell-fu-mode)
              (let
                (
                  (item-start (overlay-start item-ov))
                  (item-end (overlay-end item-ov)))
                (when
                  (cond
                    ((< dir 0)
                      (< item-end point-init))
                    (t
                      (> item-start point-init)))
                  (let ((test-delta (abs (- point-init item-start))))
                    (when (< test-delta point-found-delta)
                      (setq point-found item-start)
                      (setq point-found-delta test-delta))))))))
        (setq point-prev (point))
        (forward-line dir)))

    (cond
      (point-found
        (goto-char point-found)
        t)
      (t
        (message
          "Spell-fu: no %s spelling error found"
          (cond
            ((< dir 0)
              "previous")
            (t
              "next")))
        nil))))

(defun spell-fu-goto-next-error ()
  "Jump to the next error, return t when found, otherwise nil."
  (interactive)
  (spell-fu--goto-next-or-previous-error 1))

(defun spell-fu-goto-previous-error ()
  "Jump to the previous error, return t when found, otherwise nil."
  (interactive)
  (spell-fu--goto-next-or-previous-error -1))


;; ---------------------------------------------------------------------------
;; Personal Dictionary Management
;;

(defun spell-fu--buffers-refresh-with-cache-table (cache-table)
  "Reset spell-checked overlays for buffers using the dictionary from CACHE-TABLE."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (bound-and-true-p spell-fu-mode)
        (when (eq cache-table (bound-and-true-p spell-fu--cache-table))
          ;; For now simply clear syntax highlighting.
          (unless (<= spell-fu-idle-delay 0.0)
            (spell-fu--idle-remove-overlays))
          (spell-fu--remove-overlays)
          (font-lock-flush))))))

(defun spell-fu--word-add-or-remove (word words-file action)
  "Apply ACTION to WORD from the personal dictionary WORDS-FILE.

Return t when the action succeeded."
  (catch 'result
    (spell-fu--with-message-prefix "Spell-fu: "
      (unless word
        (message "word not found!")
        (throw 'result nil))
      (unless words-file
        (message "personal dictionary not defined!")
        (throw 'result nil))

      (let ((this-cache-table spell-fu--cache-table))
        (with-temp-buffer
          (insert-file-contents-literally words-file)

          ;; Ensure newline at EOF,
          ;; not essential but complicates sorted add if we don't do this.
          ;; also ensures we can step past the header which _could_ be a single line
          ;; without anything below it.
          (goto-char (point-max))
          (unless
            (string-blank-p
              (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
            (insert "\n"))
          ;; Delete extra blank lines.
          ;; So we can use line count as word count.
          (while
            (and
              (eq 0 (forward-line -1))
              (string-blank-p
                (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
            (delete-region
              (line-beginning-position)
              (progn
                (forward-line -1)
                (point))))

          (goto-char (point-min))

          ;; Case insensitive.
          (let
            (
              (changed nil)
              (header-match
                (save-match-data
                  (when
                    ;; Match a line like: personal_ws-1.1 en 66
                    (looking-at
                      (concat
                        "personal_ws-[[:digit:]\\.]+"
                        "[[:blank:]]+"
                        "[A-Za-z_]+"
                        "[[:blank:]]+"
                        "\\([[:digit:]]+\\)"))
                    (forward-line 1)
                    (match-data))))
              (word-point
                (save-match-data
                  (let ((case-fold-search t))
                    (when
                      (re-search-forward (concat "^" (regexp-quote word) "[[:blank:]]*$") nil t)
                      (match-beginning 0))))))

            (cond
              ((eq action 'add)
                (when word-point
                  (message "\"%s\" already in the personal dictionary." word)
                  (throw 'result nil))


                (let ((keep-searching t))
                  (while
                    (and
                      keep-searching
                      (string-lessp
                        (buffer-substring-no-properties
                          (line-beginning-position)
                          (line-end-position))
                        word))
                    (setq keep-searching (eq 0 (forward-line 1)))))

                (insert word "\n")

                (puthash (downcase word) t this-cache-table)

                (message "\"%s\" successfully added!" word)
                (setq changed t))

              ((eq action 'remove)
                (unless word-point
                  (message "\"%s\" not in the personal dictionary." word)
                  (throw 'result nil))

                ;; Delete line.
                (goto-char word-point)
                (delete-region
                  (line-beginning-position)
                  (or (and (eq 0 (forward-line 1)) (point)) (line-end-position)))

                (remhash (downcase word) this-cache-table)

                (message "\"%s\" successfully removed!" word)
                (setq changed t))

              (t ;; Internal error, should never happen.
                (error "Invalid action %S" action)))

            (when changed
              (when header-match
                (save-match-data
                  (set-match-data header-match)
                  (replace-match
                    (number-to-string (1- (count-lines (point-min) (point-max))))
                    t
                    nil
                    nil
                    1)))

              (write-region nil nil words-file nil 0)

              (spell-fu--buffers-refresh-with-cache-table this-cache-table)
              t)))))))

(defun spell-fu--word-at-point ()
  "Return the word at the current point or nil."
  (let
    (
      (point-init (point))
      (point-start (line-beginning-position))
      (point-end (line-end-position)))
    (save-excursion
      (goto-char point-start)
      (catch 'result
        (with-syntax-table spell-fu-syntax-table
          (save-match-data
            (while (re-search-forward spell-fu-word-regexp point-end t)
              (when (and (<= (match-beginning 0) point-init) (<= point-init (match-end 0)))
                (throw 'result (match-string-no-properties 0))))))
        (throw 'result nil)))))

(defun spell-fu-word-add ()
  "Add the current word to the personal dictionary.

Return t when the word has been added."
  (interactive)
  (spell-fu--word-add-or-remove (spell-fu--word-at-point) ispell-personal-dictionary 'add))

(defun spell-fu-word-remove ()
  "Remove the current word from the personal dictionary.

Return t when the word is removed."
  (interactive)
  (spell-fu--word-add-or-remove (spell-fu--word-at-point) ispell-personal-dictionary 'remove))


;; ---------------------------------------------------------------------------
;; Define Minor Mode
;;
;; Developer note, use global hooks since these run before buffers are loaded.
;; Each function checks if the local mode is active before operating.

(defun spell-fu-mode-enable ()
  "Turn on option `spell-fu-mode' for the current buffer."
  (spell-fu--ensure-dict (spell-fu--dictionary))

  ;; We may want defaults for other modes,
  ;; although keep this general.
  (cond
    ((derived-mode-p 'prog-mode)
      (unless spell-fu-faces-include
        (setq spell-fu-faces-include
          '(font-lock-comment-face font-lock-doc-face font-lock-string-face)))
      (unless spell-fu-faces-exclude
        (setq spell-fu-faces-exclude '(font-lock-constant-face)))))

  (cond
    ((<= spell-fu-idle-delay 0.0)
      (spell-fu--immediate-enable))
    (t
      (spell-fu--idle-enable))))

(defun spell-fu-mode-disable ()
  "Turn off option `spell-fu-mode' for the current buffer."
  (cond
    ((<= spell-fu-idle-delay 0.0)
      (spell-fu--immediate-disable))
    (t
      (spell-fu--idle-disable))))

;;;###autoload
(define-minor-mode spell-fu-mode
  "Toggle variable `spell-fu-mode' in the current buffer."
  :global nil

  (cond
    (spell-fu-mode
      (spell-fu-mode-enable))
    (t
      (spell-fu-mode-disable))))

(defun spell-fu--mode-turn-on ()
  "Enable the option `spell-fu-mode' where possible."
  (when
    (and
      ;; Not already enabled.
      (not spell-fu-mode)
      ;; Not in the mini-buffer.
      (not (minibufferp))
      ;; Not a special mode (package list, tabulated data ... etc)
      ;; Instead the buffer is likely derived from `text-mode' or `prog-mode'.
      (not (derived-mode-p 'special-mode))
      ;; Not explicitly ignored.
      (not (memq major-mode spell-fu-ignore-modes))
      ;; Optionally check if a function is used.
      (or
        (null global-spell-fu-ignore-buffer)
        (cond
          ((functionp global-spell-fu-ignore-buffer)
            (not (funcall global-spell-fu-ignore-buffer (current-buffer))))
          (t
            nil))))
    (spell-fu-mode 1)))

;;;###autoload
(define-globalized-minor-mode global-spell-fu-mode spell-fu-mode spell-fu--mode-turn-on)

(provide 'spell-fu)
;;; spell-fu.el ends here
