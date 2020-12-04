;;; smeargle.el --- Highlighting region by last updated time -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2020 Syohei YOSHIDA and Neil Okamoto

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; Maintainer: Neil Okamoto <neil.okamoto+melpa@gmail.com>
;; URL: https://github.com/emacsorphanage/smeargle
;; Package-Version: 20200323.533
;; Package-Commit: 0cfe0ff083d55bb90c6dfaf1dc930500099c4d5c
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

;; `smeargle' is an Emacs port of Vim's smeargle.  `smeargle'
;; highlights lines in a buffer by the last update time / age of last
;; commit as a visual indication which parts have been changed recently.

;;; Code:

(require 'cl-lib)

(defgroup smeargle nil
  "Highlight regions by last updated time."
  :group 'vc)

(defcustom smeargle-colors
  '((older-than-1day . nil)
    (older-than-3day . "grey5")
    (older-than-1week . "grey10")
    (older-than-2week . "grey15")
    (older-than-1month . "grey20")
    (older-than-3month . "grey25")
    (older-than-6month . "grey30")
    (older-than-1year . "grey35"))
  "Alist of last updated era and background color."
  :type '(repeat (cons (symbol :tag "How old")
                       (string :tag "Background color name"))))

(defcustom smeargle-age-colors
  '((0 . nil)
    (1 . "grey5")
    (2 . "grey10")
    (3 . "grey15")
    (4 . "grey20")
    (5 . "grey25")
    (6 . "grey30")
    (7 . "grey30"))
  "Alist of age of changes and background color."
  :type '(repeat (cons (int :tag "Age of changes")
                       (string :tag "Background color name"))))

(defcustom smeargle-age-threshold 7
  "Threshould of age of changes."
  :type 'integer)

(defun smeargle--updated-era (now updated-date)
  (let* ((delta (decode-time (time-subtract now updated-date)))
         (delta-year (- (nth 5 delta) 1970))
         (delta-month (nth 4 delta))
         (delta-day (nth 3 delta)))
    (cond ((>= delta-year 1) 'older-than-1year)
          ((> delta-month 6) 'older-than-6month)
          ((> delta-month 3) 'older-than-3month)
          ((> delta-month 1) 'older-than-1month)
          ((> delta-day 14) 'older-than-2week)
          ((> delta-day 7) 'older-than-1week)
          ((> delta-day 3) 'older-than-3day)
          ((> delta-day 1) 'older-than-1day))))

(defsubst smeargle--date-regexp (repo-type)
  (cl-case repo-type
    (git "\\(\\S-+ \\S-+ \\S-+\\)\\s-+[1-9][0-9]*)")
    (mercurial "^\\(.+?\\): ")))

(defsubst smeargle--compare-function (update-type)
  (cl-case update-type
    (by-age (lambda (a b) (= a b)))
    (by-time (lambda (a b) (eq a b)))))

(defsubst smeargle--retrieve-function (update-type)
  (cl-case update-type
    (by-age (lambda (_now time) (float-time time)))
    (by-time (lambda (now time) (smeargle--updated-era now time)))))

(defun smeargle--parse-blame (proc repo-type update-type)
  (let ((cmp-fn (smeargle--compare-function update-type))
        (retrieve-fn (smeargle--retrieve-function update-type)))
    (with-current-buffer (process-buffer proc)
      (goto-char (point-min))
      (let ((update-date-regexp (smeargle--date-regexp repo-type))
            (now (current-time))
            (curline 1)
            start update-info last-update)
        (while (re-search-forward update-date-regexp nil t)
          (let* ((updated-date (date-to-time (match-string-no-properties 1)))
                 (update-era (funcall retrieve-fn now updated-date)))
            (when (and (not last-update) update-era)
              (setq start curline last-update update-era))
            (when (and last-update
                       (not (funcall cmp-fn last-update update-era)))
              (push (list :start start :end (1- curline) :when last-update)
                    update-info)
              (setq start curline last-update update-era))
            (cl-incf curline)
            (forward-line 1)))
        (push (list :start start :end curline :when last-update) update-info)
        (reverse update-info)))))

(defun smeargle--highlight (update-info curbuf colors)
  (with-current-buffer curbuf
    (save-excursion
      (goto-char (point-min))
      (let ((curline 1))
        (dolist (info update-info)
          (let ((start-line (plist-get info :start))
                (end-line (1+ (plist-get info :end)))
                (color (assoc-default (plist-get info :when) colors))
                start)
            (forward-line (- start-line curline))
            (setq start (point))
            (forward-line (- end-line start-line))
            (setq curline end-line)
            (let ((ov (make-overlay start (point))))
              (overlay-put ov 'face `(:background ,color :extend t))
              (overlay-put ov 'smeargle t))))))))

(defun smeargle--blame-command (repo-type)
  (let ((bufname (buffer-file-name)))
    (cl-case repo-type
      (git `("git" "--no-pager" "blame" ,bufname))
      (mercurial `("hg" "blame" "-d" ,bufname)))))

(defun smeargle--sorted-date (update-info)
  (let ((times (mapcar (lambda (c) (plist-get c :when)) update-info)))
    (delete-dups times)
    (cl-loop with hash = (make-hash-table :test 'equal)
             for time in (sort times '>)
             for age = 0 then (+ age 1)
             do
             (puthash time age hash)
             finally return hash)))

(defun smeargle--set-age (update-info)
  (let ((age-info (smeargle--sorted-date update-info)))
    (cl-loop for info in update-info
             for d = (plist-get info :when)
             for real-age = (gethash d age-info)
             for age = (if (>= real-age smeargle-age-threshold)
                           smeargle-age-threshold
                         real-age)
             do
             (plist-put info :when age))))

(defun smeargle--start-blame-process (repo-type proc-buf update-type)
  (let* ((curbuf (current-buffer))
         (cmds (smeargle--blame-command repo-type))
         (proc (apply 'start-file-process "smeargle" proc-buf cmds)))
    (set-process-query-on-exit-flag proc nil)
    (set-process-sentinel
     proc
     (lambda (proc _event)
       (when (eq (process-status proc) 'exit)
         (let ((update-info (smeargle--parse-blame proc repo-type update-type))
               (colors (if (eq update-type 'by-time)
                           smeargle-colors
                         smeargle-age-colors)))
           (when (eq update-type 'by-age)
             (smeargle--set-age update-info))
           (smeargle--highlight update-info curbuf colors)
           (kill-buffer proc-buf)))))))

(defsubst smeargle--process-buffer (bufname)
  (get-buffer-create (format " *smeargle-%s*" bufname)))

(defsubst smeargle--repo-type ()
  (cl-loop for (type . repo-dir) in '((git . ".git") (mercurial . ".hg"))
           when (locate-dominating-file default-directory repo-dir)
           return type))

;;;###autoload
(defun smeargle-clear ()
  "Clear smeargle overlays in current buffer."
  (interactive)
  (dolist (ov (overlays-in (point-min) (point-max)))
    (when (overlay-get ov 'smeargle)
      (delete-overlay ov))))

;;;###autoload
(defun smeargle (&optional update-type)
  "Highlight regions by last updated time."
  (interactive)
  (smeargle-clear)
  (let ((repo-type (smeargle--repo-type)))
    (unless repo-type
      (user-error "Here is not 'git' or 'mercurial' repository"))
    (smeargle--start-blame-process
     repo-type (smeargle--process-buffer (buffer-file-name))
     (or update-type 'by-time))))

;;;###autoload
(defun smeargle-commits ()
  "Highlight regions by age of commits."
  (interactive)
  (smeargle 'by-age))

(provide 'smeargle)

;;; smeargle.el ends here

;; Local Variables:
;; fill-column: 80
;; indent-tabs-mode: nil
;; End:
