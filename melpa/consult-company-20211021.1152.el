;;; consult-company.el --- Consult frontend for company -*- lexical-binding: t; -*-

;; Copyright (C) 2021  mohsin kaleem

;; Author: mohsin kaleem <mohkale@kisara.moe>
;; Package-Requires: ((emacs "27.1") (company "0.9") (consult "0.9"))
;; Package-Version: 20211021.1152
;; Package-Commit: ef1c553b4a72b23297b55708bf6f6dd1b27cc68e
;; Version: 0.1
;; URL: https://github.com/mohkale/consult-company

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a command to interactively complete a company
;; completion candidate through completing-read using the consult API.
;; This works much like the builtin `completion-at-point' command except
;; it can accept candidates from `company-backends' making it consistent
;; with the completion candidates you would see in the company popup.

;;; Code:

(require 'company)
(require 'consult)

(defgroup consult-company nil
  "Consult frontend for company."
  :group 'company
  :group 'consult)

(defcustom consult-company-narrow
  ;; Takes the same keys as `company-text-icons-mapping'.
  `((color ?# . "Color")
    ((file folder) ?f . "Files")
    (text ?w . "Word")
    (snippet ?s . "Snippet")
    (t ?c . "Completion"))
  "Narrow configuration for `consult-company'."
  :type '(list (choice (symbol :tag "Completion kind")
                       (repeat (symbol :tag "Completion kind")))
               (cons (character :tag "Narrow key")
                     (string :tag "Display name"))))

(defun consult-company--candidates ()
  "Retrieve a list of candidates for `consult-company'."
  (cl-loop for cand in company-candidates
           ;; We need to keep the original candidate separate from the one passed
           ;; to completing-read to prevent the useful text-properties from being
           ;; stripped.
           with ix = 0 do (setq ix (1+ ix))
           with cand-str = nil
           do (setq cand-str (consult--tofu-append (substring-no-properties cand) ix))
           ;; Assign the backend for candidate, defaults to capf for unknown backends.
           with backend = nil
           do (setq backend
                    (or (get-text-property 0 'company-backend cand)
                        (if (consp company-backend)
                            (car (cl-remove-if #'symbolp company-backend))
                          company-backend)))
           ;; Apply completions-common face to non-capf candidates.
           when (and (not (eq backend 'company-capf))
                     (string-prefix-p company-prefix cand))
             ;; Copy candidate and prefix with completions-common-part
             do (add-face-text-property 0 (length company-prefix)
                                          'completions-common-part nil cand-str)
           ;; Assign the consult--type property for title and narrowing.
           do (when-let ((narrow (or (when-let ((company-backend backend)
                                                (kind (company-call-backend 'kind cand)))
                                       (cl-assoc kind consult-company-narrow
                                                 :test (lambda (it x)
                                                         (or (eq x it)
                                                             (and (listp x)
                                                                  (member it x))))))
                                   (assoc t consult-company-narrow))))
              (add-text-properties 0 1 (list 'consult--type (cadr narrow)) cand-str))
           collect (cons cand-str cand)))

;;;###autoload
(defun consult-company ()
  "Interactively complete company candidates."
  (interactive)
  (unless company-candidates
    (company-complete))
  (let ((cands (consult--with-increased-gc
                (consult-company--candidates)))
        (narrow-assoc (mapcar #'cdr consult-company-narrow)))
    (unless cands
      (user-error "No completion candidates available"))
    (company-finish
     (consult--read
      cands
      :prompt "Candidate: "
      :lookup #'consult--lookup-cdr
      :sort nil
      :group (consult--type-group narrow-assoc)
      :narrow
      (let* ((narrow (consult--type-narrow narrow-assoc))
             (pred (plist-get narrow :predicate)))
        `(:predicate
          ,(lambda (cand)
             (funcall pred (car cand)))
          ,@narrow))))))

(provide 'consult-company)
;;; consult-company.el ends here
