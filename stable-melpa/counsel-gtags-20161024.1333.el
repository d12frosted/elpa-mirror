;;; counsel-gtags.el --- ivy for GNU global -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-counsel-gtags
;; Package-Version: 20161024.1333
;; Package-Commit: 8066dd4cd6eb157345fb43788bacf2c5d746b497
;; Version: 0.01
;; Package-Requires: ((emacs "24.3") (counsel "0.8.0"))

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

;; `counsel-gtags.el' provides `ivy' interface of GNU GLOBAL.

;;; Code:

(require 'counsel)
(require 'cl-lib)

(declare-function cygwin-convert-file-name-from-windows "cygw32.c")
(declare-function cygwin-convert-file-name-to-windows "cygw32.c")
(declare-function tramp-file-name-localname "tramp")
(declare-function tramp-dissect-file-name "tramp")

(defgroup counsel-gtags nil
  "`counsel' for GNU Global"
  :group 'counsel)

(defcustom counsel-gtags-ignore-case nil
  "Ignore case in search command."
  :type 'boolean)

(defcustom counsel-gtags-path-style 'root
  "Candidates path style.
- `root' shows path from root where tag files are
- `relative' shows path from current directory
- `absolute' shows absolute path."
  :type '(choice (const :tag "Root of the current project" root)
                 (const :tag "Relative from the current directory" relative)
                 (const :tag "Absolute Path" absolute)))

(defcustom counsel-gtags-auto-update nil
  "*If non-nil, tag files are updated whenever a file is saved."
  :type 'boolean)

(defcustom counsel-gtags-update-interval-second 60
  "Tag updating interval seconds.
Tags are updated at `after-save-hook' after the seconds passed from last update.
Always update if value of this variable is nil."
  :type '(choice (integer :tag "Update interval seconds")
                 (boolean :tag "Update every time" nil)))

(defcustom counsel-gtags-prefix-key "\C-c"
  "If non-nil, it is used for the prefix key of gtags-xxx command."
  :type 'string)

(defcustom counsel-gtags-suggested-key-mapping nil
  "If non-nil, suggested key mapping is enabled."
  :type 'boolean)

(defconst counsel-gtags--prompts
  '((definition . "Find Definition: ")
    (reference  . "Find Reference: ")
    (pattern    . "Find Pattern: ")
    (symbol     . "Find Symbol: ")))

(defconst counsel-gtags--complete-options
  '((reference . "-r")
    (symbol    . "-s")
    (pattern   . "-g")))

(defvar counsel-gtags--last-update-time 0)
(defvar counsel-gtags--context nil)
(defvar counsel-gtags--original-default-directory nil
  "Last `default-directory' where command is invoked.")

(defun counsel-gtags--select-gtags-label ()
  (let ((labels '("default" "native" "ctags" "pygments")))
    (ivy-read "GTAGSLABEL(Default: default): " labels)))

(defun counsel-gtags--generate-tags ()
  (if (not (yes-or-no-p "File GTAGS not found. Run 'gtags'? "))
      (error "Abort generating tag files.")
    (let* ((root (read-directory-name "Root Directory: "))
           (label (counsel-gtags--select-gtags-label))
           (default-directory root))
      (message "gtags is generating tags....")
      (unless (zerop (process-file "gtags" nil nil nil "-q"
                                   (concat "--gtagslabel=" label)))
        (error "Faild: 'gtags -q'"))
      root)))

(defun counsel-gtags--root ()
  (or (getenv "GTAGSROOT")
      (locate-dominating-file default-directory "GTAGS")
      (counsel-gtags--generate-tags)))

(defsubst counsel-gtags--windows-p ()
  (memq system-type '(windows-nt ms-dos)))

(defun counsel-gtags--set-absolute-option-p ()
  (or (eq counsel-gtags-path-style 'absolute)
      (and (counsel-gtags--windows-p)
           (getenv "GTAGSLIBPATH"))))

(defun counsel-gtags--command-options (type &optional extra-options)
  (let ((options '("--result=grep")))
    (when extra-options
      (setq options (append extra-options options)))
    (let ((opt (assoc-default type counsel-gtags--complete-options)))
      (when opt
        (push opt options)))
    (when (counsel-gtags--set-absolute-option-p)
      (push "-a" options))
    (when counsel-gtags-ignore-case
      (push "-i" options))
    (when current-prefix-arg ;; XXX
      (push "-l" options))
    (when (getenv "GTAGSLIBPATH")
      (push "-T" options))
    options))

(defun counsel-gtags--complete-candidates (string type)
  (let ((cmd-options (counsel-gtags--command-options type)))
    (push "-c" cmd-options)
    (push (shell-quote-argument string) cmd-options)
    (counsel--async-command
     (mapconcat #'identity (cons "global" (reverse cmd-options)) " "))
    nil))

(defun counsel-gtags--file-and-line (candidate)
  (if (and (counsel-gtags--windows-p)
           (string-match-p "\\`[a-zA-Z]:" candidate)) ;; Windows Driver letter
      (when (string-match "\\`\\([^:]+:[^:]+:\\):\\([^:]+\\)" candidate)
        (list (match-string-no-properties 1)
              (string-to-number (match-string-no-properties 2))))
    (let ((fields (split-string candidate ":")))
      (list (cl-first fields) (string-to-number (cl-second fields))))))

(defun counsel-gtags--find-file (candidate)
  (with-ivy-window
    (swiper--cleanup)
    (cl-destructuring-bind (file line) (counsel-gtags--file-and-line candidate)
      (push (list :file (counsel-gtags--real-file-name) :line (line-number-at-pos))
            counsel-gtags--context)
      (let ((default-directory counsel-gtags--original-default-directory))
        (find-file file)
        (goto-char (point-min))
        (forward-line (1- line))
        (back-to-indentation)))))

(defun counsel-gtags--read-tag (type)
  (let ((default-val (thing-at-point 'symbol))
        (prompt (assoc-default type counsel-gtags--prompts))
        (comp-fn (lambda (string)
                   (counsel-gtags--complete-candidates string type))))
    (ivy-read prompt comp-fn
              :initial-input default-val
              :dynamic-collection t
              :unwind (lambda ()
                        (counsel-delete-process)
                        (swiper--cleanup))
              :caller 'counsel-gtags--read-tag)))

(defun counsel-gtags--tag-directory ()
  (with-temp-buffer
    (or (getenv "GTAGSROOT")
        (progn
          (unless (zerop (process-file "global" nil t nil "-p"))
            (error "GTAGS not found"))
          (goto-char (point-min))
          (let ((dir (buffer-substring-no-properties (point) (line-end-position))))
            (file-name-as-directory (if (eq system-type 'cygwin)
                                        (cygwin-convert-file-name-from-windows dir)
                                      dir)))))))

(defsubst counsel-gtags--construct-command (options &optional input)
  (mapconcat #'identity (append '("global") options (list (shell-quote-argument input))) " "))

(defun counsel-gtags--execute (type tagname encoding extra-options)
  (let* ((options (counsel-gtags--command-options type extra-options))
         (cmd (counsel-gtags--construct-command (reverse options) tagname))
         (default-directory default-directory)
         (coding-system-for-read encoding)
         (coding-system-for-write encoding))
    (counsel--async-command cmd nil)
    nil))

(defun counsel-gtags--select-file (type tagname &optional extra-options)
  (let* ((root (counsel-gtags--default-directory))
         (encoding buffer-file-coding-system)
         (comp-fn (lambda (_string)
                    (let ((default-directory root))
                      (counsel-gtags--execute type tagname encoding extra-options)))))
    (ivy-read "Pattern: " comp-fn
              :dynamic-collection t
              :unwind (lambda ()
                        (counsel-delete-process)
                        (swiper--cleanup))
              :action #'counsel-gtags--find-file
              :caller 'counsel-gtags--read-tag)))

;;;###autoload
(defun counsel-gtags-find-definition (tagname)
  "Find `tagname' definition."
  (interactive
   (list (counsel-gtags--read-tag 'definition)))
  (counsel-gtags--select-file 'definition tagname))

;;;###autoload
(defun counsel-gtags-find-reference (tagname)
  "Find `tagname' references."
  (interactive
   (list (counsel-gtags--read-tag 'reference)))
  (counsel-gtags--select-file 'reference tagname))

;;;###autoload
(defun counsel-gtags-find-symbol (tagname)
  "Find `tagname' references."
  (interactive
   (list (counsel-gtags--read-tag 'symbol)))
  (counsel-gtags--select-file 'symbol tagname))

(defconst counsel-gtags--include-regexp
  "\\`\\s-*#\\(?:include\\|import\\)\\s-*[\"<]\\(?:[./]*\\)?\\(.*?\\)[\">]")

(defun counsel-gtags--include-file ()
  (let ((line (buffer-substring-no-properties
               (line-beginning-position) (line-end-position))))
    (when (string-match counsel-gtags--include-regexp line)
      (match-string-no-properties 1 line))))

(defun counsel-gtags--read-file-name ()
  (let ((default-file (counsel-gtags--include-file))
        (candidates
         (with-temp-buffer
           (let* ((options (cl-case counsel-gtags-path-style
                             (absolute "-Poa")
                             (root "-Poc")
                             (relative ""))))
             (unless (zerop (process-file "global" nil t nil options))
               (error "Failed: collect file names."))
             (goto-char (point-min))
             (let (files)
               (while (not (eobp))
                 (push (buffer-substring-no-properties (point) (line-end-position)) files)
                 (forward-line 1))
               (reverse files))))))
    (ivy-read "Find File: " candidates
              :initial-input default-file)))

(defun counsel-gtags--default-directory ()
  (setq counsel-gtags--original-default-directory
        (cl-case counsel-gtags-path-style
          ((relative absolute) default-directory)
          (root (counsel-gtags--root)))))

;;;###autoload
(defun counsel-gtags-find-file (filename)
  "Find `filename' from tagged files."
  (interactive
   (list (counsel-gtags--read-file-name)))
  (let ((default-directory (counsel-gtags--default-directory)))
    (find-file filename)))

;;;###autoload
(defun counsel-gtags-pop ()
  "Jump back to previous point."
  (interactive)
  (let ((context (pop counsel-gtags--context)))
    (find-file (plist-get context :file))
    (goto-char (point-min))
    (forward-line (1- (plist-get context :line)))))

(defun counsel-gtags--make-gtags-sentinel (action)
  (lambda (process _event)
    (when (eq (process-status process) 'exit)
      (if (zerop (process-exit-status process))
          (message "Success: %s TAGS" action)
        (message "Failed: %s TAGS(%d)" action (process-exit-status process))))))

;;;###autoload
(defun counsel-gtags-create-tags (rootdir label)
  "Create tag files tags in `rootdir'. This command is asynchronous."
  (interactive
   (list (read-directory-name "Directory: " nil nil t)
         (counsel-gtags--select-gtags-label)))
  (let* ((default-directory rootdir)
         (proc-buf (get-buffer-create " *counsel-gtags-tag-create*"))
         (proc (start-file-process
                "counsel-gtags-tag-create" proc-buf
                "gtags" "-q" (concat "--gtagslabel=" label))))
    (set-process-sentinel
     proc
     (counsel-gtags--make-gtags-sentinel 'create))))


(defun counsel-gtags--real-file-name ()
  (let ((buffile (buffer-file-name)))
    (unless buffile
      (error "This buffer is not related to file."))
    (if (file-remote-p buffile)
        (tramp-file-name-localname (tramp-dissect-file-name buffile))
      (file-truename buffile))))

(defun counsel-gtags--read-tag-directory ()
  (let ((dir (read-directory-name "Directory tag generated: " nil nil t)))
    ;; On Windows, "gtags d:/tmp" work, but "gtags d:/tmp/" doesn't
    (directory-file-name (expand-file-name dir))))

(defsubst counsel-gtags--how-to-update-tags ()
  (cl-case (prefix-numeric-value current-prefix-arg)
    (4 'entire-update)
    (16 'generate-other-directory)
    (otherwise 'single-update)))

(defun counsel-gtags--update-tags-command (how-to)
  (cl-case how-to
    (entire-update '("global" "-u"))
    (generate-other-directory (list "gtags" (counsel-gtags--read-tag-directory)))
    (single-update (list "global" "--single-update" (counsel-gtags--real-file-name)))))

(defun counsel-gtags--update-tags-p (how-to interactive-p current-time)
  (or interactive-p
      (and (eq how-to 'single-update)
           (buffer-file-name)
           (or (not counsel-gtags-update-interval-second)
               (>= (- current-time counsel-gtags--last-update-time)
                   counsel-gtags-update-interval-second)))))

;;;###autoload
(defun counsel-gtags-update-tags ()
  "Update TAG file. Update All files with `C-u' prefix.
Generate new TAG file in selected directory with `C-u C-u'"
  (interactive)
  (let ((how-to (counsel-gtags--how-to-update-tags))
        (interactive-p (called-interactively-p 'interactive))
        (current-time (float-time (current-time))))
    (when (counsel-gtags--update-tags-p how-to interactive-p current-time)
      (let* ((cmds (counsel-gtags--update-tags-command how-to))
             (proc (apply #'start-file-process "counsel-gtags-update-tag" nil cmds)))
        (if (not proc)
            (message "Failed: %s" (mapconcat 'identity cmds " "))
          (set-process-sentinel proc (counsel-gtags--make-gtags-sentinel 'update))
          (setq counsel-gtags--last-update-time current-time))))))

(defun counsel-gtags--from-here (tagname)
  (let* ((line (line-number-at-pos))
         (from-here-opt (format "--from-here=%d:%s" line (counsel-gtags--real-file-name))))
    (counsel-gtags--select-file 'from-here tagname (list from-here-opt))))

;;;###autoload
(defun counsel-gtags-dwim ()
  "Call the counsel-gtags command by current context(Do What I Mean)
by global --from-here option."
  (interactive)
  (if (and (buffer-file-name) (thing-at-point 'symbol))
      (counsel-gtags--from-here (thing-at-point 'symbol))
    (call-interactively 'counsel-gtags-find-definition)))

(defvar counsel-gtags-mode-name " CounselGtags")
(defvar counsel-gtags-mode-map (make-sparse-keymap))

;;;###autoload
(define-minor-mode counsel-gtags-mode ()
  "Monor mode of counsel-gtags. If `counsel-gtags-update-tags' is non-nil, then
updating gtags after saving buffer."
  :init-value nil
  :global     nil
  :keymap     counsel-gtags-mode-map
  :lighter    counsel-gtags-mode-name
  (if counsel-gtags-mode
      (when counsel-gtags-auto-update
        (add-hook 'after-save-hook 'counsel-gtags-update-tags nil t))
    (when counsel-gtags-auto-update
      (remove-hook 'after-save-hook 'counsel-gtags-update-tags t))))

;; Key mapping of gtags-mode.
(when counsel-gtags-suggested-key-mapping
  ;; Current key mapping.
  (let ((command-table '(("s" . counsel-gtags-find-symbol)
                         ("r" . counsel-gtags-find-reference)
                         ("t" . counsel-gtags-find-definition)
                         ("d" . counsel-gtags-find-definition)))
        (key-func (if (string-prefix-p "\\" counsel-gtags-prefix-key)
                      #'concat
                    (lambda (prefix key) (kbd (concat prefix " " key))))))
    (cl-loop for (key . command) in command-table
             do
             (define-key counsel-gtags-mode-map (funcall key-func counsel-gtags-prefix-key key) command))

    ;; common
    (define-key counsel-gtags-mode-map "\C-]" 'counsel-gtags--from-here)
    (define-key counsel-gtags-mode-map "\C-t" 'counsel-gtags-pop)
    (define-key counsel-gtags-mode-map "\e*" 'counsel-gtags-pop)
    (define-key counsel-gtags-mode-map "\e." 'counsel-gtags-find-definition)))

(provide 'counsel-gtags)

;;; counsel-gtags.el ends here
