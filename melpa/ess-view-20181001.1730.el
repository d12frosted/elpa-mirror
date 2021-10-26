;;; ess-view.el --- View R dataframes in a spreadsheet software

;; Copyright (C) 2016 Bocci Gionata

;; Author: Bocci Gionata <boccigionata@gmail.com>
;; Maintainer: Bocci Gionata <boccigionata@gmail.com>
;; URL: https://github.com/GioBo/ess-view
;; Package-Version: 20181001.1730
;; Package-Commit: 925cafd876e2cc37bc756bb7fcf3f34534b457e2
;; Created: 2016-02-10
;; Version: 0.1
;; Package-Requires: ((ess "15")  (s "1.8.0") (f "0.16.0"))
;; Keywords: extensions, ess

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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


;; When working with big R dataframes, the console is impractical for looking at
;; its content; a spreadsheet software is a much more convenient tool for this task.
;; This package allows users to have a look at R dataframes in an external
;; spreadsheet software.

;; If you simply want to have a look at a dataframe simply hit (inside a buffer running
;; an R process)

;; C-x w

;; and you will be asked for the name of the object (dataframe) to
;; view... it's a simple as that!

;; If you would like to modify the dataframe within the spreadsheet
;; software and then have the modified version loaded back in the
;; original R dataframe, use:

;; C-x q

;; When you've finished modifying the dataset, save the file (depending
;; on the spreadsheet software you use, you may be asked if you want to
;; save the file as a csv file and/or you want to overwrite the original
;; file: the answer to both question is yes) and the file content will be
;; saved in the original R dataframe.


;; If these functions are called with the prefix argument 0, then the dataframes
;; will be exported with their row.names, eg. use:

;; C-u 0 C-x w  (to see the object)

;; C-u 0 C-x q  (to see it and then have it saved back in the R dataframe)
;;
;;
;;; Code:

(require 'ess)
(require 'ess-inf)
(require 'ess-site)
(require 'f)
(require 's)


(defvar ess-view--spreadsheet-program (or
				       (executable-find "libreoffice")
				       (executable-find "openoffice")
				       (executable-find "gnumeric")
				       (executable-find "soffice")
				       nil)
   "Spreadsheet software to be used to show data.")

(defvar ess-view--rand-str
  "Random string to be used for temp files.")

(defvar ess-view-oggetto
  "Name of the R dataframe to work with.")

(defvar ess-view-newobj
  "Temp name to be used for the temporary copy of R object")

(defvar ess-view-temp-file
  "Temporary file to be used to save the csv version of the dataframe")

(defvar ess-view-string-command
  "Command - as a string - to be passed to the R interpreter.")

(defvar ess-view-spr-proc
  "Process of the called spreadsheet software.")


(defun ess-view-print-vector (obj)
  "Print content of vector OBJ in another buffer.
In case the passed object is a vector it is not convenient to use
an external spreadsheet sofware to look at its content."
  (let ((header (concat obj " contains the following elements: \n")))
    (ess-execute (concat "cat(" obj ",sep='\n')") nil "*BUFF*" header)))


(defun ess-view-random-string ()
  "Create a string of 20 random characters."
  (interactive)
  (setq ess-view--rand-str (make-string 20 0))
  (let ((mycharset "abcdefghijklmnopqrstuvwxyz"))
    (dotimes (i 20)
      (aset ess-view--rand-str i (elt mycharset (random (length mycharset)))))
    ess-view--rand-str))


(defun ess-view-create-env ()
  "Create a temporary R environment.
This is done in order not to pollute user's environments with a temporary
copy of the passed object which is used to create the temporary .csv file."
  (interactive)
  (let ((nome-env (ess-view-random-string)))
    ;; it is very unlikely that the user has an environment which
    ;; has the same name of our random generated 20-char string,
    ;; but just to be sure, we run this cycle recursively
    ;; until we find an environment name which does not exist yet
    (if (ess-boolean-command (concat "is.environment(" nome-env ")\n"))
        (ess-view-create-env))
    nome-env))



(defun ess-view-send-to-R (R-PROCESS STRINGCMD)
  "A wrapper function to send commands to the R process.
Argument STRINGCMD  is the command - as a string - to be passed to the R process."
  (ess-send-string (get-process R-PROCESS) STRINGCMD nil))


(defun ess-view-write--sentinel (process signal)
  "Check the spreadsheet (PROCESS) to intercept when it is closed (SIGNAL).
The saved version of the file - in the csv fomat -is than converted back
to the R dataframe."
  (cond
   ((equal signal "finished\n")
    (progn
      (ess-view-check-separator ess-view-temp-file)
      (ess-view-send-to-R ess-view-chosen-R-process (format "%s <- read.table('%s',header=TRUE,sep=',',stringsAsFactors=FALSE)\n" ess-view-oggetto ess-view-temp-file))))))


(defun ess-view-clean-data-frame (R-PROCESS obj)
  "This function cleans the dataframe of interest.
Factors are converted to characters (less problems when exporting), NA and
'NA' are removed so that reading the dataset within the spreadsheet software
is clearer.
Argument R-PROCESS is the running R process where
the dataframe of interest is to be found.
Argument OBJ is the name of the dataframe to be cleaned."
  (ess-view-send-to-R R-PROCESS (format "%s[sapply(%s,is.factor)]<-lapply(%s[sapply(%s,is.factor)],as.character)" obj obj obj obj))
  (ess-view-send-to-R R-PROCESS (format "%s[is.na(%s)]<-''\n" obj obj))
  (ess-view-send-to-R R-PROCESS (format "%s[%s=='NA']<-''\n" obj obj)))


(defun ess-view-extract-R-process ()
"Return the name of R running in current buffer."
  (let*
      ((proc (get-buffer-process (current-buffer)))
       (string-proc (prin1-to-string proc))
       (selected-proc (s-match "^#<process \\(R:?[0-9]*\\)>$" string-proc)))
    (nth 1 (-flatten selected-proc))
    )
  )

  

(defun ess-view-data-frame-view (object save row-names dframe)
  "This function is used in case the passed OBJECT is a data frame.
Argument SAVE if t means that the user wants to store the spreadsheet-modified
version of the dataframe in the original object.
Argument ROW-NAMES is either t or nil: in case it's true, user wants to save
the row names of the dataframe as well.
Argument DFRAME is t if the object of interest is a dataframe: if so, it is
'cleaned' (via ess-view-clean-data-frame) before exporting; if it's a matrix
it is not cleaned."
  ;;  (interactive)
  (save-excursion

    ;; create a temp environment where we will work
    (let
	((envir (ess-view-create-env))
	 (win-place (current-window-configuration))
	 (R-process (ess-view-extract-R-process))
	 )
      
      (setq ess-view-chosen-R-process R-process)
      (ess-view-send-to-R ess-view-chosen-R-process (concat envir "<-new.env()\n"))
      ;; create a copy of the passed object in the custom environment
      (ess-view-send-to-R ess-view-chosen-R-process (concat envir "$obj<-" object "\n"))
      ;; create a variable containing the complete name of the object
      ;; (in the form environm$object
      (setq ess-view-newobj (concat envir "$obj"))
      ;; remove NA and NAN so that objects is easier to read in spreadsheet file
      (if dframe
	  (ess-view-clean-data-frame R-process ess-view-newobj))
      ;; create a csv temp file
      (setq ess-view-temp-file (make-temp-file nil nil ".csv"))
      (if row-names (setq row-names "row.names=TRUE,col.names=NA")
	(setq row-names "row.names=FALSE"))
      ;; write the passed object to the csv tempfile
      (setq ess-view-string-command (concat "write.table(" ess-view-newobj ",file='" ess-view-temp-file "',sep=','," row-names ")\n"))
      (ess-view-send-to-R ess-view-chosen-R-process ess-view-string-command)
      ;; wait a little just to be sure that the file has been written (is this necessary? to be checked)
      (sit-for 1)

      ;; start the spreadsheet software to open the temp csv file
      (setq ess-view-spr-proc (start-process "spreadsheet" nil ess-view--spreadsheet-program ess-view-temp-file))
      (if save
	  (set-process-sentinel ess-view-spr-proc 'ess-view-write--sentinel))

      (set-window-configuration win-place)
      ;; remove the temporary environment
      (ess-view-send-to-R ess-view-chosen-R-process (format "rm(%s)" envir)))))


(defun ess-no-program ()
  "Request user to set the default spreadsheet software."
  (with-output-to-temp-buffer "*ess-view-error*"
    (with-current-buffer "*ess-view-error*"
      (princ " \t-- ess-view Message --\n\n")
      (princ "No spreadsheet software was found.\n\n")
      (princ "Please store the path to your spreadsheet software in the ess-view--spreadsheet-program\n")
      (princ "variable, eg. write in you .emacs file:\n\n\n")
      (princ "(setq ess-view--spreadsheet-program \"/path/to/my/software.EXE\")\n")
      (princ "\n\n"))
    (pop-to-buffer "*ess-view-error*")))


(defun ess-view-check-separator (file-path)
  "Try to convert the tmp file to the csv format.
This is a tentative strategy to obtain a csv content from the file - specified
by FILE-PATH - separated by commas, regardless of the default field separator
used by the spreadsheet software."
  (let ((testo (s-split "\n" (f-read file-path) t)))
    (setq testo (mapcar (lambda (x) (s-replace-all '(("\t" . ",") ("|" . ",") (";" . ",")) x)) testo))
    (setq testo (s-join "\n" testo))
    (f-write-text testo 'utf-8 file-path)))


(defun ess-view-inspect-df-inner (row-names save)
  "Show a dataframe.
If ROW-NAMES is t, the row names of the dataframe are also exported.
If SAVE is t, it also saves back the result."
  (if ess-view--spreadsheet-program
      (progn
        (setq ess-view-oggetto (ess-read-object-name "name of R object:"))
        (setq ess-view-oggetto (substring-no-properties (car ess-view-oggetto)))
        (cond
         ((ess-boolean-command (concat "exists(" ess-view-oggetto ")\n"))
          (message "The object does not exists"))
         ((ess-boolean-command (concat "is.vector(" ess-view-oggetto ")\n"))
          (ess-view-print-vector ess-view-oggetto))
         ((ess-boolean-command (concat "is.data.frame(" ess-view-oggetto ")\n"))
          (ess-view-data-frame-view ess-view-oggetto save row-names t))
         ((ess-boolean-command (concat "is.matrix(" ess-view-oggetto ")\n"))
          (ess-view-data-frame-view ess-view-oggetto save nil nil))

	 (t
          (message "the object is neither a vector or a data.frame; don't know how to show it..."))))
    (ess-no-program)))


(defun ess-view-inspect-df (&optional row-names)
  "Show a dataframe.
If ROW-NAMES is t, the row names of the dataframe are also exported."
  (interactive "P")
  (ess-view-inspect-df-inner (if (eq row-names 0) t nil) nil))


(defun ess-view-inspect-and-save-df (&optional row-names)
  "Show a dataframe and save the result.
If ROW-NAMES is t, the row names of the dataframe are also exported."
  (interactive "P")
  (ess-view-inspect-df-inner (if (eq row-names 0) t nil) t))


(global-set-key (kbd "C-x w") 'ess-view-inspect-df)
(global-set-key (kbd "C-x q") 'ess-view-inspect-and-save-df)


(define-minor-mode ess-view-mode
  "Have a look at dataframes."
  :lighter " ess-v"
  :keymap (let ((map (make-sparse-keymap)))
	    (define-key map (kbd "C-x w") 'ess-view-inspect-df)
	    (define-key map (kbd "C-x q") 'ess-view-inspect-and-save-df)
	    map))


(add-hook 'ess-post-run-hook 'ess-view-mode)
(provide 'ess-view)


;;; ess-view.el ends here
