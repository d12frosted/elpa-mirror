;;; eopengrok.el --- opengrok interface for emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Youngjoo Lee

;; Author: Youngjoo Lee <youngker@gmail.com>
;; Version: 1.7.42
;; Package-Version: 20230114.1413
;; Package-Commit: 83b1695774f8bdc322e528ade9dffe9b2e93f32a
;; Keywords: tools
;; Package-Requires: ((s "1.9.0") (dash "2.10.0") (magit "2.1.0") (cl-lib "0.5"))

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

;; opengrok interface for Emacs
;;
;; See documentation on https://github.com/youngker/eopengrok.el

;;; Code:

(require 's)
(require 'dash)
(require 'etags)
(require 'magit)
(require 'cl-lib)
(require 'xref)

(defvar eopengrok-pending-output nil)
(defvar eopengrok-last-filename nil)
(defvar eopengrok-page nil)
(defvar eopengrok-mode-line-status 'not-running)
(defvar eopengrok--line-overlay nil)

(defconst eopengrok-buffer "*eopengrok*")
(defconst eopengrok-indexing-buffer "*eopengrok-indexing*")

(defconst eopengrok-history-regexp
  "^\\([[:lower:][:upper:]]?:?.*?\\)::[ \t]+\\(\\w+\\)\\(.*\\)")

(defconst eopengrok-source-regexp
  "^\\([[:lower:][:upper:]]?:?.*?\\):\\([0-9]+\\):\\(.*\\)")

(defconst eopengrok-page-separator-regexp
  "^clj-opengrok> \\([0-9]+\\)/\\([0-9]+\\)")

(defgroup eopengrok nil
  "Opengrok interface for EMACS."
  :prefix "eopengrok-"
  :group 'applications)

(defcustom eopengrok-configuration
  ".opengrok/configuration.xml"
  "Configuration file."
  :type 'string
  :group 'eopengrok)

(defcustom eopengrok-abbreviate-filename 80
  "Abbreviate filename length."
  :type 'number
  :group 'eopengrok)

(defcustom eopengrok-mode-line '(:eval (eopengrok--mode-line-page))
  "Mode line lighter for eopengrok."
  :group 'eopengrok
  :type 'sexp
  :risky t)

(defcustom eopengrok-mode-line-prefix "EOG"
  "Mode line prefix."
  :group 'eopengrok
  :type 'string)

(defcustom eopengrok-ignore-file-or-directory
  ".opengrok:out:*.so:*.a:*.o:*.gz:*.bz2:*.jar:*.zip:*.class:*.elc"
  "Ignore files or directories."
  :group 'eopngrok
  :type 'string)

(defface eopengrok-file-face
  '((t :inherit font-lock-function-name-face))
  "Face for files."
  :group 'eopengrok)

(defface eopengrok-info-face
  '((t :inherit font-lock-constant-face))
  "Face for info."
  :group 'eopengrok)

(defface eopengrok-source-face
  '((t :inherit font-lock-doc-face))
  "Face for source."
  :group 'eopengrok)

(defface eopengrok-highlight-face
  '((t :inherit highlight))
  "Face for highlight item."
  :group 'eopengrok)

(defface eopengrok-highlight-line-face
  '((t :inherit hl-line))
  "Face for highlight line."
  :group 'eopengrok)

(defun eopengrok-resume ()
  "Resume *eopengrok* buffer."
  (interactive)
  (when (get-buffer eopengrok-buffer)
    (pop-to-buffer eopengrok-buffer)))

(defun eopengrok-quit ()
  "Quit `eopengrok-mode'."
  (interactive)
  (if eopengrok--line-overlay
      (delete-overlay eopengrok--line-overlay))
  (let* ((buf (current-buffer))
         (proc (get-buffer-process buf)))
    (when (process-live-p proc)
      (kill-process proc)
      (sleep-for 0.1))
    (kill-buffer buf)))

(defun eopengrok--get-configuration ()
  "Search for Project configuration.xml."
  (let* ((start-dir (expand-file-name default-directory))
         (index-dir (locate-dominating-file start-dir eopengrok-configuration)))
    (if index-dir
        (concat (expand-file-name index-dir) eopengrok-configuration)
      (user-error "Can't find configuration.xml"))))

(defun eopengrok--search-option (conf text option symbol)
  "Opengrok search option list with CONF TEXT OPTION SYMBOL."
  (if (eq symbol 'custom)
      (-flatten (list "search" "-R" conf (split-string text " " t)))
    (list "search" "-R" conf option text)))

(defmacro eopengrok--properties-region (props &rest body)
  "Add PROPS and Execute BODY to all the text it insert."
  (let ((start (cl-gensym)))
    `(let ((,start (point)))
       (prog1 (progn ,@body)
         (add-text-properties ,start (point) ,props)))))

(defun eopengrok--get-properties (pos)
  "Get properties at POS."
  (list (get-text-property pos :name)
        (get-text-property pos :info)))

(defun eopengrok--highlight-current-line ()
  "Make overlay in current line."
  (let ((s (line-beginning-position))
        (e (1+ (line-end-position))))
    (if eopengrok--line-overlay
        (move-overlay eopengrok--line-overlay s e (current-buffer))
      (setq eopengrok--line-overlay (make-overlay s e)))
    (overlay-put eopengrok--line-overlay 'face 'eopengrok-highlight-line-face)
    (recenter)))

(defun eopengrok--open-file ()
  "Open with `find-file-other-window'."
  (-when-let ((file number)
              (eopengrok--get-properties (point)))
    (find-file-other-window file)
    (goto-char (point-min))
    (forward-line (1- number))
    (eopengrok--highlight-current-line)))

(defun eopengrok--show-commit (noselect)
  "Display `magit-show-commit' with NOSELECT."
  (-when-let* (((file commit-id) (eopengrok--get-properties (point))))
    (setq default-directory (file-name-directory file))
    (let ((magit-display-buffer-noselect noselect))
      (magit-git-string "rev-parse" "--show-toplevel")
      (magit-show-commit commit-id))))

(defun eopengrok-jump-to-source ()
  "Jump point to the other window."
  (interactive)
  (if (numberp (get-text-property (point) :info))
      (eopengrok--open-file)
    (eopengrok--show-commit nil))
  (delete-overlay eopengrok--line-overlay)
  (xref-push-marker-stack (point-marker)))

(defun eopengrok-move-line (pfn lfn)
  "Move point with PFN and LFN."
  (with-current-buffer (current-buffer)
    (-when-let (pos (funcall pfn (save-excursion
                                   (funcall lfn) (point)) :info))
      (goto-char pos)
      (beginning-of-line)
      (save-selected-window
        (if (numberp (get-text-property (point) :info))
            (eopengrok--open-file)
          (eopengrok--show-commit nil))))))

(defun eopengrok-next-line ()
  "Move point to the next search result, if one exists."
  (interactive)
  (eopengrok-move-line #'next-single-property-change
                       #'end-of-line))

(defun eopengrok-previous-line ()
  "Move point to the previous search result, if one exists."
  (interactive)
  (eopengrok-move-line #'previous-single-property-change
                       #'beginning-of-line))

(defun eopengrok--abbreviate-file (file)
  "Abbreviate FILE name."
  (let* ((start (- (point) (length file)))
         (end (point))
         (amount (if (numberp eopengrok-abbreviate-filename)
                     (- (- end start) eopengrok-abbreviate-filename)
                   999))
         (advance-word (lambda ()
                         "Return the length of the text made invisible."
                         (let ((wend (min end (progn (forward-word 1) (point))))
                               (wbeg (max start (progn (backward-word 1) (point)))))
                           (goto-char wend)
                           (if (<= (- wend wbeg) 1)
                               0
                             (put-text-property (1+ wbeg) wend 'invisible t)
                             (1- (- wend wbeg)))))))
    (goto-char start)
    (while (and (> amount 0) (> end (point)))
      (cl-decf amount (funcall advance-word)))
    (goto-char end)))

(defun eopengrok--remove-html-tags (text)
  "Remove html tag from TEXT."
  (->> text
       (replace-regexp-in-string "<[^>]*>" "")
       (s-replace-all '(("&lt;" . "<") ("&gt;" . ">")
                        ("&amp;" . "&") ("\r" . "")))))

(defun eopengrok--text-highlight (text line)
  "Highlighting TEXT from LINE."
  (let (beg end)
    (with-temp-buffer
      (insert (propertize line 'read-only nil))
      (goto-char (point-min))
      (while (and (re-search-forward
                   (s-replace "\"" "" text) nil t)
                  (> (- (setq end (match-end 0))
                        (setq beg (match-beginning 0))) 0))
        (add-text-properties beg end '(face eopengrok-highlight-face)))
      (buffer-string))))

(defun eopengrok--handle-mouse (_event)
  "Handle mouse click EVENT."
  (interactive "e")
  (eopengrok-jump-to-source))

(defvar eopengrok-mouse-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] #'eopengrok--handle-mouse)
    map))

(defun eopengrok--line-properties (line-list &optional history)
  "Decorate LINE-LIST with HISTORY."
  (-when-let* (((file info src) line-list)
               (file (propertize file 'face 'eopengrok-file-face))
               (info (propertize info
                                 'face 'eopengrok-info-face
                                 'mouse-face 'highlight
                                 'keymap eopengrok-mouse-map))
               (src (propertize (eopengrok--remove-html-tags src)
                                'face 'eopengrok-source-face))
               (proc (get-process "eopengrok")))
    (eopengrok--properties-region
     (list :page eopengrok-page)
     (progn
       (unless (string= file eopengrok-last-filename)
         (insert (format "\n%s\n" file))
         (eopengrok--abbreviate-file file))
       (eopengrok--properties-region
        (list :name (expand-file-name file)
              :info (if history info (string-to-number info)))
        (insert (concat (format "%08s" info) " "
                        (eopengrok--text-highlight
                         (process-get proc :text)
                         src))))
       (insert "\n")
       (setq eopengrok-last-filename file)))))

(defun eopengrok--insert-line (line)
  "Insert matching any regex in LINE."
  (cond
   ((string-match eopengrok-history-regexp line)
    (eopengrok--line-properties
     (mapcar (lambda (n) (match-string n line)) '(1 2 3)) t))
   ((string-match eopengrok-source-regexp line)
    (eopengrok--line-properties
     (mapcar (lambda (n) (match-string n line)) '(1 2 3))))
   ((string-match eopengrok-page-separator-regexp line)
    (setq eopengrok-mode-line-status 'running
          eopengrok-page (format "%s/%s" (match-string 1 line)
                                 (match-string 2 line))))
   (t (insert line "\n"))))

(defun eopengrok--process-filter (process output)
  "Process eopengrok output from PROCESS containted in OUTPUT."
  (with-current-buffer (process-buffer process)
    (let ((buffer-read-only nil)
          (pos 0)
          (output (concat eopengrok-pending-output output)))
      (save-excursion
        (while (string-match "\n" output pos)
          (let ((line (substring output pos (match-beginning 0))))
            (setq pos (match-end 0))
            (goto-char (point-max))
            ;;(insert line "\n")
            (eopengrok--insert-line line))))
      (setq eopengrok-pending-output (substring output pos)))))

(defun eopengrok--process-sentinel (process event)
  "Handle eopengrok PROCESS EVENT."
  (let ((buf (process-buffer process)))
    (with-current-buffer buf
      (cond ((string= "killed\n" event)
             (kill-buffer buf))
            ((string= "finished\n" event)
             (setq eopengrok-mode-line-status 'finished))
            (t nil)))))

(defun eopengrok--current-info (process dir &optional search text ep)
  "Display current information (PROCESS DIR SEARCH TEXT EP)."
  (let ((buf (process-buffer process)))
    (with-current-buffer buf
      (let ((buffer-read-only nil))
        (erase-buffer)
        (if search
            (insert text)
          (insert (concat "Creating the index" (and ep " (enable projects)"))))
        (insert (format "\nDirectory: %s\n" dir))
        (forward-line -2))
      (setq truncate-lines t)
      (setq buffer-read-only t)
      (pop-to-buffer buf))))

(defun eopengrok--init ()
  "Initialize variable."
  (setq eopengrok-last-filename nil
        eopengrok-pending-output nil
        eopengrok-page nil
        eopengrok-mode-line-status 'not-running))

(defmacro eopengrok-define-find (sym option)
  "Make function with SYM and OPTION."
  (let ((fun (intern (format "eopengrok-find-%s" sym)))
        (doc (format "Find option %s" option))
        (str (format "Find %s: " sym)))
    `(defun ,fun (text) ,doc
            (interactive (list (read-string ,str (thing-at-point 'symbol))))
            (let ((proc (get-process "eopengrok")))
              (when proc
                (kill-process proc)
                (sleep-for 0.1)))
            (let* ((conf (eopengrok--get-configuration))
                   (proc (apply 'start-process
                                "eopengrok"
                                eopengrok-buffer
                                "clj-opengrok"
                                (eopengrok--search-option conf text
                                                          ,option ',sym))))
              (set-process-query-on-exit-flag proc nil)
              (set-process-filter proc 'eopengrok--process-filter)
              (set-process-sentinel proc 'eopengrok--process-sentinel)
              (process-put proc :text text)
              (with-current-buffer eopengrok-buffer
                (eopengrok-mode t)
                (eopengrok--init)
                (eopengrok--current-info
                 proc (s-chop-suffix eopengrok-configuration conf)
                 t (concat ,str text)))))))

(eopengrok-define-find definition "-d")
(eopengrok-define-find file "-p")
(eopengrok-define-find reference "-r")
(eopengrok-define-find text "-f")
(eopengrok-define-find history "-h")
(eopengrok-define-find custom "")

(defun eopengrok-create-index (dir &optional enable-projects-p)
  "Create an Index file in DIR, ENABLE-PROJECTS-P is flag for enable projects.
If not nil every directory in DIR is considered a separate project."
  (interactive "DRoot directory: ")
  (let ((proc (apply 'start-process
                     "eopengrok-indexer"
                     eopengrok-indexing-buffer
                     "clj-opengrok"
                     (append (list "index" "-s" (expand-file-name dir))
                             (list "-i" eopengrok-ignore-file-or-directory)
                             (when enable-projects-p '("-e"))))))
    (set-process-filter proc 'eopengrok--process-filter)
    (set-process-sentinel proc 'eopengrok--process-sentinel)
    (with-current-buffer eopengrok-indexing-buffer
      (eopengrok-mode t)
      (eopengrok--init)
      (eopengrok--current-info proc (expand-file-name dir)
                               nil nil enable-projects-p)
      (setq eopengrok-mode-line-status 'running))))

(defun eopengrok-create-index-with-enable-projects (dir)
  "Create an Index file, every directory in DIR is considered a separate project."
  (interactive "DRoot directory (enable projects): ")
  (eopengrok-create-index dir t))

(defvar eopengrok-mode-map nil
  "Keymap for eopengrok minor mode.")

(unless eopengrok-mode-map
  (setq eopengrok-mode-map (make-sparse-keymap)))

(--each '(("n"        . eopengrok-next-line)
          ("p"        . eopengrok-previous-line)
          ("q"        . eopengrok-quit)
          ("RET"      . eopengrok-jump-to-source))
  (define-key eopengrok-mode-map (read-kbd-macro (car it)) (cdr it)))

(defun eopengrok--mode-line-page ()
  "Return the string of page number."
  (let ((page (or (get-text-property (point) :page)
                  eopengrok-page))
        (status (pcase eopengrok-mode-line-status
                  (`running "*:") (`finished ":") (`not-running ""))))
    (concat " " eopengrok-mode-line-prefix status page)))

(define-minor-mode eopengrok-mode
  "Minor mode for opengrok."
  :keymap eopengrok-mode-map
  :lighter eopengrok-mode-line)

(provide 'eopengrok)

;;; eopengrok.el ends here
