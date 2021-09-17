;;; counsel-edit-mode.el --- Edit results of counsel commands in-place -*- lexical-binding: t -*-
;; Author: Tyler Dodge
;; Version: 0.6
;; Package-Version: 20210824.1504
;; Package-Commit: 378803ac0040c04762ff001ab1aca7d4325ecf22
;; Keywords: convenience, matching
;; Package-Requires: ((emacs "26.1") (ht "2.3") (s "1.12.0") (counsel "0.10.0"))
;; URL: https://github.com/tyler-dodge/counsel-edit-mode
;; Git-Repository: git://github.com/tyler-dodge/counsel-edit-mode.git
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

;;;
;;;
;;; Commentary:
;; counsel-edit-mode can be added to the ivy actions for `counsel-ag' by adding
;; (counsel-edit-mode-setup-ivy) to your init file.
;;;
;;; Code:

(require 'counsel)
(require 'dash)
(require 'cl-lib)
(require 'ediff)
(require 'ht)
(require 's)

(defgroup counsel-edit nil
  "Mode for Ag-Edit Ivy ag results."
  :group 'counsel)

(defcustom counsel-edit-mode-major-mode
  'prog-mode
  "The default `major-mode' used by the `counsel-edit-mode` buffer.
This can be changed per `counsel-edit-mode` buffer
by calling \\[counsel-edit-mode-change-major-mode] in that buffer."
  :type 'function
  :group 'counsel-edit)

(defcustom counsel-edit-mode-expand-braces-by-default
  nil
  "When non-nil, expand the entire buffer at start.

When this is set non-nil, `counsel-edit-mode' will expand the context of each
file until all matching delimiters are closed.
This can be done manually per section by calling
\\[counsel-edit-mode-expand-section].

If \\[counsel-edit-mode-expand-section] is called with a prefix arg,
it will expand every section in the buffer."
  :type 'boolean
  :group 'counsel-edit)

(defcustom counsel-edit-mode-confirm-commits
  nil
  "The default `major-mode' used by `counsel-edit-mode'.

When this is set non-nil, `counsel-edit-mode` will confirm commits
with showing the changes in ediff.

\\[counsel-edit-mode--confirm-commit] confirms the changes in ediff.

\\[ediff-quit] will close the ediff session."
  :type 'boolean
  :group 'counsel-edit)

(defface counsel-edit-mode-overlay
  '((t . (:foreground "#99CCCC" :background "#AA2222")))
  "Face for file location side bar."
  :group 'counsel-edit)

(defface counsel-edit-mode-expanded-context-overlay
  '((t . (:foreground "#AACCCC" :background "#774444")))
  "Face for expanded context in file location side bar."
  :group 'counsel-edit)

(defface counsel-edit-mode-overlay-deleted
  '((t . (:inherit counsel-edit-mode-overlay :strike-through t)))
  "Face for deleted lines in file location side bar."
  :group 'counsel-edit)

(defface counsel-edit-mode-expanded-context-overlay-deleted
  '((t . (:inherit counsel-edit-mode-expanded-context-overlay :strike-through t)))
  "Face for expanded context deleted lines in file location side bar."
  :group 'counsel-edit)

(defvar counsel-edit-mode-map
  (--doto (make-sparse-keymap)
    (define-key it (kbd "C-c C-k") #'counsel-edit-mode-quit)
    (define-key it (kbd "C-c C-d") #'counsel-edit-mode-mark-line-deleted)
    (define-key it (kbd "C-c C-l") #'counsel-edit-mode-goto)
    (define-key it (kbd "C-c C-r") #'revert-buffer)
    (define-key it (kbd "C-c C-e") #'counsel-edit-mode-expand-section)
    (define-key it (kbd "C-c C-m") #'counsel-edit-mode-change-major-mode)
    (define-key it (kbd "C-c C-u") #'counsel-edit-mode-undo-line)
    (define-key it (kbd "C-c C-c") #'counsel-edit-mode-commit)
    (define-key it (kbd "C-c C-p") #'counsel-edit-mode-expand-context-up)
    (define-key it (kbd "C-c C-n") #'counsel-edit-mode-expand-context-down))
  "Keymap for `counsel-edit-mode'.")

(defvar counsel-edit-mode-ediff-mode-map
  (--doto (make-sparse-keymap)
    (define-key it (kbd "C-c C-c") #'counsel-edit-mode--confirm-commit))
  "Keymap for `counsel-edit-ediff-mode'.")

;;;###autoload
(defun counsel-edit-mode-setup-ivy ()
  "Add counsel-edit-mode-ivy-action to the ivy actions for counsel."
  (interactive)
  (ivy-add-actions 'counsel-git-grep
                   '(("e" counsel-edit-mode-ivy-action "Edit Results")))
  (ivy-add-actions 'counsel-grep
                   '(("e" counsel-edit-mode-ivy-action "Edit Results")))
  (ivy-add-actions 'counsel-rg
                   '(("e" counsel-edit-mode-ivy-action "Edit Results")))
  (ivy-add-actions 'counsel-ack
                   '(("e" counsel-edit-mode-ivy-action "Edit Results")))
  (ivy-add-actions 'counsel-ag
                   '(("e" counsel-edit-mode-ivy-action "Edit Results"))))

(defvar-local counsel-edit-mode--section-overlays nil
  "The list that `counsel-edit-mode' uses to keep track of the overlays.")

(defvar-local counsel-edit-mode--formatted-buffer nil
  "Boolean indicating that this buffer has already been formatted.")

(defvar-local counsel-edit-mode--start-buffer nil
  "Buffer that the counsel-edit-mode-action was invoked from.
Mainly exists for counsel-grep compatibility")

(defun counsel-edit-mode-ivy-action (&rest _)
  "Action for use with ivy that triggers `counsel-edit-mode'."
  (let ((start-buffer (current-buffer))
        (edit-buffer (generate-new-buffer "*counsel-edit*")))
    (-some--> (with-current-buffer edit-buffer
                (display-buffer edit-buffer)
                (with-current-buffer edit-buffer
                  (condition-case _
                      (save-excursion
                        (insert (shell-command-to-string (--> counsel--async-last-command
                                                           (if (listp it) (->> it
                                                                            (--map (shell-quote-argument it))
                                                                            (s-join " "))
                                                             it))))
                        (goto-char (point-min))
                        (funcall counsel-edit-mode-major-mode)
                        (setq-local counsel-edit-mode--start-buffer start-buffer)
                        (counsel-edit-mode 1)
                        edit-buffer)
                    (user-error (progn (kill-buffer edit-buffer)
                                       'deleted)))))
      (cond ((eq it 'deleted) (user-error "Failed to created buffer"))
            (t (prog1 it (display-buffer it)))))))

(define-minor-mode counsel-edit-mode
  "Special mode for Ag-Edit Buffers"
  nil
  " Ag-Edit"
  counsel-edit-mode-map
  (when counsel-edit-mode
    (when (buffer-file-name)
      (counsel-edit-mode -1)
      (user-error "Ag Edit Mode must be initialized in a non file visiting buffer"))
    (unless counsel-edit-mode--formatted-buffer
      (counsel-edit-mode--format-buffer)
      (when counsel-edit-mode-expand-braces-by-default (counsel-edit-mode-expand-all)))
    (setq-local after-change-functions (append (list #'counsel-edit-mode--after-change-fix-overlays) after-change-functions nil))
    (setq-local revert-buffer-function #'counsel-edit-mode--revert-buffer)))

(define-minor-mode counsel-edit-ediff-mode
  "Special mode for ediff buffers for use with `counsel-edit-mode'."
  nil
  " Ag-Ediff"
  counsel-edit-mode-ediff-mode-map)

(defvar-local counsel-edit-ediff-mode--target-buffer nil
  "Target buffer used with ediff.")

(defvar-local counsel-edit-ediff-mode--temp-buffer nil
  "Temporary buffer used with ediff.")

(defun counsel-edit-mode-ediff-changes ()
  "Ediff the modifications in the current `counsel-edit-mode' buffer.
Use `counsel-edit-mode--confirm-commit' to commit from the ediff control buffer."
  (interactive)
  (let ((target-buffer (current-buffer))
        (temp-buffer (counsel-edit-ediff-mode--generate-original-text-buffer)))
    (ediff-buffers temp-buffer (current-buffer)
                   (list (lambda ()
                           (counsel-edit-ediff-mode 1)
                           (add-hook 'ediff-quit-hook (lambda () (kill-buffer temp-buffer)) nil t)
                           (setq counsel-edit-ediff-mode--target-buffer target-buffer)
                           (setq counsel-edit-ediff-mode--temp-buffer temp-buffer))))))


(defun counsel-edit-mode-change-major-mode (new-major-mode)
  "Change the `major-mode' of the ag-edit buffer to NEW-MAJOR-MODE.
This handles preserving the `counsel-edit-mode' state correctly so
should be used instead of directly calling the `major-mode' functions."
  (interactive "C")
  (unless counsel-edit-mode (user-error "Can only call `counsel-edit-mode-change-major-mode' in `counsel-edit-mode' buffers"))
  (let ((formatted-buffer counsel-edit-mode--formatted-buffer)
        (sections counsel-edit-mode--section-overlays)
        (start-buffer counsel-edit-mode--start-buffer))
    (funcall-interactively new-major-mode)
    (setq-local counsel-edit-mode--formatted-buffer formatted-buffer)
    (setq-local counsel-edit-mode--section-overlays sections)
    (setq-local counsel-edit-mode--start-buffer start-buffer)
    (counsel-edit-mode 1)))

(defun counsel-edit-mode-mark-line-deleted ()
  "Mark the current line or regions for deletion once the `counsel-edit-mode' buffer is committed."
  (interactive)
  (save-mark-and-excursion
    (if (region-active-p)
        (let ((region-start (region-beginning))
              (region-end (region-end)))
          (goto-char (1- region-end))
          (while (> (point) region-start)
            (counsel-edit-mode--delete-line)
            (when (> (point) region-start) (forward-char -1))))
      (counsel-edit-mode--delete-line))))

(defun counsel-edit-mode-undo-line ()
  "Revert the current line or region back to its expected value.  Undo line deletions."
  (interactive)
  (save-mark-and-excursion
    (if (region-active-p) (counsel-edit-mode--undo-line-in-region (region-beginning) (region-end))
      (counsel-edit-mode--undo-line))))

(defun counsel-edit-mode-commit ()
  "Commit the modifications in the `counsel-edit-mode' buffer."
  (interactive)
  (unless counsel-edit-mode (user-error "Will only commit `counsel-edit-mode' buffers"))
  (if counsel-edit-mode-confirm-commits
      (counsel-edit-mode-ediff-changes)
    (counsel-edit-mode--confirm-commit)))

(defun counsel-edit-mode-quit ()
  "Discard the modifications in the `counsel-edit-mode' buffer."
  (interactive)
  (unless counsel-edit-mode (user-error "Will only quit `counsel-edit-mode' buffers"))
  (when (and counsel-edit-mode-confirm-commits (not (y-or-n-p "Really discard changes? ")))
    (user-error "Discard changes cancelled"))
  (kill-buffer (current-buffer)))

(defun counsel-edit-mode-goto ()
  "Goto the line that will be replaced with the one at point in the `counsel-edit-mode buffer'."
  (interactive)
  (unless counsel-edit-mode (user-error "Will only goto in `counsel-edit-mode' buffers"))
  (-let (((&plist :file-name :line-number) (overlay-get (counsel-edit-mode--prev-overlay-for-section) 'metadata)))
    (set-buffer (or (find-buffer-visiting file-name)
                    (find-file-noselect file-name)))
    (goto-char (point-min))
    (forward-line (1- line-number))
    (current-buffer)
    (display-buffer (current-buffer))))

(defun counsel-edit-mode-expand-all ()
  "Expand the context of all of the files in the `counsel-edit-mode' buffer until there are no unmatched delimiters."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (counsel-edit-mode--add-context-lines-in-contiguous-section)
    (redisplay)
    
    (let ((last-time (current-time)))
      (while (not (eobp))
        (forward-line 1)
        (counsel-edit-mode--add-context-lines-in-contiguous-section)
        (when (> (time-to-seconds (time-subtract (current-time) last-time)) 1)
          (setq last-time (current-time))
          (redisplay))))))

(defun counsel-edit-mode-expand-section (arg)
  "Expand the context of the current section while mismatched delimiters remain.
Given a prefix ARG, expand the context of all sections in the buffer."
  (interactive "P")
  (if arg (counsel-edit-mode-expand-all)
    (save-excursion (counsel-edit-mode--add-context-lines-in-contiguous-section))))


(defun counsel-edit-mode-expand-context-up (arg)
  "Expand the context of the current file up by one line or by the prefix ARG count."
  (interactive "P")
  (save-excursion
    (cl-loop for i from 0 below (or arg 1) do
             (-let [(&plist :file-name :line-number) (counsel-edit-mode--prev-missing-line-metadata)]
               (when (<= (1- line-number) 0) (user-error "Can't expand past file start"))
               (counsel-edit-mode--insert-overlay file-name (1- line-number))))))

(defun counsel-edit-mode-expand-context-down (arg)
  "Expand the context of the current file down by one line or by the prefix ARG count."
  (interactive "P")
  (save-excursion
    (cl-loop for i from 0 below (or arg 1) do
             (-let [(&plist :file-name :line-number) (counsel-edit-mode--next-missing-line-metadata)]
               (counsel-edit-mode--insert-overlay file-name (1+ line-number))))))

(defun counsel-edit-mode--confirm-commit ()
  "Commit the modifications in the `counsel-edit-mode' buffer."
  (interactive)
  (when counsel-edit-ediff-mode--target-buffer
    (let ((target-buffer counsel-edit-ediff-mode--target-buffer)
          (temp-buffer counsel-edit-ediff-mode--temp-buffer))
      (ediff-really-quit nil)
      (kill-buffer temp-buffer)
      (set-buffer target-buffer)))
  (unless counsel-edit-mode (user-error "Will only commit `counsel-edit-mode' buffers"))
  (counsel-edit-mode--validate-section-overlays)
  (-let* ((start-buffer (current-buffer))
          (modified-buffers (ht))
          (transformation-list (reverse (counsel-edit-mode--transformation-list))))
    (cl-loop for list = transformation-list then (cdr list)
             while list
             do
             (let ((transformation (car list)))
               (-let [(&plist :string replacement-text
                              :start-overlay
                              :metadata (&plist :original-text :file-name :line-number)) transformation]
                 (unless (and (string= original-text (s-chop-suffix "\n" replacement-text))
                              (not (overlay-get start-overlay 'counsel-edit-deleted)))
                   (with-current-buffer (or (find-buffer-visiting file-name)
                                            (find-file-noselect file-name))
                     (save-excursion
                       (goto-char (point-min))
                       (unless (ht-get modified-buffers (current-buffer))
                         (undo-boundary))
                       (ht-set modified-buffers (current-buffer) t)
                       (forward-line (1- line-number))
                       (forward-line 0)
                       (let ((text (buffer-substring (point) (save-excursion (end-of-line) (point)))))
                         (when (and (not (string= original-text text))
                                    (not (y-or-n-p (concat "Text changed since lookup.
Expected: " original-text "
Actual: " text "
Continue? "))))
                           (user-error "Text changed since lookup")))
                       (delete-region (point) (save-excursion (end-of-line) (point)))
                       (if (overlay-get start-overlay 'counsel-edit-deleted) (delete-char 1)
                         (insert (s-chop-suffix "\n" replacement-text)))))))))
    (cl-loop for buffer in (ht-keys modified-buffers)
             do (with-current-buffer buffer (undo-boundary) (save-buffer)))
    (when (eq (ht-size modified-buffers) 0)
      (message "No changes to commit."))
    (kill-buffer start-buffer)))

(defun counsel-edit-mode--add-context-lines-in-contiguous-section ()
  "Expand the current section until there are no longer any mismatched delimiters."
  (unless counsel-edit-mode (user-error "Will only goto in `counsel-edit-mode' buffers"))
  (cl-loop while
           (let ((mismatched (-some--> (cons (counsel-edit-mode--contiguous-section-start) (counsel-edit-mode--contiguous-section-end))
                               (and (car it) (cdr it) it)
                               (counsel-edit-mode--validate-parens  (car it) (cdr it)))))
             (when mismatched
               (condition-case err
                   (pcase mismatched
                     ((or ?\} ?\) ?\])
                      (-let [(&plist :file-name :line-number) (counsel-edit-mode--prev-missing-line-metadata)]
                        (when (<= (1- line-number) 0) (user-error "Missing matching delimiter"))
                        (counsel-edit-mode--insert-overlay file-name (1- line-number))
                        t))
                     ((or ?\{ ?\( ?\[)
                      (-let [(&plist :file-name :line-number) (counsel-edit-mode--next-missing-line-metadata)]
                        (counsel-edit-mode--insert-overlay file-name (1+ line-number))
                        t))
                     (pt (user-error "Unexpected delimiter %s" pt)))
                 (error (message "Error While parsing %s. %s"
                                 (plist-get  (overlay-get (counsel-edit-mode--prev-overlay-for-section) 'metadata) :file-name)
                                 (error-message-string err)) nil)
                 (user-error (message "Error While parsing %s. %s"
                                      (plist-get  (overlay-get (counsel-edit-mode--prev-overlay-for-section) 'metadata) :file-name)
                                      (error-message-string err)) nil)))))
  (-some--> (counsel-edit-mode--contiguous-section-end) (goto-char it)))

(defun counsel-edit-mode--matching-delimiter (delimiter)
  "Return the matching delimiter for DELIMITER."
  (pcase delimiter
    (?\] ?\[)
    (?\) ?\()
    (?\} ?\{)

    (?\[ ?\])
    (?\( ?\))
    (?\{ ?\})))

(defun counsel-edit-mode--validate-parens (start end)
  "Validate the delimiters match between START and END.
If a mismatch is found:
  Goto the point of the mismatched delimiter.
  Return the mismatched delimiter."
  (goto-char start)
  (cl-block nil
    (let ((stack nil)
          (state 'normal))
      (while (< (point) end)
        (pcase state
          ('string
           (pcase (char-after (point))
             (?\"
              (setq state 'normal))))
          ('lisp-char-literal
           (setq state 'normal))
          ('start-lisp-char-literal
           (pcase (char-after (point))
             (?\\ (setq state 'lisp-char-literal))
             (_ (setq state 'normal))))
          ('normal
           (pcase (char-after (point))
             (?\? (setq state 'start-lisp-char-literal))
             (?\" (setq state 'string))
             ((or ?\} ?\) ?\])
              (unless stack (cl-return (char-after (point))))
              (when (eq (char-after (point))
                        (counsel-edit-mode--matching-delimiter (caar stack)))
                (pop stack)))

             ((or ?\{ ?\( ?\[)
              (push (cons (char-after (point)) (point)) stack))
             (_ ))))
        (forward-char 1))
      (-some->> stack (cdar) (goto-char))
      (caar stack))))

(defun counsel-edit-mode--prev-missing-line-metadata ()
  "Return the metadata for the start of the current contiguous section."
  (-let* ((section (counsel-edit-mode--prev-overlay-for-section))
          ((last-metadata &as &plist :file-name :line-number last-line-number) (overlay-get section 'metadata))
          (done nil)
          (start-file file-name))
    (forward-line -1)
    (cl-loop
     while (not (or done (bobp)))
     do
     (-let (((loop-metadata &as &plist :file-name loop-file-name :line-number loop-number)
             (-some--> (counsel-edit-mode--prev-overlay-for-section) (overlay-get it 'metadata))))
       (if (or (not (string= loop-file-name start-file))
               (not (eq loop-number (1- last-line-number))))
           (progn (forward-line 1)
                  (end-of-line)
                  (setq done t))
         (setq last-line-number loop-number)
         (setq last-metadata loop-metadata)
         (forward-line -1)))
     finally return (overlay-get  (counsel-edit-mode--prev-overlay-for-section) 'metadata))))

(defun counsel-edit-mode--next-missing-line-metadata ()
  "Return the metadata for the end of the current contiguous section."
  (-let* ((section (counsel-edit-mode--prev-overlay-for-section))
          ((last-metadata &as &plist :file-name :line-number last-line-number) (overlay-get section 'metadata))
          (done nil)
          (start-file file-name))
    (forward-line 1)
    (cl-loop
     while (not (or done (eobp)))
     do
     (-let (((loop-metadata &as &plist :file-name loop-file-name :line-number loop-number)
             (-some--> (counsel-edit-mode--prev-overlay-for-section) (overlay-get it 'metadata))))
       (if (or (not (string= loop-file-name start-file))
               (not (eq loop-number (1+ last-line-number))))
           (progn (forward-line -1)
                  (end-of-line)
                  (setq done t))
         (setq last-line-number loop-number)
         (setq last-metadata loop-metadata)
         (forward-line 1)))
     finally return last-metadata)))

(defun counsel-edit-mode--prev-overlay-for-section ()
  "Get the overlay for the start of the next section.
Returns nil for the last section in the buffer."
  (-let ((overlay nil)
         (at-pt-min nil))
    (save-excursion
      (while (and (not overlay) (not at-pt-min))
        (setq overlay
              (--first
               (overlay-get it 'counsel-edit-overlay)
               (overlays-in (point) (point))))
        (if (bobp) (setq at-pt-min t)
          (forward-char -1)))
      overlay)))

(defun counsel-edit-mode--next-overlay-for-section ()
  "Get the overlay for the start of the next section.
Returns nil for the last section in the buffer."
  (-let ((overlay nil))
    (save-excursion
      (unless (eobp) (forward-char 1))
      (while (and (not overlay) (not (eobp)))
        (setq overlay
              (--first
               (overlay-get it 'counsel-edit-overlay)
               (overlays-in (point)
                            (point))))
        (forward-char 1))
      overlay)))

(defun counsel-edit-mode--bounds-of-section ()
  "Return a cons of the form (start of section . end of section)."
  (cons (overlay-start (counsel-edit-mode--prev-overlay-for-section))
        (or (-some--> (counsel-edit-mode--next-overlay-for-section)
              (overlay-start it))
            (point-max))))

(defun counsel-edit-mode--insert-overlay (file-name line-number)
  "Insert an overlay for the line described by FILE-NAME and LINE-NUMBER."
  (let ((inhibit-modification-hooks t))
    (-let [(found &as &plist :overlay :pt)
           (cl-block nil
             (cl-loop for overlays = counsel-edit-mode--section-overlays then (cdr overlays)
                      until (not overlays)
                      do
                      (-let [((loop-overlay &as &plist :metadata (&plist :file-name loop-file-name :line-number loop-line-number))
                              (next-overlay &as &plist :metadata (&plist :file-name next-file-name :line-number next-line-number))
                              . _) overlays]
                        (when (and (string= file-name loop-file-name)
                                   (eq line-number loop-line-number))
                          (cl-return nil))
                        (when (and
                               (string= file-name loop-file-name)
                               (or
                                (not next-overlay)
                                (not (string= file-name next-file-name))
                                (> loop-line-number line-number)
                                (> next-line-number line-number)))
                          (cl-return
                           (if (< line-number loop-line-number) loop-overlay (or next-overlay
                                                                                 (list :pt (save-excursion (goto-char (point-max))
                                                                                                           (forward-line -1)
                                                                                                           (end-of-line)
                                                                                                           (point))))))))))]
      (when found
        (save-excursion
          (goto-char (or pt (1- (overlay-start overlay))))
          (let* ((original-text (with-current-buffer (find-file-noselect file-name)
                                  (save-excursion
                                    (goto-char (point-min))
                                    (forward-line (1- line-number))
                                    (when (< (line-number-at-pos (point)) line-number)
                                      (user-error "Line Number after the end of file"))
                                    (buffer-substring (point) (save-excursion (end-of-line) (point))))))
                 (metadata (list :file-name file-name
                                 :original-text original-text
                                 :line-number line-number)))
            (if (eq (point-min) (point))
                (progn
                  (insert "\n")
                  (move-overlay overlay (1+ (point-min)) (1+ (point-min)))
                  (forward-char -1))
              ;; else
              (insert "\n"))
            (cl-loop for overlays = counsel-edit-mode--section-overlays then (cdr overlays)
                     while overlays
                     until
                     (let ((has-next-overlay-p (cdr overlays))
                           (target-is-current-overlay-p (eq (plist-get (car overlays) :overlay) overlay))
                           (target-is-next-overlay-p (eq (plist-get (cadr overlays) :overlay) overlay)))

                       (cond
                        (target-is-current-overlay-p
                         (prog1 t
                           (setq-local
                            counsel-edit-mode--section-overlays
                            (cons
                             (list
                              :overlay (--doto (counsel-edit-mode--make-line-details-overlay
                                                (point)
                                                original-text metadata
                                                'counsel-edit-mode-expanded-context-overlay)
                                         (overlay-put it 'counsel-edit-order 0))
                              :metadata metadata)
                             (--map (prog1 it
                                      (overlay-put (plist-get it :overlay)
                                                   'counsel-edit-order
                                                   (1+ (or (overlay-get (plist-get it :overlay) 'counsel-edit-order)
                                                           0))))
                                    counsel-edit-mode--section-overlays)))))
                        ((or target-is-next-overlay-p
                             (not has-next-overlay-p))
                         (prog1 t
                           (cl-loop for overlay in (cdr overlays)
                                    do (overlay-put (plist-get overlay :overlay) 'counsel-edit-order (1+ (overlay-get (plist-get overlay :overlay)
                                                                                                            'counsel-edit-order))))
                           (setcdr overlays (cons (list
                                                   :overlay (--doto (counsel-edit-mode--make-line-details-overlay
                                                                     (point)
                                                                     original-text
                                                                     metadata
                                                                     'counsel-edit-mode-expanded-context-overlay)
                                                              (overlay-put it
                                                                           'counsel-edit-order
                                                                           (or (-some-->
                                                                                   (car overlays)
                                                                                 (plist-get it :overlay)
                                                                                   (overlay-get it 'counsel-edit-order)
                                                                                 (1+ it))
                                                                               0)))
                                                   :metadata metadata)
                                                  (cdr overlays))))))))
            (let* ((start-pt (or pt
                                 (-some--> overlay (save-excursion (goto-char (overlay-start it)) (point)))))
                   (end-pt (save-excursion
                             (progn
                               (insert original-text)
                               (unless (eq (point-max) (point)) (forward-line 1))
                               (point)))))
              (goto-char start-pt)
              (counsel-edit-mode--after-change-fix-overlays (1- start-pt) (1+ end-pt))
              (goto-char end-pt))))))))


(defun counsel-edit-mode--contiguous-section-end ()
  "Return the point for the end of the current contiguous set of lines."
  (cl-block nil
    (-let ((start-overlay (counsel-edit-mode--prev-overlay-for-section))
           (after-overlay-line-number nil))
      (cl-loop for list = counsel-edit-mode--section-overlays then (cdr list)
               while list
               do
               (-let [(&plist :overlay :metadata (&plist :file-name :line-number)) (car list)]
                 (progn
                   (when (eq start-overlay overlay)
                     (setq after-overlay-line-number line-number))
                   (when after-overlay-line-number
                     (-let [(plist &as &plist
                                   :overlay next-overlay
                                   :metadata (&plist :file-name next-file-name
                                                     :line-number next-line-number) ) (cadr list)]
                       (setq after-overlay-line-number line-number)
                       (unless plist
                         (cl-return (point-max)))
                       (when (or (not (string= next-file-name file-name))
                                 (< 1 (abs (- after-overlay-line-number next-line-number))))
                         (cl-return (1- (overlay-start next-overlay))))))))))))

(defun counsel-edit-mode--contiguous-section-start ()
  "Return the point for the beginning of the current contiguous set of lines."
  (cl-block nil
    (-let ((start-overlay (counsel-edit-mode--prev-overlay-for-section))
           (after-overlay-line-number))
      (cl-loop for list = (reverse counsel-edit-mode--section-overlays) then (cdr list)
               while list
               do
               (-let [(&plist :overlay :metadata (&plist :file-name :line-number)) (car list)]
                 (progn
                   (when (eq start-overlay overlay)
                     (setq after-overlay-line-number (plist-get (overlay-get start-overlay 'metadata) :line-number)))
                   (when after-overlay-line-number
                     (-let [(plist &as &plist :metadata (&plist :file-name next-file-name :line-number next-line-number) ) (cadr list)]
                       (setq after-overlay-line-number line-number)
                       (when (or (not plist)
                                 (not (string= next-file-name file-name))
                                 (< 1 (abs (- after-overlay-line-number next-line-number))))
                         (cl-return (overlay-start overlay)))))))))))

(defun counsel-edit-mode--revert-buffer (&rest _)
  "Revert the buffer to the current state of the target buffers."
  (interactive)
  (let ((start-overlay (counsel-edit-mode--prev-overlay-for-section)))
    (cl-loop for overlays = counsel-edit-mode--section-overlays then (cdr overlays)
             while overlays
             do
             (-let [((overlay-plist
                      &as &plist
                      :overlay
                      :metadata (overlay-metadata
                                 &as &plist
                                 :file-name
                                 :line-number)) . _) overlays]
               (let ((original-text
                      (with-current-buffer (or (find-buffer-visiting file-name)
                                               (find-file-noselect file-name))
                        (save-excursion
                          (goto-char (point-min))
                          (forward-line (1- line-number))
                          (when (< (line-number-at-pos (point)) line-number)
                            (error "Line Number after the end of file"))
                          (buffer-substring (point) (save-excursion (end-of-line) (point)))))))
                 (overlay-put overlay 'original-text original-text)
                 (setcar overlays
                         (plist-put overlay-plist
                                    :metadata (--> overlay-metadata
                                                   (plist-put it :original-text original-text)))))))
    (--each (->> counsel-edit-mode--section-overlays (--map (plist-get it :overlay)))
      (progn
        (goto-char (overlay-start it))
        (counsel-edit-mode--undo-line)))
    (goto-char (overlay-start start-overlay))))


  ;; (rx  line-start
  ;;      (zero-or-one (group-n 1 (* (not ":")))
  ;;                   ":")
  ;;      (group-n 2 (* (not ":")))
  ;;      ":"
  ;;      (zero-or-one
  ;;       (group-n 3 (* (not ":")) ":"))

  ;;      (group-n 4 (* (not "\n")) line-end))
(defvar counsel-edit-mode--line-regexp
  "^\\(?:\\(?1:[^:]*\\):\\)?\\(?2:[^:]*\\):\\(?3:[^:]*:\\)?\\(?4:.*$\\)"
  "See comment near definition for generating (rx).")

(defun counsel-edit-mode--format-buffer ()
  "Format the counsel-edit-mode buffer.
Is a no-op if run multiple times in a `counsel-edit-mode' buffer."
  (unless counsel-edit-mode (user-error "Will only format `counsel-edit-mode' buffers"))
  (unless counsel-edit-mode--formatted-buffer
    (delete-all-overlays)
    (goto-char (point-max))
    (let ((inhibit-read-only t)
          (addresses (ht)))
      (cl-loop while (re-search-backward counsel-edit-mode--line-regexp
                                         nil t)
               collect
               (let* ((file-name (or (-some--> (match-string 1)
                                          (unless (s-numeric-p it) it))
                                  (buffer-file-name counsel-edit-mode--start-buffer)))
                      (line-number (or (-some--> (match-string 1)
                                            (when (s-numeric-p it) it))
                                       (match-string 2)))
                      (column-number (match-string 3))
                      (section-start (match-beginning 4))
                      (section-end (match-end 4))
                      (full-line-start (match-beginning 0))
                      (full-line-end (match-end 0))
                      (original-text (buffer-substring section-start section-end))
                      (dedupe-key (concat file-name ":" line-number))
                      (metadata (list :file-name file-name
                                      :original-text original-text
                                      :line-number (string-to-number line-number)
                                      :column-number (-some--> column-number (string-to-number it)))))

                 (if (ht-get addresses dedupe-key)
                     (progn
                       (forward-line 0)
                       (delete-char (- (save-excursion (end-of-line) (1+ (point))) (point))))
                   (add-text-properties (max (1- full-line-start) 1) full-line-end
                                        `(metadata ,metadata))
                   (add-text-properties full-line-start section-start '(read-only t))
                   (ht-set addresses dedupe-key t)

                   (setq-local
                    counsel-edit-mode--section-overlays
                    (cons
                     (list
                      :overlay (--doto (counsel-edit-mode--make-line-details-overlay section-start original-text metadata)
                                 (overlay-put it 'counsel-edit-order 0))
                      :metadata metadata)
                     (--map (prog1 it
                              (overlay-put (plist-get it :overlay)
                                           'counsel-edit-order
                                           (1+ (overlay-get (plist-get it :overlay) 'counsel-edit-order))))
                            counsel-edit-mode--section-overlays)))
                   (goto-char section-end)
                   ;;(insert " ")
                   ;;(add-text-properties section-end (1+ section-end) '(read-only t cursor-intangible t))
                   (goto-char section-start)
                   (delete-char (- full-line-start section-start))))))
    (buffer-disable-undo)
    (setq-local counsel-edit-mode--formatted-buffer t)))

(defun counsel-edit-mode--validate-section-overlays ()
  "Final check to ensure that the user is notified if overlays are messed up."
  (-let ((overlay-start-ordered-list (->> counsel-edit-mode--section-overlays
                                          (--map (cons (overlay-start (plist-get it :overlay))
                                                       (overlay-get (plist-get it :overlay) 'counsel-edit-order)))
                                          (--sort (< (car it) (car other)))
                                          (--map (cdr it)))))
    (unless (equal overlay-start-ordered-list (cl-loop for i upfrom 0 below (length overlay-start-ordered-list) collect i))
      (unless (y-or-n-p "Overlays are not sorted correctly.  This buffer might be dangerous to use for substitution.  Continue? ")
        (user-error "Overlays are not sorted correctly.  This buffer might be dangerous to use for substitution.  %S"
               overlay-start-ordered-list)))))

(defun counsel-edit-ediff-mode--generate-original-text-buffer ()
  "Return a new buffer containing the original text for the current `ag-edit-mode' buffer."
  (-let  ((overlays counsel-edit-mode--section-overlays)
          (text (buffer-string))
          (start-major-mode major-mode))
    (with-current-buffer (generate-new-buffer " *counsel-edit-mode-original-text*")
      (funcall start-major-mode)
      (save-excursion
        (prog1 (current-buffer)
          (let ((counsel-edit-mode-expand-braces-by-default nil))
            (counsel-edit-mode 1))
          (insert text)
          (setq-local counsel-edit-mode--section-overlays (->> overlays
                                                     (--map
                                                      (plist-put (cl-copy-list it)
                                                                 :overlay
                                                                 (let* ((overlay (plist-get it :overlay))
                                                                        (overlay-start (overlay-start overlay))
                                                                        (overlay-end (overlay-end overlay)))
                                                                   (--doto (copy-overlay overlay)
                                                                     (move-overlay it overlay-start overlay-end (current-buffer))))))))
          (counsel-edit-mode--undo-line-in-region (point-min) (point-max))
          (goto-char (point-max))
          (insert "\n"))))))

(defun counsel-edit-mode--make-line-details-overlay (pt original-text metadata &optional face)
  "Initialize a line details overlay at PT.

The overlay will have the following properties:
  `original-text' ORIGINAL-TEXT
  `metadata' METADATA

FACE defaults to `counsel-edit-mode-overlay' if nil."
  (-let [(&plist :file-name :line-number) metadata]
    (let ((overlay-text (concat
                         (propertize (concat " " file-name ":" (number-to-string line-number) " ")
                                     'face (or face 'counsel-edit-mode-overlay))
                         " ")))
      (--doto (make-overlay pt pt (current-buffer) t nil)
        (overlay-put it 'counsel-edit-overlay t)
        (overlay-put it 'metadata metadata)
        (overlay-put it 'original-text original-text)
        ;;(overlay-put it 'insert-in-front-hooks '(counsel-edit-mode--after-change-fix-overlays))
        ;;(overlay-put it 'insert-behind-hooks '(counsel-edit-mode--after-change-fix-overlays))
        (overlay-put it 'before-string overlay-text)))))

(defun counsel-edit-mode--delete-line ()
  "Mark the current line for deletion."
  (-let ((overlay (counsel-edit-mode--prev-overlay-for-section)))
    (save-excursion
      (-let ((end (-some--> (counsel-edit-mode--next-overlay-for-section) (1- (overlay-start it)))))
        (--doto (overlay-get overlay 'before-string)
          (let ((deleted-face (pcase (get-text-property 0 'face it)
                                ('counsel-edit-mode-overlay 'counsel-edit-mode-overlay-deleted)
                                ('counsel-edit-mode-expanded-context-overlay 'counsel-edit-mode-expanded-context-overlay-deleted)
                                (unknown (error "Unknown face at position %s" unknown)))))
            (add-text-properties 1 (- (length it) 2) `(face ,deleted-face) it)))
        (overlay-put overlay 'counsel-edit-deleted t)
        (goto-char (overlay-start overlay))
        (delete-char (- (or end (point-max)) (overlay-start overlay)))))
    (goto-char (overlay-start overlay))))

(defun counsel-edit-mode--undo-line ()
  "Revert the current line back to its expected value.  Undo line deletions."
  (let ((section-overlay (counsel-edit-mode--prev-overlay-for-section)))
    (save-excursion
      (-let ((end (-some--> (counsel-edit-mode--next-overlay-for-section) (overlay-start it))))
        (goto-char (overlay-start section-overlay))
        (overlay-put section-overlay 'counsel-edit-deleted nil)
        (--doto (overlay-get section-overlay 'before-string)
          (add-text-properties 1 (- (length it) 2) `(face ,(get-text-property 0 'face it)) it))
        (delete-char (- (or end (point-max)) (overlay-start section-overlay)))
        (insert (overlay-get section-overlay 'original-text))))
    (goto-char (overlay-start section-overlay))))

(defun counsel-edit-mode--undo-line-in-region (region-start region-end)
  "Revert the lines back to their expected values between REGION-START REGION-END."
  (goto-char (if (eq (point-max) region-end) (point-max) (1- region-end)))
  (let ((at-start nil))
    (while (not at-start)
      (when (eq (point) region-start) (setq at-start t))
      (forward-line 0)
      (counsel-edit-mode--undo-line)
      (when (> (point) region-start)
        (forward-char -1)))))

(defun counsel-edit-mode--after-change-fix-overlays (beg &rest _)
  "Fix the overlays starting at BEG so that the invariants stay true."
  (save-excursion
    (-let ((overlays (->> (overlays-in (save-excursion (goto-char (1- beg)) (forward-line 0) (max (point-min) (1- (point))))
                                       (save-excursion (goto-char (1+ beg)) (end-of-line) (min (point-max) (1+ (point)))))
                          (--filter (overlay-get it 'counsel-edit-order))
                          (--sort (< (overlay-get it 'counsel-edit-order) (overlay-get other 'counsel-edit-order))))))
      (unless overlays
        (goto-char beg)
        (let ((overlay (counsel-edit-mode--prev-overlay-for-section)))
          (when overlay
            (goto-char (overlay-start overlay))
            (let ((next-overlay-start (or (-some--> (counsel-edit-mode--next-overlay-for-section) (overlay-start it))
                                          (point-max))))
              (remove-text-properties (overlay-start overlay) (max (1- next-overlay-start)
                                                                   (overlay-start overlay)) '(line-prefix))
              (forward-line 1)
              (counsel-edit-mode--propertize-line-prefix-region (point) (1- next-overlay-start) overlay)))))
      (cl-loop for overlay in overlays
               do
               (progn
                 (-let* ((start (overlay-start overlay))
                         (delimiter (or (char-before start) ?\n))
                         (other-overlays (->> (overlays-in start start)
                                              (--filter (and (overlay-get it 'counsel-edit-order)
                                                             (not (eq overlay it)))))))
                   (goto-char start)
                   (unless (eq delimiter ?\n)
                     (insert "\n")
                     (-let [new-pt (point)]
                       (--each (append (list overlay) other-overlays)
                         (move-overlay it new-pt new-pt))))
                   (when other-overlays
                     (insert "\n")
                     (--each other-overlays
                       (move-overlay it (point) (point))))
                   (goto-char (overlay-start overlay))
                   (let ((next-overlay-start (or (-some--> (counsel-edit-mode--next-overlay-for-section) (overlay-start it))
                                                 (point-max))))
                     (remove-text-properties (overlay-start overlay) (max (1- next-overlay-start)
                                                                          (overlay-start overlay)) '(line-prefix))
                     (goto-char (overlay-start overlay))
                     (forward-line 1)
                     (counsel-edit-mode--propertize-line-prefix-region (point) (1- next-overlay-start) overlay))))))))

(defun counsel-edit-mode--propertize-line-prefix-region (beg end overlay)
  "Propertize the section between BEG and END with line-prefixes.
Does nothing if OVERLAY is not the overlay for the section between BEG and END."
  (save-excursion
    (goto-char beg)
    (when (and (< beg end) (eq (counsel-edit-mode--prev-overlay-for-section) overlay))
      (add-text-properties
       beg
       (max beg end)
       `(line-prefix ,(propertize (s-center (1- (length (overlay-get overlay 'before-string))) " ! ")
                                  'face 'counsel-edit-mode-expanded-context-overlay))))))

(defun counsel-edit-mode--transformation-list ()
  "Return a list where each item is a plist.
The plist is of the form:
\\(:metadata :start-overlay :end-overlay :string\\).

:string the transformation text
:end-overlay overlay marking the start of the next sectionn
:start-overlay the overlay marking the start of the section
:metadata the metadata for the section"
  (cl-loop for rest = counsel-edit-mode--section-overlays then (cdr rest)
       while (car rest)
       collect
       (-let* ((start-overlay (plist-get (car rest) :overlay))
              (end-overlay (-some--> (cadr rest) (plist-get it :overlay)))
              (start (overlay-end start-overlay))
              (end (or (-some--> end-overlay (overlay-end it))
                       (point-max))))
         (list
          :metadata (plist-get (car rest) :metadata)
          :start-overlay start-overlay
          :end-overlay end-overlay
          :string (buffer-substring start end)))))

(provide 'counsel-edit-mode)
;;; counsel-edit-mode.el ends here
