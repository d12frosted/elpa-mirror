;;; tblui.el --- Define tabulated list UI easily -*- lexical-binding: t -*-

;; Copyright (C) 2016 Yuki Inoue

;; 2 function defs are taken from: https://github.com/politza/tablist
;; Namely, tblui--tablist-get-marked-items and tblui--tablist-map-over-marks
;; Those copyright belongs to:
;;     Copyright (C) 2013, 2014  Andreas Politz

;; Author: Yuki Inoue <inouetakahiroki _at_ gmail.com>
;; URL: https://github.com/Yuki-Inoue/tblui.el
;; Package-Version: 20161007.1912
;; Package-Commit: bb29323bb3e27093d50cb42db3a9329a096b6e4d
;; Version: 0.1.0
;; Package-Requires: ((dash "2.12.1") (magit-popup "2.6.0") (tablist "0.70") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

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

;; Define tabulated list UI easily.

;;; Code:

(require 'tablist)
(require 'dash)
(require 'magit-popup)
(require 'cl-lib)

(defun tblui--append-str-to-symbol (symbol str)
  (intern (concat (symbol-name symbol) str)))


;; Following 2 functions taken from: https://github.com/politza/tablist
;; Copyright (C) 2013, 2014  Andreas Politz
;; licensed under GPLv3.
(defun tblui--tablist-map-over-marks (fn &optional arg show-progress
                                  distinguish-one-marked)
  (prog1
      (cond
       ((and arg (integerp arg))
        (let (results)
          (tablist-repeat-over-lines
           arg
           (lambda ()
             (if show-progress (sit-for 0))
             (push (funcall fn) results)))
          (if (< arg 0)
              (nreverse results)
            results)))
       (arg
        ;; non-nil, non-integer ARG means use current item:
        (tablist-skip-invisible-entries)
        (unless (eobp)
          (list (funcall fn))))
       (t
        (cl-labels ((search (re)
                            (let (sucess)
                              (tablist-skip-invisible-entries)
                              (while (and (setq sucess
                                                (re-search-forward re nil t))
                                          (invisible-p (point)))
                                (tablist-forward-entry))
                              sucess)))
          (let ((regexp (tablist-marker-regexp))
                next-position results found)
            (save-excursion
              (goto-char (point-min))
              ;; remember position of next marked file before BODY
              ;; can insert lines before the just found file,
              ;; confusing us by finding the same marked file again
              ;; and again and...
              (setq next-position (and (search regexp)
                                       (point-marker))
                    found (not (null next-position)))
              (while next-position
                (goto-char next-position)
                (if show-progress (sit-for 0))
                (push (funcall fn) results)
                ;; move after last match
                (goto-char next-position)
                (forward-line 1)
                (set-marker next-position nil)
                (setq next-position (and (search regexp)
                                         (point-marker)))))
            (if (and distinguish-one-marked (= (length results) 1))
                (setq results (cons t results)))
            results))))
    (tablist-move-to-major-column)))

(defun tblui--tablist-get-marked-items (&optional arg distinguish-one-marked)
  "Return marked or ARG entries."
  (let ((items (save-excursion
                 (tblui--tablist-map-over-marks
                  (lambda () (cons (tabulated-list-get-id)
                                   (tabulated-list-get-entry)))
                  arg nil distinguish-one-marked))))
    (if (and distinguish-one-marked
             (eq (car items) t))
        items
      (nreverse items))))

;; end of copy from tablist


(defun tblui--select-if-empty (&optional _arg)
  "Select current row is selection is empty."
  (unless (tblui--tablist-get-marked-items)
    (tablist-put-mark)))

;;;###autoload
(defmacro tblui-define (tblui-name entries-provider table-layout popup-definitions)

  "Define tabulated list UI easily.  Hereafter referred as tblui.
This macro defines functions and popups for the defined tblui.
User of this macro can focus on writing the logic for ui, let this
package handle the tabulated list buffer interaction part.

Each arguments are explained as follows:

 * `TBLUI-NAME` : the symbol name of defining tblui.  It will be used
                  as prefix for functions defined via this macro.
 * `ENTRIES-PROVIDER` : the function which provides tabulated-list-entries
 * `TABLE-LAYOUT` : the `tabulated-list-format` to be used for the tblui.
 * `POPUP-DEFINITIONS` : list of popup definition.
   A popup definition is an plist of
       `(:key KEY :name NAME :funcs FUNCTIONS)`.
   KEY is the key to be bound for the defined magit-popup.
   NAME is the name for defined magit-popup.
   FUNCTIONS is the list of action definition.
   Action definition is a list of 3 elements,
   which is `(ACTIONKEY DESCRIPTION FUNCTION)`.

   ACTIONKEY is the key to be used as action key in the magit-popup.
   DESCRIPTION is the description of the action.
   FUNCTION is the logic to be called for this UI.
   It is the elisp function which receives the IDs of tabulated-list entry,
    and do what ever operation.

With this macro `TBLUI-NAME-goto-ui` function is defined.
Calling this function will popup and switch to the tblui buffer."


  (let* ((goto-ui-symbol
          (tblui--append-str-to-symbol tblui-name "-goto-ui"))
         (ui-buffer-name
          (concat "*" (symbol-name tblui-name) "*"))
         (refresher-symbol
          (tblui--append-str-to-symbol tblui-name "-refresher"))
         (mode-name-symbol
          (tblui--append-str-to-symbol tblui-name "-mode"))
         (mode-map-symbol
          (tblui--append-str-to-symbol mode-name-symbol "-map"))
         (tablist-funcs
          (->> popup-definitions
               (mapcar (lambda (pdef) (plist-get pdef :funcs)))
               (apply #'append)
               (mapcar (apply-partially #'nth 2))))
         (tablist-func-info-assoc
          (->> tablist-funcs
               (mapcar
                (lambda (tablist-func)
                  (cons tablist-func
                        (tblui--append-str-to-symbol tablist-func "-popup-interface")))))))

    `(progn
       (defun ,refresher-symbol ()
         (setq tabulated-list-entries (,entries-provider)))

       ,@(mapcar
          (lambda (tablist-func-info-entry)
            `(defun ,(cdr tablist-func-info-entry) ()
               (interactive)
               (,(car tablist-func-info-entry)
                (mapcar #'car (tablist-get-marked-items)))))
          tablist-func-info-assoc)

       ,@(mapcar
          (lambda (popup-definition)
            (let ((popup-name (plist-get popup-definition :name))
                  (associated-funcs (plist-get popup-definition :funcs)))
              `(progn
                 (magit-define-popup ,popup-name (quote ,tblui-name)
                   :actions ',(mapcar
                               (lambda (entry)
                                 (cl-multiple-value-bind
                                     (key descr raw-func) entry
                                   (list key descr (assoc-default raw-func tablist-func-info-assoc))))
                               associated-funcs))
                 (add-function :before (symbol-function ',popup-name) #'tblui--select-if-empty))
              ))
            popup-definitions)

       (define-derived-mode ,mode-name-symbol tabulated-list-mode "Containers Menu"
         "Major mode for handling a list of docker containers."

         ,@(mapcar
            (lambda (popup-definition)
              (let ((key (plist-get popup-definition :key))
                    (popup-name (plist-get popup-definition :name)))
                `(define-key ,mode-map-symbol ,key (function ,popup-name))
                ))
            popup-definitions)

         (setq tabulated-list-format ,table-layout)
         (setq tabulated-list-padding 2)
         (add-hook 'tabulated-list-revert-hook (function ,refresher-symbol) nil t)
         (tabulated-list-init-header)
         (tablist-minor-mode))

       (defun ,goto-ui-symbol ()
         (pop-to-buffer ,ui-buffer-name)
         (tabulated-list-init-header)
         (,mode-name-symbol)
         (tabulated-list-revert))

       )
    ))

(provide 'tblui)
;;; tblui.el ends here
