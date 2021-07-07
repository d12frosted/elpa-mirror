;;; helm-etags-plus.el --- Another Etags helm.el interface

;; Created: 2011-02-23
;; Last Updated: 纪秀峰 2014-07-27 16:56:24
;; Version: 1.1
;; Package-Version: 20201003.1424
;; Package-Commit: 52598fe69636add4b62cd9873041de5c6db9b7ac
;; Author: 纪秀峰(Joseph) <jixiuf@gmail.com>
;; Copyright (C) 2015, 纪秀峰(Joseph), all rights reserved.
;; URL       :https://github.com/jixiuf/helm-etags-plus
;; Keywords: helm, etags
;; Package-Requires: ((helm "1.7.8"))
;;
;; Features that might be required by this library:
;;
;; `helm' `etags'
;;
;;
;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This package use `helm' as an interface to find tag with Etags.
;;
;;  it support multiple tag files.
;;  and it can recursively searches each parent directory for a file named
;;  'TAGS'. so you needn't add this special file to `tags-table-list'
;;
;;  if you use GNU/Emacs ,you can set `tags-table-list' like this.
;;  (setq tags-table-list '("/path/of/TAGS1" "/path/of/TAG2"))
;;
;;  (global-set-key "\M-." 'helm-etags-plus-select)
;;       `M-.' default use symbol under point as tagname
;;       `C-uM-.' use pattern you typed as tagname
;;
;; helm-etags-plus.el also support history go back ,go forward and list tag
;; histories you have visited.(must use commands list here:)
;;  `helm-etags-plus-history'
;;    List all tag you have visited with `helm'.
;;  `helm-etags-plus-history-go-back'
;;    Go back cyclely.
;;  `helm-etags-plus-history-go-forward'
;;    Go Forward cyclely.
;;
;; if you want to work with `etags-table.el' ,you just need
;; add this line to to init file after loading etags-table.el
;;
;;     (add-hook 'helm-etags-plus-select-hook 'etags-table-recompute)
;;    (setq etags-table-alist
;;     (list
;;        '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
;;        '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
;;        '(".*\\.[ch]$" "/usr/local/include/TAGS")
;;        ))
;;
;;; Installation:
;;
;; Just put helm-etags-plus.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'helm-etags-plus)
;;
;; No need more.
;;
;; I use GNU/Emacs,and this is my config file about etags
;; (require 'helm-etags-plus)
;; (global-set-key "\M-." 'helm-etags-plus-select)
;; ;;list all visited tags
;; (global-set-key "\M-*" 'helm-etags-plus-history)
;; ;;go back directly
;; (global-set-key "\M-," 'helm-etags-plus-history-go-back)
;; ;;go forward directly
;; (global-set-key "\M-/" 'helm-etags-plus-history-go-forward)
;;
;;  if you do not want use bm.el for navigating history
;;  you could
;; (autoload 'bm-bookmark-add "bm" "add bookmark")
;;      (add-hook 'helm-etags-plus-before-jump-hook 'bm-bookmark-add)
;; or   (add-hook 'helm-etags-plus-before-jump-hook '(lambda()(bm-bookmark-add nil nil t)))
;; (setq bm-in-lifo-order t)
;;  then use bm-previous bm-next

;;
;; and how to work with etags-table.el
;; (require 'etags-table)
;; (setq etags-table-alist
;;       (list
;;        '("/home/me/Projects/foo/.*\\.[ch]$" "/home/me/Projects/lib1/TAGS" "/home/me/Projects/lib2/TAGS")
;;        '("/home/me/Projects/bar/.*\\.py$" "/home/me/Projects/python/common/TAGS")
;;        '("/tmp/.*\\.c$"  "/java/tags/linux.tag" "/tmp/TAGS" )
;;        '(".*\\.java$"  "/opt/sun-jdk-1.6.0.22/src/TAGS" )
;;        '(".*\\.[ch]$"  "/java/tags/linux.ctags")
;;        ))
;; (add-hook 'helm-etags-plus-select-hook 'etags-table-recompute)

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `helm-etags-plus-select'
;;    Find Tag using `etags' and `helm'
;;  `helm-etags-plus-history-go-back'
;;    Go Back.
;;  `helm-etags-plus-history-go-forward'
;;    Go Forward.
;;  `helm-etags-plus-history'
;;    show all tag historys using `helm'

;;; Code:

;; Some functions are borrowed from helm-etags.el and etags-select.el.

;;; Require
;; (require 'custom)
(require 'etags)
(require 'helm)
(require 'helm-utils)
;; (require 'helm-config nil t)        ;optional
(eval-when-compile
   (require 'helm-multi-match nil t)
  )
;;  ;optional

;;; Custom

(defgroup helm-etags-plus nil
  "Another Etags helm.el interface."
  :prefix "helm-etags-plus-"
  :group 'etags)

(defcustom helm-etags-plus-use-absolute-path nil
  "Not nil means means use absolute filename.
nil means use relative filename as the display,
 search '(DISPLAY . REAL)' in helm.el for more info."
  :type '(choice (const nil) (const t) (const absolute))
  :group 'helm-etags-plus)

(defcustom helm-etags-plus-split-char ?.
  "A char between tag and filepath."
  :type 'string
  :group 'helm-etags-plus)

(defcustom helm-etags-plus-follow-symlink-p t
  "You might want to set `find-file-visit-truename' to nil if you
set this to nil."
  :type 'boolean
  :group 'helm-etags-plus)

(defcustom helm-etags-plus-min-pattern-length 3
  "Minimum length of pattern to search for."
  :group 'helm-etags-plus
  :type 'integer)

(defcustom helm-etags-plus-highlight-after-jump t
  "*If non-nil, temporarily highlight the tag after you jump to it."
  :group 'helm-etags-plus
  :type 'boolean)

(defcustom helm-etags-plus-highlight-delay 0.2
  "*How long to highlight the tag."
  :group 'helm-etags-plus
  :type 'number)

(defcustom helm-etags-plus-auto-create-tags t
  "If no TAGS found,prompt creating one by `ctags-update' if ctags-update.el exists."
  :group 'helm-etags-plus
  :type 'number)

(defface helm-etags-plus-highlight-face
  '((t (:foreground "white" :background "cadetblue4" :bold t)))
  "Font Lock mode face used to highlight tags.
  (borrowed from etags-select.el)"
  :group 'helm-etags-plus)

(defface helm-etags-plus-file-face
  '((t (:foreground "Lightgoldenrod4"
                    :underline t)))
  "Face used to highlight etags filenames."
  :group 'helm-etags-plus)

(defun helm-etags-plus-highlight (beg end)
  "Highlight a region temporarily.
\(borrowed from etags-select.el)
Argument BEG begin position.
Argument END end position."
  (let ((ov (make-overlay beg end)))
      (overlay-put ov 'face 'helm-etags-plus-highlight-face)
      (sit-for helm-etags-plus-highlight-delay)
      (delete-overlay ov)))

;;; Hooks

(defvar helm-etags-plus-select-hook nil
  "Hooks run before `helm' funcion with source `helm-etags-plus-source'.")
(defvar helm-etags-plus-before-jump-hook nil
  "Hooks run before jump to tag location.")
(defvar helm-etags-plus-after-jump-hook nil
  "Hooks run afterjump to tag location.")

;;; Variables
(defvar  helm-etags-plus-markers (make-ring 8))

(defvar helm-etags-plus-cur-mark nil
  "A marker in `helm-etags-plus-markers'.
going back and going forward are related to this variable.")

;; (defvar helm-etags-plus-history-tmp-marker nil
;;   "this variable will remember current position
;;    when you call `helm-etags-plus-history'.
;;   after you press `RET' execute `helm-etags-plus-history-action'
;;  it will be push into `helm-etags-plus-markers'")
(defvar helm-etags-plus-tag-table-buffers nil
  "Each time `helm-etags-plus-select' is executed ,it will set this variable.")

(defvar helm-etags-plus--input-idle-delay 0.8
"See `helm-idle-delay',I will set it locally in `helm-etags-plus-select'.")

(defvar helm-etags-plus--prev-opened-buf-in-persist-action nil
  "Record it to kill-it in persistent-action,in order to not open too much buffer.")

(defvar helm-etags-plus-prev-matched-pattern nil
  "Work with `helm-etags-plus-candidates-cache'.
the value is (car (helm-mm-split-pattern helm-pattern))
:the first part of `helm-pattern', the matched
 candidates is saved in `helm-etags-plus-candidates-cache'. when current
'(car (helm-mm-split-pattern helm-pattern))' is equals to this value
then the cached candidates can be reused ,needn't find from the tag file.")

(defvar helm-etags-plus-candidates-cache nil
  "Documents see `helm-etags-plus-prev-matched-pattern'.")
(defvar helm-etags-plus-untransformed-helm-pattern
  "this variable is seted in func of transformed-pattern .and is used when
getting candidates.")

;;; Functions

(defun helm-etags-plus-case-fold-search ()
  "Get case-fold search."
  (when (boundp 'tags-case-fold-search)
    (if (memq tags-case-fold-search '(nil t))
        tags-case-fold-search
      case-fold-search)))

(defun helm-etags-plus-file-truename(filename)
  (if helm-etags-plus-follow-symlink-p
      (file-truename filename)
    filename))

(defun helm-etags-plus-get-symbal-at-point()
  (let(symbol )
    (cond ( (equal major-mode 'verilog-mode)
            (with-syntax-table (copy-syntax-table (syntax-table))
              (modify-syntax-entry ?`  ".");treat . as punctuation character
              (setq symbol (thing-at-point 'symbol))))
          (t
           (setq symbol (thing-at-point 'symbol))))
    symbol))

(defun helm-etags-plus-find-tags-file ()
  "Recursively search each parent directory for a file named 'TAGS'.
and returns the path to that file or nil if a tags file is not found.
Returns nil if the buffer is not visiting a file"
(let ((tag-root-dir (locate-dominating-file default-directory "TAGS")))
    (if tag-root-dir
        (expand-file-name "TAGS" tag-root-dir)
      nil)))

(defun helm-etags-plus-get-tag-files()
  "Get tag files."
  (let ((local-tag  (helm-etags-plus-find-tags-file)))
    (if local-tag
        (add-to-list 'tags-table-list (helm-etags-plus-find-tags-file))
      (when (and (featurep 'ctags-update)
                 (boundp 'ctags-update))
        (call-interactively 'ctags-update)))
    (dolist (tag tags-table-list)
      (when (not (file-exists-p tag))
        (setq  tags-table-list (delete tag tags-table-list))))
    (mapcar 'tags-expand-table-name tags-table-list)))

(defun helm-etags-plus-rename-tag-buffer-maybe(buf)
  (with-current-buffer buf
    (if (string-match "^ \\*Helm" (buffer-name))
        buf
      (rename-buffer (concat" *Helm etags-plus:" (buffer-name)
                            "-" (number-to-string (random)) "*") nil)
      ))buf)

(defun helm-etags-plus-get-tag-table-buffer (tag-file)
  "Get tag table buffer for a tag file.
Argument TAG-FILE tag file name."
  (when (file-exists-p tag-file)
    (let ((tag-table-buffer) (current-buf (current-buffer))
          (tags-revert-without-query t)
          (large-file-warning-threshold nil)
          (tags-add-tables t))

        (visit-tags-table-buffer tag-file)
        (setq tag-table-buffer (find-buffer-visiting tag-file))
      (set-buffer current-buf)
      (helm-etags-plus-rename-tag-buffer-maybe tag-table-buffer))))

(defun helm-etags-plus-get-avail-tag-bufs()
  "Get tag table buffer for a tag file."
  (setq helm-etags-plus-tag-table-buffers
        (delete nil (mapcar 'helm-etags-plus-get-tag-table-buffer
                            (helm-etags-plus-get-tag-files)))))

(defun helm-etags-plus-get-candidates-cache()
  "for example when the `helm-pattern' is 'toString System pub'
   only 'toString' is treated as tagname,and
`helm-etags-plus-candidates-from-all-file'
will search `toString' in all tag files. and the found
 candidates is stored in `helm-etags-plus-candidates-cache'
'toString' is stored in `helm-etags-plus-prev-matched-pattern'
so when the `helm-pattern' become to 'toString System public'
needn't search tag file again."
  (let ((pattern (car (helm-mm-split-pattern helm-etags-plus-untransformed-helm-pattern))));;default use whole helm-pattern to search in tag files
    ;; first collect candidates using first part of helm-pattern
    ;; (when (featurep 'helm-match-plugin)
    ;;   ;;for example  (helm-mm-split-pattern "boo far") -->("boo" "far")
    ;;   (setq pattern  (car (helm-mm-split-pattern helm-etags-plus-untransformed-helm-pattern))))
    (cond
     ((or (string-equal "" pattern) (string-equal "\\_<\\_>" pattern))
       nil)
     ((not  (string-equal helm-etags-plus-prev-matched-pattern pattern))
       (setq helm-etags-plus-prev-matched-pattern pattern)
       (setq helm-etags-plus-candidates-cache (helm-etags-plus-candidates-from-all-file pattern)))
     (t helm-etags-plus-candidates-cache))))

(defun helm-etags-plus-candidates-from-all-file(first-part-of-helm-pattern)
  (let (candidates)
    (dolist (tag-table-buffer helm-etags-plus-tag-table-buffers)
      (setq candidates
            (append
             candidates
             (helm-etags-plus-candidates-from-tag-file
              first-part-of-helm-pattern tag-table-buffer))))
    candidates))

(defun helm-etags-plus-candidates-from-tag-file (tagname tag-table-buffer)
  "Find TAGNAME in TAG-TABLE-BUFFER."
  (catch 'failed
    (let ((case-fold-search (helm-etags-plus-case-fold-search))
          tag-info tag-line src-file-path full-tagname
          tag-regex
          tagname-regexp-quoted
          candidates)
      (if (string-match "\\\\_<\\|\\\\_>[ \t]*" tagname)
          (progn
            (setq tagname (replace-regexp-in-string "\\\\_<\\|\\\\_>[ \t]*" ""  tagname))
            (setq tagname-regexp-quoted (regexp-quote tagname))
            (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.']"  tagname-regexp-quoted "\\)\^A"
                                    "\\|" "\^?"  tagname-regexp-quoted "\^A"
                                    "\\|" "\\<"  tagname-regexp-quoted "[ \f\t()=,;]*\^?[0-9,]"
                                    "\\)")))
        (setq tagname-regexp-quoted (regexp-quote tagname))
        (setq tag-regex (concat "^.*?\\(" "\^?\\(.+[:.'].*"  tagname-regexp-quoted ".*\\)\^A"
                                "\\|" "\^?.*"  tagname-regexp-quoted ".*\^A"
                                "\\|" ".*"  tagname-regexp-quoted ".*[ \f\t()=,;]*\^?[0-9,]"
                                "\\)")))
      (with-current-buffer tag-table-buffer
        (modify-syntax-entry ?_ "w")
        (goto-char (point-min))
        (while (search-forward  tagname nil t) ;;take care this is not re-search-forward ,speed it up
          (beginning-of-line)
          (when (re-search-forward tag-regex (point-at-eol) 'goto-eol)
            (setq full-tagname (or (match-string-no-properties 2) tagname))
            (beginning-of-line)
            (save-excursion (setq tag-info (etags-snarf-tag)))
            (re-search-forward "\\s-*\\(.*?\\)\\s-*\^?" (point-at-eol) t)
            (setq tag-line (match-string-no-properties 1))
            (setq tag-line (replace-regexp-in-string  "/\\*.*\\*/" "" tag-line))
            (setq tag-line (replace-regexp-in-string  "\t" (make-string tab-width ? ) tag-line))
            (end-of-line)
            ;;(setq src-file-path (etags-file-of-tag))
            (setq src-file-path   (helm-etags-plus-file-truename (etags-file-of-tag)))

            (add-to-list 'candidates (helm-etags-plus-build-calidate tag-table-buffer tag-line src-file-path tag-info full-tagname))))
        (modify-syntax-entry ?_ "_"))
      candidates)))

(defun helm-etags-plus-build-calidate(tag-table-buffer tag-line src-file-path tag-info full-tagname)
  (let* ((display)
         (real (list  src-file-path tag-info full-tagname))
         (src-file-name (file-name-nondirectory src-file-path))
         (src-file-parent (file-name-directory src-file-path))
         (prefix src-file-name)
         (suffix src-file-parent)
         tag-table-parent)
    (cond
     ((equal helm-etags-plus-use-absolute-path nil) ;relative
      (setq tag-table-parent (helm-etags-plus-file-truename (file-name-directory (buffer-file-name tag-table-buffer))))
      (when (string-match  (regexp-quote tag-table-parent) src-file-path)
        (setq suffix (substring src-file-parent (length  tag-table-parent))))))
    (setq display (concat (propertize prefix 'face 'helm-etags-plus-file-face)
                          ": " tag-line
                          (or (ignore-errors
                                (make-string (- (window-text-width)
                                                8
                                                (string-width tag-line)
                                                (string-width  suffix)
                                                (string-width  prefix))
                                             helm-etags-plus-split-char)) "")
                          (propertize suffix 'face 'helm-etags-plus-file-face)))
    (cons display real)))

(defun helm-etags-plus-find-tag(candidate)
  "Find tag that match CANDIDATE from `tags-table-list'.
   And switch buffer and jump tag position.."
  (let ((src-file-path (car candidate))
        (tag-info (nth 1 candidate))
        (tagname (nth 2 candidate))
        src-file-buf)
    (when (file-exists-p src-file-path)
      ;; Jump to tag position when
      ;; tag file is valid.
      (setq src-file-buf (find-file src-file-path))
      (etags-goto-tag-location  tag-info)

      (beginning-of-line)
      (when (search-forward tagname (point-at-eol) t)
        (goto-char (match-beginning 0))
        (setq tagname (thing-at-point 'symbol))
        (beginning-of-line)
        (search-forward tagname (point-at-eol) t)
        (goto-char (match-beginning 0))
        (when(and helm-etags-plus-highlight-after-jump
                  (not helm-in-persistent-action))
          (helm-etags-plus-highlight (match-beginning 0) (match-end 0))))

      (when (and helm-in-persistent-action ;;color
                 (fboundp 'helm-highlight-current-line))
        (helm-highlight-current-line))

      (if helm-in-persistent-action ;;prevent from opening too much buffer in persistent action
          (progn
            (if (and helm-etags-plus--prev-opened-buf-in-persist-action
                     (not (equal helm-etags-plus--prev-opened-buf-in-persist-action src-file-buf)))
                (kill-buffer  helm-etags-plus--prev-opened-buf-in-persist-action))
            (setq helm-etags-plus--prev-opened-buf-in-persist-action src-file-buf))
        (setq helm-etags-plus--prev-opened-buf-in-persist-action nil)))))

(defun helm-etags-plus--pos-in-same-symbol-p(marker1 marker2)
  "check whether `marker1' and `marker2' are at the same place or not"
  (cond
   ((and (helm-etags-plus-is-marker-available marker1)
         (helm-etags-plus-is-marker-available marker2)
         (equal (marker-buffer marker1) (marker-buffer marker2)))
    (let((pos1 (marker-position marker1))
         (pos2 (marker-position marker2))
         bounds1 bounds2)
      (setq bounds1
            (unwind-protect
                (save-excursion
                  (goto-char pos1)
                  (bounds-of-thing-at-point 'symbol) )
              nil))
      (setq bounds2
            (unwind-protect
                (save-excursion
                  (goto-char pos2)
                  (bounds-of-thing-at-point 'symbol) )
              nil))
      (and bounds1 bounds1
           (equal bounds1 bounds2))))
   (t nil)))

(defun helm-etags-plus-goto-location (candidate)
  "Goto location.
Argument CANDIDATE the candidate."
  (unless helm-in-persistent-action
    ;;you can use `helm-etags-plus-history' go back
    (when (or  (ring-empty-p helm-etags-plus-markers)
               (not (helm-etags-plus--pos-in-same-symbol-p  (point-marker)
                                           (ring-ref helm-etags-plus-markers 0))))
      (let ((index (ring-member helm-etags-plus-markers (point-marker))))
        (when index (ring-remove helm-etags-plus-markers index)))
      (ring-insert helm-etags-plus-markers (point-marker))
      ))

  (run-hooks 'helm-etags-plus-before-jump-hook)
  (helm-etags-plus-find-tag candidate);;core func.

  (when (or  (ring-empty-p helm-etags-plus-markers)
             (not (helm-etags-plus--pos-in-same-symbol-p  (point-marker)
                                         (ring-ref helm-etags-plus-markers 0))))
    (let ((index (ring-member helm-etags-plus-markers (point-marker))))
      (when index (ring-remove helm-etags-plus-markers index)))
    (ring-insert helm-etags-plus-markers (point-marker))
    (setq helm-etags-plus-cur-mark (point-marker)))
  (run-hooks 'helm-etags-plus-after-jump-hook))

;; if you want call helm-etags in your special function
;; you can do it like this
;; (condition-case nil
;;     (helm-etags-plus-select-internal   (concat "\\_<" "helm-etags-plus-dddselect-internal" "\\_>"))
;;   (error (message "do something when no candidates found")))
(defun helm-etags-plus-select-internal(&optional pattern)
  "Find Tag using `etags' and `helm' `pattern' is a regexp."
  (interactive "P")
  (let ((helm-execute-action-at-once-if-one t)
        (helm-quit-if-no-candidate  (lambda()(error "No candidates")))
        (helm-maybe-use-default-as-input nil)
        (helm-candidate-number-limit nil)
        (helm-input-idle-delay helm-etags-plus--input-idle-delay))
    (when (and pattern (string-equal "" pattern) ) (setq helm-quit-if-no-candidate nil) )
    (run-hooks 'helm-etags-plus-select-hook)
    (helm  :sources 'helm-etags-plus-source
           ;; :default (concat "\\_<" (thing-at-point 'symbol) "\\_>")
           ;; Initialize input with current symbol
           :input (or pattern (concat "\\_<" (helm-etags-plus-get-symbal-at-point) "\\_>"))
           :prompt (format "Find Tag (at least %d chars): " helm-etags-plus-min-pattern-length))))

;; if you want call helm-etags in your special function
;; you can do it like this
;; (condition-case nil
;;     (helm-etags-plus-select)
;;   (error (message "do something when no candidates found")))
;;;###autoload
(defun helm-etags-plus-select(&optional arg)
  "Find Tag using `etags' and `helm'"
  (interactive "P")
  (cond
   ((equal arg '(4))                  ;C-u
    (helm-etags-plus-select-internal "")) ;waiting for you input pattern
   (t (helm-etags-plus-select-internal))))  ;use thing-at-point as symbol

(defvar helm-etags-plus-source
  '((name . "Etags+")
    (init . helm-etags-plus-get-avail-tag-bufs)
    (candidates . helm-etags-plus-get-candidates-cache)
    (volatile);;candidates
    (pattern-transformer (lambda (helm-pattern)
                           (setq helm-etags-plus-untransformed-helm-pattern helm-pattern)
                           (regexp-quote (replace-regexp-in-string "\\\\_<\\|\\\\_>" ""  helm-pattern))))
    (requires-pattern . helm-etags-plus-min-pattern-length) ;need at least N chars
    ;; (delayed);; (setq helm-etags-plus--input-idle-delay 1)
    (action ("Goto the location" . helm-etags-plus-goto-location))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Go Back and Go Forward

;;util func

;;(helm-etags-plus-is-marker-avaiable (ring-ref helm-etags-plus-markers 0))
(defun helm-etags-plus-is-marker-available(marker)
  "return nil if marker is nil or  in dead buffer ,
   return marker if it is live"
  (if (and marker
           (markerp marker)
           (marker-buffer marker))
      marker
    ))
;;; func about history
(defun helm-etags-plus-hist-get-candidate-from-marker(marker)
  "genernate candidate from marker candidate= (display . marker)."
  (let ((buf (marker-buffer marker))
        (pos (marker-position marker))
        line-num line-text candidate display
        file-name empty-string)
    (when  buf
      ;;      (save-excursion
      ;;        (set-buffer buf)
      (with-current-buffer buf
        (setq file-name  (buffer-name))
        (goto-char pos)
        (setq line-num (int-to-string (count-lines (point-min) pos)))
        (setq line-text (buffer-substring-no-properties (point-at-bol)(point-at-eol)))
        (setq line-text (replace-regexp-in-string "^[ \t]*\\|[ \t]*$" "" line-text))
        (setq line-text (replace-regexp-in-string  "/\\*.*\\*/" "" line-text))
        (setq line-text (replace-regexp-in-string  "\t" (make-string tab-width ? ) line-text)))
      ;;          )
      (if (equal marker helm-etags-plus-cur-mark)
          ;;this one will be preselected
          (setq line-text (concat line-text "\t")))
      (setq empty-string  (or (ignore-errors
                                (make-string (- (window-width) 4
                                                (string-width  line-num)
                                                (string-width file-name)
                                                (string-width line-text))
                                             ? )) " "))
      (setq display (concat line-text empty-string
                            file-name ":[" line-num "]"))
      (setq candidate  (cons display marker)))))

;; time_init
(defun helm-etags-plus-history-candidates()
  "generate candidates from `helm-etags-plus-markers'.
  and remove unavailable markers in `helm-etags-plus-markers'"
   (mapcar 'helm-etags-plus-hist-get-candidate-from-marker (ring-elements helm-etags-plus-markers)))

(defun helm-etags-plus-history-init()
  "remove #<marker in no buffer> from `helm-etags-plus-markers'.
   and remove those markers older than #<marker in no buffer>."
  (let ((tmp-marker-ring))
    (while (not (ring-empty-p helm-etags-plus-markers))
      (helm-aif (helm-etags-plus-is-marker-available (ring-remove helm-etags-plus-markers 0))
          (setq tmp-marker-ring (append tmp-marker-ring (list it)));;new item first
        (while (not (ring-empty-p helm-etags-plus-markers));;remove all old marker
          (ring-remove helm-etags-plus-markers))))
    ;;reinsert all available marker to `helm-etags-plus-markers'
    (mapcar (lambda(marker) (ring-insert-at-beginning helm-etags-plus-markers marker)) tmp-marker-ring))
  )

(defun helm-etags-plus-history-clear-all(&optional candidate)
  "param `candidate' is unused."
  (while (not (ring-empty-p helm-etags-plus-markers));;remove all marker
    (ring-remove helm-etags-plus-markers)))


;;;###autoload
(defun helm-etags-plus-history-go-back()
  "Go Back."
  (interactive)
  (helm-etags-plus-history-init)
  (when
      (let ((next-marker))
        (cond ((and (helm-etags-plus-is-marker-available helm-etags-plus-cur-mark)
                    (ring-member helm-etags-plus-markers helm-etags-plus-cur-mark))
               (setq next-marker (ring-next helm-etags-plus-markers helm-etags-plus-cur-mark)))
              ((not(ring-empty-p helm-etags-plus-markers))
               (setq next-marker  (ring-ref helm-etags-plus-markers 0)))
              (t nil))
        (when next-marker
          (helm-etags-plus-history-go-internel next-marker)
          (setq helm-etags-plus-cur-mark next-marker)))))

;;;###autoload
(defun helm-etags-plus-history-go-forward()
  "Go Forward."
  (interactive)
  (helm-etags-plus-history-init)
  (when
      (let ((prev-marker))
        (cond ((and (helm-etags-plus-is-marker-available helm-etags-plus-cur-mark)
                    (ring-member helm-etags-plus-markers helm-etags-plus-cur-mark))
               (setq prev-marker (ring-previous helm-etags-plus-markers helm-etags-plus-cur-mark)))
              ((not(ring-empty-p helm-etags-plus-markers))
               (setq prev-marker  (ring-ref helm-etags-plus-markers 0)))
              (t nil))
        (when prev-marker
          (helm-etags-plus-history-go-internel prev-marker)
          (setq helm-etags-plus-cur-mark prev-marker)))))

(defun helm-etags-plus-history-go-internel (candidate-marker)
  "Go to the location depend on candidate.
Argument CANDIDATE-MARKER candidate marker."
  (let ((buf (marker-buffer candidate-marker))
        (pos (marker-position candidate-marker)))
    (when buf
      (switch-to-buffer buf)
      (set-buffer buf)
      (goto-char pos))))

;; (action .func),candidate=(Display . REAL), now in this func
;; param candidate is 'REAL' ,the marker.
(defun helm-etags-plus-history-action-go(candidate)
  "List all history."
  (helm-etags-plus-history-go-internel candidate)
  (unless  helm-in-persistent-action
    (setq helm-etags-plus-cur-mark candidate))
  (when  helm-in-persistent-action
    (helm-highlight-current-line)))

(defvar helm-etags-plus-history-source
  '((name . "Etags+ History: ")
    (header-name .( (lambda (name) (concat name "`RET': Go ,`C-z' Preview. `C-e': Clear all history."))))
    (init .  helm-etags-plus-history-init)
    (candidates . helm-etags-plus-history-candidates)
    ;;        (volatile) ;;maybe needn't
    (action . (("Go" . helm-etags-plus-history-action-go)
               ("Clear all history" . helm-etags-plus-history-clear-all)))))

;;;###autoload
(defun helm-etags-plus-history()
  "show all tag historys using `helm'"
  (interactive)
  (let ((helm-execute-action-at-once-if-one t)
        (helm-quit-if-no-candidate
         (lambda () (message "No history record in `helm-etags-plus-markers'"))))
    (helm :sources    '(helm-etags-plus-history-source)
          :input      ""
          :preselect  "\t")))           ;if an candidate ,then this line is preselected

(provide 'helm-etags-plus)

;;; helm-etags-plus.el ends here.

