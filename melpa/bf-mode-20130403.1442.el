;;; bf-mode.el --- Browse file persistently on dired

;; Description: Browse file persistently on dired
;; Author: isojin
;; Maintainer: myuhe <yuhei.maeda_at_gmail.com>
;; Copyright (C) 2012,2013 myuhe all rights reserved.
;; Created: :2005-12-28
;; Version: 0.0.1
;; Package-Version: 20130403.1442
;; Package-Commit: 7cc4d09aed64d9db6be95646f5f5067de68f8895
;; Keywords: convenience
;; URL: https://github.com/emacs-jp/bf-mode
;;
;;	$Id: bf-mode.el,v 1.60 2005/12/28 09:49:13 gnrr Exp gnrr $
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; What is this:
;;   Bf(Browse File)-mode is minor-mode for dired. Bf-mode allows you
;;   to browse file easily and directly, despite of keeping dired.
;;
;; Features:
;;   * easy browsing (texts, images, ... )
;;   * allow to use dired command (mark, delete, ... )
;;   * browse contents in directory
;;   * browse contents list in archived file such as .tar.* or .lzh
;;   * browse html files with w3m
;;
;; Install:
;;   1. Put "bf-mode.el" into your load-path directory.
;;   2. Add the following line to your dot.emacs.
;;
;;     (require 'bf-mode)
;;
;;   3. If you need to configure, add the following lines in your dot.emacs.
;;
;;     ;; list up file extensions which should be excepted
;;     (setq bf-mode-except-exts
;;           (append '("\\.dump$" "\\.data$" "\\.mp3$" "\\.lnk$")
;;                   bf-mode-except-exts))
;;
;;     ;; list up file extensions which should be forced browsing
;;      (setq bf-mode-force-browse-exts
;;           (append '("\\.txt$" "\\.and.more...")
;;                   bf-mode-force-browse-exts))
;;
;;     ;; browsable file size maximum
;;     (setq bf-mode-browsing-size 100) ;; 100 killo bytes
;;
;;     ;; browsing htmls with w3m (needs emacs-w3m.el and w3m)
;;     (setq bf-mode-html-with-w3m t)
;;
;;     ;; browsing archive file (contents listing) verbosely
;;     (setq bf-mode-archive-list-verbose t)
;;
;;     ;; browing directory (file listing) verbosely
;;     (setq bf-mode-directory-list-verbose t)
;;
;;     ;; start bf-mode immediately after starting dired
;;     (setq bf-mode-enable-at-starting-dired t)
;;
;;     ;; quitting dired directly from bf-mode
;;     (setq bf-mode-directly-quit t)

;; Usage:
;;   1. invoke dired by C-x d.
;;   2. b               enter bf-mode
;;   3. b or q          exit from bf-mode
;;   4. n or p          move cursor to target file in order to browse it.
;;   5. SPC             scroll up browsing window
;;      S-SPC           scroll down browsing window
;;   6. r               toggle read-only
;;      j               toggle browsing alternatively (html, archive and more)
;;      s               adjust browsable file size

;;; Todo:

;;   3. turning on/off font lock appearance in browsing window.
;;   5. browsing text file with heading.
;;   6. load and show a part of large text file.
;;   7. show specification of image file such as width and height.
;;   8. add on user's function definitions according to their extensions.
;;  10. play mp3 and show the lyric

;;; Code:

(require 'dired)

(declare-function w3m-find-file "w3m")

;; mode variable
(defvar bf-mode nil
  "Mode variable for bf minor mode.")
(make-variable-buffer-local 'bf-mode)

;; keymap
(defvar bf-mode-map nil
  "Keymap for browse-file (bf) minor mode.")

;;
;; variables for users
;;
(defvar bf-mode-selecting-read-only nil
  "*Fla:g, treat as read-only when file is selected.\n\n
Non-nil means read-only.\n
Nil means writable.")

(defvar bf-mode-browsing-read-only t
  "*Flag, treat as read-only in browsing window.\n\n
Non-nil means read-only.\n
Nil means writable.")

(defvar bf-mode-browsing-heading 0
  "*Number, will be shown top line in browsing window.\n\n
0 is working without heading.")

(defvar bf-mode-browsing-size 30
  "*Number, browsable maximum file size (KByte).")

(defvar bf-mode-html-with-w3m nil
  "*Flag, browsing html file using w3m.\n\n
Non-nil means use w3m. Nil means NOT use w3m.\n
This variable applies to html files only.")

(defvar bf-mode-archive-list-verbose nil
  "*Flag, browsing archive file list verbosely.\n\n
Non-nil means verbosely. Nil means simply.\n
This variable applies to archive files only.")

(defvar bf-mode-directory-list-verbose nil
  "*Flag, browsing directory list verbosely.\n\n
Non-nil means verbosely. Nil means simply.\n
This variable applies to directories only.")

(defvar bf-mode-except-exts '("\\.exe$" "\\.com$" "\\.elc$" "\\.lnk$")
  "*List of file extensions which are excepted to browse.")

(defvar bf-mode-xdoc2txt-exts '("\\.rtf" "\\.doc" "\\.xls" "\\.ppt"
                                "\\.jaw" "\\.jtw" "\\.jbw" "\\.juw"
                                "\\.jfw" "\\.jvw" "\\.jtd" "\\.jtt"
                                "\\.oas" "\\.oa2" "\\.oa3" "\\.bun"
                                "\\.wj2" "\\.wj3" "\\.wk3" "\\.wk4"
                                "\\.123" "\\.wri" "\\.pdf" "\\.mht")
  "*List of file extensions which are handled by xdoc2txt.")


(defvar bf-mode-image-exts '("\\.png$"  "\\.gif$" "\\.bmp$" "\\.jp[e]?g$")
  "*List of file extensions which are handled as image.")

(defvar bf-mode-force-browse-exts ()
  "*List of file extensions which are forced browsing independent of its size.")
(defvar bf-mode-enable-at-starting-dired nil
  "*Flag, to enable bf-mode at starting dired.\n\n
Non-nil means that bf-mode is enabled immediately after starting dired.")

(defvar bf-mode-directly-quit nil
  "*Flag, quitting dired directly from bf-mode.\n\n
Non-nil means quitting dired directly from bf-mode.\n
Nil means quitting bf-mode only, thus still alive dired.")

;;
;; internal variables
;;
(defvar bf-mode-window-stack nil)
(defvar bf-mode-dired-window nil)
(defvar bf-mode-previous-keymap nil)
(defvar bf-mode-current-browsing-buffer nil)
(defvar bf-mode-browsing-category nil)
(defvar bf-mode-force-browse-temporary nil)

;;
;; additional functions to dired
;;
(defun bf-mode-save-window-configuration ()
  (setq bf-mode-window-stack (current-window-configuration)))

(defun bf-mode-kill-dired ()
  (interactive)
  (when bf-mode-current-browsing-buffer
    (kill-buffer bf-mode-current-browsing-buffer))
  (quit-window t)
  (set-window-configuration bf-mode-window-stack))

(defun bf-mode-dired-delete-other-window ()
  (unless (one-window-p)
    (delete-other-windows (selected-window))))

;;
;; sub routines
;;

;; same as dired-advertised-find-file's functionality
(defun bf-mode-find-file ()
  (interactive)
  (bf-mode 0)
  (dired-find-file)
  (when (eq major-mode 'dired-mode)
    (bf-mode 1))
  (if bf-mode-selecting-read-only
      (setq buffer-read-only t)
    (setq buffer-read-only nil)))

;; toggle read-only browsing file
(defun bf-mode-toggle-read-only ()
  (interactive)
  (setq bf-mode-browsing-read-only (not bf-mode-browsing-read-only))
  (bf-mode-browse))

;; toggle browsing alternative
(defun bf-mode-toggle-browse-alternative ()
  (interactive)
  (cond
   ;; directory: toggle verbose/simply
   ((eq bf-mode-browsing-category 'directory)
    (setq bf-mode-directory-list-verbose (not bf-mode-directory-list-verbose)))

   ;; size-over: force browse once
   ((eq bf-mode-browsing-category 'size-over)
    (setq bf-mode-force-browse-temporary t))

   ;; except: force browse once
   ((eq bf-mode-browsing-category 'except)
    (setq bf-mode-force-browse-temporary t))

   ;; image
   ((eq bf-mode-browsing-category 'image)
    ;; do nothing
    )

   ;; xdoc2txt
   ((eq bf-mode-browsing-category 'xdoc2txt)
    ;; do nothing
    )

   ;; archive: toggle verbose/simply
   ((eq bf-mode-browsing-category 'archive)
    (setq bf-mode-archive-list-verbose (not bf-mode-archive-list-verbose)))

   ;; html: toggle browsing htmls with/without w3m
   ((eq bf-mode-browsing-category 'html)
    (setq bf-mode-html-with-w3m (not bf-mode-html-with-w3m))
    ;; (if bf-mode-html-with-w3m
    ;; 	(bf-mode-start-w3m)
    ;;   (bf-mode-quit-w3m))
    )

   ;; text
   ((eq bf-mode-browsing-category 'text)
    ;; do nothing
    )
   )
  (bf-mode-browse))

;; (defun bf-mode-start-w3m ()
;;   (w3m)
;;   (w3m-close-window)
;;   )

;; (defun bf-mode-quit-w3m ()
;;   (w3m-quit t)
;;   )

;; change browsable file size maximum temporary
(defun bf-mode-change-browsing-size (num)
  (interactive "NBrowsable size (KByte):")
  (setq bf-mode-browsing-size num)
  (bf-mode-browse))

;; change heading line of browsing file temporary (not work yet)
(defun bf-mode-change-heading (num)
  (interactive "NHeading Line:")
  (setq bf-mode-browsing-heading num)
  (bf-mode-browse))

;; move cursor then browse file
(defun bf-mode-next ()
  (interactive)
  (dired-next-line 1)
  (bf-mode-browse))

(defun bf-mode-previous ()
  (interactive)
  (dired-next-line -1)
  (bf-mode-browse))

;; scroll in browsing window
(defun bf-mode-scroll-other-window ()
  (interactive)
  (let* ((browsing-window (get-buffer-window bf-mode-current-browsing-buffer))
         (browsing-window-pmax (save-selected-window
                                 (select-window browsing-window)
                                 (point-max)))
         (browsing-window-pmin 1))
    (cond ((= (window-point browsing-window) browsing-window-pmax)
           (set-window-point browsing-window browsing-window-pmin))
          ((and (pos-visible-in-window-p browsing-window-pmax
                                         browsing-window)
                (not (pos-visible-in-window-p browsing-window-pmin
                                              browsing-window)))
           (set-window-point browsing-window browsing-window-pmax))
          (t (scroll-other-window (1- (window-height)))))))

(defun bf-mode-scroll-other-window-down ()
  (interactive)
  (let ((browsing-window (get-buffer-window bf-mode-current-browsing-buffer)))
    (scroll-other-window (- (1- (window-height))))
    (set-window-point browsing-window (window-start browsing-window))))

;; browsing with heading (not work yet)
(defun bf-mode-set-window-start-line (num)
  (when (wholenump num)
    ;; positive value
    (goto-char (point-min))
    (vertical-motion (1- num))
    (set-window-start (selected-window) (point))))

;; get parent directory name
(defun bf-mode-upper-directory-name (path)
  (setq path (file-name-directory path))
  (let ((clist (split-string path "/")))
    (nth (1- (length clist)) clist)))

;; whether target file is correspond to list
(defun bf-mode-correspond-ext-p (filename list)
  (let ((ret nil))
    (while list
      (when (string-match (car list) filename)
        (setq ret t))
      (setq list (cdr list)))
    ret))

;;
;; distinguish between directory or not
;;
(defun bf-mode-browse ()
  (let ((display-buffer-function nil))
  (when (one-window-p)
    (find-file-other-window (make-temp-name "bf"))
    (setq bf-mode-current-browsing-buffer (current-buffer))
    (select-window bf-mode-dired-window))
  (let ((filename (file-name-sans-versions (dired-get-filename) t)))
    (if (file-directory-p filename)
        ;; directory
        (progn
          (bf-mode-browse-directory filename bf-mode-directory-list-verbose)
          (setq bf-mode-browsing-category 'directory)
          (select-window (next-window))
          (setq bf-mode-current-browsing-buffer (current-buffer))
          (select-window bf-mode-dired-window))
      ;; other regular file
      (when (file-regular-p filename)
        (select-window (next-window))
        (bf-mode-browse-file filename)
        (setq bf-mode-current-browsing-buffer (current-buffer))
        (select-window bf-mode-dired-window))))))

;;
;; processing depends on file extensions
;;
(defun bf-mode-browse-file (filename)
  (let ((attr (file-attributes filename)))
    (if (and (>= (nth 7 attr) (* bf-mode-browsing-size 1024))
             (not (bf-mode-correspond-ext-p filename
                                            bf-mode-force-browse-exts))
             (not bf-mode-force-browse-temporary))
        ;; size over
        (progn
          (bf-mode-buffer-for-size-over filename)
          (setq bf-mode-browsing-category 'size-over))
      (cond
       ;; except
       ((and (bf-mode-correspond-ext-p filename bf-mode-except-exts)
             (not bf-mode-force-browse-temporary))
        (bf-mode-browse-except-file filename)
        (setq bf-mode-browsing-category 'except))

       ;; image
       ((bf-mode-correspond-ext-p filename bf-mode-image-exts)
        (bf-mode-browse-image filename)
        (setq bf-mode-browsing-category 'image))

       ;;xdoc
       ((bf-mode-correspond-ext-p filename bf-mode-xdoc2txt-exts)
        (bf-mode-browse-xdoc2txt filename)
        (setq bf-mode-browsing-category 'xdoc2txt))
       
       ;; archive
       ((string-match "\\.tar\\.gz$" filename)
        (bf-mode-browse-archive filename
                                (if bf-mode-archive-list-verbose
                                    "tar ztvf " "tar ztf "))
        (setq bf-mode-browsing-category 'archive))
       ((string-match "\\.tar\\.bz[2]?$" filename)
        (bf-mode-browse-archive filename
                                (if bf-mode-archive-list-verbose
                                    "tar jtvf " "tar jtf "))
        (setq bf-mode-browsing-category 'archive))
       ((string-match "\\.tar$" filename)
        (bf-mode-browse-archive filename
                                (if bf-mode-archive-list-verbose
                                    "tar tvf " "tar tf "))
        (setq bf-mode-browsing-category 'archive))
       ((string-match "\\.lzh$" filename)
        (bf-mode-browse-archive filename
                                (if bf-mode-archive-list-verbose
                                    "lha v " "lha l "))
        (setq bf-mode-browsing-category 'archive))

       ;; html
       ((string-match "\\.htm[l]?$" filename)
        (if bf-mode-html-with-w3m
            (bf-mode-browse-html filename)
          (bf-mode-browse-text filename))
        (setq bf-mode-browsing-category 'html))

       ;; other extensions and invoked functions here

       ;; text
       (t
        (bf-mode-browse-text filename)
        (setq bf-mode-browsing-category 'text)))
      (setq bf-mode-force-browse-temporary nil))))

;;
;; standard handling
;;

;; except
(defun bf-mode-browse-except-file (filename)
  (kill-buffer bf-mode-current-browsing-buffer)
  (let ((dummy-buff (generate-new-buffer "bf:cant browse")))
    (set-buffer dummy-buff)
    (insert
     "\n"
     "\t\t+-------------------------------+\n"
     "\t\t|       CANNOT BE BROWSED       |\n"
     "\t\t+-------------------------------+\n\n"
     "\t\"" (file-name-nondirectory filename)
     "\" can not be browsed caused by restriction.\n\n"
     "\tNow, its configured as below...\n\n"
     "\t")
    (eval-expression 'bf-mode-except-exts t)
    (insert
     "\n\n"
     "\tIf you change this definition,\n"
     "\tyou can adjust a variable \"bf-mode-except-exts\" in dot.emacs.\n"
     "\tOtherwise, type \"j\" for force browsing just this once.")
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (bf-mode-set-window-start-line 1)
  )

;; size over
(defun bf-mode-buffer-for-size-over (filename)
  (kill-buffer bf-mode-current-browsing-buffer)
  (let ((dummy-buff (generate-new-buffer "bf:size over")))
    (set-buffer dummy-buff)
    (insert
     "\n"
     "\t\t+-------------------------------+\n"
     "\t\t| EXCEEDING BROWSABLE FILE SIZE |\n"
     "\t\t+-------------------------------+\n\n"
     "\t\"" (file-name-nondirectory filename)
     "\" can not be browsed caused by size over.\n\n"
     "\tNow, its limited to "
     (number-to-string bf-mode-browsing-size) " KByte(s).\n\n"
     "\tThere are 3-ways in order to browse this/these file(s).\n\n"
     "\t1. JUST THIS ONCE: Type \"j\"\n"
     "\t2. THIS SESSION ONLY: Type \"s\" and input size value\n"
     "\t3. PERMANENTLY: Adjust a variable \"bf-mode-browsing-size\" in dot.emacs.\n")
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (bf-mode-set-window-start-line 1))

;; directory
(defun bf-mode-browse-directory (dir verbose)
  (kill-buffer bf-mode-current-browsing-buffer)
  (list-directory dir verbose))

;;
;; each case of kind of files.
;;

;; texts
(defun bf-mode-browse-text (filename)
  (find-alternate-file filename)
  (if bf-mode-browsing-read-only
      (setq buffer-read-only t)
    (setq buffer-read-only nil))
  (when (integerp bf-mode-browsing-heading)
    (bf-mode-set-window-start-line bf-mode-browsing-heading)))

;; images
(defun bf-mode-browse-image (filename)
  (kill-buffer bf-mode-current-browsing-buffer)
  (let ((dummy-buff (generate-new-buffer "bf:image file")))
    (set-buffer dummy-buff)
    (condition-case nil
        (insert-image-file filename)
      (error
       (message "Error occured while loading image.")))
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (bf-mode-set-window-start-line 1))

;; xdoc2txt
(defun bf-mode-browse-xdoc2txt (filename)
  (kill-buffer bf-mode-current-browsing-buffer)
  (let ((dummy-buff (generate-new-buffer (concat "bf:"
                                                 (file-name-nondirectory
                                                  filename)))))
    (set-buffer dummy-buff)
    (let ((fn (concat
               (expand-file-name
                (make-temp-name "xdoc2")
                temporary-file-directory)
               "."
               (file-name-extension filename)))
          (str nil))
      (copy-file filename fn t)
      (insert
       "XDOC2TXT FILE: " (file-name-nondirectory filename) "\n"
       "----------------------------------------------------\n"
       (shell-command-to-string
        (concat
         "xdoc2txt" " -e " fn)))
      (goto-char (point-min))
      (while (re-search-forward "\r" nil t)
        (delete-region (match-beginning 0)
                       (match-end 0)))
      (goto-char (point-min))
      (while (re-search-forward "\\([\n ]+\\)\n[ ]*\n" nil t)
        (delete-region (match-beginning 1)
                       (match-end 1)))
      (delete-file fn))
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (bf-mode-set-window-start-line 1))


;; archives
(defun bf-mode-browse-archive (filename command)
  (kill-buffer bf-mode-current-browsing-buffer)
  (let ((dummy-buff (generate-new-buffer (concat "bf:"
                                                 (file-name-nondirectory
                                                  filename)))))
    (set-buffer dummy-buff)
    (insert
     "ARCHIVE FILE: " (file-name-nondirectory filename) "\n"
     "----------------------------------------------------\n"
     (shell-command-to-string (concat
                               "cd " (file-name-directory filename) ";"
                               command (file-name-nondirectory filename))))
    (setq buffer-read-only t)
    (set-window-buffer (selected-window) dummy-buff))
  (bf-mode-set-window-start-line 1))

;; htmls
(defun bf-mode-browse-html (filename)
  (kill-buffer bf-mode-current-browsing-buffer)
  (require 'w3m)
  (condition-case nil
      (w3m-find-file filename)
    (error
     (message "Error occured while w3m."))))

;;
;; accordance with minor mode rules
;;

(defun bf-mode-quit-dired ()
  (interactive)
  (bf-mode 0)
  (bf-mode-kill-dired))

;; enter the minor mode
(defun bf-mode-enter ()
  (setq bf-mode-dired-window (selected-window))
  (setq bf-mode-previous-keymap (copy-keymap (current-local-map)))
  (use-local-map bf-mode-map)
  (substitute-key-definition 'bf-mode 'bf-mode bf-mode-map dired-mode-map)

  ;; exit from dired directly from bf-mode
  (when bf-mode-directly-quit
    (substitute-key-definition 'bf-mode-kill-dired
                               'bf-mode-quit-dired bf-mode-map
                               dired-mode-map))
  (bf-mode-browse))

;; exit from minor mode
(defun bf-mode-quit ()
  (interactive)
  (kill-buffer bf-mode-current-browsing-buffer)
  (unless (one-window-p)
    (delete-other-windows bf-mode-dired-window))
  (use-local-map bf-mode-previous-keymap))

(if bf-mode-map
    nil
  (setq bf-mode-map (make-sparse-keymap))
  (define-key bf-mode-map "\C-m" 'bf-mode-find-file)
  (define-key bf-mode-map "n" 'bf-mode-next)
  (define-key bf-mode-map "p" 'bf-mode-previous)
  (define-key bf-mode-map " " 'bf-mode-scroll-other-window)
  (define-key bf-mode-map '[33554464] 'bf-mode-scroll-other-window-down)
  (define-key bf-mode-map "r" 'bf-mode-toggle-read-only)
  (define-key bf-mode-map "j" 'bf-mode-toggle-browse-alternative)
  ;;   (define-key bf-mode-map "h" 'bf-mode-change-heading)
  (define-key bf-mode-map "s" 'bf-mode-change-browsing-size)
  (define-key bf-mode-map "q" 'bf-mode)

  (set-keymap-parent bf-mode-map dired-mode-map))

;; mode line
(if (not (assq 'bf-mode minor-mode-alist))
    (setq minor-mode-alist
          (cons '(bf-mode " Bf") minor-mode-alist)))

;; entrance
(defun bf-mode (&optional arg)
  "Browse file (bf) minor mode."
  (interactive "P")
  (setq bf-mode
        (if (null arg)
            (not bf-mode)
          (> (prefix-numeric-value arg) 0)))
  (if bf-mode
      (bf-mode-enter)
    (bf-mode-quit))
  (force-mode-line-update))

;;
;; hooks and advices to dired in order to use simply.
;;
(add-hook 'dired-mode-hook
          '(lambda ()
             (bf-mode-save-window-configuration)
             (bf-mode-dired-delete-other-window)
             (define-key dired-mode-map "q" 'bf-mode-kill-dired)
             (define-key dired-mode-map "b" 'bf-mode)))

(defvar bf-mode-interactive-p
  (if (fboundp 'called-interactively-p)
      (lambda () (called-interactively-p 'interactive))
    'interactive-p))

(defadvice dired (after bf-enable activate)
  (when (and (funcall bf-mode-interactive-p)
             bf-mode-enable-at-starting-dired)
    (bf-mode 1)))

(defadvice dired-mark (after bf-show-next activate)
  (when bf-mode
    (bf-mode-browse)))

(provide 'bf-mode)

;;; bf-mode.el ends here
