;;; journalctl-mode.el --- Sample major mode for  viewing output journalctl -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2020, by Sebastian Meisel

;; Author: Sebastian Meisel <sebastian.meisel@gmail.com>
;; Version: 0.9
;; Package-Version: 20201217.1625
;; Package-Commit: c5bca1a5f42d2fe2a00fdf52fe480137ace971d3
;; Created:  June 1, 2020
;; Keywords: unix
;; Homepage: https://github.com/SebastianMeisel/journalctl-mode
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;;; License:

;; You can redistribute this program and/or modify it under the terms of the GNU General Public License version 2.

;;; Commentary:

;; This is a major-mode for Emacs to view systemd's journalctl output in Emacs.
;; The output is split into chunks for performance reasons.
;; Fontification is provided and may be customized.
;; At the moment it is still in very early development.  Please give feedback on any problems that occure.

;; Put journalctl-mode.el in your load-path and add   ( require 'journalctl-mode)  to your .Emacs file.

;;; Code:

(require 'array)

;; customization

(defgroup journalctl nil
  "View journalctl output in a emacs buffer"
  :group 'external)

(defcustom journalctl-chunk-size
  250
 "Number of lines of journalctl output that are loaded in the buffer.  You can navigate."
  :group 'journalctl
  :type 'integer)
  
(defcustom journalctl-error-keywords
  '("Failed" "failed" "Error" "error" "critical" "couldn't" "Can't" "not" "Not" "unreachable")
  "Keywords that mark errors in journalctl output."
  :group 'journalctl
  :type 'string)

(defcustom journalctl-warn-keywords
  '("Warning" "warn" "debug")
  "Keywords that mark warnings in journalctl output."
  :group 'journalctl
  :type 'string)

(defcustom journalctl-starting-keywords
  '("Starting" "Activating" "Listening" "Reloading" "connect")
  "Keywords that mark start of processes or steps in journalctl output."
  :group 'journalctl
  :type 'string)

(defcustom journalctl-finished-keywords
  '("Stopped" "Stopping" "Reached" "Closed" "finished" "Started" "Successfully activated"
    "Received" "opened" "success" "enabled" "removed" "active" "Created" "loaded" "detected")
  "Keywords that mark finished processes or steps in journalctl output."
  :group 'journalctl
  :type 'string)

;;; faces
(defface journalctl-error-face
  '((t :inherit error))
  "Face to mark errors in journalctl's output."
  :group 'journalctl)

(defface journalctl-warning-face
  '((t :inherit warning))
  "Face to mark warnings in journalctl's output."
  :group 'journalctl)

(defface journalctl-starting-face
  '((t :inherit success))
  "Face to mark starting units in journalctl's output."
  :group 'journalctl)

(defface journalctl-finished-face
  '((t :inherit success :bold t))
  "Face to mark finished units in journalctl's output."
  :group 'journalctl)

(defface journalctl-timestamp-face
  '((t :inherit font-lock-type-face))
  "Face for timestamps in journalctl's output."
  :group 'journalctl)

(defface journalctl-host-face
  '((t :inherit font-lock-keyword-face))
  "Face for hosts in journalctl's output."
  :group 'journalctl)

(defface journalctl-process-face
  '((t :inherit font-lock-function-name-face))
  "Face for hosts in journalctl's output."
  :group 'journalctl)

;; variables
(defvar journalctl-current-chunk
  0
  "Counter for chunks of journalctl output loaded into the *journalctl*-buffer.")

(defvar journalctl-current-lines
  0
  "Number of lines  of journalctl output with current opts.")


(defvar journalctl-current-opts
  ""
  "Keeps the optetes of  the last call of journalctl.")

(defvar journalctl-current-filter
  ""
  "Keeps filters as grep that shall be applied to journalctl's output.")

(defvar journalctl-disk-usage
  (concat
   "Disk-usage: "
   (shell-command-to-string "journalctl --disk-usage | egrep -o '[0-9.]+G'"))
  "Disk-usage of  journalctl.")

;; functions

(defvar journalctl-list-of-options
  '("x" "b" "k" "S" "U" "l" "a" "e" "n" "r" "o"  "q" "m" "t" "u" "p"
   "F" "M" "D"
   "since" "until" "dmesg" "boot"
   "system" "user"
   "unit" "userunit"
   "directory" "file" "machine" "root"
   "nofull" "full" "all"
   "pagerend"
   "output"   "outputfields"
   "utc"
   "nohostname"
   "catalog" "quiet"
   "merge"
   "identifier" "priority"
   "fields" )
  "List of possible options to be given to journalctl without the first dash." )

(defun journalctl-parse-options (opt)
 "Parse options (OPT)  given to journalctl."
 (interactive)
 (let ((opt-list nil))
 (let  ((list  (split-string	opt " -" t "[- ]+")))
    (while list
      (setq opt-list (cons (split-string   (car list) "[= ]+" t "[ ']*") opt-list))
      (setq list (cdr list))))
  ;;  Add function to test the options and maybe values
  (let ((list opt-list))
     (while  list
      (let ((this-opt (car (car list))))
    (unless (member  this-opt  journalctl-list-of-options)
      (progn
	;; skip invalid option
	(setq opt-list (delete (car list) opt-list))
	(message "Option %s is not valid and will be skipped."   this-opt))))
      (setq list (cdr list))))
  ;;set journalctl-current-opts to  opt-list
  (setq journalctl-current-opts opt-list)))

(defun journalctl-unparse-options ()
 "Join options to  a string, this is given to  journalctl."
 (interactive)
 (let* ((opt " ")
	(opt-list journalctl-current-opts))
     (while opt-list
       (let ((this-opt (car opt-list)))
	 (if (> (length this-opt) 1) ;; check if option needs a value
	    (setq opt  (concat opt
		     (if (> (string-width (car this-opt)) 1) ;; long or short options
			    (concat "--" (car this-opt) "=");; long option with value
			    (concat "-" (car this-opt) " "));; short option with value
		     (let ((value "'")
			   (value-chunks (cdr this-opt)))
		       (while value-chunks ;; value may co ntain spaces -> saved as list
			 (setq value (concat value (car value-chunks) " "))
			 (setq value-chunks (cdr value-chunks)))
		       (when (string-equal (substring value  -1) " ") (setq value (substring value 0 -1)))
		       value)
		     "' "))
	   ;; else
	   (if (> (string-width (car this-opt)) 1) ;; long or short options
	       (setq opt (concat opt "--" (car this-opt) " "))
	     (setq opt (concat opt "-" (car this-opt) " ")))))
       (setq opt-list (cdr opt-list)))
     (message "%s" opt)))
     

;;; Main
(defun journalctl (&optional opt chunk)
 "Run journalctl with give OPT and present CHUNK of  output in a special buffer.
If OPT is t the options in 'journalctl-current-opts' are taken."
  (interactive)
  (unless (eq opt t)
  (let ((opt (or opt (read-string "option: " "-x  -n 1000" nil "-x "))))
    (journalctl-parse-options opt)))
    (let ((opt (journalctl-unparse-options)))
    (setq journalctl-current-lines (string-to-number (shell-command-to-string (concat "journalctl " opt "|  wc -l"))))
    (let* ((this-chunk (or chunk  0)) ;; if chunk is not explicit given, we assume this first (0) chunk
	         (first-line (+ 1 (* this-chunk journalctl-chunk-size)))
	         (last-line (if (<= (+ first-line journalctl-chunk-size)
                              journalctl-current-lines)
			                    (+ first-line journalctl-chunk-size)
		                    journalctl-current-lines)))
      (with-current-buffer (get-buffer-create "*journalctl*")
        (setq buffer-read-only nil)
        (fundamental-mode)
        (erase-buffer))
      (save-window-excursion
       (shell-command (concat "journalctl " opt journalctl-current-filter
                              " | sed -ne '"  (int-to-string first-line) ","
                              (int-to-string last-line) "p'")
                      "*journalctl*" "*journalctl-error*"))
      (switch-to-buffer "*journalctl*")
      (setq buffer-read-only t)
;;      (setq journalctl-current-opts opt)
      (journalctl-mode))))


;;;;;; Moving and Chunks

(defun journalctl-next-chunk ()
  "Load the next chunk of journalctl output to the buffer."
  (interactive)
  (let* ((chunk (if  (> (* (+ 2 journalctl-current-chunk) journalctl-chunk-size) journalctl-current-lines)
		    journalctl-current-chunk
		  (+ journalctl-current-chunk 1) )))
	(setq journalctl-current-chunk chunk)
	(journalctl t  chunk)))

(defun journalctl-previous-chunk ()
  "Load the previous chunk of journalctl output to the buffer."
  (interactive)
  (let ((chunk (if (>= journalctl-current-chunk 1) (- journalctl-current-chunk 1) 0)))
	(setq journalctl-current-chunk chunk)
	(journalctl t  chunk)))

(defun journalctl-scroll-up ()
  "Scroll up journalctl output or move to next chunk when bottom of frame is reached."
  (interactive)
  (let ((target-line  (+ (current-line) 25)))
    (if (>= target-line journalctl-current-lines)
	(message "%s" "End of journalctl output")
      (if (>= target-line journalctl-chunk-size)
	(journalctl-next-chunk)
      (forward-line 25)))))

(defun journalctl-scroll-down ()
  "Scroll down journalctl output or move to next chunk when bottom of frame is reached."
  (interactive)
  (let ((target-line  (- (current-line) 25)))
    (if (<= target-line 0)
	(if (<=  journalctl-current-chunk 0)
	    	(message "%s" "Beginn of journalctl output")
	(journalctl-previous-chunk)))
      (forward-line  -25)))

;;;;;;;; Special functions
;;;###autoload
(defun journalctl-boot (&optional boot)
  "Select and show boot-log.

If BOOT is provided it is the number of the boot-log to be shown."
  (interactive)
  (let ((boot-log (or boot (car (split-string
				 (completing-read "Boot: " (reverse (split-string
		     (shell-command-to-string "journalctl --list-boots") "[\n]" t " ")) nil t))))))
    (journalctl (concat "-b '" boot-log "'"))))

;;;###autoload
(defun journalctl-unit (&optional unit)
  "Select and show journal for UNIT."
  (interactive)
  (let ((unit (or unit (car (split-string
				 (completing-read "unit: " (split-string
		     (shell-command-to-string "systemctl list-units --all --quiet | awk '{print $1}' | head -n -7 | sed -ne '2,$p'| sed -e '/●/d'") "[\n]" t " ") nil t))))))
    (journalctl (concat "--unit='" unit "'"))))

;;;###autoload
(defun journalctl-user-unit (&optional unit)
  "Select and show journal for the user-unit UNIT."
  (interactive)
  (let ((unit (or unit (car (split-string
				 (completing-read "unit: " (split-string
		     (shell-command-to-string "systemctl list-units --all --user --quiet | awk '{print $1}' | head -n -7 | sed -ne '2,$p'| sed -e '/●/d'") "[\n]" t " ") nil t))))))
    (journalctl (concat "--user-unit='" unit "'"))))


(defun journalctl-add-opt (&optional opt)
  "Add options to journalctl call.

If OPT is set, use these options."
  (interactive)
  (let* ((opt-list nil)
	(opt (or opt (read-string "option: " "" nil ))))
    (let  ((list  (split-string	opt " -" t "[- ]+")))
    (while list
      (setq opt-list (cons (split-string   (car list) "[= ]+" t "[ ']*") opt-list))
      (setq list (cdr list))))
    ;;  Add function to test the options and maybe values
    (let ((list opt-list))
      (while  list
	(let ((this-opt (car (car list))))
	  ;; delete old option values if given.
	  (when  (member  this-opt (mapcar (lambda (arg) (car arg)) journalctl-current-opts))
	    (setq journalctl-current-opts (delq (assoc this-opt journalctl-current-opts)
						journalctl-current-opts)))
        (unless (member  this-opt  journalctl-list-of-options)
	  (progn
	;; skip invalid option.
	(setq opt-list (delete (car list) opt-list))
	(message "Option %s is not valid and will be skipped."   this-opt))))
      (setq list (cdr list))))
    ;;add opt-list to  journalctl-current-opts.
    (setq journalctl-current-opts  (append opt-list journalctl-current-opts)))
    (journalctl t journalctl-current-chunk))

(defun journalctl-add-since (&optional date)
  "Add '--since' option with DATE or ask for date."
  (interactive)
  (let ((date (or  date
		   (if  (fboundp 'org-read-date)  (org-read-date t)
		     (read-string "Date [yy-mm-dd [hh:mm[:ss]]]: ")))))
     (journalctl-add-opt (concat " --since='" date "'"))))

(defun journalctl-add-until (&optional date)
  "Add '--until' option with DATE or ask for date."
  (interactive)
  (let ((date (or  date
		   (if  (fboundp 'org-read-date)  (org-read-date t) (read-string "Date [yy-mm-dd [hh:mm[:ss]]]: ")))))
     (journalctl-add-opt (concat " --until='" date "'"))))

(defun journalctl-add-priority (&optional priority to-priority)
  "Add '--priority' option with PRIORITY.
If TO-PRIORITY is non-nil, call '--priority' with range
from PRIORITY  TO-PRIORITY.
If none is non-nil it will prompt for priority (range)."
  (interactive)
  (let* ((from-priority (or  priority (completing-read "Priority: "
						 '("emerg" "alert" "crit" "err" "warning" "notice" "info" "debug")
						 nil t "warning")))
	 (to-priority (if  priority
			 (or to-priority nil)
			(or to-priority  (completing-read "Priority: "
						 '(("emerg" "alert" "crit" "err" "warning" "notice" "info" "debug"))
						 nil nil priority))))
	 (opt (concat "--priority='" from-priority (when to-priority
						       (unless (string-equal from-priority to-priority) (concat ".." to-priority))) "'")))
     (journalctl-add-opt opt)))

(defun journalctl-remove-opt (&optional opt)
  "Remove option from journalctl call.

If OPT is set, remove this option."
  (interactive)
  (let* ((opt-list (mapcar (lambda (arg) (car arg)) journalctl-current-opts))
	 (opt (or opt (completing-read "option: " opt-list  nil t))))
    (when  (member opt opt-list)
      (setq journalctl-current-opts (delq (assoc opt journalctl-current-opts) journalctl-current-opts))))
    (journalctl t journalctl-current-chunk))

(defun journalctl-grep (&optional pattern)
  "Run journalctl with -grep flag to search for PATTERN."
  (interactive)
  (let ((pattern (or pattern (read-string "grep pattern: " nil nil ))))
    (setq journalctl-current-filter (concat journalctl-current-filter  "| grep '" pattern "'" ))
    (journalctl journalctl-current-opts journalctl-current-chunk)))

(defun journalctl-remove-filter ()
  "Remove all filters such as grep from journalctl output."
  (interactive)
  (setq journalctl-current-filter "")
    (journalctl journalctl-current-opts journalctl-current-chunk))
  
(defun  journalctl-edit-opts ()
  "Edit the value of 'journalctl-current-opts'."
  (interactive)
  (let ((opt (read-string "Options: " (journalctl-unparse-options))))
    (journalctl-parse-options opt)
    (journalctl t journalctl-current-chunk)))


;;;;;;;;;;;;;;;;; Fontlock


(defvar journalctl-font-lock-keywords
      (let* (
            ;; generate regex string for each category of keywords
	     (error-keywords-regexp (regexp-opt journalctl-error-keywords 'words))
	     (warn-keywords-regexp (regexp-opt journalctl-warn-keywords 'words))
	     (starting-keywords-regexp (regexp-opt journalctl-starting-keywords 'words))
	     (finished-keywords-regexp (regexp-opt journalctl-finished-keywords 'words)))
        `(
          (,warn-keywords-regexp . 'journalctl-warning-face)
          (,error-keywords-regexp . 'journalctl-error-face)
          (,starting-keywords-regexp . 'journalctl-starting-face)
          (,finished-keywords-regexp . 'journalctl-finished-face)
	  ("^\\([A-Z][a-z]+ [0-9]+ [0-9:]+\\)" . (1 'journalctl-timestamp-face))
	  ("^\\([A-Z][a-z]+ [0-9]+ [0-9:]+\\) \\([-a-zA-Z]+\\)" . (2 'journalctl-host-face))
	  ("^\\([A-Z][a-z]+ [0-9]+ [0-9:]+\\) \\([-a-zA-Z]+\\) \\(.*?:\\)" . (3 'journalctl-process-face))

          ;; note: order above matters, because once colored, that part won't change.
          ;; in general, put longer words first
          )))

;; keymap
(defvar journalctl-mode-map
  (let ((map (make-keymap "journalctl")))
    (define-key map (kbd "n") 'journalctl-next-chunk)
    (define-key map (kbd "p") 'journalctl-previous-chunk)
    ;; add opts
    (define-key map (kbd "+ +")  'journalctl-add-opt)
    (define-key map (kbd "+ r")  (lambda () (interactive) (journalctl-add-opt "r" )));; reverse output
    (define-key map (kbd "+ x")  (lambda () (interactive) (journalctl-add-opt "x" )));; add explanations
    (define-key map (kbd "+ s")  (lambda () (interactive) (journalctl-add-opt "system" )));; system-units only
    (define-key map (kbd "+ u")  (lambda () (interactive) (journalctl-add-opt "user" )));; user-units only
    (define-key map (kbd "+ k")  (lambda () (interactive) (journalctl-add-opt "dmesg" )));; user-units only
    (define-key map (kbd "+ S")  'journalctl-add-since)
    (define-key map (kbd "+ U")  'journalctl-add-until)
    (define-key  map (kbd "+ p")  'journalctl-add-priority)
    ;; remove opts
    (define-key map (kbd "- -")  'journalctl-remove-opt)
    (define-key map (kbd "- r")  (lambda () (interactive) (journalctl-remove-opt "r" )));; reverse output
    (define-key map (kbd "- x")  (lambda () (interactive) (journalctl-remove-opt "x" )));; remove explanations
    (define-key map (kbd "- s")  (lambda () (interactive) (journalctl-remove-opt "system" )));; system-units only
    (define-key map (kbd "- u")  (lambda () (interactive) (journalctl-remove-opt "user" )));; user-units only
    (define-key map (kbd "- k")  (lambda () (interactive) (journalctl-remove-opt "dmesg" )));; user-units only
    (define-key map (kbd "- S")  (lambda () (interactive) (journalctl-remove-opt "since" )))
    (define-key map (kbd "- U")  (lambda () (interactive) (journalctl-remove-opt "until" )))
    (define-key  map (kbd "- p")  (lambda () (interactive) (journalctl-remove-opt "priority" )))
    ;;  edit opts
    (define-key map (kbd "e") 'journalctl-edit-opts)
    ;; grep
    (define-key map (kbd "+ g")  'journalctl-grep)
    (define-key map (kbd "- g")  'journalctl-remove-filter)
    ;;
    (define-key map (kbd "C-v") 'journalctl-scroll-up)
    (define-key map (kbd "M-v") 'journalctl-scroll-down)
    (define-key map (kbd "q")  (lambda () (interactive) (kill-buffer  "*journalctl*")))
    map)
  "Keymap for journalctl mode.")

;;;###autoload
(define-derived-mode journalctl-mode fundamental-mode "journalctl"
  "Major mode for viewing journalctl output"
  (setq mode-line-process journalctl-disk-usage)
  ;; code for syntax highlighting
  (setq font-lock-defaults '((journalctl-font-lock-keywords))))


;; add the mode to the `features' list
(provide 'journalctl-mode)

;;; journalctl-mode.el ends here
