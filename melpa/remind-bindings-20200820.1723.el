;;; remind-bindings.el --- Reminders for your init bindings -*- lexical-binding: t; -*-

;; Copright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://github.com/mtekman/remind-bindings.el
;; Package-Version: 20200820.1723
;; Package-Commit: c9a327bfd3c68a0c41b5b64df491bdee4c73ca39
;; Keywords: outlines
;; Package-Requires: ((emacs "25.1") (omni-quotes "0.5") (popwin "1.0") (map "2.0"))
;; Version: 0.7

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; This package parses your Emacs init file for use-package or
;; global-set-key calls and summarizes the bindings it detects on a
;; package by package basis.
;;
;; The package makes use of the omni-quotes package to give you
;; a small reminder during idle periods.

;;; Code:
(require 'subr-x)
(require 'omni-quotes)
(require 'popwin)
(require 'map)
(require 'paren)

(defgroup remind-bindings nil
  "Group for remembering bindings."
  :group 'convenience)

(defgroup remind-bindings-format nil
  "Group for formatting how the reminders are displayed"
  :group 'remind-bindings)

(defcustom remind-bindings-initfile (locate-user-emacs-file "init.el" ".emacs")
  "The Emacs init file with your bindings in it."
  :type 'string
  :group 'remind-bindings)

(defcustom remind-bindings-buffername "*remind-bindings*"
  "Name of the buffer to render bindings."
  :type 'string
  :group 'remind-bindings)

(defcustom remind-bindings-format-bincom " → "
  "The format for displaying the binding (car %s) and the command (last %s)."
  :type 'string
  :group 'remind-bindings-format)

(defconst remind-bindings-format-bincom-internal " &&& "
  "Internal format for putting together binding to command.")

(defcustom remind-bindings-format-packbincom "[%s] %s"
  "The format for displaying the package (car %s) and the bindings (last %s)."
  :type 'string
  :group 'remind-bindings-format)

(defcustom remind-bindings-format-bindingsep " | "
  "The separator between the bindings of the same package."
  :type 'string
  :group 'remind-bindings-format)

(define-minor-mode remind-bindings-specific-mode
  "Allow remind-bindings to show buffer specific bindings only"
  :lighter " ¶"
  (if remind-bindings-specific-mode
      (progn (message "Buffer Specific Bindings Only")
             (remind-bindings-specific)
             (add-hook 'window-selection-change-functions
                       #'remind-bindings-specific nil t))
    ;; re-initialise full bindings again
    (remind-bindings-initialise)
    (remove-hook 'window-selection-change-functions
                 #'remind-bindings-specific t)))


;; --- global-set-key --- funcs
(defun remind-bindings-globalsetkey ()
  "Process entire Emacs init.el for global bindings and build an alist map grouped on package name."
  (with-current-buffer (find-file-noselect remind-bindings-initfile)
    (save-excursion
      (goto-char 0)
      (let ((globbers nil))
        (condition-case err
            (while t
              (let ((glob (remind-bindings-globalsetkey-next)))
                (when glob
                  (let ((pname (string-trim (car glob)))
                        (binde (car (last glob))))
                    (push `(,pname ,binde) globbers))))
              (end-of-line))
          (error
           (ignore err)
           (end-of-line)
           ;; Convert alist into hash-table
           (map-into
            (->> globbers
                 (seq-group-by #'car)
                 (--map (cons (car it) (-map #'cadr (cdr it)))))
            'hash-table)))))))

(defun remind-bindings-globalsetkey-next ()
  "Get the binding and name of the next ‘global-set-key’."
  (search-forward "(global-set-key ") ;; throw error if no more
  (beginning-of-line) ;; get the total bounds
  (let ((bsub #'buffer-substring-no-properties)
        (getfn #'remind-bindings-globalsetkey-fromfunc)
        (initfile remind-bindings-initfile)
        (bincomint remind-bindings-format-bincom-internal))
    (let* ((bound (funcall show-paren-data-function))
           (outer (nth 3 bound)))
      (search-forward "global-set-key " outer)
      (let* ((bounk (funcall show-paren-data-function))
             (keybf (nth 0 bounk))
             (keybl (nth 3 bounk))
             (keyb (apply bsub `(,keybf ,keybl))))
        (when (search-forward "kbd \"" keybl t)
          (let ((beg (point))
                (end (- (search-forward "\"" keybl) 1)))
            (setq keyb (apply bsub `(,beg ,end)))))
        ;; Try to grab the command, quote or interactive
        (condition-case nofuncstart
            (progn (unless (search-forward "(interactive) " outer t)
                     (unless (search-forward "'" outer t)
                       (unless (search-forward "(" outer t))))
                   (let ((ninner (point))
                         (nouter (- outer 1)))
                     (let* ((func (apply bsub `(,ninner ,nouter)))
                            (package-name (apply getfn `(,func ,initfile))))
                       (end-of-line)
                       (let ((bname (concat keyb bincomint func)))
                         `(,package-name ,bname)))))
          (error
           ;; Move to end of line and give nil
           (ignore nofuncstart)
           (end-of-line)))))))

(defun remind-bindings-globalsetkey-fromfunc (fname default)
  "Get the name of the package the FNAME belongs to.  Return the DEFAULT if none found."
  (let ((packname (symbol-file (intern fname))))
    (if packname
        (let ((bnamext (car (last (split-string packname "/")))))
          ;; name without extension
          (car (split-string bnamext "\\.")))
      default)))

;; --- usepackages --- funcs
(defun remind-bindings-usepackages ()
  "Process entire Emacs init.el for package bindings."
  (with-current-buffer (find-file-noselect remind-bindings-initfile)
    (save-excursion
      (goto-char 0)
      (let ((packbinds nil)
            (stop nil))
        (condition-case _err
            (while (not (eobp))
              (let ((packinfo (remind-bindings-usepackages-next)))
                (when (nth 1 packinfo) ;; has bounds
                  (let ((binds (remind-bindings-usepackages-bindsinpackage
                                packinfo)))
                    (message (car binds))
                    (when (nth 1 binds)
                      (push binds packbinds)))))
              (end-of-line))
          (search-failed nil))
        (map-into (nreverse packbinds) 'hash-table)))))

(defun remind-bindings-usepackages-next ()
  "Get the name and parenthesis bounds of the next ‘use-package’."
  (search-forward "(use-package")
  (beginning-of-line)
  (let* ((bound (funcall show-paren-data-function))
         (inner (nth 0 bound))
         (outer (nth 3 bound)))
    (if (not bound)
        (progn (move-end-of-line 1) nil)
      (search-forward "use-package " outer t)
      (let* ((beg (point))
             (end (progn
                    (search-forward-regexp "\\( \\|)\\|$\\)" outer)
                    (point)))
             (name (string-trim (buffer-substring-no-properties beg end))))
        (goto-char outer)
        `(,name ,inner ,outer)))))

(defun remind-bindings-usepackages-bindsinpackage (packinfo)
  "Return the name and bindings for the current package named and bounded by PACKINFO."
  (let ((bindlist (list (nth 0 packinfo))) ;; package name is first
        (inner (nth 1 packinfo))
        (outer (nth 2 packinfo)))
    (when inner
      (goto-char inner)
      (save-excursion
        (when (search-forward ":bind" outer 1) ;; if fail, move to limit
          (while (search-forward-regexp "\( ?\"[^)]*\" ?\. [^\") ]*\)" outer t)
            (save-excursion
              (let* ((end (- (point) 1))
                     (sta (+ (search-backward "(") 1))
                     (juststr (buffer-substring-no-properties sta end))
                     (bin-comm (split-string juststr " \\. "))
                     (bin  (nth 1 (split-string (car bin-comm) "\"")))
                     (comm (car (cdr bin-comm)))
                     (psnickle (concat bin
                                       remind-bindings-format-bincom-internal
                                       comm)))
                (push psnickle bindlist))))
          (nreverse bindlist))))))

;; --- Main --
(defun remind-bindings-aggregatelists ()
  "Aggregate the `use-package` and `global-set-key` bindings and merge them by package."
  (let ((globals (remind-bindings-globalsetkey))
        (usepack (remind-bindings-usepackages)))
    (map-merge-with 'hash-table #'append globals usepack)))

(defun remind-bindings-omniquotes-make (hashtable)
  "Convert a HASHTABLE of bindings into a single formatted list."
  (let ((bcomint remind-bindings-format-bincom-internal)
        (bcom remind-bindings-format-bincom)
        (bsep remind-bindings-format-bindingsep)
        (pbin remind-bindings-format-packbincom)
        (total))
    (maphash
     (lambda (packname bindings)
       (let* ((replacefn `(lambda (x) (s-replace ,bcomint ,bcom x)))
              (newbsep (mapcar replacefn bindings))
              (reform (mapconcat #'identity newbsep bsep))
              ;; [packname] bindings
              (fmt (format pbin packname reform)))
         (push fmt total)))
     hashtable)
    total))

(defun remind-bindings-sidebuffer-make (hashtable)
  "Populate a sidebuffer with a HASHTABLE of bindings."
  (require 'org)
  (let* ((buff (get-buffer-create remind-bindings-buffername))
         (prevsep remind-bindings-format-bincom-internal)
         (replacefn `(lambda (x) (s-replace ,prevsep " :: "  x))))
    (with-current-buffer buff
      (read-only-mode 0)
      (erase-buffer)
      (maphash
       (lambda (packname bindings)
         (insert (format "** %s" (string-trim packname)))
         (insert "\n  - ")
         (insert (mapconcat replacefn bindings "\n  - "))
         (insert "\n"))
       hashtable)
      (org-mode)
      ;; (mark-whole-buffer) -- interactive only...
      (push-mark (point))
      (push-mark (point-max) nil t)
      (goto-char (point-min))
      ;;
      (org-sort-entries nil ?a ) ;; alphabetic sort of entries
      (read-only-mode t))))

;;;###autoload
(defun remind-bindings-initialise ()
  "Collect all ‘use-package’ and global key bindings and set the omni-quotes list."
  (if remind-bindings-initfile
      (let ((intbinds (remind-bindings-aggregatelists)))
        (remind-bindings-doitall intbinds))
    (message "Please set ‘remind-bindings-initfile’ first")))

(defun remind-bindings-doitall (bindings)
  "Take an alist of BINDINGS and set the omniquotes and sidebuffer."
  (let ((make-quotes (remind-bindings-omniquotes-make bindings))
        (make-sidebf (remind-bindings-sidebuffer-make bindings)))
    (ignore make-sidebf) ;; it just aligns nicely in the let part...
    (omni-quotes-set-populate make-quotes "bindings")))

(defun remind-bindings-togglebuffer-isopen ()
  "Check if the sidebuffer is open."
  ;; For some reason ’(get-buffer-window-list)’ fails to list
  ;; all active buffers in Emacs 28.0.50...
  (let ((funclist (lambda (x) (buffer-name (window-buffer x))))
        (bname remind-bindings-buffername)
        (windlist (window-list)))
    (let ((bnamelist (mapcar funclist windlist)))
      (member bname bnamelist))))

(defun remind-bindings-togglebuffer-bufferexists ()
  "Check if the buffer exists."
  (let ((bname remind-bindings-buffername)
        (blist (buffer-list)))
    (member bname (mapcar #'buffer-name blist))))

;;;###autoload
(defun remind-bindings-togglebuffer (&optional level)
  "Toggle the sidebar with static window rules.  Initialise and recurse to a max LEVEL of 2."
  (interactive)
  (or level (setq level 0))
  (if (remind-bindings-togglebuffer-isopen)
      (popwin:close-popup-window)
    (if (remind-bindings-togglebuffer-bufferexists)
        ;; If we're in buffer-specific mode, initialise them.
        (progn (when remind-bindings-specific-mode
                 (remind-bindings-specific))
               (popwin:popup-buffer remind-bindings-buffername
                                    :width 0.25 :position 'right
                                    :noselect :stick))
      ;; Otherwise initialise no more than twice
      (setq level (+ level 1))
      (if (> level 2)
          (message "Could not initialise")
        (if remind-bindings-specific-mode
            (remind-bindings-specific)
          (remind-bindings-initialise))
        (remind-bindings-togglebuffer)))))


;; -- Methods to guess the modes in the current buffer --
(defvar remind-bindings-specific-buffermap nil
  "Buffer Map of bindings.")

(defun remind-bindings-specific-activefiltered (alistmap)
  "Get a list of packages with modes active in buffer, and match them to ALISTMAP of packages."
  (let ((fn1 (lambda (x) (symbol-name (car x))))
        (fn2 (lambda (x) (s-replace-regexp "\\(-minor\\)?-mode$" "" x))))
    (let* ((actsmode (mapcar fn1 minor-mode-alist))
           (sansmode (mapcar fn2 actsmode)))
      ;;(sansmode (cl-sort sansmode 'string-lessp))) ;; debug, sort
      (map-filter (lambda (k v) (ignore v)(member k sansmode)) alistmap))))

(defun remind-bindings-specific ()
  "Grab the modes for the current buffer."
  (let ((bfnam (buffer-file-name (current-buffer)))
        (damap remind-bindings-specific-buffermap))
    (let ((binds (map-elt damap bfnam)))
      (unless binds
        (let* ((allrbinds (remind-bindings-aggregatelists))
               (bufflists (remind-bindings-specific-activefiltered
                           allrbinds))
               (buffbinds (map-into bufflists 'hash-table)))
          (setq binds buffbinds)
          (setq remind-bindings-specific-buffermap
                (map-insert damap bfnam buffbinds))))
      (remind-bindings-doitall binds))))

(provide 'remind-bindings)
;;; remind-bindings.el ends here
