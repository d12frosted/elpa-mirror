;;; coq-commenter.el --- Coq commenting minor mode for proof

;; Copyright (C) 2016-2017 Junyoung Clare Jang <jjc9310@gmail.com>

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

;; Version: 0.4.2
;; Package-Version: 20170822.2309
;; Package-Commit: 7fe9a2cc0ebdb0b1e54a24eb7971d757fb588ac3
;; Keywords: comment coq proof
;; Author: Junyoung Clare Jang <jjc9310@gmail.com>
;; Maintainer: Junyoung Clare Jang <jjc9310@gmail.com>
;; URL: http://github.com/ailrun/coq-commenter
;; Package-Requires: ((dash "2.13.0") (s "1.11.0") (cl-lib "0.5"))

;;; Commentary:

;;
;; Minor mode for coq
;; 
;; You can automatically start this minor mode with following elisp
;; when you use Proof-General
;;
;;  (add-hook 'coq-mode-hook 'coq-commenter-mode)
;;
;; You can set your key with
;; 
;;  (define-key coq-commenter-mode-map
;;              (kbd "C-;")
;;              #'coq-commenter-comment-proof-in-region)
;;  (define-key coq-commenter-mode-map
;;              (kbd "C-x C-;")
;;              #'coq-commenter-comment-proof-to-cursor)
;;  (define-key coq-commenter-mode-map
;;              (kbd "C-'")
;;              #'coq-commenter-uncomment-proof-in-region)
;;  (define-key coq-commenter-mode-map
;;              (kbd "C-x C-'")
;;              #'coq-commenter-uncomment-proof-in-buffer)
;;
;; or whatever you want.
;;

;;; Code:
(require 'easymenu)

;; (require 'f)
;; (defconst coq-commenter-file (f-this-file))
(require 'cl-lib)
(require 's)
(require 'dash)


;; Group Definition

(defgroup coq-commenter
  nil
  "coq-commenter customization group"
  :prefix "coq-commenter-"
  :group 'convenience)

(defcustom coq-commenter--added-keyword-indent
  2
  "Indentation of added keyword(like Admitted).")

;; Internal variables

(defconst coq-commenter--v
  "154303401202")

(defconst coq-commenter--comment
  (s-concat
   "coq-commenter automat"
   coq-commenter--v
   "ic"))

(defconst coq-commenter--comment-regex
  (s-concat
   "coq-commenter automat"
   "[[:digit:]]"
   "ic"))

(defconst coq-commenter--proof-start-regex-part
  "Proof\\(?:\\.\\| with .*\\.\\)\\|Obligation [0-9]*\\.\\|Next Obligation\\.")

(defconst coq-commenter--proof-start-regex
  (s-concat
   "\\(^"
   coq-commenter--proof-start-regex-part
   "|[[:space:] .]*"
   coq-commenter--proof-start-regex-part
   "\\)"))

(defconst coq-commenter--proof-end-regex
  "\\(Qed\\(?:\\.\\| exporting\\.\\)\\)")

;; (defconst coq-proof-end-abnormal-regex
;;   "\\(\\(Abort\\.\\)\\|\\(Defined\\.\\)\\|\\(Admitted\\.\\)\\|\\(Admit\\.\\)\\)")

;; (defconst coq-proof-end-regex
;;   (s-concat
;;    coq-proof-end-normal-regex
;;    "\\|"
;;    coq-proof-end-abnormal-regex
;;    ))

;; commenting & uncommenting forms

(defconst coq-commenter--commenting-from
  (s-concat
   coq-commenter--proof-start-regex
   "\\([[:print:] \t\r\n]*\\)"
   coq-commenter--proof-end-regex))

(defconst coq-commenter--commenting-to-prefix
  (s-concat
   "\\1"
   "\n(" (s-repeat 20 "*") "\n"
   "\\2"
   "\\3"
   coq-commenter--comment
   "\n" (s-repeat 20 "*") ")\n"))

(defconst coq-commenter--commenting-to
  (s-concat
   coq-commenter--commenting-to-prefix
   (s-repeat coq-commenter--added-keyword-indent " ")
   "Admitted."))

(defconst coq-commenter--uncommenting-from
  (s-concat
   coq-commenter--proof-start-regex
   "\\(?:\n\\|\\)(" (s-repeat 20 "\\*") "\n"
   "\\(\\(?:[[:print:] \n\r\t]\\)*?\\)"
   coq-commenter--proof-end-regex
   "coq-commenter automat-?\\(?:[[:digit:]]*\\)ic"
   "\n" (s-repeat 20 "\\*") ")\n"
   "[[:space:]]*"
   "Admitted."))

(defconst coq-commenter--uncommenting-to
  (s-concat
   "\\1"
   "\\2"
   "\\3"))



;; commenting functions

(defun coq-commenter--find-closest-proof-start (startl end)
  "Find closest start points of proof among STARTL from END."
  (let ((closest  '(0 . 0))
		(lst      startl))
	(progn
	  (cl-labels ((distance (a b)
                            (- (car b) (cdr a))))
        (while (and (not (null lst))
                    (< 0 (distance (car lst) end)))
          (if (< (distance (car lst) end)
                 (distance closest end))
              (setq closest (car lst)))
          (setq lst (cdr lst))))
	  (if (and (/= (car closest) 0)
               (/= (cdr closest) 0))
		  (cons closest (cons end nil))))))

(defun coq-commenter--find-proofs (str comments proofstarts proofends)
  "Find valid proofs in STR using COMMENTS, PROOFSTARTS and PROOFENDS."
  (if (or (null proofstarts)
          (null proofends))
	  nil
    (cl-labels ((between-pos (a b)
                             (and (< (car a) (car b)) (> (cdr a) (cdr b))))
                (between-poss (a bl)
                              (--none? (between-pos it a) bl)))
      (let ((proofstarts1 (--filter (between-poss it comments) proofstarts))
            (proofends1   (--filter (between-poss it comments) proofends)))
        (--filter
         (not (null it))
         (--map (coq-commenter--find-closest-proof-start proofstarts1 it)
                proofends1))))))

(defun coq-commenter--comment-proof-at (proofpos qedpos)
  "Commenting a proof which starts at PROOFPOS and ends at QEDPOS."
;;  (print (cons (car proofpos) (cdr qedpos)))
  (perform-replace
   coq-commenter--commenting-from
   coq-commenter--commenting-to
   nil t nil nil nil
   (- (car proofpos) 1) (cdr qedpos)))

(defun coq-commenter--comment-proof-from-to (start end)
  "Commenting proofs from START to END."
  (save-excursion
	(let ((fullstr   (buffer-substring-no-properties (point-min) (point-max)))
		  (str       (buffer-substring-no-properties start end)))
      (cl-labels ((add-start-positions (pl start)
                                       (--map
                                        (cons (+ (car it) start)
                                              (+ (cdr it) start)) pl)))
        (let ((comments    (s-matched-positions-all
                            "(\\*[[:print:] \t\r\n]*?\\*)"
                            fullstr))
              (proofstarts (add-start-positions
                            (s-matched-positions-all
                             coq-commenter--proof-start-regex
                             str)
                            start))
              (proofends   (add-start-positions
                            (s-matched-positions-all
                             coq-commenter--proof-end-regex
                             str)
                            start)))
          (let ((proofs (coq-commenter--find-proofs str comments proofstarts proofends)))
            (progn
              (setq proofs (reverse proofs))
              (--map (coq-commenter--comment-proof-at (car it)
                                                    (cadr it)) proofs))))))))

(defun coq-commenter-comment-proof-in-region ()
  "Commenting proofs in the region."
  (interactive)
  (if (null (use-region-p))
          (print "No region specified!")
        (coq-commenter--comment-proof-from-to (region-beginning)
                                              (region-end))))

(defun coq-commenter-comment-proof-in-buffer ()
  "Commenting proofs in the buffer."
  (interactive)
  (coq-commenter--comment-proof-from-to (point-min)
                                        (point-max)))

(defun coq-commenter-comment-proof-to-cursor ()
  "Commenting proofs to the cursor point."
  (interactive)
  (coq-commenter--comment-proof-from-to (point-min)
                                        (point)))


;; Uncommenting functions

(defun coq-commenter--uncomment-proof-from-to (start end)
  "Uncommenting proofs from START to END."
  (save-excursion
	(let ((windstart (window-start)))
	  (progn
		(perform-replace
		 coq-commenter--uncommenting-from
		 coq-commenter--uncommenting-to
		 nil t nil nil nil
		 start end)
		(set-window-start (selected-window) windstart)))))

(defun coq-commenter-uncomment-proof-in-region ()
  "Uncommenting proofs in the region."
  (interactive)
  (if (null (use-region-p))
          (print "No region specified!")
        (coq-commenter--uncomment-proof-from-to (region-beginning)
                                                (region-end))))

(defun coq-commenter-uncomment-proof-in-buffer ()
  "Uncommenting proofs in the buffer."
  (interactive)
  (coq-commenter--uncomment-proof-from-to (point-min) (point-max)))

(defun coq-commenter-uncomment-proof-to-cursor ()
  "Uncommenting proofs to the cursor point."
  (interactive)
  (coq-commenter--uncomment-proof-from-to (point-min) (point)))

(defvar coq-commenter-mode-map (make-sparse-keymap))

;;;###autoload
(define-minor-mode coq-commenter-mode
  "Commenting support mode for coq proof assistant."
  ;; mode line indicator
  :lighter " CoqCom")

(defvar coq-commenter--mode-menu nil
  "Holds coq-commenter-mode menu.")

(easy-menu-define coq-commenter--mode-menu
  coq-commenter-mode-map
  "Menu used when `coq-commenter-mode' is active."
  '("CoqCom"
    "----"
    ["Comment proof in buffer" coq-commenter-comment-proof-in-buffer
     :help "Comment proof in buffer"]
    ["Comment proof to cursor" coq-commenter-comment-proof-to-cursor
     :help "Comment proof to cursor"]
    ["Comment proof in region" coq-commenter-comment-proof-in-region
     :help "Comment proof in region"]
    ["Uncomment proof in buffer" coq-commenter-uncomment-proof-in-buffer
     :help "Uncomment proof in buffer"]
    ["Uncomment proof to cursor" coq-commenter-uncomment-proof-to-cursor
     :help "Uncomment proof to cursor"]
    ["Uncomment proof in region" coq-commenter-uncomment-proof-in-region
     :help "Uncomment proof in region"]))

(provide 'coq-commenter)
;;; coq-commenter.el ends here
