;;; elpa-audit.el --- Handy functions for inspecting and comparing package archives

;; Copyright (C) 2012 Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; Version: DEV
;; Package-Version: 20141023.1331
;; Package-Commit: 727da50e626977351aff2675b6540a36818bbbe6
;; URL: https://github.com/purcell/elpa-audit
;; Keywords: maint

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

;; Useful functions for package archive maintainers.

;;; Code:

(defun elpa-audit/clean-description (package-descr)
  "Trim cruft from PACKAGE-DESCR."
  (replace-regexp-in-string " \\(-\\*-\\|\\[\\).*" "" package-descr))

(defun elpa-audit/read-elisp-datum (file-name)
  "Read the first sexp in FILE-NAME."
  (car (read-from-string
        (with-temp-buffer
          (insert-file-contents-literally file-name)
          (buffer-substring-no-properties (point-min) (point-max))))))

(defun elpa-audit/package-list (archive-name)
  "Return a sorted list of informative plists for packages in ARCHIVE-NAME."
  (let* ((archive-contents (expand-file-name (concat "archives/" archive-name "/archive-contents")
                                             package-user-dir))
         (packages (mapcar (lambda (entry) (list :archive archive-name
                                            :name (symbol-name (car entry))
                                            :desc (elpa-audit/clean-description
                                                   (elt (cdr entry) 2))
                                            :version (package-version-join (elt (cdr entry) 0))))
                        (rest (elpa-audit/read-elisp-datum archive-contents)))))
    (sort packages (lambda (p1 p2) (string< (plist-get p1 :name) (plist-get p2 :name))))))

(defun elpa-audit/full-package-list ()
  "Return information about packages in all archives."
  (apply 'append (mapcar 'elpa-audit/package-list (mapcar 'car package-archives))))

(defun elpa-audit/package-names (archive-name)
  "Return a (sorted) list of package names found in ARCHIVE-NAME."
  (mapcar (lambda (p) (plist-get p :name)) (elpa-audit/package-list archive-name)))

(defun elpa-audit/archive-sizes ()
  "Return a list of (ARCHIVE-NAME . PACKAGE-COUNT) for all archives."
  (mapcar
   (lambda (archive-name)
     (cons archive-name (length (elpa-audit/package-list archive-name))))
   (mapcar 'car package-archives)))



(defun elpa-audit/read-archive-name (&optional prompt)
  "Ask the name of an archive, optionally using PROMPT."
  (let ((archive-names (mapcar 'car package-archives)))
    (completing-read (or prompt "Package archive: ")
                     archive-names
                     nil t nil nil
                     (first archive-names))))

(defun elpa-audit/read-package-name (&optional prompt)
  "Ask the name of a package, optionally using PROMPT."
  (let ((package-names (mapcar (lambda (p) (plist-get p :name))
                               (elpa-audit/full-package-list))))
    (completing-read (or prompt "Package name: ")
                     (remove-duplicates package-names)
                     nil t nil nil
                     (first package-names))))

(defun elpa-audit/browse-url-at-point (button)
  "When BUTTON is clicked, browses the value of the button's 'url text property."
  (let ((url (button-get button 'url)))
    (when url
      (browse-url url))))

(defun elpa-audit/package-url (package)
  "Return an informative URL for package with plist PACKAGE."
  (let ((archive-url (cdr (assoc (plist-get package :archive) package-archives)))
        (name (plist-get package :name)))
    (cond
     ((string= archive-url "http://melpa.org/packages/")
      (format "https://github.com/milkypostman/melpa/blob/master/recipes/%s" name))
     ((string= archive-url "http://marmalade-repo.org/packages/")
      (format "http://marmalade-repo.org/packages/%s" name))
     ((string= archive-url "http://elpa.gnu.org/packages/")
      (format "http://bzr.savannah.gnu.org/lh/emacs/elpa/files/head:/packages/%s/" name)))))

(defun elpa-audit/insert-package-link (package &optional label)
  "Insert a text button linking to PACKAGE, optionally with LABEL."
  (let ((text (or label (plist-get package :name)))
        (url (elpa-audit/package-url package)))
    (if url
        (insert-text-button
         text
         'mouse-face 'highlight
         'follow-link t
         'action #'elpa-audit/browse-url-at-point
         'url url
         'help-echo "mouse-2: visit the upstream package page")
      (insert text))))

;;;###autoload
(defun elpa-audit-dump-package-list-to-buffer (archive-name)
  "Write a list of packages in ARCHIVE-NAME into a new buffer."
  (interactive (list (elpa-audit/read-archive-name)))
  (let ((buffer
         (save-excursion
           (let ((packages (elpa-audit/package-list archive-name)))
             (with-current-buffer (get-buffer-create (format "*package list - %s*" archive-name))
               (fundamental-mode)
               (erase-buffer)
               (dolist (entry packages)
                 (elpa-audit/insert-package-link entry)
                 (insert (format " - %s\n" (plist-get entry :desc))))
               (goto-char 0)
               (view-mode)
               (current-buffer))))))
    (when (called-interactively-p 'any)
      (pop-to-buffer buffer))
    buffer))

;;;###autoload
(defun elpa-audit-ediff-archives (archive1 archive2)
  "Start an ediff session comparing the package lists for ARCHIVE1 and ARCHIVE2."
  (interactive (list
                (elpa-audit/read-archive-name "Package archive A: ")
                (elpa-audit/read-archive-name "Package archive B: ")))
  (ediff-buffers (elpa-audit-dump-package-list-to-buffer archive1)
                 (elpa-audit-dump-package-list-to-buffer archive2)))

;;;###autoload
(defun elpa-audit-show-package-versions (package-name)
  "Write info about available versions of PACKAGE-NAME into a new buffer."
  (interactive (list (elpa-audit/read-package-name)))
  (let ((buffer
         (with-current-buffer (get-buffer-create (format "*package versions - %s*" package-name))
           (fundamental-mode)
           (erase-buffer)
           (dolist (package (elpa-audit/full-package-list))
             (when (string= package-name (plist-get package :name))
               (elpa-audit/insert-package-link package)
               (insert (format " - %s - %s\n"
                               (plist-get package :version)
                               (plist-get package :archive)))))
           (view-mode)
           (current-buffer))))
    (when (called-interactively-p 'any)
      (pop-to-buffer buffer))
    buffer))


(provide 'elpa-audit)

;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not cl-functions)
;; eval: (checkdoc-minor-mode 1)
;; End:

;;; elpa-audit.el ends here
