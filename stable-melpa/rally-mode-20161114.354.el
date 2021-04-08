;;; rally-mode.el --- a mode to interact with the Rally Software web site.

;; Copyright (C) 2015 Sean LeBlanc
;; Author: Sean LeBlanc <seanleblanc@gmail.com>
;; Maintainer: Sean LeBlanc <seanleblanc@gmail.com>
;; Created: 15 Oct 2015
;; Version: 1.3
;; Package-Requires: ((popwin "1.0.0"))
;; Keywords: Rally, CA, agile
;; Homepage: https://pragcraft.wordpress.com/

;;; Commentary: A mode for the Rally website.
;;
;; rally-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; rally-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with rally-mode.  If not, see http://www.gnu.org/licenses.
;;
;; To use - M-x rally-current-iteration, enter Rally username and password.

;;; Code: 

(require 'popwin)
(require 'json)

(defvar rally-user)
(defvar rally-password)
(defvar rally-tasks-cache nil)

(define-derived-mode rally-mode special-mode "rally-mode"
  "Major mode for interacting with Rally website."
  :group 'rally-mode)

; Refresh:
(define-key rally-mode-map (kbd "g") 'rally-current-iteration)

; Display the contents of the story/defect:
(define-key rally-mode-map (kbd "<SPC>") 'rally-get-description)

; Handy for experimenting with display w/o re-fetching data
(define-key rally-mode-map (kbd "r") 'rally-draw-results)   


(defcustom rally-detail-pane-position 'bottom
  "Position of the popup entry pane."
  :group 'rally-mode
  :type '(choice (const left) (const right) (const top) (const bottom)))

(defcustom rally-detail-pane-size 0.75
  "Size (width or height, depending on position) of the popup entry pane."
  :group 'rally-mode
  :type 'number)

(defvar xyz-block-authorisation nil 
   "Flag whether to block url.el's usual interactive authorisation procedure")

(defadvice url-http-handle-authentication (around xyz-fix)
  (unless xyz-block-authorisation
    ad-do-it))

(ad-activate 'url-http-handle-authentication)

;; Similar to sqlplus' shine-color func:
(defun rally-shine-color (color change)
  (apply 'color-rgb-to-hex
	 (mapcar (lambda (arg) (max 0.0 (min 1.0 (+ arg change))))
		   (color-name-to-rgb color))))

(defun rally-build-url (url-server-string params)
  (concat url-server-string "?"
	  (url-build-query-string params)))

(defun rally-basic-auth (url user pass)
  ;;(princ url) 
  (let ((xyz-block-authorisation t)
	(url-request-method "GET")
	(url-queue-timeout 60)
	(url-request-extra-headers 
	 `(("Content-Type" . "application/xml")
	   ("Authorization" . ,(concat "Basic "
				       (base64-encode-string
					(concat user ":" pass)))))))
     (with-current-buffer (url-retrieve-synchronously url t)
       (delete-region 1 url-http-end-of-headers)
       (buffer-string)
       )))

(defun rally-make-url-lst (username password)
  `(
    (query ,(format "((Owner.Name = %s ) AND (( Iteration.StartDate <= today ) AND (Iteration.EndDate >= today)) )" username ) )
    (order Rank)
    (fetch "true,WorkProduct,Tasks,Iteration,Estimate,State,ToDo,Name,Description,Type")
    ))

(defun rally-make-query (username password)
   (rally-build-url
	      "https://rally1.rallydev.com/slm/webservice/v2.0/task"
	      (rally-make-url-lst username password)
	       ))

(defun rally-current-iteration-info (username password)
  (rally-basic-auth
   (rally-make-query username password) 
	       username 
	       password))

(defun rally-extract-info (lst)
  (list
   `(TaskName . ,(assoc-default '_refObjectName lst ))
   `(WorkItemDescription . ,(assoc-default '_refObjectName (cl-find 'WorkProduct lst :key #'car ) ))
   `(SprintName . ,(assoc-default '_refObjectName (cl-find 'Iteration lst :key #'car ) ))
   (assoc 'State lst)
   (assoc 'ToDo lst)
   (assoc 'Estimate lst)
   (assoc 'FormattedID lst)   
   `(WorkItemName . ,(assoc-default 'FormattedID (cl-find 'WorkProduct lst :key #'car)))
   `(Description . ,(assoc-default 'Description (cl-find 'WorkProduct lst :key #'car ) ))
   ))

(defun rally-fetch-current-iteration-info-as-json ()
  (rally-current-iteration-info
   (setq rally-user (read-string "Rally user/email:" (if (boundp 'rally-user) rally-user nil)))
   (setq rally-password (read-passwd "Rally password:" nil (if (boundp 'rally-password) rally-password nil )))))

(defun rally-parse-json-results (json-string)
  (progn
    (rally-log json-string)
    (json-read-from-string json-string)
    ))

(defun rally-get-task-list (parsed-json)
  (cdr (assoc 'Results (assoc 'QueryResult parsed-json))))


(defun rally-fetch-and-parse-current-iteration-info ()
  (mapcar #'rally-extract-info (rally-get-task-list (rally-parse-json-results (rally-fetch-current-iteration-info-as-json)))))

(defun rally-get-buffer ()
  (get-buffer-create "*rally-current-iteration*"))

(defvar rally-line-string nil "Formatting for Rally info.")
;(setq rally-line-string "%-6s/%-6s %-90.90s %-10s %-4s %-4s\n")
(setq rally-line-string "%-6s %-90.90s %-10s %-4s %-4s\n")

(defun rally-write-task-line (parsed-json)
  (insert (format rally-line-string
		  (assoc-default 'WorkItemName parsed-json)
		  ;(assoc-default 'FormattedID parsed-json)
		  (assoc-default 'WorkItemDescription parsed-json)
		  (assoc-default 'State parsed-json)
		  (assoc-default 'Estimate parsed-json)
		  (assoc-default 'ToDo parsed-json)
		  )))

(defun rally-format-header (str)
  (propertize str
	      'face
	      `(:background ,(rally-shine-color (face-background 'default) +.2) :foreground ,(rally-shine-color (face-foreground 'default) +.2) :weight bold )))
							    
(defun rally-log (str)
  (progn
    ;(message "trying to log")
    (message "%s" str)
    (message "")))		    
			    

(defun rally-write-header ()
  (insert (rally-format-header (format rally-line-string
		    "Story"
		    "Description"
		    "Status"
		    "Est."
		    "ToDo"
		    ) )))

(rally-shine-color (face-foreground 'default) -.6)
(face-background 'default)

(rally-shine-color (face-background 'default) +20)
(defun rally-write-output-to-buffer (buf parsed-json)
  (with-current-buffer buf 
    (rally-write-header)
    (mapcar #'rally-write-task-line parsed-json)))

(defun rally-draw-results ()
  (interactive)
  (let ((rally-current-iteration-buffer (rally-get-buffer)))
    (switch-to-buffer rally-current-iteration-buffer)
    (rally-mode)
    (let (buffer-read-only)
    (progn          
      (erase-buffer)
      (rally-write-output-to-buffer (rally-get-buffer) rally-tasks-cache)))))

;;;###autoload
(defun rally-current-iteration ()
  "Pulls up current iteration information for the supplied user."
  (interactive)
      (progn 
	(setq rally-tasks-cache (rally-fetch-and-parse-current-iteration-info))
	(rally-draw-results)))

(defun rally-extract-description (idx)
  (assoc 'Description (nth idx rally-tasks-cache)))

(defun rally-get-description ()
  "Get detailed description of story/defect."
  (interactive)
  (rally-display-description
   (cdr (rally-extract-description (- (line-number-at-pos) 2)))))

(defun rally-get-detail-buffer ()
  (get-buffer-create "*rally-detail*"))


(defun rally--clean-html (html)
  "Search/replace on problematic character sequences such as smart quotes"
  (replace-regexp-in-string "\342\200\235" "\"" (replace-regexp-in-string "\342\200\234" "\"" html)))

(defun rally-display-description (html)
  "Insert Story description html into buffer"
  (let
    (
     (rally-detail-buffer (rally-get-detail-buffer)))
    (rally-switch-pane rally-detail-buffer)
    (let (buffer-read-only)
      (progn
	(erase-buffer)
	(rally-insert-html (rally--clean-html html))
	(goto-char (point-min))))
    (other-window 1)))

(defun rally-switch-pane (buff)
  "Display BUFF in a popup window."
  (popwin:popup-buffer buff
                       :position rally-detail-pane-position
                       :width rally-detail-pane-size
                       :height rally-detail-pane-size
                       :stick t
                       :dedicated t))

(defun rally-insert-html (html &optional base-url)
  (shr-insert-document
   (if (rally-libxml-supported-p)
       (with-temp-buffer         
         (insert html)
         (libxml-parse-html-region (point-min) (point-max) base-url))
     '(i () "Rally-mode: libxml2 functionality is unavailable"))))

(defun rally-libxml-supported-p ()
  "Return non-nil if `libxml-parse-html-region' is available."
  (with-temp-buffer
    (insert "<html></html>")
    (and (fboundp 'libxml-parse-html-region)
         (not (null (libxml-parse-html-region (point-min) (point-max)))))))


(provide 'rally-mode)
;;; rally-mode.el ends here

