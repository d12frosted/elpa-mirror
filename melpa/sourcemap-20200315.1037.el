;;; sourcemap.el --- Sourcemap parser -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-sourcemap
;; Package-Version: 20200315.1037
;; Package-Commit: bb2a56b2feb62b0c77d7f03ef2acd94f91be6b3f
;; Version: 0.03
;; Package-Requires: ((emacs "24.3"))

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

;;; Code:

(require 'cl-lib)
(require 'json)

(cl-defstruct sourcemap-entry
  source generated-line generated-column original-line original-column name)

(defconst sourcemap--vlq-shift-width 5)

(defconst sourcemap--vlq-mask (1- (ash 1 5))
  "0b011111")

(defconst sourcemap--vlq-continuation-bit (ash 1 5)
  "0b100000")

(defvar sourcemap--char2int-table (make-hash-table :test 'equal))

(let ((chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"))
  (cl-loop for char across chars
           for index = 0 then (1+ index)
           do
           (puthash char index sourcemap--char2int-table)))

(defsubst sourcemap--vlq-continuation-value-p (value)
  (not (zerop (logand value sourcemap--vlq-continuation-bit))))

(defsubst sourcemap--vlq-value (value)
  (logand value sourcemap--vlq-mask))

(defun sourcemap--base64-decode (char)
  (let ((val (gethash char sourcemap--char2int-table 'not-found)))
    (if (eq val 'not-found)
        (error "Invalid input '%s'" (char-to-string char))
      val)))

(defun sourcemap--from-vlq-signed (value)
  (let ((negative-p (= (logand value 1) 1))
        (shifted (ash value -1)))
    (if negative-p
        (- shifted)
      shifted)))

(defun sourcemap-base64-vlq-decode (str start limit)
  (cl-loop for i from start below limit
           for index = 1 then (1+ index)
           for shift = 0 then (+ shift sourcemap--vlq-shift-width)
           for digit = (sourcemap--base64-decode (aref str i))
           for value = (sourcemap--vlq-value digit)
           for result = value then (+ result (ash value shift))
           unless (sourcemap--vlq-continuation-value-p digit)
           return (list :value (sourcemap--from-vlq-signed result)
                        :rest-index (+ index start))))

(defsubst sourcemap--starts-with-separator-p (char)
  (member char '(?\; ?,)))

(defun sourcemap--retrieve (sourcemap property)
  (let ((value (assoc-default property sourcemap)))
    (if (not value)
        (error "Can't found '%s' property" property)
      value)))

(defsubst sourcemap--sources-at (sourcemap index)
  (aref (sourcemap--retrieve sourcemap 'sources) index))

(defsubst sourcemap--names-at (sourcemap index)
  (aref (sourcemap--retrieve sourcemap 'names) index))

(defun sourcemap--parse-mappings (sourcemap)
  (let* ((str (sourcemap--retrieve sourcemap 'mappings))
         (generated-line 1) (previous-generated-column 0)
         (previous-source 0) (previous-original-line 0)
         (previous-original-column 0) (previous-name 0)
         (mappings '())
         temp (curpos 0) (limit (length str)))
    (while (< curpos limit)
      (let ((first-char (aref str curpos)))
        (cond ((= first-char ?\;)
               (cl-incf curpos)
               (setq generated-line (1+ generated-line)
                     previous-generated-column 0))
              ((= first-char ?,)
               (cl-incf curpos))
              (t
               (let ((mapping (make-sourcemap-entry :generated-line generated-line)))
                 ;; Generated Column
                 (setq temp (sourcemap-base64-vlq-decode str curpos limit))
                 (let ((current-column (+ previous-generated-column (plist-get temp :value))))
                   (setq previous-generated-column current-column)
                   (setf (sourcemap-entry-generated-column mapping) current-column))

                 ;; Original source
                 (setq curpos (plist-get temp :rest-index))
                 (when (and (< curpos limit)
                            (not (sourcemap--starts-with-separator-p (aref str curpos))))
                   (setq temp (sourcemap-base64-vlq-decode str curpos limit))
                   (let* ((source-value (plist-get temp :value))
                          (current-source (+ previous-source source-value)))
                     (setf (sourcemap-entry-source mapping)
                           (sourcemap--sources-at sourcemap current-source))
                     (cl-incf previous-source source-value))
                   (setq curpos (plist-get temp :rest-index))
                   (when (or (= (1- curpos) limit)
                             (sourcemap--starts-with-separator-p (aref str curpos)))
                     (error "Found a source, but no line and column"))

                   ;; Original line
                   (setq temp (sourcemap-base64-vlq-decode str curpos limit))
                   (let ((original-line (+ previous-original-line (plist-get temp :value))))
                     (setq previous-original-line original-line)
                     (setf (sourcemap-entry-original-line mapping) (1+ original-line)))
                   (setq curpos (plist-get temp :rest-index))

                   ;; Original column
                   (setq temp (sourcemap-base64-vlq-decode str curpos limit))
                   (let ((original-column (+ previous-original-column
                                             (plist-get temp :value))))
                     (setf (sourcemap-entry-original-column mapping) original-column)
                     (setq previous-original-column original-column))
                   (setq curpos (plist-get temp :rest-index))
                   ;; Original name
                   (when (and (< curpos limit)
                              (not (sourcemap--starts-with-separator-p (aref str curpos))))
                     (setq temp (sourcemap-base64-vlq-decode str curpos limit))
                     (let* ((name-value (plist-get temp :value))
                            (name-index (+ previous-name name-value)))
                       (setf (sourcemap-entry-name mapping)
                             (sourcemap--names-at sourcemap name-index))
                       (cl-incf previous-name name-value))
                     (setq curpos (plist-get temp :rest-index))))
                 (push mapping mappings))))))
    (vconcat (reverse mappings))))

(defun sourcemap--select-nearest (src low high line-fn column-fn)
  (let* ((low-line (funcall line-fn low))
         (low-column (funcall column-fn low))
         (high-line (funcall line-fn high))
         (high-column (funcall column-fn high))
         (src-line (funcall line-fn src))
         (src-column (funcall column-fn src))
         (distance-low (abs (- src-line low-line)))
         (distance-high (abs (- src-line high-line))))
    (cond ((< distance-low distance-high) low)
          ((> distance-low distance-high) high)
          (t
           (let ((distance-low (abs (- src-column low-column)))
                 (distance-high (abs (- src-column high-column))))
             (cond ((<= distance-low distance-high) low)
                   ((> distance-low distance-high) high)))))))

(defsubst sourcemap--compare-mapping (target-line target-column source-line source-column)
  (cond ((< target-line source-line) 1)
        ((> target-line source-line) -1)
        ((< target-column source-column) 1)
        ((> target-column source-column) -1)
        (t 0)))

(defun sourcemap--binary-search (sourcemap here type &optional nearest)
  (let ((low 0) (high (1- (length sourcemap)))
        line-fn column-fn finish matched last-low last-high
        source-line source-column)
    (if (eq type 'original)
        (setq line-fn #'sourcemap-entry-original-line
              column-fn #'sourcemap-entry-original-column)
      (setq line-fn #'sourcemap-entry-generated-line
            column-fn #'sourcemap-entry-generated-column))
    (setq source-line (funcall line-fn here)
          source-column (funcall column-fn here))
    (while (and (<= low high) (not finish))
      (let* ((middle-index (/ (+ low high) 2))
             (middle (aref sourcemap middle-index))
             (middle-line (funcall line-fn middle))
             (middle-column (funcall column-fn middle))
             (compare-value (sourcemap--compare-mapping
                             middle-line middle-column source-line source-column)))
        (setq last-low low last-high high)
        (cond ((= compare-value -1)
               (setq high (1- middle-index)))
              ((= compare-value 1)
               (setq low (1+ middle-index)))
              (t
               (setq finish t matched middle)))))
    (cond (finish matched)
          (nearest (sourcemap--select-nearest
                     here (aref sourcemap last-low) (aref sourcemap last-high)
                     line-fn column-fn)))))

(defsubst sourcemap--filter-same-file (sourcemap file)
  (cl-loop for map across sourcemap
           when (string= file (sourcemap-entry-source map))
           collect map into ret
           finally return (vconcat ret)))

(defun sourcemap-generated-position-for (sourcemap &rest props)
  (let ((samefile-map (sourcemap--filter-same-file sourcemap (plist-get props :source)))
        (here (make-sourcemap-entry :original-line (plist-get props :line)
                                    :original-column (plist-get props :column))))
    (when samefile-map
      (let ((ret (sourcemap--binary-search samefile-map here 'original
					   (plist-get props :nearest))))
        (when ret
          (list :line (sourcemap-entry-generated-line ret)
                :column (sourcemap-entry-generated-column ret)))))))

(defun sourcemap-original-position-for (sourcemap &rest props)
  (let ((here (make-sourcemap-entry :generated-line (plist-get props :line)
                                    :generated-column (plist-get props :column))))
    (let ((ret (sourcemap--binary-search sourcemap here 'generated
					 (plist-get props :nearest))))
      (when ret
        (list :source (sourcemap-entry-source ret)
              :line (sourcemap-entry-original-line ret)
              :column (sourcemap-entry-original-column ret))))))

;;;###autoload
(defun sourcemap-goto-corresponding-point (props)
  "hook function of coffee-mode. This function should not be used directly.
This functions should be called in generated Javascript file."
  (let ((sourcemap-file (plist-get props :sourcemap)))
    (unless sourcemap-file
      (user-error "Error: ':sourcemap' property is not set"))
    (let* ((sourcemap (sourcemap-from-file sourcemap-file))
           (source-file (file-name-nondirectory (plist-get props :source)))
           (samefile-mappings (sourcemap--filter-same-file sourcemap source-file)))
      (if (not samefile-mappings)
          (message "Information in '%s' are not found" source-file)
        (let* ((here (make-sourcemap-entry :original-line (plist-get props :line)
                                           :original-column (plist-get props :column)))
               (nearest (sourcemap--binary-search sourcemap here 'original t)))
          (forward-line (1- (sourcemap-entry-generated-line nearest)))
          (move-to-column (sourcemap-entry-generated-column nearest)))))))

;;;###autoload
(defun sourcemap-from-file (file)
  (interactive
   (list (read-file-name "Sourcemap File: " nil nil t)))
  (sourcemap--parse-mappings (json-read-file file)))

;;;###autoload
(defun sourcemap-from-string (str)
  (sourcemap--parse-mappings (json-read-from-string str)))

(provide 'sourcemap)

;;; sourcemap.el ends here
