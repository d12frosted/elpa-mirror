;;; helm-codesearch.el --- helm interface for codesearch -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Youngjoo Lee

;; Author: Youngjoo Lee <youngker@gmail.com>
;; Version: 0.5.0
;; Package-Version: 20190412.1153
;; Package-Commit: 72f1d1de746115ab7e861178b49fa3c0b6b58d90
;; Keywords: tools
;; Package-Requires: ((emacs "25.1") (s "1.11.0") (dash "2.12.0") (helm "1.7.7") (cl-lib "0.5"))

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

;; helm interface for codesearch
;;
;; See documentation on https://github.com/youngker/helm-codesearch.el

;;; Code:
(require 's)
(require 'dash)
(require 'helm)
(require 'helm-grep)
(require 'helm-files)
(require 'cl-lib)
(require 'xref)

(defgroup helm-codesearch nil
  "Helm interface for codesearch."
  :prefix "helm-codesearch-"
  :group 'helm)

(defface helm-codesearch-file-face
  '((t :inherit font-lock-function-name-face))
  "Face for file."
  :group 'helm-codesearch)

(defface helm-codesearch-lineno-face
  '((t :inherit font-lock-constant-face))
  "Face for lineno."
  :group 'helm-codesearch)

(defface helm-codesearch-source-face
  '((t :inherit font-lock-doc-face))
  "Face for source."
  :group 'helm-codesearch)

(defcustom helm-codesearch-csearchindex ".csearchindex"
  "Index file for each projects."
  :type 'string
  :group 'helm-codesearch)

(defcustom helm-codesearch-global-csearchindex nil
  "The global csearchindex file."
  :type 'boolean
  :group 'helm-codesearch)

(defcustom helm-codesearch-ignore-case nil
  "Ignore case distinctions in both the PATTERN and the input files."
  :type 'boolean
  :group 'helm-codesearch)

(defcustom helm-codesearch-abbreviate-filename 80
  "Abbreviate filename length."
  :type 'number
  :group 'helm-codesearch)

(defcustom helm-codesearch-action
  '(("Find file" . helm-grep-action)
    ("Find file other frame" . helm-grep-other-frame)
    ("Find file other window" . helm-grep-other-window)
    ("Change filename filter" . helm-codesearch-set-filename)
    ("Save results in other buffer" . helm-codesearch-run-save-result))
  "Actions for helm-codesearch."
  :group 'helm-codesearch
  :type '(alist :key-type string :value-type function))

(defcustom helm-codesearch-overwrite-search-result nil
  "Overwrite search result buffer without asking confirmation."
  :type 'boolean
  :group 'helm-codesearch)

(defvar helm-codesearch-buffer "*helm codesearch*")
(defvar helm-codesearch-indexing-buffer "*helm codesearch indexing*")
(defvar helm-codesearch-file nil)
(defvar helm-codesearch-process nil)
(defvar helm-codesearch--file-pattern nil)

(defun helm-codesearch-set-filename (_candidate)
  "Setting the filename."
  (setq helm-codesearch--file-pattern
        (helm-read-string "File Pattern: " helm-codesearch--file-pattern))
  (helm-resume helm-codesearch-buffer))

(defun helm-codesearch-run-set-filename ()
  "Run Setting the filename."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-codesearch-set-filename)))
(put 'helm-codesearch-run-set-filename 'helm-only t)

(defun helm-codesearch-run-ignore-case ()
  "Run Toggle ignore case."
  (interactive)
  (setq helm-codesearch-ignore-case (not helm-codesearch-ignore-case))
  (run-with-idle-timer 0.1 nil (lambda ()
                                 (with-helm-buffer
                                   (helm-force-update)
                                   (sit-for 1)))))

(defun helm-codesearch-run-save-result (candidate)
  "Run helm-codesearch save results with CANDIDATE."
  (helm-codesearch-save-buffer candidate))

(defun helm-codesearch-run-save-buffer ()
  "Run helm-codesearch save results action."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-codesearch-run-save-result)))
(put 'helm-codesearch-run-save-buffer 'helm-only t)

(defvar helm-codesearch-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-c f") 'helm-codesearch-run-set-filename)
    (define-key map (kbd "C-c h") 'helm-minibuffer-history)
    (define-key map (kbd "C-c i") 'helm-codesearch-run-ignore-case)
    (define-key map (kbd "C-c s") 'helm-codesearch-run-save-buffer)
    map))

(defvar helm-codesearch-source-pattern
  (helm-build-async-source "Codesearch: Find pattern"
    :header-name #'helm-codesearch-header-name
    :init #'helm-codesearch-init
    :cleanup #'helm-codesearch-cleanup
    :resume #'helm-codesearch-resume
    :candidates-process #'helm-codesearch-find-pattern-process
    :filtered-candidate-transformer #'helm-codesearch-find-pattern-transformer
    :keymap helm-codesearch-map
    :action 'helm-codesearch-action
    :persistent-action 'helm-grep-persistent-action
    :help-message 'helm-grep-help-message
    :candidate-number-limit 99999
    :nohighlight t
    :requires-pattern 3))

(defvar helm-codesearch-source-file
  (helm-build-async-source "Codesearch: Find file"
    :header-name #'helm-codesearch-header-name
    :init #'helm-codesearch-init
    :cleanup #'helm-codesearch-cleanup
    :candidates-process #'helm-codesearch-find-file-process
    :filtered-candidate-transformer #'helm-codesearch-find-file-transformer
    :keymap helm-codesearch-map
    :action 'helm-type-file-actions
    :candidate-number-limit 99999
    :nohighlight t
    :requires-pattern 3))

(defun helm-codesearch-header-name (name)
  "Display Header NAME."
  (concat name " [" (getenv "CSEARCHINDEX") "]"))

(defun helm-codesearch-search-single-csearchindex ()
  "Search for single project index file."
  (let* ((start-dir (expand-file-name default-directory))
         (index-dir (locate-dominating-file start-dir
                                            helm-codesearch-csearchindex)))
    (if index-dir
        (concat index-dir helm-codesearch-csearchindex)
      (error "Can't find csearchindex"))))

(defun helm-codesearch-search-csearchindex ()
  "Search for project index file."
  (setenv "CSEARCHINDEX"
          (expand-file-name (or helm-codesearch-global-csearchindex
                                (helm-codesearch-search-single-csearchindex)))))

(defun helm-codesearch-abbreviate-file (file)
  "FILE."
  (with-temp-buffer
    (insert file)
    (let* ((start (- (point) (length file)))
           (end (point))
           (amount (if (numberp helm-codesearch-abbreviate-filename)
                       (- (- end start) helm-codesearch-abbreviate-filename)
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
      (goto-char end))
    (buffer-substring (point-min) (point-max))))

(defconst helm-codesearch-pattern-regexp
  "^\\([[:lower:][:upper:]]?:?.*?\\):\\([0-9]+\\):\\(.*\\)")

(defvar helm-codesearch-line-overlay nil)

(defun helm-codesearch-highlight-current-line ()
  "Make overlay in current line."
  (let ((s (line-beginning-position))
        (e (1+ (line-end-position))))
    (if helm-codesearch-line-overlay
        (move-overlay helm-codesearch-line-overlay s e (current-buffer))
      (setq helm-codesearch-line-overlay (make-overlay s e)))
    (overlay-put helm-codesearch-line-overlay 'face 'helm-selection-line)
    (recenter)))

(defun helm-codesearch-open-file ()
  "Open with `find-file-other-window'."
  (-when-let ((_ file lineno source)
              (s-match helm-codesearch-pattern-regexp
                       (get-text-property (point) 'helm-realvalue)))
    (find-file-other-window file)
    (goto-char (point-min))
    (forward-line (1- (string-to-number lineno)))
    (helm-codesearch-highlight-current-line)))

(defun helm-codesearch-jump-to-source ()
  "Jump point to the other window."
  (interactive)
  (helm-codesearch-open-file)
  (delete-overlay helm-codesearch-line-overlay)
  (xref-push-marker-stack (point-marker)))

(defun helm-codesearch-move-line (pfn lfn)
  "Move point with PFN and LFN."
  (with-current-buffer (current-buffer)
    (-when-let (pos (funcall pfn (save-excursion
                                   (funcall lfn) (point)) 'lineno))
      (goto-char pos)
      (beginning-of-line)
      (save-selected-window
        (helm-codesearch-open-file)))))

(defun helm-codesearch-next-line ()
  "Move point to the next search result, if one exists."
  (interactive)
  (helm-codesearch-move-line #'next-single-property-change
                             #'end-of-line))

(defun helm-codesearch-previous-line ()
  "Move point to the previous search result, if one exists."
  (interactive)
  (helm-codesearch-move-line #'previous-single-property-change
                             #'beginning-of-line))

(defun helm-codesearch-quit-window ()
  "Quit helm-codesearch window."
  (interactive)
  (delete-overlay helm-codesearch-line-overlay)
  (quit-window))

(defun helm-codesearch-save-buffer (_candidate)
  "Save buffer."
  (let ((buf "*helm codesearch results*")
        new-buf
        (pattern (with-helm-buffer helm-input-local))
        (src-name (assoc-default 'name (helm-get-current-source))))
    (when (and (get-buffer buf)
               (not helm-codesearch-overwrite-search-result))
      (setq new-buf (helm-read-string "GrepBufferName: " buf))
      (cl-loop for b in (helm-buffer-list)
               when (and (string= new-buf b)
                         (not (y-or-n-p
                               (format "Buffer `%s' already exists overwrite? "
                                       new-buf))))
               do (setq new-buf (helm-read-string "GrepBufferName: " "*helm codesearch results ")))
      (setq buf new-buf))
    (with-current-buffer (get-buffer-create buf)
      (setq default-directory (or helm-ff-default-directory
                                  (helm-default-directory)
                                  default-directory))
      (setq buffer-read-only t)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "-*- mode: helm-codesearch -*-\n\n"
                (format "%s Results for `%s':\n" src-name pattern))
        (save-excursion
          (insert (with-current-buffer helm-buffer
                    (goto-char (point-min)) (forward-line 1)
                    (buffer-substring (point) (point-max))))))
      (local-set-key (kbd "RET") 'helm-codesearch-jump-to-source)
      (local-set-key (kbd "n") 'helm-codesearch-next-line)
      (local-set-key (kbd "p") 'helm-codesearch-previous-line)
      (local-set-key (kbd "q") 'helm-codesearch-quit-window))
    (pop-to-buffer buf)
    (message "Helm %s Results saved in `%s' buffer" src-name buf)))

(defun helm-codesearch-handle-mouse (_event)
  "Handle mouse click EVENT."
  (interactive "e")
  (helm-codesearch-jump-to-source))

(defvar helm-codesearch-mouse-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] #'helm-codesearch-handle-mouse)
    map))

(defun helm-codesearch-make-pattern-format (candidate)
  "Make pattern format from CANDIDATE."
  (-when-let* (((_ file lineno source)
                (s-match helm-codesearch-pattern-regexp candidate))
               (file (propertize file 'face 'helm-codesearch-file-face))
               (lineno (propertize lineno
                                   'lineno t
                                   'face 'helm-codesearch-lineno-face
                                   'mouse-face 'highlight
                                   'local-map helm-codesearch-mouse-map))
               (source (helm-grep-highlight-match
                        (propertize source 'face 'helm-codesearch-source-face) t))
               (display-line (format "%08s %s" lineno source))
               (abbrev-file (format "\n%s" (helm-codesearch-abbreviate-file file)))
               (fake-file (propertize abbrev-file 'helm-candidate-separator t)))
    (if (string= file helm-codesearch-file)
        (list (cons display-line candidate))
      (progn
        (setq helm-codesearch-file file)
        (list (cons (format "%s\n%s" fake-file display-line) candidate))))))

(defun helm-codesearch-find-pattern-transformer (candidates _source)
  "Transformer is run on the CANDIDATES and not use the SOURCE."
  (-mapcat 'helm-codesearch-make-pattern-format candidates))

(defun helm-codesearch-make-file-format (candidate)
  "Make file format from CANDIDATE."
  (-when-let* ((file-p (and (file-exists-p candidate) (> (length candidate) 0)))
               (file (propertize candidate 'face 'helm-codesearch-file-face))
               (lineno (propertize "1" 'face 'helm-codesearch-lineno-face))
               (source (propertize "..." 'face 'helm-codesearch-source-face))
               (display-line (format "%08s %s" lineno source))
               (abbrev-file (format "\n%s" (helm-codesearch-abbreviate-file file)))
               (fake-file (propertize abbrev-file 'helm-candidate-separator t)))
    (list (cons (format "%s\n%s" fake-file display-line) candidate))))

(defun helm-codesearch-find-file-transformer (candidates _source)
  "Transformer is run on the CANDIDATES and not use the SOURCE."
  (-mapcat 'helm-codesearch-make-file-format candidates))

(defun helm-codesearch-show-candidate-number (&optional _name)
  "Used to display candidate number in mode-line, not used NAME."
  (let* ((source (cdr (assoc helm-codesearch-process helm-async-processes)))
         (match-num (cdr (assoc 'item-count source))))
    (propertize
     (format "[%s%s%s]"
             (if (and match-num (> match-num 0)) match-num "No match found")
             (if helm-codesearch-ignore-case "(?i)"
               (if helm-codesearch--file-pattern " " ""))
             (or helm-codesearch--file-pattern ""))
     'face 'helm-candidate-number)))

;; from helm-ag
(defun helm-codesearch-elisp-regexp-to-pcre (regexp)
  "Change elisp REGEXP to pcre."
  (with-temp-buffer
    (insert regexp)
    (goto-char (point-min))
    (while (re-search-forward "[(){}|]" nil t)
      (backward-char 1)
      (cond ((looking-back "\\\\\\\\" nil))
            ((looking-back "\\\\" nil)
             (delete-char -1))
            (t
             (insert "\\")))
      (forward-char 1))
    (buffer-string)))

(defun helm-codesearch-find-pattern-process ()
  "Execute the csearch for a pattern."
  (let ((proc (apply 'start-process
                     "codesearch"
                     nil
                     "csearch"
                     (helm-codesearch-build-find-pattern-param helm-pattern))))
    (setq helm-codesearch-file nil)
    (setq helm-codesearch-process proc)))

(defun helm-codesearch-build-find-pattern-param (text-pattern)
  "Build search pattern from flags and the command input (TEXT-PATTERN).
File scope from the command takes precedence over the one from
'helm-codesearch--file-pattern' which is included only when the user doesn't
specifiy the file scope with -f."
  (let ((has-only-text-pattern (helm-codesearch-has-only-text-pattern text-pattern)))
    (delq nil (append
               (list (and helm-codesearch-ignore-case "-i")
                     (and has-only-text-pattern "-f")
                     (and has-only-text-pattern (or helm-codesearch--file-pattern "")))
               (cons "-n" (helm-codesearch-maybe-split-search-pattern text-pattern))))))

(defun helm-codesearch-has-only-text-pattern (pattern)
  "Return non-nil if PATTERN contain one for text to search only, without file scope."
  (not (and (string= (car (split-string pattern)) "-f"))))

(defun helm-codesearch-maybe-split-search-pattern (text-pattern)
  "Split pattern into one for file scope(if present),the other for TEXT-PATTERN.
'-f java import android' -> '('-f' 'java' 'import android')
'import android' -> '('import android')"
  (let ((tokens (split-string text-pattern)))
    (if (string= (car tokens) "-f")
        (list "-f" (nth 1 tokens) (helm-codesearch-elisp-regexp-to-pcre
                                   (s-join ".*" (nthcdr 2 tokens))))
      (list (helm-codesearch-elisp-regexp-to-pcre (s-join ".*" tokens))))))

(defun helm-codesearch-find-file-process ()
  "Execute the csearch for a file."
  (let* ((pattern (replace-regexp-in-string "\s" ".*" helm-pattern))
         (proc (apply 'start-process
                      "codesearch"
                      nil
                      "csearch"
                      (delq nil (list "-l" "-f"
                                      (if helm-codesearch-ignore-case
                                          (concat "(?i)" pattern)
                                        pattern) "$")))))
    (setq helm-codesearch-process proc)))

(defun helm-codesearch-create-csearchindex-process (dir)
  "Execute the cindex from a DIR."
  (let* ((buf helm-codesearch-indexing-buffer)
         (proc (apply 'start-process "codesearch"
                      buf "cindex" (list dir))))
    (set-process-filter proc
                        (lambda (process output)
                          (with-current-buffer (process-buffer process)
                            (let ((buffer-read-only nil))
                              (insert output)))))
    (set-process-sentinel proc
                          (lambda (process event)
                            (with-current-buffer (process-buffer process)
                              (when (string= event "finished\n")
                                (let ((buffer-read-only nil))
                                  (insert "\nIndexing finished"))))))
    (with-current-buffer buf
      (local-set-key (kbd "q") 'quit-window)
      (let ((buffer-read-only nil))
        (erase-buffer))
      (setq buffer-read-only t)
      (pop-to-buffer buf))))

(defvar helm-codesearch--marker nil
  "Point to previous position.")

(defun helm-codesearch-push-marker ()
  "Push marker to previous position."
  (interactive)
  (xref-push-marker-stack helm-codesearch--marker))

(defun helm-codesearch-update-keymap ()
  "Handle different keymap."
  (helm--maybe-update-keymap helm-codesearch-map))

(defun helm-codesearch-init ()
  "Initialize."
  (advice-add 'helm-show-candidate-number :override
              #'helm-codesearch-show-candidate-number)
  (add-hook 'post-command-hook 'helm-codesearch-update-keymap)
  (setq helm-codesearch--marker (point-marker)))

(defun helm-codesearch-cleanup ()
  "Cleanup Function."
  (advice-remove 'helm-show-candidate-number
                 #'helm-codesearch-show-candidate-number)
  (remove-hook 'post-command-hook 'helm-codesearch-update-keymap)
  (helm-codesearch-push-marker))

(defun helm-codesearch-resume ()
  "Resume."
  (advice-add 'helm-show-candidate-number :override
              #'helm-codesearch-show-candidate-number)
  (add-hook 'post-command-hook 'helm-codesearch-update-keymap)
  (setq helm-codesearch--marker (point-marker))
  (run-with-idle-timer 0.1 nil (lambda ()
                                 (with-helm-buffer
                                   (helm-force-update)
                                   (sit-for 1)))))

;;;###autoload
(defun helm-codesearch-find-pattern ()
  "Find pattern."
  (interactive)
  (let ((symbol (substring-no-properties (or (thing-at-point 'symbol) ""))))
    (helm-codesearch-search-csearchindex)
    (helm :sources 'helm-codesearch-source-pattern
          :buffer helm-codesearch-buffer
          :preselect ""
          :input symbol
          :keymap helm-codesearch-map
          :prompt "Find pattern: "
          :truncate-lines t)))

;;;###autoload
(defun helm-codesearch-find-file ()
  "Find file."
  (interactive)
  (let ((symbol (substring-no-properties (or (thing-at-point 'symbol) ""))))
    (helm-codesearch-search-csearchindex)
    (helm :sources 'helm-codesearch-source-file
          :buffer helm-codesearch-buffer
          :preselect ""
          :input symbol
          :keymap helm-codesearch-map
          :prompt "Find file: "
          :truncate-lines t)))

;;;###autoload
(defun helm-codesearch-create-csearchindex (dir)
  "Create index file at DIR."
  (interactive "DIndex files in directory: ")
  (setenv "CSEARCHINDEX"
          (expand-file-name (or helm-codesearch-global-csearchindex
                                (concat dir helm-codesearch-csearchindex))))
  (helm-codesearch-create-csearchindex-process (expand-file-name dir)))

(provide 'helm-codesearch)
;;; helm-codesearch.el ends here
