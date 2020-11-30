;;; swiper.el --- Isearch with an overview. Oh, man! -*- lexical-binding: t -*-

;; Copyright (C) 2015  Free Software Foundation, Inc.

;; Author: Oleh Krehel <ohwoeowho@gmail.com>
;; URL: https://github.com/abo-abo/swiper
;; Version: 0.7.0
;; Package-Requires: ((emacs "24.1"))
;; Keywords: matching

;; This file is part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package gives an overview of the current regex search
;; candidates.  The search regex can be split into groups with a
;; space.  Each group is highlighted with a different face.
;;
;; It can double as a quick `regex-builder', although only single
;; lines will be matched.
;;
;; It also provides `ivy-mode': a global minor mode that uses the
;; matching back end of `swiper' for all matching on your system,
;; including file matching. You can use it in place of `ido-mode'
;; (can't have both on at once).

;;; Code:
(require 'ivy)

(defgroup swiper nil
  "`isearch' with an overview."
  :group 'matching
  :prefix "swiper-")

(defface swiper-match-face-1
  '((t (:inherit isearch-lazy-highlight-face)))
  "The background face for `swiper' matches.")

(defface swiper-match-face-2
  '((t (:inherit isearch)))
  "Face for `swiper' matches modulo 1.")

(defface swiper-match-face-3
  '((t (:inherit match)))
  "Face for `swiper' matches modulo 2.")

(defface swiper-match-face-4
  '((t (:inherit isearch-fail)))
  "Face for `swiper' matches modulo 3.")

(define-obsolete-face-alias 'swiper-minibuffer-match-face-1
    'ivy-minibuffer-match-face-1 "0.6.0")

(define-obsolete-face-alias 'swiper-minibuffer-match-face-2
    'ivy-minibuffer-match-face-2 "0.6.0")

(define-obsolete-face-alias 'swiper-minibuffer-match-face-3
    'ivy-minibuffer-match-face-3 "0.6.0")

(define-obsolete-face-alias 'swiper-minibuffer-match-face-4
    'ivy-minibuffer-match-face-4 "0.6.0")

(defface swiper-line-face
  '((t (:inherit highlight)))
  "Face for current `swiper' line.")

(defcustom swiper-faces '(swiper-match-face-1
                          swiper-match-face-2
                          swiper-match-face-3
                          swiper-match-face-4)
  "List of `swiper' faces for group matches.")

(defcustom swiper-min-highlight 2
  "Only highlight matches for regexps at least this long."
  :type 'integer)

(defvar swiper-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "M-q") 'swiper-query-replace)
    (define-key map (kbd "C-l") 'swiper-recenter-top-bottom)
    (define-key map (kbd "C-'") 'swiper-avy)
    (define-key map (kbd "C-7") 'swiper-mc)
    (define-key map (kbd "C-c C-f") 'swiper-toggle-face-matching)
    map)
  "Keymap for swiper.")

(defun swiper-query-replace ()
  "Start `query-replace' with string to replace from last search string."
  (interactive)
  (if (null (window-minibuffer-p))
      (user-error "Should only be called in the minibuffer through `swiper-map'")
    (let* ((enable-recursive-minibuffers t)
           (from (ivy--regex ivy-text))
           (to (query-replace-read-to from "Query replace" t)))
      (swiper--cleanup)
      (ivy-exit-with-action
       (lambda (_)
         (with-ivy-window
           (move-beginning-of-line 1)
           (perform-replace from to
                            t t nil)))))))

(defvar avy-background)
(defvar avy-all-windows)
(defvar avy-style)
(defvar avy-keys)
(declare-function avy--regex-candidates "ext:avy")
(declare-function avy--process "ext:avy")
(declare-function avy--overlay-post "ext:avy")
(declare-function avy-action-goto "ext:avy")
(declare-function avy--done "ext:avy")
(declare-function avy--make-backgrounds "ext:avy")
(declare-function avy-window-list "ext:avy")
(declare-function avy-read "ext:avy")
(declare-function avy-read-de-bruijn "ext:avy")
(declare-function avy-tree "ext:avy")
(declare-function avy-push-mark "ext:avy")
(declare-function avy--remove-leading-chars "ext:avy")

;;;###autoload
(defun swiper-avy ()
  "Jump to one of the current swiper candidates."
  (interactive)
  (unless (string= ivy-text "")
    (let* ((avy-all-windows nil)
           (candidates (append
                        (with-ivy-window
                          (avy--regex-candidates
                           (ivy--regex ivy-text)))
                        (save-excursion
                          (save-restriction
                            (narrow-to-region (window-start) (window-end))
                            (goto-char (point-min))
                            (forward-line)
                            (let ((cands))
                              (while (< (point) (point-max))
                                (push (cons (1+ (point))
                                            (selected-window))
                                      cands)
                                (forward-line))
                              cands)))))
           (candidate (unwind-protect
                          (prog2
                              (avy--make-backgrounds
                               (append (avy-window-list)
                                       (list  (ivy-state-window ivy-last))))
                              (if (eq avy-style 'de-bruijn)
                                  (avy-read-de-bruijn
                                   candidates avy-keys)
                                (avy-read (avy-tree candidates avy-keys)
                                          #'avy--overlay-post
                                          #'avy--remove-leading-chars))
                            (avy-push-mark))
                        (avy--done))))
      (if (window-minibuffer-p (cdr candidate))
          (progn
            (ivy-set-index (- (line-number-at-pos (car candidate)) 2))
            (ivy--exhibit)
            (ivy-done)
            (ivy-call))
        (ivy-quit-and-run
         (avy-action-goto (caar candidate)))))))

(declare-function mc/create-fake-cursor-at-point "ext:multiple-cursors-core")
(declare-function multiple-cursors-mode "ext:multiple-cursors-core")

;;;###autoload
(defun swiper-mc ()
  (interactive)
  (unless (require 'multiple-cursors nil t)
    (error "multiple-cursors isn't installed"))
  (let ((cands (nreverse ivy--old-cands)))
    (unless (string= ivy-text "")
      (ivy-exit-with-action
       (lambda (_)
         (let (cand)
           (while (setq cand (pop cands))
             (swiper--action cand)
             (when cands
               (mc/create-fake-cursor-at-point))))
         (multiple-cursors-mode 1))))))

(defun swiper-recenter-top-bottom (&optional arg)
  "Call (`recenter-top-bottom' ARG)."
  (interactive "P")
  (with-ivy-window
    (recenter-top-bottom arg)))

(defun swiper-font-lock-ensure ()
  "Ensure the entired buffer is highlighted."
  (unless (or (derived-mode-p 'magit-mode)
              (bound-and-true-p magit-blame-mode)
              (memq major-mode '(package-menu-mode
                                 gnus-summary-mode
                                 gnus-article-mode
                                 gnus-group-mode
                                 emms-playlist-mode
                                 emms-stream-mode
                                 erc-mode
                                 org-agenda-mode
                                 dired-mode
                                 jabber-chat-mode
                                 elfeed-search-mode
                                 elfeed-show-mode
                                 fundamental-mode
                                 Man-mode
                                 woman-mode
                                 mu4e-view-mode
                                 mu4e-headers-mode
                                 help-mode
                                 debbugs-gnu-mode
                                 occur-mode
                                 occur-edit-mode
                                 bongo-mode
                                 eww-mode
                                 twittering-mode
                                 vc-dir-mode
                                 w3m-mode)))
    (unless (> (buffer-size) 100000)
      (if (fboundp 'font-lock-ensure)
          (font-lock-ensure)
        (with-no-warnings (font-lock-fontify-buffer))))))

(defvar swiper--format-spec ""
  "Store the current candidates format spec.")

(defvar swiper--width nil
  "Store the amount of digits needed for the longest line nubmer.")

(defvar swiper-use-visual-line nil
  "When non-nil, use `line-move' instead of `forward-line'.")

(declare-function outline-show-all "outline")

(defun swiper--candidates (&optional numbers-width)
  "Return a list of this buffer lines.

NUMBERS-WIDTH, when specified, is used for line numbers width
spec, instead of calculating it as the log of the buffer line
count."
  (if (and visual-line-mode
           ;; super-slow otherwise
           (< (buffer-size) 20000))
      (progn
        (when (eq major-mode 'org-mode)
          (require 'outline)
          (if (fboundp 'outline-show-all)
              (outline-show-all)
            (with-no-warnings
              (show-all))))
        (setq swiper-use-visual-line t))
    (setq swiper-use-visual-line nil))
  (let ((n-lines (count-lines (point-min) (point-max))))
    (unless (zerop n-lines)
      (setq swiper--width (or numbers-width
                              (1+ (floor (log n-lines 10)))))
      (setq swiper--format-spec
            (format "%%-%dd " swiper--width))
      (let ((line-number 0)
            (advancer (if swiper-use-visual-line
                          (lambda (arg) (line-move arg t))
                        #'forward-line))
            candidates)
        (save-excursion
          (goto-char (point-min))
          (swiper-font-lock-ensure)
          (while (< (point) (point-max))
            (let ((str (concat
                        " "
                        (replace-regexp-in-string
                         "\t" "    "
                         (if swiper-use-visual-line
                             (buffer-substring
                              (save-excursion
                                (beginning-of-visual-line)
                                (point))
                              (save-excursion
                                (end-of-visual-line)
                                (point)))
                           (buffer-substring
                            (point)
                            (line-end-position)))))))
              (when (eq major-mode 'twittering-mode)
                (remove-text-properties 0 (length str) '(field) str))
              (put-text-property 0 1 'display
                                 (format swiper--format-spec
                                         (cl-incf line-number))
                                 str)
              (push str candidates))
            (funcall advancer 1))
          (nreverse candidates))))))

(defvar swiper--opoint 1
  "The point when `swiper' starts.")

;;;###autoload
(defun swiper (&optional initial-input)
  "`isearch' with an overview.
When non-nil, INITIAL-INPUT is the initial search pattern."
  (interactive)
  (swiper--ivy initial-input))

(declare-function evil-jumper--set-jump "ext:evil-jumper")

(defun swiper--init ()
  "Perform initialization common to both completion methods."
  (setq swiper--opoint (point))
  (when (bound-and-true-p evil-jumper-mode)
    (evil-jumper--set-jump)))

(defun swiper--re-builder (str)
  "Transform STR into a swiper regex.
This is the regex used in the minibuffer, since the candidates
there have line numbers. In the buffer, `ivy--regex' should be used."
  (cond
    ((equal str "")
     "")
    ((equal str "^")
     (setq ivy--subexps 0)
     ".")
    ((string-match "^\\^" str)
     (setq ivy--old-re "")
     (let ((re (ivy--regex-plus (substring str 1))))
       (if (zerop ivy--subexps)
           (prog1 (format "^ ?\\(%s\\)" re)
             (setq ivy--subexps 1))
         (format "^ %s" re))))
    (t
     (ivy--regex-plus str))))

(defvar swiper-history nil
  "History for `swiper'.")

(defvar swiper-invocation-face nil
  "The face at the point of invocation of `swiper'.")

(defun swiper--ivy (&optional initial-input)
  "`isearch' with an overview using `ivy'.
When non-nil, INITIAL-INPUT is the initial search pattern."
  (interactive)
  (swiper--init)
  (setq swiper-invocation-face
        (plist-get (text-properties-at (point)) 'face))
  (let ((candidates (swiper--candidates))
        (preselect
         (if swiper-use-visual-line
             (count-screen-lines
              (point-min)
              (save-excursion (beginning-of-visual-line) (point)))
           (1- (line-number-at-pos))))
        (minibuffer-allow-text-properties t)
        res)
    (unwind-protect
         (setq res
               (ivy-read
                "Swiper: "
                candidates
                :initial-input initial-input
                :keymap swiper-map
                :preselect preselect
                :require-match t
                :update-fn #'swiper--update-input-ivy
                :unwind #'swiper--cleanup
                :action #'swiper--action
                :re-builder #'swiper--re-builder
                :history 'swiper-history
                :caller 'swiper))
      (unless res
        (goto-char swiper--opoint)))))

(defun swiper-toggle-face-matching ()
  "Toggle matching only the candidates with `swiper-invocation-face'."
  (interactive)
  (setf (ivy-state-matcher ivy-last)
        (if (ivy-state-matcher ivy-last)
            nil
          #'swiper--face-matcher))
  (setq ivy--old-re nil))

(defun swiper--face-matcher (regexp candidates)
  "Return REGEXP-matching CANDIDATES.
Matched candidates should have `swiper-invocation-face'."
  (cl-remove-if-not
   (lambda (x)
     (and
      (string-match regexp x)
      (let ((s (match-string 0 x))
            (i 0))
        (while (and (< i (length s))
                    (text-property-any
                     i (1+ i)
                     'face swiper-invocation-face
                     s))
          (cl-incf i))
        (eq i (length s)))))
   candidates))

(defun swiper--ensure-visible ()
  "Remove overlays hiding point."
  (let ((overlays (overlays-at (point)))
        ov expose)
    (while (setq ov (pop overlays))
      (if (and (invisible-p (overlay-get ov 'invisible))
               (setq expose (overlay-get ov 'isearch-open-invisible)))
          (funcall expose ov)))))

(defvar swiper--overlays nil
  "Store overlays.")

(defun swiper--cleanup ()
  "Clean up the overlays."
  (while swiper--overlays
    (delete-overlay (pop swiper--overlays)))
  (save-excursion
    (goto-char (point-min))
    (isearch-clean-overlays)))

(defun swiper--update-input-ivy ()
  "Called when `ivy' input is updated."
  (with-ivy-window
    (swiper--cleanup)
    (when (> (length ivy--current) 0)
      (let* ((re (funcall ivy--regex-function ivy-text))
             (re (if (stringp re) re (caar re)))
             (str (get-text-property 0 'display ivy--current))
             (num (if (string-match "^[0-9]+" str)
                      (string-to-number (match-string 0 str))
                    0)))
        (unless (eq this-command 'ivy-yank-word)
          (goto-char (point-min))
          (when (cl-plusp num)
            (goto-char (point-min))
            (if swiper-use-visual-line
                (line-move (1- num))
              (forward-line (1- num)))
            (if (and (equal ivy-text "")
                     (>= swiper--opoint (line-beginning-position))
                     (<= swiper--opoint (line-end-position)))
                (goto-char swiper--opoint)
              (re-search-forward re (line-end-position) t))
            (isearch-range-invisible (line-beginning-position)
                                     (line-end-position))
            (unless (and (>= (point) (window-start))
                         (<= (point) (window-end (ivy-state-window ivy-last) t)))
              (recenter))))
        (swiper--add-overlays re)))))

(defun swiper--add-overlays (re &optional beg end wnd)
  "Add overlays for RE regexp in visible part of the current buffer.
BEG and END, when specified, are the point bounds.
WND, when specified is the window."
  (setq wnd (or wnd (ivy-state-window ivy-last)))
  (let ((ov (if visual-line-mode
                (make-overlay
                 (save-excursion
                   (beginning-of-visual-line)
                   (point))
                 (save-excursion
                   (end-of-visual-line)
                   (point)))
              (make-overlay
               (line-beginning-position)
               (1+ (line-end-position))))))
    (overlay-put ov 'face 'swiper-line-face)
    (overlay-put ov 'window wnd)
    (push ov swiper--overlays)
    (let* ((wh (window-height))
           (beg (or beg (save-excursion
                          (forward-line (- wh))
                          (point))))
           (end (or end (save-excursion
                          (forward-line wh)
                          (point)))))
      (when (>= (length re) swiper-min-highlight)
        (save-excursion
          (goto-char beg)
          ;; RE can become an invalid regexp
          (while (and (ignore-errors (re-search-forward re end t))
                      (> (- (match-end 0) (match-beginning 0)) 0))
            (let ((i 0))
              (while (<= i ivy--subexps)
                (when (match-beginning i)
                  (let ((overlay (make-overlay (match-beginning i)
                                               (match-end i)))
                        (face
                         (cond ((zerop ivy--subexps)
                                (cadr swiper-faces))
                               ((zerop i)
                                (car swiper-faces))
                               (t
                                (nth (1+ (mod (+ i 2) (1- (length swiper-faces))))
                                     swiper-faces)))))
                    (push overlay swiper--overlays)
                    (overlay-put overlay 'face face)
                    (overlay-put overlay 'window wnd)
                    (overlay-put overlay 'priority i)))
                (cl-incf i)))))))))

(defun swiper--action (x)
  "Goto line X."
  (if (null x)
      (user-error "No candidates")
    (with-ivy-window
      (unless (equal (current-buffer)
                     (ivy-state-buffer ivy-last))
        (switch-to-buffer (ivy-state-buffer ivy-last)))
      (goto-char (point-min))
      (funcall (if swiper-use-visual-line
                   #'line-move
                 #'forward-line)
               (1- (read (get-text-property 0 'display x))))
      (re-search-forward
       (ivy--regex ivy-text) (line-end-position) t)
      (swiper--ensure-visible)
      (when (/= (point) swiper--opoint)
        (unless (and transient-mark-mode mark-active)
          (when (eq ivy-exit 'done)
            (push-mark swiper--opoint t)
            (message "Mark saved where search started")))))))

;; (define-key isearch-mode-map (kbd "C-o") 'swiper-from-isearch)
(defun swiper-from-isearch ()
  "Invoke `swiper' from isearch."
  (interactive)
  (let ((query (if isearch-regexp
                   isearch-string
                 (regexp-quote isearch-string))))
    (isearch-exit)
    (swiper query)))

(defvar swiper-multi-buffers nil
  "Store the current list of buffers.")

(defvar swiper-multi-candidates nil
  "Store the list of candidates for `swiper-multi'.")

(defun swiper-multi-prompt ()
  (format "Buffers (%s): "
          (mapconcat #'identity swiper-multi-buffers ", ")))

(defun swiper-multi ()
  "Select one or more buffers.
Run `swiper' for those buffers."
  (interactive)
  (setq swiper-multi-buffers nil)
  (ivy-read (swiper-multi-prompt)
            'internal-complete-buffer
            :action 'swiper-multi-action-1)
  (ivy-read "Swiper: " swiper-multi-candidates
            :action 'swiper-multi-action-2
            :unwind #'swiper--cleanup
            :caller 'swiper-multi))

(defun swiper-all ()
  "Run `swiper' for all opened buffers."
  (interactive)
  (ivy-read "Swiper: " (swiper--multi-candidates
                        (cl-remove-if-not
                         #'buffer-file-name
                         (buffer-list)))
            :action 'swiper-multi-action-2
            :unwind #'swiper--cleanup
            :caller 'swiper-multi))

(defun swiper--multi-candidates (buffers)
  (let* ((ww (window-width))
         (res nil)
         (column-2 (apply #'max
                          (mapcar
                           (lambda (b)
                             (length (buffer-name b)))
                           buffers)))
         (column-1 (- ww 4 column-2 1)))
    (dolist (buf buffers)
      (with-current-buffer buf
        (setq res
              (append
               (mapcar
                (lambda (s)
                  (setq s (concat (ivy--truncate-string s column-1) " "))
                  (let ((len (length s)))
                    (put-text-property
                     (1- len) len 'display
                     (concat
                      (make-string
                       (- ww (string-width s) (length (buffer-name)) 3)
                       ?\ )
                      (buffer-name))
                     s)
                    s))
                (swiper--candidates 4))
               res))
        nil))
    res))

(defun swiper-multi-action-1 (x)
  (if (member x swiper-multi-buffers)
      (progn
        (setq swiper-multi-buffers (delete x swiper-multi-buffers)))
    (unless (equal x "")
      (setq swiper-multi-buffers (append swiper-multi-buffers (list x)))))
  (let ((prompt (swiper-multi-prompt)))
    (setf (ivy-state-prompt ivy-last) prompt)
    (setq ivy--prompt (concat "%-4d " prompt)))
  (cond ((memq this-command '(ivy-done
                              ivy-alt-done
                              ivy-immediate-done))
         (setq swiper-multi-candidates
               (swiper--multi-candidates
                (mapcar #'get-buffer swiper-multi-buffers))))
        ((eq this-command 'ivy-call)
         (delete-minibuffer-contents))))

(defun swiper-multi-action-2 (x)
  (let ((buf-space (get-text-property (1- (length x)) 'display x)))
    (with-ivy-window
      (when (string-match "\\` *\\([^ ]+\\)\\'" buf-space)
        (switch-to-buffer (match-string 1 buf-space))
        (goto-char (point-min))
        (forward-line (1- (read (get-text-property 0 'display x))))
        (re-search-forward
         (ivy--regex ivy-text)
         (line-end-position) t)
        (unless (eq ivy-exit 'done)
          (swiper--cleanup)
          (swiper--add-overlays (ivy--regex ivy-text)))))))

;;;; ChangeLog:

;; 2020-11-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Rename swiper -> ivy
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/ivy.org: Add "Variable Index" node
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/ivy.texi: Re-export using adjusted texinfo exporter
;; 
;; 	* doc/ivy.org: Add defopt/endopt macros. Change `ivy-wrap' and
;; 	 `ivy-height' to defopt.
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Bump version to 0.7.0
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/Changelog.org: Update up to 706349f
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completing-read): Use completing-read-default for tmm
;; 
;; 	Fixes #316
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-tmm): New command
;; 
;; 	* counsel.el (counsel-tmm-prompt): New defun.
;; 	(tmm-km-list): Define this variable here, since `tmm-get-keymap' 
;; 	modifies a global variable (yuck!).
;; 
;; 	Re #316
;; 
;; 2015-12-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Add vc-dir-mode
;; 
;; 	Re #19
;; 
;; 2015-12-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use :caller for ivy-re-builders-alist
;; 
;; 	* counsel.el (counsel-M-x): Add :caller.
;; 
;; 	* ivy.el (ivy--reset-state): Use :caller.
;; 
;; 2015-12-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--update-input-ivy): Add a work-around for "M-j"
;; 
;; 	When `ivy-yank-word' is called, don't move to the line of the current 
;; 	candidate. We're already there anyway. And not moving helps when there 
;; 	are multiple occurrences of the current input on the current line.
;; 
;; 	Fixes #314
;; 
;; 2015-12-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Structure all faces into ivy-faces custom group
;; 
;; 2015-11-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix due to visual-line-mode weirdness
;; 
;; 	* swiper.el (swiper--candidates): Under a specific random condition,
;; 	(line-move 1) from the beginning of line doesn't move to the beginning 
;; 	of the next visual line.
;; 
;; 	This change fixes it, but will result in an even slower startup when
;; 	`visual-line-mode' is active.
;; 
;; 	Fixes #313
;; 
;; 2015-11-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Use show-all if outline-show-all isn't there
;; 
;; 	Fixes #312
;; 
;; 2015-11-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix ivy-resume issue caused by the recursive calls change
;; 
;; 	* ivy.el (ivy-read): recursive-ivy-last is only set if there's an active
;; 	 minibuffer window. If this check isn't made, it causes the previous
;; 	 `ivy-last' to be reset after the current one, so `ivy-resume' would
;; 	 resume not the last command.
;; 
;; 2015-11-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the preselect for (swiper "one") again
;; 
;; 	* ivy.el (ivy--reset-state): Take into account :preselect being integer. 
;; 	This means that it's void once the candidates are filtered over
;; 	:initial-input.
;; 
;; 	Fixes #292
;; 
;; 2015-11-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the issue caused by recursive swiper calls
;; 
;; 	* swiper.el (swiper--ivy): Look at the return result of `ivy-read'; 
;; 	looking at `ivy-exit' no longer works.
;; 
;; 	Fixes #311
;; 
;; 2015-11-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Remove 'field text property for twittering-mode
;; 
;; 	* swiper.el (swiper--candidates): Update.
;; 	(swiper-font-lock-ensure): Add `twittering-mode'.
;; 
;; 	Fixes #310
;; 
;; 2015-11-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Enable recursive swiper calls
;; 
;; 	* ivy.el (ivy-read): Don't need to be in the minibuffer to do a
;; 	 recursive store/restore.
;; 
;; 	(ivy--reset-state): Avoid nil string while testing.
;; 
;; 	Fixes #309
;; 
;; 2015-11-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/Changelog.org: Update up to 2bec99d
;; 
;; 2015-11-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixes on the previous docstring edits
;; 
;; 2015-11-27  sjLambda  <sjLambda@gmail.com>
;; 
;; 	Edit documentation strings in ivy.el
;; 
;; 	Fixes #308
;; 
;; 2015-11-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Ease production of functions like ivy-format-function-default
;; 
;; 	* ivy.el (ivy--format-function-generic): New defun.
;; 	(ivy-format-function-default):
;; 	(ivy-format-function-arrow):
;; 	(ivy-format-function-line): Use `ivy--format-function-generic'.
;; 
;; 	* counsel.el (counsel--M-x-transformer): Add an extra space to simplify
;; 	 the logic.
;; 
;; 	Re #307
;; 
;; 2015-11-26  Stephen Whipple  <shw@wicdmedia.org>
;; 
;; 	Convert ivy formatting functions to dotted pairs.
;; 
;; 	`ivy-format-function' now expects to operate on dotted pairs 
;; 	representing (stub . extra), where `stub' is the original candidate and
;; 	`extra' is any extra information that has been added by counsel or other
;; 	libraries.
;; 
;; 	The format function can differentiate between the original stub and
;; 	extra information and choose how to display the result to the user.
;; 
;; 2015-11-25  Stephen Whipple  <shw@wicdmedia.org>
;; 
;; 	Update ivy format functions.
;; 
;; 	`ivy-format-function' now accessible via Customize system.
;; 
;; 	`ivy-format-function-default' and `ivy-format-function-arrow' 
;; 	simplified.
;; 
;; 	New format `ivy-format-function-line' added.
;; 
;; 	`counsel-M-x' restores `ivy-format-function' before executing command.
;; 
;; 	Fixes #306
;; 
;; 2015-11-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add counsel-grep
;; 
;; 	* ivy.el (ivy--reset-state): Don't push preselect onto collection for
;; 	 :dynamic-collection.
;; 	(ivy-recompute-index-swiper-async): New defun. It's useful for 
;; 	re-anchoring on collections produced async processes. The major 
;; 	difference from `ivy-recompute-index-swiper' is using `equal' instead of
;; 	`eq'.
;; 
;; 	* counsel.el (counsel--async-sentinel): Add index recomputing logic. 
;; 	When `ivy--old-cands' are null, recompute the index according to
;; 	:preselect, otherwise try `ivy--recompute-index'.
;; 	(counsel-grep): New command. Very similar to `swiper', except calls an 
;; 	external process for each key update. Should be much faster for very 
;; 	large files, both for startup and for matching. For smaller files, it's 
;; 	less convenient.
;; 	(counsel-grep-function): New defun.
;; 	(counsel-grep-action): New defun.
;; 
;; 	Fixes #299
;; 
;; 2015-11-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Ivy-resume should restore the buffer for swiper
;; 
;; 	* ivy.el (ivy-resume): Update.
;; 
;; 	Fixes #302
;; 
;; 2015-11-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix broken candidate index in ivy-resume
;; 
;; 	* ivy.el (ivy--reset-state): When given initial-input, call
;; 	 `ivy--preselect-index' on candidates filtered by initial-input. This
;; 	 is important for `ivy-resume'.
;; 
;; 2015-11-24  Samuel Loury  <konubinixweb@gmail.com>
;; 
;; 	Warn the user about the behavior of ivy--regex-ignore-order
;; 
;; 	Fixes #296 Fixes #305
;; 
;; 2015-11-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Minor fixes to ivy.org and export to ivy.texi
;; 
;; 	Fixes #304
;; 
;; 2015-11-24  sjLambda  <sjLambda@gmail.com>
;; 
;; 	ivy.org manual edits
;; 
;; 2015-11-24  kovrik  <kovrik0@gmail.com>
;; 
;; 	Fix `counsel-ag` on Windows
;; 
;; 2015-11-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--action): push-mark only if exited the minibuffer
;; 
;; 	"C-M-n" and "C-M-p" will no longer push mark and annoy with messages.
;; 
;; 2015-11-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Perform string-match in the original buffer
;; 
;; 	* ivy.el (ivy--exhibit): Wrap in `with-current-buffer'
;; 	 `ivy-state-buffer'.
;; 	(ivy-recompute-index-swiper): Reset to the candidate at the current line 
;; 	number, in case the previous regex resulted in 0 candidates.
;; 
;; 	Fixes #298
;; 
;; 2015-11-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--candidates): Require outline
;; 
;; 	Fixes #297
;; 
;; 2015-11-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the preselect for (swiper "one")
;; 
;; 	* ivy.el (ivy--reset-state): Ignore INITIAL-INPUT on the first
;; 	 step. Then all `ivy--filter' on the second step.
;; 	(ivy--preselect-index): Change arglist. No longer takes INITIAL-INPUT.
;; 	(ivy--recompute-index): Update the call to `ivy--preselect-index'.
;; 
;; 	Fixes #292
;; 
;; 2015-11-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Split into smaller defuns
;; 
;; 	* ivy.el (ivy--directory-done): New defun.
;; 	(ivy-alt-done): Forward to `ivy--directory-done'.
;; 
;; 2015-11-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Refactor
;; 
;; 	Collect all `ivy--directory' branches into a single `cond'.
;; 
;; 2015-11-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow access to TRAMP from "// C-j"
;; 
;; 	* ivy.el (ivy-alt-done): Match not only `ivy-text' but also
;; 	 `ivy--current' for TRAMP regex.
;; 
;; 	Re #285
;; 
;; 2015-11-18  Stephen Whipple  <shw@wicdmedia.org>
;; 
;; 	Improve ivy TRAMP support
;; 
;; 2015-11-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completing-read): Fix off by one
;; 
;; 	Re #295
;; 
;; 2015-11-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Switch to using ivy-exit-with-action
;; 
;; 	* ivy.el (ivy-exit-with-action): Add a missing quote.
;; 	(ivy--cd-maybe): Use `ivy-exit-with-action'.
;; 
;; 	* counsel.el (counsel-find-symbol):
;; 	(counsel--info-lookup-symbol):
;; 	(counsel-git-grep-query-replace): Use `ivy-exit-with-action'.
;; 
;; 	* swiper.el (swiper-query-replace):
;; 	(swiper-mc): Use `ivy-exit-with-action'.
;; 
;; 	The previous approach was overwriting the action list, so when
;; 	`ivy-resume' was called, only a single action was present.  The new 
;; 	approach doesn't have this bug.
;; 
;; 	So now it's possible to e.g. `counsel-describe-function' -> "M-o d" ->
;; 	`ivy-resume' -> "M-o o" -> `ivy-resume' -> "M-o i".
;; 
;; 2015-11-18  Samuel Loury  <konubinixweb@gmail.com>
;; 
;; 	Make ivy-completing-read handle history as cons
;; 
;; 	The ivy-read function assumes that history is a symbol, hence 
;; 	ivy-completing-read now makes sure that a symbol is given to ivy-read.
;; 
;; 	Moreover, it makes sure that the value of initial-input is coherent with
;; 	the value of the HISTPOS part of the history variable if it exists.
;; 
;; 	Fixes #295
;; 
;; 2015-11-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Modify the behavior with org-mode and visual-line-mode
;; 
;; 	* swiper.el (swiper--candidates): Set `swiper-use-visual-line' even for
;; 	 `org-mode'. In that case, reveal all text to prevent `line-move'
;; 	 weirdness.
;; 	(swiper--ivy): Use `swiper-use-visual-line'.
;; 
;; 	Re #291 Re #227
;; 
;; 2015-11-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add more bindings
;; 
;; 2015-11-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add precise preselect for swiper with visual-line-mode
;; 
;; 	* swiper.el (swiper--ivy): Use `count-screen-lines' to calculate the
;; 	 visual line number.
;; 
;; 	Fixes #291
;; 
;; 2015-11-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Intermediate fix for :preselect with visual-line-mode
;; 
;; 	* swiper.el (swiper--ivy): Use `beginning-of-visual-line' and
;; 	 `end-of-visual-line'. This should fix the preselect problem for
;; 	 non-duplicate buffer lines.
;; 
;; 	For duplicate buffer lines, a `visual-line-number-at-pos' function is 
;; 	necessary. I don't currently know how to implement such a function in an 
;; 	efficient way. The naive implementation could be pretty inefficient, 
;; 	comparable to doubling `swiper' startup time with `visual-line-mode'.
;; 
;; 	Re #291
;; 
;; 2015-11-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix swiper preselect issue with similar or identical lines
;; 
;; 	* ivy.el (ivy--preselect-index): Allow PRESELECT to be an integer.
;; 
;; 	* swiper.el (swiper--anchor):
;; 	(swiper--len): Remove unused defvar.
;; 	(swiper--init): Update.
;; 	(swiper--ivy): Set PRESELECT to `line-number-at-pos'.
;; 
;; 	Fixes #290
;; 
;; 2015-11-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-all): New command to swiper all file buffers
;; 
;; 	* swiper.el (swiper--candidates): Add NUMBERS-WIDTH arg.  It could be 
;; 	done better by calculating the line count of each buffer and then 
;; 	getting the max of that, but this way is faster, since the collections 
;; 	are traversed only once.
;; 	(swiper-multi): Update.
;; 	(swiper-all): New command. This is like `swiper-multi' where the buffer 
;; 	list is pre-selected to be all file visiting buffers.
;; 	(swiper--multi-candidates): New defun.
;; 	(swiper-multi-action-1): Use `swiper--multi-candidates'.
;; 	(swiper-multi-action-2): Update - the line number is in the 'display 
;; 	property of the first char.
;; 
;; 	Re #234
;; 
;; 2015-11-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--candidates): Replace "\t" with "    "
;; 
;; 	This will allow the minibuffer strings to align nicer for
;; 	`swiper-multi'.
;; 
;; 2015-11-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--truncate-string): New defun
;; 
;; 	* ivy.el (ivy-format-function-default): Use `ivy--truncate-string'.
;; 
;; 2015-11-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-locate): Add INTIAL-INPUT arg
;; 
;; 	Fixes #289
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--sort-files-by-date): Fix due to destructive cl-sort
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to sort files by last modification time.
;; 
;; 	* ivy.el (ivy--sort-files-by-date): New defun.
;; 
;; 	Example of use:
;; 
;; 	(add-to-list
;; 	'ivy-sort-matches-functions-alist
;; 	'(read-file-name-internal . ivy--sort-files-by-date))
;; 
;; 	This will result in e.g. `find-file' or `counsel-find-file' sorting 
;; 	files by last modification time.
;; 
;; 	Fixes #213
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow user-specified matched candidate sorting
;; 
;; 	* ivy.el (ivy-prefix-sort): Remove defcustom.
;; 	(ivy--filter): Forward sorting of matched candidates to `ivy--sort'.
;; 	(ivy-sort-matches-functions-alist): New defcustom.
;; 	(ivy--sort): New defun.
;; 
;; 	Fixes #269 Fixes #265
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-prefix-sort): New defcustom, off by default for now
;; 
;; 	* ivy.el (ivy--filter): When `ivy-prefix-sort' is non-nil, additionally
;; 	 sort the matching candidates with `ivy--prefix-sort'.
;; 	(ivy--prefix-sort): New defun.
;; 
;; 	Fixes #265
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-sort-functions-alist): Update doc
;; 
;; 	Mention `ivy-sort-max-size'.
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Add support for evil-jumper/backward
;; 
;; 	* swiper.el (evil-jumper--set-jump): Declare.
;; 	(swiper--init): When `evil-jumper-mode' is on, call
;; 	`evil-jumper--set-jump'.
;; 
;; 	* ivy.el (counsel-git-grep-cmd): Declare to silence the byte compiler.
;; 
;; 	Fixes #268
;; 
;; 2015-11-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Add eww-mode
;; 
;; 2015-11-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Add occur-mode
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-occur): Give full counsel-git-grep cands
;; 
;; 	This means that the " | head -n 200" speed-up isn't used and full 
;; 	candidates are returned.
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-occur-mode-map): Bind "q" to quit-window
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow counsel-git-grep -> ivy-occur -> wgrep
;; 
;; 	* ivy.el (ivy-exit-with-action): New defun.
;; 	(ivy-occur-action): Remove defvar. It's part of `ivy-occur-last' now.
;; 	(ivy-occur-last): Update doc.
;; 	(ivy-occur-map): Rename to `ivy-occur-mode-map'.
;; 	(ivy-occur-mode): New major mode.
;; 	(ivy-occur): When the caller is `counsel-git-grep', enter `grep-mode'; 
;; 	otherwise enter the new `ivy-occur-mode'. For `wgrep' to work, two
;; 	things are changed: candidates need to start on the 5th line, and
;; 	candidates need to be prefixed with "./".
;; 	(ivy-occur-read-action): New command, bound to "a".
;; 	(ivy-occur-dispatch): New command, bound to "o".
;; 	(ivy-occur-press): Update to work with `grep-mode'.
;; 	(ivy-occur-grep-mode-map): New defvar.
;; 	(ivy-occur-grep-mode): New major mode. Basically, it's grep-mode with
;; 	"C-x C-q" bound to `wgrep-change-to-wgrep-mode'.
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-dispatching-done): Don't set action permanently
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--find-symbol): Silence byte compiler
;; 
;; 2015-11-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-toggle-face-matching): Add and bind to "C-c C-f"
;; 
;; 	* swiper.el (swiper-map): Bind `swiper-toggle-face-matching' to
;; 	 "C-c C-f".
;; 	(swiper-invocation-face): New defvar.
;; 	(swiper--ivy): Set `swiper-invocation-face'.
;; 	(swiper-toggle-face-matching): Toggle `ivy-state-matcher' between nil
;; 	(the initial value) and 'swiper--face-matcher.
;; 	(swiper--face-matcher): New defun. In addition to filtering CANDIDATES 
;; 	by having them match REGEXP, also ensure that every match has
;; 	`swiper-invocation-face'.
;; 
;; 	Example of usage:
;; 
;; 	1. Move point to a variable with e.g. `font-lock-keyword-face' and "C-s"
;; 	<input>.
;; 
;; 	2. Use "C-c C-f" to filter the candidates further by selecting only the 
;; 	ones that have `font-lock-keyword-face'. Note that "M-q"
;; 	(`swiper-query-replace') is also affected by the filtering.
;; 
;; 	3. Use "C-c C-f" to toggle the filtering off.
;; 
;; 	Fixes #288
;; 
;; 2015-11-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Ensure the trailing slash for directories
;; 
;; 	* ivy.el (ivy-alt-done): Update.
;; 
;; 2015-11-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Show current-prefix-arg in the prompt
;; 
;; 	* counsel.el (counsel--M-x-prompt): New defun.
;; 	(counsel-M-x): Update.
;; 
;; 	Fixes #287
;; 
;; 2015-11-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/ivy.org: Start writing a manual
;; 
;; 2015-11-05  Stephen Whipple  <shw@wicdmedia.org>
;; 
;; 	Fix directory validity check
;; 
;; 	Directory validity check should be based on `ivy-text` and
;; 	`ivy--directory` rather than only `ivy-text`.
;; 
;; 	Fixes #283 Fixes #284
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a better ivy-occur pulse to swiper and counsel-git-grep
;; 
;; 	* ivy.el (ivy-occur-press): Bind `ivy-exit' to 'done, so that
;; 	 `swiper--add-overlays' called by ACTION don't do anything.
;; 	 Call another `swiper--add-overlays' for swiper and counsel-git-grep,
;; 	 limited to the current line. Call `swiper--cleanup' with a delay of 1
;; 	 second.
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--add-overlays): Take extra WND arg
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-query-replace): Should exit minibuffer
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Input "/sudo::" goes to current directory instead of root's home
;; 
;; 	* ivy.el (ivy-alt-done): Update.
;; 
;; 	Re #283
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix /ssh: and /sudo:: broken in 71695df
;; 
;; 	* ivy.el (ivy-alt-done): `file-directory-p' errors when given "/ssh:" or
;; 	 "/sudo::".
;; 
;; 	Re #283
;; 
;; 2015-11-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Rebind ivy-occur to "C-c C-o" and "C-o u"
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Update.
;; 
;; 	Wouldn't want to violate the "C-c LETTER" convention.
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Add "definition" action
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-occur-press): Extend with-ivy-window
;; 
;; 	ivy-occur-action should be called in (ivy--get-window ivy-last).
;; 
;; 	This means, for purposes of e.g. `counsel-find-symbol' or
;; 	`lispy--action-jump` that if *ivy-occur* is the only window, it will be 
;; 	re-used. But if the user wants *ivy-occur* not to get buried, then
;; 	having at least 2 windows solves that problem.
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-minibuffer-map): Bind "C-M-a" to ivy-read-action
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-rhythmbox): Add :caller
;; 
;; 	This results in more descriptive *ivy-occur* buffers.
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-occur-press): Work with counsel-rhythmbox
;; 
;; 	> (cdr (assoc str coll))
;; 
;; 	Special behavior for `counsel-rhythmbox'.  Maybe not taking `cdr' is the
;; 	right thing, but that's how Helm and `helm-rhythmbox-play-song' works.
;; 
;; 2015-11-04  mike  <miketz@users.noreply.github.com>
;; 
;; 	fix 1-too-far scrolling issue
;; 
;; 	Functions `ivy-scroll-up-command' and `ivy-scroll-down-command' would 
;; 	scroll 1 unit too far. So one item in the list would be skipped and
;; 	never seen for each scroll.
;; 
;; 2015-11-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Pulse after ivy-occur-press
;; 
;; 	* ivy.el (ivy-state): New field TEXT.
;; 	(ivy-occur): Add `ivy-text' to the name of the buffer. Also store
;; 	`ivy-text' in `ivy-occur-last'. Might be needed in the future for a more 
;; 	specific pulse.
;; 	(ivy-occur-press): Pulse the selected line.
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make ivy work with enable-recursive-minibuffers
;; 
;; 	* ivy.el (ivy-read): Fix the doc of DYNAMIC-COLLECTION.	 Store the old
;; 	`ivy-last' in case `ivy-read' is called while inside the minibuffer. 
;; 	Restore it after `ivy-call'.
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude debbugs-gnu-mode
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-occur): Add and bind to "C-c o"
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 	(ivy-occur-action):
;; 	(ivy-occur-last):
;; 	(ivy-occur-map): New defvar.
;; 	(ivy-occur): New command.
;; 	(ivy-occur-click): New command bound to mouse click.
;; 	(ivy-occur-press): New command bound to "RET" press.
;; 
;; 	`ivy-occur' allows to store the current completion session for further 
;; 	use. An unlimited amount of these sessions can be used, each in its own 
;; 	buffer.
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (with-ivy-window): Ensure window is live
;; 
;; 	* ivy.el (ivy--get-window): New defun.
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-state): Add a new field BUFFER
;; 
;; 	* ivy.el (ivy-resume): Update.
;; 	(ivy-read): Update.
;; 
;; 	* swiper.el (swiper--action): Use `ivy-state-buffer'.
;; 
;; 2015-11-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-mc): Update
;; 
;; 2015-11-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Highlight modified file buffers with 'ivy-modified-buffer face
;; 
;; 	* ivy.el (ivy-modified-buffer): New face, blank by default.
;; 	(ivy--format): When the collection is 'internal-complete-buffer, 
;; 	highlight unsaved file visiting buffers with 'ivy-modified-buffer.
;; 
;; 	Fixes #280
;; 
;; 	Example custom setting for 'ivy-modified-buffer:
;; 
;; 	(custom-set-faces
;; 	'(ivy-modified-buffer ((t (:background "#ff7777")))))
;; 
;; 2015-11-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ffap): Move require
;; 
;; 2015-10-31  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-query-replace): Add and bind to "M-q"
;; 
;; 	* counsel.el (counsel-git-grep-map): Bind "M-q" to
;; 	 `counsel-git-grep-query-replace'.
;; 	(counsel-git-grep-query-replace): New command. Perform `query-replace' 
;; 	on all matches of git-grep in all buffers.
;; 
;; 2015-10-31  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude eems-stream-mode
;; 
;; 	Re #19
;; 
;; 2015-10-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"C-x C-f M-n" can call ffap-url-fetcher when at URL
;; 
;; 	* ivy.el (ivy--cd-maybe): Check if the input is a valid URL. If so, exit
;; 	immediately by calling (funcall ffap-url-fetcher url). Otherwise, do the
;; 	usual `ivy--cd' thing.
;; 
;; 2015-10-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: "M-n" should prefer url at point to symbol at point
;; 
;; 	* ivy.el (ivy--reset-state): Update.
;; 
;; 2015-10-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--find-symbol): Resolve name clash better
;; 
;; 	* counsel.el (counsel--find-symbol): When the symbol is both bound and
;; 	 fbound, prefer the fbound one, unless the :caller is
;; 	 `counsel-describe-variable'.
;; 	(counsel-describe-variable): Declare :caller.
;; 	(counsel-describe-function): Declare :caller.
;; 
;; 	One example is going to the definition of `isearch-forward' (also with
;; 	`counsel-M-x').
;; 
;; 2015-10-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve the preselect index in ivy-resume
;; 
;; 	* ivy.el (ivy--recompute-index): Don't change the ivy--index that was
;; 	 set in `ivy--reset-state' by `ivy-resume'.
;; 
;; 	With this, it's possible to e.g. "<f1> f", enter "for", navigate to
;; 	"format" and press "C-g". Calling `ivy-resume' will point to "format" 
;; 	still.
;; 
;; 2015-10-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use a specific blending method for dark themes
;; 
;; 	* colir.el (colir-blend): Use 'colir-compose-soft-light for dark themes.
;; 
;; 	Fixes #278
;; 
;; 2015-10-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Rename and move the minibuffer faces
;; 
;; 	* swiper.el (swiper-minibuffer-match-face-1):
;; 	(swiper-minibuffer-match-face-2):
;; 	(swiper-minibuffer-match-face-3):
;; 	(swiper-minibuffer-match-face-4): Transform into obsolete aliases.
;; 
;; 	* ivy.el (ivy-minibuffer-match-face-1):
;; 	(ivy-minibuffer-match-face-2):
;; 	(ivy-minibuffer-match-face-3):
;; 	(ivy-minibuffer-match-face-4): New renamed faces.
;; 	(ivy-minibuffer-faces): Rename from `swiper-minibuffer-faces'.
;; 
;; 	Fixes #276
;; 
;; 2015-10-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git): Update default-directory
;; 
;; 2015-10-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-immediate-done should use ivy--directory
;; 
;; 	* ivy.el (ivy-immediate-done): When completing file names, expand the
;; 	 file name properly.
;; 
;; 	Fixes #275
;; 
;; 2015-10-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Amend exception list
;; 
;; 	Re #19
;; 
;; 2015-10-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Fix up last commit
;; 
;; 2015-10-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"C-j" should not stop completion for a pasted file path
;; 
;; 	* ivy.el (ivy-alt-done): If you paste a file path, it won't match
;; 	 anything in the current directory. Previously, "C-j" would open dired
;; 	 for that path. Now, "C-j" will switch to the pasted directory and
;; 	 continue completion.
;; 
;; 	This behavior conforms to `ido-find-file'.
;; 
;; 2015-10-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix pasting file paths on Windows
;; 
;; 	* ivy.el (ivy--exhibit): Update.
;; 
;; 	Fixes #272
;; 
;; 2015-10-22  Stephen Whipple  <shw@wicdmedia.org>
;; 
;; 	Fix Custom menus
;; 
;; 	Custom menus for `ivy-virtual-abbreviate' and `ivy-sort-functions-alist' 
;; 	now display a better user interface.
;; 
;; 	Fixes #274
;; 
;; 2015-10-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a test for the perfect match logic
;; 
;; 	Re #270
;; 
;; 2015-10-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bring back the lost perfect match logic
;; 
;; 	* ivy.el (ivy--recompute-index): Don't defer the perfect match logic to
;; 	 `ivy-index-functions-alist'.
;; 	(ivy-recompute-index-swiper): Simplify.
;; 
;; 	Once again, if the minibuffer text becomes `equal' to one of the 
;; 	candidates, that candidate will be selected.
;; 
;; 	Fixes #270
;; 
;; 2015-10-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-resume): Pass caller
;; 
;; 	Fixes #245
;; 
;; 2015-10-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial): Fix for fuzzy completion
;; 
;; 	Postfix doesn't always work if the completion is fuzzy, so check if
;; 	`string-match' succeeds.
;; 
;; 	Fixes #266
;; 
;; 2015-10-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the count in user-specified counsel-git-grep
;; 
;; 	* counsel.el (counsel--gg-count): Generate the count command from
;; 	`counsel-git-grep-cmd' by replacing "--full-name" with "-c".
;; 
;; 	Re #244
;; 
;; 2015-10-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-sort-functions-alist): Upgrade to defcustom
;; 
;; 	Add the proper :type.
;; 
;; 2015-10-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-extra-directories): Improve :type
;; 
;; 2015-10-16  Jon Miller	<jonEbird@gmail.com>
;; 
;; 	counsel.el (counsel-ag): Add initial-directory
;; 
;; 	Support alternative initial directory which helps other packages call 
;; 	this function with their unique starting directory.
;; 
;; 2015-10-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't re-anchor to matching old candidate if flx is on
;; 
;; 	* ivy.el (ivy--recompute-index): If `flx' is in position to select the
;; 	 "best" candidate, don't re-anchor to the still-matching previous
;; 	 candidate.
;; 
;; 	Fixes #263
;; 
;; 2015-10-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add feedback for long-running async processes
;; 
;; 	* counsel.el (counsel--async-time): New defvar.
;; 	(counsel--async-filter): New defun.
;; 	(counsel--async-command): Use `counsel--async-filter'.
;; 
;; 	Each time 0.5s pass after the last input, if the external process hasn't 
;; 	finished yet, update minibuffer with the amount of candidates collected 
;; 	so far. This is useful to see that long running commands like
;; 	`counsel-locate' or `counsel-ag' (when in a very large directory) aren't 
;; 	stuck.
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-test.el (swiper--re-builder): Update
;; 
;; 	Due to last commit
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--re-builder): Fix "^a" -> "^" case
;; 
;; 	Fixes #262
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Adjust the swiper regexp builder for the display change
;; 
;; 	* swiper.el (swiper--re-builder): Update. The old re-builder was for
;; 	 when the line numbers were part of the candidates. Now the line
;; 	 numbers are the text properties of the candidates.
;; 
;; 	Fixes #262
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Try to fix the previous commit
;; 
;; 	* ivy.el (ivy--exhibit): Update.
;; 
;; 	Sometimes the cursor randomly moves to the start of the read-only prompt 
;; 	and it's impossible to move it.
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix "C-x h" selection and "C-b" bug
;; 
;; 	* ivy.el (ivy--exhibit): Add another `constrain-to-field'.
;; 
;; 	This ensures that the point doesn't cross into the prompt text. 
;; 	Previously, there was a bug that pressing "C-b" once more when already 
;; 	at the start of the input set `ivy-text' to "", i.e. ignoring the 
;; 	minibuffer input.
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix window selection in counsel-locate
;; 
;; 	* counsel.el (counsel-locate): Use `with-ivy-window'.
;; 
;; 2015-10-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-mc): Add and bind to "C-7"
;; 
;; 	* swiper.el (swiper-map): Update.
;; 	(swiper-mc): New command.
;; 	(swiper--ivy): Use :action.
;; 	(swiper--action): Update arglist.
;; 
;; 2015-10-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-case-fold-search): New defvar
;; 
;; 	* ivy.el (ivy--reset-state): Set `ivy-case-fold-search' to 'auto.
;; 	(ivy-toggle-case-fold): New command.
;; 	(ivy--filter): Use `ivy-case-fold-search' to determine
;; 	`case-fold-search'.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Bind "C" to `ivy-toggle-case-fold'.
;; 
;; 	Fixes #259
;; 
;; 2015-10-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-count-format must be an empty string instead of nil
;; 
;; 	Using an empty string is easier. No longer needed to check for nil when 
;; 	using `string-match', `concat' etc.
;; 
;; 	* doc/Changelog.org: Update.
;; 
;; 	* ivy.el (ivy-count-format): Update doc and customize type.
;; 	(ivy--reset-state): Error if `ivy-count-format' nil is encountered.
;; 
;; 	Fixes #257 Re  #188
;; 
;; 2015-10-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the count when git-grep for "->foo"
;; 
;; 	* counsel.el: For some reason, "-" gets interpreted in a bad way. 
;; 	Escaping it as "\-" makes it work fine.
;; 
;; 2015-10-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--recompute-index): Fixup
;; 
;; 	Fixes #258
;; 
;; 2015-10-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't reset the match to first if the current one still works
;; 
;; 	* ivy.el (ivy--recompute-index): If the old match is still located in
;; 	 the current matches after the change in input, keep it selected.
;; 
;; 	* ivy-test.el (ivy-read): Add test.
;; 
;; 	Fixes #258
;; 
;; 2015-10-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-virtual-abbreviate): New defcustom
;; 
;; 	* ivy.el (ivy--virtual-buffers): Update.
;; 
;; 	Fixes #255
;; 
;; 2015-10-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el (hydra-ivy): Make the docstring a rectangle
;; 
;; 2015-10-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Move setq ivy--index to ivy--recompute-index
;; 
;; 	* ivy.el (ivy--recompute-index): Move the setq statement here, so that
;; 	 the customization functions have less internal variables to deal with.
;; 	(ivy-recompute-index-swiper): Update.
;; 	(ivy-recompute-index-zero): Update.
;; 
;; 	Re #253
;; 
;; 2015-10-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-index-functions-alist): New variable
;; 
;; 	* ivy.el (ivy-state): Add `caller' field.
;; 	(ivy-read): Add `caller' keyword arg; update docstring. Use
;; 	`ivy--recompute-index'.
;; 	(ivy--recompute-index): New defun, dispatch according to `caller' and
;; 	`ivy-index-functions-alist'.
;; 	(ivy-recompute-index-swiper): New defun.
;; 	(ivy-recompute-index-zero): New defun.
;; 
;; 	Fixes #253
;; 
;; 2015-10-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Add a lot of avy declares
;; 
;; 2015-10-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-dispatching-call): Add and bind to "C-M-o"
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 	(ivy-read-action): New command.
;; 	(ivy-dispatching-done): Update.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Bind `ivy-read-action' to "a".
;; 
;; 	Re #254
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix preselect for input "^"
;; 
;; 	* ivy.el (ivy--filter): Update.
;; 
;; 	Notably, e.g. `counsel-describe-variable' should properly preselect 
;; 	variable at point.
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-last): Update docstring
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-use-virtual-buffers): Update docstring
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Default ivy-display-style to 'fancy for Emacs>=24.5
;; 
;; 	* ivy.el (ivy-display-style): Update.
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-count-format): Extend customize choices
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix ivy-state-preselect for file name completion
;; 
;; 	* ivy.el (ivy--preselect-index): Add a check for null preselect.
;; 	(ivy--filter): Use `ivy--preselect-index' instead of `cl-position'. The 
;; 	reason is that the collection contains e.g "foo/" while the preselect is
;; 	"foo".
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix "M-o k" when switching buffers
;; 
;; 	* ivy.el (ivy-call): Check if (active-minibuffer-window) is non-nil
;; 	 before switching.
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Adjust ivy-state-preselect for file name completion
;; 
;; 	* ivy.el (ivy--reset-state): Since `ivy--index' is now recomputed more,
;; 	 `ivy-state-preselect' needs to be in the collection properly, so that
;; 	 `ivy--index' is set to preselect whenever the input is empty.
;; 
;; 2015-10-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--filter): Fix typo
;; 
;; 	Re #253
;; 
;; 2015-10-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--filter): Anchor only for swiper
;; 
;; 	* ivy-test.el (ivy-read): Add tests. Except for `swiper', when the input
;; 	 changes `ivy-index' should usually be 0.
;; 
;; 	Fixes #231
;; 
;; 2015-10-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--insert-prompt): Use newlines instead of truncation
;; 
;; 	When the prompt string is longer than window-width, insert newlines 
;; 	appropriately so that the whole prompt fits in the window without 
;; 	scrolling.  Finally, when prompt+entered text would be larger than 
;; 	window-width, reformat the prompt so that entered text starts on a 
;; 	newline.  When completing file names, move the whole path to a new line 
;; 	in that case.
;; 
;; 	Fixes #252
;; 
;; 2015-10-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Support hash tables in ivy-read
;; 
;; 	* ivy.el (ivy--reset-state): `all-completions' also works fine for hash
;; 	 tables, so start using it.
;; 
;; 	Hash tables as collections are rare. One example is "C-c C-w" in *rcirc*
;; 	(`rcirc-cmd-whois').
;; 
;; 2015-10-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude help-mode
;; 
;; 	Fixes #248
;; 
;; 2015-10-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix up visual-line-mode limitation logic
;; 
;; 	* swiper.el (swiper-use-visual-line): New defvar.
;; 	(swiper--candidates):
;; 	(swiper--update-input-ivy):
;; 	(swiper--action): Update.
;; 
;; 	Re #227
;; 
;; 2015-10-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--candidates): Avoid line-move for large buffers
;; 
;; 	Re #227
;; 
;; 2015-10-04  PythonNut  <PythonNut@users.noreply.github.com>
;; 
;; 	swiper-avy: show avy hints in minibuffer as well
;; 
;; 2015-10-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix "End of buffer" for swiper and visual-line-mode
;; 
;; 	Fixes #247
;; 
;; 2015-10-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Customize ivy-avy and fix compile warnings
;; 
;; 	* ivy.el (ivy-avy): Require avy. Allow the user to customize `avy-keys',
;; 	 `avy-background' and `avy-style' (but prefer 'pre to 'at-full, since
;; 	 it doesn't obscure any letters).  Don't issue an extra `ivy-call'.
;; 
;; 	Fixes #246
;; 
;; 2015-10-03  PythonNut  <PythonNut@users.noreply.github.com>
;; 
;; 	Implement ivy-avy
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--gg-count): Fix for "'" in query
;; 
;; 	Since "'" is used for quoting in bash, it needs to be replaced with "''"
;; 	.
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use forward-line instead of line-move if possible
;; 
;; 	* swiper.el (swiper--candidates):
;; 	(swiper--update-input-ivy):
;; 	(swiper--action): `line-move' is much slower than `forward-line'. Use it 
;; 	only if `visual-line-mode' is on.
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--gg-candidates): Use counsel-git-grep-cmd
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix counsel-git-grep not updating to 0 candidates
;; 
;; 	* counsel.el (counsel--gg-candidates): `ivy--all-candidates' should not
;; 	 be nil in order for `ivy--exhibit' to update the minibuffer.
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make swiper compatible with visual-line-mode
;; 
;; 	* swiper.el (swiper--candidates): Use `end-of-visual-line' and
;; 	 `line-move' appropriately.
;; 	(swiper--update-input-ivy):
;; 	(swiper--action): Use `line-move' instead of `forward-line'.
;; 	(swiper--add-overlays): Update.
;; 
;; 	Fixes #227
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-resume): Don't regexp-quote preselect
;; 
;; 	`ivy--preselect-index' uses `cl-position' before trying to match regex, 
;; 	so the string needs to be as is.
;; 
;; 	Fixes #245
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el: Bind "t" to toggle-truncate-lines
;; 
;; 	* ivy.el (ivy-format-function-default): When `truncate-lines' is non-nil
;; 	 don't truncate with "...".
;; 
;; 	Use "C-o t" when you complete very long lines and want to see them 
;; 	whole.
;; 
;; 	Fixes #214
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--reset-state): Less strict on :preselect
;; 
;; 2015-10-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Specify shell command for counsel-git-grep with prefix arg
;; 
;; 	* counsel.el (counsel-git-grep-cmd): New defvar.
;; 	(counsel-git-grep-function): Use `counsel-git-grep-cmd'.
;; 	(counsel-git-grep-cmd-history): New defvar.
;; 	(counsel-git-grep): Update signature. When called with a prefix arg, 
;; 	prompt for a command reading from and recording to
;; 	`counsel-git-grep-cmd-history'.
;; 
;; 	Remember to use "M-i" to insert the current candidate into the 
;; 	minibuffer.
;; 
;; 	Fixes #244
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-yank-word): Add only one space each time
;; 
;; 	The previous behavior got in trouble with consecutive spaces.
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex-fuzzy): Add minibuffer highlighting
;; 
;; 	* ivy-test.el (ivy--regex-fuzzy): Update test.
;; 
;; 	Re #207
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add flx sorting
;; 
;; 	* ivy.el (ivy--flx-cache): New defvar.
;; 	(ivy--filter): Since flx is costly, move the caching to an earlier 
;; 	point. This means immediate return for when the input hasn't changed, 
;; 	i.e. for "C-n" or "C-p". When flx is installed, and
;; 	(eq ivy--regex-function 'ivy--regex-fuzzy) for current function (through
;; 	`ivy-re-builders-alist'), then sort the final candidates with
;; 	`ivy--flx-sort'.
;; 	(ivy--flx-sort): New defun. In the worst case when some error pops up
;; 	return the same list. In the best case sort the `cands' that all match
;; 	`name' by closeness to `name'.
;; 
;; 	How to use: 1. Have flx installed - (require 'flx) should succeed. 2.
;; 	Configure `ivy-re-builders-alist' appropriately to use
;; 	`ivy--regex-fuzzy', for example:
;; 
;; 	    (setq ivy-re-builders-alist
;; 		 '((t . ivy--regex-fuzzy)))
;; 
;; 	Fixes #207
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-call): "C-M-n" should not leave the minibuffer
;; 
;; 	Make sure that the minibuffer window remains selected as long as the 
;; 	completion hasn't finished. For example, "<f1> f" to call
;; 	`counsel-describe-function' input
;; 	"forward" and spam "C-M-n" to read the doc for each function that starts 
;; 	with "forward". The *Help* window popup would move the window focus, but 
;; 	this change moves it back to the minibuffer.
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve "C-g" out of a long-running async process
;; 
;; 	* counsel.el (counsel-delete-process): New defun.
;; 	(counsel-locate):
;; 	(counsel-ag): Use `counsel-delete-process' as :unwind.
;; 
;; 2015-09-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--insert-prompt): Improve truncation
;; 
;; 	Re #240
;; 
;; 2015-09-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Don't rely on package-installed-p
;; 
;; 	* counsel.el (counsel-M-x): Use `require' instead. `package-installed-p'
;; 	 may fail if package wasn't initialized.
;; 
;; 2015-09-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-ag-function): Improve for fancy faces
;; 
;; 	Set `ivy--old-re' in order for fancy `ivy-display-style' to work.
;; 
;; 2015-09-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--find-symbol): Allow to jump back with pop-tag-mark
;; 
;; 	Using "C-." in:
;; 
;; 	- counsel-describe-function
;; 	- counsel-describe-variable
;; 	- counsel-load-library
;; 
;; 	will change the current buffer. The buffer and point can be restored 
;; 	with "M-*" (`pop-tag-mark').
;; 
;; 	I also recommend this binding:
;; 
;; 	    (global-set-key (kbd "M-,") 'pop-tag-mark)
;; 
;; 2015-09-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Add mu4e
;; 
;; 	Re #19
;; 
;; 2015-09-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--insert-prompt): Avoid negative length error
;; 
;; 2015-09-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Truncate minibuffer prompts longer than window-width
;; 
;; 	* ivy.el (ivy--insert-prompt): When the prompt string is longer than the
;; 	 window width, truncate it to window width minus 26 chars.
;; 
;; 	Fixes #240
;; 
;; 2015-09-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make ivy-display-style more compatible with 24.3
;; 
;; 	* ivy.el (ivy--format-minibuffer-line): Use
;; 	 `font-lock-append-text-property' instead of
;; 	 `add-face-text-property'. It's not optimal, since the new face needs
;; 	 to be put in front, but at least it doesn't error out.
;; 
;; 2015-09-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--resize-minibuffer-to-fit): Make compatible with 24.3
;; 
;; 	Fixes #220
;; 
;; 2015-09-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Remove obsolete version check
;; 
;; 2015-09-22  Julien Wietrich  <julien.w6h@gmail.com>
;; 
;; 	Fix minibuffer collapse in text mode emacs
;; 
;; 	In graphic mode : resize-mini-windows is temporarily set to nil, the 
;; 	only value which does not collapse the minibuffer.
;; 
;; 	In text mode : if resize-mini-windows is nil, it is temporarily set to
;; 	'grow-only (default emacs value).
;; 
;; 	This prevent the minibuffer collapse in both graphic and text mode.
;; 
;; 	In text mode it respects the user settings if it is already set to
;; 	'grow-only or t.
;; 
;; 	Fix #237 in text mode emacs too.
;; 
;; 2015-09-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Use minibuffer-allow-text-properties
;; 
;; 	Using `minibuffer-allow-text-properties' makes Emacs not strip the text 
;; 	properties from the result of `read-from-minibuffer'. This is better 
;; 	because a function call result is used instead of a global var to pass 
;; 	this info.
;; 
;; 2015-09-19  Julien Wietrich  <julien.w6h@gmail.com>
;; 
;; 	Revert multiple frames workaround
;; 
;; 	Since SHA:d8d7ed45f07b52ab63eca444f0e6fa03747fab9e workaround
;; 	SHA:435f2b6edfe3ab517c9eda56c6351f0bcfdf3845 is no longer required.
;; 
;; 2015-09-19  Julien Wietrich  <julien.w6h@gmail.com>
;; 
;; 	Fix minibuffer collapses to one line
;; 
;; 	It happens since commit SHA:d374afea36df19b5d6b654adc6018b25d6c1d8f2 
;; 	when resize-mini-windows is set to true.
;; 
;; 	It also happens when resize-mini-windows is set to 'grow-only (default) 
;; 	and multiple frames are open.
;; 	(Although SHA:435f2b6edfe3ab517c9eda56c6351f0bcfdf3845 work around it)
;; 
;; 	Temporarily bind `resize-mini-windows' to nil before calling
;; 	`read-from-minibuffer'.
;; 
;; 	Fix #237 and #229
;; 
;; 	It might fix #77 although this need to be checked as I cannot reproduce
;; 	it.
;; 
;; 2015-09-18  PythonNut  <PythonNut@users.noreply.github.com>
;; 
;; 	Add autoloads to some important functions
;; 
;; 2015-09-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-switch-buffer): Make "M-o r" rename buffer
;; 
;; 	* ivy.el (ivy--rename-buffer-action): New defun.
;; 
;; 	Fixes #233
;; 
;; 2015-09-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make "<left>" and "<right>" behave as in fundamental-mode
;; 
;; 	Fixes #232
;; 
;; 2015-09-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add work-around for minibuffer not re-sizing for many frames
;; 
;; 	* ivy.el (ivy--minibuffer-setup): When `truncate-lines' is set, it works
;; 	 fine for one graphic frame, but not for two (unknown why); add a
;; 	 work-around.
;; 
;; 	Fixes #229
;; 
;; 2015-09-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-yank-pop): Add autoload
;; 
;; 2015-09-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-format-function-default): Fix boundp bug
;; 
;; 	Fixes #225
;; 
;; 2015-09-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-yank-pop-truncate): Add group
;; 
;; 2015-09-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Fix compiler warning
;; 
;; 2015-09-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-yank-pop): New command
;; 
;; 	* counsel.el (counsel-yank-pop-truncate): New defcustom. Choose whether
;; 	 to truncate strings over 4 lines.
;; 	(counsel-yank-pop-action): New defun.
;; 
;; 	Fixes #218
;; 
;; 2015-09-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make line numbers in swiper into display properties
;; 
;; 	* swiper.el (swiper--candidates): Each candidate is now a single space
;; 	 plus the original string. The display property of the single space
;; 	 holds the line number. This means that it's no longer possible to
;; 	 match line numbers in queries. Also, the preselect of the current line
;; 	 is slightly worse (in case there are two identical lines in a buffer).
;; 	(swiper--ivy): Update the preselect to not include the line number.
;; 	Also, call `ivy--action' on `ivy-current' instead of `res', because
;; 	`res' doesn't have the string property that points to the line number.
;; 	(swiper--update-input-ivy): Update.
;; 	(swiper--action): Update.
;; 
;; 	Fixes #224
;; 
;; 2015-09-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Set truncate-lines in the minibuffer
;; 
;; 	* ivy.el (ivy--minibuffer-setup): Update.
;; 	(ivy-format-function-default): Check `truncate-lines'. Check if
;; 	`fringe-mode' is bound.
;; 
;; 	Fixes #223
;; 
;; 2015-09-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--resize-minibuffer-to-fit): Make compatible with 24.3
;; 
;; 	Re #220
;; 
;; 2015-09-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-format-function-default): Handle fringe-mode 0
;; 
;; 	Fixes #219
;; 
;; 2015-09-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-unicode-char): Add own history
;; 
;; 	Also make "C-M-n", "C-M-p", and `ivy-resume' work properly.
;; 
;; 2015-09-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix up the "foo ! bar" matching and highlighting
;; 
;; 	* ivy.el (ivy--filter): When regex returned is a list, use only the
;; 	 first string part.
;; 
;; 	* swiper.el (swiper--update-input-ivy): When regex returned is a list,
;; 	 use only the first string part.
;; 
;; 2015-09-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Move swiper-minibuffer-faces to ivy.el
;; 
;; 	Fixes #217
;; 
;; 2015-09-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Declare some SLIME functions
;; 
;; 	* counsel.el (slime-symbol-start-pos):
;; 	(slime-symbol-end-pos):
;; 	(slime-contextual-completions): Declare.
;; 
;; 2015-09-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-function): Fix up
;; 
;; 	Set `ivy--old-re' for the benefit of fancy minibuffer faces.
;; 
;; 2015-09-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make the minibuffer faces look nicer
;; 
;; 	* ivy.el (ivy-current-match): Update background and add white
;; 	 foreground for light themes. Update background and add black
;; 	 foreground for dark themes.
;; 	(ivy--add-face): If a face has an explicit foreground, add it ahead, 
;; 	with no blending. Blend the background as usual.
;; 
;; 	* swiper.el (swiper-minibuffer-match-face-1):
;; 	(swiper-minibuffer-match-face-2): Update the background for light
;; 	 themes.
;; 	(swiper-minibuffer-match-face-4): Update the background for dark themes.
;; 
;; 2015-09-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add default values for minibuffer faces
;; 
;; 	* swiper.el (swiper-minibuffer-match-face-1):
;; 	(swiper-minibuffer-match-face-2):
;; 	(swiper-minibuffer-match-face-3):
;; 	(swiper-minibuffer-match-face-4): Update.
;; 
;; 	Re #215
;; 
;; 2015-09-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--format-minibuffer-line): Fix nil regexp
;; 
;; 2015-09-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make ivy-current blend correctly for fancy minibuffer
;; 
;; 	* ivy.el (ivy--format-minibuffer-line): Stop setting :height - it messes
;; 	 with blending. Also, the minibuffer height issue was fixed in an
;; 	 earlier pull request.
;; 
;; 	(ivy--format): Call `ivy--add-face' on modified string, not on the 
;; 	original one.
;; 
;; 2015-09-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--format-minibuffer-line): Use add-face-text-property
;; 
;; 2015-09-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add extra faces for minibuffer highlighting
;; 
;; 	* swiper.el (swiper-minibuffer-match-face-1):
;; 	(swiper-minibuffer-match-face-2):
;; 	(swiper-minibuffer-match-face-3):
;; 	(swiper-minibuffer-match-face-4): New defface.
;; 	(swiper-minibuffer-faces): New defvar.
;; 
;; 	* ivy.el (ivy--format-minibuffer-line): New defun.
;; 	(ivy--format): Use `ivy--format-minibuffer-line'.
;; 
;; 2015-09-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-display-style): New defcustom
;; 
;; 	* ivy.el (ivy--format): Add additional highlighting for the minibuffer,
;; 	 similar to `swiper', when `ivy-display-style' is set to 'fancy.
;; 
;; 	Fixes #212
;; 
;; 2015-08-31  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-cl): New command
;; 
;; 	* counsel.el (counsel--el-action): Add `with-ivy-window' wrapper.
;; 
;; 2015-08-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel--py-action): Work with "C-M-n"
;; 
;; 	* counsel.el (counsel--py-action): Include the inserted parens in to
;; 	 bounds, so that "C-M-n", "C-M-p" and `ivy-resume' work.
;; 
;; 2015-08-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-jedi): New command
;; 
;; 	* counsel.el (counsel--py-action): New defun.
;; 
;; 	Add a few declares as well.
;; 
;; 2015-08-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add swiper-multi command
;; 
;; 	* swiper.el (swiper-multi-buffers): New defvar.
;; 	(swiper-multi-candidates): New defvar.
;; 	(swiper-multi-prompt): New defun.
;; 	(swiper-multi-action-1): New defun.
;; 	(swiper-multi-action-2): New defun.
;; 
;; 	Fixes #182.
;; 
;; 	Basic usage tips for selecting multiple buffers:
;; 
;; 	- Use "C-M-m" (`ivy-call') to add or remove one more buffer without
;; 	exiting.
;; 	- Use "C-m" (`ivy-done') to add one last buffer.
;; 	- Or use "C-M-j" (`ivy-immediate-done') to finish without adding more
;; 	buffers.
;; 	- Hold "C-M-n" (`ivy-next-line-and-call') to add a lot of buffers at
;; 	once.
;; 
;; 2015-08-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-tag): Now works in agenda
;; 
;; 	* counsel.el (counsel-org--set-tags): New defun.
;; 	(counsel-org-tag-action): Update.
;; 
;; 	When on an agenda item, add/remove tags for that item.
;; 
;; 	When any agenda items are marked with "m", add selected tags to all 
;; 	items, with no duplicates.
;; 
;; 	Fixed the bug of setting tags to "::" sometimes. Fixed "C-M-j" not
;; 	exiting.
;; 
;; 	Fixes #200
;; 
;; 2015-08-18  Felix Lange	 <fjl@twurst.com>
;; 
;; 	ivy: enlarge the minibuffer window if the candiate list doesn't fit
;; 
;; 	Fixes #161 Fixes #198
;; 
;; 2015-08-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Set line-spacing to 0 in the minibuffer
;; 
;; 	* ivy.el (ivy--minibuffer-setup): Update.
;; 
;; 	Fixes #198
;; 
;; 2015-08-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-kill-ring-save): Add and bind to "M-w"
;; 
;; 	Fixes #197
;; 
;; 2015-08-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completing-read): Fix up last commit
;; 
;; 	Check if string before using `string-match'.
;; 
;; 2015-08-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	When initial input contains a plus, escape it
;; 
;; 	* ivy.el (ivy-completing-read): Escape the plus in the initial input,
;; 	 for it to not be interpreted like a regex.
;; 
;; 	Fixes #195
;; 
;; 2015-08-12  Tassilo Horn  <tsdh@gnu.org>
;; 
;; 	Fix #126 again.
;; 
;; 	After #126 has been solved, the regexp has been changed to
;; 
;; 	  "\\`[`']?\\(.*\\)'?\\'"
;; 
;; 	where the trailing ' is optional ("'?").  However, the preceeding
;; 	"\\(.*\\)" group will already capture the trailing ' because .* is 
;; 	greedy.	 Now I've replaced it with the non-greedy .*? which makes it 
;; 	work again.
;; 
;; 2015-08-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix :dynamic-collection not being sorted
;; 
;; 	* ivy.el (ivy--sort-maybe): New defun. If the current completion has
;; 	 sorting enabled, try to find the sorting function either in :sort or
;; 	 `ivy-sort-functions-alist'.
;; 	(ivy--exhibit): Use `ivy--sort-maybe'.
;; 
;; 	* counsel.el (counsel--async-sentinel): Use `ivy--sort-maybe'.
;; 
;; 2015-08-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel-locate should use '' for the regex
;; 
;; 	* counsel.el (counsel-unquote-regex-parens): New defun.
;; 	(counsel-locate-function): Update.
;; 	(counsel-ag-function): Update.
;; 
;; 	Fixes #194
;; 
;; 2015-08-07  Chunyang Xu	 <xuchunyang56@gmail.com>
;; 
;; 	(counsel-locate): Support OS X
;; 
;; 	- OS X "open" is the equivalent to "xdg-open"
;; 	- OS X "locate" doesn't support "--regex"
;; 
;; 2015-08-06  Tassilo Horn  <tsdh@gnu.org>
;; 
;; 	(counsel-locate): Allow customizing locate options
;; 
;; 2015-08-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix up ivy-recentf and ivy-switch-buffer window-wise
;; 
;; 	* ivy.el (ivy--switch-buffer-action):
;; 	(ivy-recentf): Use `with-ivy-window'.
;; 
;; 2015-08-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	doc/Changelog.org: Add
;; 
;; 2015-08-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-find-file): Fix window focus issue
;; 
;; 	"C-M-n" should work fine now.
;; 
;; 2015-08-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Preselect perfect matches with a leading ^
;; 
;; 	* ivy.el (ivy--filter): When e.g. "filter" is in the collection,
;; 	 "^filter" input should always select it, even if other candidates
;; 	 match.
;; 
;; 2015-08-01  Chunyang Xu	 <xuchunyang56@gmail.com>
;; 
;; 	Allow ivy-count-format to be set as nil
;; 
;; 2015-07-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add with-ivy-window macro
;; 
;; 	* ivy.el (with-ivy-window): New macro.
;; 	(ivy-yank-word): Update.
;; 
;; 	* swiper.el (swiper--window): Remove defvar.
;; 	(swiper-query-replace):
;; 	(swiper-avy):
;; 	(swiper-recenter-top-bottom):
;; 	(swiper--init):
;; 	(swiper--update-input-ivy):
;; 	(swiper--add-overlays): Update.
;; 
;; 	* counsel.el (counsel-git-grep-recenter):
;; 	(counsel-git-grep-action):
;; 	(counsel-M-x): Update.
;; 	(org-agenda-set-tags): Add a declare.
;; 
;; 2015-07-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind "C-M-j" to ivy-immediate-done
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 
;; 	`ivy-immediate-done' will return with the current minibuffer input, even 
;; 	if the input matches a candidate.
;; 
;; 	It was possible so far to call it with "C-u C-j".
;; 
;; 	Fixes #183
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-tag-agenda): New command
;; 
;; 	* counsel.el (counsel-org-tag-agenda): It's just a flet wrapper around
;; 	 `org-agenda-set-tags', changing `org-set-tags' to `counsel-org-tag'.
;; 	(counsel-org-tag-action): Don't use `with-selected-window', since
;; 	`org-agenda-set-tags' will change the buffer for us.
;; 
;; 	Re #177
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (org-bound-and-true-p): Use bound-and-true-p
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a few more Org declarations
;; 
;; 	Re #179
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (org-last-tags-completion-table): Declare
;; 
;; 	Re #179
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (org-setting-tags): Declare dynamic var
;; 
;; 	Re #179
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-from-isearch): New command
;; 
;; 	Fixes #180
;; 
;; 2015-07-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (org-bound-and-true-p): Update declare
;; 
;; 2015-07-27  Erik Hetzner  <egh@e6h.org>
;; 
;; 	Use recoll -t instead of recollq
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-tag): Delete dups
;; 
;; 	The issue of duplicates arises from this setting (off by default):
;; 
;; 	    (setq org-complete-tags-always-offer-all-agenda-tags t)
;; 
;; 	Re #177
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-recoll): Simplify
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-tag): No need to be at heading
;; 
;; 	* counsel.el (counsel-org-tag): When not at heading, move there. Save
;; 	excursion.
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-recoll): New command
;; 
;; 	* counsel.el (counsel-recoll-function): New function.
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-ag): New command
;; 
;; 	* counsel.el (counsel-ag-function): New defun.
;; 	(counsel-git-grep): Update prompt.
;; 
;; 	Going from sync to async now is as simple as:
;; 
;; 	- add :dynamic-collection t
;; 	- replace `shell-command-to-string' with `counsel--async-command'
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update :dynamic-collection to be a boolean
;; 
;; 	* ivy.el (ivy--exhibit): Always use `ivy-state-collection', instead of
;; 	 possibly `ivy-state-dynamic-collection'. The collection function may
;; 	 return nil if it's async and doesn't want to update the minibuffer on
;; 	 exit (to update it later in the sentinel).
;; 
;; 	* counsel.el (counsel-more-chars): New defun.
;; 	(counsel-git-grep-function): Use `counsel-more-chars'; in the async 
;; 	case, return nil.
;; 	(counsel-git-grep): Update :dynamic-collection to a boolean.
;; 	(counsel--gg-sentinel):
;; 	(counsel--async-sentinel): Update to set the candidates to "Error" 
;; 	instead of message "Error" - a lot less distracting this way.
;; 	(counsel-locate-function): Use `counsel-more-chars'; return "Working", 
;; 	since it takes a few seconds to complete a single locate query.
;; 	(counsel-locate): Update.
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--exhibit): Check if in post-command-hook
;; 
;; 	* ivy.el (ivy--exhibit): A situation can occur when an async command
;; 	 calls `ivy--exhibit' in the sentinel. It causes problems when the
;; 	 minibuffer has already exited with "C-g".
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Simplify counsel-git-grep logic
;; 
;; 	* ivy.el (ivy--exhibit): Remove the condition on (eq ivy--full-length
;; 	-1).
;; 
;; 	* counsel.el (counsel-git-grep-function): Simplify.
;; 	(counsel-gg-state): New defvar. Use this instead of
;; 	(setq ivy--full-length -1).
;; 	(counsel--gg-candidates): Set `counsel-gg-state' to -2. There are two 
;; 	async processes to wait for until `ivy--exhibit' can be called:
;; 	- get the candidate count
;; 	- get the candidates Each of the async processes will increase the
;; 	number, and call
;; 	`ivy--exhibit' if the number reaches 0.
;; 	(counsel--gg-sentinel): Update.
;; 	(counsel--gg-count): Update.
;; 
;; 2015-07-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix "DEL" generating a "Quit" sometimes for counsel-git-grep
;; 
;; 	* ivy.el (ivy-backward-kill-word): It seems that `backward-kill-word' is
;; 	 too elaborate; falling back to something simpler fixed the problem.
;; 
;; 2015-07-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow "M-o j" to switch to virtual buffers in other window
;; 
;; 	* ivy.el (ivy--switch-buffer-other-window-action): New defun.
;; 	(ivy-set-actions): Use `ivy--switch-buffer-other-window-action' instead 
;; 	of `switch-to-buffer-other-window'.
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-change-tags): Improve removing tags
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup counsel-org-tag
;; 
;; 	* counsel.el (counsel-org-tag-action): Add ::
;; 	(counsel-org-tag): Set `org-last-tags-completion-table', otherwise
;; 	`org-tags-completion-function' doesn't work.
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-org-tag): Replace org-set-tags
;; 
;; 	* counsel.el (counsel-org-tags): New defvar.
;; 	(counsel-org-change-tags): New defun, adapted from part of
;; 	`org-set-tags'.
;; 	(counsel-org-tag-action): New defun.
;; 	(counsel-org-tag-prompt): New defun.
;; 	(counsel-org-tag): New command.
;; 
;; 	**Using counsel-org-tag**
;; 
;; 	- The prompt is auto-updated to the currently selected tags.
;; 	- Selecting one of the already selected tags removes it from selection.
;; 
;; 	The best shortcut for selecting/removing multiple tags is "C-M-m" (or
;; 	"g" when the "C-o" hydra is active).
;; 
;; 	Re #177 Re #91
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-call): Remove with-selected-window
;; 
;; 	* counsel.el (counsel-git-grep-action): Add with-selected-window.
;; 
;; 	* ivy.el (ivy-dispatching-done): Remove trailing ": ".
;; 	(ivy-switch-buffer): Add extra action "j" calls
;; 	`switch-to-buffer-other-window'. The change `ivy-dispatching-done' had 
;; 	to be done because of this.
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add actions for counsel-describe-function
;; 
;; 2015-07-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add actions for counsel-describe-variable
;; 
;; 2015-07-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-dispatching-done): Add a trailing newline
;; 
;; 2015-07-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-dispatching-done): Display the candidate
;; 
;; 2015-07-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow "C-g" to interrupt ivy-dispatching-done
;; 
;; 	* ivy.el (ivy-dispatching-done): Update.
;; 
;; 2015-07-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--preselect-index): Add matcher to arglist
;; 
;; 	* ivy.el (ivy--reset-state): Call `ivy--preselect-index' with matcher.
;; 	(ivy--preselect-index): In case there's a special matcher set, it 
;; 	affects the candidate list, therefore it affects the preselect index.
;; 
;; 	Fixes #165
;; 
;; 2015-07-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-dispatching-done): New command on "M-o"
;; 
;; 	* ivy.el (ivy-minibuffer-map): Bind "M-o" to `ivy-dispatching-done'.
;; 	(ivy-action-name): Update, all actions are now in hydra's format - key 
;; 	binding, command, hint.
;; 	(ivy-read): The default action is bound to "o" in the dispatch.
;; 	(ivy-switch-buffer): Update to new action format.
;; 
;; 	* counsel.el (counsel-locate):
;; 	(counsel-rhythmbox): Update to new action format.
;; 
;; 	The new interface allows to do whatever you want with the selected 
;; 	candidate with a very short key binding.
;; 
;; 	The old interface with "C-o w/s" still works, but:
;; 
;; 	- it gives a lot more info than necessary for only selecting action
;; 	- doesn't scale well with the number of actions: for 10 actions you
;; 	 would cycle "w/s" a lot.
;; 
;; 	Example with `ivy-switch-buffer':
;; 
;; 	- switch to selected buffer: "C-m"
;; 	- kill selected buffer: "M-o k"; you get a hint right after "M-o".
;; 
;; 	When there is only one action, "M-o" will forward to "C-m".
;; 
;; 2015-07-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-call): Add selected-window work-around for M-x
;; 
;; 	* ivy.el (ivy-call): For some commands that depend on the buffer, like
;; 	`counsel-git-grep' the action needs to be performed in
;; 	`ivy-state-window'. However, this results in wrong window for M-x calc. 
;; 	Add a workaround until I figure out why this happens.
;; 
;; 	Fixes #176
;; 
;; 2015-07-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el: Add featurep for hydra
;; 
;; 	Fixes #174
;; 
;; 2015-07-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-variable-list): Add
;; 
;; 	* counsel.el (counsel-describe-variable): Use `counsel-variable-list'.
;; 
;; 2015-07-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Update avy--goto -> avy-action-goto
;; 
;; 2015-07-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Ignore Man-mode
;; 
;; 2015-07-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-call): Bind to "C-M-m" or "M-RET"
;; 
;; 	"C-M-m" is close to "C-M-n" and "C-M-p", just as "M-RET" is close to
;; 	"RET". Previously, the only binding was "C-o g".
;; 
;; 2015-07-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-count-format): Improve docstring
;; 
;; 	* ivy.el (ivy-minibuffer-grow):
;; 	(ivy-toggle-calling):
;; 	(ivy-sort-functions-alist): Checkdoc.
;; 
;; 2015-07-11  Erik Hetzner  <egh@e6h.org>
;; 
;; 	Allow % in prompt string
;; 
;; 	- quote % when passing prompt from ivy-completing-read to ivy-read
;; 	- add documentation in ivy-read that all % should be quoted
;; 
;; 2015-07-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-rhythmbox-history): Add
;; 
;; 	* counsel.el (counsel-rhythmbox): Update.
;; 
;; 2015-07-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Improve ivy-set-actions interaction
;; 
;; 	* ivy.el (ivy-read): When the base action is already a list, merge it
;; 	 with the one obtained from `ivy-set-actions'.
;; 
;; 2015-07-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add counsel-rhythmbox
;; 
;; 	* counsel.el (counsel-completion-beg):
;; 	(counsel-completion-end): Move declarations before first use.
;; 	(dired-jump): Declare.
;; 	(counsel-rhythmbox-enqueue-song): New defun.
;; 	(counsel-rhythmbox): New command. Requires `helm-rhythmbox' package, and 
;; 	Rhythmbox, obviously.
;; 
;; 	* ivy.el (ivy-call): Make interactive. Add special handling for the case
;; 	 when the collection is an alist. In that case, call the action not
;; 	 with the collection item, but with the cdr of said item. A bit weird,
;; 	 but that's the way Helm does it, and doing it in the same way means
;; 	 the action functions are cross-compatible.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Bind "g" to call the current action on
;; 	 current candidate without exiting.
;; 
;; 	Now it's possible to make a query to Rhythmbox, "C-o" and navigate to a 
;; 	song with "j" and "k". Try the song with "g".  Or use "s" once and then 
;; 	enqueue different songs with e.g. "jjgjjjgjgkkg".
;; 
;; 2015-07-07  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex): Improve for trailing backslash
;; 
;; 	When there's a single trailing backslash, which would result in a bad 
;; 	regex, ignore it.
;; 
;; 2015-07-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a new interface to customize additional exit points
;; 
;; 	* ivy.el (ivy--actions-list): New defvar. Store the exit points per
;; 	 command.
;; 	(ivy-set-actions): New defun. Use this to set the extra exit points for 
;; 	each command.
;; 	(ivy-read): Account for `ivy--actions-list'.
;; 	(ivy-switch-buffer): Set extra action to kill the buffer. Update the 
;; 	call to `ivy-read'.
;; 
;; 	* counsel.el (counsel-locate): Use the single action in the function and
;; 	 customize the rest via `ivy-set-actions'.
;; 
;; 	Re #164
;; 
;; 2015-07-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-locate-history): Add
;; 
;; 2015-07-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update index formatting logic
;; 
;; 	* ivy.el (ivy--reset-state): Update.
;; 	(ivy--insert-prompt): Simplify.
;; 
;; 	If you want to see both the index and the length of the candidates, 
;; 	instead of just the length, it can be done like this:
;; 
;; 	    (setq ivy-count-format "%d/%d ")
;; 
;; 	Each "%d" is replaced appropriately due to the total length of the 
;; 	candidates. For instance, this one can result in "%4d/%-4d M-x ".
;; 
;; 	Re #167
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to see the candidate index via ivy-count-format
;; 
;; 	* ivy.el (ivy--insert-prompt): Update.
;; 
;; 	To use this feature, use something like this:
;; 
;; 	    (setq ivy-count-format "(%d/%d)")
;; 
;; 	Basically two number specifiers instead of the usual one. The problem 
;; 	with this approach is that the prompt length will change as you scroll 
;; 	e.g. from 9 to 10, which is uncomfortable.
;; 
;; 	Fixes #167
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--reset-state): Fixup
;; 
;; 	Re #165
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Don't put empty string on history
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind case-fold-search to t when the input is all lower-case
;; 
;; 	* ivy.el (ivy--filter): Update.
;; 
;; 	* ivy-test.el (ivy--filter): Add test.
;; 
;; 	- input "the" matches both "the" and "The".
;; 	- input "The" matches only "The".
;; 
;; 	Fixes #166
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--reset-state): Fixup
;; 
;; 2015-07-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make ffap work again
;; 
;; 	* ivy.el (ivy--reset-state): When completing files, consider the case
;; 	 when the directory of PRESELECT isn't `default-directory'.
;; 
;; 	Fixes #165
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-switch-buffer): Add a multi-action interface
;; 
;; 	While in "C-o":
;; 
;; 	- Use "s" to make "C-m", "C-j", "C-M-n" and "C-M-p" kill
;; 	- Use "w" to switch back to normal.
;; 
;; 	Re #164
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a multi-action interface for counsel-locate
;; 
;; 	* ivy-hydra.el (hydra-ivy): Display the current action and allow to
;; 	 scroll the action list with "w" and "s".
;; 
;; 	* ivy.el (ivy--get-action): New defun, a getter for the action function,
;; 	 since it can also be a list now.
;; 	(ivy--actionp): New defun, checks for the action list.
;; 	(ivy-next-action): New command, scrolls to the next action in the list.
;; 	(ivy-prev-action): New command, scrolls to the previous action in the 
;; 	list.
;; 	(ivy-action-name): New defun.
;; 	(ivy-call): Use `ivy--get-action'.
;; 	(ivy-read): Use `ivy--get-action'.
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup the last two commits
;; 
;; 	* counsel.el (counsel-find-file): Update.
;; 
;; 	* ivy.el (ivy--buffer-list): Update.
;; 
;; 	Re #164
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a custom keymap for counsel-find-file
;; 
;; 	* counsel.el (counsel-find-file-map): New defvar.
;; 
;; 	Re #164
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a custom keymap for ivy-switch-buffer
;; 
;; 	* ivy.el (ivy-switch-buffer-map): New defvar.
;; 
;; 	Re #164
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-restrict-to-matches): Add and bind to "S-SPC"
;; 
;; 2015-06-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make counsel-locate use a process
;; 
;; 	* counsel.el (counsel-locate-function): Update.
;; 	(counsel--async-command): New defun.
;; 	(counsel--async-sentinel): New defun.
;; 	(counsel-locate): Switch to :action, thus allowing "C-M-n" and
;; 	`ivy-resume'.
;; 
;; 	* swiper.el: Bump version.
;; 
;; 2015-06-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el (hydra-ivy): Bind "C-o" to be a toggle
;; 
;; 	It makes sense for "C-o" to be a toggle, instead of just going one way.
;; 
;; 2015-06-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make counsel-el work with "C-M-n" and "C-M-p"
;; 
;; 	* counsel.el (counsel-el): Use the whole obarray if no initial input is
;; 	 given. Filter out only function when appropriate.
;; 	(counsel-completion-beg): New defvar.
;; 	(counsel-completion-end): New defvar.
;; 	(counsel--el-action): New defun.
;; 
;; 	* ivy.el (ivy--reset-state): Set `ivy--full-length' to nil.
;; 
;; 2015-06-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the initial input bug introduced with "C-r"
;; 
;; 	* ivy.el (ivy-read): Use (ivy-state-initial-input ivy-last).
;; 	(ivy--reset-state): Set (ivy-state-initial-input ivy-last).
;; 
;; 	Fixes #162
;; 
;; 2015-06-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-find-file): Use `file-name-history'
;; 
;; 	* counsel.el (package-installed-p): Declare.
;; 
;; 2015-06-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-history): New defvar
;; 
;; 	* counsel.el (counsel-git-grep): Use `counsel-git-grep-history'.
;; 
;; 2015-06-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-history): New defvar
;; 
;; 	* swiper.el (swiper--ivy): Use `swiper-history'.
;; 
;; 	Allows to get more use of "M-p", "M-n" and "C-r".
;; 
;; 2015-06-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to recursively match history with "C-r"
;; 
;; 	* ivy.el (ivy-minibuffer-map): Rebind "C-r" from
;; 	 `ivy-previous-line-or-history' to `ivy-reverse-i-search'. "C-r"
;; 	 binding was redundant, since "C-p" does almost the same.
;; 	(ivy-read): Separate the functionality that sets the global state based 
;; 	on `ivy-last'.
;; 	(ivy--reset-state): New defun. Move all the global state setup here.
;; 	(ivy-reverse-i-search): New command. This is very similar to "C-r" in 
;; 	bash - allows to match for history elements, instead of just scrolling 
;; 	through them with "M-p" and "M-n".
;; 
;; 2015-06-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup compilation warnings related to smex
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-unicode-char): Use action-style call
;; 
;; 	Fixes #160
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-load-theme): New command
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Avoid compilation warning
;; 
;; 	* counsel.el (counsel-M-x): Use `command-execute' instead of
;; 	 `execute-extended-command'.
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix last commit being incompatible with older Emacs
;; 
;; 	* ivy.el (ivy--format): Use `add-face-text-property' only when it's
;; 	 bound.
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix color blending for composite faces
;; 
;; 	colir.el (colir-blend-face-background): Try to find the face among the 
;; 	properties.
;; 
;; 	Re #151
;; 
;; 2015-06-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Re-scale the text height to default in the minibuffer
;; 
;; 	* ivy.el (ivy--format): Set the string height to default and turn off
;; 	 overline, so that exactly `ivy-height' lines are visible, not less.
;; 
;; 	Fixes #151
;; 
;; 2015-06-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el (hydra-ivy): Bind "C-g"
;; 
;; 	To make sure that "C-g" really exits the hydra.
;; 
;; 2015-06-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-initial-inputs-alist): Add some Org commands
;; 
;; 	* ivy.el (ivy-initial-inputs-alist): Add `org-agenda-refile' and
;; 	 `org-capture-refile'.
;; 
;; 	Fixes #156
;; 
;; 2015-06-19  Kaushal Modi  <kaushal.modi@gmail.com>
;; 
;; 	Fix the case where file name can contain ~
;; 
;; 	- The fix make opening files like init.el~ now possible. Earlier,
;; 	 hitting that last ~ char switch the dir to ~/
;; 	- This commit will now make that cd to ~/ only if ~ is the first char in
;; 	 the search term
;; 
;; 2015-06-19  Greg Lucas	<greg@glucas.net>
;; 
;; 	Match drive letter at start of current directory
;; 
;; 	When looking for the root of the current drive, make sure we only match
;; 	a drive letter at the beginning of the path.
;; 
;; 2015-06-19  Greg Lucas	<greg@glucas.net>
;; 
;; 	Add support for Windows drive letters
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve performance for "^" initial input
;; 
;; 	ivy.el (ivy--filter): There's no need to anchor when the previous regex 
;; 	is "^" (matches everything). The result will be index 0 anyway, but 
;; 	without this optimization it can be slow for ~30k candidates.
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Enable recursive minibuffers
;; 
;; 	Re #145
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Find file if given a full tramp path
;; 
;; 	* ivy.el (ivy-alt-done): Add another cond branch for `ivy-text' matching
;; 	 a full remote file path.
;; 
;; 	Re #145
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't cut off "/ssh:foo" input
;; 
;; 	* ivy.el (ivy-alt-done): With the example input, offer a completion for
;; 	 known remotes with the initial input "foo".
;; 
;; 	Re #145
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add better positioning to counsel-git-grep finalizer
;; 
;; 	counsel.el (counsel-git-grep-action): Use a regex instead of just 
;; 	splitting the string on ":". Additionally, goto match, not just the line 
;; 	of the match.
;; 
;; 	Fixes #153
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make counsel-M-x respect ivy-format-function
;; 
;; 	* counsel.el (counsel--format-function-M-x): Remove defun.
;; 	(counsel--M-x-transformer): New defun.
;; 	(counsel-M-x): Temporarily bind `ivy-format-function' to apply
;; 	`counsel--M-x-transformer' beforehand.
;; 
;; 	* ivy.el (ivy-format-function-arrow): Update style.
;; 
;; 	Fixes #150
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix non-file completions ability to enter tramp completion
;; 
;; 	* ivy.el (ivy-alt-done): Update.
;; 
;; 	Re #145
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"M-i" should not switch directories
;; 
;; 	ivy.el (ivy-insert-current): When the current candidate is a directory, 
;; 	just insert its name without the last "/". The user can insert "/" to 
;; 	switch to that directory if necessary.
;; 
;; 	Re #141
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add "^" as initial input to "C-h f" and "C-h v"
;; 
;; 	* ivy.el (ivy-initial-inputs-alist): Add entries for
;; 	 `counsel-describe-function' and `counsel-describe-variable'.
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-kill-line): Add and bind to "C-k"
;; 
;; 	The only difference to `kill-line' is that it will kill the whole input 
;; 	when at the end of the minibuffer. In that case, the regular `kill-line' 
;; 	was extending into the second line of the minibuffer, which is 
;; 	unacceptable.
;; 
;; 2015-06-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a set of commands for resizing minibuffer height
;; 
;; 	* ivy.el (ivy-minibuffer-grow): New command.
;; 	(ivy-minibuffer-shrink): New command.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Bind "<" and ">".
;; 
;; 	Use "C-o >>>>>" to grow the minibuffer, and "C-o <<<<<" to shrink it.
;; 
;; 	Re #151
;; 
;; 2015-06-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Put the file instead of partial input on history
;; 
;; 	* ivy.el (ivy-read): When completing file names, put the whole file name 
;; 	on history, not just the partial input that lead to that name. This is
;; 	important in order for `ivy--cd-maybe' to work.
;; 
;; 	Re #152
;; 
;; 2015-06-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"M-n", "M-p", "M-i" should switch directories when needed
;; 
;; 	* ivy.el (ivy-previous-history-element):
;; 	(ivy-next-history-element):
;; 	(ivy-switch-buffer): Call `ivy--cd-maybe'.
;; 	(ivy--cd-maybe): New defun. Check if the current input points to a 
;; 	different directory than `ivy--directory'. If so, `ivy--cd' there.
;; 
;; 	Fixes #152
;; 
;; 2015-06-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Fixup smex interaction
;; 
;; 	* counsel.el (counsel-M-x): Use `smex-rank' only if smex is installed.
;; 
;; 	Fixes #147
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Fixup
;; 
;; 	Re #136
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el (defhydra): Wrap in eval-when-compile
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Swiper should not deactivate-mark
;; 
;; 	* swiper.el (swiper--init): Update to make it the same as `isearch'.
;; 	"C-SPC" + `swiper' should work to mark a region.
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el: Improve for hydra not installed
;; 
;; 	* ivy-hydra.el (hydra): No error on require.
;; 	(package-installed-p): Enable recursive minibuffers.
;; 	(hydra-ivy): Use ASCII char instead of Unicode, since the char width may 
;; 	cause misalignment.
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-query-replace): Don't miss the first
;; 
;; 	* swiper.el (swiper-query-replace): Since the point is always after the
;; 	 matching thing in swiper, it's necessary to move it before it in order
;; 	 for `perform-replace' not to skip it.
;; 
;; 	Fixes #144
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Require TRAMP in time
;; 
;; 	* ivy.el (ivy-alt-done): Require tramp before use. Store `ivy-last'
;; 	 before calling `ivy-read', since each `ivy-read' overwrites
;; 	 `ivy-last', and this one overwrites `counsel-find-file' action.
;; 
;; 	Fixes #145
;; 
;; 2015-06-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Call smex-rank
;; 
;; 	Re #136
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-hydra.el (hydra-ivy): Add "C-j" and "C-m" exit points
;; 
;; 	Just to make sure that the hydra exits.
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to toggle matching mode with "C-o m"
;; 
;; 	* ivy.el (ivy-toggle-fuzzy): New command.
;; 
;; 	* ivy-hydra.el (hydra-ivy): Bind `ivy-toggle-fuzzy' to "m".
;; 
;; 	Fixes #142.
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-sort-functions-alist): Work for commands as well
;; 
;; 	* ivy.el (ivy-sort-functions-alist): Examine `this-command' in addition
;; 	 to the COLLECTION arg of `completing-read'. Add `Man-goto-section' and
;; 	 `org-refile' to the list, since these commands collect the candidates
;; 	 in the order in which they are in the buffer => the candidates must
;; 	 not be sorted. Mention this in the doc.
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-initial-inputs-alist): Add man and woman
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the minibuffer being too small with enough candidates
;; 
;; 	* ivy.el (ivy--format): Fix the bug of getting the minibuffer height
;; 	 less than `ivy-height' when `ivy--index' was between `ivy--length'
;; 	 and (- ivy--length (/ ivy--height 2)).
;; 
;; 	* ivy-test.el (ivy--format): Add test.
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-insert-current): Add and bind to "M-i"
;; 
;; 	Use "M-i" if you want something close to the current candidate. You can 
;; 	follow up with an edit and select.
;; 
;; 	Fixes #141
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix yank/undo bug
;; 
;; 	* ivy.el (ivy--insert-minibuffer): Bind `buffer-undo-list' later. 
;; 	Previously, "C-y C-u" would result in the first char of yanked text not 
;; 	being undone.
;; 
;; 2015-06-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the initial input for all commands
;; 
;; 	* ivy.el (ivy-initial-inputs-alist): New defvar. Customize this to get
;; 	 an initial input in any command.
;; 	(ivy-read): Unless INTIAL-INPUT is given, look it up in
;; 	`ivy-initial-inputs-alist' based on `this-command'.
;; 
;; 	* counsel.el (counsel-M-x-initial-input): Remove defcustom. It's
;; 	 superseded by `ivy-initial-inputs-alist'.
;; 	(counsel-M-x): Update.
;; 
;; 	Fixes #140
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex-fuzzy): Improve for "^" and "$"
;; 
;; 	* ivy.el (ivy--regex-fuzzy): Don't insert .* after ^ and before $.
;; 
;; 	* ivy-test.el (ivy--regex-fuzzy): Add test.
;; 
;; 	Fixes #139
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (hydra-ivy/body): Autoload
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Call smex-initialize
;; 
;; 	Otherwise, smex-cache isn't defined.
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind "C-o" to hydra-ivy/body
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 
;; 	* ivy-hydra.el (hydra-ivy): New defhydra.
;; 
;; 	Add shortcuts:
;; 
;; 	"C-n" -> "j"
;; 	"C-p" -> "k"
;; 	"M-<" -> "h"
;; 	"M->" -> "l"
;; 	"C-j" -> "f"
;; 	"C-m" -> "d"
;; 	"C-g" -> "o" cancel "C-o" -> "i" toggle calling -> "c"
;; 
;; 	The hydra doesn't inhibit other bindings, so "C-v" and "M-v" also work 
;; 	when you toggle calling on with "c".
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-toggle-calling: Toggle calling "RET" action for current candidate
;; 
;; 	* ivy.el (ivy-calling): New defvar.
;; 	(ivy-set-index): New defun - a setter for `ivy--index' that can call the 
;; 	current action when `ivy-calling' isn't nil.
;; 	(ivy-beginning-of-buffer):
;; 	(ivy-end-of-buffer):
;; 	(ivy-scroll-up-command):
;; 	(ivy-scroll-down-command):
;; 	(ivy-next-line):
;; 	(ivy-previous-line): Use `ivy-set-index' instead of a plain `setq'.
;; 	(ivy-toggle-calling): New defun - toggle `ivy-calling'.
;; 	(ivy-call): New defun - call the current action.
;; 	(ivy-next-line-and-call): Use `ivy-call'.
;; 	(ivy-previous-line-and-call): Use `ivy-call'.
;; 	(ivy-read): Reset `ivy-calling' to nil.
;; 
;; 	To make use of this functionality, bind `ivy-toggle-calling' in
;; 	`ivy-minibuffer-map'. After this, "C-n" will behave like "C-M-n" etc.
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Replace "C-x 6" with "<f2>" in counsel-M-x
;; 
;; 	counsel.el (counsel--format-function-M-x): Update.
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-find-file-ignore-regexp): Default to nil
;; 
;; 	* counsel.el (counsel--find-file-matcher): Update.
;; 
;; 	Make the default behavior more similar to `find-file'. Move the previous
;; 	value to the docstring.
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Add a bunch of autoload cookies
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x-initial-input): New defcustom
;; 
;; 	* counsel.el (counsel-M-x): Use `counsel-M-x-initial-input'.
;; 
;; 	Re #138
;; 
;; 2015-06-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow "TAB" to complete when input starts with "^"
;; 
;; 	* ivy.el (ivy-partial): Strip "^" when forwarding to `try-completion'. 
;; 	Afterwards, put it back.
;; 
;; 	Fixes #138
;; 
;; 2015-06-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup ivy-resume for file completion
;; 
;; 	* ivy.el (ivy-resume): No longer add the preselect.
;; 	(ivy-read): Don't add initial-input "".
;; 
;; 2015-06-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add fuzzy matching function
;; 
;; 	ivy.el (ivy--regex-fuzzy): New defun.
;; 
;; 	To enable fuzzy matching, set your `ivy-re-builders-alist' accordingly:
;; 
;; 	(setq ivy-re-builders-alist
;; 	     '((t . ivy--regex-fuzzy)))
;; 
;; 	Re #136
;; 
;; 2015-06-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): Piggyback on smex for sorting
;; 
;; 	* counsel.el (counsel-M-x): When smex is present, use it for sorting the
;; 	 candidates. Also use `counsel-describe-map', so that "C-." and "C-,"
;; 	 work for commands.
;; 
;; 	Re #136
;; 
;; 2015-06-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-M-x): New command
;; 
;; 	* counsel.el (counsel--format-function-M-x): New defun.
;; 
;; 	Re #136.
;; 
;; 2015-06-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-symbol-at-point): Improve
;; 
;; 	Fixes #137
;; 
;; 2015-06-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a hack for kill-buffer and invisible buffer
;; 
;; 	* ivy.el (ivy-read): When COLLECTION is 'internal-complete-buffer,
;; 	 ignore the fact that REQUIRE-MATCH was set to t.
;; 	 Normally, when REQUIRE-MATCH is t, the COLLECTION should not be
;; 	 extended with PRESELECT.
;; 
;; 	Fixes #135
;; 
;; 2015-06-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Account for minibuffer-depth-indication-mode
;; 
;; 	* ivy.el (ivy--insert-prompt): When `minibuffer-depth-indication-mode'
;; 	 is on, and `minibuffer-depth' is more than 1, prepend it to prompt.
;; 
;; 	Fixes #134
;; 
;; 2015-06-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--switch-buffer-action): Add work-around
;; 
;; 	If BUFFER is live, and can also be virtual, don't open the virtual one. 
;; 	This work-around should be disabled once uniquify is added to buffer
;; 	list.
;; 
;; 2015-06-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel-git-grep should quote strings better
;; 
;; 	* counsel.el (counsel-git-grep-function):
;; 	(counsel--gg-candidates): Update.
;; 
;; 	Fixes an errror when the input has a " in it.
;; 
;; 2015-06-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-minibuffer-map): Bind ivy-yank-word to "M-j"
;; 
;; 	Re #133
;; 
;; 2015-06-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make counsel-git-grep fully async
;; 
;; 	* counsel.el (counsel-git-grep-count): Rename to `counsel--gg-count' and
;; 	 make it async.
;; 	(counsel-git-grep-function): Set `ivy--full-length' to -1. It means that
;; 	`ivy--exhibit' should do nothing until the length is re-computed.
;; 	(counsel-git-grep): Use the sync version of `counsel-git-grep-count' for 
;; 	the initial repo line count.
;; 	(counsel--gg-candidates): New defun. When called, kill the previous git
;; 	grep process and start a new one. The sentinel will insert the 
;; 	candidates, bypassing the `ivy--exhibit'.
;; 	(counsel--gg-sentinel): New defun.
;; 	(counsel--gg-count): Rename from `counsel-git-grep-count'. When finished 
;; 	computing, redisplay.
;; 
;; 	* ivy.el (ivy--exhibit): Don't expect dynamic collection to return the
;; 	 candidates as before. Just call it and expect it to redisplay the
;; 	 minibuffer.
;; 
;; 2015-06-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup compilation warnings
;; 
;; 2015-06-04  Tassilo Horn  <tsdh@gnu.org>
;; 
;; 	Regexp-quote name of candidate buffer to be preselected
;; 
;; 	Fixes #128
;; 
;; 2015-06-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-virtual): New defface
;; 
;; 	* ivy.el (ivy--virtual-buffers): Use `ivy-virtual'. No need for
;; 	`ido-use-faces' approach, the user can just customize
;; 	`ivy-virtual' to look like `default' if needed.
;; 
;; 	Fixes #129
;; 
;; 2015-06-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--done): Set ivy--current
;; 
;; 	Fixes a bug of using :action for completing file names.
;; 
;; 2015-06-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Handle symbol-at-point better in non-Elisp buffers
;; 
;; 	* counsel.el (counsel-symbol-at-point): New defun.
;; 	(counsel-describe-variable): Update.
;; 	(counsel-describe-function): Update.
;; 
;; 	Fixes #126
;; 
;; 2015-06-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Swiper should preserve column for empty input
;; 
;; 	swiper.el (swiper--update-input-ivy): When there's no input yet, don't 
;; 	move point.
;; 
;; 	Re #125
;; 
;; 2015-06-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-yank-word): New command
;; 
;; 	* swiper.el (swiper--update-input-ivy): Move point to current regex, not
;; 	 just current line.
;; 
;; 	Gives a behavior similar to "C-w" of `isearch'. Possible binding:
;; 
;; 	    (define-key ivy-minibuffer-map (kbd "C-w") 'ivy-yank-word)
;; 
;; 	Fixes #125
;; 
;; 2015-06-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-recentf): New command
;; 
;; 	Fixes #124
;; 
;; 2015-05-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-find-file-at-point): New defcustom
;; 
;; 	* counsel.el (counsel-find-file): When `counsel-find-file-at-point' is
;; 	 non-nil, add the file at point to the list of candidates.
;; 
;; 	Fixes #123
;; 
;; 2015-05-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-find-file): Extend `find-file'
;; 
;; 	* counsel.el (counsel-find-file): Forward to `find-file', with Ivy
;; 	 completion. `ivy-next-line-and-call' as well as `ivy-resume' should
;; 	 work.
;; 	(counsel--find-file-matcher): New defun.
;; 	(counsel-find-file-ignore-regexp): Regexp of files to ignore.
;; 
;; 	Fixes #122
;; 
;; 	Recommended binding:
;; 
;; 	(global-set-key (kbd "C-x C-f") 'counsel-find-file)
;; 
;; 	Peek at files with "C-M-n" and "C-M-p". Input a leading dot to see all 
;; 	files.
;; 
;; 2015-05-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-info-lookup-symbol): Add a require
;; 
;; 	In case it's called non-interactively.
;; 
;; 2015-05-28  Tassilo Horn  <tsdh@gnu.org>
;; 
;; 	Add info lookup binding to counsel-describe-map
;; 
;; 	* counsel.el (counsel-describe-map): Bind C-, to 
;; 	counsel--info-lookup-symbol.
;; 	(counsel--info-lookup-symbol): New command.  Just sets the ivy action to 
;; 	counsel-info-lookup-symbol.
;; 
;; 2015-05-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Change the :matcher interface
;; 
;; 	* ivy.el (ivy--filter): The matcher is now a function that takes a
;; 	 regexp and candidates and returns the filtered candidates.
;; 
;; 	* counsel.el (counsel-git-grep-matcher): Cache matched candidates. This
;; 	 is very important for "C-n" / "C-p", especially near the threshold
;; 	 where a switch to :dynamic-collection is made.
;; 
;; 2015-05-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Avoid ensuring font lock when magit-blame-mode is active
;; 
;; 	swiper.el (swiper-font-lock-ensure): Update.
;; 
;; 2015-05-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to open an Info file on the file system
;; 
;; 	* ivy.el (ivy-alt-done): Update.
;; 
;; 	When in Info-mode, press "g" and select either "(./)" or "(../)" to 
;; 	switch to file name completion. That file will be opened with Info.
;; 
;; 2015-05-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Don't double-quote preselect
;; 
;; 	The :preselect is already quoted in `ivy--preselect-index'.
;; 
;; 2015-05-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-avy): Don't start on empty input
;; 
;; 	Fixes abo-abo/avy#50
;; 
;; 2015-05-24  Ingo Lohmar	 <i.lohmar@gmail.com>
;; 
;; 	ivy.el (ivy-next-line): Fix wraparound at end of candidates
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-avy): Use only the current window
;; 
;; 	Fixes #117
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Bump version
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add a secion on Ivy
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	The :action parameter to ivy-read should take one arg
;; 
;; 	* ivy.el (ivy-next-line-and-call): Update.
;; 	(ivy-previous-line-and-call): Update.
;; 	(ivy-read): Update.
;; 	(ivy--switch-buffer-action): Update.
;; 
;; 	* swiper.el (swiper-query-replace): Update.
;; 
;; 	* counsel.el (counsel--find-symbol): Update.
;; 	(counsel-describe-variable): Update.
;; 	(counsel-describe-function): Update.
;; 	(counsel-git): Update.
;; 	(counsel-git-grep-action): Update.
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup "C-u C-j" for `ivy-switch-buffer'
;; 
;; 	ivy.el (ivy-immediate-done): Since action-style call is used now,
;; 	`ivy--current' must be set to `ivy-test', since it's `ivy--current' that 
;; 	will count as completion result.
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git): Switch to action-style call
;; 
;; 	This allows "C-M-n" and "C-M-p" to be used.
;; 
;; 	Re #114
;; 
;; 2015-05-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completing-read): Check for a cons initial-input
;; 
;; 2015-05-23  Stefan Monnier  <monnier@iro.umontreal.ca>
;; 
;; 	* swiper/ivy.el: Clean up regexps and pseudo-closures
;; 
;; 	Don't require cl-lib twice.
;; 	(ivy-read, ivy--filter): Use closures instead of `(lambda ...).
;; 	(ivy--format, ivy--filter, ivy--exhibit, ivy--insert-prompt)
;; 	(ivy--regex-ignore-order, ivy--regex, ivy--sorted-files)
;; 	(ivy-partial-or-done, ivy-alt-done): Don't use ^/$ to match string
;; 	bounds.
;; 
;; 2015-05-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup compilation warnings
;; 
;; 2015-05-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	When building a regex, consider ^ only at start
;; 
;; 	swiper.el (swiper--re-builder): Update.
;; 
;; 2015-05-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-info-lookup-symbol): Turn on sorting
;; 
;; 2015-05-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't try to call permanent action if there's none
;; 
;; 	* ivy.el (ivy-next-line-and-call): Update.
;; 	(ivy-previous-line-and-call): Update.
;; 
;; 	Fixes #114.
;; 
;; 2015-05-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-forward-char): Add and bind to "C-f"
;; 
;; 	This is to avoid problems for the ido-related "C-x C-f C-f" reflex.
;; 
;; 2015-05-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't error on incomplete bad regexp in counsel-git-grep
;; 
;; 	counsel.el (counsel-git-grep-matcher): Update.
;; 
;; 2015-05-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep): Warn if not in a repository
;; 
;; 2015-05-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-kill-word): Add and bind to "M-d"
;; 
;; 	Fixes #94
;; 
;; 2015-05-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add sample init
;; 
;; 	Fixes #112
;; 
;; 2015-05-15  __rompy  <rompy.under@gmail.com>
;; 
;; 	Fixed ivy--preselect-index on windows where the drives folders ends with
;; 	a backslash (C:\, D:\)
;; 
;; 2015-05-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update the way spaces are quoted using ivy
;; 
;; 	* ivy.el (ivy--split): Split only on single spaces. From all other space
;; 	 groups, remove one space.
;; 
;; 	* ivy-test.el (ivy--split): Add test.
;; 
;; 	Fixes #109
;; 
;; 2015-05-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): More predictability
;; 
;; 	* ivy.el (ivy-partial-or-done): Forward to `ivy-alt-done' only if
;; 	 `ivy-partial' did nothing new, and either previous command was
;; 	 `ivy-partial-or-done', or there's exactly one matching candidate.
;; 
;; 	Fixes #107
;; 
;; 2015-05-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to recenter with "C-l" during counsel-git-grep
;; 
;; 	* counsel.el (counsel-git-grep-map): New defvar.
;; 	(counsel-git-grep-recenter): New command.
;; 	(counsel-git-grep-action): New defun.
;; 	(counsel-git-grep): Update.
;; 
;; 	Fixes #103
;; 
;; 2015-05-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): Update doc
;; 
;; 	Re #105
;; 
;; 2015-05-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): Always forward to `ivy-alt-done'
;; 
;; 	Fixes #105
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-delete-char): Add and bind to "C-d"
;; 
;; 	`delete-char' must not be called when at end of line, since that would 
;; 	bring the first candidate into the input.
;; 
;; 	Fixes #94
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-switch-buffer): Preselect other-buffer
;; 
;; 	* ivy.el (ivy-switch-buffer): Preselect other buffer, just like
;; 	 `switch-to-buffer' does it.
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Keep the last ivy--index for :dynamic-collection
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel-git-grep now works with ivy-resume
;; 
;; 	* ivy.el (ivy-state): New field DYNAMIC-COLLECTION.
;; 	(ivy-resume): Update.
;; 	(ivy-read): New argument DYNAMIC-COLLECTION. When this is non-nil, 
;; 	ignore collection and matchers etc, and just obtain the filtered 
;; 	candidates by calling DYNAMIC-COLLECTION each time the input changes.
;; 
;; 	Fixes #100
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Introduce :matcher for counsel-git-grep
;; 
;; 	* ivy.el (ivy-state): Add MATCHER field.
;; 	(ivy-resume): Update.
;; 	(ivy-read): Add MATCHER argument. To make things faster, MATCHER can 
;; 	reuse `ivy--old-re', but it's not required. MATCHER is a function that 
;; 	takes a candidate and returns non-nil if it matches.
;; 
;; 	* counsel.el (counsel-git-grep): Use :matcher.
;; 	(counsel-git-grep-matcher): New defun. Skip the file name and line 
;; 	number, then match as usual.
;; 
;; 	Fixes #99
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Forward to minibuffer-complete for filenames only if "^/"
;; 
;; 	* ivy.el (ivy-partial-or-done): Update.
;; 
;; 	Fixes #102
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Properly update virtual buffers for "^ " interaction
;; 
;; 	* ivy.el (ivy-read): Use `ivy--buffer-list'.
;; 	(ivy--exhibit): Use `ivy--buffer-list'.
;; 	(ivy-add-virtual-buffers): Remove.
;; 	(ivy--buffer-list): New defun.
;; 
;; 	Re #68
;; 
;; 2015-05-12  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the error switching to non-existent buffers
;; 
;; 	* ivy.el (ivy-read): Use `ivy-add-virtual-buffers'.
;; 	(ivy-buffer-list): Remove.
;; 	(ivy-add-virtual-buffers): New defun.
;; 	(ivy--switch-buffer-action): New defun, consider `ivy--current' being 
;; 	zero length.
;; 	(ivy-switch-buffer): Use `ivy--switch-buffer-action'.
;; 
;; 	Fixes #101
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): Fixup
;; 
;; 	* ivy.el (ivy-partial-or-done): Switch `default-directory' so that
;; 	 `minibuffer-complete' is aware of it. Select a directory only if there
;; 	 is only one.
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): Fixup
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	When completing file names, defer to `minibuffer-complete' for "TAB"
;; 
;; 	* ivy.el (ivy-partial-or-done): Call `minibuffer-complete'. If the
;; 	 resulting text is a valid directory, move there.
;; 	(ivy-read): Setup `minibuffer-completion-table' and
;; 	`minibuffer-completion-predicate'. This makes `minibuffer-complete' 
;; 	work.
;; 
;; 	Fixes #92
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Ignore fundamental-mode
;; 
;; 	ELP uses this.
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the minibuffer formatter
;; 
;; 	* ivy.el (ivy-format-function): New defvar.
;; 	(ivy-format-function-default): New defun.
;; 	(ivy-format-function-arrow): New defun, alternative for
;; 	`ivy-format-function'.
;; 
;; 	Fixes #87
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update test
;; 
;; 	ivy-test.el (swiper--re-builder): Rename from `ivy--transform-re'.
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Swiper should use the :re-builder argument
;; 
;; 	* ivy.el (ivy--transform-re): Remove defun, :re-builder should be used
;; 	 for this logic.
;; 	(ivy--filter): Update.
;; 
;; 	* swiper.el (swiper-avy): Use `ivy--regex'.
;; 	(swiper--init): Don't set `ivy--regex-function' - it will be set by
;; 	:re-builder.
;; 	(swiper--re-builder): New defun.
;; 	(swiper--ivy): Use :re-builder in call to `ivy-read'.
;; 	(swiper--update-input-ivy): Use `ivy--regex'.
;; 	(swiper--action): Use `ivy--regex'.
;; 
;; 	Fixes #90
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Add a re-builder argument
;; 
;; 	* ivy.el (ivy-state): Add a RE-BUILDER field.
;; 	(ivy-resume): Use RE-BUILDER field.
;; 	(ivy-read): Set `ivy--regex-function' to RE-BUILDER if it's given.
;; 
;; 2015-05-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-backward-kill-word): Add and bind to "M-DEL"
;; 
;; 	Fixes #94
;; 
;; 2015-05-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the transition from a bad regex to good one
;; 
;; 	* ivy.el (ivy--filter): Update.
;; 
;; 	Fixes #93
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Declare swiper-map
;; 
;; 	Fixes #90
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Rename avy-swiper to swiper-avy
;; 
;; 	* swiper.el (swiper-avy): Rename and fix the regex.
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-use-virtual-buffers): New defcustom
;; 
;; 	Re #84
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add support for virtual buffers
;; 
;; 	* ivy.el (ivy-mode-map): New defvar. Remap `switch-to-buffer' to
;; 	 `ivy-switch-buffer'.
;; 	(ivy-mode): Use `ivy-mode-map'.
;; 	(ivy--virtual-buffers): New devar.
;; 	(ivy--virtual-buffers): New defun.
;; 	(ivy-buffer-list): Return a list of buffers, taking
;; 	`ido-use-virtual-buffers' into account.
;; 	(ivy-switch-buffer): New command.
;; 
;; 	Fixes #84
;; 
;; 2015-05-08  Tassilo Horn  <tsdh@gnu.org>
;; 
;; 	Simplify ivy-partial-or-done
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add swiper -> avy finalizer
;; 
;; 	* ivy.el (ivy-quit-and-run): New defmacro.
;; 	(tramp-get-completion-function): Add declare.
;; 
;; 	* swiper.el (swiper-map): Bind `avy-swiper' to "C-'".
;; 	(avy-swiper): New defun - jump to one of the currently visible swiper 
;; 	candidates using avy.
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to use "^" in swiper
;; 
;; 	* swiper.el (swiper--width): New defvar.
;; 	(swiper--candidates): Set `swiper--width'.
;; 
;; 	* ivy.el (ivy--transform-re): New defun - transform the regex
;; 	 specifically for `swiper'.
;; 	(ivy--filter): Call `ivy--transform-re'.
;; 
;; 	* ivy-test.el (ivy--transform-re): Add test.
;; 
;; 	Fixes #82
;; 
;; 2015-05-08  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add ivy-partial: partial complete without exiting
;; 
;; 	* ivy.el (ivy-partial-or-done): Forward to `ivy-partial'.
;; 	(ivy-partial): New defun.
;; 
;; 	If you want a different style of completion for "TAB", do this in your 
;; 	config:
;; 
;; 	(define-key ivy-minibuffer-map (kbd "TAB") 'ivy-partial)
;; 
;; 	Fixes #85 Fixes #86
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Try to prevent the resize of minibuffer window
;; 
;; 	* ivy.el (ivy--insert-minibuffer): Temporarily bind
;; 	 `resize-mini-windows' to nil.
;; 
;; 	From its doc:
;; 	   A value of `grow-only', the default, means let mini-windows grow
;; 	only;
;; 	   they return to their normal size when the minibuffer is closed, or
;; 	the
;; 	   echo area becomes empty.
;; 
;; 	It could be that an update catches this minibuffer empty during
;; 	`ivy--insert-minibuffer'.
;; 
;; 	Re #77
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy--update-fn into ivy-last
;; 
;; 	* ivy.el (ivy--update-fn): Remove defvar.
;; 	(ivy-read): Update.
;; 	(ivy--insert-minibuffer): Update.
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add parents using 'display for `counsel-load-library'
;; 
;; 	* counsel.el (counsel--find-symbol): The argument string may have a
;; 	 'full-name property.
;; 	(counsel-string-compose): New defun.
;; 	(counsel-load-library): Make libraries unique through text properties.
;; 
;; 	Re #79
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add counsel-load-library
;; 
;; 	* counsel.el (counsel-directory-parent): New defun.
;; 	(counsel-load-library): New command.
;; 
;; 	Improve on `load-library':
;; 
;; 	- don't consider .*elc or .*pkg.elc?, they're usually useless
;; 	- resolve duplicates in a similar way to uniquify (prepend parent
;; 	directory)
;; 	- allow to jump-to-library with "C-." (see `counsel-describe-map')
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Work around grep-read-files
;; 
;; 	* ivy.el (ivy--done): If history is `grep-files-history', the caller is
;; 	 `grep-read-files'. Don't expand the file name, since it's probably a
;; 	 glob, and `find' doesn't work with expanded globs.
;; 
;; 	It should now be possible to simply "M-x" rgrep "RET" "RET" "RET".
;; 
;; 	Fixes #72
;; 
;; 2015-05-06  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-partial-or-done): Handle empty input
;; 
;; 	Fixes #81
;; 
;; 2015-05-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve "TAB" interaction with `confirm-nonexistent-file-or-buffer'
;; 
;; 	* ivy.el (ivy-partial-or-done): When
;; 	 `confirm-nonexistent-file-or-buffer' is t, and there are no
;; 	 candidates, modify the prompt to "(confirm)" right after the first
;; 	 "TAB".
;; 
;; 	Re #76
;; 
;; 2015-05-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Simplify and improve
;; 
;; 	* ivy.el (ivy--done): New defun.
;; 	(ivy-done): Consider `confirm-nonexistent-file-or-buffer' for buffers as 
;; 	well.
;; 
;; 	Fixes #76
;; 
;; 2015-05-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy--collection into ivy-last
;; 
;; 	* ivy.el (ivy--collection): Delete defvar.
;; 	(ivy-read): Update.
;; 	(ivy--exhibit): Update.
;; 
;; 2015-05-05  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Require dired when completing file names
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 	Fixes #78
;; 
;; 2015-05-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Make "TAB" switch directories properly
;; 
;; 	* ivy.el (ivy-partial-or-done): Forward to `ivy-alt-done'.
;; 
;; 	Fixes #75
;; 
;; 2015-05-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"TAB" shouldn't delete input when no candidate
;; 
;; 	ivy.el (ivy-partial-or-done): Update.
;; 
;; 	Fixes #74
;; 
;; 2015-05-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Ignore case for "TAB"
;; 
;; 	* ivy.el (ivy-partial-or-done): Update.
;; 
;; 	Now, e.g. "pub" can expand to "Public License".
;; 
;; 2015-05-04  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-tab-space): New defcustom
;; 
;; 	* ivy.el (ivy-partial-or-done): Insert an extra space when
;; 	 `ivy-tab-space' is non-nil. This is useful to complete partially and
;; 	 start a new group at once.
;; 
;; 	Fixes #73
;; 
;; 2015-05-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add an option for out-of-order matching
;; 
;; 	* ivy.el (ivy--regex-ignore-order): New defun.
;; 
;; 	* swiper.el (swiper--init): Set `ivy--regex-function'.
;; 	(swiper--update-input-ivy): Use `ivy--regex-function'.
;; 	(swiper--action): Use `ivy--regex-function'.
;; 
;; 	Example of use:
;; 
;; 	(setq ivy-re-builders-alist
;; 	     '((t . ivy--regex-ignore-order)))
;; 
;; 	With this, e.g. swiper will match "bar foo" from input "foo bar".
;; 
;; 2015-05-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Bump version
;; 
;; 2015-05-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-resume): Quote the preselect
;; 
;; 2015-05-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the candidate index for `ivy-resume'
;; 
;; 	* ivy.el (ivy--preselect-index): The the regex, not the plain text.
;; 
;; 2015-05-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add unwind argument to ivy-read
;; 
;; 	* ivy.el (ivy-state): Add `unwind' field.
;; 	(ivy-resume): Update.
;; 	(ivy-read): Call the `unwind' argument in the unwind form.
;; 
;; 	* swiper.el (swiper--ivy): Use `unwind' for `ivy-read'.
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy--persistent-action into ivy-state-action
;; 
;; 	* counsel.el (counsel-git-grep): Update.
;; 
;; 	* ivy.el (ivy--persistent-action): Remove defvar.
;; 	(ivy-next-line-and-call): Update.
;; 	(ivy-previous-line-and-call): Update.
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-resume now works for functions that supply action
;; 
;; 	ivy.el (ivy-resume): Use action
;; 
;; 	Functions like `counsel-describe-funtion' and `counsel-describe-varible' 
;; 	are now resume-able: after finishing with "RET" or breaking out with
;; 	"C-g" it's possible to resume the query in the same state as it was
;; 	(same collection, input, index).
;; 
;; 	With:
;; 
;; 	(global-set-key (kbd "C-c C-r") 'ivy-resume)
;; 
;; 	it's possible to e.g.:
;; 
;; 	- "F1 f" info read "RET" to describe Info-breadcrumbs
;; 	- "C-c C-r" "C-n" to describe Info-read-node-name
;; 	- "C-c C-r" "C-n" to describe Info-read-node-name-1
;; 	...
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy--action into ivy-last
;; 
;; 	* ivy.el (ivy-state): Add action field.
;; 	(ivy-set-action): New defun. Just a shortcut to set action.
;; 	(ivy--action): Remove defvar.
;; 	(ivy-read): Add action argument. Check (ivy-state-action ivy-last) in 
;; 	the end and call it, since the action can change during the completion.
;; 	(ivy--insert-prompt): Add `counsel-find-symbol' to the list.
;; 	(ivy--format): If there are no matches, set `ivy--current' to "".
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy-window into ivy-last
;; 
;; 	* ivy.el (ivy-state): Add a window field.
;; 	(ivy-window): Remove defvar.
;; 	(ivy-next-line-and-call): Update.
;; 	(ivy-previous-line-and-call): Update.
;; 	(ivy-read): Update.
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Merge ivy-def into ivy-last
;; 
;; 	* ivy.el (ivy-def): Remove defvar.
;; 	(ivy-read): Update.
;; 	(ivy--filter): Update.
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to quote spaces while matching
;; 
;; 	* ivy.el (ivy--split): New defun.
;; 
;; 	Use (ivy--split str) in place of (split-string str " +" t). Allows to
;; 	"quote" N spaces by inputting N+1 spaces.
;; 
;; 2015-05-01  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add ivy-state struct
;; 
;; 	* ivy.el (ivy-state): New defstruct.
;; 	(ivy-last): A single global to store an `ivy-state' struct.
;; 	(ivy-require-match): Move into `ivy-last'.
;; 	(ivy-done): Update.
;; 	(ivy-resume): New defun. Initial draft, kind of works for swiper. Need 
;; 	to add a callback of what to do with the result as an argument.
;; 	(ivy-read): Store all arguments into `ivy-last'.
;; 	(ivy-completing-read): Update doc.
;; 
;; 2015-04-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow for "/ssh:user@" as well as for "/ssh:"
;; 
;; 	* ivy.el (ivy-alt-done): Update.
;; 
;; 	Re #59
;; 
;; 2015-04-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve TRAMP completion for ivy-mode
;; 
;; 	* ivy.el (ivy-build-tramp-name): New defun.
;; 	(ivy-alt-done): Use arcane TRAMP stuff to complete host names.
;; 
;; 	Re #59
;; 
;; 2015-04-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Reset `ivy-text' earlier
;; 
;; 	Related to `counsel-git-grep' "-3 chars more".
;; 
;; 2015-04-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex): Fixup
;; 
;; 	Fixes #62
;; 
;; 2015-04-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't error on bad regex
;; 
;; 	* ivy.el (ivy--filter): When on bad regex, just set the result to nil.
;; 
;; 	Fixes #70
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update and improve faces
;; 
;; 	* ivy.el (ivy-subdir): Inherit from dired-directory.
;; 
;; 	* swiper.el (swiper-match-face-1): Update doc.
;; 	(swiper-match-face-2): Update doc.
;; 	(swiper-match-face-3): Update doc.
;; 	(swiper-match-face-4): Inherit from isearch-fail.
;; 	(swiper--add-overlays): Fix the faces order swapping on the second 
;; 	match.
;; 
;; 	Now it finally works as planned: face-1 is the background (re group 0), 
;; 	next it cycles: face-2, face-3, face-4, face-2, face-3, face-4.
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add gamma-correction to alpha-blending
;; 
;; 	* colir.el (colir-compose-method): Make 'colir-compose-alpha default.
;; 	(colir-compose-alpha): Add gamma-correction.
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	colir.el: Add two additional blend algorithms
;; 
;; 	* colir.el (colir-join): Remove.
;; 	(color): Require.
;; 	(colir-compose-method): New defcustom.
;; 	(colir-compose-soft-light): New defun.
;; 	(colir-compose-overlay): New defun.
;; 	(colir-compose-alpha): New defun.
;; 	(colir-blend): Update.
;; 	(colir-blend-face-background): Update.
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--exhibit): Fixup last commit
;; 
;; 	* ivy.el (ivy--old-text): Should always be a string.
;; 	(ivy-read): Update.
;; 	(ivy--exhibit): Recompute candidates on flip, always set `ivy--old-re' 
;; 	to nil.
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve hidden buffer completion further
;; 
;; 	* ivy.el (ivy--exhibit): Update.
;; 
;; 	Fixes #68 Fixes #69
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve the completion of hidden buffers
;; 
;; 	* ivy.el (ivy--collection): New defvar.
;; 	(ivy-read): Update.
;; 	(ivy--exhibit): Update.
;; 
;; 	Re #68.
;; 
;; 2015-04-29  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind "TAB" to do partial completion
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 	(ivy-alt-done): New defun.
;; 	(ivy--old-text): Update.
;; 
;; 	Re #63.
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep): Add optional initial-input
;; 
;; 	* counsel.el (counsel-git-grep): Update.
;; 
;; 	Fixes #66
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-re-builders-alist): Improve doc
;; 
;; 	Re #62
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Fixup docstrings
;; 
;; 	* ivy.el (ivy-require-match): Update.
;; 	(ivy-def): Update.
;; 	(ivy--prompt-extra): Update.
;; 	(ivy--maybe-scroll-history): Update.
;; 	(ivy-completing-read): Update.
;; 	(ivy--insert-minibuffer): Update.
;; 	(ivy--filter): Update.
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add an option for multi-tier regex matching
;; 
;; 	* ivy.el (ivy--regex-plus): New defun. This is an example for the
;; 	 multi-tier interface.
;; 	(ivy--filter): Update.
;; 
;; 	To use it, add e.g.:
;; 
;; 	(setq ivy-re-builders-alist
;; 	     '((t . ivy--regex-plus)))
;; 
;; 	Example using boost_1_58_0 and `find-file-in-project`:
;; 
;; 	* "utility" - 234 matches
;; 	* "utility hpp" - 139 matches
;; 	* "utility !hpp" - 95 matches
;; 
;; 	Fixes #62
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Makefile: Update
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use alpha compositing to add ivy-current-match face
;; 
;; 	* ivy.el (ivy--exhibit): Use `colir-blend-face-background'. In case it
;; 	 fails, try `font-lock-append-text-property', which was used before.
;; 
;; 	* colir.el (colir-join): New defun.
;; 	(colir-blend): New defun.
;; 	(colir-blend-face-background): New defun.
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude `elfeed-search-mode'
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--filter): Fixup
;; 
;; 	Fixes #65
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Treat `ivy-text' with ":" verbatim
;; 
;; 	* ivy.el (ivy-alt-done): Should work better now for ssh: stuff.
;; 
;; 	It should be possible to type in any directory: `/ssh:user@domain.com:`
;; 	<kbd>C-j</kbd> and get completion.
;; 
;; 	Re #59
;; 
;; 2015-04-28  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Store the preselect and use it for empty ivy-text
;; 
;; 	* ivy.el (ivy-def): New defvar.
;; 	(ivy-read): Store `ivy-def'.
;; 	(ivy-completing-read): Update.
;; 	(ivy--filter): When the input is empty, set `ivy--index' to select
;; 	`ivy-def'.
;; 
;; 	Fixes #64
;; 
;; 2015-04-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve completion history using the propertize trick
;; 
;; 	* ivy.el (ivy-previous-history-element): Update.
;; 	(ivy-next-history-element): Update.
;; 	(ivy--maybe-scroll-history): New defun. When the history element string 
;; 	has ivy-index property, set `ivy--index' to that.
;; 
;; 	Fixes #46
;; 
;; 2015-04-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Minibuffer faces should inherit minibuffer-prompt
;; 
;; 	* ivy.el (ivy-confirm-face): Update.
;; 	(ivy-match-required-face): Update.
;; 
;; 	Re #60
;; 
;; 2015-04-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Improve the match confirm while completing files
;; 
;; 	* ivy.el (ivy-confirm-face): New face.
;; 	(ivy-match-required-face): New face.
;; 	(ivy--prompt-extra): New defvar, the prompt is concatenaded with this.
;; 	(ivy--extend-prompt): Remove.
;; 	(ivy-done): Update.
;; 	(ivy--insert-prompt): Use `ivy--prompt-extra'. Reset it unless the
;; 	`this-command' is appropriate.
;; 	(ivy--set-match-props): New defun.
;; 
;; 	Fixes #60
;; 
;; 2015-04-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Reset to the first candidate when switching directories
;; 
;; 	* ivy.el (ivy--cd): Update.
;; 
;; 2015-04-24  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Propertize remote buffers with ivy-remote face
;; 
;; 	* ivy.el (ivy-remote): New face.
;; 	(ivy-read): Update.
;; 
;; 	Fixes #61
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Respect `confirm-nonexistent-file-or-buffer'
;; 
;; 	* ivy.el (ivy--extend-prompt): New defun.
;; 	(ivy-done): Ask for a confirmation if no candidates match and
;; 	`confirm-nonexistent-file-or-buffer' is t.
;; 
;; 	Re #60
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Fixup preselect addition
;; 
;; 	It was unnecessarily inserting `preselect' when completing tags.
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--cd): Reset `ivy--old-re'
;; 
;; 	* ivy.el (ivy--cd): Switching directory switches the candidates, so
;; 	`ivy--old-re' must be invalidated.
;; 
;; 	Fixes #58
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (Info-current-file): Declare
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use "//" to move to root instead of "/" as before
;; 
;; 	ivy.el (ivy--exhibit): Update.
;; 
;; 	This improves the situation with tramp and generally avoids losing the 
;; 	current directory by pressing "/" by accident.
;; 
;; 	Fixes #59
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Avoid sorting org refile candidates
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Exclude jabber-chat-mode from font-lock
;; 
;; 	* swiper.el (swiper-font-lock-ensure): Update.
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Remove globbing heuristics for file name completion
;; 
;; 	* ivy.el (ivy-done): Simplify.
;; 	(ivy-alt-done): Simplify.
;; 
;; 	If you want to exit with the current text, ignoring candidates, use
;; 	`ivy-immediate-done' instead. Works for globs as well.
;; 
;; 	Fixes #55
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep): Fixup
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-backward-delete-char): Expand `ivy--directory'
;; 
;; 	This avoids the situation of getting a nil for "~/".
;; 
;; 	Re #57
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Update wrt globs
;; 
;; 	Re #55
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-query-replace): Fix
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Check for stand-alone ivy
;; 
;; 	Re #54
;; 
;; 2015-04-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Don't expand globs
;; 
;; 	Re #55
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Update video link
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fixup `swiper-query-replace'
;; 
;; 	* swiper.el (swiper-query-replace): Make sure to use `swiper--window'.
;; 
;; 	* ivy.el (ivy--minibuffer-setup): Remove the `use-local-map' statement,
;; 	 the map is already set in `read-from-minibuffer'.
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-test.el (ivy-read): Update test.
;; 
;; 	REQUIRE-MATCH is nil by default.
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Fix preselect logic
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 	Fixes e.g. `ert' passing "t" as the default, which isn't in collection, 
;; 	but `all-completions' doesn't return nil.
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Fixup
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--add-face): Don't fail for weird str
;; 
;; 	Fixes #44
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--ivy): Fix preselect being added
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--exhibit): Wrap in `while-no-input'
;; 
;; 	* ivy.el (ivy--exhibit): `ivy--dynamic-function' will sometimes use
;; 	 `call-process'. Adding `while-no-input' speeds up things a lot, at the
;; 	 cost of a small message interrupting the minibuffer when
;; 	 `call-process' takes too long or the user types too fast.
;; 	 This message is not an issue for emacs-snapshot.
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind "M-q" to `ivy-toggle-regexp-quote'
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 	(ivy--regexp-quote): New defvar.
;; 	(ivy-toggle-regexp-quote): New command, toggle `ivy--regex-function' 
;; 	between the value selected in `ivy-read' and `ivy--regexp-quote'.
;; 	(ivy-read): Reset `ivy--regexp-quote' to 'regexp-quote.
;; 
;; 	Fixes #48
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the regex matching per-collection
;; 
;; 	* ivy.el (ivy--regex-function): New defvar.
;; 	(ivy-re-builders-alist): New defvar, use this to customize.
;; 	(ivy-read): Update.
;; 	(ivy--filter): Update.
;; 
;; 	Currently, it only works for function collections. Example:
;; 
;; 	(setq ivy-re-builders-alist
;; 	 '((read-file-name-internal . regexp-quote)
;; 	   (t . ivy--regex)))
;; 
;; 	Re #48
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Be more strict for `require-match'
;; 
;; 	When `require-match' isn't in (nil confirm confirm-after-completion), 
;; 	don't allow to exit if there isn't a match. Instead, amend the prompt 
;; 	with "(match required)".
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Change `ivy-read' to a cl-defun
;; 
;; 	* ivy.el (ivy-read): All args but PROMPT and COLLECTION are now keys. 
;; 	The existing basic calls to `ivy-read' should still work, the others 
;; 	need to be updated. It's best to try to use `ivy-completing-read' if 
;; 	possible, since it conforms to the `completing-read' arguments. New
;; 	arguments: REQUIRE-MATCH and HISTORY. If HISTORY is nil, `ivy-history' 
;; 	is used.
;; 
;; 	(ivy--sorted-files): Don't try to extend the collection.
;; 	(ivy-completing-read): Update.
;; 
;; 	* swiper.el (swiper--ivy): Update.
;; 
;; 	* counsel.el (counsel-describe-symbol-history): New defvar.
;; 	(counsel-describe-variable): Update the call, require match, use
;; 	`counsel-describe-symbol-history'.
;; 	(counsel-describe-function): Update the call, require match, use
;; 	`counsel-describe-symbol-history'.
;; 
;; 	* ivy-test.el: Update tests, since zero and one length input doesn't
;; 	 return immediately any more.
;; 
;; 	Re #46
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--filter): Update prefix optimization
;; 
;; 	* ivy.el (ivy--filter): Don't use prefix optimization when the input
;; 	 contains "\".
;; 
;; 2015-04-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add a note on outdated ivy package
;; 
;; 	Fixes #51
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--filter): Try directory expansion with "/"
;; 
;; 	* ivy.el (ivy--filter): If candidate is "x" and completing file names,
;; 	 check if "x/" is among the candidates, and if so, set `ivy--index'
;; 	 accordingly.
;; 
;; 	Re #50
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix the default-directory for `counsel-git-grep'
;; 
;; 	* counsel.el (counsel--git-grep-dir): New defvar.
;; 	(counsel-git-grep-count): Update.
;; 	(counsel-git-grep-function): Update.
;; 	(counsel-git-grep): Update.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a way to exit ignoring the candidates
;; 
;; 	* ivy.el (ivy-immediate-done): New commad, currently unbound. Exit the
;; 	minibuffer, ignoring the candidates. Solves the same problem as
;; 	"C-f" in `ido-mode'.
;; 	(ivy-alt-done): With a prefix arg, e.g. "C-u C-j", forward to
;; 	`ivy-immediate-done'.
;; 
;; 	Re #50
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Don't add the `default-directory'
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Use initial-input when completing files
;; 
;; 	* ivy.el (ivy-read): Unless `require-match', add `initial-input' to the
;; 	 collection. This is important e.g. for `dired-dwim-target'.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--add-overlays): Make bounds optional
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-count): Ignore case
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix describe-function / -variable "C-." interaction
;; 
;; 	* counsel.el (counsel-describe-variable): Don't describe variable if
;; 	 jump-to-symbol action was chosen.
;; 	(counsel-describe-function): Don't describe variable if
;; 	 jump-to-symbol action was chosen.
;; 
;; 	I should handle this more gracefully if multiple actions become a 
;; 	pattern.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Add awesome swiper highlighting to git grep
;; 
;; 	* counsel.el (swiper): Require.
;; 	(counsel-git-grep-function): Use `swiper--add-overlays'. Remember to set
;; 	`swiper--window', and call `swiper--cleanup'. Use `ivy--regex' in all 
;; 	cases to build the regex.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex): Add optional greedy arg
;; 
;; 	* ivy.el (ivy--regex): When optional greedy arg is t, be greedy.  Don't 
;; 	wrap a sub-expr in a group if it's already a group, for instance
;; 	"forward \(char\|list\)".
;; 
;; 	Greedy is needed, for instance, for "git grep", which doesn't work great 
;; 	with non-greedy regex.
;; 
;; 	Re #47
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--add-overlays): Update arglist
;; 
;; 	* swiper.el (swiper--update-input-ivy): Update.
;; 	(swiper--add-overlays): Take only the regexp as the argument. Figure out
;; 	the bounds by itself.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Don't directory-expand glob filename
;; 
;; 	* ivy.el (ivy-done): Don't directory-expand if there's a star in the
;; 	 file name.
;; 
;; 	This change fixes the behavior of `rgrep`. It can't handle the case of 
;; 	e.g. /foo/bar/\*.el, but handles \*.el fine.
;; 
;; 	Re #45
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add an option to call the completion action without exiting
;; 
;; 	* ivy.el (ivy--persistent-action): New defvar. This is a lambda that the
;; 	 caller sets if the caller has a plan for persistent actions.
;; 	(ivy-next-line-and-call): Add and bind to "C-M-n". Identical to "C-n", 
;; 	except calls `ivy--persistent-action' when it's not nil. Add and bind to
;; 	"C-M-p". Identical to "C-p", except calls `ivy--persistent-action' when
;; 	it's not nil.
;; 	(ivy-window): New defvar.
;; 	(ivy-read): Store `ivy-window'.
;; 
;; 	* counsel.el (counsel-git-grep): Use `ivy--persistent-action'.
;; 
;; 	For `counsel-git-grep', as an example, it's possible to move to the 
;; 	matched place without exiting the completion with "C-M-n" and "C-M-p". 
;; 	This is a nice advantage, since it gives a full context to each one-line 
;; 	git grep match.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix double-sorting for file names
;; 
;; 	* ivy.el (ivy--sorted-files): Update.
;; 	(ivy-read): Update.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--sorted-files): Avoid returning an empty list
;; 
;; 	Fixes #49
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the sorting methods
;; 
;; 	* ivy.el (ivy-sort-functions-alist): New defvar, stores sorting
;; 	 functions for various function collection types.
;; 	(ivy-sort-file-function): Remove, merge into `ivy-sort-functions-alist'.
;; 	(ivy-sort-max-size): Don't sort candidate lists larger than this size.
;; 	(ivy--sorted-files): Update.
;; 	(ivy-read): Add an argument SORT. When it's t, sort the candidates 
;; 	according to `ivy-sort-functions-alist'.  It's assumed that if 
;; 	COLLECTION is a function it's OK to `cl-sort' it without making a copy.
;; 	(ivy-completing-read): Call with SORT t.
;; 
;; 	* counsel.el (counsel-describe-variable): Call with SORT t.
;; 	(counsel-describe-function): Call with SORT t.
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--regex): Switch to non-greedy ".*?" joiner
;; 
;; 	Fixes #47
;; 
;; 2015-04-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Expand file name for empty text
;; 
;; 	Fixes #45
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	`counsel-git-grep' can now handle huge git repos
;; 
;; 	* counsel.el (counsel-git-grep-count): Return a number instead of a
;; 	 string. Apply `ivy--regex' on the input.
;; 	(counsel--git-grep-count): New defvar.
;; 	(counsel-git-grep-function): If the repo has >20000 lines, use `head'
;; 	5000 instead, but still display the true amount of matches.
;; 	(counsel-git-grep): Set `ivy--dynamic-function'.
;; 	(counsel-locate-function): Update.
;; 
;; 	* ivy.el (ivy--dynamic-function): New defvar. When this isn't nil, it
;; 	 will be called to get a new batch of candidates in case the `ivy-text'
;; 	 was changed.
;; 	(ivy--full-length): The true candidates length in case of `head'
;; 	shenanigans.
;; 	(ivy--old-text): Store the old text for when `ivy--dynamic-function' was 
;; 	called last.
;; 	(ivy--insert-prompt): Update.
;; 	(ivy--exhibit): Don't do filtering for non-nil `ivy--dynamic-function' - 
;; 	let the caller (usually a shell tool) do the filtering.
;; 	(ivy--insert-minibuffer): New defun, created from a part of
;; 	`ivy--exhibit'.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use cl-plusp instead of plusp
;; 
;; 	* ivy.el (cl-lib): Add require.
;; 	(ivy-alt-done): Update.
;; 
;; 	Re #43
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a dynamic counsel-locate
;; 
;; 	* counsel.el (counsel-locate-function): New defun.
;; 	(counsel-locate): New defun.
;; 
;; 	* ivy.el (ivy--dynamic-function): New defvar.
;; 	(ivy--exhibit): Re-compute candidates use `ivy--dynamic-function' if 
;; 	it's non-nil.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Split `ivy-completions' into `ivy--filter' and `ivy--format'
;; 
;; 	* ivy.el (ivy--exhibit): Update.
;; 	(ivy-completions): Remove.
;; 	(ivy--filter): New defun.
;; 	(ivy--format): New defun.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep-count): Add defun
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Fix compilation warnings
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Bind arrows
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 
;; 	Re #40
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add an optimization to speed up matching
;; 
;; 	* ivy.el (ivy-completions): Update.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Bump version
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Still expand "./" though
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't expand the default when completing file names
;; 
;; 	* ivy.el (ivy-done): Update.
;; 
;; 	This affects e.g. `rgrep': "\*.el" as the default will work, but
;; 	"foo/\*.el" won't.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Propertize directories with ivy-subdir face
;; 
;; 	* ivy.el (ivy-subdir): New defface.
;; 	(ivy-completions): Update.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Speed up the default file sorting even more
;; 
;; 	* ivy.el (ivy--sorted-files): Use `string-match-p' instead of
;; 	 `file-directory-p'.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Speed up the default file sorting
;; 
;; 	* ivy.el (ivy-sort-file-function-default): Update.
;; 	(ivy--sorted-files): Update.
;; 
;; 	Turns out that calling `file-directory-p' in `cl-sort' is too expensive. 
;; 	So when `ivy-sort-file-function' is `ivy-sort-file-function-default', 
;; 	propertize all strings with whether they are directories or not.
;; 
;; 	When `ivy-sort-file-function' is something different, e.g.
;; 	`string-lessp', don't do propertizing since it also can be slow.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy--preselect-index): Give priority to perfect match
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow "C-." to jump to current symbol definition
;; 
;; 	* counsel.el (counsel-describe-map): New defvar.
;; 	(counsel-find-symbol): New defun.
;; 	(counsel--find-symbol): New defun - jump to definition of function or 
;; 	symbol or library.
;; 	(counsel-describe-variable): Use `counsel-describe-map'.
;; 	(counsel-describe-function): Use `counsel-describe-map'.
;; 
;; 2015-04-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the file sorting order
;; 
;; 	* ivy.el (ivy-sort-file-function-default): New defun.
;; 	(ivy-sort-file-function): New defvar. Set this to your preference.
;; 	(ivy--sorted-files): Update.
;; 
;; 	Fixes #38
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-done): Update for non-matching file names
;; 
;; 	* ivy.el (ivy-done): When `ivy--directory' is non-nil, accept input
;; 	 anyway.
;; 
;; 	Fixes #39
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completions): Fix an optimization
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a matching optimization
;; 
;; 	* ivy.el (ivy-completions): When the new regex `re' is a contains the
;; 	 old regex `ivy--old-re', it must be true that all candidates that
;; 	 match `re' are contained inside all candidates that match
;; 	 `ivy--old-re', i.e. the pre-computed in the last step
;; 	 `ivy--old-cands'.
;; 
;; 	This should speed up completion for large (~100k) amount of candidates, 
;; 	for the particular case of regex simply being extended.
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (counsel-git-grep): Fix the default-directory
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a command to grep the current git repo
;; 
;; 	* counsel.el (counsel-git-grep-function): New defun.
;; 	(counsel-git-grep): New command.
;; 
;; 2015-04-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add "C-v" and "M-v" scrolling
;; 
;; 	* ivy.el (ivy-minibuffer-map): Update.
;; 	(ivy-scroll-up-command): New defun.
;; 	(ivy-scroll-down-command): New defun.
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-alt-done): Update for 0 candidates
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Add a work-around for window-start not being current
;; 
;; 	* swiper.el (swiper--update-input-ivy): Update.
;; 
;; 	This results in double the window-height amount of lines being 
;; 	heightlighted, instead of just window-height. But at least it doesn't 
;; 	happen that some candidates within the current window aren't highlighted 
;; 	since they're beyond the outdated window-start and window-end.
;; 
;; 	An alternative would be to use `redisplay' to update `window-start' and
;; 	`window-end', but that causes excessive blinking.
;; 
;; 	* ivy-test.el: Add a require.
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Move all defvar before their first use
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add ivy key bindings to "C-h m"
;; 
;; 	* ivy.el (ivy-mode): Update.
;; 
;; 	Re #37
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to customize the dotted directories
;; 
;; 	* ivy.el (ivy-extra-directories): New defcustom.
;; 	(ivy--sorted-files): Update.
;; 
;; 	Re #38
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a work-around for completing topics in the info dir
;; 
;; 	* ivy.el (ivy-read): Weirdly, the topic names need to be wrapped in
;; 	 "(...)". Also, `all-completions' returns nothing for "", but returns
;; 	 stuff for "(". Also, `all-completions' for "(" returns plenty of
;; 	 duplicates.
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude dired-mode
;; 
;; 2015-04-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Switch from `with-no-warnings' to `declare-function'
;; 
;; 2015-04-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to complete dir with "/" if it's a perfect match
;; 
;; 	* ivy.el (ivy--exhibit): Update.
;; 
;; 2015-04-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add sorting for file completion
;; 
;; 	* ivy.el (ivy-alt-done): Exit with current directory when on first
;; 	 element, which is always "./", thanks to sorting.
;; 	(ivy--cd): Update.
;; 	(ivy--sorted-files): New defun for sorting file names. "./" and "../" 
;; 	are always the first, then come the directories, then the files.
;; 	(ivy-read): Update.
;; 
;; 2015-04-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add "/" and "~" shortcuts while finding files
;; 
;; 	* ivy.el (ivy--cd): New defun.
;; 	(ivy-backward-delete-char): Use `ivy--cd'.
;; 	(ivy--exhibit): When the file completion text ends in "/" or "~", move
;; 	to those dirs.
;; 
;; 2015-04-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add work-around for DEF not being in COLLECTION for `completing-read'
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 2015-04-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Remove dependency on ivy
;; 
;; 	ivy.el now comes together with swiper.
;; 
;; 	Re #36.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Ivy-mode now works better with `find-file'
;; 
;; 	* ivy.el (ivy-minibuffer-map): Bind "C-j" to visit a directory without
;; 	 exiting the minibuffer.
;; 	(ivy--directory): New defvar.
;; 	(ivy-done): Expand file names.
;; 	(ivy-alt-done): New defun.
;; 	(ivy-backward-delete-char): When completing file names, visit the parent
;; 	dir.
;; 	(ivy-read): Add the predicate argument, similar to `completing-read'. 
;; 	All code that uses `ivy-read' needs to be updated. Move the
;; 	collection/predicate stuff here.
;; 	(ivy-completing-read): Update.
;; 	(ivy--insert-prompt): Display the current directory when completing file
;; 	names.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completing-read): Rely more on `all-completions'
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add require-match functionality
;; 
;; 	* ivy.el (ivy-require-match): New defvar.
;; 	(ivy-done): When nothing matches, and `ivy-require-match' isn't t, use 
;; 	the current text anyway.
;; 	(ivy-completing-read): Update.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add function as collection support for ivy-mode
;; 
;; 	* ivy.el (ivy-completing-read): Update. Ignore initial input for
;; 	function collection type.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't try to fontify huge buffers
;; 
;; 	* swiper.el (swiper-font-lock-ensure): Update.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Remove ido-mode shenanigans
;; 
;; 	Combining `ido-mode' and `ivy-read' seemed to cause a problem at some 
;; 	stage. Can't reproduce now, so I'll just remove this for a while.
;; 
;; 2015-04-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Bump version
;; 
;; 2015-04-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix thing-at-point in describe-function and -variable
;; 
;; 	* counsel.el (counsel-describe-variable): Update.
;; 	(counsel-describe-function): Update.
;; 
;; 2015-04-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update sorting order, make sure that perfect match is selected
;; 
;; 	ivy.el (ivy-completions): Update.
;; 
;; 	When the regex matches perfectly, select it.
;; 
;; 2015-04-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add ivy-mode
;; 
;; 	* ivy.el (ivy-completing-read): New defun.
;; 	(ivy-mode): New global minor mode.
;; 
;; 2015-04-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude org-agenda-mode
;; 
;; 	Re #19
;; 
;; 2015-04-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add four more commands
;; 
;; 	* counsel.el (counsel-describe-variable): New defun.
;; 	(counsel-describe-function): New defun.
;; 	(counsel-info-lookup-symbol): New defun.
;; 	(counsel-unicode-char): New defun.
;; 
;; 	* Makefile: Compile counsel.el as well.
;; 
;; 2015-04-03  Steve Purcell  <steve@sanityinc.com>
;; 
;; 	Fix invalid package header line
;; 
;; 2015-04-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Fixup prefixes
;; 
;; 2015-04-03  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el (couns-clj): Add with-no-warnings
;; 
;; 2015-04-02  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Update comments
;; 
;; 2015-03-31  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Fix `ivy-backward-delete-char-function'
;; 
;; 	* ivy.el (ivy-on-del-error-function): Rename from
;; 	 `ivy-backward-delete-char-function'.
;; 	(ivy-backward-delete-char): Don't use eval.
;; 
;; 2015-03-30  Kevin  <nivekuil@gmail.com>
;; 
;; 	Add defcustom for ivy-backward-delete-char
;; 
;; 2015-03-30  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow duplicate candidates in `ivy-read'
;; 
;; 	* ivy.el (ivy-completions): Use `eq' instead of `equal' in
;; 	 `cl-position'.
;; 
;; 2015-03-27  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-map): Bind "C-l" to recenter
;; 
;; 	* swiper.el (swiper-map): Update.
;; 	(swiper-recenter-top-bottom): New defun.
;; 	(swiper--update-input-ivy): Use `<=' in order for `recenter-top-bottom' 
;; 	to work.
;; 
;; 2015-03-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-query-replace): Enable recursive minibuffers
;; 
;; 	* swiper.el (swiper-query-replace): Update.
;; 
;; 	Fixes #31.
;; 
;; 2015-03-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Default ARG to 1 for arrows
;; 
;; 	* ivy.el (ivy-next-line): Update.
;; 	(ivy-previous-line): Update.
;; 
;; 2015-03-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add numeric arguments to arrows
;; 
;; 	* ivy.el (ivy-next-line): Update.
;; 	(ivy-next-line-or-history): Update.
;; 	(ivy-previous-line): Update.
;; 	(ivy-previous-line-or-history): Update.
;; 	(ivy-read): Update doc.
;; 
;; 2015-03-26  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	"C-s" should forward to "C-n" etc
;; 
;; 	* ivy.el (ivy-next-line-or-history): Update.
;; 	(ivy-previous-line-or-history): Update.
;; 
;; 2015-03-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Allow to cancel "M-q" with "C-g"
;; 
;; 	swiper.el (swiper-query-replace): If the TO argument to
;; 	`perform-replace' isn't read, don't exit minibuffer.
;; 
;; 	If the user called `swiper-query-replace' and isn't happy with the 
;; 	current input being the FROM arg of `perform-replace', it's possible to 
;; 	cancel with "C-g", and edit the input once again.
;; 
;; 2015-03-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-query-replace): Call only in minibuffer
;; 
;; 2015-03-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add swiper-query-replace
;; 
;; 	* ivy.el (ivy-read): Update signature - a keymap is also accepted and
;; 	 the argument order has changed.
;; 	 The keymap is composed with `ivy-minibuffer-map'.
;; 	 Update for `ivy--action'.
;; 	(ivy--action): New defvar. If a function sets it, `ivy-read' will call
;; 	it.
;; 
;; 	* swiper.el (swiper-map): New defvar.
;; 	(swiper-query-replace): New defun.
;; 	(swiper--ivy): Use swiper-map in the call to `ivy-read'.
;; 
;; 	* counsel.el (couns-git): Fix one empty candidate.
;; 
;; 2015-03-25  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Ignore gnus modes
;; 
;; 2015-03-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Ensure that inserted candidates don't have read-only property
;; 
;; 	* ivy.el (ivy-completions): Update.
;; 
;; 	Fixes #28.
;; 
;; 	The issue was that the whole text of erc buffer has (read-only t) 
;; 	property. That means if I copy some of those strings and insert them 
;; 	into the minibuffer, I can't delete them unless I set
;; 	`inhibit-read-only' to t. Instead, I set the read-only to nil for the 
;; 	string that I insert. It doesn't affect the original buffer string.
;; 
;; 2015-03-23  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Omit erc-mode
;; 
;; 	Re #28
;; 
;; 2015-03-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update Copyright
;; 
;; 2015-03-22  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Move swiper-helm to another repo
;; 
;; 2015-03-22  John Mastro	 <john.b.mastro@gmail.com>
;; 
;; 	ivy.el (ivy-wrap): New defcustom
;; 
;; 	(ivy-next-line): Wrap around if `ivy-wrap' is non-nil
;; 	(ivy-next-line-or-history): Wrap around if `ivy-wrap' is non-nil
;; 	(ivy-previous-line): Wrap around if `ivy-wrap' is non-nil
;; 	(ivy-previous-line-or-history): Wrap around if `ivy-wrap' is non-nil
;; 
;; 2015-03-22  John Mastro	 <john.b.mastro@gmail.com>
;; 
;; 	swiper.el (swiper-min-highlight): New defcustom
;; 
;; 	(swiper--add-overlays): Use `swiper-min-highlight'
;; 
;; 2015-03-22  John Mastro	 <john.b.mastro@gmail.com>
;; 
;; 	swiper.el (swiper--init): Set `swiper--opoint'
;; 
;; 	(swiper): Don't set `swiper--opoint'
;; 
;; 2015-03-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update "C-n" and "C-p" bindings
;; 
;; 	* ivy.el (ivy-next-line): Don't touch history.
;; 	(ivy-next-line-or-history): Select previous history element if there's 
;; 	no input.
;; 	(ivy-previous-line): Don't touch history.
;; 	(ivy-previous-line-or-history): Select previous history element if 
;; 	there's no input.
;; 
;; 	Re #23
;; 
;; 2015-03-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Use `font-lock-append-text-property' to non-destructively modify a 
;; 	string
;; 
;; 	* ivy.el (ivy--add-face): Improve.
;; 	`font-lock-append-text-property' non-destructively changes properties in 
;; 	a string, which means if a string was copied from another and modified, 
;; 	the original will not be changed. In this way, it's better than
;; 	`add-face-text-property'; and still better than `propertize' that simply
;; 	erases all properties before applying.
;; 
;; 	Fixes #22
;; 
;; 2015-03-21  Steve Purcell  <steve@sanityinc.com>
;; 
;; 	Fix invalid package header line
;; 
;; 2015-03-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add a custom `ivy-count-format'
;; 
;; 	* ivy.el (ivy-count-format): New defcustom.
;; 	(ivy-read): Use `ivy-count-format', unless PROMPT already has a %d spec.
;; 
;; 	Set `ivy-count-format' to nil or "" if you don't want to see an 
;; 	auto-updating match count in the minibuffer.
;; 
;; 	Re #23.
;; 
;; 2015-03-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper-helm.el: Fix typo
;; 
;; 2015-03-21  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Remove the helm bits
;; 
;; 	They are now in swiper-helm.el. Available for install separately from 
;; 	MELPA.
;; 
;; 2015-03-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper-helm.el: Copy all helm stuff here
;; 
;; 2015-03-20  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-completions): Simplify
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Remove while-no-input
;; 
;; 	This will speed up the updates. But it might slow down somewhere else. 
;; 	The issue was that "M-DEL" did not cause an update.
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add build status
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Allow for format-style PROMPT
;; 
;; 	* ivy.el (ivy-read): When given a prompt of e.g. "%d pattern: ", update
;; 	 the number of candidates in the prompt.
;; 	(ivy--prompt): New defvar.
;; 	(ivy--insert-prompt): New defun.
;; 	(ivy--exhibit): Call `ivy--insert-prompt'.
;; 	(ivy-completions): Fix a bug of `ivy--index' becoming -1 when the number 
;; 	of matches becomes zero.
;; 
;; 	* swiper.el (swiper--format-spec): New defvar.
;; 	(swiper--candidates): Update.
;; 	(swiper--ivy): Use `swiper--format-spec' to make the prompt.
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Change index to preselect
;; 
;; 	* ivy.el (ivy-read): Update signature. Instead of giving the integer
;; 	 index of what to preselect, give a string to preselect.
;; 	(ivy--preselect-index): New defun.
;; 
;; 	* swiper.el (swiper--index-at-point): Rename to `ivy--preselect-index'.
;; 	(swiper--ivy): Simplify.
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy-test.el: Add testing
;; 
;; 	* Makefile: Add a test and compile target.
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Return nil when there is no match
;; 
;; 	* ivy.el (ivy-done): Update.
;; 	(ivy-read): Update.
;; 
;; 2015-03-19  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Silence a few compilation warnings
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Fix non-matching lines issue with initial-input
;; 
;; 	* swiper.el (swiper--index-at-point): New defun.
;; 	(swiper--ivy): Update.
;; 
;; 	Fixes #20.
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add isearch-like history behavior
;; 
;; 	* ivy.el (ivy-next-line): Select previous history element for empty
;; 	 input.
;; 	(ivy-previous-line): Select previous history element for empty input.
;; 	(ivy-previous-history-element): New defun.
;; 	(ivy-next-history-element): New defun.
;; 
;; 	Re #21
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Bring last history candidate to front
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Add git file completion
;; 
;; 	* counsel.el (couns-git): Add.
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--helm): Require helm-match-plugin
;; 
;; 	This seems to be necessary after a recent helm update.
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Fix ivy-history recording the full text instead of input
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 	Fixes #21
;; 
;; 2015-03-18  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper-font-lock-ensure): Exclude a few modes
;; 
;; 	Re #19
;; 
;; 2015-03-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Work around magit highlighting problem
;; 
;; 	* swiper.el (swiper-font-lock-ensure): Update.
;; 
;; 	Re #19
;; 
;; 2015-03-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--opoint): Fix bad defvar
;; 
;; 2015-03-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Add Clojure completion at point
;; 
;; 2015-03-17  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Fix error for empty buffer
;; 
;; 	* swiper.el (swiper--candidates): Update.
;; 	(swiper--action): Update.
;; 
;; 	Fixes #17.
;; 
;; 2015-03-16  killdash9  <killdash9>
;; 
;; 	Need to check value of variable
;; 
;; 2015-03-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Clean up overlays better on "C-g"
;; 
;; 	* swiper.el (swiper--cleanup): Improve.
;; 
;; 	Fixes #11.
;; 
;; 2015-03-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Open invisible overlays using isearch
;; 
;; 	* swiper.el (swiper--update-input-ivy): Improve.
;; 
;; 	Fixes #11.
;; 
;; 2015-03-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-read): Return immediately for less than 2 candidates
;; 
;; 2015-03-16  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	counsel.el: Add
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Truncate candidates to window width in the minibuffer
;; 
;; 	* ivy.el (ivy-completions): Update.
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add some rudimentary history handling
;; 
;; 	* ivy.el (ivy-minibuffer-map): Bind "M-n", "M-p", and "C-g".
;; 	(ivy-history): New defvar.
;; 	(ivy-read): Update.
;; 	(ivy--minibuffer-setup): Offer thing-at-point for "M-n".
;; 	(ivy--default): New defvar.
;; 
;; 	Re #16.
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el (ivy-previous-line): Change to `cl-decf'
;; 
;; 	Re #15
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Make ivy the default back end
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Don't recenter unless necessary
;; 
;; 	* swiper.el (swiper--update-input-ivy): Update.
;; 
;; 2015-03-15  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add anchoring
;; 
;; 	* ivy.el (ivy-read): Add optional argument INDEX. It's the index of
;; 	 initally selected entry.
;; 	(ivy-completions): Update.
;; 
;; 	* swiper.el (swiper--ivy): Call `ivy-read' with `line-number-at-pos'.
;; 
;; 	Fixes #16
;; 
;; 2015-03-15  Xavier Garrido  <xavier.garrido@gmail.com>
;; 
;; 	Fix use of cl-incf
;; 
;; 	* ivy.el (ivy-next-line): Update.
;; 
;; 	Fixes #15
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Require delsel for `minibuffer-keyboard-quit'
;; 
;; 	* ivy.el (ivy-backward-delete-char): Update.
;; 
;; 	Fixes #14.
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Save position before last search
;; 
;; 	* swiper.el (swiper--ivy): Forward to `swiper--action'.
;; 	(swiper--helm): Use `swiper--action-helm'.
;; 	(swiper--action-helm): New defun.
;; 	(swiper--action): Generalize, use push-mark, similarly to `isearch'.
;; 
;; 	Fixes #12.
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Reveal invisible overlays
;; 
;; 	* swiper.el (swiper--ivy): Update.
;; 	(swiper--ensure-visible): New defun.
;; 	(swiper--action): Update.
;; 
;; 	Fixes #11.
;; 
;; 2015-03-14  Steve Purcell  <steve@sanityinc.com>
;; 
;; 	Inherit standard faces by default
;; 
;; 	Every time a new custom face definition is created, it breaks every
;; 	existing theme.	 Better, then, to inherit standard faces by default.
;; 
;; 	This commit has the side benefit of making the faces defined here
;; 	legible in themes with dark backgrounds.
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Restore original point on canceling
;; 
;; 	* swiper.el (swiper--opoint): New defvar.
;; 	(swiper): Update.
;; 	(swiper--ivy): Update.
;; 
;; 	Fixes #9.
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Add `ivy-exit'
;; 
;; 	* ivy.el (ivy-done): Update.
;; 	(ivy-read): Update.
;; 	(ivy-exit): New defvar.
;; 
;; 2015-03-14  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add initial-input optional argument
;; 
;; 	* swiper.el (swiper): Update.
;; 	(swiper--ivy): Update.
;; 	(swiper--helm): Update.
;; 
;; 	* ivy.el (ivy-read): Update.
;; 
;; 	Fixes #8.
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Account for zero-length regex matches
;; 
;; 	* swiper.el (swiper--add-overlays): Update.
;; 
;; 	Fixes #6.
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el: Use `with-selected-window' instead of `with-current-buffer'
;; 
;; 	* swiper.el (swiper--buffer): Remove.
;; 	(swiper--init): Update.
;; 	(swiper--update-input-helm): Update.
;; 	(swiper--update-input-ivy): Update.
;; 	(swiper--update-sel): Update.
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	ivy.el: Improve the highlighting in the minibuffer
;; 
;; 	* ivy.el (ivy--add-face): Use `add-face-text-property' if it's
;; 	 available. You need to upgrade to Emacs 24.4 to get this feature.
;; 	(ivy-completions): Use `ivy--add-face'.
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Update
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update dependencies.
;; 
;; 	* ivy.el: Depend on emacs "24.1".
;; 
;; 	* swiper.el: Depend on ivy "0.1.0".
;; 
;; 2015-03-13  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add `ivy' back end
;; 
;; 	* ivy.el: New completion back end.
;; 
;; 	* swiper.el: Package doesn't depend on `helm'.
;; 	(ivy): Depend on `ivy'.
;; 	(swiper-completion-method): New defcustom.
;; 	(swiper--window): New var.
;; 	(swiper--helm-keymap): Rename from `swiper--keymap'.
;; 	(swiper): Change to a dispatch.
;; 	(swiper--init): New defun.
;; 	(swiper--ivy): New command.
;; 	(swiper--helm): New command.
;; 	(swiper--cleanup): New defun.
;; 	(swiper--update-input-helm): Rename from `swiper--update-input'.
;; 	(swiper--update-input-ivy): New defun.
;; 	(swiper--add-overlays): New defun.
;; 	(swiper--update-sel): Update.
;; 	(swiper--subexps):
;; 	(swiper--regex-hash):
;; 	(swiper--regex): Move to ivy.
;; 	(swiper--action): Update.
;; 
;; 2015-03-11  killdash9  <killdash9>
;; 
;; 	familiar isearch key bindings while helm is active
;; 
;; 2015-03-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--regex): Update signature
;; 
;; 2015-03-11  Syohei YOSHIDA  <syohex@gmail.com>
;; 
;; 	Use cl-lib macros instead of cl.el
;; 
;; 2015-03-11  Syohei YOSHIDA  <syohex@gmail.com>
;; 
;; 	add autoload cookie for lazy loading
;; 
;; 2015-03-11  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add dependency on emacs 24.1
;; 
;; 2015-03-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Add compatibility alias for `font-lock-ensure'
;; 
;; 	* swiper.el (swiper-font-lock-ensure): Add.
;; 
;; 	Fixes #1.
;; 
;; 2015-03-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	README.md: Add
;; 
;; 2015-03-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	swiper.el (swiper--regex): Zero groups without space
;; 
;; 	* swiper.el (swiper--update-input): Update the face order accordingly.
;; 
;; 2015-03-10  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Update call to `font-lock-ensure'
;; 
;; 	* swiper.el (swiper--candidates): `font-lock-ensure' takes no arguments
;; 	 in 24.4.1.
;; 
;; 2015-03-09  Oleh Krehel	 <ohwoeowho@gmail.com>
;; 
;; 	Initial import
;; 


(provide 'swiper)

;;; swiper.el ends here
