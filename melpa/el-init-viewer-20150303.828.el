;;; el-init-viewer.el --- Record viewer for el-init  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Hiroki YAMAKAWA

;; Author:  Hiroki YAMAKAWA <s06139@gmail.com>
;; URL: https://github.com/HKey/el-init-viewer
;; Package-Version: 20150303.828
;; Package-Commit: 7c0169d356d6c007317e253e5776e1e48a60d6ad
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (ctable "0.1.2") (dash "2.10.0") (anaphora "1.0.0") (el-init "0.1.4"))
;; Keywords:

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

;; This package is a viewer of `el-init-record'.
;; Type "M-x el-init-viewer", then you can get the table buffer like below.

;; |       Name        |   Time    |GC Count|GC Time|Non GC Time|                         Error                         |eval-after-load Errors|
;; +-------------------+-----------+--------+-------+-----------+-------------------------------------------------------+----------------------+
;; |init-test-library  |0.002586966|       0|    0.0|0.002586966|                                                       |                      |
;; |init-test-error    |0.004214732|       0|    0.0|0.004214732|Error                                                  |                      |
;; |init-test-eal-error|0.012751416|       0|    0.0|0.012751416|Required feature `init-test-eal-error' was not provided|Error                 |
;; |init-lazy-lib-dummy|0.000493942|       0|    0.0|0.000493942|                                                       |                      |
;; |lib-dummy          |0.000474224|       0|    0.0|0.000474224|                                                       |                      |
;; |init-a             |0.009302054|       0|    0.0|0.009302054|                                                       |                      |
;; |init-b             |0.000494089|       0|    0.0|0.000494089|                                                       |                      |

;;; Code:

(require 'cl-lib)
(require 'ctable)
(require 'dash)
(require 'anaphora)
(require 'el-init)

;;;; Columns

(cl-defstruct el-init-viewer-column
  cmodel
  key)

(defun el-init-viewer-sort-number-lessp (&rest args)
  (apply #'ctbl:sort-number-lessp
         (--map (if (not (numberp it)) 0 it)
                args)))

;; feature name

(defvar el-init-viewer-column/feature-name
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Name" :align 'left)
   :key
   (lambda (feature)
     (let ((name (symbol-name feature)))
       (propertize name
                   'font-lock-face 'button
                   'action (lambda () (find-library name)))))))

;; el-init-require/benchmark

(defvar el-init-viewer-column/benchmark-time
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Time" :sorter #'el-init-viewer-sort-number-lessp)
   :key
   (lambda (feature)
     (cl-first
      (el-init-get-record feature 'el-init-require/benchmark)))))

(defvar el-init-viewer-column/benchmark-gc-count
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "GC Count"
                     :sorter #'el-init-viewer-sort-number-lessp)
   :key
   (lambda (feature)
     (cl-second
      (el-init-get-record feature 'el-init-require/benchmark)))))

(defvar el-init-viewer-column/benchmark-gc-time
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "GC Time"
                     :sorter #'el-init-viewer-sort-number-lessp)
   :key
   (lambda (feature)
     (cl-third
      (el-init-get-record feature 'el-init-require/benchmark)))))

(defvar el-init-viewer-column/benchmark-non-gc-time
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Non GC Time"
                     :sorter #'el-init-viewer-sort-number-lessp)
   :key
   (lambda (feature)
     (awhen (el-init-get-record feature 'el-init-require/benchmark)
       (- (cl-first it) (cl-third it))))))

;; el-init-require/record-error

(defvar el-init-viewer-column/record-error
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Error" :align 'left)
   :key
   (lambda (feature)
     (awhen (el-init-get-record feature 'el-init-require/record-error)
       (error-message-string it)))))

;; el-init-require/record-eval-after-load-error

(defvar el-init-viewer-column/record-eval-after-load-error
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "eval-after-load Errors" :align 'left)
   :key
   (lambda (feature)
     (let ((add-button
            (lambda (string)
              (propertize string
                          'font-lock-face 'button
                          'action #'el-init-viewer-eval-after-load)))
           (errors
            (el-init-get-record
             feature
             'el-init-require/record-eval-after-load-error)))
       (cond ((> (length errors) 1)
              (funcall add-button
                       (format "%d errors" (length errors))))
             (errors
              (funcall add-button
                       (error-message-string
                        (cl-getf (cl-first errors) :error))))
             (t nil))))))

;; el-init-require/record-old-library

(defvar el-init-viewer-column/record-old-library
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Old .elc?" :align 'center)
   :key
   (lambda (feature)
     (cl-getf '(t "Yes" nil "No")
              (el-init-get-record feature
                                  'el-init-require/record-old-library
                                  (cl-gensym))))))

;; el-init-require/compile-old-library

(defvar el-init-viewer-column/compile-old-library
  (make-el-init-viewer-column
   :cmodel
   (make-ctbl:cmodel :title "Recompile" :align 'center)
   :key
   (lambda (feature)
     (cl-getf '(t "Succeeded" nil "Failed")
              (el-init-get-record feature
                                  'el-init-require/compile-old-library
                                  (cl-gensym))))))

;; columns

(defvar el-init-viewer-columns
  '(el-init-viewer-column/feature-name
    el-init-viewer-column/benchmark-time
    el-init-viewer-column/benchmark-gc-count
    el-init-viewer-column/benchmark-gc-time
    el-init-viewer-column/benchmark-non-gc-time
    el-init-viewer-column/record-error
    el-init-viewer-column/record-eval-after-load-error
    el-init-viewer-column/record-old-library
    el-init-viewer-column/compile-old-library))


;;;; Viewer

(defvar el-init-viewer-hide-no-data-column t)

(defvar el-init-viewer-map
  (let ((map (make-sparse-keymap)))
    (define-key map "q" #'quit-window)
    map))

(defun el-init-viewer--get-data (columns feature)
  (--map (or (funcall (el-init-viewer-column-key it) feature)
             "")
         columns))

(defun el-init-viewer--get-entity (object)
  (if (symbolp object)
      (symbol-value object)
    object))

(defun el-init-viewer--remove-no-data-column (column-models data)
  (let* ((no-data-column-p
          (lambda (&rest data)
            (--every-p (equal it "") data)))
         (no-data-column-flags
          (apply #'cl-mapcar
                 no-data-column-p
                 (or data (list nil))))
         (remove-no-data-column
          (lambda (columns flags)
            (cl-loop for c in columns
                     for f in flags
                     unless f
                     collect c))))
    (list :column-model
          (funcall remove-no-data-column
                   column-models
                   no-data-column-flags)
          :data
          (--map (funcall remove-no-data-column
                          it
                          no-data-column-flags)
                 data))))

;;;###autoload
(defun el-init-viewer ()
  (interactive)
  (let* ((columns (-map #'el-init-viewer--get-entity el-init-viewer-columns))
         (feature-list (-map #'car el-init-record))
         (cmodels (-map #'el-init-viewer-column-cmodel columns))
         (data (--map (el-init-viewer--get-data columns it)
                      feature-list))
         (model (if el-init-viewer-hide-no-data-column
                    (apply #'make-ctbl:model
                           (el-init-viewer--remove-no-data-column
                            cmodels
                            data))
                  (make-ctbl:model :column-model cmodels
                                   :data         data)))
         (component (ctbl:create-table-component-buffer
                     :model model
                     :buffer (get-buffer-create "*el-init-viewer*")
                     :custom-map el-init-viewer-map)))
    (ctbl:cp-add-click-hook
     component
     (lambda ()
       (awhen (get-text-property
               0
               'action
               (ctbl:cp-get-selected-data-cell component))
         (funcall it))))
    (switch-to-buffer (ctbl:cp-get-buffer component))))

;;;###autoload
(defun el-init-viewer-eval-after-load ()
  (interactive)
  (switch-to-buffer
   (ctbl:cp-get-buffer
    (ctbl:create-table-component-buffer
     :model
     (make-ctbl:model
      :column-model
      (list (make-ctbl:cmodel :title "From"  :align 'left)
            (make-ctbl:cmodel :title "To"    :align 'left)
            (make-ctbl:cmodel :title "Error" :align 'left))
      :data
      (cl-loop for (feature . plist) in el-init-record
               if (cl-getf plist
                           'el-init-require/record-eval-after-load-error)
               append
               (cl-loop for data in it
                        collect
                        (list (symbol-name feature)
                              (format "%s" (cl-getf data :file))
                              (error-message-string (cl-getf data :error))))))
     :buffer (get-buffer-create "*el-init-viewer: eval-after-load errors*")
     :custom-map el-init-viewer-map))))

(provide 'el-init-viewer)
;;; el-init-viewer.el ends here
